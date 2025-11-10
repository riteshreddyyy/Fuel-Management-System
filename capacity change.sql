-- Set the database context
USE FuelManagementSystem;
GO

-----------------------------------------------------------------------
-- NEW STORED PROCEDURE: RestockTank
-- Purpose: Adds fuel to a tank, checking against maximum capacity.
-----------------------------------------------------------------------

IF OBJECT_ID('dbo.RestockTank') IS NOT NULL
    DROP PROCEDURE dbo.RestockTank;
GO

CREATE PROCEDURE dbo.RestockTank (
    @TankID INT,
    @LitersAdded INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentLevel INT;
    DECLARE @Capacity INT;
    DECLARE @NewLevel INT;

    -- 1. Get current status and capacity for the specified tank
    SELECT @CurrentLevel = Current_Level_Liters, @Capacity = Capacity_Liters
    FROM TANKS
    WHERE Tank_ID = @TankID;

    -- Basic check if the tank exists
    IF @CurrentLevel IS NULL
    BEGIN
        -- Raise a high-severity error
        RAISERROR('Tank ID %d not found in the system.', 16, 1, @TankID);
        RETURN;
    END

    SET @NewLevel = @CurrentLevel + @LitersAdded;

    -- 2. ENFORCE CAPACITY CONSTRAINT
    IF @NewLevel > @Capacity
    BEGIN
        -- Raise a detailed error message that the Python app can catch and display
        DECLARE @ErrorMessage NVARCHAR(255) = CONCAT(
            'Refueling failed: Adding ', @LitersAdded, 
            'L would exceed the tank capacity of ', @Capacity, 
            'L. New level would be ', @NewLevel, 'L.'
        );
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END

    -- 3. Update the tank level
    UPDATE TANKS
    SET Current_Level_Liters = @NewLevel
    WHERE Tank_ID = @TankID;

    PRINT CONCAT('Restock successful for Tank ', @TankID, '. Level increased by ', @LitersAdded, 'L.');
END;
GO
