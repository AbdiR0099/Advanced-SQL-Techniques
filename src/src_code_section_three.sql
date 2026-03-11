-- Advanced SQL Techniques

-- Get MetaData
SELECT
*
FROM INFORMATION_SCHEMA.COLUMNS

SELECT
DISTINCT TABLE_NAME
FROM INFORMATION_SCHEMA.COLUMNS

-- SUBQUERY
-- A QUERY INSIDE ANOTHER QUERY

/* RESULT TYPE */
-- SCALAR SUBQUERY
-- ONE VALUE // ONE ROW
SELECT
	AVG(ORDERID)
FROM SALES.ORDERS

-- ROW SUBQUERY
-- ONE COLUMN // MULTIPLE ROWS
SELECT CUSTOMERID FROM SALES.ORDERS

-- TABLE SUBQUERY
-- MULTIPLE COLUMNS // MULTIPLE ROWS
SELECT * FROM SALES.ORDERS

-- Find the products that have a price higher than the average price of all products
			
SELECT
* 
FROM(SELECT
				PRODUCTID,
				PRICE,
				AVG(PRICE) OVER()[AvgPrice]
			FROM SALES.Products)t WHERE PRICE > AVGPRICE

-- Rank the Customers based on their total amount of sales
SELECT
*,
RANK() OVER(ORDER BY TOTALSALES DESC) RANK
FROM (
		SELECT
		CustomerID,
		SUM(Sales) AS TotalSales
		FROM Sales.Orders
		GROUP BY CustomerID)t


-- Subquery in SELECT Clause
-- Used to aggregate data side by side with the main query's data, allowing for direct comparison
-- Rules: Only Scalar Subqueries are allowed to be used

-- Show the product IDs, Product Names, Prices and total number of orders
-- MAIN QUERY
SELECT
	PRODUCTID,
	PRODUCT,
	Price,
	-- SUBQUERY
	(SELECT COUNT(*) FROM Sales.Orders) [TotalOrders]
FROM Sales.Products;


-- Subquery in JOIN Clause
-- Used to prepare the data (filtering or aggregation) before joining it with other tables

-- Show all customer details and find the total orders of each customer

SELECT
c.*,
o.TotalOrders
FROM Sales.Customers c
LEFT JOIN (
SELECT
CUSTOMERID,
COUNT(*) [TotalOrders]
FROM Sales.Orders
GROUP BY CustomerID ) o
ON c.CustomerID = o.CustomerID

-- WHERE Subquery
-- Used for Complex Filtering Logic and Makes query more flexible and dynamic
-- Rules: Only Scalar Subqueries are allowed to be used
-- Find the products that have a price higher than the average price of all products
SELECT
PRODUCTID,
PRICE,
(SELECT AVG(PRICE) FROM SALES.Products) [AvgPrice]
FROM SALES.Products
WHERE PRICE > (SELECT AVG(PRICE) FROM SALES.Products) 

-- Show the details of orders made by customers in Germany
SELECT
*
FROM Sales.Orders
WHERE CustomerID IN (
SELECT
CustomerID
FROM Sales.Customers
WHERE Country = 'Germany' )

-- ANY Operator
-- Checks if a value matches ANY value within a list.
-- Used to Check if a value is true for at least one of the values in a list.

-- Find females employees whose salaries are greater than salaries of any male employees
SELECT
*
FROM Sales.Employees
WHERE Gender = 'F'
AND Salary > ANY (SELECT Salary FROM Sales.Employees WHERE Gender = 'M')

-- ALL Operator
-- Checks if a value matches all values within a list
SELECT
*
FROM Sales.Employees
WHERE Gender = 'F'
AND Salary > ALL (SELECT Salary FROM Sales.Employees WHERE Gender = 'M')

 -- NON-CORRELATED SUBQUERY
 -- A Subquery that can run independtly from the Main Query

-- CORRELATED SUBQUERY
-- A Subquery that relies on values from main query
-- Show all customer details and find the total orders of each customer
SELECT
*,
(SELECT COUNT(*) FROM SALES.Orders o WHERE o.CustomerID = c.CustomerID) [TotalOrdersByEachCustomer]
FROM Sales.Customers c

/* Query for Understanding
SELECT
*,
(SELECT COUNT(*) FROM SALES.Orders) [TotalOrders]
FROM Sales.Customers

SELECT
CustomerID,
COUNT(*) [TotalOrders]
FROM Sales.Orders
GROUP BY CustomerID */

-- EXISTS
-- CHECK if a subquery returns any rows

-- Show the details of orders made by customers in Germany
SELECT
*
FROM Sales.Orders o
WHERE EXISTS ( SELECT
				1 -- Best practice to use 
				FROM Sales.Customers c
				WHERE Country = 'Germany'
				AND o.CustomerID = c.CustomerID) -- Establish a relationship between main query and subquery when using EXISTS


-- COMMON TABLE EXPRESSION (CTE)
-- Temporary, named result set (virtual table)
-- that can be used multiple times within your query
-- to simplify and organize complex query
-- NOTE: Similar to Subqueries, However, Can be used/referenced multiple times
-- RESTRICTION: CANNOT USE ORDER BY IN CTE (CAN USE IN MAIN QUERY)

/*
WITH CTE-NAME AS
(
SELECT
FROM
WHERE
) */

-- STEP1: Find the total Sales Per Customer (Standalone CTE)
WITH CTE_Total_Sales AS
(
SELECT
CustomerID,
SUM(Sales) [TotalSalesPerCustomer]
FROM Sales.Orders
GROUP BY CustomerID
)
-- STEP2: Find the Last order date for each customer (Multiple Standalone CTE)
, CTE2_Last_Order AS
(
SELECT
CustomerID,
MAX(OrderDate) [Last_Order]
FROM Sales.Orders
GROUP BY CustomerID
)

-- NESTED CTE
-- A CTE inside another CTE
-- A nested CTE uses the result of another CTE, so it can't run independently
-- STEP3: Rank Customers Based on Total Sales per Customer
, CTE3_Customer_Rank AS
(
SELECT
*,
RANK() OVER (ORDER BY TotalSalesPerCustomer DESC) [Customer_Rank]
FROM CTE_Total_Sales
)
-- STEP4: Segment the Customers Based on their Total Sales
, CTE4_Customer_Segment AS
(
SELECT
*,
CASE WHEN TotalSalesPerCustomer > 100 THEN 'High'
	 WHEN TotalSalesPerCustomer > 80 THEN 'Medium'
	 ELSE 'Low' 
END  [Segment]
FROM CTE_Total_Sales
)

-- Main Query
SELECT
c.CustomerID,
c.FirstName,
c.LastName,
cts.TotalSalesPerCustomer,
cts2.Last_Order,
cts3.Customer_Rank,
cts4.Segment
FROM Sales.Customers c
LEFT JOIN CTE_Total_Sales cts
ON cts.CustomerID = c.CustomerID
LEFT JOIN CTE2_Last_Order cts2
ON cts2.CustomerID = c.CustomerID
LEFT JOIN CTE3_Customer_Rank cts3
ON cts3.CustomerID = c.CustomerID
LEFT JOIN CTE4_Customer_Segment cts4
ON cts4.CustomerID = c.CustomerID
ORDER BY cts3.Customer_Rank

-- CTE Best Practice:
-- Dont create a new CTE for each new column/operation
-- Rethink and refactor/merge CTEs before starting a new one
-- Dont use more than 5 CTEs in one query; otherwise the code will be hard to understand and maintain

-- Non-Recursive CTE
-- CTE that is executed only once without repetition
-- Recursive CTE
-- Self-referencing query that repeadtedly processes data until a specific condition is met
/* Syntax:
WITH CTE-NAME AS
( -- ANCHOR QUERY
SELECT ...
FROM ...
WHERE ...
UNION // UNION ALL
SELECT ...
FROM CTE-NAME
WHERE [BREAK CONDITION]
)
*/
-- Task: Generate a sequence of numbers from 1 to 20
WITH CTE_Sequence AS
( 
-- Anchor Query
SELECT 
1 [Number]
UNION ALL
-- Recursive Query
SELECT
NUMBER + 1
FROM CTE_Sequence
WHERE NUMBER < 20
)

-- Main Query
SELECT * FROM CTE_Sequence
OPTION (MAXRECURSION 1000) -- LIMIT THE NUMBER OF LOOPS//ITERATIONS

