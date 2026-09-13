/*
===============================================================================
DATA QUALITY ASSESSMENT - BRONZE LAYER
===============================================================================

Purpose:
    Validate source data quality before transforming data
    from Bronze Layer to Silver Layer.

Checks Included:
    1. Primary Key Validation
    2. Duplicate Detection
    3. Null Value Validation
    4. Data Standardization Checks
    5. Referential Integrity Validation
    6. Business Rule Validation
    7. Date Validation
    8. Data Cleansing Requirements

===============================================================================
*/

-- ============================================================================
-- CUSTOMER DATA VALIDATION
-- Table: bronze.crm_cust_info
-- ============================================================================

/*
Check #1
---------
Validate Customer Primary Key.

Expected Result:
    No records returned.

Purpose:
    Detect duplicate customers or missing customer IDs.
*/

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;



/*
Check #2
---------
Identify latest customer record.

Purpose:
    Customer IDs may appear multiple times.
    Keep only the most recent version based on creation date.
*/

SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS last_flag
    FROM bronze.crm_cust_info
) t
WHERE last_flag = 1;



/*
Check #3
---------
Validate unwanted spaces.

Expected Result:
    No records returned.
*/

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname);

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname);

SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr <> TRIM(cst_gndr);



/*
Check #4
---------
Review Gender Values.

Purpose:
    Identify inconsistent values before standardization.
*/

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;



/*
Check #5
---------
Review Marital Status Values.

Purpose:
    Identify inconsistent values before standardization.
*/

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;



-- ============================================================================
-- PRODUCT DATA VALIDATION
-- Table: bronze.crm_prd_info
-- ============================================================================

/*
Check #6
---------
Validate Product Primary Key.

Expected Result:
    No records returned.
*/

SELECT
    prd_id,
    COUNT(*) AS record_count
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;



/*
Check #7
---------
Validate Product Category Mapping.

Purpose:
    Ensure every product category exists in ERP category table.
*/

SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key,1,5),'-','_')
NOT IN (
    SELECT DISTINCT id
    FROM bronze.erp_px_cat_g1v2
);



/*
Check #8
---------
Validate Product References in Sales Table.

Purpose:
    Ensure every product exists in sales transactions.
*/

SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
    SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key,7,LEN(prd_key))
NOT IN (
    SELECT sls_prd_key
    FROM bronze.crm_sales_details
);



/*
Check #9
---------
Validate Product Cost.

Expected Result:
    No records returned.
*/

SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0
    OR prd_cost IS NULL;



/*
Check #10
----------
Review Product Line Values.
*/

SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;



/*
Check #11
----------
Validate Product Date Range.

Expected Result:
    Product Start Date <= Product End Date
*/

SELECT *
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;



/*
Check #12
----------
Validate Product Name Formatting.
*/

SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);



-- ============================================================================
-- SALES DATA VALIDATION
-- Table: bronze.crm_sales_details
-- ============================================================================

/*
Check #13
----------
Validate Order Date Format.

Expected Format:
    YYYYMMDD

Expected Result:
    No invalid dates returned.
*/

SELECT
    NULLIF(sls_order_dt,0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE
    sls_order_dt <= 0
    OR LEN(sls_order_dt) <> 8
    OR sls_order_dt > 20500101
    OR sls_order_dt < 19000101;



/*
Check #14
----------
Validate Business Date Logic.

Expected Result:
    Order Date <= Ship Date <= Due Date
*/

SELECT *
FROM bronze.crm_sales_details
WHERE
    sls_order_dt > sls_ship_dt
    OR sls_order_dt > sls_due_dt;



/*
Check #15
----------
Validate Sales Calculation.

Business Rule:
    Sales = Quantity × Price

Purpose:
    Identify missing, invalid, or inconsistent sales values.
*/

SELECT DISTINCT
    sls_sales AS old_sls_sales,
    sls_quantity,
    sls_price AS old_sls_price,

    CASE
        WHEN sls_sales IS NULL
             OR sls_sales <= 0
             OR sls_sales <> sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS corrected_sales,

    CASE
        WHEN sls_price IS NULL
             OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity,0)
        ELSE sls_price
    END AS corrected_price

FROM bronze.crm_sales_details

WHERE
       sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_quantity <= 0
    OR sls_price <= 0
    OR sls_sales <> sls_quantity * sls_price;



-- ============================================================================
-- ERP CUSTOMER VALIDATION
-- Table: bronze.erp_cust_az12
-- ============================================================================

/*
Check #16
----------
Validate Customer Mapping between ERP and CRM.
*/

SELECT
    CASE
        WHEN cid LIKE 'NAS%'
        THEN SUBSTRING(cid,4,LEN(cid))
        ELSE cid
    END AS cid,
    bdate,
    gen
FROM bronze.erp_cust_az12
WHERE
    CASE
        WHEN cid LIKE 'NAS%'
        THEN SUBSTRING(cid,4,LEN(cid))
        ELSE cid
    END
NOT IN (
    SELECT DISTINCT cst_key
    FROM silver.crm_cust_info
);



/*
Check #17
----------
Validate Birth Date Range.

Expected Result:
    Birth date between 1924 and Today.
*/

SELECT bdate
FROM bronze.erp_cust_az12
WHERE
    bdate < '1924-01-01'
    OR bdate > GETDATE();



/*
Check #18
----------
Standardize Gender Values.
*/

SELECT DISTINCT
    gen,
    CASE
        WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
        ELSE 'N/A'
    END AS standardized_gender
FROM bronze.erp_cust_az12;



-- ============================================================================
-- ERP LOCATION VALIDATION
-- Table: bronze.erp_loc_a101
-- ============================================================================

/*
Check #19
----------
Validate Customer Location Mapping.
*/

SELECT
    REPLACE(cid,'-','') AS cid,
    cntry
FROM bronze.erp_loc_a101
WHERE REPLACE(cid,'-','')
NOT IN (
    SELECT cst_key
    FROM silver.crm_cust_info
);



/*
Check #20
----------
Standardize Country Names.
*/

SELECT DISTINCT
    cntry,
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('USA','US') THEN 'United States'
        WHEN cntry IS NULL OR cntry = '' THEN 'N/A'
        ELSE TRIM(cntry)
    END AS standardized_country
FROM bronze.erp_loc_a101;
