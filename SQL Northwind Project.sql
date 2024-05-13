--SQL Project using northwind dataset

/* 
gross revenue,
total discount, net revenue, orders, quantity of products and unique products,
divided by years and quarters.*/


SELECT
    YEAR(OrderDate) AS Year,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    SUM(UnitPrice * Quantity) AS GrossRevenue,
    SUM(Discount * Quantity * UnitPrice) AS TotalDiscount,
    SUM((UnitPrice * Quantity) * (1 - Discount)) AS NetRevenue,
    COUNT(DISTINCT od.OrderID) AS Orders,
    SUM(Quantity) AS TotalQuantity,
    COUNT(DISTINCT ProductID) AS UniqueProducts
FROM
    [Order Details] od
JOIN
    Orders o ON od.OrderID = o.OrderID
GROUP BY
    YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY
    Year, Quarter


/*Analyzed shipment performance by product name, focusing on orders from 1997 where the days to ship exceeded 200. 
Results are ordered by days to ship in descending order*/

SELECT
    ProductName,
    DaystoShip,
    OrderCount
FROM
(
    SELECT
        ProductName,
        SUM(DaystoShip) OVER (PARTITION BY ProductName) AS DaystoShip,
        SUM(OrderCount) OVER (PARTITION BY ProductName) AS OrderCount
    FROM
    (
        SELECT
            ProductName,
            COUNT(o.OrderID) AS OrderCount,
            SUM(DATEDIFF(DAY, o.OrderDate, o.ShippedDate)) AS DaystoShip
        FROM
            Orders o
        JOIN
            [Order Details] od ON o.OrderID = od.OrderID
        JOIN
            Products p ON od.ProductID = p.ProductID
        WHERE
            YEAR(OrderDate) = 1997
        GROUP BY
            ProductName, DATEDIFF(DAY, o.OrderDate, o.ShippedDate)
    ) a
) a
WHERE
    DaystoShip > 200
GROUP BY
    ProductName, OrderCount, DaystoShip
ORDER BY
    DaystoShip DESC


/*analyze shipment performance by ship country, focusing on Germany, USA, Brazil, and Austria. 
The metrics include gross revenue, discount, net revenue, orders, quantity, and the number of products shipped*/


SELECT
    ShipCountry,
    SUM(UnitPrice * Quantity) AS GrossRevenue,
    SUM(Discount * Quantity * UnitPrice) AS TotalDiscount,
    SUM((UnitPrice * Quantity) * (1 - Discount)) AS NetRevenue,
    COUNT(DISTINCT od.OrderID) AS Orders,
    SUM(Quantity) AS TotalQuantity,
    COUNT(DISTINCT ProductID) AS UniqueProducts
FROM
    [Order Details] od
JOIN
    Orders o ON od.OrderID = o.OrderID
WHERE
    ShipCountry IN ('Germany', 'USA', 'Brazil', 'Austria')
GROUP BY
    ShipCountry



/*analyze gross revenue and orders by month names in 1997, ordered by month numbers*/

SELECT
    MONTH(OrderDate) AS Month_num,
    DATENAME(MONTH, OrderDate) AS Month_Name,
    SUM(UnitPrice * Quantity) AS GrossRevenue,
    COUNT(DISTINCT od.OrderID) AS Orders
FROM
    [Order Details] od
JOIN
    Orders o ON o.OrderID = od.OrderID
WHERE
    YEAR(OrderDate) = 1997
GROUP BY
    MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY
    Month_num



/* Analyzed shipping company performance in 1997 by providing the days to ship and the number of orders for each ship company*/

SELECT
    CompanyName,
    SUM(DATEDIFF(DAY, o.OrderDate, o.ShippedDate)) AS DaysToShip,
    COUNT(OrderID) AS Orders
FROM
    Orders o
JOIN
    Shippers s ON o.ShipVia = s.ShipperID
WHERE
    YEAR(OrderDate) = 1997
GROUP BY
    CompanyName


/*We analyze the top and bottom products in our store for the year 1997 based on their sales volume. 
The results will include the names of the top 5 and bottom 5 products*/