-- Task: Show the employee hierarchy by displaying each employee's level within the organization
WITH CTE_Hierarchy AS (
		-- Anchor Query
		SELECT
		EmployeeID,
		FirstName,
		ManagerID,
		1 AS [Level]
		FROM Sales.Employees
		WHERE ManagerID IS NULL
		UNION ALL
			-- RECURSIVE QUERY
			SELECT
			e.EmployeeID,
			e.FirstName,
			e.ManagerID,
			[Level] + 1
			FROM Sales.Employees AS e
			INNER JOIN CTE_Hierarchy AS h
			ON e.ManagerID = h.EmployeeID

)
SELECT * FROM CTE_Hierarchy

-- CTE Summary:
-- Readability: Breaks down complex queries into smaller pieces
-- Modularity: Pieces are easy to manage, develop and self-contained.
-- Reusability: Reduce redundancy in query
-- Recursive: Iterations and looping in SQL
-- Tip: Don't create more than 5 CTEs in a query

-- VIEWS
-- A virtual table that shows data without storing it physically
-- Views are persisited SQL queries in the database
-- Reduce redundancy in Multi-Queries
-- Improve Reusability in Multi-Queries
-- Persisted Logic
-- Need to Maintain (DDL) (-CREATE/DROP-)

-- Use Case 1: Central Complex Query Logic
-- Store central, complex query logic in the database for access by multiple queries, reducing project complexity

-- Find the running total of sales for each month
WITH CTE_MS AS (
		SELECT
		DATETRUNC(month,OrderDate) OrderMonth,
		SUM(Sales) TotalSales,
		COUNT(OrderID) TotalOrders,
		SUM(Quantity) TotalQuantities
		FROM Sales.Orders
		GROUP BY DATETRUNC(month,OrderDate)
)
SELECT
*,
SUM(TotalSales) OVER(ORDER BY OrderMonth) [RunningSales]
FROM CTE_MS

-- Create a View so that it can be referenced multiple times

CREATE VIEW Sales.V_Monthly_Summary AS (
		SELECT
		DATETRUNC(month,OrderDate) OrderMonth,
		SUM(Sales) TotalSales,
		COUNT(OrderID) TotalOrders,
		SUM(Quantity) TotalQuantities
		FROM Sales.Orders
		GROUP BY DATETRUNC(month,OrderDate)
)
-- When Run, Commands completed successfully is shown as this is DDL (data definition language). 
-- Query the View
SELECT * FROM V_Monthly_Summary
SELECT
*,
SUM(TotalSales) OVER(ORDER BY OrderMonth) [RunningSales]
FROM V_Monthly_Summary

-- Delete the view
DROP VIEW V_Monthly_Summary -- dbo.V_Monthly_Summary is default schema (dbo)

-- T-SQL 
-- Transact SQL is an extension of SQL that adds programming features
IF OBJECT_ID('Sales.V_Monthly_Summary','V') IS NOT NULL
	DROP VIEW Sales.V_Monthly_Summary

-- Views Use Case
-- Views can be use to hide the complexity of database tables and offers users more friendly and easy to consume objects

-- Task: Provide view that combines details from orders, products, customers and employees
CREATE VIEW Sales.V_Order_Details AS (
		SELECT
		o.OrderID,
		o.OrderDate,
		p.Product,
		p.Price,
		p.Category,
		COALESCE(c.FirstName,'') + '' + COALESCE(c.LastName,'') [CustomerName],
		c.Country [CustomerCountry],
		COALESCE(e.FirstName,'') + '' + COALESCE(e.LastName,'') [EmployeeName],
		e.Department,
		o.Quantity,
		o.Sales
		FROM Sales.Orders o
		LEFT JOIN Sales.Products p
		ON p.ProductID = o.ProductID
		LEFT JOIN Sales.Customers c
		ON c.CustomerID = o.CustomerID
		LEFT JOIN Sales.Employees e
		ON e.EmployeeID = o.SalesPersonID
)

SELECT * FROM Sales.V_Order_Details

-- Coloumn/Row Security: To exclude data when creating a view to limit access
-- Task: Provide a view for EU Sales Team that combines details from all the tables and excludes data related to USA
CREATE VIEW Sales.V_Order_Details_EU AS (
		SELECT
		o.OrderID,
		o.OrderDate,
		p.Product,
		p.Price,
		p.Category,
		COALESCE(c.FirstName,'') + '' + COALESCE(c.LastName,'') [CustomerName],
		c.Country [CustomerCountry],
		COALESCE(e.FirstName,'') + '' + COALESCE(e.LastName,'') [EmployeeName],
		e.Department,
		o.Quantity,
		o.Sales
		FROM Sales.Orders o
		LEFT JOIN Sales.Products p
		ON p.ProductID = o.ProductID
		LEFT JOIN Sales.Customers c
		ON c.CustomerID = o.CustomerID
		LEFT JOIN Sales.Employees e
		ON e.EmployeeID = o.SalesPersonID
		WHERE c.Country != 'USA'
)

SELECT * FROM Sales.V_Order_Details_EU

-- Use Case: Provide Views in Multiple Languages(German/Arabic etc.)

-- IMP!!: VIEWS USE CASE
-- Views can be used as data marts in data warehouse system becuase they provide a flexible and efficient way to present data
-- Data Marts(Virtual Layer): Consists of several views related to the same information such as views regarding sales tables

-- CTAS & Temp Tables
-- DB Table: A table is a structed collection of data, similar to a spreadsheet or grid (Excel)
-- CTAS - CREATE TABLE AS SELECT - Create a new table based on the result of an SQL Query
-- Querying Views is slower than querying CTAS tables
-- CTAS will provide old data but VIEWS will provide updated data in case of Updating Original Table

-- Use Case 1: Optimize Performance
-- When querying, A View logic is always executed each time and then the operational query is run, therefore runtime each time will be high.
-- CTAS: The table will be created once, so that Table query runtime may be high (once) but then operational queries will run faster

