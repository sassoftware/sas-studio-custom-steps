# Update Global Variable in Intelligent Decisioning
The example demonstrates how to call internal Viya APIs and how to use tokens downstream returned in the HTTP header result.<br>
#### Use HTTP Request Step to receive Id for Global Variable in Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API. Set filter on REST call to receive information for a particular Global Variable.  
#### Use HTTP Request Step to receive ETag for Global Variable in Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API. We use the variable Id received in the first step as parameter to build the URL endpoint. We copy the ETag from the header result, as it is required when updating the variable.
#### Use HTTP Request Step to update Global Variable in Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API to update the variable. We use the variable Id received in the previous step as parameter to build the URL endpoint. We also use the ETag value from the previous step in the input header to update the variable.

![](../../img/HTTPRequest_ex5.gif)

Use the following settings to recreate the example in SAS Studio.

### Get Global Variable Id - step
#### HTTP Request - tab
**URL**
* Select ***Use SAS Internal Viya API***
```
/referenceData/globalVariables?filter=startsWith(name,'httpRequest')
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
data _null_;
	call symput('server', substr("&_baseurl", 1, prxmatch("\/SASStudio/\", "&_baseurl") - 1));
run;

proc http
	method="POST"
	url="&server./referenceData/globalVariables"
	in='{"name": "httpRequest2","dataType": "string", "defaultValue": "Step"}'
	oauth_bearer= sas_services;
	headers
		'Accept'='application/json'
		'Content-Type'='application/json';
quit;

%symdel server;
```