SELECT
    Name_1,
    Orders
FROM
(
    SELECT
        DENSE_RANK() OVER (ORDER BY Orders DESC) AS Dense,
        DENSE_RANK() OVER (ORDER BY Orders ASC) AS Dense1,
        Name_1,
        Orders
    FROM
    (
        SELECT
            P.ProductName AS Name_1,
            COUNT(o.OrderID) AS Orders
        FROM
            Products P
        JOIN
            [Order Details] OD ON P.ProductID = OD.ProductID
        JOIN
            Orders O ON OD.OrderID = O.OrderID
        WHERE
            YEAR(OrderDate) = 1997
        GROUP BY
            P.ProductName
    ) a
) a
WHERE
    Dense < 6 OR Dense1 < 6
ORDER BY
    Orders DESC


/*We analyze the performance of main categories and products in 1997 by providing the orders, 
quantity, gross revenue, discount, and net revenue for the top 10 percent of orders within each category name and product name*/

SELECT TOP 10 PERCENT
    CategoryName,
    ProductName,
    COUNT(od.OrderID) AS Orders,
    SUM(Quantity) AS Quantity,
    SUM(od.UnitPrice * Quantity) AS GrossRevenue,
    SUM(Discount * Quantity * od.UnitPrice) AS TotalDiscount,
    SUM((od.UnitPrice * Quantity) * (1 - Discount)) AS NetRevenue
FROM
    Products P
JOIN
    [Order Details] OD ON P.ProductID = OD.ProductID
JOIN
    Orders O ON OD.OrderID = O.OrderID
JOIN
    Categories C ON P.CategoryID = C.CategoryID
WHERE
    YEAR(OrderDate) = 1997
GROUP BY
    CategoryName, ProductName
ORDER BY
    Orders DESC




/*analyze the total units in stock and units on order per category name and product name for products with an amount of units in stock lower than 10*/

SELECT
    CategoryName,
    ProductName,
    UnitsInStock,
    UnitsOnOrder
FROM
    Products p
JOIN
    Categories c ON p.CategoryID = c.CategoryID
WHERE
    UnitsInStock < 10
ORDER BY
    ProductName

/*We analyze employee performance in 1997 by providing a list of employee names with their top 5 and bottom 5 orders. 
Additionally, a new column named ‘performance’ is added to indicate the performance ranking for each employee*/


SELECT FirstName, Performance, Orders
FROM (
    SELECT FirstName,
        CASE
            WHEN Top_5 < 6 THEN 'Top_5'
        END AS Performance,
        Orders
    FROM (
        SELECT FirstName, Orders,
            ROW_NUMBER() OVER (ORDER BY Orders DESC) AS Top_5,
            ROW_NUMBER() OVER (ORDER BY Orders ASC) AS Bottom_5
        FROM (
            SELECT FirstName, COUNT(OrderID) AS Orders
            FROM Employees e
            JOIN Orders o ON o.EmployeeID = e.EmployeeID
            WHERE YEAR(OrderDate) = 1997
            GROUP BY FirstName
        ) a
    ) a
) a
WHERE Performance IS NOT NULL

UNION ALL

SELECT FirstName, Performance, Orders
FROM (
    SELECT FirstName,
        CASE
            WHEN Bottom_5 < 6 THEN 'Bottom_5'
        END AS Performance,
        Orders
    FROM (
        SELECT FirstName, Orders,
            ROW_NUMBER() OVER (ORDER BY Orders DESC) AS Top_5,
            ROW_NUMBER() OVER (ORDER BY Orders ASC) AS Bottom_5
        FROM (
            SELECT FirstName, COUNT(OrderID) AS Orders
            FROM Employees e
            JOIN Orders o ON o.EmployeeID = e.EmployeeID
            WHERE YEAR(OrderDate) = 1997
            GROUP BY FirstName
        ) a
    ) a
) a
WHERE Performance IS NOT NULL








/*We analyze employee performance in 1997 by providing a list of employee names with their orders, quantity, gross revenue, discount, and net revenue. 
Additionally, we calculate the same KPIs per each title, without considering individual employees.*/

