WITH CategoryAnnualRevenue AS (
    SELECT 
        ISNULL(t.product_category_name_english, 'misc') AS category_name,
        
        -- Period 1: Oct 2016 to Oct 2017 (12-month window)
        SUM(CASE 
            WHEN o.order_purchase_timestamp >= '2016-10-01' 
             AND o.order_purchase_timestamp <  '2017-09-01' 
            THEN ord.price ELSE 0 
        END) AS rev_period_1,
        
        -- Period 2: Oct 2017 to Oct 2018 
        SUM(CASE 
            WHEN o.order_purchase_timestamp >= '2017-10-01' 
             AND o.order_purchase_timestamp <  '2018-09-01' 
            THEN ord.price ELSE 0 
        END) AS rev_period_2

    FROM olist.orders AS o
    JOIN olist.order_items AS ord 
        ON ord.order_id = o.order_id
    JOIN olist.products AS pr 
        ON pr.product_id = ord.product_id
    LEFT JOIN olist.category_translation AS t 
        ON pr.product_category_name = t.product_category_name
    WHERE 
        o.order_status = 'delivered' 
        AND o.order_purchase_timestamp >= '2016-10-01' 
        AND o.order_purchase_timestamp <  '2018-09-01' 
    GROUP BY 
        t.product_category_name_english
)
SELECT 
    category_name,
    rev_period_1 AS revenue_oct16_oct17,
    rev_period_2 AS revenue_oct17_oct18,
    
    -- Absolute Growth
    rev_period_2 - rev_period_1 AS revenue_growth_amount,
    
    -- Percentage YoY Growth
    CAST(
        (rev_period_2 - rev_period_1) * 100.0 / NULLIF(rev_period_1, 0) 
        AS DECIMAL(10,2)
    ) AS revenue_growth_YoY_pct

FROM CategoryAnnualRevenue
WHERE rev_period_1 > 0 -- Optional: filters out categories that didn't exist in period 1 to avoid massive distorted percentages
ORDER BY 
    revenue_oct16_oct17 DESC, 
    revenue_oct17_oct18 DESC;