--8.Business Problem: What products do our Top 100 customers buy together? This helps with cross-selling.
WITH top_customers AS (
    SELECT 
        customer_id,
        SUM(total_amount) as total_spent
    FROM fact_orders
    WHERE EXTRACT(YEAR FROM order_date) = 2026
    GROUP BY customer_id
    ORDER BY total_spent DESC
    LIMIT 100
),
customer_product_matrix AS (
    SELECT 
        o.customer_id,
        p.product_name,
        COUNT(*) as purchase_count
    FROM fact_orders o
    JOIN dim_product p ON o.product_id = p.product_id
    WHERE o.customer_id IN (SELECT customer_id FROM top_customers)
    AND EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY o.customer_id, p.product_name
),
product_pairs AS (
    SELECT 
        a.product_name as product_1,
        b.product_name as product_2,
        COUNT(DISTINCT a.customer_id) as customers_who_bought_both
    FROM customer_product_matrix a
    JOIN customer_product_matrix b 
        ON a.customer_id = b.customer_id 
        AND a.product_name < b.product_name
    GROUP BY a.product_name, b.product_name
    HAVING COUNT(DISTINCT a.customer_id) >= 2
)
SELECT 
    product_1,
    product_2,
    customers_who_bought_both,
    ROUND(
        (customers_who_bought_both * 100.0 / (SELECT COUNT(*) FROM top_customers))::numeric,
        2
    ) as pct_of_top_customers
FROM product_pairs
ORDER BY customers_who_bought_both DESC
LIMIT 10;
