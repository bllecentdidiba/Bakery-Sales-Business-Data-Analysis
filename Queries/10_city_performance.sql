--10. Business Problem: Which cities are most profitable? Compare revenue generated vs. number of customers.
WITH city_metrics AS (
    SELECT 
        c.city,
        COUNT(DISTINCT c.customer_id) as total_customers,
        COUNT(DISTINCT c.customer_id) FILTER (
            WHERE c.signup_date >= '2026-01-01'
        ) as new_customers_2026,
        COUNT(DISTINCT o.order_id) as total_orders_2026,
        SUM(o.total_amount) as total_revenue_2026,
        ROUND(AVG(o.total_amount)::numeric, 2) as avg_order_value,
        SUM(o.quantity) as total_items_sold
    FROM dim_customer c
    LEFT JOIN fact_orders o ON c.customer_id = o.customer_id
        AND EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY c.city
),
city_rankings AS (
    SELECT 
        city,
        total_customers,
        new_customers_2026,
        ROUND((new_customers_2026*100/ NULLIF(total_customers, 0))::numeric, 2) as new_customer_pct,
        total_orders_2026,
        ROUND(total_revenue_2026::numeric, 2) as total_revenue,
        avg_order_value,
        total_items_sold,
        ROUND((total_revenue_2026 / NULLIF(total_customers, 0))::numeric, 2) as revenue_per_customer,
        RANK() OVER (ORDER BY total_revenue_2026 DESC) as revenue_rank,
        RANK() OVER (ORDER BY total_customers DESC) as customer_count_rank
    FROM city_metrics
)
SELECT 
    city,
    total_customers,
    new_customers_2026,
    new_customer_pct,
    total_revenue,
    avg_order_value,
    revenue_per_customer,
    revenue_rank,
    CASE 
        WHEN revenue_rank <= 3 THEN '💎 Top Performing City'
        WHEN revenue_rank > 10 AND total_customers > 100 THEN '📈 Growth Opportunity'
        WHEN total_customers < 50 THEN '🌱 Emerging Market'
        ELSE '📊 Stable Market'
    END as city_performance_category
FROM city_rankings
ORDER BY revenue_rank;
