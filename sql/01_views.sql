-- ===============================================================================
-- Author: Marek Lis
-- Description: Reporting views for Power BI model to ensure query folding and performance.
-- ===============================================================================

USE WideWorldImportersDW;
GO

-- 1. Widok agregujący sprzedaż pod kątem wydajnościowego modelu Power BI
IF OBJECT_ID('Fact.vw_Sales_Reporting', 'V') IS NOT NULL 
    DROP VIEW Fact.vw_Sales_Reporting;
GO

CREATE VIEW Fact.vw_Sales_Reporting AS
SELECT 
    s.[Sale Key],
    s.[City Key],
    s.[Customer Key],
    s.[Bill To Customer Key],
    s.[Stock Item Key],
    s.[Invoice Date Key],
    s.[Salesperson Key],
    s.[Quantity],
    s.[Unit Price],
    s.[Total Excluding Tax] AS Revenue,
    s.[Tax Amount],
    s.[Profit],
    s.[Total Including Tax] AS GrossRevenue
FROM Fact.Sale s;
GO