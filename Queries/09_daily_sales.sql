--9.Business Problem: Calculate how many days of inventory we have for each product. Which products are overstocked or understocked?
WITH daily_sales AS (
    SELECT p.product_name, SUM(o.quantity) as total_sold_2026,
       AVG(o.quantity) as avg_daily_sales, COUNT(DISTINCT o.order_date) as days_with_sales
    FROM dim_product p
    JOIN fact_orders o ON p.product_id = o.product_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY p.product_name
),
inventory_status AS (
    SELECT 
        p.product_name, p.quantity as current_inventory, COALESCE(ds.total_sold_2026, 0) as total_sold_2026,
        CASE 
            WHEN ds.avg_daily_sales IS NULL OR ds.avg_daily_sales = 0 
            THEN 'No Sales in 2026'
            ELSE ROUND(p.quantity / ds.avg_daily_sales, 2)::text || ' days'
        END as days_of_inventory,
        CASE 
            WHEN p.quantity = 0 AND COALESCE(ds.total_sold_2026, 0) > 0 THEN '🚨 OUT OF STOCK'
            WHEN p.quantity > 0 AND COALESCE(ds.total_sold_2026, 0) = 0 THEN '⚠️ SLOW MOVER (No 2026 Sales)'
            WHEN p.quantity / NULLIF(ds.avg_daily_sales, 0) > 90 THEN '📦 OVERSTOCKED (>90 days)'
            WHEN p.quantity / NULLIF(ds.avg_daily_sales, 0) < 14 THEN '⚡ LOW STOCK (<14 days)'
            ELSE '✅ HEALTHY INVENTORY'
        END as inventory_status,
        ROUND(p.cost::numeric, 2) as unit_cost,
        ROUND(p.sales_price::numeric, 2) as sales_price,
        ROUND((p.sales_price - p.cost)::numeric, 2) as profit_per_unit
    FROM dim_product p
    LEFT JOIN daily_sales ds ON p.product_name = ds.product_name
)
SELECT 
    product_name,
    current_inventory,
    total_sold_2026,
    days_of_inventory,
    inventory_status,
    unit_cost,
    sales_price,
    profit_per_unit
FROM inventory_status
WHERE inventory_status != '✅ HEALTHY INVENTORY'
ORDER BY 
    CASE inventory_status
        WHEN '🚨 OUT OF STOCK' THEN 1
        WHEN '⚡ LOW STOCK (<14 days)' THEN 2
        WHEN '📦 OVERSTOCKED (>90 days)' THEN 3
        WHEN '⚠️ SLOW MOVER (No 2026 Sales)' THEN 4
    END;
