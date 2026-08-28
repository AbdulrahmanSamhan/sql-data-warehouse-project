/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script initializes the Data Warehouse environment.

    It performs the following:
    1. Checks if the 'DataWarehouse' database already exists.
    2. Drops the existing database if found.
    3. Creates a new 'DataWarehouse' database.
    4. Creates three schemas based on the Medallion Architecture:
       - Bronze: Raw data
       - Silver: Cleaned and transformed data
       - Gold: Business-ready data

WARNING:
    This script will permanently delete the existing
    'DataWarehouse' database and all its data if it exists.

    Use this script only in development or testing environments.
=============================================================
*/

USE master;
GO

-- =============================================================
-- 2. Drop Existing DataWarehouse Database
-- =============================================================
-- Check if the DataWarehouse database already exists.
-- If it exists:
--   1. Set the database to SINGLE_USER mode.
--   2. Terminate all active connections.
--   3. Roll back any active transactions.
--   4. Drop the database completely.

IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'DataWarehouse'
)
BEGIN

    -- Force all existing connections to close
    ALTER DATABASE DataWarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    -- Delete the existing database
    DROP DATABASE DataWarehouse;

END;
GO


-- =============================================================
-- 3. Create DataWarehouse Database
-- =============================================================
-- Create a new empty database that will contain
-- the Data Warehouse layers.

CREATE DATABASE DataWarehouse;
GO


-- =============================================================
-- 4. Switch to DataWarehouse Database
-- =============================================================
USE DataWarehouse;
GO

-- =============================================================
-- 5. Create Bronze Schema
-- =============================================================
-- Bronze Layer:
--     Stores raw data extracted from source systems.
--
--     Data in this layer should remain as close as possible
--     to the original source data (AS-IS).
--
-- Examples:
--     - Raw CSV or CRM data
--     - Source system extracts
--     - Initial staging tables

CREATE SCHEMA bronze;
GO

-- =============================================================
-- 6. Create Silver Schema
-- =============================================================
-- Silver Layer:
--     Contains cleaned, validated, and transformed data.
--
-- Typical operations:
--     - Handling NULL values
--     - Removing duplicates
--     - Data type conversions
--     - Standardization
--     - Data quality checks
--     - Applying business rules

CREATE SCHEMA silver;
GO


-- =============================================================
-- 7. Create Gold Schema
-- =============================================================
-- Gold Layer:
--     Contains business-ready data optimized for
--     reporting, analytics, and BI tools.
--
-- Typical objects:
--     - Fact tables
--     - Dimension tables
--     - Aggregated tables
--     - Reporting views

CREATE SCHEMA gold;
GO
