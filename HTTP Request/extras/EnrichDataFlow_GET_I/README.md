# Enrich data flow using GET method
The example is calling a REST API using the GET method to enrich country names with capital, continent and languages information.<br>
The column from the input table is used as parameter to complete URL endpoint.<br>
Fields from the HTTP result are mapped to columns in the output table.<br>
The column from the input table is also passed through to the output table.

![](../../img/HTTPRequest_ex2.gif)

Use the following settings and code to recreate the example in SAS Studio.

**URL**
```
https://restcountries.com/v3.1/name/@country@
```
**Headers**
```
"Content-Type"="application/json"
```
**Field Mapping**
```
0/capital/0 | capital
0/continents | continents
0/languages | languages
```
**Test Data**
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
