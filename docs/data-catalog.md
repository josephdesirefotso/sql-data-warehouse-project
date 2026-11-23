# Gold Layer Data Catalog

## Executive Overview
The **Gold Layer** serves as the business-ready presentation tier of the Data Warehouse. Modeled as a high-performance **Star Schema**, it organizes conformed master data into **Dimension Tables** and transactional business events into **Fact Tables** to power executive dashboards, self-service BI, and ad-hoc analytics.

[Sales Data Mart (Star Schema)](sales-data-mart-star-schema.png)

---

## 1. `gold.dim_customers`
* **Object Type:** Dimension View
* **Purpose:** Stores enriched customer profiles combining core CRM master records with demographic and geographic attributes.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `customer_key` | `INT` | Surrogate key uniquely identifying each customer record in the dimension table. |
| `customer_id` | `INT` | Unique numerical business identifier assigned to each customer in the source system. |
| `customer_number` | `NVARCHAR(50)` | Alphanumeric identifier representing the customer, used for cross-system tracking and referencing. |
| `first_name` | `NVARCHAR(50)` | The customer's standardized first (given) name. |
| `last_name` | `NVARCHAR(50)` | The customer's standardized last (family) name. |
| `country` | `NVARCHAR(50)` | The customer's standardized country of residence (e.g., `'Australia'`, `'United States'`, `'n/a'`). |
| `marital_status` | `NVARCHAR(50)` | The standardized marital status of the customer (e.g., `'Married'`, `'Single'`, `'n/a'`). |
| `gender` | `NVARCHAR(50)` | The standardized gender of the customer (e.g., `'Male'`, `'Female'`, `'n/a'`). |
| `birthdate` | `DATE` | The customer's date of birth, formatted as `YYYY-MM-DD` (e.g., `1971-10-06`). |
| `create_date` | `DATE` | The date when the customer record was created in the source system, formatted as `YYYY-MM-DD`. |

---

## 2. `gold.dim_products`
* **Object Type:** Dimension View
* **Purpose:** Provides a comprehensive, current-state catalog of active products and their hierarchical attributes.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `product_key` | `INT` | Surrogate key uniquely identifying each active product record in the dimension table. |
| `product_id` | `INT` | Unique numerical identifier assigned to the product for internal source tracking. |
| `product_number` | `NVARCHAR(50)` | Structured alphanumeric product code (SKU) used for categorization and inventory tracking. |
| `product_name` | `NVARCHAR(50)` | Official descriptive name of the product, including key attributes such as model, color, and size. |
| `category_id` | `NVARCHAR(50)` | Standardized identifier for the product's category, linking to its high-level classification. |
| `category` | `NVARCHAR(50)` | Broad product classification (e.g., `'Bikes'`, `'Components'`) used to group related items. |
| `subcategory` | `NVARCHAR(50)` | Granular product classification within the parent category (e.g., `'Mountain Bikes'`, `'Helmets'`). |
| `maintenance` | `NVARCHAR(50)` | Indicates whether the product requires ongoing maintenance (e.g., `'Yes'`, `'No'`). |
| `cost` | `INT` | Standard unit manufacturing or base cost of the product, measured in whole monetary units. |
| `product_line` | `NVARCHAR(50)` | The specific business product line or series to which the item belongs (e.g., `'Road'`, `'Mountain'`, `'Touring'`). |
| `start_date` | `DATE` | The effective date when the current product version became available for sale, formatted as `YYYY-MM-DD`. |

---

## 3. `gold.fact_sales`
* **Object Type:** Fact View
* **Purpose:** Stores line-item transactional sales metrics linked to customer and product dimensions for revenue and volume analysis.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `order_number` | `NVARCHAR(50)` | Unique alphanumeric identifier for each sales order (e.g., `'SO54496'`). |
| `product_key` | `INT` | Surrogate foreign key linking the order line item to `gold.dim_products`. |
| `customer_key` | `INT` | Surrogate foreign key linking the order line item to `gold.dim_customers`. |
| `order_date` | `DATE` | The date when the sales order was placed by the customer. |
| `shipping_date` | `DATE` | The date when the order was shipped to the customer. |
| `due_date` | `DATE` | The date when the order payment was due. |
| `sales_amount` | `INT` | Total monetary value of the sale for the line item (`quantity * price`), in whole currency units (e.g., `25`). |
| `quantity` | `INT` | Number of product units ordered on the line item (e.g., `1`). |
| `price` | `INT` | Selling price per unit of the product on the line item, in whole currency units (e.g., `25`). |
