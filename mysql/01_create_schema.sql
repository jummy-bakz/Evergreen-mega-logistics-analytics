CREATE DATABASE IF NOT EXISTS evergreen_mega_logistics;
USE evergreen_mega_logistics;

CREATE TABLE dim_locations (
    Location_ID VARCHAR(10) PRIMARY KEY,
    City VARCHAR(100), State VARCHAR(100), Country VARCHAR(100), Region VARCHAR(50),
    Latitude DECIMAL(9,6), Longitude DECIMAL(9,6)
);

CREATE TABLE dim_carriers (
    Carrier_ID VARCHAR(10) PRIMARY KEY,
    Carrier_Name VARCHAR(100), Carrier_Type VARCHAR(50), Reliability_Tier VARCHAR(20),
    Base_OTD_Rate DECIMAL(6,4), OTD_Target_Pct DECIMAL(5,2)
);

CREATE TABLE dim_suppliers (
    Supplier_ID VARCHAR(10) PRIMARY KEY,
    Supplier_Name VARCHAR(100), Supplier_Category VARCHAR(60), Risk_Tier VARCHAR(20),
    Base_SLA_Rate DECIMAL(6,4), SLA_Target_Pct DECIMAL(5,2)
);

CREATE TABLE dim_vehicles (
    Vehicle_ID VARCHAR(10) PRIMARY KEY,
    Vehicle_Type_ID VARCHAR(10), Model_Year INT, Fuel_Type VARCHAR(30),
    Vehicle_Type VARCHAR(50), Category VARCHAR(50), Capacity_KG DECIMAL(12,2),
    Efficiency_L_per_100KM DECIMAL(8,2)
);

CREATE TABLE dim_date (
    Date_Key INT PRIMARY KEY,
    Date DATE, Year INT, Month_Number INT, Month_Name VARCHAR(20),
    Month_Year VARCHAR(20), Quarter VARCHAR(5), Week_Number INT, Day_Name VARCHAR(20)
);

CREATE TABLE fact_shipments (
    Shipment_ID VARCHAR(20) PRIMARY KEY,
    Order_Date DATETIME, Order_Date_Key INT,
    Origin_ID VARCHAR(10), Destination_ID VARCHAR(10), Carrier_ID VARCHAR(10),
    Supplier_ID VARCHAR(10), Vehicle_ID VARCHAR(10),
    Shipment_Type VARCHAR(50), Priority VARCHAR(20),
    Shipment_Weight_KG DECIMAL(12,2), Distance_KM DECIMAL(12,1),
    Booking_Time DATETIME, Assignment_Time DATETIME, Pickup_Time DATETIME,
    Expected_Delivery_Time DATETIME, Actual_Delivery_Time DATETIME,
    Matching_Time_Min DECIMAL(10,1),
    Pickup_Delay_Hours DECIMAL(10,2), Transit_Delay_Hours DECIMAL(10,2),
    Unloading_Delay_Hours DECIMAL(10,2), Total_Delay_Hours DECIMAL(10,2),
    On_Time_Flag TINYINT, SLA_Flag TINYINT, Damage_Flag TINYINT,
    Documentation_Defect_Flag TINYINT, Defect_Flag TINYINT,
    Delay_Category VARCHAR(20), Shipment_Status VARCHAR(30),
    Fuel_Cost_USD DECIMAL(12,2), Toll_Cost_USD DECIMAL(12,2),
    Warehouse_Cost_USD DECIMAL(12,2), Administrative_Cost_USD DECIMAL(12,2),
    Carrier_Payout_USD DECIMAL(12,2), Total_Cost_USD DECIMAL(12,2),
    Revenue_USD DECIMAL(12,2), Gross_Profit_USD DECIMAL(12,2),
    Gross_Margin_Pct DECIMAL(7,2), Estimated_Lost_Revenue_USD DECIMAL(12,2),
    Lead_Time_Days DECIMAL(10,2), Cost_per_KM_USD DECIMAL(10,4),
    Cost_per_Shipment_USD DECIMAL(12,2),
    FOREIGN KEY (Origin_ID) REFERENCES dim_locations(Location_ID),
    FOREIGN KEY (Destination_ID) REFERENCES dim_locations(Location_ID),
    FOREIGN KEY (Carrier_ID) REFERENCES dim_carriers(Carrier_ID),
    FOREIGN KEY (Supplier_ID) REFERENCES dim_suppliers(Supplier_ID),
    FOREIGN KEY (Vehicle_ID) REFERENCES dim_vehicles(Vehicle_ID),
    FOREIGN KEY (Order_Date_Key) REFERENCES dim_date(Date_Key)
);

