-- Orders

CREATE TABLE raw.orders
(
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

COPY raw.orders
FROM '/Users/hannettochi/Downloads/archive/olist_orders_dataset.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.orders;

SELECT *
FROM raw.orders
LIMIT 10;

SELECT
  COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
  COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
  COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS date_nulls
FROM raw.orders;


-- Customers
CREATE TABLE raw.customers
(
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

COPY raw.customers
FROM '/Users/hannettochi/Downloads/archive/olist_customers_dataset.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.customers;

SELECT *
FROM raw.customers
LIMIT 10;

SELECT
  COUNT(*) FILTER (WHERE customer_id IS NULL) AS customer_id_nulls,
  COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS customer_unique_id_nulls,
  COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS zip_code_prefix_nulls
FROM raw.customers;


-- Order Items
CREATE TABLE raw.order_items
(
    order_id TEXT,
    order_item_id TEXT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price TEXT,
    freight_value TEXT
);

COPY raw.order_items
FROM '/Users/hannettochi/Downloads/archive/olist_order_items_dataset.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.order_items;

SELECT *
FROM raw.order_items
LIMIT 10;

SELECT
  COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
  COUNT(*) FILTER (WHERE order_item_id IS NULL) AS order_item_id_nulls,
  COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
  COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
  COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS shipping_limit_date_nulls,
  COUNT(*) FILTER (WHERE price IS NULL) AS price_nulls,
  COUNT(*) FILTER (WHERE freight_value IS NULL) AS freight_value_nulls
FROM raw.order_items;


-- Payments
CREATE TABLE raw.payments
(
    order_id TEXT,
    payment_sequential TEXT,
    payment_type TEXT,
    payment_installments TEXT,
    payment_value TEXT
);

COPY raw.payments
FROM '/Users/hannettochi/Downloads/archive/olist_order_payments_dataset.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.payments;

SELECT *
FROM raw.payments
LIMIT 10;

SELECT
  COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
  COUNT(*) FILTER (WHERE payment_sequential IS NULL) AS payment_sequential_nulls,
  COUNT(*) FILTER (WHERE payment_type IS NULL) AS payment_type_nulls,
  COUNT(*) FILTER (WHERE payment_installments IS NULL) AS payment_installments_nulls,
  COUNT(*) FILTER (WHERE payment_value IS NULL) AS payment_value_nulls
FROM raw.payments;


-- Products
CREATE TABLE raw.products
(
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght TEXT,
    product_description_lenght TEXT,
    product_photos_qty TEXT,
    product_weight_g TEXT,
    product_length_cm TEXT,
    product_height_cm TEXT,
    product_width_cm TEXT
);

COPY raw.products
FROM '/Users/hannettochi/Downloads/archive/olist_products_dataset.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.products;

SELECT *
FROM raw.products
LIMIT 10;

SELECT
  COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_nulls,
  COUNT(*) FILTER (WHERE product_category_name IS NULL) AS product_category_name_nulls,
  COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS product_weight_g_nulls,
  COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS product_length_cm_nulls,
  COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS product_height_cm_nulls,
  COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS product_width_cm_nulls
FROM raw.products;


-- Sellers
CREATE TABLE raw.sellers
(
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

COPY raw.sellers
FROM '/Users/hannettochi/Downloads/archive/olist_sellers_dataset.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.sellers;

SELECT *
FROM raw.sellers
LIMIT 10;

SELECT
  COUNT(*) FILTER (WHERE seller_id IS NULL) AS seller_id_nulls,
  COUNT(*) FILTER (WHERE seller_zip_code_prefix IS NULL) AS seller_zip_code_prefix_nulls
FROM raw.sellers;


-- Reviews
CREATE TABLE raw.reviews
(
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

COPY raw.reviews
FROM '/Users/hannettochi/Downloads/archive/olist_order_reviews_dataset.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.reviews;

SELECT *
FROM raw.reviews
LIMIT 10;

SELECT
  COUNT(*) FILTER (WHERE review_id IS NULL) AS review_id_nulls,
  COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
  COUNT(*) FILTER (WHERE review_score IS NULL) AS review_score_nulls
FROM raw.reviews;


-- Geolocation
CREATE TABLE raw.geolocation
(
    geolocation_zip_code_prefix TEXT,
    geolocation_lat TEXT,
    geolocation_lng TEXT,
    geolocation_city TEXT,
    geolocation_state TEXT
);

COPY raw.geolocation
FROM '/Users/hannettochi/Downloads/archive/olist_geolocation_dataset.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.geolocation;

SELECT *
FROM raw.geolocation
LIMIT 10;

SELECT
    COUNT(*) FILTER (WHERE geolocation_zip_code_prefix IS NULL) AS geolocation_zip_code_prefix_nulls,
    COUNT(*) FILTER (WHERE geolocation_lat IS NULL) AS geolocation_lat_nulls,
    COUNT(*) FILTER (WHERE geolocation_lng IS NULL) AS geolocation_lng_nulls
FROM raw.geolocation;


-- Translations
CREATE TABLE raw.translations
(
    product_category_name TEXT,
    product_category_name_english TEXT
);

COPY raw.translations
FROM '/Users/hannettochi/Downloads/archive/product_category_name_translation.csv'
CSV HEADER;

SELECT COUNT(*)
FROM raw.translations;

SELECT *
FROM raw.translations
LIMIT 10;

SELECT
  COUNT(*) FILTER (WHERE product_category_name IS NULL) AS product_category_name_nulls,
  COUNT(*) FILTER (WHERE product_category_name_english IS NULL) AS product_category_name_english_nulls
FROM raw.translations;