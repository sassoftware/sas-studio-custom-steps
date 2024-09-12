# Use HTTP result to macro and output data to SAS Library
In the example we use the HTTP Request step to receive a list of all Data Quality steps in SAS Studio.<br>
#### Use HTTP Request Step to receive a Viya access token
Use the HTTP Request Step to receive the Viya access token and copy the token into a SAS macro variable. We use the token in the macro variable in the next two steps to authenticate against Viya.
#### Use HTTP Request Step to receive Viya folder id
Use the HTTP Request Step to receive the Viya folder information for the folder that holds the Data Quality steps. We copy the folder id into the step output table to use it in the next step as parameter.
#### Use HTTP Request Step to receive Data Quality Steps
Use the HTTP Request Step to receive information about the Data Quality steps and output the result to a SAS Library. We use the folder id from the previous step to build the correct URL endpoint.
#### Select the necessary information from the HTTP result in the SAS Library
Access the table in the SAS Lib that holds the information about the Data Quality steps and select the appropriate column in the table.

![](../../img/HTTPRequest_ex4.gif)

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
