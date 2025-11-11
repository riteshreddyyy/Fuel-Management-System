USE FuelManagementSystem;
GO

------------------------------------------------------
-- 1️⃣ EMPLOYEES (10 entries)
------------------------------------------------------
INSERT INTO EMPLOYEES (Name, Role, Shift_Time)
VALUES
('Amit Sharma', 'Manager', 'Day'),
('Bina Patel', 'Cashier', 'Night'),
('Chirag Verma', 'Attendant', 'Day'),
('Deepa Rao', 'Attendant', 'Night'),
('Eshan Khan', 'Supervisor', 'Day'),
('Farah Mirza', 'Cashier', 'Night'),
('Gaurav Singh', 'Attendant', 'Day'),
('Hema Iyer', 'Attendant', 'Night'),
('Imran Ali', 'Manager', 'Day'),
('Jiya Krishnan', 'Cashier', 'Night');
GO

------------------------------------------------------
-- 2️⃣ FUEL_TYPES (10 entries)
------------------------------------------------------
INSERT INTO FUEL_TYPES (Name, Current_Price_Per_Liter)
VALUES
('Petrol 95', 105.00),
('Diesel', 94.00),
('Power Petrol', 112.50),
('Premium Diesel', 118.00),
('Auto LPG', 69.00),
('CNG', 60.00),
('Petrol 98', 109.00),
('Ethanol Blend', 90.00),
('Biodiesel', 85.50),
('Aviation Fuel', 150.00);
GO

------------------------------------------------------
-- 3️⃣ TANKS (10 entries)
------------------------------------------------------
INSERT INTO TANKS (Fuel_Type_ID, Capacity_Liters, Current_Level_Liters)
VALUES
(1, 25000, 19000),
(2, 30000, 27000),
(3, 20000, 15000),
(4, 22000, 14000),
(5, 15000, 9000),
(6, 12000, 8000),
(7, 26000, 18000),
(8, 20000, 19500),
(9, 18000, 16000),
(10, 35000, 34000);
GO

------------------------------------------------------
-- 4️⃣ PUMPS (10 entries)
------------------------------------------------------
INSERT INTO PUMPS (Fuel_Type_ID, Pump_Number, Status)
VALUES
(1, 'P1A', 'Active'),
(2, 'P1B', 'Active'),
(3, 'P2A', 'Active'),
(4, 'P2B', 'Maintenance'),
(5, 'P3A', 'Active'),
(6, 'P3B', 'Active'),
(7, 'P4A', 'Active'),
(8, 'P4B', 'Active'),
(9, 'P5A', 'Active'),
(10, 'P5B', 'Active');
GO

------------------------------------------------------
-- 5️⃣ TRANSACTIONS (10 entries)
------------------------------------------------------
INSERT INTO TRANSACTIONS (Pump_ID, Employee_ID, [datetime], Liters_Sold, Total_Amount)
VALUES
(1, 3, GETDATE(), 30.0, 3150.00),
(2, 4, GETDATE(), 45.0, 4230.00),
(3, 5, GETDATE(), 20.0, 2250.00),
(4, 6, GETDATE(), 15.0, 1770.00),
(5, 7, GETDATE(), 25.0, 1725.00),
(6, 8, GETDATE(), 35.0, 2100.00),
(7, 9, GETDATE(), 40.0, 4360.00),
(8, 10, GETDATE(), 50.0, 4500.00),
(9, 2, GETDATE(), 55.0, 4702.50),
(10, 1, GETDATE(), 60.0, 9000.00);
GO
