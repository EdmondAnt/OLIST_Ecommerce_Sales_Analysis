 -- Revenue and number of items grouped by categoryWITH OrderPayments AS (

WITH OrderPayments AS (
    -- Pre-aggregate payments per order to prevent fan-out duplicate sums
    SELECT 
        order_id, 
        SUM(payment_value) AS total_order_payment
    FROM olist.payments
    GROUP BY order_id
),
CategoryCount AS(
SELECT SUM(total_order_payment) AS category_revenue,
COUNT(p.product_id) AS category_count,
t.product_category_name_english AS category_name
FROM olist.orders as o
JOIN olist.order_items as ord
ON o.order_id = ord.order_id
JOIN olist.products AS p
ON p.product_id = ord.product_id
JOIN OrderPayments AS pay
ON pay.order_id = o.order_id
JOIN olist.category_translation as t
ON p.product_category_name = t.product_category_name
WHERE 
        o.order_status IN ('delivered') 
GROUP BY t.product_category_name_english)
SELECT
category_count, category_name, category_revenue
FROM CategoryCount
ORDER BY category_count DESC; 