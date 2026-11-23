/*
===============================================================================
Quality Assurance Script: Gold Layer Data Validation (Sales Data Mart)
===============================================================================
Script Purpose:
    This script executes automated data quality and integrity checks across the
    Gold Layer views (Star Schema) prior to BI consumption:
      1. Entity Integrity     : Uniqueness and non-nullability of surrogate and
                                business keys in gold.dim_customers and gold.dim_products.
      2. Domain Standardization: Verification of standardized categorical values
                                and null-safety defaults ('n/a').
      3. Referential Integrity: Star Schema join validation ensuring zero orphan
                                foreign keys in gold.fact_sales.
      4. Measure & Date Logic : Validation of revenue calculations and chronological
                                order fulfillment dates.

Compatibility:
    SQL Server 2014+ (12.0.2269.0)

Usage Notes:
    - Execute this script immediately after deploying or refreshing Gold views.
    - Expected Outcome: Every query below must return ZERO (0) rows. Any returned
      records indicate an upstream Silver transformation or join anomaly.
===============================================================================
*/

-- =============================================================================
-- 1. Dimension Validation: gold.dim_customers
-- =============================================================================

-- 1.1 Check Surrogate & Business Key Uniqueness / Nullability
-- Expectation: No results (0 rows)
SELECT
    customer_key,
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key, customer_id
HAVING COUNT(*) > 1
    OR customer_key IS NULL
    OR customer_id  IS NULL;
GO

-- 1.2 Check Standardized Categorical Domains & Null-Safety
-- Expectation: No results (0 rows)
SELECT
    customer_key,
    country,
    marital_status,
    gender
FROM gold.dim_customers
WHERE country        IS NULL
   OR marital_status IS NULL
   OR gender         IS NULL
   OR gender NOT IN ('Male', 'Female', 'n/a');
GO

-- =============================================================================
-- 2. Dimension Validation: gold.dim_products
-- =============================================================================

-- 2.1 Check Surrogate & Product Number (Join Key) Uniqueness / Nullability
-- Expectation: No results (0 rows)
SELECT
    product_key,
    product_number,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key, product_number
HAVING COUNT(*) > 1
    OR product_key    IS NULL
    OR product_number IS NULL;
GO

-- 2.2 Check Standardized Product Attributes & Cost Boundaries
-- Expectation: No results (0 rows)
SELECT
    product_key,
    category,
    subcategory,
    maintenance,
    cost
FROM gold.dim_products
WHERE category    IS NULL
   OR subcategory IS NULL
   OR maintenance IS NULL
   OR cost        IS NULL
   OR cost < 0;
GO

-- =============================================================================
-- 3. Fact & Star Schema Connectivity Validation: gold.fact_sales
-- =============================================================================

-- 3.1 Check Referential Integrity (Orphan Foreign Keys Between Fact & Dimensions)
-- Expectation: No results (0 rows)
SELECT
    f.order_number,
    f.product_key,
    f.customer_key
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products AS p
    ON p.product_key = f.product_key
WHERE c.customer_key IS NULL
   OR p.product_key  IS NULL;
GO

-- 3.2 Check Revenue Calculation Consistency & Positive Measure Values
-- Expectation: No results (0 rows)
SELECT
    order_number,
    sales_amount,
    quantity,
    price
FROM gold.fact_sales
WHERE sales_amount IS NULL
   OR quantity     IS NULL
   OR price        IS NULL
   OR sales_amount <= 0
   OR quantity     <= 0
   OR price        <= 0
   OR sales_amount != (quantity * price);
GO

-- 3.3 Check Chronological Order Date Integrity
-- Expectation: No results (0 rows)
SELECT
    order_number,
    order_date,
    shipping_date,
    due_date
FROM gold.fact_sales
WHERE (shipping_date IS NOT NULL AND order_date > shipping_date)
   OR (due_date      IS NOT NULL AND order_date > due_date);
GO
