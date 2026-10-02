USE evergreen_mega_logistics;

-- verifying if the database loaded correctly
SELECT COUNT(*) FROM dim_locations;
SELECT COUNT(*) FROM dim_date;
SELECT COUNT(*) FROM dim_carriers;
SELECT COUNT(*) FROM dim_suppliers;
SELECT COUNT(*) FROM dim_vehicles;

SELECT COUNT(*) AS shipment_count
FROM fact_shipments;

-- 1. Foreign key / dimension validation
SELECT COUNT(*) AS total_shipments,
COUNT(l.Location_ID) AS valid_origins,
COUNT(c.Carrier_ID) AS valid_carriers,
COUNT(s.Supplier_ID) AS valid_suppliers,
COUNT(v.Vehicle_ID) AS valid_vehicles,
COUNT(d.Date_Key) AS valid_dates
FROM fact_shipments f
LEFT JOIN dim_locations l ON f.Origin_ID = l.Location_ID
LEFT JOIN dim_carriers c ON f.Carrier_ID = c.Carrier_ID
LEFT JOIN dim_suppliers s ON f.Supplier_ID = s.Supplier_ID
LEFT JOIN dim_vehicles v ON f.Vehicle_ID = v.Vehicle_ID
LEFT JOIN dim_date d ON f.Order_Date_Key = d.Date_Key;

-- 2. Duplicate shipment ID check
SELECT COUNT(*) AS total_rows,
COUNT(DISTINCT Shipment_ID) AS unique_shipments,
COUNT(*) - COUNT(DISTINCT Shipment_ID) AS duplicate_ids
FROM fact_shipments;

-- 3. Missing values check
SELECT COUNT(*) AS total_rows,
SUM(Order_Date IS NULL) AS missing_dates,
SUM(Origin_ID IS NULL) AS missing_origins,
SUM(Destination_ID IS NULL) AS missing_destinations,
SUM(Carrier_ID IS NULL) AS missing_carriers,
SUM(Supplier_ID IS NULL) AS missing_suppliers,
SUM(Vehicle_ID IS NULL) AS missing_vehicles,
SUM(Revenue_USD IS NULL) AS missing_revenue,
SUM(Total_Cost_USD IS NULL) AS missing_cost
FROM fact_shipments;

-- 4. Gross profit consistency
SELECT COUNT(*) AS incorrect_profit
FROM fact_shipments
WHERE ABS(Gross_Profit_USD - (Revenue_USD - Total_Cost_USD)) > 0.01;

-- 5. Gross margin consistency
SELECT COUNT(*) AS incorrect_margin
FROM fact_shipments
WHERE ABS(Gross_Margin_Pct - ((Revenue_USD - Total_Cost_USD) / Revenue_USD * 100)) > 0.01;

-- 6. Core operational KPIs
SELECT COUNT(*) AS total_shipments,
ROUND(AVG(Matching_Time_Min),2) AS avg_matching_minutes,
ROUND(AVG(Lead_Time_Days),2) AS avg_lead_days,
ROUND(AVG(On_Time_Flag)*100,2) AS otd_pct,
ROUND(AVG(SLA_Flag)*100,2) AS sla_pct
FROM fact_shipments;

-- 7. Financial KPIs
SELECT ROUND(SUM(Revenue_USD),2) AS total_revenue,
ROUND(SUM(Total_Cost_USD),2) AS total_spend,
ROUND(SUM(Gross_Profit_USD),2) AS gross_profit,
ROUND(AVG(Gross_Margin_Pct),2) AS avg_margin_pct,
ROUND(SUM(Estimated_Lost_Revenue_USD),2) AS lost_revenue
FROM fact_shipments;

-- 8. Top 20 busiest routes
SELECT l1.City AS origin, l2.City AS destination,
COUNT(*) AS shipments,
ROUND(AVG(f.Distance_KM),1) AS avg_distance_km,
ROUND(AVG(f.Lead_Time_Days),2) AS avg_lead_days,
ROUND(AVG(f.On_Time_Flag)*100,2) AS otd_pct,
ROUND(AVG(f.Gross_Margin_Pct),2) AS avg_margin_pct,
ROUND(SUM(f.Gross_Profit_USD),2) AS gross_profit
FROM fact_shipments f
JOIN dim_locations l1 ON f.Origin_ID = l1.Location_ID
JOIN dim_locations l2 ON f.Destination_ID = l2.Location_ID
GROUP BY l1.City, l2.City
ORDER BY shipments DESC
LIMIT 20;

