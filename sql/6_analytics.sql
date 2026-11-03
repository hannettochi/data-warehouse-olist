-- вопросы, которым нужны данные по отдельным заказам и покупателям


-- 1 Влияет ли опыт первого заказа на повторную покупку?
-- *первые заказы до 2018-03-01 (у более поздних покупателей не было времени
-- сделать повторную покупку и доля была бы занижена)
-- *повторная покупка — заказ в более поздний день (заказы в тот же день — разбитая корзина)
-- *это корреляция, на повторную покупку также влияют и другие факторы

-- повторная покупка в зависимости от доставки первого заказа
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        fo.order_id,
        fo.purchase_date,
        fo.is_delayed,
        fo.review_score,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY fo.order_purchase_timestamp, fo.order_id   -- order_id: на случай двух заказов в одну секунду
        ) AS rn,
        MAX(fo.purchase_date) OVER (PARTITION BY c.customer_unique_id) AS last_purchase_date
    FROM dwh.fact_orders fo
    JOIN dwh.dim_customers c
        ON c.customer_id = fo.customer_id
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
),
first_orders AS (
    SELECT *
    FROM customer_orders
    WHERE rn = 1
      AND purchase_date < '2018-03-01'
)
SELECT
    CASE
        WHEN is_delayed IS NULL THEN '3. не доставлен'
        WHEN is_delayed         THEN '2. с задержкой'
        ELSE                         '1. вовремя'
    END AS first_order_delivery,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE last_purchase_date > purchase_date) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE last_purchase_date > purchase_date) / COUNT(*), 2) AS repeat_pct
FROM first_orders
GROUP BY 1
ORDER BY 1;
-- Вывод: покупатели, чей первый заказ задержали, реже делают повторную покупку
-- 1.99% против 2.94% у получивших заказ вовремя (разница значима, p < 0.01)


-- повторная покупка в зависимости от оценки первого заказа
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        fo.purchase_date,
        fo.review_score,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY fo.order_purchase_timestamp, fo.order_id
        ) AS rn,
        MAX(fo.purchase_date) OVER (PARTITION BY c.customer_unique_id) AS last_purchase_date
    FROM dwh.fact_orders fo
    JOIN dwh.dim_customers c
        ON c.customer_id = fo.customer_id
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
),
first_orders AS (
    SELECT *
    FROM customer_orders
    WHERE rn = 1
      AND purchase_date < '2018-03-01'
)
SELECT
    CASE
        WHEN review_score IN (1, 2) THEN '1. негатив (1-2)'
        WHEN review_score = 3       THEN '2. нейтрально (3)'
        WHEN review_score IN (4, 5) THEN '3. позитив (4-5)'
        ELSE                             '4. без оценки'
    END AS first_order_review,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE last_purchase_date > purchase_date) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE last_purchase_date > purchase_date) / COUNT(*), 2) AS repeat_pct
FROM first_orders
GROUP BY 1
ORDER BY 1;
-- Вывод: после плохой оценки повторную покупку делают реже (2.23% вместо 3.04% после позитивной)
-- (разница значима, p < 0.01)


-- что сильнее связано с повторной покупкой: задержка или плохая оценка
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        fo.purchase_date,
        fo.is_delayed,
        fo.review_score,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY fo.order_purchase_timestamp, fo.order_id
        ) AS rn,
        MAX(fo.purchase_date) OVER (PARTITION BY c.customer_unique_id) AS last_purchase_date
    FROM dwh.fact_orders fo
    JOIN dwh.dim_customers c
        ON c.customer_id = fo.customer_id
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
),
first_orders AS (
    SELECT *
    FROM customer_orders
    WHERE rn = 1
      AND purchase_date < '2018-03-01'
      AND is_delayed IS NOT NULL
      AND review_score IS NOT NULL
)
SELECT
    CASE WHEN is_delayed THEN '2. с задержкой' ELSE '1. вовремя' END AS delivery,
    CASE
        WHEN review_score IN (1, 2) THEN '1. негатив (1-2)'
        WHEN review_score = 3       THEN '2. нейтрально (3)'
        ELSE                             '3. позитив (4-5)'
    END AS review,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE last_purchase_date > purchase_date) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE last_purchase_date > purchase_date) / COUNT(*), 2) AS repeat_pct
FROM first_orders
GROUP BY 1, 2
ORDER BY 1, 2;
-- Вывод: связаны и задержка, и оценка, меньше всего повторных покупок при задержке
-- и плохой оценке (1.79%), больше всего, если доставили вовремя и позитивный отзыв (3.05%)
-- среди доставленных вовремя оценка значима (3.05% против 2.43%, p = 0.02)


-- 2 Сколько покупателей делают повторную покупку и через сколько дней?

