--3.Business Problem: Identify customers who haven't ordered in the last 3 months (churn risk) vs new customers in 2026.
WITH customer_last_order AS (
    SELECT 
        customer_id,
        MAX(order_date) as last_order_date,
        COUNT(*) as total_orders_lifetime,
        SUM(total_amount) as lifetime_value
    FROM fact_orders
    GROUP BY customer_id
),
customer_segments AS (
    SELECT 
        c.customer_id,
        c.city,
        c.customer_tier,
        cl.last_order_date,
        cl.total_orders_lifetime,
        ROUND(cl.lifetime_value::numeric, 2) as lifetime_value,
        CASE 
            WHEN cl.last_order_date >= '2026-10-01' THEN 'Active (Last 3 Months)'
            WHEN cl.last_order_date >= '2026-07-01' THEN 'At Risk (4-6 Months)'
            WHEN cl.last_order_date >= '2026-01-01' THEN 'Dormant (7-12 Months)'
            ELSE 'Churned (Over 1 Year)'
        END as churn_risk_category,
        CASE 
            WHEN c.signup_date >= '2026-01-01' THEN 'New 2026 Customer'
            ELSE 'Existing Customer'
        END as customer_type
    FROM dim_customer c
    LEFT JOIN customer_last_order cl ON c.customer_id = cl.customer_id
)
SELECT 
    churn_risk_category,
    customer_type,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value)::numeric, 2) as avg_lifetime_value,
    SUM(total_orders_lifetime) as total_orders_placed,
    ROUND(SUM(lifetime_value)::numeric, 2) as total_revenue_contribution
FROM customer_segments
GROUP BY churn_risk_category, customer_type
ORDER BY 
    CASE churn_risk_category
        WHEN 'Active (Last 3 Months)' THEN 1
        WHEN 'At Risk (4-6 Months)' THEN 2
        WHEN 'Dormant (7-12 Months)' THEN 3
        ELSE 4
    END;
