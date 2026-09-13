/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        --- Customer Info table --> CRM
        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Inserting Data Into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info(
            cst_id ,
            cst_key ,
            cst_firstname , 
            cst_lastname ,
            cst_marital_status ,
            cst_gndr ,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,     
            TRIM(cst_lastname) AS cst_lastname,     
            CASE                                     
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                ELSE 'N/A'
            END as cst_marital_status,  -- Normalize marital status values to readable format
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'N/A'
            END as cst_gndr,     -- Normalize gender values to readable format        
            cst_create_date
        FROM (
            SELECT 
                *,
                ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC ) last_flag
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE last_flag = 1 ;     -- Select the most recent record per customer

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as NVARCHAR) + 'seconds'
        PRINT '>> -------------';

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Inserting Data Into: silver.crm_prd_info';
        --- Product Table --> CRM
        INSERT INTO silver.crm_prd_info(
            prd_id ,
            cat_id ,
            prd_key ,
            prd_nm  ,
            prd_cost ,
            prd_line ,
            prd_start_dt ,
            prd_end_dt 
        )
        SELECT
            prd_id ,
            REPLACE(SUBSTRING(prd_key, 1 , 5), '-', '_')  AS cat_id,  -- Extract category ID
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,           -- Extract product key
            prd_nm ,
            ISNULL(prd_cost, 0) AS prd_cost ,
            CASE 
                    WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                    WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                    WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                    WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                    ELSE 'n/a'
                END AS prd_line, -- Map product line codes to descriptive values
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE)  
            AS prd_end_dt   -- Calculate end date as one day before the next start date
        FROM bronze.crm_prd_info 

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Inserting Data Into: silver.crm_sales_details';
        --- sales_details table
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,     
            sls_prd_key,   
            sls_cust_id,   
            sls_order_dt,   
            sls_ship_dt,     
            sls_due_dt,     
            sls_sales ,    
            sls_quantity,  
            sls_price  
        )  
        SELECT
            sls_ord_num,    
            sls_prd_key,     
            sls_cust_id,
            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
            END AS sls_order_dt, 

            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
            END AS sls_ship_dt,

            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
            END AS sls_due_dt,

            CASE 
            WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
                THEN sls_quantity * ABS(sls_price) 
            ELSE sls_sales   -- Recalculate sales if original value is missing or incorrect
        END AS sls_sales,

            sls_quantity,

            CASE
            WHEN sls_price IS NULL OR sls_price <= 0 
                THEN sls_sales / NULLIF(sls_quantity,0)
            ELSE sls_price
        END AS sls_price  -- Derive price if original value is invalid
        FROM bronze.crm_sales_details  

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';  

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Inserting Data Into: silver.erp_cust_az12';
        --- erp_cust table --> extra customer information (birthdate)
        INSERT INTO silver.erp_cust_az12 (
            cid ,
            bdate ,
            gen
        )
        SELECT  
            CASE 
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove 'NAS' prefix if present
            ELSE cid 
            END AS cid ,     
        
            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,     -- Set future birthdates to NULL

            CASE 
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'N/A'    
            END AS gen   -- Normalize gender values and handle unknown cases
        FROM bronze.erp_cust_az12

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------'; 

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Inserting Data Into: silver.erp_loc_a101';
        --- lOACTION cUSTOMERS TABLE
        INSERT INTO silver.erp_loc_a101(
            cid ,
            cntry
        )
        SELECT  
            REPLACE(cid , '-','') AS cid,          
                CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('USA', 'US') THEN 'United States'
                WHEN cntry = '' OR cntry IS NULL THEN 'N/A'
                ELSE TRIM(cntry)
            END AS cntry   -- Normalize and Handle missing or blank country codes
        FROM bronze.erp_loc_a101  

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';  

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
        --- cATGORT tABLE --erp
        INSERT INTO silver.erp_px_cat_g1v2(
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2 

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '=========================================='
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=========================================='  

    END TRY    

    BEGIN CATCH
        PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
        PRINT 'Error Message' + ERROR_MESSAGE() ;
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=========================================='

    END CATCH

END


/*
===============================================================================
ETL FLOW

CRM / ERP Sources
        │
        ▼
   Bronze Layer
        │
        ▼
 Data Cleansing
 Standardization
 Deduplication
 Validation
        │
        ▼
   Silver Layer

Load Strategy:
    Full Refresh

Error Handling:
    TRY...CATCH

Execution:
    EXEC silver.load_silver;
===============================================================================
*/









