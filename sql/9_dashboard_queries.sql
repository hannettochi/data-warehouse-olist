-- Запросы виджетов дашборда Redash


SELECT
    SUM(orders) AS orders,
    SUM(revenue) AS revenue,
    ROUND(SUM(revenue) / NULLIF(SUM(orders), 0), 2) AS avg_order_value,
    ROUND(100.0 * SUM(delayed_orders) / NULLIF(SUM(delivered_orders), 0), 2) AS delayed_pct,
    ROUND(SUM(review_score_sum)::NUMERIC / NULLIF(SUM(reviewed_orders), 0), 2) AS avg_review_score
FROM mart.daily_sales
WHERE date_day BETWEEN '{{ period.start }}' AND '{{ period.end }}';


SELECT
    month_start AS month,
    SUM(orders) AS orders,
    SUM(revenue) AS revenue,
    ROUND(SUM(revenue) / NULLIF(SUM(orders), 0), 2) AS avg_order_value
FROM mart.daily_sales
WHERE date_day BETWEEN '{{ period.start }}' AND '{{ period.end }}'
GROUP BY month_start
ORDER BY month_start;


SELECT
    day_of_week,
    ROUND(AVG(revenue), 2) AS avg_daily_revenue
FROM mart.daily_sales
WHERE date_day BETWEEN '{{ period.start }}' AND '{{ period.end }}'
GROUP BY day_of_week
ORDER BY day_of_week;


SELECT
    state,
    SUM(orders) AS orders,
    SUM(revenue) AS revenue,
    ROUND(100.0 * SUM(delayed_orders) / NULLIF(SUM(delivered_orders), 0), 2) AS delayed_pct,
    ROUND(SUM(delivery_days_sum)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 1) AS avg_delivery_days,
    ROUND(SUM(review_score_sum)::NUMERIC / NULLIF(SUM(reviewed_orders), 0), 2) AS avg_review_score
FROM mart.daily_sales_by_state
WHERE date_day BETWEEN '{{ period.start }}' AND '{{ period.end }}'
GROUP BY state
ORDER BY revenue DESC;


SELECT DISTINCT state
FROM mart.daily_sales_by_state
ORDER BY state;


SELECT
    month_start AS month,
    SUM(orders) AS orders,
    SUM(revenue) AS revenue
FROM mart.daily_sales_by_state
WHERE date_day BETWEEN '{{ period.start }}' AND '{{ period.end }}'
  AND state = '{{ state }}'
GROUP BY month_start
ORDER BY month_start;


SELECT
    category,
    SUM(revenue) AS revenue,
    SUM(items_sold) AS items_sold
FROM mart.daily_category_sales
WHERE date_day BETWEEN '{{ period.start }}' AND '{{ period.end }}'
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;


SELECT
    delay_bucket,
    SUM(orders) AS orders,
    ROUND(SUM(review_score_sum)::NUMERIC / NULLIF(SUM(reviewed_orders), 0), 2) AS avg_review_score,
    ROUND(100.0 * SUM(low_score_orders) / NULLIF(SUM(reviewed_orders), 0), 2) AS low_score_pct
FROM mart.reviews_by_delay
WHERE date_day BETWEEN '{{ period.start }}' AND '{{ period.end }}'
GROUP BY delay_bucket
ORDER BY delay_bucket;


SELECT
    seller_id,
    seller_state,
    orders,
    revenue,
    ROUND(100.0 * delayed_orders / NULLIF(delivered_orders, 0), 2) AS delayed_pct,
    ROUND(review_score_sum::NUMERIC / NULLIF(reviewed_orders, 0), 2) AS avg_review_score
FROM mart.seller_performance
WHERE orders >= 30
ORDER BY revenue DESC
LIMIT 20;


SELECT
    c.cohort_month,
    c.month_number,
    c.customers,
    base.customers AS cohort_size,
    ROUND(100.0 * c.customers / base.customers, 2) AS retention_pct
FROM mart.customer_cohorts c
JOIN mart.customer_cohorts base
    ON base.cohort_month = c.cohort_month
   AND base.month_number = 0
ORDER BY c.cohort_month, c.month_number;
