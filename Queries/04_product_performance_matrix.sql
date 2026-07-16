-- QUERY 4: Product Performance Matrix
-- Business Problem: Identify which products are "Stars" (high revenue, high volume) 
-- vs. "Dogs" (low revenue, low volume).
WITH product_performance AS (
    SELECT 
        p.product_name,
        p.gluten_free,
        p.is_gluten_free,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(o.quantity) as total_quantity_sold,
        SUM(o.total_amount) as total_revenue,
        AVG(o.total_amount) as avg_revenue_per_order,
        ROUND(AVG(p.sales_price)::numeric, 2) as avg_price,
        ROUND(AVG(p.cost)::numeric, 2) as avg_cost,
        -- 🔥 FIX: Handle -Infinity by excluding invalid profit margins
        ROUND(AVG(
            CASE 
                WHEN p.sales_price > 0 THEN p.profit_margin 
                ELSE NULL 
            END
        )::numeric, 2) as avg_profit_margin
    FROM dim_product p
    JOIN fact_orders o ON p.product_id = o.product_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY p.product_name, p.gluten_free, p.is_gluten_free
),
performance_stats AS (
    SELECT 
        AVG(total_revenue) as avg_revenue,
        AVG(total_quantity_sold) as avg_quantity
    FROM product_performance
)
SELECT 
    pp.product_name,
    pp.gluten_free,
    pp.order_count,
    pp.total_quantity_sold,
    ROUND(pp.total_revenue::numeric, 2) as total_revenue,
    pp.avg_profit_margin,
    CASE 
        WHEN pp.total_revenue > (SELECT avg_revenue FROM performance_stats) 
         AND pp.total_quantity_sold > (SELECT avg_quantity FROM performance_stats) 
        THEN '⭐ STAR (High Revenue, High Volume)'
        WHEN pp.total_revenue > (SELECT avg_revenue FROM performance_stats) 
         AND pp.total_quantity_sold < (SELECT avg_quantity FROM performance_stats) 
        THEN '💰 CASH COW (High Revenue, Low Volume)'
        WHEN pp.total_revenue < (SELECT avg_revenue FROM performance_stats) 
         AND pp.total_quantity_sold > (SELECT avg_quantity FROM performance_stats) 
        THEN '❓ QUESTION MARK (Low Revenue, High Volume)'
        ELSE '🐕 DOG (Low Revenue, Low Volume)'
    END as performance_category,
    RANK() OVER (ORDER BY pp.total_revenue DESC) as revenue_rank
FROM product_performance pp
ORDER BY pp.total_revenue DESC;
