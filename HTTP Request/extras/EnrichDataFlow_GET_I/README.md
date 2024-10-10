# Enrich data flow using GET method
The example is calling a REST API using the GET method to enrich country names with capital, continent and languages information.<br>
The column from the input table is used as parameter to complete URL endpoint.<br>
Fields from the HTTP result are mapped to columns in the output table.<br>
The column from the input table is also passed through to the output table.

![](../../img/HTTPRequest_ex2.gif)

---
## Demo Recreate
Use the following settings to recreate the above example in SAS Studio.

1. Create new flow job in SAS Studio.
2. See the section on  [Test Data](./#TestData).
3. 
4. Step ***Get Global Variable Id***
	> * Drag ***HTTP Request step*** on canvas.
	> * Go to tab ***HTTP Request***.
	>	* Select ***Above specified URL is a relative-URL and points to a SAS Viya service***.
	>	* Set ***SAS Viya Service*** using URL below. 
	>		```
	>		/referenceData/globalVariables?filter=eq(name,'httpRequest')
	>		```
	>	* Set ***Method*** to *GET*.
	> * Go to tab ***Input Options***.
	>	* Under ***Headers*** set *Header Lines* to 1.
	>		* Use the Header Line default value.<br>
	>			```
	>			"Content-Type"="application/json"
	>			```
	> * Go to tab ***Output Options***.
	>	* Under ***Output Body - Output Table***<br>
 	> 		* Use the below mapping in field *Field Mapping* to copy the global variable 'id' from the URL JSON result to the output table column 'globalVariableId'.
	>			```
	>			items/0/id | globalVariableId
	>			```
	> * Go to tab ***Node***.
	>	* Set ***Node name*** to:
	>		```
	>		Get Global Variable Id
	>		```
	> * Add ***Output Port***
	>	* Use right mouse click to add output port to the step.

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

 [Test Data](#TestData)
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
