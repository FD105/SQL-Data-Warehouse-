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
