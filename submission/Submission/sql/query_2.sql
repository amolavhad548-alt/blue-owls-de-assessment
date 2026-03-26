WITH seller_metrics AS (
    SELECT
        ds.seller_id,
        ds.seller_state,
        COUNT(DISTINCT foi.order_id) AS total_orders,
        SUM(COALESCE(foi.payment_value, 0)) AS total_revenue,
        AVG(CASE WHEN foi.is_late_delivery = 1 THEN 1.0 ELSE 0.0 END) AS late_delivery_rate,
        AVG(foi.days_delivery_vs_estimate) AS avg_days_vs_estimate
    FROM fact_order_items foi
    JOIN dim_sellers ds
      ON foi.seller_key = ds.seller_key
    GROUP BY ds.seller_id, ds.seller_state
    HAVING COUNT(DISTINCT foi.order_id) >= 20
),
percentiles AS (
    SELECT
        *,
        PERCENT_RANK() OVER (ORDER BY total_revenue) AS revenue_pctl,
        PERCENT_RANK() OVER (ORDER BY avg_days_vs_estimate DESC) AS speed_pctl,
        PERCENT_RANK() OVER (ORDER BY late_delivery_rate DESC) AS on_time_pctl
    FROM seller_metrics
)
SELECT
    seller_id,
    seller_state,
    total_orders,
    total_revenue,
    late_delivery_rate,
    avg_days_vs_estimate,
    on_time_pctl,
    speed_pctl,
    revenue_pctl,
    (on_time_pctl * 0.4 + speed_pctl * 0.3 + revenue_pctl * 0.3) AS composite_score,
    RANK() OVER (
        ORDER BY (on_time_pctl * 0.4 + speed_pctl * 0.3 + revenue_pctl * 0.3) DESC
    ) AS overall_rank
FROM percentiles
ORDER BY overall_rank;