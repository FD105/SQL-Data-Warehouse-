/*
DDL Script, welches die Silber Tables erstellt.
------------------------------------------------
Zu beachten:
	Das Script erstellt die Table für das Silber-Schema.
	In den folgenden Schritten werden die Daten die in den Bronze Tables entahlten sind, 
	bereinigt und dann in die Silber Tables überführt.
	Die vorn an die eigentliche INSERT-Query angestellten Queries verfolgten den Zweck, erstmal zu testen, wo möglicher Weise 
	Probleme in den Daten bestehen können und die Query am Ende der individuellen Blöcke setzt diese dann für den 
	entsprechenden Table um.
	Im folgenden gibt es sechs abgetrennte und mit dem dort behandelten Table gekennzeichneten Bereiche.
*/

------------------------------------------------ ab hier wird crm_cust_info auf Unstimmigkeiten geprüft und dann geladen
--testen, ob es Duplikate oder NULLs bei den Primary Keys gibt
SELECT 
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL


--Duplikate entfernen
SELECT 
*
FROM (
	SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
)t 
WHERE flag_last = 1 --nur die aktuellsten Daten über eine Person werden ausgewählt


--falsch gesetzte Leerzeichen finden
SELECT 
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)


--prüfen, ob bei einheitlichen Werten, wie dem Geschlecht (oder dem Beziehungsstatus), noch weitere Bezeichnungen außer M, F und NULL (oder M, S und NULL) auftauchen
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

------------------------------------------------

--gesamte Query, welche die Daten bereinigt und diese Daten dann in die Silver-Schicht überträgt
INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date) --Spalten die übernommen werden sollen
SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n/a'
END AS cst_marital_status, --Normalisieren des Beziehungsstatus in ein lesbares Format
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 ELSE 'n/a'
END AS cst_gndr, --Normalisieren des Geschlechts in ein lesbares Format
cst_create_date
FROM (
	SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t 
WHERE flag_last = 1

------------------------------------------------ ab hier wird crm_prd_info auf Unstimmigkeiten geprüft und dann geladen

	--auf Duplikate oder NULLs in prd_id testen
SELECT 
prd_id,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL


--feststellen, ob man die cat_id mit der id in bronze.erp_px_cat_g1v2 verbinden kann
SELECT DISTINCT id from bronze.erp_px_cat_g1v2

SELECT 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test --hier -1 nutzen, da das Datum einen Tag vor dem aus der nachfolgenden Zeile geholten prd_start_dt liegen soll
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509') --Beispiele

------------------------------------------------
	
--gesamte Query, welche die Daten bereinigt und diese Daten dann in die Silver-Schicht überträgt
INSERT INTO silver.crm_prd_info (
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
)
SELECT 
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, --Aufteilen der vorherigen ID in zwei Teile (cetegory ID und product key)
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	 WHEN 'M' THEN 'Mountain'
	 WHEN 'R' THEN 'Road'
	 WHEN 'S' THEN 'Other Sales'
	 WHEN 'T' THEN 'Touring'
	 ELSE 'n/a'
END AS prd_line, --Beschreibendere Namen für die Produktlinien einsetzen
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info

------------------------------------------------ ab hier wird crm_sales_info auf Unstimmigkeiten geprüft und dann geladen

SELECT --testen auf ungewollte Leerzeichen in der sls_ord_num
sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

	
SELECT --testen, ob alle sls_prd_key und sls_cust_id mit den beiden zuvor bereinigen Silber-Tables verbunden werden können
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT sls_cust_id FROM silver.crm_cust_info)

	
SELECT --bei Daten, die Zeiten angeben sollen auf Werte testen, die es nicht geben sollte (z.B. 0) und diese dann zu NULL abändern, damit man die restlichen Zahlen als DATE CASTen kann
NULLIF(sls_order_dt,0)
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 --Werte sollten nicht länger oder kürzer als 8 Zeichen sein
OR sls_order_dt > 20500101 --testen, ob die Jahre in der Zukunft 
OR sls_order_dt < 19000101 --oder zu weit in der Vergangenheit liegen


SELECT DISTINCT--Sales müssen das Ergebnis aus Quantity * Price sein und sie dürfen nicht negativ sein oder als Null oder NULL ausfallen
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL
OR sls_quantity IS NULL
OR sls_price IS NULL
OR sls_sales <= 0
OR sls_quantity <= 0
OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price


SELECT DISTINCT--Sales müssen das Ergebnis aus Quantity * Price sein und sie dürfen nicht negativ sein oder als Null oder NULL ausfallen
sls_sales AS old_sales,
sls_quantity,
sls_price AS old_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
		THEN sls_quantity * ABS(sls_price) --ABS damit alle negativen Zahelen beim rechnen in positive gewandelt werden
	 ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity,0) --falls irgendwann 0-en in den Daten auftauchen, sorgt das dafür dass diese zu NULL werden und man nicht durch Null teilt
	 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
ORDER BY sls_sales, sls_quantity, sls_price

------------------------------------------------
	
--gesamte Query, welche die Daten bereinigt und diese Daten dann in die Silver-Schicht überträgt
INSERT INTO silver.crm_sales_details (
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)
SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
		THEN sls_quantity * ABS(sls_price) --ABS damit alle negativen Zahelen beim rechnen in positive gewandelt werden
	 ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity,0) --falls irgendwann 0-en in den Daten auftauchen, sorgt das dafür dass diese zu NULL werden und man nicht durch Null teilt
	 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details

------------------------------------------------ ab hier wird erp_cust_az12 auf Unstimmigkeiten geprüft und dann geladen

SELECT --bei den CIDs dafür sorgen, dass diese alle gelich aufgebaut sind
CASE WHEN cid LIKE 'NAS%'
		THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12

SELECT --testen ob manche Geburtstage (über 100 Jahre zurückliegen oder noch) in der Zukunft liegen
bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()


SELECT DISTINCT --Geschlechter auf Unstimmigkeiten prüfen und wenn nötig vereinheitlichen
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' -- TRIM und UPPER falls es in Zukunft mal Leerzeichen oder unterschiedliche Schreibweisen gibt
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	 ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12

------------------------------------------------
	
--gesamte Query, welche die Daten bereinigt und diese Daten dann in die Silver-Schicht überträgt
INSERT INTO silver.erp_cust_az12 (
cid,
bdate,
gen
)
SELECT
CASE WHEN cid LIKE 'NAS%'
		THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
	 ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' -- TRIM und UPPER falls es in Zukunft mal Leerzeichen oder unterschiedliche Schreibweisen gibt
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	 ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12

------------------------------------------------ ab hier wird erp_loc_a101 auf Unstimmigkeiten geprüft und dann geladen

SELECT DISTINCT --testen in welchen Formen cntry vorliegt
cntry
FROM bronze.erp_loc_a101

------------------------------------------------
	
--gesamte Query, welche die Daten bereinigt und diese Daten dann in die Silver-Schicht überträgt
INSERT INTO silver.erp_loc_a101 (
cid,
cntry
)
SELECT
REPLACE(cid, '-', '') AS cid,
CASE WHEN UPPER(TRIM(cntry)) IN ('DE', 'GERMANY') THEN 'Germany'
	 WHEN UPPER(TRIM(cntry)) IN ('US', 'USA', 'UNITED STATES') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101
