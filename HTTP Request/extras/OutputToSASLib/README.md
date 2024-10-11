# Use HTTP Request step to copy the result to a macro and output data to SAS Library
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

## Demo Recreate
Use the following settings to recreate the above example in SAS Studio.
1. Create new flow job in SAS Studio.
2. Add swimlane and name it *Get Data Quality Steps*.
3. Step ***Get Token***.
	> * Drag ***HTTP Request step*** on swimlane *Get Data Quality Steps*.
	> * Go to tab ***HTTP Request***.
	>	* Set ***URL*** as below. Point <'viya server'> to your SAS Viya sever domain.
	>		```
	>		https://<viya server>/SASLogon/oauth/token
	>		```
	>	* Set ***Method*** to *POST*.
 	>	* Fill ***Payload***.<br>
  	>		* Set your SAS Viya *userid* and *password*.
	>		```
	>		grant_type=password&.username=<userid>&.password=<password>
	>		```
	> * Go to tab ***Input Options***.
	>	* Under ***Headers*** set *Header Lines* to 1.
	>		* Set Header Line to below value.<br>
	>			```
	>			"Content-Type" = "application/x-www-form-urlencoded"
	>			```
	>	* Under ***Authorization*** select *Auth Type*.
 	> 		* Set *Auth Type* to 'Basic Auth'
 	>		* Use *ClientId* and *Secret* in fields *Username* and *Password* respectively.   
	> * Go to tab ***Output Options***.
	>	* Under ***Output Body - Output Table***<br>
 	> 		* Use the below mapping in field *Field Mapping* to copy the *access_token* to column token in the step's output table.
	>			```
	>			access_token | token
	>			```
 	>	* Tick box *Create macro for output column*.
 	>		* Set the column from the output table that is copied to a macro with the same name as the column.
 	> 			``` 
 	> 			token 
 	> 			``` 
	> * Go to tab ***Node***.
	>	* Set ***Node name*** to:
	>		```
	>		Get Token
	>		```
	> * Add ***Output Port***
	>	* Use right mouse click to add output port to the step.

4. Step ***Get folder info***
	> * Drag ***HTTP Request step*** on swimlane and connect with step *Get Token*.
	> * Go to tab ***HTTP Request***.
	>	* Set ***URL***. 
	>		```
	>		https://<viya server>/folders/folders?filter=startsWith(name,'SAS Data Quality Steps')
	>		```
	>	* Set ***Method*** to *GET*.
	> * Go to tab ***Input Options***.
	>	* Under ***Headers*** set *Header Lines* to 1.
	>		* Use the Header Line default value.<br>
	>			```
	>			"Content-Type"="application/json"
	>			```
	>	* Under ***Authorization*** select *Auth Type*.
 	> 		* Set *Auth Type* to 'Bearer Token'
 	>		* Use SAS macro *token* from previous step.
 	> 			``` 
 	> 			&token 
 	> 			``` 
	> * Go to tab ***Output Options***.
	>	* Under ***Output Body - Output Table***<br>
 	> 		* Use the below mapping in field *Field Mapping* to copy the folder 'id' from the URL JSON result structure to the output table column 'folderid'.
	>			```
	>			items/0/id | folderid
	>			```
	> * Go to tab ***Node***.
	>	* Set ***Node name*** to:
	>		```
	>		Get folder info
	>		```
	> * Add ***Output Port***.
	>	* Use right mouse click to add output port to the step.
5. Step ***Get folder member info***
	> * Drag ***HTTP Request step*** on swimlane and connect with step *Get folder info*.
	> * Go to tab ***HTTP Request***.
	>	* Set ***URL***. In the URL we use the value from column 'folderid' from the previous step's output table to build the required endpoint. 
	>		```
	>		https://<viya server>/folders/folders/@folderid@/members
	>		```
	>	* Set ***Method*** to *GET*.
	> * Go to tab ***Input Options***.
	>	* Under ***Headers*** set *Header Lines* to 1.
	>		* Use the Header Line default value.<br>
	>			```
	>			"Content-Type"="application/json"
	>			```
	>	* Under ***Authorization*** select *Auth Type*.
 	> 		* Set *Auth Type* to 'Bearer Token'
 	>		* Use SAS macro *token* from first step.
 	> 			``` 
 	> 			&token 
 	> 			``` 
	> * Go to tab ***Output Options***.
	>	* Under ***Output Body - Output Library***<br>
 	> 		* Tick box *Write URL JSON output to SAS library*. This will output the step result to SAS library 'HTTPOUT'.
	> * Go to tab ***Node***.
	>	* Set ***Node name*** to:
	>		```
	>		Get folder member info
	>		```
6. Run swimlane *Get Data Quality Steps*.
7. Add swimlane and name it *List Data Quality Steps*.
8. Step ***R1_ITEMS***.
	* From SAS Lib *HTTPOUT* drag dataset R1_ITEMS on the canvas.
9. Step ***DQ Steps***.
	> * Drag step ***Manage Columns*** on canvas and connect with the *R1_ITEMS*.
	> * Use the step to select the column that contains the DQ Step names.
 	> 	* Select column *name* and give it the new name 'DQ Steps'.
	>	* Set ***Node name*** to:
	>		```
	>		Data Quality Steps
	>		```
