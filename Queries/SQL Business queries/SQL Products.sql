DECLARE @volumetric_divisor decimal(9, 2) = 5000; -- cm3 per kg. Some carriers charge 6000, but for domestic transport 5000 is standard.
DECLARE @start_date         date          = '2017-08-01';
DECLARE @end_date           date          = '2018-08-01'; 
DECLARE @category           nvarchar(100) = 'health_beauty';

WITH order_scores AS (
    -- Some orders have more than one review, so average them to one score per order
    SELECT
        order_id,
        AVG(CAST(review_score AS float)) AS review_score,
        COUNT(review_id) AS reviews_count
    FROM olist.reviews
    GROUP BY order_id
),

items AS (
    SELECT
        p.product_id,
        t.product_category_name_english AS category_name,
        i.order_id,
        i.seller_id,
        i.price,
        i.freight_value,
        s.review_score,
        s.reviews_count,
        NULLIF(p.product_weight_g, 0) / 1000.0 AS actual_weight_kg,
        (p.product_length_cm * p.product_height_cm * p.product_width_cm)
            / @volumetric_divisor              AS volumetric_weight_kg
    FROM olist.order_items AS i
    JOIN olist.orders AS o
        ON o.order_id = i.order_id
    LEFT JOIN olist.products AS p
        ON p.product_id = i.product_id
    JOIN olist.category_translation AS t
        ON t.product_category_name = p.product_category_name
    LEFT JOIN order_scores AS s
        ON s.order_id = i.order_id
    WHERE t.product_category_name_english = @category
      AND o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= @start_date
      AND o.order_purchase_timestamp <  @end_date
),

product_stats AS (
    SELECT
        product_id,
        category_name,
        COUNT(*)                                          AS units_sold,
        COUNT(DISTINCT order_id)                          AS order_count,
        COUNT(DISTINCT seller_id)                         AS seller_count,
        SUM(price)                                        AS revenue,
        AVG(price)                                        AS avg_price,
        MIN(price)                                        AS min_price,
        MAX(price)                                        AS max_price,
        AVG(freight_value)                                AS avg_freight,
        AVG(review_score)                                 AS avg_review_score,
        SUM(reviews_count)                                AS reviews_count,
        MAX(actual_weight_kg)                             AS actual_weight_kg,        -- same for every row of a product
        MAX(volumetric_weight_kg)                         AS volumetric_weight_kg
    FROM items
    GROUP BY product_id, category_name
),

product_metrics AS (
    SELECT
        *,
        -- Carriers charge for the larger of actual and volumetric weight
        CASE
            WHEN actual_weight_kg IS NULL THEN volumetric_weight_kg
            WHEN volumetric_weight_kg IS NULL THEN actual_weight_kg
            WHEN actual_weight_kg >= volumetric_weight_kg THEN actual_weight_kg
            ELSE volumetric_weight_kg
        END AS chargeable_weight_kg
    FROM product_stats
)


SELECT
    category_name,
    product_id,
    units_sold,
    order_count,
    seller_count,
    ROUND(revenue, 2)                                                   AS revenue,
    ROUND(avg_price, 2)                                                 AS avg_price,
    ROUND(min_price, 2)                                                 AS min_price,
    ROUND(max_price, 2)                                                 AS max_price,
    ROUND(avg_freight, 2)                                               AS avg_freight,
    ROUND(actual_weight_kg, 3)                                          AS actual_weight_kg,
    ROUND(volumetric_weight_kg, 3)                                      AS volumetric_weight_kg,
    ROUND(chargeable_weight_kg, 3)                                      AS chargeable_weight_kg,
    ROUND(avg_freight / NULLIF(chargeable_weight_kg, 0), 2)             AS freight_per_kg,
    ROUND(avg_review_score, 2)                                          AS avg_review_score,
    reviews_count
FROM product_metrics
ORDER BY revenue DESC, product_id;

/*

SELECT
    category_name,
    product_id,
    COUNT(DISTINCT seller_id) AS seller_count,
    1.0*AVG(unit_price) AS avg_price,
    1.0*AVG(freight_value) AS avg_freight,
    volum_weight AS volum_weight,
    ROUND(1.0*AVG(freight_value)/volum_weight,2) AS freight_ratio
FROM ( SELECT     
    t.product_category_name_english AS category_name,
    p.product_id                    AS product_id,
    i.seller_id                     AS seller_id,
    i.price                         AS unit_price,
    i.freight_value                 AS freight_value,
    ROUND((p.product_length_cm*p.product_height_cm*p.product_width_cm*1.0)/5000,2) AS volum_weight
    FROM olist.products AS p
    LEFT JOIN olist.category_translation AS t 
    ON t.product_category_name = p.product_category_name
    JOIN olist.order_items as i
    ON i.product_id = p.product_id
    WHERE t.product_category_name_english = 'health_beauty'
    ) AS product_info
    GROUP BY product_id, category_name, volum_weight
    ORDER BY seller_count DESC;

    */