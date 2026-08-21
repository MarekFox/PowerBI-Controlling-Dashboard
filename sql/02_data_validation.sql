-- ===============================================================================
-- Author: Marek Lis
-- Description: Data reconciliation scripts to validate Power BI DAX measures against DWH.
-- ===============================================================================

USE WideWorldImportersDW;
GO

-- 1. Weryfikacja głównych KPI (Suma przychodów, zysku, wolumenu i liczby transakcji)
SELECT 
    COUNT(*) AS TotalInvoices,
    SUM([Quantity]) AS TotalQuantity,
    SUM([Total Excluding Tax]) AS TotalRevenue,
    SUM([Profit]) AS TotalProfit,
    ROUND((SUM([Profit]) / SUM([Total Excluding Tax])) * 100, 2) AS GrossMarginPct
FROM Fact.Sale;

-- 2. Weryfikacja zakresu dat w tabeli faktów
SELECT 
    MIN([Invoice Date Key]) AS MinInvoiceDate,
    MAX([Invoice Date Key]) AS MaxInvoiceDate
FROM Fact.Sale;

-- 3. Sprawdzenie spójności relacji (Orphaned keys in Fact.Sale)
SELECT COUNT(*) AS MissingCustomers
FROM Fact.Sale s
LEFT JOIN Dimension.Customer c ON s.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] IS NULL;