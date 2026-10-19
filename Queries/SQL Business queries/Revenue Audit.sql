-- Calculating variance between actual payments and order price + freight Value
-- CTE for Payments
WITH OrderPayments AS (
    SELECT 
        order_id, 
        SUM(payment_value) AS total_order_payment
    FROM olist.payments
    GROUP BY order_id
),
-- CTE for Order price and freight
OrderPrices AS (
    SELECT 
        order_id, 
        SUM(price) AS total_order_price,
        SUM(freight_value) AS total_order_freight
    FROM olist.order_items
    GROUP BY order_id
)
SELECT 
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    ISNULL(p.total_order_payment, 0) AS total_order_payment,
    ISNULL(i.total_order_price, 0) AS total_order_price,
    ISNULL(i.total_order_freight, 0) AS total_order_freight,
    -- Variance: Payment minus Total Items Charge (Price + Freight)
    ISNULL(p.total_order_payment, 0) - (ISNULL(i.total_order_price, 0) + ISNULL(i.total_order_freight, 0)) AS variance
FROM olist.orders AS o
LEFT JOIN OrderPayments AS p 
    ON o.order_id = p.order_id
LEFT JOIN OrderPrices AS i 
    ON o.order_id = i.order_id
WHERE 
    o.order_status IN ('delivered') 
    AND o.order_purchase_timestamp >= '2017-08-01' 
    AND o.order_purchase_timestamp <  '2018-08-01'
    AND ISNULL(p.total_order_payment, 0) - (ISNULL(i.total_order_price, 0) + ISNULL(i.total_order_freight, 0)) > 0.02
ORDER BY 
    o.order_purchase_timestamp ASC;


    -- Sum of revenue variance
    WITH OrderPayments AS (
    SELECT 
        order_id, 
        SUM(payment_value) AS total_order_payment
    FROM olist.payments
    GROUP BY order_id
),
OrderPrices AS (
    SELECT 
        order_id, 
        SUM(price) AS total_order_price,
        SUM(freight_value) AS total_order_freight
    FROM olist.order_items
    GROUP BY order_id
)
SELECT
    SUM(ISNULL(p.total_order_payment, 0)) AS sum_payments,
    SUM(ISNULL(i.total_order_price, 0)) AS sum_order_price,
    SUM(ISNULL(i.total_order_freight, 0)) AS sum_order_freight,
    SUM(ISNULL(p.total_order_payment, 0) - (ISNULL(i.total_order_price, 0) + ISNULL(i.total_order_freight, 0))) AS sum_var
    FROM olist.orders AS o
LEFT JOIN OrderPayments AS p 
    ON o.order_id = p.order_id
LEFT JOIN OrderPrices AS i 
    ON o.order_id = i.order_id
WHERE 
    o.order_status IN ('delivered') 
    AND o.order_purchase_timestamp >= '2017-08-01' 
    AND o.order_purchase_timestamp <  '2018-08-01'
    AND ABS(ISNULL(p.total_order_payment, 0) - (ISNULL(i.total_order_price, 0) + ISNULL(i.total_order_freight, 0))) > 0.02