-- Create a CTAS (SYNTAX // SQL SERVER)
SELECT
	DATENAME(month,ORDERDATE) OrderMonth,
	COUNT(OrderID) TotalOrders
INTO Sales.MonthlyOrders -- CTAS Syntax For SQL Server
FROM Sales.orders
GROUP BY DATENAME(month,ORDERDATE)

SELECT * FROM Sales.MonthlyOrders
DROP TABLE Sales.MonthlyOrders

-- REFRESH CTAS
-- USE T-SQL
IF OBJECT_ID('Sales.MonthlyOrders','U') IS NOT NULL -- 'U' is table type, in this case, User defined Table 'U'
	DROP TABLE Sales.MonthlyOrders;
GO
-- Create a CTAS (SYNTAX // SQL SERVER)
SELECT
	DATENAME(month,ORDERDATE) OrderMonth,
	COUNT(OrderID) TotalOrders
INTO Sales.MonthlyOrders -- CTAS Syntax For SQL Server
FROM Sales.orders
GROUP BY DATENAME(month,ORDERDATE)

-- Use CASE: Creating a SNAPSHOT of Data at Specific Time
-- This is useful with data marts as the CTAS logic query will run once and not everytime as with the case is with VIEWS

-- Temporary Tables
-- Stores intermediate results in temporary storage within the database during the session
-- The database will drop all temporary tables once the session ends
-- Session: Time between connecting to and disconnecting from the database
-- Can be found in System Databases, tempdb
-- Syntax:
-- INTO #New_table ... '#'
SELECT
*
INTO #Orders
FROM Sales.orders

DELETE FROM #Orders
WHERE OrderStatus = 'Delivered'

SELECT * FROM #ORDERS

-- Save Temp table for permanent use like how normally a table exists
SELECT
*
INTO Sales.TempToPerm
FROM #Orders

SELECT * FROM Sales.TempToPerm

-- USE CASE TEMP-TABLES: Save Intermediate Results in
-- ETL processes: Extract/Transformation (Filtering,Handling NULLs, Remove Duplicates, Aggregations), LOAD

-- Preference in using a project:
-- 1. Views
-- 2. CTE ( dont use more than 5 in one query)
-- 3. Subquery
-- 4. CTAS (if Views are slow)
-- 5. Temp Table

-- STORED PROCEDURES
-- Stored in // Programibility folder // Stored Procedures

-- Step1: Write a Query
-- Write a Query, For US customers, find total number of customers and average score

SELECT
		COUNT(*) TotalCustomersUS,
		AVG(Score) [AVGScore]
FROM Sales.Customers
WHERE COUNTRY = 'USA'

-- Step2: Turning Query into Stored Procedure
CREATE PROCEDURE GetCustomerSummary AS
BEGIN
	SELECT
			COUNT(*) TotalCustomersUS,
			AVG(Score) [AVGScore]
	FROM Sales.Customers
	WHERE COUNTRY = 'USA'
END

-- Step 3: Execute the Stored Procedure
EXEC GetCustomerSummary

-- Parameters (Stored Procedures)
-- Placeholders used to pass values as input from caller to procedure, allowing dynamic data to be processed

-- Task: For German customers, find total number of customers and average score
ALTER PROCEDURE GetCustomerSummary @Country NVARCHAR(50) = 'USA' -- Define Parameter // -- Placeholder
AS
BEGIN
	BEGIN TRY -- Error Handling Try and Catch
		DECLARE @TotalCustomers INT, @AVGScore FLOAT; -- Initiate Variables

		-- ====================
		-- STEP 1: Prepare & Cleanup Data
		-- ====================

		-- Control Flow // Stored Procedure
		-- IF-ELSE
		-- Handling Nulls before aggregating
		-- Condition: Check if there are any Nulls in scores
		-- SELECT 1 FROM Sales.Customers WHERE SCORE IS NULL AND Country = 'USA'
		IF EXISTS (SELECT 1 FROM Sales.Customers WHERE SCORE IS NULL AND Country = @Country)
			BEGIN
				PRINT('Updating NULL Score to 0');
				UPDATE Sales.Customers
				SET Score = 0
				WHERE SCORE IS NULL AND COUNTRY = @COUNTRY;
			END


		ELSE
		BEGIN
			PRINT('No NULL Score Found')
		END;

		-- ====================
		-- STEP 2: Generating Summary Reports
		-- ====================

		-- Calculate Total Customers and Average Score for specific country
			SELECT
					@TotalCustomers = COUNT(*), -- Assign value to variable
					@AVGScore = AVG(Score) -- Assign value to variable
			FROM Sales.Customers
			WHERE COUNTRY = @Country
			GROUP BY Country; -- USE SemiColon when using multiple queries

		-- Variables // Stored Procedure
		-- Placeholders used to store values to be used later in the procedure
		-- Variables temporarily store and manipulate data during its execution
		-- Total Customers from Germany: 2
		-- Average Score from Germany: 425
		PRINT 'Total Customers from ' + @Country + ': ' + CAST(@TotalCustomers AS NVARCHAR); -- Print statements should only have strings so CAST
		PRINT 'Average Score from ' + @Country + ': ' + CAST(@AVGScore AS NVARCHAR); -- Print statements should only have strings so CAST
		-- PRINT STATEMENTS ARE SHOWN IN MESSAGES TAB IN OUTPUT WINDOW

		-- Stored Procedure // Multiple Statements
		-- Calculate the Total Number of Orders and Total Sales for Specific Country 
			SELECT
				COUNT(ORDERID) [TotalOrders],
				SUM(Sales) [TotalSales],
				-- Error Handling // Stored Procedure
				-- TRY - CATCH --
				-- 1/0, -- INTRODUCE ERROR
				c.Country
			FROM Sales.Orders o
			JOIN Sales.Customers c
			ON c.CustomerID = o.CustomerID
			WHERE Country = @Country
			GROUP BY Country;
	END TRY -- Error Handling

	
	BEGIN CATCH -- Error Handling
	-- ==================
	-- Error Handling
	-- ==================
		PRINT('ERROR OCCURED')
		PRINT('ERROR MESSAGE: ' + ERROR_MESSAGE())
		PRINT('ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR))
		PRINT('ERROR LINE: ' + CAST(ERROR_LINE() AS NVARCHAR))
		PRINT('ERROR PROCEDURE: ' + ERROR_PROCEDURE())

	END CATCH -- Error Handling

END

EXEC GetCustomerSummary
EXEC GetCustomerSummary @Country = 'Germany'



-- TRIGGERS
-- Special Stored Procedure (set of statements) that automatically runs in response to a specific event on a table or view.
-- DML TRIGGERS: INSERT // UPDATE // DELETE
-- DDL TRIGGERS: CREATE // ALTER // DROP

-- TRIGGER USE CASE: LOGGING

-- Step 1: Create a Log Table
CREATE TABLE Sales.EmployeeLogs(
	LogID INT IDENTITY(1,1) PRIMARY KEY,
	EmployeeID INT,
	LogMessage VARCHAR(255),
	LogDate DATE
)

CREATE TRIGGER trg_AfterInsertEmployee ON Sales.Employees
AFTER INSERT
AS
BEGIN
	INSERT INTO Sales.EmployeeLogs (EmployeeID, LogMessage, LogDate)
	SELECT
		EmployeeID,
		'New Employee Added = ' + CAST(EmployeeID AS VARCHAR), -- Everything has to be a string
		GETDATE()
	FROM INSERTED -- virtual table that holds a copy of the rows that are being inserted into the target table
END

SELECT * FROM Sales.EmployeeLogs

INSERT INTO Sales.Employees
Values
(6,'Maria','Doe','HR','1988-01-12','F',70000,3)

-- INDEX
-- Data Structure provides quick access to data, optimizing the speed of your queries
-- INDEX TYPES -> STRUCTURE // STORAGE // FUNCTIONS
-- STRUCTURE -> Clustered INDEX // NON-Clustered Index
-- Storage -> Rowstore Index // Columnstore Index
-- Functions -> Unique Index // Filtered Index
-- Trade Off: Some indexes are better for reading, others for writing performance

-- PAGE: The smallest unit of data storage in database (8kb)
-- It stores anything (Data, Metadata, Indexes, etc.)
-- Types: Data Page // Index Page

-- HEAP = Table without Clustered Index // Fast Read, Slow Write
-- Table Full Scan: Scans the entire table page by page and row by row, searching for data.

-- Clustered Index
-- B-Tree (Balance Tree): Hierarchical Structure storing data at leaves, to help quickly locate data.
-- Index Page: It stores key values (Pointers) to another page. It doesn't store the actual rows.
-- Physically sorts and stores rows.
-- One index per Table
-- Faster reading
-- Write Performance is slow due to potential data row reordering
-- More storage efficient
-- USE CASE: Unique Column // Not frequently modified column // improve range query performance

-- Non-Clustered Index
-- A non-clustered index won't reorganize or change anything on the data page.
-- Separate structure with pointers to data
-- Multiple indexes are allowed
-- Slower reading
-- Write Performance is faster since physical data order is unaffected
-- Required additional storage space
-- USE CASE: Columns frequently used in // Search conditions and joins // Exact match queries

-- ANALOGY: Clustered Index -> Table of Contents // Non-Clustered Index -> Index (end of the book)

-- SYNTAX:
-- CREATE [CLUSTERED | NONCLUSTERED (default is nonclustered) ] INDEX index_name ON table_name (col1,col2....) 

-- INFO: A Primary Key (PK) automatically creates a clustered index by default

SELECT * 
INTO Sales.DBCustomers
FROM Sales.Customers

SELECT 
*
FROM Sales.DBCustomers

CREATE CLUSTERED INDEX idx_DBCustomers_CustomerID
ON Sales.DBCustomers (CustomerID)
-- RULE: Only ONE clustered index can be created per Table
CREATE CLUSTERED INDEX idx_DBCustomers_FirstName
ON Sales.DBCustomers (FirstName)

DROP INDEX idx_DBCustomers_CustomerID ON Sales.DBCustomers

SELECT
*
FROM Sales.DBCustomers
WHERE LastName = 'Brown'
-- If the above query is being run again and again, we can create a nonclustered index on it to improve performance.
CREATE NONCLUSTERED INDEX idx_DBCustomers_LastName ON Sales.DBCustomers(LastName)
-- RULE: There can be multiple NONCLUSTERED Index per table
CREATE NONCLUSTERED INDEX idx_DBCustomers_FirstName ON Sales.DBCustomers(FirstName)

-- Composite Index
-- Index that has multiple columns in it
SELECT
*
FROM Sales.DBCustomers
WHERE Country = 'USA' AND Score > 500

CREATE INDEX idx_DBCustomers_CountryScore ON Sales.DBCustomers(Country, Score)
-- Default is NONClustered
-- RULE: Columns of index order must match the order in the query (ORDER IS CRUCIAL)
-- LEFTMOST Prefix RULE: Index works only if your query filters start from the first column in the index and follow its order.
(Country, Score) -- Index
-- Index will be used 
Country
Country, Score
-- Index won't be used
Score
Score, Country 
-- If order is followed, then Index will be used

-- ColumnStore Index
-- The data page stores the values of the One whole column
-- LOB Page: Large Object Page
-- LOB Page: Header, Segment Header, Data Stream (Dictionary and keys)

-- Rowstore Index // ColumnStore Index
-- Organizes and stores data row by row // organizes and stores data column by column
-- Less efficient in storage // Highly Efficient with compression
-- Fair speed for read and write operations // Fast Read Performance, Slow Write Performance
-- Retrieves all columns // Retrieves specific columns
-- BEST FOR: OLTP (Transactional) Commerce, banking, financial systems, order processing // OLAP (Analytical) Data Warehouse, BI, Analytics
-- USE CASE: High frequency transaction applications, Quick access to complete records // Big Data Analytics, Scanning Large Dataset, Fast Aggregaiton

CREATE CLUSTERED COLUMNSTORE INDEX idx_DBCustomers_CS
ON Sales.DBCustomers -- Column is not allowed for Clustered Columnstore

CREATE NONCLUSTERED COLUMNSTORE INDEX idx_DBCustomers_CS_FirstName
ON Sales.DBCustomers (FirstName)
-- ERROR: Multiple columnstore indexes are not supported.
-- This limitation is only with SSMS
-- AZURE allows multiple ColumnStore Indexes

SELECT
COUNT(FirstName) OVER(),
FirstName
FROM Sales.DBCustomers

-- Storage Efficiency (Best to Worst)
-- 1. Columnstore Index
-- 2. Heap Table
-- 3. Rowstore Clustered Index

-- Unique Index
-- Ensures no duplicate values exist in specific column
-- Benefits: Enfore Uniqueness // Slightly increase query performance
-- Performnace: Writing to an unique index is slower than non unique // Reading is faster

SELECT
	*
FROM Sales.Products

CREATE UNIQUE NONCLUSTERED INDEX idx_Products_Category
ON Sales.Products(Category) -- There will be an error because category column contains duplicates
-- RULE: Duplicates in column will prevent creating a unique index
CREATE UNIQUE NONCLUSTERED INDEX idx_Products_Product
ON Sales.Products(Product)

INSERT INTO Sales.Products (PRODUCTID, PRODUCT) Values (106,'Caps') -- Error because caps already exists in column (duplicate)

-- Filtered Index
-- An index that includes only rows meeting the specified conditions
-- Benefits: Targeted Optimization
-- Reduce storage: Less data in the index
-- SQL SERVER is very restricted with filtered index: Cannot create filtered index on clustered OR columnstore index
SELECT * FROM Sales.Customers
WHERE Country = 'USA'

CREATE NONCLUSTERED INDEX idx_Customers_Country -- Unique can be used as well with filtered index
ON Sales.Customers (Country)
WHERE Country = 'USA'

-- WHEN TO USE
-- CHOOSING THE CORRECT INDEX

-- HEAP : FAST INSERTS (For Staging Tables)
-- Clustered Rowstore Index: For Primary Keys(if not, then for date columns) (Note: If PK doesn't exists, then choose a column where sorting is IMP such as Date) (OLTP Systems)
-- ColumnStore Index: For Analytical Queries, Reduce Size of Large Table (OLAP Systems) 
-- Non-Clustered Index: For NON-PK Columns (Foreign Keys, JOINS and Filters)
-- Filtered Index: Target Subset of Data, Reduce Size of Index
-- Unique Index: Enforce Uniqueness (No Duplicates), Improve Query Speed

-- Index Management & Monitoring
-- 1. Monitor Index Usage
-- List all indexes on a specific table
sp_helpindex 'Sales.DBCustomers'
SELECT 
		tbl.name AS TableName,
		idx.name AS INDEXNAME,
		idx.type_desc as INDEXTYPE,
		is_primary_key AS ISPRIMARYKEY,
		is_unique AS ISUNIQUE,
		is_disabled AS ISDISABLED,
		s.user_seeks AS UserSeeks,
		s.user_scans AS UserScans,
		COALESCE(s.last_user_seek,s.last_user_scan) AS LASTUPDATE,
		s.user_lookups AS UserLookups,
		s.user_updates AS UserUpdates

FROM sys.indexes idx
JOIN sys.tables tbl
ON idx.object_id = tbl.object_id
LEFT JOIN sys.dm_db_index_usage_stats s
ON s.object_id = idx.object_id
AND s.index_id = idx.index_id
ORDER BY tbl.name,idx.name
-- Dynamic Management View (DMV): Provides real time insights into database performance and system health
SELECT * FROM sys.dm_db_index_usage_stats

-- Use Index and see the values change in the above query
SELECT * FROM Sales.Products
WHERE Product = 'Caps'

-- TIP: 90% of the indexes created are UNUSED.
-- Always run the index usage query when joining a project and drop unused indexes
-- Benefits: Saved Storage, Improve Write Performance // Optimize the database performance

SELECT * FROM sys.tables

-- 2. Monitor Missing Indexes
SELECT * FROM sys.dm_db_missing_index_details
-- TIP: Evaluate recommendations by the database before creating any index

-- 3. Monitor Duplicate Indexes
SELECT
	tbl.name AS TableName,
	col.name AS IndexColumn,
	idx.name AS IndexName,
	idx.type_desc AS IndexType,
	COUNT(*) OVER (PARTITION BY tbl.name, col.name) ColumnCount
FROM sys.indexes idx
JOIN sys.tables tbl ON idx.object_id = tbl.object_id
JOIN sys.index_columns ic ON idx.object_id = ic.object_id AND idx.index_id = ic.index_id
JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
ORDER BY ColumnCount DESC

-- 4. Update Statistics
SELECT
	SCHEMA_NAME(t.schema_id) AS SchemaName,
	t.name AS TableName,
	s.name AS StatisticName,
	sp.last_updated AS LastUpdate,
	DATEDIFF(day, sp.last_updated, GETDATE()) AS LastUpdateDate,
	sp.rows AS 'Rows',
	sp.modification_counter AS ModificationsSinceLastUpdate
FROM sys.stats AS s
JOIN sys.tables AS t
ON s.object_id = t.object_id
CROSS APPLY sys.dm_db_stats_properties(s.object_id,s.stats_id) AS sp
ORDER BY sp.modification_counter DESC

-- Now update the statistics for table
UPDATE STATISTICS Sales.DBCustomers _WA_Sys_00000003_2739D489
-- Update all statistics for a table
UPDATE STATISTICS Sales.DBCustomers
-- Update statistics for the WHOLE database (may take time)
EXEC sp_updatestats

-- Updating Statistics
-- 1. Weekly job to update statistics on weekends
-- 2. After Migrating Data

-- 5. Monitor Fragmentations
-- Fragmentation: Unused spaces in data pages // data pages are out of order
-- Fragmentation Methods:
-- Reorgranize: Defragments leaf nodes to keep them sorted // "light" operation
-- Rebuild: Recreates index from Scratch // "Heavy Operation"

SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'LIMITED')
-- avg_framentation_in_percent: Indicate how out of order pages are within the index
-- 0% means no fragmentation (perfect)
-- 100% means index is completely fragmented (out of order)

SELECT
	tbl.name AS TableName,
	idx.name AS IndexName,
	s.avg_fragmentation_in_percent,
	s.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'LIMITED') AS s
INNER JOIN sys.tables tbl
ON s.object_id = tbl.object_id
INNER JOIN sys.indexes as idx
ON idx.index_id = s.index_id
ORDER BY s.avg_fragmentation_in_percent DESC

-- WHEN TO DEFRAGMENT?
-- <10% No Action Needed
-- 10 - 30 % Reorganize
-- >30% Rebuild

ALTER INDEX idx_DBCustomers_FirstName ON Sales.DBCustomers REORGANIZE -- Less Time
ALTER INDEX idx_DBCustomers_LastName ON Sales.DBCustomers REBUILD -- More Time

-- EXECUTION PLAN
-- Roadmap generated by a database on how it will execute your query step by step

-- Estimated Execution Plan (in ToolBar): predicts the execution plan without actually running the query
-- Actual Execution Plan (in ToolBar): Shows the execution plan as it occured after running the query
-- Live Execution Plan (in ToolBar): Shows the real-time execution flow as the query runs

-- Estimated Vs Actual Plans
-- If the predictions dont match the actual execution plan
-- this indicates issues like inaccurate statistics or outdated indexes, leading to poor performance.

-- IMP: Execution plan is read from RIGHT TO LEFT
-- Index Scan: Scans all data in an index to find matching rows
-- Sorting Data: Heap is slower than Clustered because database must perform extra work to sort rows
-- TIP: After, creating a new index, Check the execution plan to see if your query uses the index
SELECT * FROM Sales.Customers WHERE Score IS NOT NULL

CREATE NONCLUSTERED INDEX idx_Customer_Score_NC
ON Sales.Customers(Score)

-- Types of Scan:
-- Table Scan: Reads every row in a table.
-- Index Scan: Reads all entries in an index to find results
-- Index Seek: A targeted search within an index, retrieving only specific rows.

-- JOIN Algorithms
-- Nested Loops: Compares tables row by row; best for small tables
-- Hash Match: Matches rows using a hash table; best for large tables
-- Merge Join: Merge two sorted tables; efficient when both are sorted

-- Execution Plan:
-- Understand how SQL executes the query
-- How many resources are being consumed by the query?
-- Check if new indexes are being used.
-- Testing & Experimenting indexes.

-- SQL Hints
-- Commands added to a query to force the database to run it in a specific way
-- for better performance

SELECT
	o.Sales,
	c.Country
FROM Sales.Orders o
LEFT JOIN Sales.Customers c  WITH (INDEX([idx_Customer_Score_NC]))-- <= USE SPECIFIC INDEX -- WITH (FORCESEEK) -- SQL HINT
ON c.CustomerID = o.CustomerID
-- OPTION (HASH JOIN) -- SQL HINT

-- TIPS (SQL HINTS):
-- 1. Test hints in all project environments (DEV,PROD) as performance may vary.
-- 2. Hints are quick fixes (Workaround not Solution). You still have to find the cause and fix it.
-- 3. Use it CAREFULLY.

-- INDEXING STRATEGY
-- THE GOLDEN RULE: AVOID OVER INDEXING (INDEXES SLOW DOWN WRITE PERFORMANCE) (TOO MANY INDEXES CAN CONFUSE EXECUTION PLAN)
-- LESS IS MORE

-- PHASE 1: Initial Index Strategy
-- What is the main goal of our indexing strategy?
-- OLAP: Online Analytical Processing (Example: Data Warehousing: ETL Processes -> Reporting)
-- OLAP Usual GOAL: OPTIMIZE READ Performance // Best Practice: COLUMNSTORE INDEX
-- OTLP: Online Transaction Processing (Example: E-commerce, Financing etc.)
-- OTLP Usual GOAL: OPTIMIZE WRITE Performance // Best Practice: CLUSTERED INDEX Primary Key PK
-- Two Strategies: Optimize READ performance // Optimize WRITE performance

-- PHASE 2: Usage Patterns Indexing
-- 1. Identify frequently used tables // Identify most important columns (USE AI to create a statistical report on Queries)
-- 2. Choose right index
-- 3. Test Index

-- PHASE 3: Scenario-Based Indexing
-- 1. Identify Slow Queries
-- 2. Check Execution Plan
-- 3. Choose the RIGHT index
-- 4. (Test) Compare Execution Plans

-- PHASE 4: Monitoring & Maintenance
-- 1. Monitor Index Usage
-- 2. Monitor Missing Indexes
-- 3. Monitor Duplicate Indexes
-- 4. Update Statistics
-- 5. Monitor Fragmentations
 
 -- SQL PARTITIONING
 -- Divides big table into smaller partitions while still being treated as a single logical table
 -- 1. PARTITION FUNCTION
 -- DEFINE THE LOGIC ON HOW TO DIVIDE DATA INTO PARTITIONS.. BASED ON PRIMARY KEY (USUALLY DATE(YEAR))
 CREATE PARTITION FUNCTION PartitionByYear (DATE)
 AS RANGE LEFT FOR VALUES ('2023-12-31','2024-12-31','2025-12-31')
-- Query lists all existing Partition Function
SELECT
	name,
	function_id,
	type,
	type_desc,
	boundary_value_on_right
FROM sys.partition_functions

-- 2. FILE GROUPS
-- Logical container of one or more data files to help organize partitions
ALTER DATABASE SalesDB ADD FILEGROUP FG_2023;
ALTER DATABASE SalesDB ADD FILEGROUP FG_2024;
ALTER DATABASE SalesDB ADD FILEGROUP FG_2025;

ALTER DATABASE SalesDB REMOVE FILEGROUP FG_2025;

-- Query lists all existing filegroups
SELECT
*
FROM sys.filegroups
WHERE type = 'FG'

-- PRIMARY FILEGROUP : Default filegroup where all objects of database are stored

-- 3. DATA FILES
-- (.ndf) Physical Files where data is stored
-- Add .ndf files to each filegroup
ALTER DATABASE SalesDB ADD FILE
(
	NAME = P_2023, -- Logical Name
	FILENAME = 'C:\Users\Dell - G15\Desktop\sql-ultimate-course\My_WORK\Section 3\src\P_2023.ndf'
) TO FILEGROUP FG_2023
ALTER DATABASE SalesDB ADD FILE
(
	NAME = P_2024, -- Logical Name
	FILENAME = 'C:\Users\Dell - G15\Desktop\sql-ultimate-course\My_WORK\Section 3\src\P_2024.ndf'
) TO FILEGROUP FG_2024
ALTER DATABASE SalesDB ADD FILE
(
	NAME = P_2025, -- Logical Name
	FILENAME = 'C:\Users\Dell - G15\Desktop\sql-ultimate-course\My_WORK\Section 3\src\P_2025.ndf'
) TO FILEGROUP FG_2025

SELECT
	fg.name AS FileGroupName,
	mf.name AS LogicalFileName,
	mf.physical_name AS PhysicalFilePath,
	mf.size / 128 AS SizeInMB
FROM sys.filegroups fg
JOIN sys.master_files mf ON fg.data_space_id = mf.data_space_id
WHERE mf.data_space_id = DB_ID('SalesDB')

-- 4. PARTITION SCHEME
CREATE PARTITION SCHEME SchemePartitionByYear
AS PARTITION PartitionByYear
TO (FG_2023,FG_2024,FG_2025) -- ORDER IS IMPORTANT
-- 3 BOUNDARIES = 4 PARTITIONS = 4 FilesGroups

-- Query Lists all Partition Scheme
SELECT
	ps.name AS PartitionSchemeName,
	pf.name AS PartitionFunctionName,
	ds.destination_id AS PartitionNumber,
	fg.name as FileGroupName
FROM sys.partition_schemes ps
JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
JOIN sys.destination_data_spaces ds ON ps.data_space_id = ds.partition_scheme_id
JOIN sys.filegroups fg ON ds.data_space_id = fg.data_space_id

-- 5. PARTITIONED TABLE
CREATE TABLE Sales.Orders_Partitioned
(
	ORDERID INT,
	ORDERDATE DATE,
	SALES INT
) ON SchemePartitionByYear (ORDERDATE)

-- Insert Data Into Partitioned Table
INSERT INTO Sales.Orders_Partitioned VALUES (1,'2023-05-15',100);
SELECT * FROM Sales.Orders_Partitioned

-- CHECK if the data is being stored in the right partition
SELECT
	p.partition_number AS PartitionNumber,
	f.name AS PartitionFileGroup,
	p.rows AS NumberOfRows
FROM sys.partitions p
JOIN sys.destination_data_spaces dds ON p.partition_number = dds.destination_id
JOIN sys.filegroups f ON dds.data_space_id = f.data_space_id
WHERE OBJECT_NAME(p.object_id) = 'Orders_Partitioned'

-- PERFORMANCE TIPS
-- For small-medium tables, the query optimizer may react similarly to different query styles
-- GOLDEN RULE: Always check the EXECUTION PLAN to confirm performance improvements when optimizing your query.
-- // If there's no improvement, then just focus on readibility.

-- ==============
-- BEST PRACTICES: FETCHING DATA
-- ==============

-- TIP 1: Select Only What is Needed (No unnecessary Columns)
SELECT CustomerID, FirstName FROM Sales.Customers -- Specify columns

-- TIP 2: Avoid Unnecessary DISTINCT & ORDER BY

-- TIP 3: For Exploration Purpose, LIMIT ROWS!!
SELECT TOP 10
	ORDERID,
	SALES
FROM Sales.Orders

-- ==============
-- BEST PRACTICES: FILTERING DATA
-- ==============

-- TIP 4: Create NONCLUSTERED Index on frequently used Columns in WHERE Clause
SELECT * FROM Sales.Orders WHERE OrderStatus = 'Delivered'
CREATE NONCLUSTERED INDEX idx_Orders_OrderStatus ON Sales.Orders(OrderStatus)

-- TIP 5: Avoid Applying Functions To Columns In WHERE Clause
SELECT * FROM Sales.Orders WHERE LOWER(OrderStatus) = 'delivered' -- NOTE: Functions on columns can block index usage
-- BAD PRACTICE
SELECT * FROM Sales.Customers WHERE SUBSTRING(FirstName,1,1) = 'A'
-- GOOD PRACTICE
SELECT * FROM Sales.Customers WHERE FirstName LIKE 'A%'
-- BAD PRACTICE
SELECT * FROM Sales.Orders WHERE YEAR(ORDERDATE) = 2025
-- GOOD PRACTICE
SELECT * FROM Sales.Orders WHERE OrderDate BETWEEN '2025-01-01' AND '2025-12-31'

-- TIP 6: Avoid leading wildcards as they prevent index usage
-- BAD PRACTICE
SELECT * FROM Sales.Customers WHERE LastName LIKE '%Gold%'
-- GOOD PRACTICE
SELECT * FROM Sales.Customers WHERE LastName LIKE 'Gold%'

-- TIP 7: Use IN instead of Multiple OR
-- BAD PRACTICE
SELECT * FROM Sales.Orders WHERE CustomerID = 1 OR CustomerID = 2 OR CustomerID = 3 
-- GOOD PRACTICE
SELECT * FROM Sales.Orders WHERE CustomerID IN (1,2,3)

-- ==============
-- BEST PRACTICES: JOINING DATA
-- ==============

-- TIP 8: Understand the speed of JOINS & USE INNER JOIN when Possible
-- WORST PERFORMANCE
SELECT c.FirstName, o.OrderID FROM Sales.Customers c OUTER JOIN Sales.Orders o ON c.customerID = o.CustomerID
-- BAD PERFORMANCE
SELECT c.FirstName, o.OrderID FROM Sales.Customers c RIGHT JOIN Sales.Orders o ON c.customerID = o.CustomerID
SELECT c.FirstName, o.OrderID FROM Sales.Customers c LEFT JOIN Sales.Orders o ON c.customerID = o.CustomerID
-- BEST PERFORMANCE
SELECT c.FirstName, o.OrderID FROM Sales.Customers c INNER JOIN Sales.Orders o ON c.customerID = o.CustomerID

-- TIP 9: USE Explicit JOIN (ANSI JOIN) Instead of Implicit JOIN (NON ANSI JOIN)
-- BAD PRACTICE
SELECT o.OrderID,c.FirstName
FROM Sales.Customers c, Sales.Orders o
WHERE c.CustomerID = o.CustomerID
-- GOOD PRACTICE
SELECT o.OrderID,c.FirstName
FROM Sales.Customers c
INNER JOIN Sales.Orders o
ON c.CustomerID = o.CustomerID

-- TIP 10: Make sure to Index the columns used in the ON Clause
SELECT o.OrderID,c.FirstName
FROM Sales.Customers c
INNER JOIN Sales.Orders o
ON c.CustomerID = o.CustomerID
CREATE NONCLUSTERED INDEX idx_Customers_CustomerID ON Sales.Customers(CustomerID)
CREATE NONCLUSTERED INDEX idx_Orders_CustomerID ON Sales.Orders(CustomerID)

-- TIP 11: FILTER Before JOINING (Big Tables)
-- Filter After JOIN (WHERE) -- USE THIS FOR Small-Medium Tables
SELECT c.firstname, o.orderid FROM sales.Customers c
INNER JOIN sales.Orders o
ON o.CustomerID = c.CustomerID
WHERE o.OrderStatus = 'Delivered'
-- Filter During JOIN (ON)
SELECT c.firstname, o.orderid FROM sales.Customers c
INNER JOIN sales.Orders o
ON o.CustomerID = c.CustomerID
AND o.OrderStatus = 'Delivered'
-- Filter Before JOIN (Subquery) -- For Large Tables
SELECT c.firstname, o.orderid FROM sales.Customers c
INNER JOIN (SELECT OrderID,CustomerID FROM Sales.Orders WHERE OrderStatus ='Delivered') o
ON c.CustomerID = o.CustomerID
-- TIP: Try to isolate the preparation step in a CTE or Subquery

-- TIP 12: AGGREGATE Before JOINING (Big Tables)
-- Grouping and Joining (SMALL - MEDIUM Tables)
SELECT c.customerID, c.FirstName, COUNT(ORDERID) as OrderCount
FROM sales.customers c
INNER JOIN sales.Orders o
ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName
-- Pre-aggregated Subquery (BIG TABLES)
SELECT c.customerID, c.firstname, o.ordercount
FROM sales.Customers c
INNER JOIN (
			SELECT customerID, COUNT(ORDERID) AS ordercount
			FROM sales.Orders
			GROUP BY CustomerID
			) o
ON c.CustomerID = o.CustomerID
-- Correlated Subquery (WORST PERFORMANCE)
SELECT
	c.customerId,
	c.firstname,
	(SELECT COUNT(o.orderID)
	 FROM sales.Orders o
	 WHERE o.CustomerID = c.customerid) AS OrderCount
FROM Sales.Customers c

-- TIP 13: Use UNION instead of OR while joining tables
-- BAD PRACTICE
SELECT o.orderID,c.FirstName
FROM sales.customers c
INNER JOIN sales.orders o 
ON c.CustomerID = o.CustomerID
OR c.CustomerID = o.SalesPersonID
-- GOOD PRACTICE
SELECT c.firstname, o.orderid
FROM sales.Customers c
INNER JOIN sales.Orders o
ON c.CustomerID = o.customerid
UNION
SELECT c.firstname, o.orderid
FROM sales.Customers c
INNER JOIN sales.Orders o
ON c.CustomerID = o.SalesPersonID

-- TIP 14: Check for Nested Loops and USE SQL Hints
-- BAD PRACTICE
SELECT o.orderid, c.firstname
FROM sales.Customers c
INNER JOIN sales.Orders o
ON c.CustomerID = o.CustomerID
-- GOOD PRACTICE for having BIG and Small Table
SELECT o.orderid, c.firstname
FROM sales.Customers c
INNER JOIN sales.Orders o
ON c.CustomerID = o.CustomerID
OPTION (HASH JOIN)

-- TIP 15: Use UNION ALL instead of using UNION | duplicates are acceptable
-- BAD PRACTICE
SELECT CustomerID FROM Sales.Orders
UNION
SELECT CustomerID FROM Sales.OrdersArchive
-- GOOD PRACTICE
SELECT CustomerID FROM Sales.Orders
UNION ALL
SELECT CustomerID FROM Sales.OrdersArchive

-- TIP 16: Use UNION ALL + DISTINCT instead of using UNION | duplicates are NOT acceptable
-- BAD PRACTICE
SELECT CustomerID FROM Sales.Orders
UNION
SELECT CustomerID FROM Sales.OrdersArchive
-- BEST PRACTICE
SELECT DISTINCT CustomerID 
FROM (
		SELECT CustomerID FROM Sales.Orders
		UNION ALL
		SELECT CustomerID FROM Sales.OrdersArchive
) AS CombinedData

-- ==============
-- BEST PRACTICES: AGGREGATING DATA
-- ==============

-- TIP 17: Use ColumnStore Index for Aggreagtions on Large Tables
SELECT CustomerID, COUNT(ORDERID) AS OrderCount FROM Sales.Orders
GROUP BY CustomerID

CREATE CLUSTERED COLUMNSTORE INDEX idx_Orders_ColumnStore ON Sales.Orders

-- TIP 18: Pre-Aggregate Data and Store it in new Table for Reporting
SELECT MONTH(OrderDate) OrderMonth, SUM(Sales) AS TotalSales 
INTO Sales.SalesSummary
FROM Sales.Orders
GROUP BY MONTH(ORDERDATE)

SELECT OrderMonth, TotalSales FROM Sales.SalesSummary

-- ==============
-- BEST PRACTICES: SUBQUERIES
-- ==============

-- TIP 19: JOIN VS EXISTS VS IN
-- BAD PRACTICE (IN)
SELECT o.OrderID, o.Sales
FROM Sales.Orders o
WHERE o.CustomerID IN (
	SELECT CustomerID
	FROM Sales.Customers
	WHERE Country = 'USA'
)
-- GOOD PRACTICE (JOIN VS EXISTS)
SELECT o.OrderID, o.Sales
FROM Sales.Orders o
WHERE EXISTS (
	SELECT 1
	FROM Sales.Customers c
	WHERE Country = 'USA'
	AND c.CustomerID = o.CustomerID
)

SELECT o.OrderID, o.Sales
FROM Sales.Orders o
INNER JOIN Sales.Customers c
ON c.CustomerID = o.CustomerID
WHERE Country = 'USA'
-- NOTE: IF PERFORMANCE IS EQUAL, USE JOIN FOR BETTER READIBILITY
-- NOTE: USE EXISTS FOR LARGE TABLES AS IT STOPS AT FIRST MATCH AND AVOID DATA DUPLICATION

-- TIP 20: Avoid Redundant Logic in the Query
-- BAD PRACTICE
SELECT EmployeeID, FirstName, 'Above Average' Status
FROM Sales.Employees
WHERE Salary > (SELECT AVG(Salary) FROM Sales.Employees)
UNION ALL
SELECT EmployeeID, FirstName, 'Below Average' Status
FROM Sales.Employees
WHERE Salary < (SELECT AVG(Salary) FROM Sales.Employees)
-- GOOD PRACTICE
SELECT
	EmployeeID,
	FirstName,
	CASE
		WHEN Salary > AVG(Salary) OVER() THEN 'Above Average'
		WHEN Salary < AVG(Salary) OVER() THEN 'Below Average'
		ELSE 'Average'
	END AS Status
FROM Sales.Employees

-- ==============
-- BEST PRACTICES: CREATING TABLES (DDL)
-- ==============

-- TIP 21: Avoid Data Types VARCHAR & TEXT
-- TIP 22: Avoid (MAX) unnecessarily large lengths in data types
-- TIP 23: Use the NOT NULL Constraint where applicable
-- TIP 24: Ensure all tables have a Clustered Primary Key
-- TIP 25: Create a NONCLUSTERED Index for Foreign Keys that are used Frequently
-- BAD PRACTICE
CREATE TABLE CustomersInfo(
	CustomerID INT,
	FirstName VARCHAR(MAX),
	LastName TEXT,
	SCORE VARCHAR(255),
	CONSTRAINT FK_CustomerInfo_EmployeeID FOREIGN KEY (EmployeeID)
		REFERENCES Sales.Employees(EmployeeID)
)
-- GOOD PRACTICE
CREATE TABLE CustomersInfo(
	CustomerID INT PRIMARY KEY CLUSTERED,
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	Country VARCHAR(25) NOT NULL,
	SCORE INT,
	BirthDate DATE,
	EmployeeID INT,
	TotalPurchases FLOAT,
	CONSTRAINT FK_CustomerInfo_EmployeeID FOREIGN KEY (EmployeeID)
		REFERENCES Sales.Employees(EmployeeID)
)

CREATE NONCLUSTERED INDEX idx_Good_Customers_EmployeeID
ON CustomerInfo(EmployeeID)

-- ==============
-- BEST PRACTICES: INDEXING
-- ==============

-- TIP 26: AVOID OVER INDEXING
-- TIP 27: DROP UNUSED INDEXES
-- TIP 28: UPDATE STATISTICS (WEEKLY) 
-- TIP 29: REORGANIZE & REBULD INDEXES (WEEKLY) (DEFRAGMENTATION)
-- TIP 30: PARTITION LARGE TABLES (FACTS) TO IMPROVE PERFORMANCE (Next, Apply a ColumnStore Index for the Best Results)

/*
	1. Focus on Writing CLEAR Queries
	2. Optimize performance only WHEN NECESSARY
	3. Always Test Using EXECUTION PLAN
*/


/* ==============================================================================
   SQL AI Prompts for SQL
-------------------------------------------------------------------------------
   This script contains a series of prompts designed to help both SQL developers 
   and anyone interested in learning SQL improve their skills in writing, 
   optimizing, and understanding SQL queries. The prompts cover a variety of 
   topics, including solving SQL tasks, enhancing query readability, performance 
   optimization, debugging, and interview/exam preparation. Each section provides 
   clear instructions and sample code to facilitate self-learning and practical 
   application in real-world scenarios.

   Table of Contents:
     1. Solve an SQL Task
     2. Improve the Readability
     3. Optimize the Performance Query
     4. Optimize Execution Plan
     5. Debugging
     6. Explain the Result
     7. Styling & Formatting
     8. Documentations & Comments
     9. Improve Database DDL
    10. Generate Test Dataset
    11. Create SQL Course
    12. Understand SQL Concept
    13. Comparing SQL Concepts
    14. SQL Questions with Options
    15. Prepare for a SQL Interview
    16. Prepare for a SQL Exam
=================================================================================
*/

/* ==============================================================================
   1. Solve an SQL Task
=================================================================================

In my SQL Server database, we have two tables:
The first table is `orders` with the following columns: order_id, sales, customer_id, product_id.
The second table is `customers` with the following columns: customer_id, first_name, last_name, country.
Do the following:
	- Write a query to rank customers based on their sales.
	- The result should include the customer's customer_id, full name, country, total sales, and their rank.
	- Include comments but avoid commenting on obvious parts.
	- Write three different versions of the query to achieve this task.
	- Evaluate and explain which version is best in terms of readability and performance
*/

/* ==============================================================================
   2. Improve the Readability
=================================================================================

The following SQL Server query is long and hard to understand. 
Do the following:
	- Improve its readability.
	- Remove any redundancy in the query and consolidate it.
	- Include comments but avoid commenting on obvious parts.	
	- Explain each improvement to understand the reasoning behind it.
*/
-- Bad Formated Query
WITH CTE_Total_Sales_By_Customer AS (
    SELECT 
        c.CustomerID, 
        c.FirstName + ' ' + c.LastName AS FullName,  SUM(o.Sales) AS TotalSales
    FROM  Sales.Customers c
    INNER JOIN 
        Sales.Orders o ON c.CustomerID = o.CustomerID GROUP BY  c.CustomerID, c.FirstName, c.LastName
),CTE_Highest_Order_Product AS (
    SELECT 
        o.CustomerID, 
        p.Product, ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY o.Sales DESC) AS rn
    FROM Sales.Orders o
    INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
),
CTE_Highest_Category AS (  SELECT 
        o.CustomerID,  p.Category, 
        ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY SUM(o.Sales) DESC) AS rn
    FROM Sales.Orders o
    INNER JOIN Sales.Products p ON o.ProductID = p.ProductID GROUP BY  o.CustomerID, p.Category
),
CTE_Last_Order_Date AS (
    SELECT 
        CustomerID, 
        MAX(OrderDate) AS LastOrderDate
    FROM  Sales.Orders
    GROUP BY CustomerID
),
CTE_Total_Discounts_By_Customer AS (
    SELECT o.CustomerID,  SUM(o.Quantity * p.Price * 0.1) AS TotalDiscounts
    FROM  Sales.Orders o INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
    GROUP BY o.CustomerID
)
SELECT 
    ts.CustomerID, ts.FullName,
    ts.TotalSales,hop.Product AS HighestOrderProduct,hc.Category AS HighestCategory,
    lod.LastOrderDate,
    td.TotalDiscounts
