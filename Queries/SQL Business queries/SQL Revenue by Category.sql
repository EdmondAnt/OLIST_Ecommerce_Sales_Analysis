SELECT 
    ISNULL(t.product_category_name_english, 'misc') AS category_name,
    COUNT(i.order_item_id)                          AS category_count, -- Count amount of ordered products
    SUM(i.price)                                    AS gross_merchandise_value,
    SUM (i.price + i.freight_value)                 AS gross_order_value,
    SUM(i.freight_value)                            AS gross_freight_cost
FROM olist.order_items AS i
JOIN olist.orders AS o 
    ON i.order_id = o.order_id
JOIN olist.products AS p 
    ON i.product_id = p.product_id
JOIN olist.category_translation AS t 
    ON p.product_category_name = t.product_category_name
WHERE 
    o.order_status IN ('delivered') 
    AND o.order_purchase_timestamp >= '2017-08-01' 
    AND o.order_purchase_timestamp <  '2018-08-01'
GROUP BY 
    t.product_category_name_english
ORDER BY 
    gross_merchandise_value DESC;