-- 9. Worst-performing routes
SELECT l1.City AS origin, l2.City AS destination,
COUNT(*) AS shipments,
ROUND(AVG(f.On_Time_Flag)*100,2) AS otd_pct,
ROUND(AVG(f.Total_Delay_Hours),2) AS avg_delay_hours,
ROUND(AVG(f.Gross_Margin_Pct),2) AS avg_margin_pct
FROM fact_shipments f
JOIN dim_locations l1 ON f.Origin_ID = l1.Location_ID
JOIN dim_locations l2 ON f.Destination_ID = l2.Location_ID
GROUP BY l1.City, l2.City
HAVING COUNT(*) >= 50
ORDER BY otd_pct ASC
LIMIT 10;

-- 10. Delay attribution
SELECT Delay_Category, COUNT(*) AS shipments,
ROUND(SUM(Total_Delay_Hours),2) AS total_delay_hours,
ROUND(AVG(Total_Delay_Hours),2) AS avg_delay_hours
FROM fact_shipments
GROUP BY Delay_Category
ORDER BY total_delay_hours DESC;

-- 11. Route profitability vs distance
SELECT l1.City AS origin, l2.City AS destination,
COUNT(*) AS shipments,
ROUND(AVG(f.Distance_KM),1) AS avg_distance_km,
ROUND(AVG(f.Gross_Margin_Pct),2) AS avg_margin_pct,
ROUND(SUM(f.Gross_Profit_USD),2) AS gross_profit
FROM fact_shipments f
JOIN dim_locations l1 ON f.Origin_ID = l1.Location_ID
JOIN dim_locations l2 ON f.Destination_ID = l2.Location_ID
GROUP BY l1.City, l2.City
HAVING COUNT(*) >= 50
ORDER BY avg_margin_pct ASC
LIMIT 20;

-- 12. Supplier performance scorecard
SELECT s.Supplier_Name AS supplier, COUNT(*) AS shipments,
ROUND(AVG(f.SLA_Flag)*100,2) AS sla_compliance_pct,
ROUND(AVG(f.Defect_Flag)*100,2) AS defect_rate_pct,
ROUND(AVG(f.Lead_Time_Days),2) AS avg_lead_days,
ROUND(AVG(f.Total_Cost_USD),2) AS avg_cost_per_shipment
FROM fact_shipments f
JOIN dim_suppliers s ON f.Supplier_ID = s.Supplier_ID
GROUP BY s.Supplier_ID, s.Supplier_Name
ORDER BY sla_compliance_pct ASC;

-- 13. Supplier volume vs reliability
SELECT s.Supplier_Name AS supplier, COUNT(*) AS shipment_volume,
ROUND(AVG(f.SLA_Flag)*100,2) AS sla_compliance_pct,
ROUND(AVG(f.Defect_Flag)*100,2) AS defect_rate_pct
FROM fact_shipments f
JOIN dim_suppliers s ON f.Supplier_ID = s.Supplier_ID
GROUP BY s.Supplier_ID, s.Supplier_Name
ORDER BY shipment_volume DESC;

-- 14. Carrier performance scorecard
SELECT c.Carrier_Name AS carrier, COUNT(*) AS shipments,
ROUND(AVG(f.On_Time_Flag)*100,2) AS otd_pct,
ROUND(AVG(f.Total_Delay_Hours),2) AS avg_delay_hours,
ROUND(AVG(f.Gross_Margin_Pct),2) AS avg_margin_pct,
ROUND(AVG(f.Carrier_Payout_USD),2) AS avg_carrier_cost
FROM fact_shipments f
JOIN dim_carriers c ON f.Carrier_ID = c.Carrier_ID
GROUP BY c.Carrier_ID, c.Carrier_Name
ORDER BY otd_pct ASC;

-- 15. Monthly performance trend
SELECT DATE_FORMAT(Order_Date,'%Y-%m') AS month,
COUNT(*) AS shipments,
ROUND(SUM(Revenue_USD),2) AS revenue,
ROUND(SUM(Total_Cost_USD),2) AS logistics_spend,
ROUND(SUM(Gross_Profit_USD),2) AS gross_profit,
ROUND(AVG(Gross_Margin_Pct),2) AS avg_margin_pct,
ROUND(AVG(On_Time_Flag)*100,2) AS otd_pct
FROM fact_shipments
GROUP BY DATE_FORMAT(Order_Date,'%Y-%m')
ORDER BY month;

