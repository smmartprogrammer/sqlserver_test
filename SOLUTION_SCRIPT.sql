/*
Q1. List top 5 customers by total order amount.
Retrieve the top 5 customers who have spent the most across all sales orders. Show CustomerID, CustomerName, and TotalSpent.
*/

SELECT TOP 5 
    c.CustomerID,
    c.Name,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customer c
JOIN salesorder o 
    ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Name
ORDER BY TotalSpent DESC;

/*
Q2. Find the number of products supplied by each supplier.
Display SupplierID, SupplierName, and ProductCount. Only include suppliers that have more than 10 products.
*/

select s.SupplierID, s.Name,   Count(pod.ProductID) As ProductCount
from Supplier s
join PurchaseOrder po
on s.SupplierID = po.SupplierID
join PurchaseOrderDetail pod
on po.OrderID = pod.OrderID
GROUP BY s.SupplierID, s.Name
HAVING COUNT(pod.ProductID) > 10
ORDER BY ProductCount DESC;

/*
Q3. Identify products that have been ordered but never returned.
Show ProductID, ProductName, and total order quantity.
*/

SELECT 
    p.ProductID,
    p.Name AS ProductName,
    SUM(pod.Quantity) AS TotalOrderQuantity
FROM Product p
JOIN PurchaseOrderDetail pod
    ON p.ProductID = pod.ProductID
JOIN PurchaseOrder po
    ON po.OrderID = pod.OrderID
LEFT JOIN ReturnDetail rd
    ON rd.ProductID = p.ProductID
LEFT JOIN returns r
    ON r.OrderID = p.ProductID    
WHERE rd.ProductID IS NULL       
GROUP BY p.ProductID, p.Name
ORDER BY TotalOrderQuantity DESC;

/*
Q4. For each category, find the most expensive product.
Display CategoryID, CategoryName, ProductName, and Price. Use a subquery to get the max price per category.
*/

SELECT 
    c.CategoryID,
    c.Name AS CategoryName,
    p.Name AS ProductName,
    p.Price
FROM Product p
JOIN Category c
    ON p.CategoryID = c.CategoryID
WHERE p.Price = (
    SELECT MAX(p2.Price)
    FROM Product p2
    WHERE p2.CategoryID = p.CategoryID
)
ORDER BY c.CategoryID;


/*
Q5. List all sales orders with customer name, product name, category, and supplier.
For each sales order, display:
OrderID, CustomerName, ProductName, CategoryName, SupplierName, and Quantity.
*/

SELECT 
    so.OrderID,
    c.Name AS CustomerName,
    p.Name AS ProductName,
    cat.Name AS CategoryName,
    s.Name AS SupplierName,
    sod.Quantity
FROM SalesOrder so
JOIN Customer c
    ON so.CustomerID = c.CustomerID
JOIN SalesOrderDetail sod
    ON so.OrderID = sod.OrderID
JOIN Product p
    ON sod.ProductID = p.ProductID
JOIN Category cat
    ON p.CategoryID = cat.CategoryID
JOIN PurchaseOrderDetail pod
    ON p.ProductID = pod.ProductID
JOIN PurchaseOrder po
    ON pod.OrderID = po.OrderID
JOIN Supplier s
    ON po.SupplierID = s.SupplierID
ORDER BY so.OrderID;

/*
Q6. Find all shipments with details of warehouse, manager, and products shipped.
Display:
ShipmentID, WarehouseName, ManagerName, ProductName, QuantityShipped, and TrackingNumber.
*/


/*
Q6. Find all shipments with details of warehouse, manager, and products shipped.
Display:
ShipmentID, WarehouseName, ManagerName, ProductName, QuantityShipped, and TrackingNumber.
*/

SELECT 
    sh.ShipmentID,
    d.Name AS WarehouseName, -- warehouse name is not giving on any table, therefore i am using department name here
    e.Name AS ManagerName,
    p.Name AS ProductName,
    count(sd.ShipmentID) AS QuantityShipped,
    sh.TrackingNumber