FROM CTE_Total_Sales_By_Customer ts
LEFT JOIN (SELECT CustomerID, Product FROM CTE_Highest_Order_Product WHERE rn = 1) hop ON ts.CustomerID = hop.CustomerID
LEFT JOIN (SELECT CustomerID, Category FROM CTE_Highest_Category WHERE rn = 1) hc ON ts.CustomerID = hc.CustomerID
LEFT JOIN CTE_Last_Order_Date lod ON ts.CustomerID = lod.CustomerID
LEFT JOIN  CTE_Total_Discounts_By_Customer td ON ts.CustomerID = td.CustomerID
WHERE  ts.TotalSales > 0
ORDER BY  ts.TotalSales DESC


/* ===========================================================================
   3. Optimize the Performance Query
============================================================================== 

The following SQL Server query is slow. 
Do the following:
	- Propose optimizations to improve its performance.
	- Provide the improved SQL query.
	- Explain each improvement to understand the reasoning behind it.
*/
-- Query with Bar Performance
SELECT 
    o.OrderID,
    o.CustomerID,
    c.FirstName AS CustomerFirstName,
    (SELECT COUNT(o2.OrderID)
     FROM Sales.Orders o2
     WHERE o2.CustomerID = c.CustomerID) AS OrderCount
FROM 
    Sales.Orders o
