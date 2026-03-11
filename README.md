# Advanced-SQL-Architecture-And-Performance

![GitHub last commit](https://img.shields.io/github/last-commit/YOUR_USERNAME/YOUR_REPO_NAME?style=flat-square)
![GitHub repo size](https://img.shields.io/github/repo-size/YOUR_USERNAME/YOUR_REPO_NAME?style=flat-square)
![GitHub language count](https://img.shields.io/github/languages/count/YOUR_USERNAME/YOUR_REPO_NAME?style=flat-square)

## Credits 
This project was developed with guidance from *Data with Baraa*. YouTube Channel: [Data with Baraa](https://www.youtube.com/@DataWithBaraa)

##  About the Project
This repository represents the culmination of advanced SQL mastery, focusing on database architecture, programmatic SQL (T-SQL), and query performance tuning. Moving beyond data retrieval, this project explores how to manipulate the database engine for maximum efficiency, handle complex logic through stored procedures and triggers, and design scalable physical storage through indexing and partitioning.

##  Key Concepts & Techniques

### 1. Advanced Query Structures (Subqueries & CTEs)
* **Subqueries:** Implemented Scalar, Row, and Table subqueries across `SELECT`, `WHERE`, and `JOIN` clauses. Mastered the distinction and performance impacts of Non-Correlated vs. Correlated subqueries.
* **Common Table Expressions (CTEs):** Designed standalone, multiple, and nested CTEs to improve query modularity and readability. 
* **Recursive CTEs:** Utilized self-referencing queries with anchor and recursive members to process hierarchical data.

### 2. Database Programmability (T-SQL)
* **Stored Procedures:** Encapsulated complex reporting logic into reusable routines utilizing parameters, variables, and control flow (`IF-ELSE`). Implemented `TRY...CATCH` blocks for robust error handling.
* **Triggers:** Deployed automated DML triggers (`AFTER INSERT`) that execute automatically in response to data modifications.

### 3. Performance Tuning & Indexing Strategy
Understanding physical data storage is critical for optimization:
* **Index Structures:** Differentiated between Heaps and B-Trees, creating Clustered, Non-Clustered, Composite, Unique, and Filtered indexes.
* **Columnstore vs. Rowstore:** Applied Columnstore indexes for OLAP (Analytical) workloads to achieve massive compression and read speed, contrasting with Rowstore for OLTP (Transactional) systems.
* **Maintenance:** Leveraged Dynamic Management Views (DMVs) like `sys.dm_db_index_usage_stats` to monitor missing, unused, or duplicate indexes. Managed fragmentation by updating statistics and deciding when to `REORGANIZE` vs `REBUILD`.

### 4. Execution Plans & Query Best Practices
* Read and analyzed SQL Server Execution Plans (right-to-left) to identify bottlenecks.
* Understood physical join algorithms: Nested Loops, Hash Match, and Merge Joins.
* Applied strict best practices for filtering (SARGability, avoiding functions on indexed columns), joining (filtering before joining for large tables), and aggregating. 

### 5. Database Architecture (Views, CTAS, & Partitioning)
* **Views & CTAS:** Designed virtual tables (Views) for centralized logic and security, and compared them against `CREATE TABLE AS SELECT` (CTAS) and Temporary Tables (`#`) for optimizing ETL performance.
* **Table Partitioning:** Built scalable architectures by dividing massive tables across multiple Data Files (`.ndf`) and Filegroups using Partition Functions and Schemes based on date boundaries.

##  Applied Case Studies

* **Hierarchical Organization Mapping:** Used a Recursive CTE to iterate through an employee table and dynamically generate a leveled organizational chart based on `ManagerID`.
* **Data Marts & Row-Level Security:** Created unified `Views` of complex joins while applying row-level exclusions (e.g., hiding 'USA' region data for EU specific teams).
* **Automated Audit Logging:** Built a DML Trigger that automatically writes to an `EmployeeLogs` table capturing the timestamp and ID every time a new employee is inserted.
* **ETL Load Optimization:** Transitioned from querying slow views to generating Temp Tables and CTAS snapshots to pre-aggregate monthly sales data, vastly reducing dashboard load times.
* **OLAP vs OLTP Indexing:** Applied a Clustered Columnstore Index to large fact tables to speed up aggregations, while utilizing Non-Clustered indexes with specific Leftmost Prefix Rules to optimize transactional lookup speeds.

##  AI for SQL Optimization
This repository also includes a comprehensive library of 16 modular AI Prompts designed to assist developers in debugging, formatting, understanding execution plans, and generating test data via LLMs.

##  Tech Stack
* **Language:** T-SQL (Transact-SQL)
* **Environment:** Microsoft SQL Server / SSMS
* **Core Focus:** Database Architecture, Performance Tuning, Execution Plans, Stored Procedures, Indexing

##  Getting Started
1. Clone the repository:
   ```bash
   git clone [https://github.com/AbdiR0099/Advanced-SQL-Techniques.git](https://github.com/AbdiR0099/Advanced-SQL-Techniques.git)
   
2. Open the .sql scripts in SQL Server Management Studio (SSMS).

3. The scripts are sequential. Ensure you have the dummy database context (USE SalesDB) initialized before running the Stored Procedures, Triggers, or Partitioning logic.
  
