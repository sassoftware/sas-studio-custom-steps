# Enrich data flow using GET method
The example is calling a REST API using the GET method to enrich address data with longitude & latitude information.<br>
The columns from the input table are used as parameters in the URL to set the URL input parameters.<br>
The longitude & latitude fields from the HTTP result are mapped to columns in the output table.<br>
The address columns from the input table are also passed through to the output table.

![](../../img/HTTPRequest_ex3.gif)

---
## Demo Recreate
Use the following settings to recreate the above example in SAS Studio.

1. Create new flow job in SAS Studio.
2. Drag table 'address' on the canvas.
	* See [here](#testdata-) to create table 'address'.
3. ***HTTP Request***
	> * Drag ***HTTP Request step*** on canvas  and connect with the input table step.
	> * Go to tab ***HTTP Request***.
	>	* Set ***URL*** as below where we use the comun values from the input table as URL parameters.<br>
 	>         :grey_exclamation:**Note:** We need to escape the ampersand sign (&) with a dot (.) to prevent any macro resolution.
	>		```
	>		https://nominatim.openstreetmap.org/search?street=@address@&.city=@town@&.country=@country@&.format=json&.addressdetails=1&.limit=1
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
 	> 		* Use the below mapping in field *Field Mapping* to copy fields from the URL JSON result structure to the output table.
	>			```
	>			0/lat | lat,
	>			0/lon | lon
	>			```
 	> 		* Tick *Add input columns to output table* to pass trough input columns the output table.
	> * Add ***Output Port***.
	>	* Use right mouse click to add output port to the step.

### Test Data <a name="testdata-"></a>
```
data work.address;
	length address town country $30;
	infile cards dlm=",";
	input address town country $;
	cards;
Oppelner Strasse 12,Marl,Germany
2 Trowley Hill Rd,Flamstead,UK
10 Chiswell St,London,UK
333 Orchard Rd,Singapore,
;
run;
```

