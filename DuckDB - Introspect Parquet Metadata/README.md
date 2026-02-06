# DuckDB - Introspect Parquet Metadata

## Description
This custom step extracts and outputs metadata from input parquet files. It loads the output to a SAS Cloud Analytics Services (CAS) table for visualization. A future plan is that, based on user parameters, the step modifies parquet reflecting in changed metadata, particularly partitioning information and rowgroups to optimise query performance.  It takes advantage of the SAS/ACCESS Interface to DuckDB and inbuilt functions to work with parquet files.

Open file formats such as Parquet are popular due to the benefits they offer in reduced data footprint and columnar structure.  Also, DuckDB has gained popularity as a performant query processing engine which reduces data movement.  Functions available as part of DuckDB parquet support provide useful tools which assist query engines to use parquet file metadata better.

---
## User Interface

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

- Path to parquet file (folder or file selector, required): select only files on the SAS server (i.e. the filesystem). Based on earlier selection, these correspond to a single parquet file or a folder comprising multiple files.

### Output Specification

- Output table (output port, required): select an output table which holds schema results.  Choose based on your use case, but it's preferred that this belongs to a DuckDB libname. 
---
## Installation & Notes
This step is part of the `sas-studio-custom-steps` collection. Follow the repository instructions in the top-level README to make custom steps available in SAS Studio.

---
## Change Log

- Version: 0.2.1 (05FEB2026)
   - Working Version

- Version: 0.1.0 (04FEB2026)
   - Initial Prototype

---
## Contact
- [Sundaresh Sankaran](mailto:Sundaresh.sankaran@sas.com)
