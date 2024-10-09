# Update Global Variable in Intelligent Decisioning
The example demonstrates how to call [SAS Viya Services](https://developer.sas.com/rest-apis) and how to use tokens downstream returned in the HTTP header result.<br>
#### Use HTTP Request Step to receive Id for Global Variable in Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API. Set filter on REST call to receive information for a particular Global Variable.  
#### Use HTTP Request Step to receive ETag for Global Variable in Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API. We use the variable Id received in the first step as parameter to build the URL endpoint. We copy the ETag from the header result, as it is required when updating the variable.
#### Use HTTP Request Step to update Global Variable in Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API to update the global variable in Intelligent Decisioning. We use the variable Id received in the previous step as parameter to build the URL endpoint. We also use the ETag value from the previous step in the input header to update the global variable.

![](../../img/HTTPRequest_ex5.gif)

---
## Demo Recreate
Use the following settings to recreate the above example in SAS Studio.
1. Create new flow job in SAS Studio.
2. Step ***Get Global Variable Id - step***
	> * Drag ***HTTP Request step*** on canvas.
	> * Go to ***HTTP Request*** - tab.
 	> 	* Select ***Above specified URL is a relative-URL and points to a SAS Viya service***.
 	>  	* Set ***SAS Viya Service*** using URL below. 
	> 		```
	> 		/referenceData/globalVariables?filter=eq(name,'httpRequest')
	> 		```
 	>	* Set ***Method*** to *GET*.
 	>  * Go to ***Input Options*** - tab.
 	>  * Under ***Headers*** set *Header Lines* to 1
 	>  	* Use the Header Line default value
	> 		```
	> 		"Content-Type"="application/json"
	> 		```
	> * Go to ***Output Options*** - tab
	> 	* Under ***Output Table - Field Mapping*** use the below mapping to copy the global variable Id from the URL JSON result to macro 'globalVariableId'.
	> 	```
	> 	items/0/id | globalVariableId
	> 	```

---

### Read ETag - step
#### HTTP Request - tab
* Select ***Use SAS Internal Viya API***
**URL**
```
/referenceData/globalVariables/@globalVariableId@
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
id | globalVariableId
```
**Header Mapping**
```
ETag : ETag
```

---

### Update Global Variable - step
#### HTTP Request - tab
**URL**
```
/referenceData/globalVariables/@globalVariableId@
```
**Method**<br>
* Set method to ***PUT***.

**Payload**<br>
```
{
  "name": "httpRequest",
  "dataType": "string",
  "defaultValue": "HTTP Step"
}
```  
  
#### Input Options - tab
**Headers**
```
"Content-Type"="application/json"
```
```
"Accept"="application/json"
```
* We use %tslit() because the ETag has double quotes and we need to wrap it in single quotes.
```
"If-Match"= %tslit(&ETag)
```

### Test Data
* Run this code to create a Global Variable in Intelligent Decisioning.
```
%let viyaHost= %sysfunc(getoption(SERVICESBASEURL));

proc http
	method= "POST"
	url= "&server./referenceData/globalVariables"
	in= '{"name": "httpRequest","dataType": "string", "defaultValue": "Step"}'
	oauth_bearer= sas_services;
	headers
		'Accept'='application/json'
		'Content-Type'='application/json';
quit;

%symdel viyaHost;
```
