Select p.product_id, o.price, t.product_category_name_english
FROM olist.products AS p
JOIN olist.category_translation as t
ON p.product_category_name = t.product_category_name
JOIN olist.order_items as o
ON p.product_id = o.product_id; 


SELECT
    REPLACE(t.product_category_name_english, CHAR(13), '') AS category_name,
    COUNT(DISTINCT p.product_id)    AS product_count
FROM olist.products AS p
LEFT JOIN olist.category_translation AS t ON t.product_category_name = p.product_category_name
--WHERE REPLACE(t.product_category_name_english, CHAR(13), '') = 'health_beauty'
GROUP BY REPLACE(t.product_category_name_english, CHAR(13), '')
ORDER BY product_count DESC;