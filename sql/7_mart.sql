-- *не учитываем canceled и unavailable заказы
-- отсекаем конец 2016 и сентябрь-октябрь 2018, они почти пустые и исказят график

DROP MATERIALIZED VIEW IF EXISTS mart.daily_sales;
DROP MATERIALIZED VIEW IF EXISTS mart.daily_sales_by_state;
DROP MATERIALIZED VIEW IF EXISTS mart.daily_category_sales;
DROP MATERIALIZED VIEW IF EXISTS mart.reviews_by_delay;
DROP MATERIALIZED VIEW IF EXISTS mart.seller_performance;
DROP MATERIALIZED VIEW IF EXISTS mart.customer_cohorts;


-- 1 Как меняются продажи во времени (из-за числа заказов/ среднего чека)?
CREATE MATERIALIZED VIEW mart.daily_sales AS
WITH valid_orders AS (
    SELECT *
    FROM dwh.fact_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
)
SELECT
    d.date_day,
    d.week_start,
    d.month_start,
    d.year,
    d.day_of_week,
    d.is_weekend,

    COUNT(o.order_id) AS orders,
    COALESCE(SUM(o.total_order_amount), 0) AS revenue,
    COALESCE(SUM(o.total_freight), 0) AS freight,
    COALESCE(SUM(o.items_count), 0) AS items,

    COUNT(o.order_id) FILTER (WHERE o.is_delayed IS NOT NULL) AS delivered_orders,
    COUNT(o.order_id) FILTER (WHERE o.is_delayed) AS delayed_orders,
    COALESCE(SUM(o.delivery_days), 0) AS delivery_days_sum,

    COUNT(o.review_score) AS reviewed_orders,
    COALESCE(SUM(o.review_score), 0) AS review_score_sum
FROM dwh.dim_date d
LEFT JOIN valid_orders o
    ON o.purchase_date = d.date_day
WHERE d.date_day BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY d.date_day, d.week_start, d.month_start, d.year, d.day_of_week, d.is_weekend;


-- 2 В каких штатах растут продажи, в каких проблемы с доставкой?
CREATE MATERIALIZED VIEW mart.daily_sales_by_state AS
SELECT
    o.purchase_date AS date_day,
    DATE_TRUNC('month', o.purchase_date)::DATE AS month_start,
    c.customer_state AS state,

    COUNT(*) AS orders,
    SUM(o.total_order_amount) AS revenue,
    SUM(o.total_freight) AS freight,

    COUNT(*) FILTER (WHERE o.is_delayed IS NOT NULL) AS delivered_orders,
    COUNT(*) FILTER (WHERE o.is_delayed) AS delayed_orders,
    COALESCE(SUM(o.delivery_days), 0) AS delivery_days_sum,

    COUNT(o.review_score) AS reviewed_orders,
    COALESCE(SUM(o.review_score), 0) AS review_score_sum
FROM dwh.fact_orders o
JOIN dwh.dim_customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.purchase_date BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY o.purchase_date, c.customer_state;


-- 3 Какие категории приносят выручку и как это меняется?
CREATE MATERIALIZED VIEW mart.daily_category_sales AS
SELECT
    o.purchase_date AS date_day,
    DATE_TRUNC('month', o.purchase_date)::DATE AS month_start,
    p.product_category_name_english AS category,

    COUNT(*) AS items_sold,
    SUM(oi.price) AS revenue,
    COUNT(DISTINCT oi.order_id) AS orders
FROM dwh.fact_order_items oi
JOIN dwh.fact_orders o
    ON oi.order_id = o.order_id
JOIN dwh.dim_products p
    ON oi.product_id = p.product_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.purchase_date BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY o.purchase_date, p.product_category_name_english;


-- 4 Как опоздание доставки влияет на оценку покупателя?
-- *только доставленные заказы с датой доставки
CREATE MATERIALIZED VIEW mart.reviews_by_delay AS
SELECT
    o.purchase_date AS date_day,
    CASE
        WHEN o.days_late <= 0 THEN '1. вовремя'
        WHEN o.days_late <= 3 THEN '2. 1-3 дня'
        WHEN o.days_late <= 7 THEN '3. 4-7 дней'
        ELSE                       '4. 8+ дней'
    END AS delay_bucket,

    COUNT(*) AS orders,
    COUNT(o.review_score) AS reviewed_orders,
    COALESCE(SUM(o.review_score), 0) AS review_score_sum,
    COUNT(*) FILTER (WHERE o.review_score <= 2) AS low_score_orders
FROM dwh.fact_orders o
WHERE o.order_status = 'delivered'
  AND o.days_late IS NOT NULL
  AND o.purchase_date BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY 1, 2;


-- 5 Какие продавцы приносят выручку, у кого проблемы с доставкой и оценками?
CREATE MATERIALIZED VIEW mart.seller_performance AS
WITH seller_items AS (
    SELECT
        oi.seller_id,
        oi.order_id,
        COUNT(*) AS items_sold,
        SUM(oi.price) AS revenue
    FROM dwh.fact_order_items oi
    JOIN dwh.fact_orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
      AND o.purchase_date BETWEEN '2017-01-01' AND '2018-08-31'
    GROUP BY oi.seller_id, oi.order_id
)
SELECT
    si.seller_id,
    s.seller_state,
    s.seller_city,

    COUNT(*) AS orders,
    SUM(si.items_sold) AS items_sold,
    SUM(si.revenue) AS revenue,

    COUNT(*) FILTER (WHERE o.is_delayed IS NOT NULL) AS delivered_orders,
    COUNT(*) FILTER (WHERE o.is_delayed) AS delayed_orders,

    COUNT(o.review_score) AS reviewed_orders,
    COALESCE(SUM(o.review_score), 0) AS review_score_sum
FROM seller_items si
JOIN dwh.fact_orders o
    ON si.order_id = o.order_id
JOIN dwh.dim_sellers s
    ON si.seller_id = s.seller_id
GROUP BY si.seller_id, s.seller_state, s.seller_city;


-- 6 Делают ли покупатели повторные покупки?
CREATE MATERIALIZED VIEW mart.customer_cohorts AS
WITH customer_months AS (
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.purchase_date)::DATE AS order_month
    FROM dwh.fact_orders o
    JOIN dwh.dim_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
first_purchase AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_unique_id
)
SELECT
    f.cohort_month,
    ( (EXTRACT(YEAR FROM cm.order_month) * 12 + EXTRACT(MONTH FROM cm.order_month))
    - (EXTRACT(YEAR FROM f.cohort_month) * 12 + EXTRACT(MONTH FROM f.cohort_month)) )::INT AS month_number,
    COUNT(*) AS customers
FROM customer_months cm
JOIN first_purchase f
    ON cm.customer_unique_id = f.customer_unique_id
WHERE f.cohort_month BETWEEN '2017-01-01' AND '2018-08-01'
  AND cm.order_month <= '2018-08-01'
GROUP BY 1, 2;