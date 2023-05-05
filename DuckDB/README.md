# DuckDB

## Description

The **DuckDB** step enables you to use DuckDB, a column-oriented OLAP database, to access data.
In this version following data sources are supported:
-	Parquet
-	CSV files
-	Postgres

The step supports SQL as explained in the [DuckDB documentation](https://duckdb.org/docs/sql/introduction).

## User Interface
* ### SQL tab ###
In the tab SQL you can submit one or more SQL statements.
   | Standalone mode | Flow mode |
   | --- | --- |                  
   | ![](img/DuckDB-SQL-SA.jpg) | ![](img/DuckDB-SQL-FL.jpg) |
   
   | UI Field | Comment |
   | --- | --- |
   | Ignore file options | When ticked:<br> - All options set in tab *Parquet* and *CSV* will be ignored.<br> - SQL will be sent *as is* to DuckDB.<br> - You can use SQL with DuckDB functions. E.g.:<br>```SELECT * FROM read_parquet('test.parq');``` |
   | SQL statement | Field for SQL statement.<br>For allowed SQL syntax see [DuckDB documentation](https://duckdb.org/docs/sql/introduction)<br>You can submit several SQL statements in this field.<br>SQL statements need to delimited with a semicolon (;) when submitting more than one statement.<br>Example - Load table into DuckDB:<br>`CREATE SCHEMA IF NOT EXISTS asd;`<br>`CREATE TABLE taxi as (`<br>`SELECT * FROM mytaxidata.csv);`|
* ### DuckDb Optios tab ###
In this tab you can set general options for DuckDB.
   | DuckDB Options |
   | --- |
   | ![](img/DuckDB-Options-SA.jpg) |

   

