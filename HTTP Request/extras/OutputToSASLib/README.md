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

Use the following settings to recreate the example in SAS Studio.

### Swimlane: *Get Data Quality Steps*

---

#### Get Token - step
#### HTTP Request - tab
**URL**
```
https://<viya server>/SASLogon/oauth/token
```
**Method**<br>
* Set method to ***POST***
  
**Payload**<br>
* Set your *userid* and *password*.
```
grant_type=password&.username=<userid>&.password=<password>
```
#### Input Options - tab
**Headers**
```
"Content-Type" = "application/x-www-form-urlencoded"
```
**Authorization**<br>
* Select ***Basic Auth***
* Use *ClientId* and *Secret* in fields *Username* and *Password* respectively.

#### Output Options - tab
**Field Mapping**
```
access_token | token
```
**Create Macro**
* Select box ***Create macro for output column*** in the UI.
* Set the macro name to the same name as the output column.
```
token
```

#### Get folder info - step
#### HTTP Request - tab
**URL**
```
https://<viya server>/folders/folders?filter=startsWith(name,'SAS Data Quality Steps')
```
**Method**<br>
* Set method to ***GET***.
#### Input Options - tab
**Headers**
```
"Content-Type"="application/json"
```
**Authorization**<br>
* Select ***Bearer Token***.
* Use SAS macro *&token* from previous step.
```
&token
```
#### Output Options - tab
**Field Mapping**
```
items/0/id | folderid
```
#### Get folder member info - step
#### HTTP Request - tab
**URL**
```
https://<viya server>/folders/folders/@folderid@/members
```
**Method**<br>
* Set method to ***GET***.
#### Input Options - tab
**Headers**
```
"Content-Type"="application/json"
```
**Authorization**<br>
* Select ***Bearer Token***.
* Use SAS macro *&token* from previous step.
```
&token
```
#### Output Options - tab
**Output Library**
* Select box ***Output to SAS library***.

### Swimlane: *List Data Quality Steps*
#### __ITEMS
* Drag dataset __ITEMS from SAS Lib *HTTPOUT* on the canvas.
#### Get folder info - step
* Use step *Manage Columns* to select *Data Quality Step* names from the dataset.
* Select column name.
* Rename column to *DQSteps*.
