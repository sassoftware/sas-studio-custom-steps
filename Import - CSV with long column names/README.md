# Import - CSV with long column names

## Description

The **Import - CSV with long column names** custom step provides an easy way to import a CSV (or any other delimited file) with column names longer than 32 characters. It will abbreviate column names in the first row of the CSV so they adhere to 32-char restrictions, and then generate label statements with the original long column name.

## User Interface

* ### Options tab ###

   | Standalone mode | Flow mode |
   |-----------| --- |                
   | ![](img/Import_csv_labels-tabOptions-standalone.png) | ![](img/Import_csv_labels-tabOptions-flowmode.png) |

* ### About tab ###

   ![](img/Import_csv_labels-tabAbout-flowmode.png)

## Requirements

This custom step has been tested on SAS Viya version Stable 2023.11.

## Usage

![](img/Import_csv_labels-Demo.gif)

## Change Log

* Version 1.0 (21DEC2023) 
    * Initial version