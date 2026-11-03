DROP TABLE IF EXISTS dwh.fact_order_items CASCADE;
DROP TABLE IF EXISTS dwh.fact_orders CASCADE;
DROP TABLE IF EXISTS dwh.dim_date CASCADE;
DROP TABLE IF EXISTS dwh.dim_customers CASCADE;
DROP TABLE IF EXISTS dwh.dim_products CASCADE;
DROP TABLE IF EXISTS dwh.dim_sellers CASCADE;


-- dim_customers
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

SELECT COUNT(*) FROM staging.customers;
SELECT COUNT(*) FROM dwh.dim_customers;

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls
FROM dwh.dim_customers;

SELECT customer_id, COUNT(*)
FROM dwh.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- dim_products
CREATE TABLE dwh.dim_products
(
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_category_name_english TEXT,
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
    p.product_id,
    p.product_category_name,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown'),
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM staging.products p
LEFT JOIN staging.product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

SELECT COUNT(*) FROM staging.products;
SELECT COUNT(*) FROM dwh.dim_products;

SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls
FROM dwh.dim_products;

SELECT product_id, COUNT(*)
FROM dwh.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Категории без перевода
SELECT product_category_name, COUNT(*)
FROM dwh.dim_products
WHERE product_category_name IS NOT NULL
  AND product_category_name_english = product_category_name
GROUP BY product_category_name;


-- dim_sellers
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

SELECT COUNT(*) FROM staging.sellers;
SELECT COUNT(*) FROM dwh.dim_sellers;

SELECT
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls
FROM dwh.dim_sellers;

SELECT seller_id, COUNT(*)
FROM dwh.dim_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- dim_date — календарь
CREATE TABLE dwh.dim_date
(
    date_day DATE PRIMARY KEY,
    year INT,
    quarter INT,
    month INT,
    month_start DATE,
    week_start DATE,
    day_of_week INT,      -- 1 = понедельник ... 7 = воскресенье
    is_weekend BOOL
);

INSERT INTO dwh.dim_date
SELECT
    d::DATE,
    EXTRACT(YEAR FROM d)::INT,
    EXTRACT(QUARTER FROM d)::INT,
    EXTRACT(MONTH FROM d)::INT,
    DATE_TRUNC('month', d)::DATE,
    DATE_TRUNC('week', d)::DATE,
    EXTRACT(ISODOW FROM d)::INT,
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2016-01-01'::DATE, '2018-12-31'::DATE, INTERVAL '1 day') AS d;

SELECT MIN(date_day), MAX(date_day), COUNT(*)
FROM dwh.dim_date;


-- fact_orders: гранулярность - один заказ
CREATE TABLE dwh.fact_orders
(
    order_id TEXT PRIMARY KEY,
    customer_id TEXT REFERENCES dwh.dim_customers(customer_id),
    order_status TEXT,

    order_purchase_timestamp TIMESTAMP,
    purchase_date DATE REFERENCES dwh.dim_date(date_day),
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    total_order_amount NUMERIC,
    total_freight NUMERIC,
    items_count INT,

    payment_value NUMERIC,       
    main_payment_type TEXT,      
    payment_installments INT,    

    review_score INT,            

    delivery_days INT,
    days_late INT,      -- >0 — опоздание в днях, <=0 — вовремя/раньше
    is_delayed BOOL
);

INSERT INTO dwh.fact_orders
WITH items AS (
    SELECT
        order_id,
        SUM(price) AS total_order_amount,
        SUM(freight_value) AS total_freight,
        COUNT(*) AS items_count
    FROM staging.order_items
    GROUP BY order_id
),
payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value,
        (ARRAY_AGG(payment_type ORDER BY payment_value DESC))[1] AS main_payment_type,
        MAX(payment_installments) AS payment_installments
    FROM staging.payments
    GROUP BY order_id
),
reviews AS (
    -- у части заказов несколько отзывов: берём самый поздний ответ
    SELECT DISTINCT ON (order_id)
        order_id,
        review_score
    FROM staging.reviews
    ORDER BY order_id, review_answer_timestamp DESC NULLS LAST
)
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,

    o.order_purchase_timestamp,
    o.order_purchase_timestamp::DATE,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(i.total_order_amount, 0),
    COALESCE(i.total_freight, 0),
    COALESCE(i.items_count, 0),

    p.payment_value,
    p.main_payment_type,
    p.payment_installments,

    r.review_score,

    o.order_delivered_customer_date::DATE - o.order_purchase_timestamp::DATE,
    o.order_delivered_customer_date::DATE - o.order_estimated_delivery_date::DATE,
    o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE
FROM staging.orders o
LEFT JOIN items    i ON o.order_id = i.order_id
LEFT JOIN payments p ON o.order_id = p.order_id
LEFT JOIN reviews  r ON o.order_id = r.order_id;


-- Проверки fact_orders

-- 1 строк столько же, сколько заказов
SELECT
    (SELECT COUNT(*) FROM staging.orders) AS staging_orders,
    (SELECT COUNT(*) FROM dwh.fact_orders) AS fact_orders;

-- 2 выручка сходится с источником
SELECT
    (SELECT SUM(price) FROM staging.order_items) AS staging_revenue,
    (SELECT SUM(total_order_amount) FROM dwh.fact_orders) AS fact_revenue;

-- 3. распределение по статусам
SELECT order_status, COUNT(*)
FROM dwh.fact_orders
GROUP BY order_status
ORDER BY COUNT(*) DESC;

-- 4 сколько заказов расходятся больше чем на 1
SELECT
    COUNT(*) FILTER (WHERE ABS(payment_value - (total_order_amount + total_freight)) > 1) AS mismatched_orders,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS orders_without_payment
FROM dwh.fact_orders;

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

SELECT *
FROM dwh.fact_orders
WHERE delivery_days < 0;


-- fact_order_items каждая строка = один товар
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
    shipping_limit_date,
    price,
    freight_value,
    1 AS quantity
FROM staging.order_items;

SELECT COUNT(*) FROM staging.order_items;
SELECT COUNT(*) FROM dwh.fact_order_items;

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
   OR price <= 0;

SELECT order_id, order_item_id, COUNT(*)
FROM dwh.fact_order_items
GROUP BY 1, 2
HAVING COUNT(*) > 1;