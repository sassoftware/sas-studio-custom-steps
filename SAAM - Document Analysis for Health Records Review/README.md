# SAAM - Document Analysis for Health Records Review

## Description

SAS Studio Custom Step for executing the SAS Document Analysis Health Records Review information extraction process. This custom step is provided to enable point-and-click usage of the functionality available as part of the [Health Records Review](https://www.sas.com/en_us/solutions/ai/models.html) offering from within the SAS Studio interface.

## Required Inputs

At a minimum, user must specify the following to execute this custom step:

  - a folder / directory containing either the SAS or SDA file to be processed,
  - an output folder / directory to export results,
  - a desired file type format for the exported results,
  - a folder / directory containing model astore files and
  - a folder / directory containing SAS macro catalog

The source directory should be located on the server file system (not in SAS Content). 

If using SAS as the input source, the following file extensions are supported: [sas7bdat, sashdat]. If using the mapping output from the upstream SDA OCR process, the following file types are supported: [csv, xlsx].

## User Interface

* ### SAAM - Document Analysis for Health Records Review - Options Page - Main Inputs ###

   ![](img/saam_document_analysis_health_records_review_information_extraction_options_1.png)

* ### SAAM - Document Analysis for Health Records Review - Options Page - Additional Inputs (Optional) ###

   ![](img/saam_document_analysis_health_records_review_information_extraction_options_2.png)

## Pre-requisites
 
-   SAS Viya 2025.12 or later 
-   A license for SAS Document Analysis is required

## Settings

For more information about the different settings please refer to the SAS documentation linked below.

## Documentation

- [SAS Document Analysis documentation](https://go.documentation.sas.com/doc/en/aaimdacdc/default/aaimdawlcm/home.htm)

## Change Log

### SAAM - Document Analysis for Health Records Review

* Version 1.3 (23JAN2026)
-----------------------------

  * Updated Program code with code fixes

* Version 1.2 (21JAN2026)

  * Updated the Program code with few code fixes

* Version 1.1 (14JAN2026)

  * Updated the Options page with additional required parameters for the user to populate to execute the step
  * Updated the About page with more description explaining the usage of the step
  * Updated logic to handle conflicts with output libref name 
  * Added cleanup code towards the end of completion of the step to delete macro variables that were created by the step
  * Updated the UI field names and column names to use proper casing and end of line punctuation (: or ?)

* Version 1.0 (08DEC2025)

  * Initial version