FROM Shipment sh
JOIN Warehouse w
    ON sh.WarehouseID = w.WarehouseID
JOIN Department d
    ON d.LocationID = w.LocationID
JOIN Employee e
    ON e.EmployeeID = d.ManagerID   
JOIN ShipmentDetail sd
    ON sh.ShipmentID = sd.ShipmentID
JOIN Product p
    ON sd.ProductID = p.ProductID
GROUP BY 
    sh.ShipmentID, d.Name, e.Name, p.Name, sh.TrackingNumber
ORDER BY sh.ShipmentID;


/*
Q7. Find the top 3 highest-value orders per customer using RANK().
Display CustomerID, CustomerName, OrderID, and TotalAmount.
*/

WITH RankedOrders AS (
    SELECT 
        c.CustomerID,
        c.Name AS CustomerName,
        o.OrderID,
        o.TotalAmount,
        RANK() OVER (
            PARTITION BY c.CustomerID 
            ORDER BY o.TotalAmount DESC
        ) AS OrderRank
    FROM Customer c
    JOIN SalesOrder o
        ON c.CustomerID = o.CustomerID
)
SELECT 
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount,
    OrderRank
FROM RankedOrders
WHERE OrderRank <= 3
ORDER BY  OrderRank;

/*
Q8. For each product, show its sales history with the previous and next sales quantities (based on order date).
Display ProductID, ProductName, OrderID, OrderDate, Quantity, PrevQuantity, and NextQuantity.
*/

SELECT
    p.ProductID,
    p.Name AS ProductName,
    so.OrderID,
    so.OrderDate,
    sod.Quantity,
    LAG(sod.Quantity) OVER (
        PARTITION BY p.ProductID 
        ORDER BY so.OrderDate
    ) AS PrevQuantity,
    LEAD(sod.Quantity) OVER (
        PARTITION BY p.ProductID 
        ORDER BY so.OrderDate
    ) AS NextQuantity
FROM Product p
JOIN SalesOrderDetail sod
    ON p.ProductID = sod.ProductID
JOIN SalesOrder so
    ON sod.OrderID = so.OrderID
ORDER BY p.ProductID, so.OrderDate;


Q9. Create a view named vw_CustomerOrderSummary that shows for each customer:
CustomerID, CustomerName, TotalOrders, TotalAmountSpent, and LastOrderDate.


/*
Q9. Create a view named vw_CustomerOrderSummary that shows for each customer:
CustomerID, CustomerName, TotalOrders, TotalAmountSpent, and LastOrderDate.
*/

CREATE VIEW vw_CustomerOrderSummary AS
SELECT
    c.CustomerID,
    c.Name AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalAmountSpent,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customer c
LEFT JOIN SalesOrder o
    ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Name;


SELECT * FROM vw_CustomerOrderSummary
ORDER BY TotalAmountSpent DESC;


/*
Q10. Write a stored procedure sp_GetSupplierSales that takes a SupplierID as input 
and returns the total sales amount for all products supplied by that supplier.
*/

CREATE PROCEDURE sp_GetSupplierSales
    @SupplierID INT
AS
BEGIN
    SELECT 
        s.SupplierID,
        s.Name AS SupplierName,
        SUM(sod.Quantity * sod.UnitPrice) AS TotalSalesAmount
    FROM Supplier s
    JOIN PurchaseOrder po
        ON po.SupplierID = s.SupplierID
    JOIN PurchaseOrderDetail pod
        ON po.OrderID = pod.OrderID
    JOIN Product p
        ON pod.ProductID = p.ProductID
    JOIN SalesOrderDetail sod
        ON p.ProductID = sod.ProductID
    JOIN SalesOrder so
        ON sod.OrderID = so.OrderID
    WHERE s.SupplierID = @SupplierID
    GROUP BY s.SupplierID, s.Name;
END;


EXEC sp_GetSupplierSales @SupplierID = 3;
