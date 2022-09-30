# GeoDistance with Rounding

## Description

The **GeoDistance with Rounding** custom step enables SAS Studio users to calculate the distance between 2 supplied lat/long locations in either kilometers or miles using the SAS **geodist** data step function.  It also includes the option to round the result to a specified number of decimal places (0 to 5).

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

Copy/paste and run the following SAS code into SAS Studio for sample input data.
```sas
data latlong ;
	length country location $ 50 ;
	infile cards dlm="," ;
	input country $ country_latitude country_longitude location $ location_latitude location_longitude ;
	cards ;
Andorra,42.546245,1.601554,SAS Headquarters,35.824539,-78.755821
United Arab Emirates,23.424076,53.847818,SAS Headquarters,35.824539,-78.755821
Antarctica,-75.250973,-0.071389,SAS Headquarters,35.824539,-78.755821
Argentina,-38.416097,-63.616672,SAS Headquarters,35.824539,-78.755821
American Samoa,-14.270972,-170.132217,SAS Headquarters,35.824539,-78.755821
Bermuda,32.321384,-64.75737,SAS Headquarters,35.824539,-78.755821
Belize,17.189877,-88.49765,SAS Headquarters,35.824539,-78.755821
Canada,56.130366,-106.346771,SAS Headquarters,35.824539,-78.755821
Switzerland,46.818188,8.227512,SAS Headquarters,35.824539,-78.755821
Côte d'Ivoire,7.539989,-5.54708,SAS Headquarters,35.824539,-78.755821
Finland,61.92411,25.748151,SAS Headquarters,35.824539,-78.755821
Fiji,-16.578193,179.414413,SAS Headquarters,35.824539,-78.755821
Falkland Islands [Islas Malvinas],-51.796253,-59.523613,SAS Headquarters,35.824539,-78.755821
Guernsey,49.465691,-2.585278,SAS Headquarters,35.824539,-78.755821
Honduras,15.199999,-86.241905,SAS Headquarters,35.824539,-78.755821
Croatia,45.1,15.2,SAS Headquarters,35.824539,-78.755821
Kyrgyzstan,41.20438,74.766098,SAS Headquarters,35.824539,-78.755821
Cambodia,12.565679,104.990963,SAS Headquarters,35.824539,-78.755821
Luxembourg,49.815273,6.129583,SAS Headquarters,35.824539,-78.755821
Latvia,56.879635,24.603189,SAS Headquarters,35.824539,-78.755821
Malta,35.937496,14.375416,SAS Headquarters,35.824539,-78.755821
Mauritius,-20.348404,57.552152,SAS Headquarters,35.824539,-78.755821
Maldives,3.202778,73.22068,SAS Headquarters,35.824539,-78.755821
New Zealand,-40.900557,174.885971,SAS Headquarters,35.824539,-78.755821
Oman,21.512583,55.923255,SAS Headquarters,35.824539,-78.755821
Puerto Rico,18.220833,-66.590149,SAS Headquarters,35.824539,-78.755821
Palestinian Territories,31.952162,35.233154,SAS Headquarters,35.824539,-78.755821
Portugal,39.399872,-8.224454,SAS Headquarters,35.824539,-78.755821
Palau,7.51498,134.58252,SAS Headquarters,35.824539,-78.755821
Qatar,25.354826,51.183884,SAS Headquarters,35.824539,-78.755821
Réunion,-21.115141,55.536384,SAS Headquarters,35.824539,-78.755821
São Tomé and Príncipe,0.18636,6.613081,SAS Headquarters,35.824539,-78.755821
El Salvador,13.794185,-88.89653,SAS Headquarters,35.824539,-78.755821
Uruguay,-32.522779,-55.765835,SAS Headquarters,35.824539,-78.755821
Uzbekistan,41.377491,64.585262,SAS Headquarters,35.824539,-78.755821
Vatican City,41.902916,12.453389,SAS Headquarters,35.824539,-78.755821
Zimbabwe,-19.015438,29.154857,SAS Headquarters,35.824539,-78.755821
;
```

## Change Log

* Version 1.0 (28SEP2022)
    * Initial version
