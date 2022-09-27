# Anonymize and Mask Data

## Description

The **Anonymize and Mask Data** custom step enables SAS Studio users to select a standardization definition from the [SAS Quality Knowledge Base (QKB)](https://support.sas.com/en/software/quality-knowledge-base-support.html#documentation) to mask or anonymize data in a selected column.  [This blog](https://communities.sas.com/t5/SAS-Communities-Library/Viya-2020-1-5-April-2021-Introducing-Custom-Steps-in-SAS-Studio/ta-p/744463) describes the creation of this custom step.  Note: The *Masked column name* control and the *About* tab was added after this blog was written.

Note: This custom step is related to the [DQ - Standardize](https://github.com/sassoftware/sas-studio-custom-steps/tree/main/DQStandardize) custom step.

## User Interface

* ### **Anonymize and Mask Data** tab ###

   | Standalone mode | Flow mode |
   | --- | --- |
   | ![](img/Anonymize_and_Mask_Data_StandAlone.png) | ![](img/Anonymize_and_Mask_Data_Flow.png) |
* ### **About** tab ###

   ![](img/Anonymize_and_Mask_Data_About.png)
## Requirements

* SAS Viya 2020.1.5 or later
* SAS Quality Knowledge Base for Contact Information version 32 or later


## Usage

![](img/AnonymizeMaskData.gif)

## Change Log

* Version 1.1 (27SEP2022)
    * Made New Column control required
* Version 1.0 (15SEP2022)
    * Initial version
