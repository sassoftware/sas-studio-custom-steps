# GeoDistance with Rounding

## Description

The **GeoDistance with Rounding** custom step enables SAS Studio users to calculate the distance between 2 supplied lat/long locations in either kilometers or miles using the SAS proc **geodist**.  It also includes the option to round the result to a specified number of decimal places (0 to 5).

The results are stored in a new column called either "distance_in_Miles" or "distance_in_Kilometers" depending on the distance type option selected.


## User Interface

* ### **Calculate Geo Distance** tab ###

   | Standalone mode | Flow mode |
   | --- | --- |
   | ![](img/Calculate_GeoDist_StandAlone.png) | ![](img/Calculate_GeoDist_Flow.png) |

* ### **Options** tab ###

   | Option checked | Option unchecked |
   | --- | --- |
   ![](img/Calculate_GeoDist_Options_Checked.png) | ![](img/Calculate_GeoDist_Options_Unchecked.png)

* ### **About** tab ###

   ![](img/Calculate_GeoDist_About.png)

## Requirements

* SAS Viya 2020.1.5 or later
* Input contains two latitude/longitude columns for calculation of distance between them


## Usage

![](img/GeoDistWithRounding.gif)

## Change Log

* Version 1.0 (28SEP2022)
    * Initial version
