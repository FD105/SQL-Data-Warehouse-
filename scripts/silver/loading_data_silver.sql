/*
DDL Script, welches die Silber Tables erstellt.
------------------------------------------------
Zu beachten:
	Das Script erstellt die Table für das Silber-Schema.
	In den folgenden Schritten werden die Daten die in den Bronze Tables entahlten sind, 
	bereinigt und dann in die Silber Tables überführt.
	Die vorn an die eigentliche INSERT-Query angestellten Queries verfolgten den Zweck, erstmal zu testen, wo möglicher Weise 
	Probleme in den Daten bestehen können und die Query am Ende der individuellen Blöcke setzt diese dann für den 
	gesamten Table um.
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
