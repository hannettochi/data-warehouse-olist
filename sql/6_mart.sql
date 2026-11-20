DROP MATERIALIZED VIEW IF EXISTS mart.daily_category_sales;
DROP MATERIALIZED VIEW IF EXISTS mart.daily_sales;


-- продажи по дням
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

    COUNT(o.order_id) AS orders_count,
    COALESCE(SUM(o.total_order_amount), 0) AS revenue,
    COALESCE(SUM(o.total_freight), 0) AS freight,
    COALESCE(SUM(o.items_count), 0) AS items_count,

    COUNT(o.order_id) FILTER (
        WHERE o.is_delayed IS NOT NULL
    ) AS delivered_orders,

    COUNT(o.order_id) FILTER (
        WHERE o.is_delayed = TRUE
    ) AS delayed_orders,

    COALESCE(SUM(o.delivery_days), 0) AS delivery_days_sum,

    COUNT(o.review_score) AS reviewed_orders,
    COALESCE(SUM(o.review_score), 0) AS review_score_sum

FROM dwh.dim_date d
LEFT JOIN valid_orders o
    ON o.purchase_date = d.date_day

GROUP BY
    d.date_day,
    d.week_start,
    d.month_start,
    d.year,
    d.day_of_week,
    d.is_weekend;


-- продажи по категориям товаров
CREATE MATERIALIZED VIEW mart.daily_category_sales AS

SELECT
    o.purchase_date AS date_day,
    DATE_TRUNC('month', o.purchase_date)::DATE AS month_start,

    COALESCE(
        p.product_category_name_english,
        'unknown'
    ) AS category,

    COUNT(*) AS items_sold,
    SUM(oi.price) AS item_revenue,
    COUNT(DISTINCT oi.order_id) AS orders_count

FROM dwh.fact_order_items oi

JOIN dwh.fact_orders o
    ON oi.order_id = o.order_id

JOIN dwh.dim_products p
    ON oi.product_id = p.product_id

WHERE o.order_status NOT IN ('canceled', 'unavailable')

GROUP BY
    o.purchase_date,
    DATE_TRUNC('month', o.purchase_date)::DATE,
    p.product_category_name_english;



-- проверки
SELECT
    (SELECT SUM(orders_count)
     FROM mart.daily_sales) AS mart_orders,

    (SELECT SUM(revenue)
     FROM mart.daily_sales) AS mart_revenue,

    (SELECT COUNT(*)
     FROM dwh.fact_orders
     WHERE order_status NOT IN ('canceled', 'unavailable')
    ) AS dwh_orders,

    (SELECT SUM(total_order_amount)
     FROM dwh.fact_orders
     WHERE order_status NOT IN ('canceled', 'unavailable')
    ) AS dwh_revenue;


SELECT
    COUNT(*) AS rows_in_mart,
    COUNT(DISTINCT date_day) AS distinct_days,
    (SELECT COUNT(*) FROM dwh.dim_date) AS expected_days
FROM mart.daily_sales;


SELECT
    (SELECT SUM(item_revenue)
     FROM mart.daily_category_sales) AS mart_item_revenue,

    (SELECT SUM(oi.price)
     FROM dwh.fact_order_items oi
     JOIN dwh.fact_orders o
         ON oi.order_id = o.order_id
     WHERE o.order_status NOT IN ('canceled', 'unavailable')
    ) AS dwh_item_revenue;


SELECT *
FROM mart.daily_sales
WHERE date_day IS NULL
   OR orders_count IS NULL
   OR revenue IS NULL;

SELECT *
FROM mart.daily_category_sales
WHERE date_day IS NULL
   OR category IS NULL
   OR items_sold IS NULL
   OR item_revenue IS NULL;


SELECT *
FROM mart.daily_sales
WHERE orders_count < 0
   OR revenue < 0
   OR items_count < 0;

SELECT *
FROM mart.daily_category_sales
WHERE items_sold < 0
   OR item_revenue < 0;
