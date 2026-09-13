/*
===============================================================================
GOLD LAYER VALIDATION
===============================================================================
Purpose:
    Validate Gold Layer dimensions and fact tables after loading.

Validation Checks:
    1. Duplicate Customer Records
    2. Gender Standardization Logic
    3. Duplicate Product Records
    4. Customer Foreign Key Integrity
    5. Product Foreign Key Integrity
===============================================================================
*/


-- ============================================================================
-- CHECK #1 : Duplicate Customers in Customer Dimension Source
-- ============================================================================
-- Purpose:
--     Verify that joining CRM, ERP Customer, and ERP Location tables
--     does not create duplicate customer records.
--
-- Expected Result:
--     No records returned.
-- ============================================================================

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM (
    SELECT
        ci.cst_id,
        ci.cst_key,
        ci.cst_firstname,
        ci.cst_lastname,
        ci.cst_marital_status,
        ci.cst_gndr,
        ci.cst_create_date,
        ci.dwh_create_date,
        li.bdate,
        li.gen,
        ca.cntry
    FROM silver.crm_cust_info ci
    INNER JOIN silver.erp_cust_az12 li
        ON ci.cst_key = li.cid
    INNER JOIN silver.erp_loc_a101 ca
        ON ci.cst_key = ca.cid
) t
GROUP BY cst_id
HAVING COUNT(*) > 1;



-- ============================================================================
-- CHECK #2 : Gender Resolution Logic
-- ============================================================================
-- Business Rule:
--     CRM Gender is the primary source.
--     If CRM Gender = 'N/A'
--     then use ERP Gender.
--
-- Purpose:
--     Review records where CRM and ERP gender values differ.
-- ============================================================================

SELECT
    ci.cst_gndr AS crm_gender,
    li.gen      AS erp_gender,

    CASE
        WHEN ci.cst_gndr <> 'N/A'
            THEN ci.cst_gndr
        ELSE COALESCE(li.gen, 'N/A')
    END AS final_gender

FROM silver.crm_cust_info ci

INNER JOIN silver.erp_cust_az12 li
    ON ci.cst_key = li.cid

INNER JOIN silver.erp_loc_a101 ca
    ON ci.cst_key = ca.cid

WHERE ci.cst_gndr <> li.gen;



-- ============================================================================
-- CHECK #3 : Duplicate Products in Product Dimension Source
-- ============================================================================
-- Purpose:
--     Verify that Product-to-Category joins do not generate duplicates.
--
-- Expected Result:
--     No records returned.
-- ============================================================================

SELECT
    prd_id,
    COUNT(*) AS record_count
FROM (
    SELECT
        p.prd_id,
        p.cat_id,
        p.prd_key,
        p.prd_nm,
        p.prd_cost,
        p.prd_line,
        p.prd_start_dt,
        pc.cat,
        pc.subcat,
        pc.maintenance
    FROM silver.crm_prd_info p

    INNER JOIN silver.erp_px_cat_g1v2 pc
        ON p.cat_id = pc.id

    WHERE p.prd_end_dt IS NULL
) t
GROUP BY prd_id
HAVING COUNT(*) > 1;



-- ============================================================================
-- CHECK #4 : Customer Foreign Key Integrity
-- ============================================================================
-- Purpose:
--     Verify that every Customer Key in Fact Sales exists
--     in the Customer Dimension.
--
-- Expected Result:
--     No records returned.
-- ============================================================================

SELECT *
FROM gold.fact_sales f

LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key

WHERE c.customer_key IS NULL;



-- ============================================================================
-- CHECK #5 : Product Foreign Key Integrity
-- ============================================================================
-- Purpose:
--     Verify that every Product Key in Fact Sales exists
--     in the Product Dimension.
--
-- Expected Result:
--     No records returned.
-- ============================================================================

SELECT *
FROM gold.fact_sales f

LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key

WHERE p.product_key IS NULL;
