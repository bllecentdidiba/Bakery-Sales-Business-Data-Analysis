--6.Business Problem: What days of the week and months drive the most revenue? 
--Should we run promotions on slow days?
SELECT 
    order_day_of_week,
    COUNT(DISTINCT order_id) as order_count,
    COUNT(DISTINCT customer_id) as unique_customers,
    round(SUM(total_amount)::numeric, 2) as total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) as avg_order_value,
    ROUND((SUM(total_amount) * 100/ SUM(SUM(total_amount)) OVER ())::numeric, 2) as revenue_percentage,
    RANK() OVER (ORDER BY SUM(total_amount) DESC) as revenue_rank
FROM fact_orders
WHERE EXTRACT(YEAR FROM order_date) = 2026
GROUP BY order_day_of_week
ORDER BY revenue_rank;
