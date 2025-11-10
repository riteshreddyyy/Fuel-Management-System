USE FuelManagementSystem;
GO

-----------------------------------------------------------------------
-- A. SCALAR FUNCTION: GetFuelPrice
-- Used by the Stored Procedure to calculate the total amount.
-----------------------------------------------------------------------
IF OBJECT_ID('dbo.GetFuelPrice') IS NOT NULL
    DROP FUNCTION dbo.GetFuelPrice;
GO

CREATE FUNCTION dbo.GetFuelPrice (@FuelTypeID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @Price DECIMAL(10, 2);

    SELECT @Price = Current_Price_Per_Liter
    FROM FUEL_TYPES
    WHERE Fuel_Type_ID = @FuelTypeID;

    RETURN ISNULL(@Price, 0);
END;
GO

-----------------------------------------------------------------------
-- B. STORED PROCEDURE: ProcessSale
-- Handles the insertion of a new transaction and calculates the total amount.
-----------------------------------------------------------------------
IF OBJECT_ID('dbo.ProcessSale') IS NOT NULL
    DROP PROCEDURE dbo.ProcessSale;
GO

CREATE PROCEDURE dbo.ProcessSale (
    @PumpID INT,
    @EmployeeID INT,
    @LitersSold DECIMAL(8, 2)
)
AS
BEGIN
    SET NOCOUNT ON; -- Prevents 'x rows affected' messages

    IF @LitersSold <= 0
    BEGIN
        RAISERROR('Liters sold must be a positive value.', 16, 1);
        RETURN;
    END

    DECLARE @FuelTypeID INT;
    DECLARE @CurrentPrice DECIMAL(10, 2);
    DECLARE @TotalAmount DECIMAL(8, 2);

    -- 1. Get Fuel Type and Price using the Function
    SELECT @FuelTypeID = Fuel_Type_ID FROM PUMPS WHERE Pump_ID = @PumpID;
    SET @CurrentPrice = dbo.GetFuelPrice(@FuelTypeID);

    -- 2. Check if pump/fuel data is valid
    IF @FuelTypeID IS NULL OR @CurrentPrice = 0
    BEGIN
        RAISERROR('Invalid Pump ID or Fuel Price data.', 16, 1);
        RETURN;
    END

    -- 3. Calculate Total Amount
    SET @TotalAmount = @LitersSold * @CurrentPrice;

    -- 4. Insert new transaction record
    INSERT INTO TRANSACTIONS (Pump_ID, Employee_ID, [datetime], Liters_Sold, Total_Amount)
    VALUES (@PumpID, @EmployeeID, GETDATE(), @LitersSold, @TotalAmount);

    -- Trigger below will automatically update tank levels.
END;
GO

-----------------------------------------------------------------------
-- C. TRIGGER: TankLevelUpdate_TR
-- Fires AFTER INSERT on TRANSACTIONS to deduct liters sold from the tank.
-----------------------------------------------------------------------
IF OBJECT_ID('dbo.TankLevelUpdate_TR') IS NOT NULL
    DROP TRIGGER dbo.TankLevelUpdate_TR;
GO

CREATE TRIGGER TankLevelUpdate_TR
ON TRANSACTIONS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the tank level based on the transaction that just occurred
    UPDATE T
    SET T.Current_Level_Liters = T.Current_Level_Liters - I.Liters_Sold
    FROM TANKS T
    INNER JOIN PUMPS P ON T.Fuel_Type_ID = P.Fuel_Type_ID
    INNER JOIN inserted I ON I.Pump_ID = P.Pump_ID;

    -- Optional: Add alert logic here if below threshold
END;
GO

-----------------------------------------------------------------------
-- D. COMPLEX QUERIES (For Application Reporting and Insights)
-----------------------------------------------------------------------

-- 1. INVOKING PROCEDURE EXAMPLE (TESTING)
PRINT '--- Testing Stored Procedure and Trigger ---';
EXEC dbo.ProcessSale @PumpID = 1, @EmployeeID = 1, @LitersSold = 30.50;

SELECT TOP 1 * FROM TRANSACTIONS ORDER BY Transaction_ID DESC;
SELECT * FROM TANKS WHERE Tank_ID = 1; -- Check if level decreased
GO


-- 2. JOIN QUERY: Sales Detail with Employee and Fuel Name
SELECT
    T.Transaction_ID AS ID,
    E.Name AS Employee_Name,
    P.Pump_Number,
    F.Name AS Fuel_Type,
    T.Liters_Sold,
    T.Total_Amount,
    T.[datetime]
FROM TRANSACTIONS T
JOIN EMPLOYEES E ON T.Employee_ID = E.Employee_ID
JOIN PUMPS P ON T.Pump_ID = P.Pump_ID
JOIN FUEL_TYPES F ON P.Fuel_Type_ID = F.Fuel_Type_ID
ORDER BY T.[datetime] DESC;
GO


-- 3. AGGREGATE QUERY: Monthly Revenue by Fuel Type
SELECT
    F.Name AS Fuel_Type,
    SUM(T.Total_Amount) AS Total_Revenue,
    COUNT(T.Transaction_ID) AS Number_of_Sales
FROM TRANSACTIONS T
JOIN PUMPS P ON T.Pump_ID = P.Pump_ID
JOIN FUEL_TYPES F ON P.Fuel_Type_ID = F.Fuel_Type_ID
WHERE T.[datetime] >= DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)
GROUP BY F.Name
ORDER BY Total_Revenue DESC;
GO


-- 4. NESTED QUERY: High-Performing Employees (FIXED)
-- Includes employees whose total sales are equal to or above the average employee total.
SELECT
    E.Employee_ID,
    E.Name,
    E.Role
FROM EMPLOYEES E
WHERE E.Employee_ID IN (
    SELECT T.Employee_ID
    FROM TRANSACTIONS T
    GROUP BY T.Employee_ID
    HAVING SUM(T.Total_Amount) >= (
        SELECT AVG(SUM(T2.Total_Amount))
        FROM TRANSACTIONS T2
        GROUP BY T2.Employee_ID
    )
)
ORDER BY E.Employee_ID;
GO
