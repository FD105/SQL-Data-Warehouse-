/*


*/


--EXECUTE bronze.load_bronze --mittels dieses Befehls, lässt sich die darunter definierte Prozedur aufrufen

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @layer_start_time DATETIME, @layer_end_time DATETIME;
	BEGIN TRY --falls Fehler bei der Ausführung auftreten, wird das ausgeführt, was am Ende mit CATCH folgt
		
		SET @layer_start_time =GETDATE();
		PRINT ':::::::::::::::::::::::::::::::::::::::::::';
		PRINT 'Loading Bronze Layer';
		PRINT ':::::::::::::::::::::::::::::::::::::::::::';

		PRINT '-------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '-------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info; --der Table selbst bleibt erhalten, jedoch werden alle darin enthaltenen Datensätze gelöscht

		PRINT '>> Inserting Data into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info 
		FROM 'C:\Users\Anwender\Desktop\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2, --erste Zeile beinhaltet nur die Informationen des RowHeaders, daher fangen zu extrahierende Daten erst in der zweiten Zeile an 
			FIELDTERMINATOR = ',', --wodurch werden Einträge in den CSV-Dateien voneinander getrennt
			TABLOCK --kein Zugriff auf den table während des inserts
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Time: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		PRINT '-------------------------------------------';

		--SELECT COUNT(*) FROM bronze.crm_cust_info

		--SELECT * FROM bronze.crm_cust_info

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info; 

		PRINT '>> Inserting Data into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info 
		FROM 'C:\Users\Anwender\Desktop\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Time: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		PRINT '-------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> Inserting Data into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details 
		FROM 'C:\Users\Anwender\Desktop\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',', 
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Time: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		PRINT '-------------------------------------------';

		PRINT '-------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '-------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12; 

		PRINT '>> Inserting Data into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12 
		FROM 'C:\Users\Anwender\Desktop\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,  
			FIELDTERMINATOR = ',', 
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Time: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		PRINT '-------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101; 

		PRINT '>> Inserting Data into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101 
		FROM 'C:\Users\Anwender\Desktop\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Time: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		PRINT '-------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2 
		FROM 'C:\Users\Anwender\Desktop\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Time: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		PRINT '-------------------------------------------';
		SET @layer_end_time = GETDATE();
		PRINT ':::::::::::::::::::::::::::::::::::::::::::';
		PRINT 'Loading Bronze Layer is Complete';
		PRINT ' >> Total Load Time: ' + CAST(DATEDIFF(millisecond, @layer_start_time, @layer_end_time) AS NVARCHAR) + ' milliseconds';
		PRINT ':::::::::::::::::::::::::::::::::::::::::::';

	END TRY
	BEGIN CATCH
		PRINT ':::::::::::::::::::::::::::::::::::::::::::';
		PRINT 'ERROR OCURRED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message ' + ERROR_MESSAGE();
		PRINT 'Error Message ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message ' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT ':::::::::::::::::::::::::::::::::::::::::::';
	END CATCH
END