-- доля покупателей с заказами в 2+ разных дня
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT fo.purchase_date) AS purchase_days
    FROM dwh.fact_orders fo
    JOIN dwh.dim_customers c
        ON fo.customer_id = c.customer_id
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE purchase_days > 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE purchase_days > 1) / COUNT(*), 2) AS repeat_customers_pct
FROM customer_orders;
-- Вывод: повторную покупку делают только 2.17% покупателей (2 065 из 94 990)


-- время между первой и второй покупкой
WITH ordered AS (
    SELECT
        c.customer_unique_id,
        fo.order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY fo.order_purchase_timestamp, fo.order_id
        ) AS rn,
        LEAD(fo.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY fo.order_purchase_timestamp, fo.order_id
        ) AS next_purchase_ts
    FROM dwh.fact_orders fo
    JOIN dwh.dim_customers c
        ON fo.customer_id = c.customer_id
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
),
second_purchase AS (
    SELECT
        next_purchase_ts::DATE - order_purchase_timestamp::DATE AS days_to_second
    FROM ordered
    WHERE rn = 1
      AND next_purchase_ts IS NOT NULL
)
SELECT
    COUNT(*) AS repeat_customers,
    COUNT(*) FILTER (WHERE days_to_second = 0) AS same_day,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_to_second) AS p25_days,
    PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY days_to_second) AS median_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_to_second) AS p75_days,
    PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY days_to_second)
        FILTER (WHERE days_to_second > 0) AS median_days_excl_same_day
FROM second_purchase;
-- Вывод: 30% вторых заказов (869 из 2 888) сделаны в тот же день, что и первый —
-- это разбитая корзина, а не повторная покупка. без них медиана до второго заказа 75 дней


-- 3 зависимость выручки от крупных заказов

-- среднее, медиана, хвост распределения чека
SELECT
    ROUND(AVG(total_order_amount), 2) AS mean_order_value,
    PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY total_order_amount) AS median_order_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_order_amount) AS p25,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_order_amount) AS p75,
    PERCENTILE_CONT(0.9)  WITHIN GROUP (ORDER BY total_order_amount) AS p90,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_order_amount) AS p99
FROM dwh.fact_orders
WHERE order_status NOT IN ('canceled', 'unavailable')
  AND items_count > 0;
-- Вывод: распределение скошено вправо: среднее 137, медиана 87,
-- для типичного заказа корректнее смотреть медиану


-- доля выручки по децилям заказов
WITH ranked AS (
    SELECT
        total_order_amount,
        NTILE(10) OVER (ORDER BY total_order_amount DESC) AS decile
    FROM dwh.fact_orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
      AND items_count > 0
)
SELECT
    decile,
    COUNT(*) AS orders,
    MIN(total_order_amount) AS min_amount,
    MAX(total_order_amount) AS max_amount,
    SUM(total_order_amount) AS revenue,
    ROUND(100.0 * SUM(total_order_amount) / SUM(SUM(total_order_amount)) OVER (), 2) AS revenue_share_pct
FROM ranked
GROUP BY decile
ORDER BY decile;
-- Вывод: 10% самых дорогих заказов дают 41% выручки, нижняя половина — около 17%


-- 4 Что ещё связано с низкой оценкой
-- *берём только доставленные вовремя заказы с оценкой

-- количество товаров в заказе
SELECT
    CASE WHEN items_count = 1 THEN '1 товар' ELSE '2+ товара' END AS basket,
    COUNT(*) AS orders,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 2) AS low_score_pct
FROM dwh.fact_orders
WHERE order_status = 'delivered'
  AND is_delayed = FALSE
  AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;
-- Вывод: заказы из 2+ товаров получают низкую оценку в 3 раза чаще (24.6% против 7.6%),
-- даже если доставлены вовремя. гипотеза: заказы от нескольких продавцов приходят частями


-- доля доставки в чеке
SELECT
    CASE
        WHEN total_freight / NULLIF(total_order_amount, 0) < 0.1  THEN '1. < 10%'
        WHEN total_freight / NULLIF(total_order_amount, 0) < 0.25 THEN '2. 10-25%'
        WHEN total_freight / NULLIF(total_order_amount, 0) < 0.5  THEN '3. 25-50%'
        ELSE                                                           '4. 50%+'
    END AS freight_share,
    COUNT(*) AS orders,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 2) AS low_score_pct
FROM dwh.fact_orders
WHERE order_status = 'delivered'
  AND is_delayed = FALSE
  AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;
-- Вывод: доля доставки в чеке на оценку почти не влияет (8.8% -> 9.8% низких оценок)


-- штат продавца и покупателей
-- *один штат, только если все продавцы заказа из штата покупателя
WITH order_geo AS (
    SELECT
        oi.order_id,
        BOOL_AND(s.seller_state = c.customer_state) AS same_state
    FROM dwh.fact_order_items oi
    JOIN dwh.dim_sellers s
        ON oi.seller_id = s.seller_id
    JOIN dwh.fact_orders fo
        ON oi.order_id = fo.order_id
    JOIN dwh.dim_customers c
        ON fo.customer_id = c.customer_id
    GROUP BY oi.order_id
)
SELECT
    CASE WHEN g.same_state THEN 'один штат' ELSE 'разные штаты' END AS geography,
    COUNT(*) AS orders,
    ROUND(AVG(fo.delivery_days), 1) AS avg_delivery_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE fo.is_delayed) / COUNT(*), 2) AS delayed_pct,
    ROUND(AVG(fo.review_score), 2) AS avg_review_score
