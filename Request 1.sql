AtliQ Adhoc SQL Insights
	
Task 1
	# Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. 

SELECT distinct market FROM gdb023.dim_customer
	WHERE customer = "Atliq Exclusive"
    AND region = "APAC";



Task 2
	# What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
    unique_products_2020 
    unique_products_2021 
    percentage_chg 
	
SELECT 
  X.A AS unique_products_2020,
  Y.B AS unique_products_2021,
  ROUND((Y.B - X.A) * 100.0 / NULLIF(X.A, 0), 2) AS percentage_chg
FROM (
  SELECT COUNT(DISTINCT product_code) AS A
  FROM gdb023.fact_gross_price
  WHERE fiscal_year = 2020
) AS X
CROSS JOIN (
  SELECT COUNT(DISTINCT product_code) AS B
  FROM gdb023.fact_gross_price
  WHERE fiscal_year = 2021
) AS Y;



Task 3
	# Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
    segment 
    product_count 

SELECT 
    segment, 
    COUNT(DISTINCT product_code) AS product_count
FROM gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC;



Task 4
      # Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference
	
SELECT
    t2020.segment,
    t2020.product_count AS product_count_2020,
    t2021.product_count AS product_count_2021,
    (t2021.product_count - t2020.product_count) AS difference
FROM
    (
        SELECT
            dp.segment,
            COUNT(DISTINCT fgp.product_code) AS product_count
        FROM
            gdb023.fact_gross_price fgp
        JOIN
            gdb023.dim_product dp 
	    ON fgp.product_code = dp.product_code
        WHERE
            fgp.fiscal_year = 2020
        GROUP BY
            dp.segment
    ) AS t2020
INNER JOIN
    (
        SELECT
            dp.segment,
            COUNT(DISTINCT fgp.product_code) AS product_count
        FROM
            gdb023.fact_gross_price fgp
        JOIN
            gdb023.dim_product dp 
	    ON fgp.product_code = dp.product_code
        WHERE
            fgp.fiscal_year = 2021
        GROUP BY
            dp.segment
    ) AS t2021
    ON t2020.segment = t2021.segment
ORDER BY
    difference DESC;





Task 5
	  # Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost 

SELECT
    dp.product_code,
    dp.product,
    fmc.manufacturing_cost
FROM
    gdb023.fact_manufacturing_cost fmc
JOIN
    gdb023.dim_product dp 
ON fmc.product_code = dp.product_code
WHERE
    fmc.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM gdb023.fact_manufacturing_cost)

UNION ALL

SELECT
    dp.product_code,
    dp.product,
    fmc.manufacturing_cost
FROM
    gdb023.fact_manufacturing_cost fmc
JOIN
    gdb023.dim_product dp 
ON fmc.product_code = dp.product_code
WHERE
    fmc.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM gdb023.fact_manufacturing_cost);






Task 6
    # Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage 

SELECT
    dc.customer_code,
    dc.customer,
    ROUND(AVG(pid.pre_invoice_discount_pct) * 100, 2) AS average_discount_percentage
FROM
    gdb023.fact_pre_invoice_deductions pid
JOIN
    gdb023.dim_customer dc
ON
    pid.customer_code = dc.customer_code
WHERE
    pid.fiscal_year = 2021
    AND dc.market = 'India'
GROUP BY
    dc.customer_code,
    dc.customer
ORDER BY
    average_discount_percentage DESC
LIMIT 5;





Task 7
    #  Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount 

SELECT
    MONTHNAME(fsm.date) AS Month,
    YEAR(fsm.date) AS Year,
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price), 2)
 AS "Gross Sales Amount"
FROM
    gdb023.fact_sales_monthly fsm
JOIN
    gdb023.dim_customer dc
ON 
	fsm.customer_code = dc.customer_code
JOIN
    gdb023.fact_gross_price fgp
ON 
	fsm.product_code = fgp.product_code
AND fsm.fiscal_year = fgp.fiscal_year
WHERE
    dc.customer = 'Atliq Exclusive' 
GROUP BY
    Year,
    Month,
    MONTH(fsm.date) 
ORDER BY
    Year,
    MONTH(fsm.date);






Task 8
      # In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity 

SELECT
    CASE
        WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1' -- Assuming Fiscal Q1 starts September
        WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
        WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
        WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4'
        ELSE 'Unknown'
    END AS Quarter,
    ROUND(SUM(sold_quantity)/1000000, 2) AS total_sold_quantity
FROM
    gdb023.fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY
    Quarter
ORDER BY
    total_sold_quantity DESC
LIMIT 1;





Task 9
     # Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage

WITH ch AS (
  SELECT 
    c.channel,
    SUM(gp.gross_price * s.sold_quantity) AS gross_sales
  FROM gdb023.fact_sales_monthly s
  JOIN gdb023.fact_gross_price gp
    ON gp.product_code = s.product_code
   AND gp.fiscal_year = s.fiscal_year
  JOIN gdb023.dim_customer c
    ON c.customer_code = s.customer_code
  WHERE s.fiscal_year = 2021
  GROUP BY c.channel
)
SELECT
  channel,
  ROUND(gross_sales / 1000000, 2) AS gross_sales_mln,
  ROUND(100 * gross_sales / SUM(gross_sales) OVER (), 2) AS percentage
FROM ch
ORDER BY gross_sales DESC;





Task 10
# Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these fields: 
division 
product_code 
product 
total_sold_quantity 
rank_order 

WITH ProductSales AS (
    SELECT
        dp.division,
        dp.product_code,
        dp.product,
        SUM(fsm.sold_quantity) AS total_sold_quantity
    FROM
        gdb023.fact_sales_monthly fsm
    JOIN
        gdb023.dim_product dp
    ON
	    fsm.product_code = dp.product_code
    WHERE
        fsm.fiscal_year = 2021
    GROUP BY
        dp.division,
        dp.product_code,
        dp.product
),
RankedSales AS (
    SELECT
        division,
        product_code,
        product,
        total_sold_quantity,
        RANK() OVER (
            PARTITION BY division
            ORDER BY total_sold_quantity DESC 
        ) AS rank_order
    FROM
        ProductSales
)
SELECT
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM
    RankedSales
WHERE
    rank_order <= 3
ORDER BY
    division,
    rank_order;
