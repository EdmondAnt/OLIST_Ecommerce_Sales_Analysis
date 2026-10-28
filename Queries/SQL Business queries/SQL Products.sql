Select p.product_id, o.price, t.product_category_name_english
FROM olist.products AS p
JOIN olist.category_translation as t
ON p.product_category_name = t.product_category_name
JOIN olist.order_items as o
ON p.product_id = o.product_id; 



-- I want a product category, product id, number of sellers that sell product, customers count, average price, average freight value, ratio freight to volume weight
SELECT
    --t.product_category_name_english AS category_name,
    p.product_id    AS product_count,
    COUNT(DISTINCT i.seller_id) AS s_id
FROM olist.products AS p
LEFT JOIN olist.category_translation AS t 
ON t.product_category_name = p.product_category_name
JOIN olist.order_items as I
ON i.product_id = p.product_id
WHERE t.product_category_name_english = 'health_beauty'
GROUP BY p.product_id

ORDER BY s_id DESC;