FROM dwh.fact_orders fo
JOIN order_geo g
    ON fo.order_id = g.order_id
WHERE fo.order_status = 'delivered'
  AND fo.is_delayed IS NOT NULL
GROUP BY 1
ORDER BY 1;
-- Вывод: между штатами доставка вдвое дольше (15.1 против 7.9 дня) и задержки вдвое чаще
-- (8.0% против 4.5%) — срок для дальних доставок прогнозируется хуже


-- 5 На каком этапе теряется время доставки
-- покупка -> подтверждение -> передача перевозчику -> получение
-- *исключаем заказы с неправильным порядком дат (проверка в 4_quality_check)

WITH stages AS (
    SELECT
        EXTRACT(EPOCH FROM order_approved_at - order_purchase_timestamp) / 86400 AS approval_days,
        EXTRACT(EPOCH FROM order_delivered_carrier_date - order_approved_at) / 86400 AS to_carrier_days,
        EXTRACT(EPOCH FROM order_delivered_customer_date - order_delivered_carrier_date) / 86400 AS shipping_days
    FROM dwh.fact_orders
    WHERE order_status = 'delivered'
      AND order_approved_at IS NOT NULL
      AND order_delivered_carrier_date IS NOT NULL
      AND order_delivered_customer_date IS NOT NULL
      AND order_approved_at >= order_purchase_timestamp
      AND order_delivered_carrier_date >= order_approved_at
      AND order_delivered_customer_date >= order_delivered_carrier_date
)
SELECT
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY approval_days)::NUMERIC, 1) AS approval_median,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY approval_days)::NUMERIC, 1) AS approval_p90,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY to_carrier_days)::NUMERIC, 1) AS to_carrier_median,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY to_carrier_days)::NUMERIC, 1) AS to_carrier_p90,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY shipping_days)::NUMERIC, 1) AS shipping_median,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY shipping_days)::NUMERIC, 1) AS shipping_p90
FROM stages;
-- Вывод: дольше всего занимает доставка перевозчиком: медиана 7.1 дня, p90 18.9.
-- передача перевозчику — медиана 1.8 дня, p90 6, подтверждение почти мгновенное


-- 6 Какие категории получают самые низкие оценки?
-- *заказ с товарами из разных категорий учитываем в каждой из них
-- *отсекаем категории с менее чем 300 заказами, где средняя оценка случайна
WITH order_categories AS (
    SELECT DISTINCT
        oi.order_id,
        p.product_category_name_english AS category
    FROM dwh.fact_order_items oi
    JOIN dwh.dim_products p
        ON oi.product_id = p.product_id
)
SELECT
    oc.category,
    COUNT(*) AS orders,
    ROUND(AVG(fo.review_score), 2) AS avg_review_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE fo.review_score <= 2) / COUNT(*), 2) AS low_score_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE fo.is_delayed) / COUNT(*), 2) AS delayed_pct
FROM order_categories oc
JOIN dwh.fact_orders fo
    ON oc.order_id = fo.order_id
WHERE fo.order_status = 'delivered'
  AND fo.review_score IS NOT NULL
GROUP BY oc.category
HAVING COUNT(*) >= 300
ORDER BY low_score_pct DESC
LIMIT 15;
-- Вывод: худшие оценки у office_furniture и audio (~22% низких оценок).
-- у audio это совпадает с самой высокой долей задержек, у office_furniture — нет:
-- там проблема, вероятно, в товаре. больше всего недовольных в bed_bath_table (~1 470 заказов)


-- 7. Покупают ли в рассрочку дороже?

SELECT
    CASE
        WHEN payment_installments <= 1 THEN '1. без рассрочки'
        WHEN payment_installments <= 3 THEN '2. 2-3 платежа'
        WHEN payment_installments <= 6 THEN '3. 4-6 платежей'
        ELSE                                '4. 7+ платежей'
    END AS installments,
    COUNT(*) AS orders,
    ROUND(AVG(total_order_amount), 2) AS mean_order_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_order_amount) AS median_order_value
FROM dwh.fact_orders
WHERE order_status NOT IN ('canceled', 'unavailable')
  AND payment_installments IS NOT NULL
GROUP BY 1
ORDER BY 1;
-- Вывод: заказы в рассрочку дороже (медиана 60 -> 180 при 7+ платежах).
-- это корреляция: скорее дорогие покупки чаще оплачивают в рассрочку, чем рассрочка увеличивает чек