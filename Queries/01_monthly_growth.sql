--Business Problem: The CEO wants to see if the bakery is growing month over month. 
--Calculate revenue, order count and month over month growth percentage.
WITH monthly_metrics AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        COUNT(DISTINCT order_id) as total_orders,
        COUNT(DISTINCT customer_id) as unique_customers,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        SUM(quantity) as total_items_sold
    FROM fact_orders
    WHERE EXTRACT(YEAR FROM order_date) = 2026
    GROUP BY DATE_TRUNC('month', order_date)
    ORDER BY month
)
SELECT 
    TO_CHAR(month, 'Month YYYY') as Month,
    total_orders,
    unique_customers,
    ROUND(total_revenue::numeric, 2) as Revenue,
    ROUND(avg_order_value::numeric, 2) as Avg_Order_Value,
    total_items_sold,
    ROUND((LAG(total_revenue) OVER (ORDER BY month))::NUMERIC,2) as previous_month_revenue,
    ROUND((
        ((total_revenue - LAG(total_revenue) OVER (ORDER BY month)) / 
        NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0)) * 100)::numeric, 
        2
    ) as Revenue_Growth_Pct
FROM monthly_metrics;
