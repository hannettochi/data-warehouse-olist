-- заказы и выручка = fact_orders с теми же правилами
SELECT
    (SELECT SUM(orders)  FROM mart.daily_sales) AS mart_orders,
    (SELECT SUM(revenue) FROM mart.daily_sales) AS mart_revenue,
    (SELECT COUNT(*) FROM dwh.fact_orders
      WHERE order_status NOT IN ('canceled', 'unavailable')
        AND purchase_date BETWEEN '2017-01-01' AND '2018-08-31') AS dwh_orders,
    (SELECT SUM(total_order_amount) FROM dwh.fact_orders
      WHERE order_status NOT IN ('canceled', 'unavailable')
        AND purchase_date BETWEEN '2017-01-01' AND '2018-08-31') AS dwh_revenue;

-- нет пропущенных дней
SELECT
    COUNT(*)                     AS rows_in_mart,
    COUNT(DISTINCT date_day)     AS distinct_days,
    '2018-08-31'::DATE - '2017-01-01'::DATE + 1 AS expected_days
FROM mart.daily_sales;

-- by_state в сумме даёт daily_sales
SELECT
    (SELECT SUM(orders)  FROM mart.daily_sales_by_state) - (SELECT SUM(orders)  FROM mart.daily_sales) AS orders_diff,
    (SELECT SUM(revenue) FROM mart.daily_sales_by_state) - (SELECT SUM(revenue) FROM mart.daily_sales) AS revenue_diff;

-- выручка совпадает, а orders нет
SELECT
    (SELECT SUM(revenue) FROM mart.daily_category_sales) - (SELECT SUM(revenue) FROM mart.daily_sales) AS revenue_diff,
    (SELECT SUM(orders)  FROM mart.daily_category_sales) AS orders_by_categories,
    (SELECT SUM(orders)  FROM mart.daily_sales)          AS orders;

-- выручка совпадает с daily_sales
SELECT
    (SELECT SUM(revenue) FROM mart.seller_performance) - (SELECT SUM(revenue) FROM mart.daily_sales) AS revenue_diff;


SELECT
    (SELECT SUM(orders) FROM mart.reviews_by_delay)            AS mart_delivered,
    (SELECT SUM(delivered_orders) FROM mart.daily_sales)       AS daily_delivered;

SELECT *
FROM mart.customer_cohorts
WHERE month_number < 0;

SELECT
    cohort_month,
    customers AS cohort_size
FROM mart.customer_cohorts
WHERE month_number = 0
ORDER BY cohort_month;