LEFT JOIN 
    Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE 
    LOWER(o.OrderStatus) = 'delivered'
    OR YEAR(o.OrderDate) = 2025
    OR o.CustomerID =1 OR o.CustomerID =2 OR o.CustomerID =3
    OR o.CustomerID IN (
        SELECT CustomerID
        FROM Sales.Customers
        WHERE Country LIKE '%USA%'
    )
	
/* ===========================================================================
   4. Optimize Execution Plan
============================================================================== 

The image is the execution plan of SQL Server query.
Do the following:
	- Describe the execution plan step by step.
	- Identify performance bottlenecks and issues.
	- Suggest ways to improve performance and optimize the execution plan.
*/

/* ===========================================================================
   5. Debugging
==============================================================================

The following SQL Server Query causing this error: "Msg 8120, Level 16, State 1, Line 5"
Do the following: 
	- Explain the error massage.
	- Find the root cause of the issue.
	- Suggest how to fix it.
*/

SELECT 
    C.CustomerID,
    C.Country,
    SUM(O.Sales) AS TotalSales,
    RANK() OVER (PARTITION BY C.Country ORDER BY O.Sales DESC) AS RankInCountry
FROM Sales.Customers C
LEFT JOIN Sales.Orders O 
ON C.CustomerID = O.CustomerID
GROUP BY C.CustomerID, C.Country

