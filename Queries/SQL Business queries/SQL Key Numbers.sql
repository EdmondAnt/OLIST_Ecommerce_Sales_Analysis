-- KEY NUMBERS: platform vs Health & Beauty
-- Period: 1 Aug 2017 to 31 Jul 2018 (end date is exclusive, so this is exactly 12 months)
-- Revenue = item price only (freight excluded). Delivered orders only.

DECLARE @start_date date          = '2017-08-01';
DECLARE @end_date   date          = '2018-08-01';
DECLARE @category   nvarchar(100) = 'health_beauty';

WITH items AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        i.seller_id,
        i.price,
        -- REPLACE removes stray line-break characters; drop it once the translation table is cleaned
        REPLACE(t.product_category_name_english, CHAR(13), '') AS category_name
    FROM olist.orders AS o
    JOIN olist.customers   AS c ON c.customer_id = o.customer_id
    JOIN olist.order_items AS i ON i.order_id    = o.order_id
    LEFT JOIN olist.products AS p
        ON p.product_id = i.product_id
    LEFT JOIN olist.category_translation AS t       -- LEFT JOIN keeps items with no category
        ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= @start_date
      AND o.order_purchase_timestamp <  @end_date
),
metrics AS (
    SELECT
        'All categories'                                  AS scope,
        COUNT(DISTINCT customer_unique_id)                AS customers,
        COUNT(DISTINCT seller_id)                         AS sellers,
        COUNT(DISTINCT order_id)                          AS orders,
        COUNT(*)                                          AS units,
        SUM(price)                                        AS revenue,
        SUM(price) / NULLIF(COUNT(DISTINCT order_id), 0)  AS avg_order_value,
        AVG(CAST(price AS float))                         AS avg_item_price
    FROM items

    UNION ALL

    SELECT
        'Health & Beauty',
        COUNT(DISTINCT customer_unique_id),
        COUNT(DISTINCT seller_id),
        COUNT(DISTINCT order_id),
        COUNT(*),
        SUM(price),
        SUM(price) / NULLIF(COUNT(DISTINCT order_id), 0),
        AVG(CAST(price AS float))
    FROM items
    WHERE category_name = @category
)
SELECT
    scope,
    customers,
    sellers,
    orders,
    units,
    ROUND(revenue, 2)         AS revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(avg_item_price, 2)  AS avg_item_price,
    ROUND(100.0 * revenue
          / MAX(CASE WHEN scope = 'All categories' THEN revenue END) OVER (), 2) AS revenue_share_pct
FROM metrics;


-- CHECK 1: data coverage (all orders, any status)
SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order,
    COUNT(*)                      AS total_orders
FROM olist.orders;


-- CHECK 2: revenue in the period with no English category name (excluded from category charts)
SELECT
    COUNT(*)                AS items_without_category,
    ROUND(SUM(i.price), 2)  AS revenue_without_category
FROM olist.orders AS o
JOIN olist.order_items AS i ON i.order_id = o.order_id
LEFT JOIN olist.products AS p ON p.product_id = i.product_id
LEFT JOIN olist.category_translation AS t ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-08-01'
  AND o.order_purchase_timestamp <  '2018-08-01'
  AND t.product_category_name_english IS NULL;