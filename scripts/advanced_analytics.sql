/*
Auf Grundlage der zuvor bereinigten Daten wird in diesem Abschnitt nun noch tiefer in 
die Daten eingetaucht, um eine genauerer Analyse dieser bereitstellen zu können.
Dabei wird folgendes betrachtet:
- Change-Over-Time
- Cumulative Analysis
- Performance Analysis
- Part-to-Whole
- Data Segmentation
- Reporting
*/

------------------------------------------------ ab hier folgen SQL-Auszüge für dem Change-Over-Time

SELECT -- gesamte Verkäufe pro Jahr
YEAR(order_date) AS order_year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

SELECT -- gesamte Verkäufe pro Monat 
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)

SELECT -- gesamte Verkäufe pro Monat und Jahr in einer Tabelle vereint
DATETRUNC(month, order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)

------------------------------------------------ ab hier folgen SQL-Auszüge für der Cumulative Analysis

SELECT -- Berechnen des gesamten Gewinns pro Jahr sowie der kumulativen Gewinne und durchschnittlichen Preise der Produkte über die Jahre
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