-- 16. Cost category breakdown
SELECT ROUND(SUM(Fuel_Cost_USD),2) AS fuel_cost,
ROUND(SUM(Toll_Cost_USD),2) AS toll_cost,
ROUND(SUM(Warehouse_Cost_USD),2) AS warehouse_cost,
ROUND(SUM(Administrative_Cost_USD),2) AS admin_cost,
ROUND(SUM(Carrier_Payout_USD),2) AS carrier_payout
FROM fact_shipments;

-- 17. Monthly spend vs unit cost
SELECT DATE_FORMAT(Order_Date,'%Y-%m') AS month,
COUNT(*) AS shipments,
ROUND(SUM(Total_Cost_USD),2) AS logistics_spend,
ROUND(AVG(Cost_per_Shipment_USD),2) AS avg_cost_per_shipment,
ROUND(AVG(Cost_per_KM_USD),2) AS avg_cost_per_km
FROM fact_shipments
GROUP BY DATE_FORMAT(Order_Date,'%Y-%m')
ORDER BY month;

-- 18. Delay impact by month
SELECT DATE_FORMAT(Order_Date,'%Y-%m') AS month,
COUNT(*) AS delayed_shipments,
ROUND(SUM(Total_Delay_Hours),2) AS total_delay_hours,
ROUND(AVG(Total_Delay_Hours),2) AS avg_delay_hours,
ROUND(SUM(Estimated_Lost_Revenue_USD),2) AS lost_revenue
FROM fact_shipments
WHERE Total_Delay_Hours > 0
GROUP BY DATE_FORMAT(Order_Date,'%Y-%m')
ORDER BY month;

-- 19. Regional performance
SELECT l1.Country AS origin_country, COUNT(*) AS shipments,
ROUND(AVG(f.On_Time_Flag)*100,2) AS otd_pct,
ROUND(AVG(f.Lead_Time_Days),2) AS avg_lead_days,
ROUND(AVG(f.Gross_Margin_Pct),2) AS avg_margin_pct,
ROUND(SUM(f.Gross_Profit_USD),2) AS gross_profit
FROM fact_shipments f
JOIN dim_locations l1 ON f.Origin_ID = l1.Location_ID
GROUP BY l1.Country
ORDER BY shipments DESC;

-- 20. Action required: worst routes
SELECT CONCAT(l1.City,' → ',l2.City) AS route,
COUNT(*) AS shipments,
ROUND(AVG(f.On_Time_Flag)*100,2) AS otd_pct,
ROUND(AVG(f.Total_Delay_Hours),2) AS avg_delay_hours,
ROUND(AVG(f.Gross_Margin_Pct),2) AS avg_margin_pct,
ROUND(SUM(f.Gross_Profit_USD),2) AS gross_profit
FROM fact_shipments f
JOIN dim_locations l1 ON f.Origin_ID = l1.Location_ID
JOIN dim_locations l2 ON f.Destination_ID = l2.Location_ID
GROUP BY l1.City, l2.City
HAVING COUNT(*) >= 50
ORDER BY otd_pct ASC, avg_margin_pct ASC
LIMIT 5;

-- 21. Action required: worst suppliers
SELECT s.Supplier_Name AS supplier, COUNT(*) AS shipments,
ROUND(AVG(f.SLA_Flag)*100,2) AS sla_compliance_pct,
ROUND(AVG(f.Defect_Flag)*100,2) AS defect_rate_pct,
ROUND(AVG(f.Lead_Time_Days),2) AS avg_lead_days,
ROUND(AVG(f.Total_Cost_USD),2) AS avg_cost_per_shipment
FROM fact_shipments f
JOIN dim_suppliers s ON f.Supplier_ID = s.Supplier_ID
GROUP BY s.Supplier_ID, s.Supplier_Name
HAVING COUNT(*) >= 50
ORDER BY sla_compliance_pct ASC, defect_rate_pct DESC
LIMIT 5;

-- 22. Action required: worst carriers
SELECT c.Carrier_Name AS carrier, COUNT(*) AS shipments,
ROUND(AVG(f.On_Time_Flag)*100,2) AS otd_pct,
ROUND(AVG(f.Total_Delay_Hours),2) AS avg_delay_hours,
ROUND(AVG(f.Gross_Margin_Pct),2) AS avg_margin_pct,
ROUND(AVG(f.Carrier_Payout_USD),2) AS avg_carrier_cost
FROM fact_shipments f
JOIN dim_carriers c ON f.Carrier_ID = c.Carrier_ID
GROUP BY c.Carrier_ID, c.Carrier_Name
HAVING COUNT(*) >= 50
ORDER BY otd_pct ASC, avg_margin_pct ASC
LIMIT 5;