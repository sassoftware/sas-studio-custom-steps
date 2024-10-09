# Enrich data flow using GET method
The example is calling a REST API using the GET method to enrich country names with capital, continent and languages information.<br>
The column from the input table is used as parameter to complete URL endpoint.<br>
Fields from the HTTP result are mapped to columns in the output table.<br>
The column from the input table is also passed through to the output table.

![](../../img/HTTPRequest_ex2.gif)

To recreate the example in SAS Studio use the following settings for HTTP Request step and use the code to create input data.

### HTTP Request - step
#### HTTP Request - tab
**URL**
```
https://restcountries.com/v3.1/name/@country@
```
**Method**<br>
* Set method to ***GET***.

#### Input Options - tab
**Headers**
```
"Content-Type"="application/json"
```

#### Output Options - tab
**Field Mapping**
```
0/capital/0 | capital
0/continents | continents
0/languages | languages
```
**Pass through input data**
* Select box ***Add input columns to HTTP output table*** in the UI.

---

 ### Test Data
```
data country;
	length country $30;
	infile cards;
	input country $;
	cards;
USA
United Kingdom
Germany
South Africa
Canada
France
Italy
Spain
;
run;
```
