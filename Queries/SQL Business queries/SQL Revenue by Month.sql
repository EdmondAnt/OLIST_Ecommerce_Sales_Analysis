-- Revenue by Category and Month from 2017.08 till 2018.08
SELECT 
    DATE_BUCKET(MONTH, 1, o.order_purchase_timestamp) AS order_period,
    ISNULL(t.product_category_name_english, 'misc')   AS category_name,
    ROUND(SUM(ord.price),2)                           AS gross_merchandise_value,
    SUM(ord.price) / COUNT(DISTINCT ord.order_id)     AS average_order_value,
    ROUND(AVG(CAST(ord.price as float)),2)            AS average_item_price,
    COUNT(DISTINCT ord.order_id)                      AS order_count
FROM olist.orders AS o
JOIN olist.order_items AS ord 
    ON ord.order_id = o.order_id
JOIN olist.products AS pr 
    ON pr.product_id = ord.product_id
LEFT JOIN olist.category_translation AS t 
    ON pr.product_category_name = t.product_category_name
WHERE 
    o.order_status IN ('delivered') 
    AND o.order_purchase_timestamp >= '2017-08-01' 
    AND o.order_purchase_timestamp <  '2018-08-01'
GROUP BY 
    DATE_BUCKET(MONTH, 1, o.order_purchase_timestamp), 
    t.product_category_name_english
ORDER BY category_name, order_period;

