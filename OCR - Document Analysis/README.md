# OCR - Document Analysis - SAS Custom Steps

## Description

These custom steps are provided to enable point-and-click usage of the functionality available as part of the [SAS Document Analysis](https://www.sas.com/en_us/solutions/ai/models.html) offering from within the SAS Studio interface.

First use the OCR - Document Analysis - Execute Batch OCR Process step in order to turn analysis documents of the following file types: PDF, PNG, JPG, JPEG, TIF, TIFF, BMP & ZIP. After the document analysis has finished you can run the second step OCR - Document Analysis - Produce Usage Report Output to generate a report about the performed analysis.

### Features
- Multiple OCR engines supported (MS & AWS)
- Parallelized batch-based end-to-end execution
- Automated file conversion (between image and PDF formats) 
- Process tracking and entity mapping
- Viya-ready outputs produced
- Usage reporting metrics

## User Interface
* ### OCR - Document Analysis - Execute Batch OCR Process - Options Page ###
![SDA execute OCR batch process options page](img/sda-execute-ocr-batch-process-options-page.png)

* ### OCR - Document Analysis - Produce Usage Report Output - Options Page ###
![SDA produce usage report options page](img/sda-produce-usage-report-options-page.png)

## Requirements

-   SAS Viya 2024.08 or later
-   A license for SAS Document Analysis is required

## Settings

For more information about the different settings please refer to the SAS documentation linked below.

## Documentation
- [SAS Document Analysis documentation](https://go.documentation.sas.com/doc/en/aaimdacdc/default/aaimdawlcm/home.htm)

## Change Log

### OCR - Document Analysis - Execute Batch OCR Process

**Version 1.2 (21NOV2024)** 

* Added option to enable syncronous processing (useful when adding this as an upstream step in a flow and downstream steps need to wait for this step to finish)
* Added option to suppress SSL check (provides the ability to avoid SSL cert errors, see: https://go.documentation.sas.com/doc/en/pgmsascdc/v_057/proc/n154smey890g2xn1l6wljfyjcemh.htm)

**Version 1.1 (09OCT2024)** 

* Implemented feedback

**Version 1.0 (07OCT2024)** 

* Initial version

### OCR - Document Analysis - Produce Usage Report Output

**Version 1.2 (21NOV2024)** 

* Added option to enable syncronous processing (useful when adding this as an upstream step in a flow and downstream steps need to wait for this step to finish)
* Added option to suppress SSL check (provides the ability to avoid SSL cert errors, see: https://go.documentation.sas.com/doc/en/pgmsascdc/v_057/proc/n154smey890g2xn1l6wljfyjcemh.htm)

**Version 1.1 (29OCT2024)** 

* Implemented feedback

**Version 1.0 (07OCT2024)** 

* Initial version
