-- ============================================================
-- DATABASE: FuelManagementSystem
-- PURPOSE: Creates all core tables for the Fuel Management project
-- ============================================================

-- Create database (run this only once)
CREATE DATABASE FuelManagementSystem;
GO

-- Switch to the database
USE FuelManagementSystem;
GO

-- ============================================================
-- 1️⃣ TABLE: FUEL_TYPES
-- Stores fuel categories and their current prices
-- ============================================================
CREATE TABLE FUEL_TYPES (
    Fuel_Type_ID INT PRIMARY KEY IDENTITY(1,1),   -- PK: Unique fuel type ID
    Name VARCHAR(50) NOT NULL UNIQUE,             -- e.g., Petrol 95, Diesel
    Current_Price_Per_Liter DECIMAL(10, 2) NOT NULL, -- Price in INR
    Reorder_Point INT                             -- Optional: for restock logic
);
GO

-- ============================================================
-- 2️⃣ TABLE: EMPLOYEES
-- Stores staff information for the fuel station
-- ============================================================
CREATE TABLE EMPLOYEES (
    Employee_ID INT PRIMARY KEY IDENTITY(1,1),    -- PK: Unique employee ID
    Name VARCHAR(100) NOT NULL,                   -- Employee name
    Role VARCHAR(50) NOT NULL,                    -- e.g., Manager, Attendant
    Shift_Time VARCHAR(50)                        -- e.g., Day, Night
);
GO

-- ============================================================
-- 3️⃣ TABLE: PUMPS
-- Each pump dispenses one type of fuel
-- ============================================================
CREATE TABLE PUMPS (
    Pump_ID INT PRIMARY KEY IDENTITY(1,1),        -- PK: Unique pump ID
    Fuel_Type_ID INT NOT NULL,                    -- FK: References fuel type
    Pump_Number VARCHAR(20) NOT NULL UNIQUE,      -- e.g., P1A, P2B
    Status VARCHAR(30) NOT NULL DEFAULT 'Active', -- Active or Maintenance
    FOREIGN KEY (Fuel_Type_ID) REFERENCES FUEL_TYPES(Fuel_Type_ID)
);
GO

-- ============================================================
-- 4️⃣ TABLE: TANKS
-- Each tank stores a single type of fuel
-- ============================================================
CREATE TABLE TANKS (
    Tank_ID INT PRIMARY KEY IDENTITY(1,1),        -- PK: Unique tank ID
    Fuel_Type_ID INT NOT NULL,                    -- FK: Linked fuel type
    Capacity_Liters DECIMAL(10, 2) NOT NULL,      -- Max capacity of tank
    Current_Level_Liters DECIMAL(10, 2) NOT NULL, -- Current stock in liters
    FOREIGN KEY (Fuel_Type_ID) REFERENCES FUEL_TYPES(Fuel_Type_ID)
);
GO

-- ============================================================
-- 5️⃣ TABLE: TRANSACTIONS
-- Records each sale made through a pump
-- ============================================================
CREATE TABLE TRANSACTIONS (
    Transaction_ID INT PRIMARY KEY IDENTITY(1,1), -- PK: Unique transaction ID
    Pump_ID INT NOT NULL,                         -- FK: Pump used
    Employee_ID INT NOT NULL,                     -- FK: Employee handling sale
    [datetime] DATETIME NOT NULL DEFAULT GETDATE(), -- Time of transaction
    Liters_Sold DECIMAL(8, 2) NOT NULL,           -- Amount of fuel sold
    Total_Amount DECIMAL(10, 2) NOT NULL,         -- Calculated total sale amount
    FOREIGN KEY (Pump_ID) REFERENCES PUMPS(Pump_ID),
    FOREIGN KEY (Employee_ID) REFERENCES EMPLOYEES(Employee_ID)
);
GO

PRINT '✅ All tables created successfully in FuelManagementSystem.';
