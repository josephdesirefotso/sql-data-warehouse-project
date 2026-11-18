# Data Warehouse Naming Conventions & Governance Standards

**Standardizing schemas, tables, views, columns, and ETL procedures to ensure maintainability, traceability, and seamless cross-team collaboration.**

Clear naming conventions eliminate ambiguity between business stakeholders, analysts, and data engineers. This document defines the architectural governance standards enforced across the data warehouse so any contributor or client team can immediately understand data lineage, table grain, and object purpose without guesswork.

---

## Table of Contents
1. [General Principles](#1-general-principles)
2. [Schema Naming Conventions](#2-schema-naming-conventions)
3. [Table & View Naming Conventions](#3-table--view-naming-conventions)
   - [Bronze Layer (Raw Ingestion)](#bronze-layer-raw-ingestion)
   - [Silver Layer (Cleansed & Standardized)](#silver-layer-cleansed--standardized)
   - [Gold Layer (Business-Aligned Star Schema)](#gold-layer-business-aligned-star-schema)
   - [Glossary of Gold Category Patterns](#glossary-of-gold-category-patterns)
4. [Column Naming Conventions](#4-column-naming-conventions)
   - [Surrogate Keys](#surrogate-keys)
   - [Technical & Audit Metadata Columns](#technical--audit-metadata-columns)
5. [Stored Procedure & ETL Naming Conventions](#5-stored-procedure--etl-naming-conventions)

---

## 1. General Principles
* **Case Formatting (`snake_case`):** All database objects must use lowercase letters with underscores (`_`) separating words (e.g., `customer_info`, `sales_amount`). Avoid spaces, hyphens, or camelCase.
* **Language:** Use clear, standardized **English** across all object names and technical documentation to support global team collaboration.
* **Avoid Reserved Keywords:** Do not use SQL reserved words (e.g., `order`, `user`, `date`, `group`, `table`) as schema, table, or column names.
* **No Abbreviations Without Consensus:** Spell out business terms clearly (e.g., `customer` instead of `cust`, `product` instead of `prod`) unless an abbreviation is universally established across the business domain (e.g., `crm`, `erp`, `id`).

---

## 2. Schema Naming Conventions
Schemas logically isolate each stage of the **Medallion Architecture** to enforce access control and clear data lineage:
* `bronze` — Raw, untransformed ingestion tables mirroring source systems.
* `silver` — Cleansed, deduplicated, and standardized operational tables.
* `gold` — Business-ready dimensional models (Star Schema) and analytical views.

---

## 3. Table & View Naming Conventions

### Bronze Layer (Raw Ingestion)
All objects in the Bronze layer must retain their exact source system table names to guarantee 1:1 traceability back to the origin system.
* **Pattern:** `<sourcesystem>_<entity>`
  * `<sourcesystem>`: Short identifier of the origin system (e.g., `crm`, `erp`).
  * `<entity>`: Exact table/file name from the source system without renaming.
* **Examples:**
  * `bronze.crm_customer_info` $\rightarrow$ Raw customer master records ingested from the CRM system.
  * `bronze.erp_sales_details` $\rightarrow$ Raw sales transaction records ingested from the ERP system.

### Silver Layer (Cleansed & Standardized)
Tables in the Silver layer preserve the source-aligned naming structure from Bronze so engineers can easily trace transformations, quality checks, and root-cause fixes between raw and cleansed states.
* **Pattern:** `<sourcesystem>_<entity>`
  * `<sourcesystem>`: Name of the source system (e.g., `crm`, `erp`).
  * `<entity>`: Exact entity name matching the corresponding Bronze table.
* **Examples:**
  * `silver.crm_customer_info` $\rightarrow$ Standardized, validated, and deduplicated CRM customer records.
  * `silver.erp_sales_details` $\rightarrow$ Cleansed ERP sales records with resolved data-type and null anomalies.

### Gold Layer (Business-Aligned Star Schema)
Gold layer objects are exposed to BI tools and business stakeholders. All names must use meaningful, business-aligned terminology prefixed by the object's analytical role.
* **Pattern:** `<category>_<entity>`
  * `<category>`: Analytical role prefix (`dim_`, `fact_`, or `report_`).
  * `<entity>`: Descriptive, pluralized business domain name (e.g., `customers`, `products`, `sales`).
* **Examples:**
  * `gold.dim_customers` $\rightarrow$ Master customer dimension table combining CRM and ERP attributes.
  * `gold.dim_products` $\rightarrow$ Master product catalog dimension table.
  * `gold.fact_sales` $\rightarrow$ Core transactional fact table recording sales events and metrics.

### Glossary of Gold Category Patterns

| Pattern | Object Role | Description | Example(s) |
| :--- | :--- | :--- | :--- |
| `dim_` | **Dimension Table** | Descriptive business entities used for filtering and grouping | `dim_customers`, `dim_products` |
| `fact_` | **Fact Table** | Quantitative business events, measurements, and foreign keys | `fact_sales` |
| `report_` | **Reporting View / Mart** | Pre-aggregated datasets tailored for specific executive dashboards | `report_customers`, `report_sales_monthly` |

---

## 4. Column Naming Conventions

### Surrogate Keys
All system-generated primary keys in Gold dimension tables must end with the `_key` suffix to distinguish them from natural business IDs (e.g., `customer_id`).
* **Pattern:** `<entity>_key`
  * `<entity>`: Singular name of the dimension entity the key identifies.
  * `_key`: Mandatory suffix designating a warehouse surrogate key.
* **Examples:**
  * `customer_key` $\rightarrow$ Surrogate primary key in `gold.dim_customers`.
  * `product_key` $\rightarrow$ Surrogate primary key in `gold.dim_products`.

### Technical & Audit Metadata Columns
All system-generated operational metadata columns must be prefixed with `dwh_` so business analysts can immediately separate audit columns from business attributes.
* **Pattern:** `dwh_<column_name>`
  * `dwh_`: Reserved prefix exclusively for data warehouse audit and lineage metadata.
  * `<column_name>`: Descriptive name indicating the column's operational purpose.
* **Examples:**
  * `dwh_create_date` $\rightarrow$ Timestamp recording when the record was loaded into the warehouse.
  * `dwh_source_system` $\rightarrow$ Identifier tracking the origin file or system (when consolidating multiple sources).

---

## 5. Stored Procedure & ETL Naming Conventions
All stored procedures responsible for orchestrating layer-to-layer data loads must follow a consistent action-first pattern:
* **Pattern:** `load_<layer>`
  * `<layer>`: Target Medallion layer being populated (`bronze`, `silver`, or `gold`).
* **Examples:**
  * `bronze.load_bronze` $\rightarrow$ Executes full truncate-and-load ingestion from source files into Bronze tables.
  * `silver.load_silver` $\rightarrow$ Executes data cleansing, standardization, and transformation rules from Bronze into Silver tables.
