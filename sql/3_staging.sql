-- Orders
CREATE TABLE staging.orders
(
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

INSERT INTO staging.orders
SELECT
    order_id,
    customer_id,
    order_status,
    CAST(order_purchase_timestamp AS TIMESTAMP),
    CAST(order_approved_at AS TIMESTAMP),
    CAST(order_delivered_carrier_date AS TIMESTAMP),
    CAST(order_delivered_customer_date AS TIMESTAMP),
    CAST(order_estimated_delivery_date AS TIMESTAMP)
FROM raw.orders;

SELECT COUNT(*) FROM raw.orders;
SELECT COUNT(*) FROM staging.orders;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS order_purchase_timestamp_nulls
FROM staging.orders;


-- Customers
CREATE TABLE staging.customers
(
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

INSERT INTO staging.customers
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM raw.customers;

SELECT COUNT(*) FROM raw.customers;
SELECT COUNT(*) FROM staging.customers;

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS customer_unique_id_nulls,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS customer_zip_code_prefix_nulls
FROM staging.customers;


-- Order items
CREATE TABLE staging.order_items
(
    order_id TEXT,
    order_item_id INT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

INSERT INTO staging.order_items
SELECT
    order_id,
    CAST(order_item_id AS INT),
    product_id,
    seller_id,
    CAST(shipping_limit_date AS TIMESTAMP),
    CAST(price AS NUMERIC),
    CAST(freight_value AS NUMERIC)
FROM raw.order_items;

SELECT COUNT(*) FROM raw.order_items;
SELECT COUNT(*) FROM staging.order_items;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS order_item_id_nulls,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
    COUNT(*) FILTER (WHERE price IS NULL) AS price_nulls,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS freight_value_nulls
FROM staging.order_items;


-- Payments
CREATE TABLE staging.payments
(
    order_id TEXT,
    payment_sequential INT,
    payment_type TEXT,
    payment_installments INT,
    payment_value NUMERIC
);

INSERT INTO staging.payments
SELECT
    order_id,
    CAST(payment_sequential AS INT),
    payment_type,
    CAST(payment_installments AS INT),
    CAST(payment_value AS NUMERIC)
FROM raw.payments;

SELECT COUNT(*) FROM raw.payments;
SELECT COUNT(*) FROM staging.payments;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE payment_sequential IS NULL) AS payment_sequential_nulls,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS payment_type_nulls,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS payment_value_nulls
FROM staging.payments;


-- Products
CREATE TABLE staging.products
(
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

INSERT INTO staging.products
SELECT
    product_id,
    product_category_name,
    CAST(product_name_lenght AS INT),
    CAST(product_description_lenght AS INT),
    CAST(product_photos_qty AS INT),
    CAST(product_weight_g AS INT),
    CAST(product_length_cm AS INT),
    CAST(product_height_cm AS INT),
    CAST(product_width_cm AS INT)
FROM raw.products;

SELECT COUNT(*) FROM raw.products;
SELECT COUNT(*) FROM staging.products;

SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS product_category_name_nulls,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS product_weight_g_nulls,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS product_length_cm_nulls,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS product_height_cm_nulls,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS product_width_cm_nulls
FROM staging.products;


-- Sellers
CREATE TABLE staging.sellers
(
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

INSERT INTO staging.sellers
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM raw.sellers;

SELECT COUNT(*) FROM raw.sellers;
SELECT COUNT(*) FROM staging.sellers;

SELECT
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
    COUNT(*) FILTER (WHERE seller_zip_code_prefix IS NULL) AS seller_zip_code_prefix_nulls
FROM staging.sellers;


-- Reviews
CREATE TABLE staging.reviews
(
    review_id TEXT,
    order_id TEXT,
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

INSERT INTO staging.reviews
SELECT
    review_id,
    order_id,
    CAST(review_score AS INT),
    review_comment_title,
    review_comment_message,
    CAST(review_creation_date AS TIMESTAMP),
    CAST(review_answer_timestamp AS TIMESTAMP)
FROM raw.reviews;

SELECT COUNT(*) FROM raw.reviews;
SELECT COUNT(*) FROM staging.reviews;

SELECT
    COUNT(*) FILTER (WHERE review_id IS NULL) AS review_id_nulls,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS review_score_nulls
FROM staging.reviews;


-- Geolocation
CREATE TABLE staging.geolocation
(
    geolocation_zip_code_prefix TEXT,
    geolocation_lat DOUBLE PRECISION,
    geolocation_lng DOUBLE PRECISION,
    geolocation_city TEXT,
    geolocation_state TEXT
);

INSERT INTO staging.geolocation
SELECT
    geolocation_zip_code_prefix,
    CAST(geolocation_lat AS DOUBLE PRECISION),
    CAST(geolocation_lng AS DOUBLE PRECISION),
    geolocation_city,
    geolocation_state
FROM raw.geolocation;

SELECT COUNT(*) FROM raw.geolocation;
SELECT COUNT(*) FROM staging.geolocation;

SELECT
    COUNT(*) FILTER (WHERE geolocation_zip_code_prefix IS NULL) AS geolocation_zip_code_prefix_nulls,
    COUNT(*) FILTER (WHERE geolocation_lat IS NULL) AS geolocation_lat_nulls,
    COUNT(*) FILTER (WHERE geolocation_lng IS NULL) AS geolocation_lng_nulls
FROM staging.geolocation;


-- Translation
CREATE TABLE staging.product_category_name_translation
(
    product_category_name TEXT,
    product_category_name_english TEXT
);

INSERT INTO staging.product_category_name_translation
SELECT
    product_category_name,
    product_category_name_english
FROM raw.product_category_name_translation;

SELECT COUNT(*) FROM raw.product_category_name_translation;
SELECT COUNT(*) FROM staging.product_category_name_translation;

SELECT
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS product_category_name_nulls,
    COUNT(*) FILTER (WHERE product_category_name_english IS NULL) AS product_category_name_english_nulls
FROM staging.product_category_name_translation;