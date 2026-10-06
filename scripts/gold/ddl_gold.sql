/*
DDL Script, welches die Gold Views erstellt.
------------------------------------------------
Zu beachten:
	Zuerst folgen wenige, kleine Tests, anhand derer getestet wird, welche 
	Spalten noch zusammengeführt werden müssen oder ähnliches, bevor die jeweilige View erstellt wird.
*/

------------------------------------------------ ab hier wird auf Unstimmigkeiten geprüft und dann gold.dim_customers erstellt

SELECT cst_id, COUNT(*) --testen, ob es auch wirklich keine Duplikate gibt
FROM (
SELECT 
ci.cst_id,
ci.cst_key,
ci.cst_firstname,
ci.cst_lastname,
ci.cst_marital_status,
ci.cst_gndr,
ci.cst_create_date,
ca.bdate,
ca.gen,
la.cntry
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid
)t GROUP BY cst_id
HAVING COUNT(*) > 1


SELECT DISTINCT --testen, wie sich die unterschiedlichen Geschlechtsspalten zu einer zusammenführen lassen
ci.cst_gndr,
ca.gen,
CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
	 ELSE COALESCE(ca.gen, 'n/a')
END AS new_gen
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid
ORDER BY 1,2

------------------------------------------------
	
--gesamte Query, welche die die View erstellt
CREATE VIEW gold.dim_customers AS 
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, --surrogate key wird verwendet
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr --das CRM hat verlässlichere Daten, daher werden die dort angegebenen Geschlechtsinformationen vorgezogen wenn vorhanden
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid

------------------------------------------------ ab hier wird auf Unstimmigkeiten geprüft und dann gold.dim_products erstellt
	
--gesamte Query, welche die die View erstellt
CREATE VIEW gold.dim_products AS
SELECT 
ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pn.cat_id AS category_id,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL --alle in der Vergangenheit liegenden Daten sollen nicht in der gold-view inbegriffen sein

------------------------------------------------ ab hier wird auf Unstimmigkeiten geprüft und dann gold.fact_sales erstellt

SELECT * --nachdem die View erstellt wurde, wird so getestet, ob die JOINs auch für alle Elemente funktioniert haben
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
ON fs.customer_key = dc.customer_key
LEFT JOIN gold.dim_products AS dp
ON fs.product_key = dp.product_key
WHERE dc.customer_key IS NULL OR dp.product_key IS NULL

------------------------------------------------
	
--gesamte Query, welche die die View erstellt
CREATE VIEW gold.fact_sales AS 
SELECT
sd.sls_ord_num AS order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
ON sd.sls_cust_id = cu.customer_id
