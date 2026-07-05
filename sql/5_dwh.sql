CREATE TABLE dwh.dim_customers
(
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

INSERT INTO dwh.dim_customers
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.customers;

SELECT COUNT(*)
FROM staging.customers;

SELECT COUNT(*)
FROM dwh.dim_customers;

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls
FROM dwh.dim_customers;

SELECT customer_id, COUNT(*)
FROM dwh.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


CREATE TABLE dwh.dim_products
(
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

INSERT INTO dwh.dim_products
SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM staging.products;

SELECT COUNT(*)
FROM staging.products;

SELECT COUNT(*)
FROM dwh.dim_products;

SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls
FROM dwh.dim_products;

SELECT product_id, COUNT(*)
FROM dwh.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;


CREATE TABLE dwh.dim_sellers
(
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

INSERT INTO dwh.dim_sellers
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers;

SELECT COUNT(*)
FROM staging.sellers;

SELECT COUNT(*)
FROM dwh.dim_sellers;

SELECT
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls
FROM dwh.dim_sellers;

SELECT seller_id, COUNT(*)
FROM dwh.dim_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


CREATE TABLE dwh.fact_orders
(
    order_id TEXT PRIMARY KEY,
    customer_id TEXT REFERENCES dwh.dim_customers(customer_id),

    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    total_order_amount NUMERIC,
    total_freight NUMERIC,
    items_count INT,
    delivery_days INT,
    is_delayed BOOL
);

INSERT INTO dwh.fact_orders
SELECT
    o.order_id,
    o.customer_id,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(SUM(oi.price), 0) AS total_order_amount,
    COALESCE(SUM(oi.freight_value), 0) AS total_freight,
    COUNT(oi.product_id) AS items_count,
    (o.order_delivered_customer_date::DATE - o.order_purchase_timestamp::DATE) AS delivery_days,
    (o.order_delivered_customer_date > o.order_estimated_delivery_date) AS is_delayed
FROM staging.orders o
LEFT JOIN staging.order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date;

SELECT COUNT(*)
FROM dwh.fact_orders;

SELECT COUNT(*)
FROM staging.orders;

SELECT *
FROM dwh.fact_orders
LIMIT 10;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE total_order_amount IS NULL) AS total_amount_nulls,
    COUNT(*) FILTER (WHERE items_count IS NULL) AS items_count_nulls
FROM dwh.fact_orders;

SELECT *
FROM dwh.fact_orders
WHERE total_order_amount < 0
   OR total_freight < 0
   OR items_count < 0;

SELECT order_id, COUNT(*)
FROM dwh.fact_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT *
FROM dwh.fact_orders
WHERE delivery_days < 0;


CREATE TABLE dwh.fact_order_items
(
    order_id TEXT REFERENCES dwh.fact_orders(order_id),
    order_item_id INT,
    product_id TEXT REFERENCES dwh.dim_products(product_id),
    seller_id TEXT REFERENCES dwh.dim_sellers(seller_id),

    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC,
    quantity INT,

    PRIMARY KEY (order_id, order_item_id)
);

INSERT INTO dwh.fact_order_items
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,

    CAST(shipping_limit_date AS TIMESTAMP),
    CAST(price AS NUMERIC),
    CAST(freight_value AS NUMERIC),
    1 AS quantity
FROM staging.order_items;

SELECT COUNT(*)
FROM staging.order_items;

SELECT COUNT(*)
FROM dwh.fact_order_items;

SELECT *
FROM dwh.fact_order_items
LIMIT 10;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS order_item_id_nulls,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
    COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS shipping_limit_date_nulls,
    COUNT(*) FILTER (WHERE price IS NULL) AS price_nulls,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS freight_value_nulls
FROM dwh.fact_order_items;

SELECT COUNT(*)
FROM dwh.fact_order_items oi
LEFT JOIN dwh.fact_orders o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT *
FROM dwh.fact_order_items
WHERE freight_value < 0
OR price <= 0;;

SELECT order_id, order_item_id, COUNT(*)
FROM dwh.fact_order_items
GROUP BY 1,2
HAVING COUNT(*) > 1;