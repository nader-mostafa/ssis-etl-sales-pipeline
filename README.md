# SSIS ETL Sales Pipeline

<p align="center">
  <img src="https://img.shields.io/badge/SSIS-SQL%20Server%20Integration%20Services-red?style=for-the-badge&logo=microsoftsqlserver&logoColor=white"/>
  <img src="https://img.shields.io/badge/SQL%20Server-TSQL-blue?style=for-the-badge&logo=microsoftsqlserver&logoColor=white"/>
  <img src="https://img.shields.io/badge/ETL-Extract%20Transform%20Load-orange?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Data%20Validation-Lookup%20%2B%20Conditional%20Split-green?style=for-the-badge"/>
</p>

---

## Overview

An end-to-end ETL solution built with **SQL Server Integration Services (SSIS)** that extracts customer and product data from an Excel workbook and sales transactions from two separate systems (a physical store flat file and an online store CSV), transforms and validates the records, and loads the results into a SQL Server database.

The package validates every sale against customer and product dimensions, separates accepted records from rejected ones with explicit rejection reasons, and tracks row counts through SSIS variables for run verification.

**Pipeline summary:**

```text
StoreSales.txt (pipe) --+                         +-- OnlineSales.csv (comma)
                        v                         v
                Flat File Source          Flat File Source
                        |                         |
                Data Conversion           Data Conversion
                        |                         |
        Derived Column (TotalAmount)      Derived Column (TotalAmount)
                        |                         |
                        +------> Union All <------+
                                     |
                         RC_TotalSales (Row Count)
                                     |
                               LKP_Customers
                                 No Match -> DC_Reject_Customer
                                     | Match
                               LKP_Products
                                 No Match -> DC_Reject_Product
                                     | Match
            Conditional Split: Quantity > 0 AND UnitPrice >= 0
                                 Default -> DC_Reject_InvalidData
                                     | ValidSales
                               RC_ValidSales
                                     |
                              OLEDB_FactSales

Reject streams (customer, product, invalid data)
  -> UA_RejectedSales -> RC_RejectedSales -> OLEDB_RejectedSales
```

## Data Sources

| Source | Format | Contents |
| --- | --- | --- |
| `SourceData.xlsx` | Excel workbook | `Customers` sheet (8 rows), `Products` sheet (6 rows) |
| `StoreSales.txt` | Pipe-delimited flat file | Physical store transactions (7 rows) |
| `OnlineSales.csv` | Comma-delimited CSV | Online store transactions (7 rows) |

The source data intentionally contains unmatched customer and product IDs to exercise the Lookup and Conditional Split logic. The data files were provided with the course assignment and are not redistributed in this repository; place them in a local `data/` folder to run the package.

## Package Design

### Control Flow

Five tasks run in sequence: `SQL_Clear_Tables` truncates all destination and staging tables so each run starts from a clean state, then `DFT_Load_Customers` and `DFT_Load_Products` populate the staging tables (required before sales, because the sales Lookups reference them), then `DFT_Process_Sales` runs the main sales pipeline, and finally `SQL_Final_Summary` executes summary queries (valid row count, rejected row count, total sales amount).

![Control Flow](screenshots/01-control-flow.png)

### Data Flow 1 - Load Customers

Excel Source -> Data Conversion (CustomerID to integer, JoinDate to date) -> Derived Column (`CustomerNameClean` = trimmed, uppercase name) -> OLE DB Destination `dbo.StgCustomers`.

![Data Flow Customers](screenshots/02-data-flow-customers.png)

### Data Flow 2 - Load Products

Excel Source -> Data Conversion (ProductCode, Category, UnitPrice to compatible types) -> OLE DB Destination `dbo.StgProducts`.

![Data Flow Products](screenshots/03-data-flow-products.png)

### Data Flow 3 - Process Sales

Two Flat File Sources read the store and online sales. Each stream gets a Data Conversion and a Derived Column (`TotalAmount = Quantity * UnitPrice`), then Union All merges them into one stream of 14 rows. `RC_TotalSales` records the total. `LKP_Customers` and `LKP_Products` validate each row against the staging tables; no-match rows get a rejection reason via Derived Columns. A Conditional Split keeps rows with `Quantity > 0 AND UnitPrice >= 0` as valid and sends the rest to the rejection flow. Valid rows load into `dbo.FactSales`, rejected rows into `dbo.RejectedSales` with their `RejectReason`.

![Data Flow Sales](screenshots/04-data-flow-sales.png)

## Results

After execution (verified in SQL Server):

| Table | Rows |
| --- | --- |
| `dbo.StgCustomers` | 8 |
| `dbo.StgProducts` | 6 |
| `dbo.FactSales` | 11 valid sales |
| `dbo.RejectedSales` | 3 rejected sales |

**Final summary query** (`SQL_Final_Summary`): 11 valid sales, 3 rejected sales, total valid sales amount **96,350.00**.

**Rejection breakdown:** 1 Unknown Customer, 2 Unknown Product.

![Summary Query](screenshots/09-summary-query.png)

### Row Count Verification

Row Count transformations capture: `TotalSalesRows` (14 after Union All), `ValidSalesRows` (11), `RejectedSalesRows` (3). The counts are verified by the SQL results above and by the package execution output (`OLEDB_FactSales` wrote 11 rows, `OLEDB_RejectedSales` wrote 3 rows).

## Key Concepts Demonstrated

- **Extract**: Excel Source and Flat File Source connection managers reading heterogeneous sources.
- **Transform**: Data Conversion vs Derived Column (type conversion vs expression-based new columns), Union All for combining unsorted streams, Lookup with Match / No Match outputs for referential validation, Conditional Split for business-rule validation.
- **Load**: OLE DB Destinations for staging, fact and rejection tables.
- **Orchestration**: Execute SQL Tasks before and after the data flows (cleanup + summary), precedence constraints enforcing load order.
- **Observability**: Row Count transformations writing into package variables, plus a final SQL summary for validation.

## How to Run

1. Run `sql/CreateDatabase.sql` in SQL Server Management Studio to create the `DataManagement_ETL` database and tables.
2. Place the course-provided source files (`SourceData.xlsx`, `StoreSales.txt`, `OnlineSales.csv`) in a local `data/` folder.
3. Open the solution in `ssis/` in Visual Studio with the SSIS extension installed.
4. Update the Excel connection manager path to point to your local copy of `SourceData.xlsx`, and the flat file connection managers to `StoreSales.txt` and `OnlineSales.csv`.
5. Update the OLE DB connection manager to point at your SQL Server instance.
6. Execute the package, then run the queries in `sql/ValidationQueries.sql` to inspect `FactSales`, `RejectedSales` and the rejection summary.

> **Warning:** every execution starts by running `SQL_Clear_Tables`, which truncates all destination and staging tables (`FactSales`, `RejectedSales`, `StgSales`, `StgCustomers`, `StgProducts`). Rerunning the package wipes the previously loaded data before reloading from the source files. Do not run it against a database whose contents you need to keep.

## Project Structure

```text
├── README.md
├── sql/
│   ├── CreateDatabase.sql       # Database + destination table setup
│   └── ValidationQueries.sql    # Post-load verification queries
├── ssis/                        # SSIS project (Visual Studio solution)
│   └── Task 1_DM/
│       ├── DataManagement_ETL.dtsx
│       ├── Task 1_DM.dtproj
│       ├── Task 1_DM.slnx
│       └── Project.params
└── screenshots/                 # Package design + results evidence
```
