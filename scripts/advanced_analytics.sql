/*
Auf Grundlage der zuvor bereinigten Daten wird in diesem Abschnitt nun noch tiefer in 
die Daten eingetaucht, um eine genauerer Analyse dieser bereitstellen zu können.
Dabei wird folgendes betrachtet:
- Change-Over-Time
- Cumulative Analysis
- Performance Analysis
- Part-to-Whole Analysis
- Data Segmentation Analysis
- Reporting
*/

------------------------------------------------ ab hier folgen SQL-Auszüge für dem Change-Over-Time

 -- gesamte Verkäufe pro Jahr
SELECT
YEAR(order_date) AS order_year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

 -- gesamte Verkäufe pro Monat 
SELECT 
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)

 -- gesamte Verkäufe pro Monat und Jahr in einer Tabelle vereint
SELECT 
DATETRUNC(month, order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)

------------------------------------------------ ab hier folgen SQL-Auszüge für der Cumulative Analysis
 
 -- Berechnen des gesamten Gewinns pro Jahr sowie der kumulativen Gewinne und durchschnittlichen Preise der Produkte über die Jahre
SELECT 
order_date,
total_sales,
SUM(total_sales) OVER (ORDER BY order_date) AS runing_total_sales,
AVG(average_price) OVER (ORDER BY order_date) AS runing_average_price
FROM
(
SELECT 
DATETRUNC(year, order_date) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(price) AS average_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year, order_date) 
)t

------------------------------------------------ ab hier folgen SQL-Auszüge für der Performance Analysis

 -- Year-Over-Year-Analysis -- analysieren der jährlichen performance von Produkten durch das Vergleichen der Gewinne
 -- verglichen mit der durchschnittlichen Performance der Produkte und dem Gewinn des vorherigen Jahres
WITH yearly_product_sales AS ( 
SELECT
YEAR(fs.order_date) AS order_year,
dp.product_name,
SUM(fs.sales_amount) AS current_sales
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_products AS dp
ON fs.product_key = dp.product_key
WHERE order_date IS NOT NULL
GROUP BY  YEAR(fs.order_date),
dp.product_name
)
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) AS average_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS difference_from_average,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg.'
  WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg.'
  ELSE 'Avg.'
END AS average_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS difference_previous_year,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
  WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
  ELSE 'No Change'
END AS previous_year_change
FROM yearly_product_sales
ORDER BY  product_name, order_year 

------------------------------------------------ ab hier folgen SQL-Auszüge für die Part-tp-Whole Analysis

  -- welche Kategorien tragen am meisten zum gesamten Gewinn bei
 WITH category_sales AS (
 SELECT
 category,
 SUM(sales_amount) AS total_sales
 FROM gold.fact_sales AS fs
 LEFT JOIN gold.dim_products AS dp
 ON fs.product_key = dp.product_key
 GROUP BY category
 )
 SELECT
 category,
 total_sales,
 SUM(total_sales) OVER () AS overall_sales,
 CONCAT(ROUND((CAST (total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
 FROM category_sales
 ORDER BY total_sales DESC

------------------------------------------------ ab hier folgen SQL-Auszüge für die Data Segmentation Analysis

 -- segmentieren von Produkten in Kosten-Bereiche -- zählen wie viele Produkte in die entsprechenden Bereiche fallen
WITH product_segments AS (
SELECT
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
  WHEN cost BETWEEN 100 AND 500 THEN '100-500'
  WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
  ELSE 'Above 1000'
END AS cost_range
FROM gold.dim_products
)
SELECT
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

 -- Kunden in Segmente einordnen basierend auf ihrem Kaufverhalten
WITH customer_spending AS (
SELECT
dc.customer_key,
SUM(fs.sales_amount) AS total_spending,
MIN(fs.order_date) AS first_order,
MAX(fs.order_date) AS last_order,
DATEDIFF(month, MIN(fs.order_date), MAX(fs.order_date)) AS lifespan
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_key
)
SELECT
customer_key,
total_spending,
lifespan,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
  WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
  ELSE 'New'
END AS customer_segment
FROM customer_spending
ORDER BY total_spending DESC


 -- aufbauend auf der vorherigen Query die Kunden in den verschiedenen Segmenten zählen
WITH customer_spending AS (
SELECT
dc.customer_key,
SUM(fs.sales_amount) AS total_spending,
MIN(fs.order_date) AS first_order,
MAX(fs.order_date) AS last_order,
DATEDIFF(month, MIN(fs.order_date), MAX(fs.order_date)) AS lifespan
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_key
)

SELECT 
customer_segment,
COUNT(customer_key) AS total_customers
FROM (
SELECT
customer_key,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
  WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
  ELSE 'New'
END AS customer_segment
FROM customer_spending
) t
GROUP BY customer_segment 
ORDER BY total_customers DESC

------------------------------------------------ ab hier folgen SQL-Auszüge für das Reporting
