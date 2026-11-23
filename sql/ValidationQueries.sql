/* Data Management - SSIS ETL Task
   Post-load verification queries. Run in SSMS after executing the package.
*/
USE DataManagement_ETL;
GO

-- Staging table contents
SELECT * FROM dbo.StgCustomers;
SELECT * FROM dbo.StgProducts;

-- Valid vs rejected counts
SELECT COUNT(*) AS ValidSalesCount
FROM dbo.FactSales;

SELECT COUNT(*) AS RejectedSalesCount
FROM dbo.RejectedSales;

-- Final summary: valid rows, rejected rows, total accepted amount
SELECT
    (SELECT COUNT(*) FROM dbo.FactSales) AS ValidSales,
    (SELECT COUNT(*) FROM dbo.RejectedSales) AS RejectedSales,
    (SELECT SUM(TotalAmount) FROM dbo.FactSales) AS TotalSalesAmount;

-- Rejection reasons breakdown
SELECT RejectReason, COUNT(*) AS RejectedCount
FROM dbo.RejectedSales
GROUP BY RejectReason;

-- Rejected rows detail
SELECT * FROM dbo.RejectedSales;
