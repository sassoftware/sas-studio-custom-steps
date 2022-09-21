# DQ - Standardize

## Description

The **DQ - Standardize** step allow you to create a standardized column code based on locale and rule definition using a **dqStandardize** function in the SAS Compute Server. This version supports 5 Locales (ITITA, ENUSA, FRFRA, DEDEU and ESESP) and allows to standardize up to 5 columns. It's worthwhile to note that the DQ Standardize step also allows to mask data when using the data masking standardization definitions that have become available since [SAS Quality Knowledge Base for Contact Information](https://support.sas.com/en/software/quality-knowledge-base-support.html#documentation)       


## User Interface  

* ### Standardize Options tab ###

   | Standalone mode | Flow mode |
   | --- | --- |                  
   | ![](img/dqstandardize-tabstandardizeoptions-standalone.png) | ![](img/dqstandardize-tabstandardizeoptions-flowmode.png) |

1. **Select Column** - Defines column to be standardized.  
2. **Standardized column** - Specify name of output column to contain standardized value.If left empty, a new column will be created using name of input column suffixed with **_STD**.  
3. **Locale**          - Define Locale to be used to compute standardized column.  
4. **Definition**      - Define the rule to be used to compute standardized column.  

## Requirements  

2021.1.1 or later  

* This custom step requires a SAS Quality Knowledge Base (QKB) to be installed and configured. More details can be found in the documentation that is available [here](https://support.sas.com/en/software/quality-knowledge-base-support.html)  


## Usage  

![Using the DQ - Standardize Custom Step](img/dqstandardize.gif)

## Change Log  

* Version 1.0 (14SEP2022)
    * Initial version 