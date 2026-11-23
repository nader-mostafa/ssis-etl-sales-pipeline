/* Data Management - SSIS ETL Task
   Run this script in SQL Server Management Studio before executing the SSIS package.
   Change the database name only if your instructor tells you to.
*/
IF DB_ID('DataManagement_ETL') IS NULL
    CREATE DATABASE DataManagement_ETL;
GO
USE DataManagement_ETL;
GO

IF OBJECT_ID('dbo.FactSales', 'U') IS NOT NULL DROP TABLE dbo.FactSales;
IF OBJECT_ID('dbo.RejectedSales', 'U') IS NOT NULL DROP TABLE dbo.RejectedSales;
IF OBJECT_ID('dbo.StgSales', 'U') IS NOT NULL DROP TABLE dbo.StgSales;
IF OBJECT_ID('dbo.StgCustomers', 'U') IS NOT NULL DROP TABLE dbo.StgCustomers;
IF OBJECT_ID('dbo.StgProducts', 'U') IS NOT NULL DROP TABLE dbo.StgProducts;
GO

CREATE TABLE dbo.StgCustomers (
    CustomerID INT NOT NULL PRIMARY KEY,
    CustomerName NVARCHAR(100),
    Email NVARCHAR(150),
    City NVARCHAR(60),
    JoinDate DATE,
    CustomerStatus NVARCHAR(20),
    CustomerNameClean NVARCHAR(120)
);

CREATE TABLE dbo.StgProducts (
    ProductCode NVARCHAR(20) NOT NULL PRIMARY KEY,
    ProductName NVARCHAR(100),
    Category NVARCHAR(60),
    UnitPrice DECIMAL(12,2)
);

CREATE TABLE dbo.StgSales (
    SaleID NVARCHAR(20) NOT NULL PRIMARY KEY,
    CustomerID INT,
    ProductCode NVARCHAR(20),
    Quantity INT,
    UnitPrice DECIMAL(12,2),
    SaleDate DATE,
    Channel NVARCHAR(20),
    TotalAmount DECIMAL(14,2)
);

CREATE TABLE dbo.FactSales (
    SaleID NVARCHAR(20) NOT NULL PRIMARY KEY,
    CustomerID INT,
    ProductCode NVARCHAR(20),
    Quantity INT,
    UnitPrice DECIMAL(12,2),
    SaleDate DATE,
    Channel NVARCHAR(20),
    TotalAmount DECIMAL(14,2),
    LoadDate DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.RejectedSales (
    SaleID NVARCHAR(20),
    CustomerID INT,
    ProductCode NVARCHAR(20),
    Quantity INT,
    UnitPrice DECIMAL(12,2),
    SaleDate DATE,
    Channel NVARCHAR(20),
    RejectReason NVARCHAR(100),
    RejectedAt DATETIME2 DEFAULT SYSDATETIME()
);
GO
