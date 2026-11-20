-- Orders
SELECT order_id, COUNT(*)
FROM staging.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT customer_id, COUNT(*)
FROM staging.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM staging.products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT seller_id, COUNT(*)
FROM staging.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- дубликаты
SELECT review_id, COUNT(*)
FROM staging.reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

SELECT order_id, order_item_id, COUNT(*)
FROM staging.order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT order_id, payment_sequential, COUNT(*)
FROM staging.payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


SELECT *
FROM staging.orders
WHERE order_delivered_customer_date < order_purchase_timestamp
   OR order_approved_at < order_purchase_timestamp;

-- этапы доставки в неправильном порядке
SELECT *
FROM staging.orders
WHERE order_delivered_carrier_date < order_approved_at
   OR order_delivered_customer_date < order_delivered_carrier_date;

-- заказы без товаров
SELECT o.order_id, o.order_status
FROM staging.orders o
LEFT JOIN staging.order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- доставленные заказы без даты получения покупателем
SELECT *
FROM staging.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

SELECT *
FROM staging.orders
WHERE order_delivered_customer_date < order_purchase_timestamp
   OR order_approved_at < order_purchase_timestamp
   OR order_delivered_carrier_date < order_purchase_timestamp;

-- записи без платежей
SELECT *
FROM staging.payments
WHERE payment_value <= 0
   OR payment_installments <= 0;

SELECT *
FROM staging.payments
WHERE payment_sequential < 1;

SELECT *
FROM staging.order_items
WHERE price < 0
   OR freight_value < 0;

SELECT *
FROM staging.order_items
WHERE shipping_limit_date IS NULL;

SELECT *
FROM staging.reviews
WHERE review_score NOT BETWEEN 1 AND 5;

SELECT *
FROM staging.products
WHERE product_weight_g < 0
   OR product_height_cm < 0
   OR product_width_cm < 0
   OR product_length_cm < 0;


SELECT o.*
FROM staging.orders o
LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT oi.*
FROM staging.order_items oi
LEFT JOIN staging.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT oi.*
FROM staging.order_items oi
LEFT JOIN staging.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT p.*
FROM staging.payments p
LEFT JOIN staging.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT r.*
FROM staging.reviews r
LEFT JOIN staging.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;