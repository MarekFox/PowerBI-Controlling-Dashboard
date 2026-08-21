-- ===============================================================================
-- Author: Marek Lis
-- Description: Advanced T-SQL analytical queries (Pareto 80/20 & YoY Analysis)
-- ===============================================================================

USE WideWorldImportersDW;
GO

-- 1. Analiza Pareto 80/20 klientów generujących większość przychodu (Funkcje okna CTE)
WITH CustomerRevenue AS (
    SELECT 
        c.[Customer],
        c.[Category],
        SUM(s.[Total Excluding Tax]) AS TotalRevenue
    FROM Fact.Sale s
    JOIN Dimension.Customer c ON s.[Customer Key] = c.[Customer Key]
    GROUP BY c.[Customer], c.[Category]
),
CumulativeRevenue AS (
    SELECT 
        [Customer],
        [Category],
        TotalRevenue,
        SUM(TotalRevenue) OVER (ORDER BY TotalRevenue DESC) AS RunningTotal,
        SUM(TotalRevenue) OVER () AS GrandTotal
    FROM CustomerRevenue
)
SELECT 
    [Customer],
    [Category],
    TotalRevenue,
    ROUND((RunningTotal / GrandTotal) * 100, 2) AS CumulativeSharePct,
    CASE 
        WHEN (RunningTotal / GrandTotal) <= 0.80 THEN 'Group A (80% Revenue)'
        WHEN (RunningTotal / GrandTotal) <= 0.95 THEN 'Group B (15% Revenue)'
        ELSE 'Group C (5% Revenue)'
    END AS ParetoGroup
FROM CumulativeRevenue
ORDER BY TotalRevenue DESC;

-- 2. Porównanie przychodów rok do roku (YoY Growth) za pomocą LAG()
WITH MonthlySales AS (
    SELECT 
        d.[Calendar Year] AS [Year],
        d.[Calendar Month Number] AS [Month],
        d.[Calendar Month Label] AS [MonthName],
        SUM(s.[Total Excluding Tax]) AS MonthlyRevenue
    FROM Fact.Sale s
    JOIN Dimension.Date d ON s.[Invoice Date Key] = d.[Date]
    GROUP BY d.[Calendar Year], d.[Calendar Month Number], d.[Calendar Month Label]
)
SELECT 
    [Year],
    [MonthName],
    MonthlyRevenue,
    LAG(MonthlyRevenue, 12) OVER (ORDER BY [Year], [Month]) AS PriorYearRevenue,
    ROUND(((MonthlyRevenue - LAG(MonthlyRevenue, 12) OVER (ORDER BY [Year], [Month])) 
            / NULLIF(LAG(MonthlyRevenue, 12) OVER (ORDER BY [Year], [Month]), 0)) * 100, 2) AS YoY_Growth_Pct
FROM MonthlySales
ORDER BY [Year], [Month];