SELECT
    Title,
    FirstName,
    Orders,
    Qty,
    Gross_Revenue,
    Discount,
    Net_Revenue,
    SUM(Orders) OVER (PARTITION BY Title) AS Total_orders,
    SUM(Qty) OVER (PARTITION BY Title) AS Total_Qty,
    SUM(Gross_Revenue) OVER (PARTITION BY Title) AS Total_Gross_Revenue,
    SUM(Discount) OVER (PARTITION BY Title) AS Total_Discount,
    SUM(Net_Revenue) OVER (PARTITION BY Title) AS Total_Net_Revenue
FROM (
    SELECT
        Title,
        FirstName,
        COUNT(DISTINCT od.OrderID) AS Orders,
        SUM(Quantity) AS Qty,
        SUM(UnitPrice * Quantity) AS Gross_Revenue,
        SUM(UnitPrice * Quantity * Discount) AS Discount,
        SUM(UnitPrice * Quantity) - SUM(UnitPrice * Quantity * Discount) AS Net_Revenue
    FROM
        [Order Details] od
    JOIN
        Orders o ON od.OrderID = o.OrderID
    JOIN
        Employees e ON e.EmployeeID = o.EmployeeID
    WHERE
        YEAR(OrderDate) = 1997
    GROUP BY
        Title, FirstName
) a
ORDER BY
    Title



/*
We would like to know per each of region description the orders and revenue made,
and the revenue per order. Please order it by revenue per order descending.
*/

SELECT
    RegionDescription,
    COUNT(DISTINCT OrderID) AS Orders,
    SUM(UnitPrice * Quantity) AS Revenue,
    SUM(UnitPrice * Quantity) / COUNT(DISTINCT OrderID) AS Revenue_Per_Order
FROM (
    SELECT DISTINCT
        od.OrderID,
        RegionDescription,
        od.UnitPrice,
        Quantity
    FROM
        Orders o
    JOIN
        [Order Details] od ON o.OrderID = od.OrderID
    JOIN
        EmployeeTerritories et ON o.EmployeeID = et.EmployeeID
    JOIN
        Territories t ON t.TerritoryID = et.TerritoryID
    JOIN
        Region r ON r.RegionID = t.RegionID
) a
GROUP BY
    RegionDescription
ORDER BY
    Revenue_Per_Order DESC



--Data Summery

SELECT
    o.OrderDate,
    datename(month,o.OrderDate) AS Month,
    DATEPART(QUARTER, o.OrderDate) AS Quarter,
    c.CustomerID,
    c.Country,
    c.City,
    o.ShipVia AS ShipperID,
    s.CompanyName AS ShippingCompany,
    e.EmployeeID,
    e.Title AS Title,
    e.FirstName,
    p.ProductName,
    cat.CategoryName,
    (od.UnitPrice * od.Quantity) AS gross_revenue,
    od.Discount,
    od.Quantity,
    DATEDIFF(DAY, o.OrderDate, o.ShippedDate) AS days_to_ship,
    COUNT(DISTINCT p.ProductID) AS products,
    COUNT(DISTINCT o.OrderID) AS orders
FROM Orders o
JOIN Customers c 
	ON o.CustomerID = c.CustomerID
JOIN Employees e 
	ON o.EmployeeID = e.EmployeeID
JOIN Shippers s 
	ON o.ShipVia = s.ShipperID
JOIN [Order Details] od 
	ON o.OrderID = od.OrderID
JOIN Products p 
	ON od.ProductID = p.ProductID
JOIN Categories cat 
	ON p.CategoryID = cat.CategoryID
GROUP BY
    o.OrderDate,MONTH(o.OrderDate),DATEPART(QUARTER, o.OrderDate),c.CustomerID,c.Country,c.City,o.ShipVia,
	s.CompanyName,e.EmployeeID,e.Title,e.FirstName,p.ProductName,cat.CategoryName,od.UnitPrice,od.Discount,od.Quantity,o.ShippedDate




