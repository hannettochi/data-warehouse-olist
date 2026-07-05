-- KPI
SELECT
    COUNT(*) AS total_orders,
    ROUND(AVG(items_count), 2) AS average_items_count,
    SUM(total_order_amount) AS overall_revenue,
    ROUND(AVG(total_order_amount), 2) AS average_order_revenue,
    ROUND(AVG(total_freight), 2) AS average_freight_cost
FROM dwh.fact_orders;


-- delivery
SELECT
    ROUND(AVG(delivery_days), 0) AS average_delivery_days,
    ROUND(
        COUNT(*) FILTER (WHERE is_delayed) * 100.0 /
        COUNT(*) FILTER (WHERE is_delayed IS NOT NULL),
        2
    ) AS delayed_orders_percentage
FROM dwh.fact_orders;


-- sales trends
SELECT
    TO_CHAR(DATE_TRUNC('month', order_purchase_timestamp), 'Month YYYY') AS month,
    COUNT(*) AS orders_amount,
    SUM(total_order_amount) AS revenue
FROM dwh.fact_orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY DATE_TRUNC('month', order_purchase_timestamp);

SELECT
    TO_CHAR(DATE_TRUNC('month', order_purchase_timestamp), 'Month YYYY') AS month,
    ROUND(AVG(total_order_amount), 2) AS average_order_revenue
FROM dwh.fact_orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY DATE_TRUNC('month', order_purchase_timestamp);


-- geography
SELECT
    c.customer_state,
    COUNT(*) AS orders_amount
FROM dwh.fact_orders fo
INNER JOIN dwh.dim_customers c
    ON fo.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY orders_amount DESC;

SELECT
    c.customer_city,
    COUNT(*) AS orders_amount
FROM dwh.fact_orders fo
INNER JOIN dwh.dim_customers c
    ON fo.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY orders_amount DESC
LIMIT 10;

SELECT
    c.customer_state,
    SUM(fo.total_order_amount) AS revenue
FROM dwh.fact_orders fo
INNER JOIN dwh.dim_customers c
    ON fo.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 5;


-- customer behavior
SELECT
    customer_id,
    COUNT(order_id) AS total_orders
FROM dwh.fact_orders
GROUP BY customer_id
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;


-- basket analysis
SELECT
    items_count,
    COUNT(order_id) AS total_orders
FROM dwh.fact_orders
GROUP BY items_count
ORDER BY items_count;


-- seller performance
SELECT
    seller_id,
    COUNT(DISTINCT order_id) AS orders_amount,
    SUM(quantity) AS sold_products_amount,
    SUM(price) AS revenue
FROM dwh.fact_order_items
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;