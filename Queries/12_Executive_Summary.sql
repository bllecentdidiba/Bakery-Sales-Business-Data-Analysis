--11.Business Problem: The CEO wants a single-page executive summary with all key metrics.
WITH executive_metrics AS (
    SELECT 
        -- Overall Performance
        COUNT(DISTINCT order_id) as total_orders,
        COUNT(DISTINCT customer_id) as unique_customers,
        ROUND(SUM(total_amount)::numeric, 2) as total_revenue,
        ROUND(AVG(total_amount)::numeric, 2) as avg_order_value,
        SUM(quantity) as total_items_sold,
        -- Customer Metrics
        COUNT(DISTINCT customer_id) FILTER (
            WHERE customer_id IN (
                SELECT customer_id FROM dim_customer
                WHERE signup_date >= '2026-01-01'
            )
        ) as new_customers_2026,
        -- Order Quality
        ROUND(AVG(order_rating)::numeric, 2) as avg_rating,
        COUNT(*) FILTER (WHERE order_rating >= 4) as high_rated_orders,
        ROUND((COUNT(*) FILTER (WHERE order_rating >= 4) * 100 / COUNT(*))::numeric, 2) as high_rating_pct,
        -- Revenue Concentration
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_amount) as median_order_value,
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY total_amount) as p90_order_value,
        -- Time Based
        COUNT(DISTINCT order_date) as active_days_in_2026,
        ROUND((SUM(total_amount) / NULLIF(COUNT(DISTINCT order_date), 0))::numeric, 2) as revenue_per_day
    FROM fact_orders
    WHERE EXTRACT(YEAR FROM order_date) = 2026
),
top_products AS (
    SELECT 
        p.product_name,
        SUM(o.total_amount) as revenue
    FROM dim_product p
    JOIN fact_orders o ON p.product_id = o.product_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY p.product_name
    ORDER BY revenue DESC
    LIMIT 5
),
customer_tier_dist AS (
    SELECT 
        c.customer_tier,
        COUNT(DISTINCT c.customer_id) as count,
        ROUND(SUM(o.total_amount)::numeric, 2) as revenue
    FROM dim_customer c
    JOIN fact_orders o ON c.customer_id = o.customer_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY c.customer_tier
    ORDER BY revenue DESC
)
SELECT 
    '📊 2026 EXECUTIVE SUMMARY' as report_section,
    'TOTAL REVENUE' as metric_name,
    CONCAT('R', total_revenue) as value,
    CONCAT(total_orders, ' orders from ', unique_customers, ' customers') as notes
FROM executive_metrics
UNION ALL
SELECT 
    '📊 2026 EXECUTIVE SUMMARY',
    'AVG ORDER VALUE',
    CONCAT('R', avg_order_value),
    CONCAT('Median: R', median_order_value, ' | P90: R', p90_order_value)
FROM executive_metrics
UNION ALL
SELECT 
    '📊 2026 EXECUTIVE SUMMARY',
    'AVG RATING',
    CAST(avg_rating as text),
    CONCAT(high_rating_pct, '% of orders are 4★+')
FROM executive_metrics
UNION ALL
SELECT 
    '📊 2026 EXECUTIVE SUMMARY',
    'NEW CUSTOMERS',
    CAST(new_customers_2026 as text),
    CONCAT('Total customer base: ', unique_customers)
FROM executive_metrics
UNION ALL
SELECT 
    '📊 2026 EXECUTIVE SUMMARY',
    'TOP PRODUCTS',
    (SELECT STRING_AGG(product_name || ' (R' || ROUND(revenue) || ')', ', ' ORDER BY revenue DESC ) FROM top_products),
    'Top 3 products by revenue'
UNION ALL
SELECT 
    '📊 2026 EXECUTIVE SUMMARY',
    'CUSTOMER TIERS',
    (SELECT STRING_AGG(customer_tier || ': ' || count || ' customers', ', ' ORDER BY revenue DESC) FROM customer_tier_dist),
    'Distribution by tier'
UNION ALL
SELECT 
    '📊 2026 EXECUTIVE SUMMARY',
    'DAILY PERFORMANCE',
    CONCAT('R', revenue_per_day, '/day'),
    CONCAT('Active days: ', active_days_in_2026)
FROM executive_metrics;
