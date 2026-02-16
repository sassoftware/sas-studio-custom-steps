# DuckDB - Introspect Parquet Metadata

## Description
This custom step extracts and outputs metadata from input parquet files. It also gives you an option to load this output to SAS Cloud Analytics Services (CAS) table for visualisation. Further, based on user-specified parameters, the step can write parquet files reflecting changed metadata, particularly partitioning information and rowgroups that optimise query performance.  It takes advantage of the SAS/ACCESS Interface to DuckDB and inbuilt functions to work with parquet files.

Open file formats such as parquet are popular due to benefits they offer in reduced data footprint and columnar structure.  Also, DuckDB is a popular and performant query processing engine that reduces data movement.  DuckDB Parquet functions are useful tools that assist query engines to use parquet file metadata better.

---
## User Interface

(Watch out for a more detailed walkthrough soon.)

![Feast Your Eyes](./img/parquet-introspect-metadata-holding-screenshot.png)


---
## Requirements
- SAS Viya environment with SAS Studio flows (step tested on version 2026.01)
- SAS/ACCESS Interface to DuckDB configured on the compute server. Note that SAS supports DuckDB from version 2025.07 onwards.
---
## Usage

Configure the parameters as needed in the Parameters tab and run the step.

---
## Parameters

### Input Parameters

- Path to parquet file(file selector, required): select only files on the SAS server (i.e. the filesystem). Based on earlier selection, this could be a single parquet file or a folder comprising multiple files.

### Output Specification

1. Output table (output port, required): select an output table to hold schema results.  
2. Load to CAS (checkbox, optional): if checked, the output table is loaded to CAS for visualisation. The default table is PARQUET_METADATA in PUBLIC caslib (can be changed by user).

### Parquet Writer Options
1. Select whether you want to write to a new parquet file with new metadata options (you will be able to overwrite existing file if you give the same name).
2. Order By Columns (text field):  Parquet rowgroups and metadata provide best value when planned in alignment with commonly queried columns.  Specify an Order By clause (without the \"ORDER BY\") in comma-separated form listing columns that you would like the new table to be ordered by.
3. Parquet writer options (option table): Change options for the new file if you wish. A limited set of options are offered as parquet writer options are numerous and differ based on DuckDB version.

---
## Installation & Notes
This step is part of the `sas-studio-custom-steps` collection. Follow the repository instructions in the top-level README to make custom steps available in SAS Studio.

---
## Change Log

- Version: 0.5.0 (15FEB2026)
   - Version submitted to GitHub

- Version: 0.1.0 (04FEB2026)
   - Initial Prototype

---
## Contact
- [Sundaresh Sankaran](mailto:Sundaresh.sankaran@sas.com)
