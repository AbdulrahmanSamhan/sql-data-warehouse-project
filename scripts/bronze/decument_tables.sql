-- =============================================================================
-- 1. CRM Customer Information
-- =============================================================================
-- Purpose:
--     Stores raw customer information extracted from the CRM source system.
--
-- Source:
--     CRM Customer Data
--
-- Key Information:
--     cst_id             : Customer identifier
--     cst_key            : Customer business key
--     cst_firstname      : Customer first name
--     cst_lastname       : Customer last name
--     cst_marital_status : Customer marital status
--     cst_gndr           : Customer gender
--     cst_create_date    : Customer creation date
-- =============================================================================



-- =============================================================================
-- 2. CRM Product Information
-- =============================================================================
-- Purpose:
--     Stores raw product information extracted from the CRM source system.
--
-- Key Information:
--     prd_id       : Product identifier
--     prd_key      : Product business key
--     prd_nm       : Product name
--     prd_cost     : Product cost
--     prd_line     : Product category/line
--     prd_start_dt : Product validity start date
--     prd_end_dt   : Product validity end date
-- =============================================================================


-- =============================================================================
-- 3. CRM Sales Details
-- =============================================================================
-- Purpose:
--     Stores raw sales transaction data extracted from the CRM system.
--
-- Key Information:
--     sls_ord_num : Sales order number
--     sls_prd_key : Product business key
--     sls_cust_id : Customer identifier
--     sls_order_dt: Order date
--     sls_ship_dt : Shipping date
--     sls_due_dt  : Due date
--     sls_sales   : Sales amount
--     sls_quantity: Quantity sold
--     sls_price   : Product selling price
--
-- Note:
--     Date fields are currently stored as INT in the Bronze Layer
--     because the source data may require validation and conversion
--     during the Silver Layer transformation.
-- =============================================================================


-- =============================================================================
-- 4. ERP Location Information
-- =============================================================================
-- Purpose:
--     Stores raw customer location/country information extracted
--     from the ERP system.
--
-- Key Information:
--     cid   : Customer identifier
--     cntry : Customer country
-- =============================================================================


-- =============================================================================
-- 5. ERP Customer Information
-- =============================================================================
-- Purpose:
--     Stores raw customer demographic information extracted
--     from the ERP system.
--
-- Key Information:
--     cid  : Customer identifier
--     bdate: Customer birth date
--     gen  : Customer gender
-- =============================================================================


-- =============================================================================
-- 6. ERP Product Category Information
-- =============================================================================
-- Purpose:
--     Stores raw product category and maintenance information
--     extracted from the ERP system.
--
-- Key Information:
--     id          : Product identifier
--     cat         : Product category
--     subcat      : Product subcategory
--     maintenance : Maintenance information/indicator
-- =============================================================================
