# DuckDB - Aggregate Parquets

## Description
This custom step dynamically builds a DuckDB SQL aggregation query against Parquet files and pushes the query down to DuckDB via the SAS/ACCESS Interface to DuckDB. It lets users run one or more aggregations over Parquet data without manually writing DuckDB SQL, reducing data movement and taking advantage of DuckDB's columnar performance. This step explicitly pushes down the query to avoid making a copy which might happen in case of implicit reference.

## User Interface
See the step's **About** tab in SAS Studio for contextual help. The Parameters tab prompts for the inputs required to build the aggregation SQL automatically.

Watch this [video](https://www.youtube.com/watch?v=sgV-4xgusKY) for a simple demo. 

Read this [article](https://communities.sas.com/t5/SAS-Communities-Library/Performant-Aggregations-on-Parquet-using-DuckDB/ta-p/981117) to learn more.

A detailed wiki of this page is available [here](https://deepwiki.com/SundareshSankaran/duckdb-parquet-aggregations): [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/SundareshSankaran/duckdb-parquet-aggregations)

### Parameters
- **Parquet file path (file selector, required):** select a Parquet file on the SAS server filesystem.
- **Aggregation functions (list, required):** choose one or more aggregation functions (e.g., AVG, SUM, COUNT, STDDEV, STDDEV_POP).
- **List columns to aggregate (space-separated, required):** columns to apply the aggregation functions to.
- **Group-by columns (space-separated, optional):** optional columns to group the aggregations by.
- **WHERE clause (text field, optional):** to filter the parquet data before aggregation.  Note that the WHERE keyword is added automatically and if provided, will be used as is.
- **Output table (output port / libname-qualified preferred, required):** destination table for the aggregated results; prefer a DuckDB-backed library name.

## Requirements
- SAS Viya environment with SAS Studio flows
- SAS/ACCESS Interface to DuckDB configured on the compute server. Note that SAS supports DuckDB from version 2025.07 onwards.
- Parquet files accessible from the SAS compute server filesystem


### Future Work
There are pros and cons to any approach.  Keeping the scope of this step in mind, and since it 'generates' DuckDB SQL dialect for explicit passthrough on the fly, we may not be able to cover all syntactic and functional patterns. Some known items slated to be addressed in a future version are:

1. Support for column names with spaces in them (note that version 1.2.5 onwards makes significant progress by handling hyphens in column names and also preventing hyphens from getting considered as operators)
2. Aggregation functions with multiple parameters

This custom step does **not** have the ambition to evolve into a full-fledged translator to DuckDB SQL (though it will be nice if it can).


## Usage
1. Select the Parquet file or provide the directory/prefix for the Parquet files.
2. Provide a table name (logical name used in the generated SQL).
3. Select aggregation functions and list the target columns.
4. (Optional) Provide group-by columns.
5. (Optional) Provide a WHERE clause to filter the parquet data before aggregation.  Note that the WHERE keyword is added automatically and if provided, will be used as is.
6. Choose an output table (preferably a DuckDB library-backed table) and run the step.

The step will build DuckDB-compliant SQL and execute it via explicit passthrough to DuckDB, producing the aggregated output table.

## Installation & Notes
This step is part of the `sas-studio-custom-steps` collection. Follow the repository instructions in the top-level README to make custom steps available in SAS Studio.

## Version
Version: 1.3.5 (10JAN2026)

## Contact
Sundaresh Sankaran (Sundaresh.sankaran@sas.com)
