/*
===============================================================================
DDL Script: Create Gold Layer Views (Sales Data Mart - Star Schema)
===============================================================================
Script Purpose:
    This script builds the presentation-ready Gold Layer views for the Enterprise
    Data Warehouse, structured as a high-performance Star Schema:
      - Dimension Views : gold.dim_customers, gold.dim_products
      - Fact View       : gold.fact_sales

    Each view integrates, conforms, and enriches cleansed data from the Silver
    Layer, applying business rules, surrogate key generation, and null-safety
    standards to support executive dashboards and self-service BI reporting.

Compatibility:
    SQL Server 2014+ (12.0.2269.0)

Usage:
    Execute this script after Silver Layer ETL loads are complete. Query views
    directly from BI tools (Power BI, Tableau) or downstream analytics pipelines.
===============================================================================
*/

-- =============================================================================
-- Create Dimension View: gold.dim_customers
-- Grain: One unique record per customer
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS INT) AS customer_key,    -- Surrogate primary key
    ci.cst_id                                           AS customer_id,     -- CRM business key
    ci.cst_key                                          AS customer_number, -- Cross-system integration key
    ci.cst_firstname                                    AS first_name,
    ci.cst_lastname                                     AS last_name,
    COALESCE(la.cntry, 'n/a')                           AS country,         -- Enriched from ERP location master
    COALESCE(ci.cst_marital_status, 'n/a')              AS marital_status,
    CASE
        WHEN ci.cst_gndr IS NOT NULL AND ci.cst_gndr != 'n/a'
            THEN ci.cst_gndr                                                -- CRM is primary source for gender
        ELSE COALESCE(ca.gen, 'n/a')                                        -- Fallback to ERP demographics
    END                                                 AS gender,
    ca.bdate                                            AS birthdate,
    ci.cst_create_date                                  AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;
GO

-- =============================================================================
-- Create Dimension View: gold.dim_products
-- Grain: One unique record per active product version (prd_end_dt IS NULL)
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS INT) AS product_key,    -- Surrogate primary key
    pn.prd_id                                                             AS product_id,     -- CRM business key
    pn.prd_key                                                            AS product_number, -- Product SKU / sales join key
    pn.prd_nm                                                             AS product_name,
    pn.cat_id                                                             AS category_id,
    COALESCE(pc.cat, 'n/a')                                               AS category,       -- Enriched from ERP category hierarchy
    COALESCE(pc.subcat, 'n/a')                                            AS subcategory,
    COALESCE(pc.maintenance, 'n/a')                                       AS maintenance,
    COALESCE(pn.prd_cost, 0)                                              AS cost,
    COALESCE(pn.prd_line, 'n/a')                                          AS product_line,
    pn.prd_start_dt                                                       AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Retain active product catalog only (exclude historical versions)
GO

-- =============================================================================
-- Create Fact View: gold.fact_sales
-- Grain: One row per sales order line item
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,  -- Degenerate order dimension
    pr.product_key  AS product_key,   -- Foreign key -> gold.dim_products
    cu.customer_key AS customer_key,  -- Foreign key -> gold.dim_customers
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,  -- Validated line-item revenue (quantity * price)
    sd.sls_quantity AS quantity,      -- Units sold
    sd.sls_price    AS price          -- Unit selling price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
GO
