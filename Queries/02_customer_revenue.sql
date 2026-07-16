--Business Problem: Marketing wants to identify their most valuable customers. 
--Who are the top 10 customers by revenue, and what percentage of total revenue do they represent?
WITH customer_revenue AS (
    SELECT c.customer_id, c.city,c.customer_tier, COUNT(DISTINCT o.order_id) as total_orders, SUM(o.total_amount) as total_spent,
        AVG(o.total_amount) as avg_order_value,
        SUM(o.quantity) as total_items,
        DENSE_RANK() OVER (ORDER BY SUM(o.total_amount) DESC) as revenue_rank
    FROM dim_customer c
  JOIN fact_orders o ON c.customer_id = o.customer_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY c.customer_id, c.city, c.customer_tier
),
total_revenue_2026 AS (
    SELECT SUM(total_amount) as total FROM fact_orders 
    WHERE EXTRACT(YEAR FROM order_date) = 2026
)
SELECT 
    cr.customer_id,
    cr.city,
    cr.customer_tier,
    cr.total_orders,
    ROUND(cr.total_spent::numeric, 2) as total_spent,
    ROUND(cr.avg_order_value::numeric, 2) as avg_order,
    ROUND(((cr.total_spent / tr.total) * 100)::numeric, 2) as pct_of_total_revenue, cr.revenue_rank
FROM customer_revenue cr
CROSS JOIN total_revenue_2026 tr
WHERE cr.revenue_rank <= 10
ORDER BY cr.revenue_rank; 
