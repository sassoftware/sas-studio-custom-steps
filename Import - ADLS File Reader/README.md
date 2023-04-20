# ADLS File Reader

## Description

The **Import - ADLS File Reader** provides an easy way to connect and read Parquet and Delta Lake files from Azure Data Lake Storage (ADLS) to SAS Compute or CAS.

It supports reading snappy compressed Parquet and DeltaLake file formats and allows reading from partitioned tables (hierarchical nested subdirectories structures 
commonly used when partitioning the datasest a very common approach when storing datasets on data lakes). 
Its supports expression filters push-down using any of the dataset fields which avoid reading and transferring unnecessary data 
between the origin and source destination (*when used with partitioned fields it's known as partition pruning*)

This custom step helps to work around some of the restrictions that currently exist for working with Parquet files in SAS Viya. Please check the following documentation that lists those restrictions for the latest SAS Viya release:
 - [Restrictions for Parquet File Features for the libname engine](https://go.documentation.sas.com/doc/en/pgmsascdc/default/enghdff/p1pr85ltrpplbtn1h9sog99p4mr5.htm) (SAS Compute Server) 
 - [Azure Data Lake Storage Data Source](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casref/n1ogaeli0qbctqn1e3fx8gz70lkq.htm) (SAS Cloud Analytic Services)
 - [Path-Based Data Source Types and Options](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casref/n0kizq68ojk7vzn1fh3c9eg3jl33.htm#n0cxk3edba75w8n1arx3n0dxtdrt) – which has a footnote for Parquet (SAS Cloud Analytic Services)

Version 2.0 (APR2023)

## User Interface

* ### Options tab ###

   | Standalone mode | Flow mode |
   | --- | --- |                
   | ![](img/ADLS_File_Reader-tabConnectionSettings-standalone.png)  | ![](img/ADLS_File_Reader-tabConnectionSettings-flowmode.png) |

* ### Options tab ###

   ![](img/ADLS_File_Reader-tabOptions-flow.png)

* ### About tab ###

   ![](img/ADLS_File_Reader-tabAbout-flow.png)

## Requirements



This customs step depends on having a python environment configured with the following libraries installed: 
> - pandas
> - saspy
> - azure-identity
> - pyarrow
> - adlfs

Tested on Viya version Stable 2023.03 with python environment version 3.8.13 and the libraries versions:
> - pandas == 1.5.2
> - saspy == 4.3.3
> - azure-identity == 1.12.0
> - pyarrow == 10.0.1
> - adlfs == 2023.1.0

## Usage

![](img/ADLS_File_Reader-Demo.gif)

## Change Log

* Version 1.0 (FEB2023)
    * Initial version
* Version 2.0 (APR2023) 
    * Added support for reading Delta Lake file format 
    * Removed pyarrowfs-adlgen2 python dependency 
    * Added adlfs python library as filesystem library implementation to access ADLS
    * Some code refactoring focusing on a object-oriented implementation for ADLSFileReader 