/* ===========================================================================
   6. Explain the Result
============================================================================== 

I didn't understand the result of the following SQL Server query.
Do the following:
	- Break down how SQL processes the query step by step.
	- Explaining each stage and how the result is formed.
*/
WITH Series AS (
	-- Anchor Query
	SELECT
	1 AS MyNumber
	UNION ALL
	-- Recursive Query
	SELECT
	MyNumber + 1
	FROM Series
	WHERE MyNumber < 20
)
-- Main Query
SELECT *
FROM Series

/* ===========================================================================
   7. Styling & Formatting
============================================================================== 

The following SQL Server query hard to understand. 
Do the following:
	Restyle the code to make it easier to read.
	Align column aliases.
	Keep it compact - do not introduce unnecessary new lines.	
	Ensure the formatting follows best practices.
*/
-- Bad Styled Query
with CTE_Total_Sales as 
(Select 
CustomerID, sum(Sales) as TotalSales 
from Sales.Orders 
group by CustomerID),
cte_customer_segments as 
(SELECT CustomerID, 
case when TotalSales > 100 then 'High Value' 
when TotalSales between 50 and 100 then 'Medium Value' 
else 'Low Value' end as CustomerSegment 
from CTE_Total_Sales)
select c.CustomerID, c.FirstName, c.LastName, 
cts.TotalSales, ccs.CustomerSegment 
FROM sales.customers c 
left join CTE_Total_Sales cts 
ON cts.CustomerID = c.CustomerID 
left JOIN cte_customer_segments ccs ON ccs.CustomerID = c.CustomerID

