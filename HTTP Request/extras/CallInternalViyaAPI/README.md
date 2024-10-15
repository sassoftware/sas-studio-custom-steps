# Update Global Variable in SAS Intelligent Decisioning using SAS Viya Services
The example demonstrates how to call [SAS Viya Services](https://developer.sas.com/rest-apis) and how to use tokens downstream returned in the HTTP header result.<br>
#### Use HTTP Request Step to receive Id for Global Variable in SAS Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API. Set filter on REST call to receive information for a particular Global Variable.  
#### Use HTTP Request Step to receive ETag for Global Variable in SAS Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API. We use the variable Id received in the first step as parameter to build the URL endpoint. We copy the ETag from the header result, as it is required when updating the variable.
#### Use HTTP Request Step to update Global Variable in SAS Intelligent Decisioning
Use the HTTP Request Step to call Viya REST API to update the global variable in SAS Intelligent Decisioning. We use the variable Id received in the previous step as parameter to build the URL endpoint. We also use the ETag value from the previous step in the input header to update the global variable.

![](../../img/HTTPRequest_ex5.gif)

---
## Demo Recreate
Use the following settings to recreate the above example in SAS Studio.
1. Run code section [Test Data](#testdata-) to create a Global Variable in SAS Intelligent Decisioning.
2. Create new flow job in SAS Studio.
3. Step ***Get Global Variable Id***
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
 	> 		* Use the below mapping in field *Field Mapping* to copy the global variable 'id' from the URL JSON result structure to the output table column 'globalVariableId'.
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

4. Step ***Read ETag***
	> * Drag ***HTTP Request step*** on canvas and connect with step *Get Global Variable Id*.
	> * Go to tab ***HTTP Request***.
	>	* Select ***Above specified URL is a relative-URL and points to a SAS Viya service***.
	>	* Set ***SAS Viya Service***. In the URL we use the value from column 'globalVariableId' from the previous step's output table to build the required endpoint. 
	>		```
	>		/referenceData/globalVariables/@globalVariableId@
	>		```
	>	* Set ***Method*** to *GET*.
	> * Go to tab ***Input Options***.
	>	* Under ***Headers*** set *Header Lines* to 1.
	>		* Use the Header Line default value.<br>
	>			```
	>			"Content-Type"="application/json"
	>			```
	> * Go to tab ***Output Options***.
	>	* Under ***Output Body - Output Table***.<br>
 	> 		* Tick *Add input columns to output table* to pass trough input column 'globalVariableId' as we need it in the next step.
	>	* Under ***Header Mapping***.
 	> 		* Set *Header Mappings* to 1 and use the below mapping to copy the return token ETag to macro ETag.
	>			```
	>			ETag : ETag
	>			```
	> * Go to tab ***Node***.
	>	* Set ***Node name*** to:
	>		```
	>		Read ETag
	>		```
	> * Add ***Output Port***.
	>	* Use right mouse click to add output port to the step.
5. Step ***Update Global Variable***
	> * Drag ***HTTP Request step*** on canvas and connect with step *Read ETag*.
	> * Go to tab ***HTTP Request***.
	>	* Select ***Above specified URL is a relative-URL and points to a SAS Viya service***.
	>	* Set ***SAS Viya Service***. In the URL we use the value from column 'globalVariableId' from the previous step's output table to build the required endpoint. 
	>		```
	>		/referenceData/globalVariables/@globalVariableId@
	>		```
	>	* Set ***Method*** to *PUT*.
 	>	* Fill ***Payload*** text box with below JSON structure to update the global variable in SAS Intelligent Decisioning.
	>		```
	>		{
	>		  "name": "httpRequest",
	>		  "dataType": "string",
	>		  "defaultValue": "HTTP Step"
	>		}
	>		```
	> * Go to tab ***Input Options***.
	>	* Under ***Headers*** set *Header Lines* to 3.
	>		* For the first Header Line use default value.<br>
	>			```
	>			"Content-Type"="application/json"
	>			```
	>		* For the second Header Line use below setting.<br>
	>			```
	>			"Accept"="application/json"
	>			```
	>		* For the third Header Line we use macro function %tslit() because the ETag value has double quotes and we need to wrap it in single quotes.
	>			```
	>			"If-Match"= %tslit(&ETag)
	>			```
	> * Go to tab ***Node***.
	>	* Set ***Node name*** to:
	>		```
	>		Update Global Variable
	>		```
6. ***Check Global Variable***
	* Go to SAS Intelligent Decisioning and check the value for global variable 'httpRequest'.
6. ***Run Demo***
	* Execute Demo Flow.
6. ***Check Global Variable***
	* Go to SAS Intelligent Decisioning and check the value for global variable 'httpRequest' again to see that it has changed to 'HTTP Step'.


### Test Data <a name="testdata-"></a>
Run this code before executing the flow to create a Global Variable in SAS Intelligent Decisioning.
```
%let viyaHost= %sysfunc(getoption(SERVICESBASEURL));

proc http
	method= "POST"
	url= "&viyaHost./referenceData/globalVariables"
	in= '{"name": "httpRequest","dataType": "string", "defaultValue": "Step"}'
	oauth_bearer= sas_services;
	headers
		'Accept'='application/json'
		'Content-Type'='application/json';
quit;

%symdel viyaHost;
```
