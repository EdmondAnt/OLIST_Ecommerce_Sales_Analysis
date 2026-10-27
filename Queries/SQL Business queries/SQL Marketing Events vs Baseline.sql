-- MARKETING EVENTS vs BASELINE: Health & Beauty
--
-- Event window : the 14 days ending on the event date (gifts are bought BEFORE the day).
-- Baseline     : the 28 days before the event window, leaving out any day that belongs to
--                another event window, so one event does not distort another's baseline.
-- Revenue      : item price only (freight excluded), delivered orders, by purchase date.
-- Control      : the same uplift for the whole platform, so you can see whether Health & Beauty
--                reacted more strongly than Olist overall (overall growth also lifts the numbers).

DECLARE @category      nvarchar(100) = 'health_beauty';
DECLARE @window_days   int           = 14;
DECLARE @baseline_days int           = 28;

WITH events AS (
    SELECT event_name, CAST(event_date AS date) AS event_date
    FROM (VALUES
        ('Fathers Day 2017',   '2017-08-13'),
        ('Childrens Day',      '2017-10-12'),
        ('Black Friday',       '2017-11-24'),
        ('Christmas',          '2017-12-25'),
        ('Womens Day',         '2018-03-08'),
        ('Mothers Day',        '2018-05-13'),
        ('Valentines Day',     '2018-06-12'),
        ('Fathers Day 2018',   '2018-08-12')
    ) AS e(event_name, event_date)
),

event_windows AS (
    SELECT
        event_name,
        event_date,
        DATEADD(day, -(@window_days - 1), event_date)                  AS window_start,
        event_date                                                     AS window_end,
        DATEADD(day, -(@window_days + @baseline_days - 1), event_date) AS baseline_start,
        DATEADD(day, -@window_days, event_date)                        AS baseline_end
    FROM events
),

-- One row for every calendar day, so days with no sales count as zero instead of disappearing
dates AS (
    SELECT MIN(baseline_start) AS sale_date, MAX(window_end) AS last_day
    FROM event_windows
    UNION ALL
    SELECT DATEADD(day, 1, sale_date), last_day
    FROM dates
    WHERE sale_date < last_day
),

daily_sales AS (
    SELECT
        CAST(o.order_purchase_timestamp AS date)                          AS sale_date,
        SUM(i.price)                                                      AS platform_revenue,
        COUNT(DISTINCT o.order_id)                                        AS platform_orders,
        SUM(CASE WHEN t.product_category_name_english = @category
                 THEN i.price ELSE 0 END)                                 AS hb_revenue,
        COUNT(DISTINCT CASE WHEN t.product_category_name_english = @category
                            THEN o.order_id END)                          AS hb_orders
    FROM olist.orders AS o
    JOIN olist.order_items AS i
        ON i.order_id = o.order_id
    LEFT JOIN olist.products AS p
        ON p.product_id = i.product_id
    LEFT JOIN olist.category_translation AS t
        ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= (SELECT MIN(baseline_start) FROM event_windows)
      AND o.order_purchase_timestamp <  DATEADD(day, 1, (SELECT MAX(window_end) FROM event_windows))
    GROUP BY CAST(o.order_purchase_timestamp AS date)
),

daily AS (
    SELECT
        d.sale_date,
        COALESCE(s.hb_revenue, 0)       AS hb_revenue,
        COALESCE(s.hb_orders, 0)        AS hb_orders,
        COALESCE(s.platform_revenue, 0) AS platform_revenue,
        CASE WHEN EXISTS (SELECT 1
                          FROM event_windows AS w
                          WHERE d.sale_date BETWEEN w.window_start AND w.window_end)
             THEN 1 ELSE 0 END          AS in_any_event_window
    FROM dates AS d
    LEFT JOIN daily_sales AS s
        ON s.sale_date = d.sale_date
),

