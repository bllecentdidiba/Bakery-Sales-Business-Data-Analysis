--5.Business Problem: Are customers moving up in tiers? Compare signup tier vs. current performance tier.
WITH customer_performance AS (
    SELECT c.customer_id, c.customer_tier as signup_tier,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(o.total_amount) as total_spent,
        AVG(o.total_amount) as avg_order_value,
        CASE 
            WHEN SUM(o.total_amount) >= 1000 THEN 'Gold'
            WHEN SUM(o.total_amount) >= 500 THEN 'Silver'
            ELSE 'Bronze'
        END as performance_tier,
        CASE 
            WHEN SUM(o.total_amount) >= 1000 AND c.customer_tier != 'Gold' THEN '⬆️ Upgraded'
            WHEN SUM(o.total_amount) < 500 AND c.customer_tier = 'Gold' THEN '⬇️ Downgraded'
            ELSE '➡️ Same'
        END as tier_migration
    FROM dim_customer c
    JOIN fact_orders o ON c.customer_id = o.customer_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY c.customer_id, c.customer_tier
)
SELECT 
    signup_tier,
    performance_tier,
    tier_migration,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent)::numeric, 2) as avg_spend,
    ROUND(AVG(order_count), 2) as avg_orders,
    ROUND(AVG(avg_order_value)::numeric, 2) as avg_order_value
FROM customer_performance
GROUP BY signup_tier, performance_tier, tier_migration
ORDER BY signup_tier, performance_tier;
