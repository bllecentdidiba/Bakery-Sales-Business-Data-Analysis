-- 7.Monthly Seasonality
SELECT 
    TO_CHAR(DATE_TRUNC('month', order_date), 'Month') as month_name,
    EXTRACT(MONTH FROM order_date) as month_number,
    COUNT(DISTINCT order_id) as total_orders,
    round(SUM(total_amount)::numeric,2) as total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) as avg_order_value,
    SUM(quantity) as total_items,
    ROUND((SUM(total_amount) - LAG(SUM(total_amount)) OVER (ORDER BY EXTRACT(MONTH FROM order_date)))::numeric, 2) as revenue_change_from_prev_month
FROM fact_orders
WHERE EXTRACT(YEAR FROM order_date) = 2026
GROUP BY DATE_TRUNC('month', order_date), EXTRACT(MONTH FROM order_date)
ORDER BY month_number;
