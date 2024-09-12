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

### Get Token - step
---
**URL**
```
https://<viya server>/SASLogon/oauth/token
```
**Method**<br>
* Set method to ***POST***
  
**Payload**
```
grant_type=password&.username=<user id>&.password=<password>
```
**Headers**
```
"Content-Type" = "application/x-www-form-urlencoded"
```
**Authorization**<br>
* Select ***Basic Auth***
* Use ClientId and Secret in Username and Password respectively.

**Field Mapping**
```
access_token | token
```
**Create Macro**
Tick box in the UI and set the macro to the same name as the output column.
```
token
```
### Get folder info - step
---
**URL**
```
https://<viya server>/folders/folders?filter=startsWith(name,'SAS Data Quality Steps')
```
**Method**<br>
* Set method to ***GET***

**Headers**
```
"Content-Type"="application/json"
```
**Authorization**<br>
* Select ***Bearer Token***
* Use SAS macro from previous step
	* ***&token***

**Field Mapping**
```
items/0/id | folderid
```
### Get folder member info - step
---
**URL**
```
https://<viya server>/folders/folders/@folderid@/members
```
**Method**<br>
* Set method to ***GET***

**Headers**
```
"Content-Type"="application/json"
```
**Authorization**<br>
* Select ***Bearer Token***
* Use SAS macro from previous step
	* ***&token***

**Field Mapping**
```
items/0/id | folderid
```
