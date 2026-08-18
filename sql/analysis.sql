-- Olist E-commerce Product Analytics
-- SQL Analysis
-- PostgreSQL

-- =========================================================
-- 1. MONTHLY SALES PERFORMANCE
-- =========================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS gmv,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS aov
FROM raw.orders o
JOIN raw.order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- =========================================================
-- 2. CUSTOMER EXPERIENCE BY DELIVERY TIME
-- =========================================================

WITH delivery_data AS (
    SELECT
        o.order_id,
        r.review_score,
        EXTRACT(
            DAY FROM (
                o.order_delivered_customer_date
                - o.order_purchase_timestamp
            )
        ) AS delivery_days
    FROM raw.orders o
    JOIN raw.order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
),

grouped_data AS (
    SELECT
        order_id,
        review_score,
        CASE
            WHEN delivery_days < 3 THEN '<3 days'
            WHEN delivery_days < 7 THEN '3-7 days'
            WHEN delivery_days < 14 THEN '7-14 days'
            ELSE '14+ days'
        END AS delivery_group
    FROM delivery_data
)

SELECT
    delivery_group,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    COUNT(DISTINCT order_id) AS orders
FROM grouped_data
GROUP BY delivery_group
ORDER BY
    CASE delivery_group
        WHEN '<3 days' THEN 1
        WHEN '3-7 days' THEN 2
        WHEN '7-14 days' THEN 3
        WHEN '14+ days' THEN 4
    END;

-- =========================================================
-- 3. NEGATIVE REVIEWS BY DELIVERY TIME
-- =========================================================

WITH delivery_data AS (
    SELECT
        o.order_id,
        r.review_score,
        EXTRACT(
            DAY FROM (
                o.order_delivered_customer_date
                - o.order_purchase_timestamp
            )
        ) AS delivery_days
    FROM raw.orders o
    JOIN raw.order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
),

grouped_data AS (
    SELECT
        order_id,
        review_score,
        CASE
            WHEN delivery_days < 3 THEN '<3 days'
            WHEN delivery_days < 7 THEN '3-7 days'
            WHEN delivery_days < 14 THEN '7-14 days'
            ELSE '14+ days'
        END AS delivery_group
    FROM delivery_data
)

SELECT
    delivery_group,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE review_score IN (1, 2)
        ) / COUNT(*),
        2
    ) AS negative_review_pct
FROM grouped_data
GROUP BY delivery_group
ORDER BY
    CASE delivery_group
        WHEN '<3 days' THEN 1
        WHEN '3-7 days' THEN 2
        WHEN '7-14 days' THEN 3
        WHEN '14+ days' THEN 4
    END;

-- =========================================================
-- 4. TOP 10 PRODUCT CATEGORIES BY GMV
-- =========================================================

SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS gmv
FROM raw.order_items oi
JOIN raw.products p
    ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY gmv DESC
LIMIT 10;

-- =========================================================
-- 5. TOP 10 STATES BY NUMBER OF ORDERS
-- =========================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders
FROM raw.orders o
JOIN raw.customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY orders DESC
LIMIT 10;


