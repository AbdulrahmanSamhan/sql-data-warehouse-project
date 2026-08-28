/*
===============================================================================
DDL Script: Create Bronze Layer Tables
===============================================================================
Script Purpose:
    This script creates the physical table structures for the Bronze Layer
    of the Data Warehouse.

    The Bronze Layer stores raw data extracted from the source systems
    without applying business transformations.

    The script performs the following:
        1. Checks whether each Bronze table already exists.
        2. Drops the existing table if found.
        3. Creates the table with the required columns and data types.

Tables Created:
    CRM:
        - bronze.crm_cust_info
        - bronze.crm_prd_info
        - bronze.crm_sales_details

    ERP:
        - bronze.erp_loc_a101
        - bronze.erp_cust_az12
        - bronze.erp_px_cat_g1v2

Important Notes:
    - Existing tables will be permanently dropped and recreated.
    - No Primary Keys, Foreign Keys, or constraints are defined at this stage.
    - Data quality and transformation rules will be handled in later layers.

===============================================================================
*/


-- =============================================================================
-- 1. CRM Customer Information
-- =============================================================================
-- Purpose:
--     Stores raw customer information extracted from the CRM source system.
-- Source:
--     CRM Customer Data


IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
);
GO


-- =============================================================================
-- 2. CRM Product Information
-- =============================================================================
-- Purpose:
--     Stores raw product information extracted from the CRM source system.
-- Source:
--     CRM Product Data

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);
GO


-- =============================================================================
-- 3. CRM Sales Details
-- =============================================================================
-- Purpose:
--     Stores raw sales transaction data extracted from the CRM system.
--     from CRM system.

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt INT,
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT
);
GO


-- =============================================================================
-- 4. ERP Location Information
-- =============================================================================
-- Purpose:
--     Stores raw customer location/country information extracted
--     from the ERP system.

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    cid    NVARCHAR(50),
    cntry  NVARCHAR(50)
);
GO


-- =============================================================================
-- 5. ERP Customer Information
-- =============================================================================
-- Purpose:
--     Stores raw customer demographic information extracted
--     from the ERP system.

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    cid    NVARCHAR(50),
    bdate  DATE,
    gen    NVARCHAR(50)
);
GO


-- =============================================================================
-- 6. ERP Product Category Information
-- =============================================================================
-- Purpose:
--     Stores raw product category and maintenance information
--     extracted from the ERP system.

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           NVARCHAR(50),
    cat          NVARCHAR(50),
    subcat       NVARCHAR(50),
    maintenance  NVARCHAR(50)
);
GO


/*
===============================================================================
End of Script
===============================================================================

Bronze Layer Tables Created:
    CRM:
        1. crm_cust_info
        2. crm_prd_info
        3. crm_sales_details

    ERP:
        4. erp_loc_a101
        5. erp_cust_az12
        6. erp_px_cat_g1v2

Next Step:
    Load raw source data into the Bronze tables and perform
    data quality checks before transforming the data into the Silver Layer.

===============================================================================
*/
