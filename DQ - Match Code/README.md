# DQ - Match Code

## Description

The **DQ - Match Code** step allows you to create a column match code based on locale and rule definition using a **dqMatch** function in the SAS Compute Server. This version supports 7 Locales (ENCAN, ENUSA, FRCAN, FRFRA, DEDEU, ITITA and ESESP) and allows to generate match code for up to 5 columns.  

## User Interface  

* ### MatchCode Options tab ###

   | Standalone mode | Flow mode |
   | --- | --- |                  
   | ![](img/dqmatch-tabmatchcodeoptions-standalone.png) | ![](img/dqmatch-tabmatchcodeoptions-flowmode.png) |
   
   * This applies to MatchCode1 … MatchCode5

1. **Select Column**   - Defines the column to be used to compute match code.  
2. **Match Column**    - Specify name of output column to contain generated match code. If left empty, a new column will be created using name of input column suffixed with **_MC**.      
3. **Locale**          - Define Locale to be used to compute match code.  
4. **Definition**      - Define the rule to be used to compute match code.  
5. **Sensitivity**     - Define the Sensitivity used to compute match code.  

## Requirements

2021.1.1 or later  

* This custom step requires a SAS Quality Knowledge Base (QKB) to be installed and configured. More details can be found in the documentation that is available [here](https://support.sas.com/en/software/quality-knowledge-base-support.html)  

## Usage

![Using the DQ - Match Code Custom Step](img/dqmatch.gif)  

## Change Log

Version 1.2 (22NOV2022)  

  * Adds support for English - Canada (ENCAN) and French - Canada (FRCAN) locales

Version 1.1 (22SEP2022)  

  * Fixes execution errors when using a locale other than English - United States (ENUSA) 

Version 1.0 (14SEP2022)  

  * Initial version  
  
 

	