/* ===========================================================================
   8. Documentations & Comments
==============================================================================

The following SQL Server query lacks comments and documentation.
Do the following:
	Insert a leading comment at the start of the query describing its overall purpose.
	Add comments only where clarification is necessary, avoiding obvious statements.
	Create a separate document explaining the business rules implemented by the query.	
	Create another separate document describing how the query works.
*/

WITH CTE_Total_Sales AS 
(
SELECT 
    CustomerID,
    SUM(Sales) AS TotalSales
FROM Sales.Orders 
GROUP BY CustomerID
),
CTE_Customer_Segements AS (
SELECT 
	CustomerID,
	CASE 
		WHEN TotalSales > 100 THEN 'High Value'
		WHEN TotalSales BETWEEN 50 AND 100 THEN 'Medium Value'
		ELSE 'Low Value'
	END CustomerSegment
FROM CTE_Total_Sales
)

SELECT 
c.CustomerID, 
c.FirstName,
c.LastName,
cts.TotalSales,
ccs.CustomerSegment
FROM Sales.Customers c
LEFT JOIN CTE_Total_Sales cts
ON cts.CustomerID = c.CustomerID
LEFT JOIN CTE_Customer_Segements ccs
ON ccs.CustomerID = c.CustomerID 

/* ===========================================================================
   9. Improve Database DDL
============================================================================== 
The following SQL Server DDL Script has to be optimized.
Do the following:
	- Naming: Check the consistency of table/column names, prefixes, standards.
	- Data Types: Ensure data types are appropriate and optimized.
	- Integrity: Verify the integrity of primary keys and foreign keys.	
	- Indexes: Check that indexes are sufficient and avoid redundancy.
	- Normalization: Ensure proper normalization and avoid redundancy.

==============================================================================
   10. Generate Test Dataset
==============================================================================

I need dataset for testing the following SQL Server DDL 
Do the following:
	- Generate test dataset as Insert statements.
	- Dataset should be realstic.
	- Keep the dataset small.	
	- Ensure all primary/foreign key relationships are valid (use matching IDs).
	- Dont introduce any Null values.

==============================================================================
   11. Create SQL Course
============================================================================== 

Create a comprehensive SQL course with a detailed roadmap and agenda.
Do the following:
	- Start with SQL fundamentals and advance to complex topics.
	- Make it beginner-friendly.
	- Include topics relevant to data analytics.	
	- Focus on real-world data analytics use cases and scenarios.

==============================================================================
   12. Understand SQL Concept
==============================================================================

I want detailed explanation about SQL Window Functions.
Do the following:
	- Explain what Window Functions are.
	- Give an analogy.
	- Describe why we need them and when to use them.	
	- Explain the syntax.
	- Provide simple examples.
	- List the top 3 use cases.

==============================================================================
   13. Comparing SQL Concepts
============================================================================== 

I want to understand the differences between SQL Windows and GROUP BY.
Do the following:
	- Explain the key differences between the two concepts.
	- Describe when to use each concept, with examples.
	- Provide the pros and cons of each concept.	
	- Summarize the comparison in a clear side-by-side table.

==============================================================================
   14. SQL Questions with Options
==============================================================================

Act as an SQL trainer and help me practice SQL Window Functions.
Do the following:
	- Make it interactive Practicing, you provide task and give solution.
	- Provide a sample dataset.
	- Give SQL tasks that gradually increase in difficulty.	
	- Act as an SQL Server and show the results of my queries.
	- Review my queries, provide feedback, and suggest improvements.

==============================================================================
   15. Prepare for a SQL Interview
==============================================================================

Act as Interviewer and prepare me for a SQL interview.
Do the following:
	- Ask common SQL interview questions.
	- Make it interactive Practicing, you provide question and give answer.
	- Gradually progress to advanced topics.
	- Evaluate my answer and give me a feedback.	

==============================================================================
   16. Prepare for a SQL Exam
==============================================================================

Prepare me for a SQL exam
Do the following:
	- Ask common SQL interview questions.
	- Make it interactive Practicing, you provide question and give answer.
	- Gradually progress to advanced topics.
	- Evaluate my answer and give me a feedback.