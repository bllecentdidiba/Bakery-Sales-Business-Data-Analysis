--11.RFM segment
WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        c.city,
        c.customer_tier,
        c.signup_date,
        MAX(o.order_date) as last_order_date,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(o.total_amount) as total_spent,
        AVG(o.total_amount) as avg_order_value
    FROM dim_customer c
    LEFT JOIN fact_orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.city, c.customer_tier, c.signup_date
),
rfm_scores AS (
    SELECT 
        customer_id,
        city,
        customer_tier,
        signup_date,
        last_order_date,
        order_count,
        total_spent,
        avg_order_value,
        -- Recency: 1-5 based on percentile
        CASE 
            WHEN PERCENT_RANK() OVER (ORDER BY last_order_date DESC) <= 0.2 THEN 5
            WHEN PERCENT_RANK() OVER (ORDER BY last_order_date DESC) <= 0.4 THEN 4
            WHEN PERCENT_RANK() OVER (ORDER BY last_order_date DESC) <= 0.6 THEN 3
            WHEN PERCENT_RANK() OVER (ORDER BY last_order_date DESC) <= 0.8 THEN 2
            ELSE 1
        END as recency_score,
        -- Frequency: 1-5 based on percentile
        CASE 
            WHEN PERCENT_RANK() OVER (ORDER BY order_count) <= 0.2 THEN 1
            WHEN PERCENT_RANK() OVER (ORDER BY order_count) <= 0.4 THEN 2
            WHEN PERCENT_RANK() OVER (ORDER BY order_count) <= 0.6 THEN 3
            WHEN PERCENT_RANK() OVER (ORDER BY order_count) <= 0.8 THEN 4
            ELSE 5
        END as frequency_score,
        -- Monetary: 1-5 based on percentile
        CASE 
            WHEN PERCENT_RANK() OVER (ORDER BY total_spent) <= 0.2 THEN 1
            WHEN PERCENT_RANK() OVER (ORDER BY total_spent) <= 0.4 THEN 2
            WHEN PERCENT_RANK() OVER (ORDER BY total_spent) <= 0.6 THEN 3
            WHEN PERCENT_RANK() OVER (ORDER BY total_spent) <= 0.8 THEN 4
            ELSE 5
        END as monetary_score
    FROM customer_rfm
    WHERE last_order_date IS NOT NULL
)
SELECT 
    customer_id,
    city,
    customer_tier,
    last_order_date,
    order_count,
    ROUND(total_spent::numeric, 2) as total_spent,
    recency_score,
    frequency_score,
    monetary_score,
    -- Combined RFM Score (out of 15)
    (recency_score + frequency_score + monetary_score) as rfm_total,
    -- Customer Segment
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 4 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Potential Loyalists'
        WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'New Customers'
        WHEN recency_score >= 3 AND frequency_score >= 1 AND monetary_score >= 1 THEN 'Promising'
        WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Need Attention'
        WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Lost Customers'
        ELSE 'Other'
    END as customer_segment
FROM rfm_scores
ORDER BY rfm_total DESC, total_spent DESC;
