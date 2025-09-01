# DQ - Parsing

## Description

>**Note**: The **Parse Data** step in the **Data Quality** group in the Steps pane in SAS Studio, introduced in release 2024.01, provides the same functionality, and it is highly recommended to use that step going forward.

The **DQ - Parsing** step allows you to parse a column by dividing a string into a set of tokens. When a parse definition is applied to a data string, the string is analysed and split into substrings that are assigned to the output tokens. For example: Mr. Bob Brauer [Mr. = Prefix, Bob = Given Name, Brauer = Family Name]. 

The QKB parse definition uses a vocabulary to identify the basic categories for each word or character. The patterns constructed from the categories of those words or characters are then compared with rules in the grammar. If the system finds a rule that captures these patterns, a solution is produced.

Parse definitions are useful when you want to break data strings into substrings to better organize your data source, or if you want to perform analytics on specific elements of strings in a table.

  * The step will add a column for each result token to the tables prefixed with **T_**.
  * You can parse one column in this step.
  * If both the input table and the output table are in CAS then the step will run in CAS, otherwise it will run in the SAS Compute Server.  
  * This version supports the following locales: ENUSA, ENGBR, FRFRA, DEDEU, ITITA and ESESP
  * For information about parsing tokens search the QKB documentation for “Definitions by Locale/Parse Definitions”: [SAS Quality Knowledge Base for Contact Information](https://support.sas.com/documentation/onlinedoc/qkb/32/QKBCI32/Help/qkb-help.html)

>**Note**: The **Parse Data** step in the **Data Quality** group in the **Steps** pane in SAS Studio, introduced in release 2024.01, provides similar functionality, 
and it is highly recommended to use that step going forward when possible.

## User Interface  

* ### Parsing Options tab ###

   | Standalone mode | Flow mode |
   | --- | --- |                  
   | ![](img/dqParsing_Standalone.png) | ![](img/dqParsing_Flow.png) |
1. **Locale** - Set Locale to be used to in ths step to parse column values.  
2. **Select column** - Select column from input table to be parsed.  
3. **Definition** - Set Parsing Definition to be used to parse the value of the selected input column. 

## Requirements  
2023.01 or later  
* This custom step requires a SAS Quality Knowledge Base (QKB) to be installed and configured. More details can be found in the documentation that is available [here](https://support.sas.com/en/software/quality-knowledge-base-support.html) 

## Usage  
![Using the DQ - Parsing Step](img/dqParsing.gif)

Copy/paste and run the following SAS code into SAS Studio for sample input data.
```sas
data ADDRESS;
    length ADDRESS $100;
    infile cards dlm="," ;
    input ADDRESS $;
    cards;
1 ARGOED AVENUE NEW BRIGHTON
1 BEECH ROAD CHANDLER'S FORD
1 BLUEBELL CLOSE BOUGHTON VALE
1 BRICKINGS WAY STURTON-LE-STEEPLE
1 FIELD WAY DEBENHAM
1 GRIMSON CLOSE SULLY
1 HILL LEYS
1 NEVILLE CRESCENT KENDRAY
1 PARK FARM THE STREET
1 ST JOHNS CLOSE DODWORTH
1 SUMMERFIELD DRIVE ASTLEY TYLDESLEY
1 Tintern House Augustus Street
1 UPPER MILL EAST MALLING
1 WESTBY CLOSE RAVENFIELD
1 WILBY CARR GARDENS
1 Y RLSFF MORFA BYCHAN
10 ACTON ROAD BURTONWOOD
10 ADDINGTON PLACE PALMERSTON AVENUE
12 WOODEND COTTAGES DALMELLINGTON ROAD
120 FERNEY ROAD EAST BARNET
121 PETERSFIELD ROAD HALL GREEN
123 STATION ROAD GLENFIELD
125 MILWARD ROAD LOSCOE
128 COMMERCIAL STREET ABERBARGOED
128 CURWENDALE STAINBURN
12B ROTTON ROW RAUNDS
13 ASPEN WAY CRINGLEFORD
13 Balmossie Avenue Monifieth
13 GROSVENOR ROAD HOUNSLOW
13 PINEWOOD ROAD BRANKSOME PARK
13 PRESCOTT DRIVE PENKRIDGE
13 SOUTHWAYS STUBBINGTON
13 SPRINGFIELD AVENUE HONLEY
13 ST HUBERTS HOUSE JANET STREET
133 THE AVENUE SEAHAM
134 MARSDEN ROAD BURNLEY
14 ASHFORD ROAD MEOLS THE WIRRAL
14 BELVIDERE ROAD CULTS
14 FAIRVIEW ROAD NEWTOWNABBEY
14 HAMILTON DRIVE NEWTON ABBOT
14 MYNYDD-RLSWG LEWISTOWN
14 NEW STREET PANTYGOG
14 ST NICHOLAS CLOSE NORTH BRADLEY
14 WAKE WAY GRANGE PARK
14 YEW TREE CLOSE LANGFORD
143 COLLEGE ROAD LLANDAFF NORTH
149 BROCKWORTH YATE
15 BREEZEMOUNT PARK CONLIG
15 BRISBANE CLOSE BRAMHALL
25 CRAIGIEBURN ROAD NORTH CARBRAIN CUMBERNAULD
25 DUNVEGAN AVENUE PORTLETHEN
25 HONEYBOURNE DRIVE WHISTON
25 Hullet Close Appley Bridge
25 WAVENEY DRIVE HOVETON
26 ARTHUR STREET AMPTHILL
26 GORSE ROAD SWINTON
26 SOUTHLANDS KIRKHAM
26 THE LEYS LONGBUCKBY
26 WINDMILL CRESCENT SKELMANTHORPE
27 ARCH ROAD HERSHAM
27 ASH TREE ROAD THORNE
27 BROOKSIDE WEST COKER
27 CROSS GATES ROAD MILNROW
27 JASPER AVENUE ROCHESTER
28 Condiere Avenue Connor Kells
28 Graham Drive Disley
28 WEST ROAD NEW COSTESSEY
29 CHESTNUT DRIVE YARNFIELD
29 KINGSBOROUGH GDNS HYNDLAND
29 LODWICK SHOEBURYNESS
29 ROWLEY DRIVE BROOM PARK
290 BARING ROAD GROVE PARK
2D GRAVEL LANE BANKS
3  CARLYON STREET (OFF STOCKTON ROAD)
3 ADKIN ROYD SILKSTONE
33 MOOR CROFT DRIVE LONGWELL GREEN
33 SHELLEY AVENUE CLIFTON
33 YEWLANDS DRIVE GARSTANG
34 ABBEY PARK BEESTON REGIS
34 SANDRINGHAM AVENUE BENTON
34 SYCAMORE LANE THE BEECHES
34 Viking House
35 BEACONSFIELD ROAD ST GEORGEBRISTOL
35 HALL DYKE SPONDON
35 MOORLAND VIEW ASTON
36 Chandos Place Roundhay
36 GREEN LANE TICKTON
36 Haigh Lane Chadderton
36 OVER MILL DRIVE BIRMINGHAM
37 FAIRVIEW DRIVE DANESTONE
37 FORSTAL COTTAGES FORSTAL AYLESFORD
;
```
## Change Log  
Version 1.0 (15MAR2023)
 * Initial version 
