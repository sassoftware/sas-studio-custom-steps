# GCSFS File Writer

## Description

The **Export - GCSFS File Writer** custom step provides an easy way to write SAS and CAS Datasets to Google Cloud Storage (GCS) in Parquet and Deltalake format.

It supports writing compressed Parquet and Deltalake files using the snappy compression to reduce storage requirements.
It also supports writing partitioned Parquet and Deltalake datasets based in a particular column or set of columns. This allows for more efficient querying and processing of large datasets, as only the relevant partitions need to be accessed. 
To control how to handle data that already exists in the destination the field **Existing data behavior** is provided with the following configuration alternatives:
Parquet:
 - **overwrite_or_ignore**: will ignore any existing data and will overwrite files with the same name as an output file. Other existing files will be ignored. This behavior, in combination with a unique basename_template for each write, will allow for an append workflow.
 - **error**: will raise an error if any data exists in the destination.
 - **delete_matching**: is useful when you are writing a partitioned dataset. The first time each partition directory is encountered the entire directory will be deleted. This allows you to overwrite old partitions completely. 
Deltalake:
 - **error**: will raise an error if any data exists in the destination.
 - **append**: will add new data.
 - **overwrite**: will replace table with new data. 
 - **ignore**: will not write anything if table already exists.

This custom step helps to work around some of the restrictions that currently exist for working with Parquet files in SAS Viya. Please check the following documentation that lists those restrictions for the latest SAS Viya release:
 - [Restrictions for Parquet File Features for the libname engine](https://go.documentation.sas.com/doc/en/pgmsascdc/default/enghdff/p1pr85ltrpplbtn1h9sog99p4mr5.htm) (SAS Compute Server)
 - [Google Cloud Storage Data Source](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casref/n0onac2l37evxtn1dmi3zsc5z452.htm) (SAS Cloud Analytic Services)
 - [Path-Based Data Source Types and Options](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casref/n0kizq68ojk7vzn1fh3c9eg3jl33.htm#n0cxk3edba75w8n1arx3n0dxtdrt) – which has a footnote for Parquet (SAS Cloud Analytic Services)

## User Interface

* ### Connection settings tab ###

   | Standalone mode | Flow mode |
   |-----------| --- |                
   | ![](img/GCSFS_File_Writer-tabConnectionSettings-standalone.png) | ![](img/GCSFS_File_Writer-tabConnectionSettings-flowmode.png) |

* ### Options tab ###

   ![](img/GCSFS_File_Writer-tabOptions-flowmode.png)

* ### About tab ###

   ![](img/GCSFS_File_Writer-tabAbout-flowmode.png)

## Requirements

This custom step depends on having a python environment configured with some additional libraries installed: 
> - gcsfs
> - cloud-arrow
> - deltalake
> - pandas
> - pyarrow
> - saspy

It has been tested on SAS Viya version Stable 2023.11 with python version 3.9.16 and the following libraries versions:

> - gcsfs==2023.10.0
> - cloud-arrow == 0.3.0
> - deltalake==0.14.0
> - pandas==1.5.3
> - pyarrow==14.0.1
> - saspy==5.4.4     

## Usage

![](img/GCSFS_File_Writer-Demo.gif)

## Change Log

* Version 1.0 (15DEC2023) 
    * Initial version