event_totals AS (
    SELECT
        w.event_name,
        w.baseline_start,
        w.window_start,
        w.window_end,

        -- inside the event window
        SUM(CASE WHEN d.sale_date BETWEEN w.window_start AND w.window_end
                 THEN d.hb_revenue ELSE 0 END)        AS ev_hb_revenue,
        SUM(CASE WHEN d.sale_date BETWEEN w.window_start AND w.window_end
                 THEN d.hb_orders ELSE 0 END)         AS ev_hb_orders,
        SUM(CASE WHEN d.sale_date BETWEEN w.window_start AND w.window_end
                 THEN d.platform_revenue ELSE 0 END)  AS ev_platform_revenue,

        -- inside the baseline period (days that are not part of any event window)
        SUM(CASE WHEN d.sale_date BETWEEN w.baseline_start AND w.baseline_end
                  AND d.in_any_event_window = 0
                 THEN d.hb_revenue ELSE 0 END)        AS base_hb_revenue,
        SUM(CASE WHEN d.sale_date BETWEEN w.baseline_start AND w.baseline_end
                  AND d.in_any_event_window = 0
                 THEN d.hb_orders ELSE 0 END)         AS base_hb_orders,
        SUM(CASE WHEN d.sale_date BETWEEN w.baseline_start AND w.baseline_end
                  AND d.in_any_event_window = 0
                 THEN d.platform_revenue ELSE 0 END)  AS base_platform_revenue,
        SUM(CASE WHEN d.sale_date BETWEEN w.baseline_start AND w.baseline_end
                  AND d.in_any_event_window = 0
                 THEN 1 ELSE 0 END)                   AS base_days
    FROM event_windows AS w
    JOIN daily AS d
        ON d.sale_date BETWEEN w.baseline_start AND w.window_end
    GROUP BY w.event_name, w.baseline_start, w.window_start, w.window_end
)

SELECT
    event_name,
    baseline_start,
    window_start,
    window_end,
    base_days,                                                      -- days used for the baseline

    ROUND(ev_hb_revenue, 2)                                         AS event_hb_revenue,
    ROUND(ev_hb_revenue * 1.0 / @window_days, 2)                    AS event_avg_daily_revenue,
    ROUND(base_hb_revenue * 1.0 / NULLIF(base_days, 0), 2)          AS baseline_avg_daily_revenue,

    ROUND(100.0 * ((ev_hb_revenue * 1.0 / @window_days)
                 / NULLIF(base_hb_revenue * 1.0 / NULLIF(base_days, 0), 0) - 1), 1)
                                                                    AS hb_uplift_pct,
    ROUND(ev_hb_revenue
          - (base_hb_revenue * 1.0 / NULLIF(base_days, 0)) * @window_days, 2)
                                                                    AS hb_extra_revenue,

    -- same measure for the whole platform (control)
    ROUND(100.0 * ((ev_platform_revenue * 1.0 / @window_days)
                 / NULLIF(base_platform_revenue * 1.0 / NULLIF(base_days, 0), 0) - 1), 1)
                                                                    AS platform_uplift_pct,

    -- how much stronger (or weaker) Health & Beauty was than the platform, in percentage points
    ROUND(100.0 * ((ev_hb_revenue * 1.0 / @window_days)
                 / NULLIF(base_hb_revenue * 1.0 / NULLIF(base_days, 0), 0) - 1)
        - 100.0 * ((ev_platform_revenue * 1.0 / @window_days)
                 / NULLIF(base_platform_revenue * 1.0 / NULLIF(base_days, 0), 0) - 1), 1)
                                                                    AS hb_vs_platform_pp,

    -- volume: did orders rise, or only order value?
    ROUND(100.0 * ((ev_hb_orders * 1.0 / @window_days)
                 / NULLIF(base_hb_orders * 1.0 / NULLIF(base_days, 0), 0) - 1), 1)
                                                                    AS hb_orders_uplift_pct,

    -- Health & Beauty share of platform revenue, event vs baseline
    ROUND(100.0 * ev_hb_revenue   / NULLIF(ev_platform_revenue, 0), 2)   AS hb_share_event_pct,
    ROUND(100.0 * base_hb_revenue / NULLIF(base_platform_revenue, 0), 2) AS hb_share_baseline_pct
FROM event_totals
ORDER BY window_end
OPTION (MAXRECURSION 0);   -- the date list is longer than SQL Server's default limit of 100 rows
