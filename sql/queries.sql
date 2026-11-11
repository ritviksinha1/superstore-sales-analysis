-- =====================================================================
-- Superstore Sales Analysis: SQL queries (SQLite)
-- Table: orders  (created by sql/load_to_sqlite.py)
-- Columns: order_id, order_date, ship_date, ship_mode, customer_id,
--          customer_name, segment, country, city, state, postal_code,
--          region, product_id, category, sub_category, product_name,
--          sales, quantity, discount, profit
-- =====================================================================


-- Q1. Overall business snapshot
SELECT
    ROUND(SUM(sales), 0)                          AS total_sales,
    ROUND(SUM(profit), 0)                         AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 1)    AS margin_pct,
    COUNT(DISTINCT order_id)                      AS total_orders
FROM orders;


-- Q2. Sales, profit and margin by category
SELECT
    category,
    ROUND(SUM(sales), 0)                          AS sales,
    ROUND(SUM(profit), 0)                         AS profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 1)    AS margin_pct
FROM orders
GROUP BY category
ORDER BY profit DESC;


-- Q3. Loss-making sub-categories (HAVING filters after grouping)
SELECT
    sub_category,
    ROUND(SUM(profit), 0) AS total_profit
FROM orders
GROUP BY sub_category
HAVING SUM(profit) < 0
ORDER BY total_profit;


-- Q4. Yearly sales and year-over-year growth (CTE + LAG window function)
WITH yearly AS (
    SELECT
        CAST(strftime('%Y', order_date) AS INTEGER) AS year,
        SUM(sales)                                  AS sales,
        SUM(profit)                                 AS profit
    FROM orders
    GROUP BY year
)
SELECT
    year,
    ROUND(sales, 0)  AS sales,
    ROUND(profit, 0) AS profit,
    ROUND((sales - LAG(sales) OVER (ORDER BY year)) * 100.0
          / LAG(sales) OVER (ORDER BY year), 1) AS sales_growth_pct
FROM yearly
ORDER BY year;


-- Q5. Seasonality: sales by calendar month, all years combined
SELECT
    strftime('%m', order_date) AS month,
    ROUND(SUM(sales), 0)       AS sales
FROM orders
GROUP BY month
ORDER BY month;


-- Q6. Regional performance
SELECT
    region,
    ROUND(SUM(sales), 0)                          AS sales,
    ROUND(SUM(profit), 0)                         AS profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 1)    AS margin_pct
FROM orders
GROUP BY region
ORDER BY profit DESC;


-- Q7. Five worst states by profit, with their average discount
SELECT
    state,
    ROUND(SUM(profit), 0)           AS profit,
    ROUND(AVG(discount) * 100, 1)   AS avg_discount_pct
FROM orders
GROUP BY state
ORDER BY profit
LIMIT 5;


-- Q8. Discount band analysis (CASE expression)
SELECT
    CASE
        WHEN discount = 0    THEN '1. None'
        WHEN discount <= 0.2 THEN '2. Low (up to 20%)'
        WHEN discount <= 0.4 THEN '3. Medium (20-40%)'
        ELSE                      '4. High (40%+)'
    END                         AS discount_band,
    COUNT(*)                    AS order_lines,
    ROUND(AVG(profit), 1)       AS avg_profit,
    ROUND(SUM(profit), 0)       AS total_profit
FROM orders
GROUP BY discount_band
ORDER BY discount_band;


-- Q9. Top 10 customers by sales, with rank (RANK window function)
SELECT *
FROM (
    SELECT
        customer_name,
        ROUND(SUM(sales), 0)                              AS sales,
        ROUND(SUM(profit), 0)                             AS profit,
        RANK() OVER (ORDER BY SUM(sales) DESC)            AS sales_rank
    FROM orders
    GROUP BY customer_name
)
WHERE sales_rank <= 10
ORDER BY sales_rank;


-- Q10. High-spending customers who are unprofitable (CTE)
WITH customer_totals AS (
    SELECT
        customer_name,
        SUM(sales)  AS sales,
        SUM(profit) AS profit
    FROM orders
    GROUP BY customer_name
)
SELECT
    customer_name,
    ROUND(sales, 0)  AS sales,
    ROUND(profit, 0) AS profit
FROM customer_totals
WHERE sales > 5000
  AND profit < 0
ORDER BY sales DESC;


-- Q11. Rank sub-categories by profit within each category
--      (RANK with PARTITION BY)
WITH sub_totals AS (
    SELECT
        category,
        sub_category,
        SUM(profit) AS profit
    FROM orders
    GROUP BY category, sub_category
)
SELECT
    category,
    sub_category,
    ROUND(profit, 0) AS profit,
    RANK() OVER (PARTITION BY category ORDER BY profit DESC) AS rank_in_category
FROM sub_totals
ORDER BY category, rank_in_category;


-- Q12. Running total of monthly sales (cumulative SUM window function)
WITH monthly AS (
    SELECT
        strftime('%Y-%m', order_date) AS year_month,
        SUM(sales)                    AS sales
    FROM orders
    GROUP BY year_month
)
SELECT
    year_month,
    ROUND(sales, 0)                                     AS monthly_sales,
    ROUND(SUM(sales) OVER (ORDER BY year_month), 0)     AS running_total
FROM monthly
ORDER BY year_month;
