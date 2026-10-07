/*
Auf Grundlage der zuvor bereinigten Daten wird ein EDA (Exploratory Data Analysis) vorgenommen. 
Dabei liegt der Fokus auf der Untersuchung relevanter Kennzahlen (Measures Exploring), 
deren Größenordnung (Megnitude) sowie der Rangfolge der betrachteten Werte (Ranking).
*/

------------------------------------------------ ab hier folgen SQL-Auszüge aus dem Measures Exploring

SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales 
  -- wie viel Gewinn wurde durch das Verkaufen von Produkten erwirtschaftet
UNION ALL
SELECT 'Total Quantity' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales 
  -- wie viele Produkte wurden insgesamt verkauft
UNION ALL
SELECT 'Average Price' AS measure_name, AVG(price) AS measure_value FROM gold.fact_sales 
  -- der durchschnittlicher Verkaufspreis der Produkte
UNION ALL
SELECT 'Total Nr. Orders' AS measure_name, COUNT(order_number) AS measure_value FROM gold.fact_sales 
  -- die Summe an Bestellungen 
UNION ALL
SELECT 'Total orders from different customers' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales 
  -- die Summe an Kunden die bereits etwas bestellt haben abzüglich der Bestellungen die vom selben Kunden kommen
UNION ALL
SELECT 'Total Nr. Products' AS measure_name, COUNT(DISTINCT product_name) AS measure_value FROM gold.dim_products 
  -- die Anzahl an Produkten die angeboten werden
UNION ALL
SELECT 'Total Nr. Customers' AS measure_name, COUNT(customer_key) AS measure_value FROM gold.dim_customers 
  -- Anzahl der Kunden in gold.dim_customers
UNION ALL
SELECT 'Customers that already ordered something' AS measure_name, COUNT(DISTINCT customer_key) AS measure_value FROM gold.fact_sales 
  -- Anzahl der Kunden in gold.dim_customers die bereits etwas bestellt haben

------------------------------------------------ ab hier folgen SQL-Auszüge aus deren Megnitude

SELECT -- Anzahl der Kunden pro Land
country,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC

  
SELECT -- Anzahl der Kunden pro Geschlecht
gender,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC

  
SELECT -- Anzahl der Produkte pro Kategorie
category,
COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC

  
SELECT -- Durchschnittliche Kosten pro Kategorie
category,
AVG(cost) AS average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC

  
SELECT -- Gesamter Gewinn pro Kategorie
dp.category,
SUM(fs.sales_amount) AS total_revenue
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_products AS dp
ON dp.product_key = fs.product_key
GROUP BY category
ORDER BY total_revenue DESC

  
SELECT -- Gewinn pro Kunde
dc.customer_key,
dc.first_name,
dc.last_name,
SUM(fs.sales_amount) AS total_revenue
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
ON dc.customer_key = fs.customer_key
GROUP BY dc.customer_key,
dc.first_name,
dc.last_name
ORDER BY total_revenue DESC

  
SELECT -- Wie viele Produkte in welchen Ländern verkauf wurden
dc.country,
SUM(fs.quantity) AS total_sold_items
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
ON dc.customer_key = fs.customer_key
GROUP BY dc.country
ORDER BY total_sold_items DESC

------------------------------------------------ ab hier folgen SQL-Auszüge aus dem Ranking

SELECT TOP 5 -- Die fünf Produkte, die den höchsten Gewinn erzielen
dp.product_name,
SUM(fs.sales_amount) AS total_revenue
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_products AS dp
ON fs.product_key = dp.product_key
GROUP BY dp.product_name
ORDER BY total_revenue DESC

  
SELECT *
FROM (
	SELECT -- Die fünf Produkte, die den höchsten Gewinn erzielen -- Alternativ als Window-Function
	dp.product_name,
	SUM(fs.sales_amount) AS total_revenue,
	ROW_NUMBER() OVER (ORDER BY SUM(fs.sales_amount) DESC) AS rank_products
	FROM gold.fact_sales AS fs
	LEFT JOIN gold.dim_products AS dp
	ON fs.product_key = dp.product_key
	GROUP BY dp.product_name
)t 
WHERE rank_products <= 5


SELECT TOP 5 -- Die fünf Produkte, die am wenigsten Gewinn erzielen
dp.product_name,
SUM(fs.sales_amount) AS total_revenue
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_products AS dp
ON fs.product_key = dp.product_key
GROUP BY dp.product_name
ORDER BY total_revenue ASC

  
SELECT TOP 10 -- Top 10 Kunden, die den meisten Gewinn generiert haben
dc.customer_key,
dc.first_name,
dc.last_name,
SUM(fs.sales_amount) AS total_revenue
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_key,
dc.first_name,
dc.last_name
ORDER BY total_revenue DESC

  
SELECT TOP 3 -- Unterste 3 Kunden, die am wenigsten Bestellungen getätigt haben
dc.customer_key,
dc.first_name,
dc.last_name,
COUNT(DISTINCT fs.order_number) AS total_orders
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_key,
dc.first_name,
dc.last_name
ORDER BY total_orders ASC
