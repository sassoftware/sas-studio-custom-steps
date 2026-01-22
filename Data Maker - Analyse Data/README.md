# Data Maker - Analyse Data

## Description
This custom step analyses parquet files and writes results to an output dataset.  The output is expected to help drive data configuration decisions in [SAS Data Maker](https://www.sas.com/en_us/software/data-maker.html), a focussed application for synthetic data generation.  The program in this step uses the [SAS/Access Interface to DuckDB](https://go.documentation.sas.com/doc/en/pgmsascdc/default/acwn/p1ozr0t2ly4bc2n0zxncjtshlyor.htm), a standard component available with SAS Viya, to take advantage of DuckDB's performant capabilities in processing Parquet. 

This step can be viewed both as a general purpose "data profiler" or as a specific tool to ease data preparation prior to data ingestion in Data Maker.  Data Maker, being a focussed tool, provides some summary statistics to help inform the user.  This step endeavours to provide the same statistics at an earlier stage in the Analytics Life Cycle, helping improve first-pass yield by allowing data generators to take adequate and appropriate steps for data preparation and transformation.

## User Interface
See the step's **About** tab in SAS Studio for contextual help. The Parameters tab prompts for the inputs required to build the aggregation SQL automatically.

A video showing a quick walkthrough of this step: [here](https://youtu.be/5ZjB7BN1EAI)

A wiki of this repo has been generated using DeepWiki and is available here: [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/SundareshSankaran/Data-Maker-Analyse-Data)

### Parameters
- **Parquet file path (file selector, required):** based on a radio button select either a single Parquet file or a folder containing multiple Parquet files on the SAS server filesystem.
- **Output table (output port / libname-qualified preferred, required):** destination table for the aggregated results

## Requirements
- SAS Viya environment with SAS Studio flows
- SAS/ACCESS Interface to DuckDB configured on the compute server. Note that SAS supports DuckDB from version 2025.07 onwards.
- Parquet files accessible from the SAS compute server filesystem


## Usage
1. Select either a single Parquet file or provide the directory/prefix for a set of Parquet files.
2. Provide an output table name (logical name used in the generated SQL).
3. Run the step

The step will build DuckDB-compliant SQL and execute it via explicit passthrough to DuckDB, producing the aggregated output table.

## Installation & Notes
This step is available as an individual repo and might also form part of the `sas-studio-custom-steps` collection. Follow these [instructions](https://github.com/sassoftware/sas-studio-custom-steps/blob/main/docs/IMPORT_CUSTOM_STEP.md) to make custom steps available in SAS Studio.

## Version
Version: 0.1.0 (22JAN2026)

## Contact
Sundaresh Sankaran (Sundaresh.sankaran@sas.com)
