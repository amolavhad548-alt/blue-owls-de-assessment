WITH monthly_revenue AS (
    SELECT
        dp.product_category_name,
        YEAR(CAST(foi.order_date AS DATE)) AS year,
        MONTH(CAST(foi.order_date AS DATE)) AS month,
        COUNT(*) AS txn_count,
        SUM(COALESCE(foi.price, 0) + COALESCE(foi.freight_value, 0)) AS monthly_revenue
    FROM fact_order_items foi
    JOIN dim_products dp
      ON foi.product_key = dp.product_key
    GROUP BY dp.product_category_name,
             YEAR(CAST(foi.order_date AS DATE)),
             MONTH(CAST(foi.order_date AS DATE))
    HAVING COUNT(*) >= 10
),
top_5_categories AS (
    SELECT product_category_name
    FROM monthly_revenue
    GROUP BY product_category_name
    ORDER BY SUM(monthly_revenue) DESC
    LIMIT 5
),
ranked AS (
    SELECT
        mr.*,
        RANK() OVER (
            PARTITION BY year, month
            ORDER BY monthly_revenue DESC
        ) AS monthly_rank,
        LAG(monthly_revenue) OVER (
            PARTITION BY product_category_name
            ORDER BY year, month
        ) AS prev_month_revenue,
        AVG(monthly_revenue) OVER (
            PARTITION BY product_category_name
            ORDER BY year, month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3m_avg_revenue
    FROM monthly_revenue mr
    JOIN top_5_categories t
      ON mr.product_category_name = t.product_category_name
)
SELECT
    product_category_name,
    year,
    month,
    monthly_revenue,
    monthly_rank,
    CASE
        WHEN prev_month_revenue IS NULL OR prev_month_revenue = 0 THEN NULL
        ELSE ((monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100
    END AS mom_growth_pct,
    rolling_3m_avg_revenue
FROM ranked
ORDER BY product_category_name, year, month;