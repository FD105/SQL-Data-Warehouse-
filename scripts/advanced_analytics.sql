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
