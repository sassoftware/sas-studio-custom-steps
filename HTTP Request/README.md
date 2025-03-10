# HTTP Request
## Content
1. [Description](#description-)
2. [User Interface](#userinterface-)<br>
   2.1.   [HTTP Request tab](#httprequesttab-)<br>
   2.2.   [Input Options tab](#inputoptionstab-)<br>
   2.3.   [Output Options tab](#outputoptionstab-)<br>
   2.4.   [Batch tab](#batchtab-)<br>
   2.5.   [Settings tab](#settingstab-)<br>
3. [JSON structure field mapping for HTTP result](#fieldmapping-)
4. [Calling HTTP request in batch mode](#batchmode-)
5. [Requirements](#requirements-)
6. [Usage](#usage-)<br>
   5.1.  [Various usage examples](extras/README.md) 
7. [Change Log](#changelog-)

## Description<a name="description-"></a>
The HTTP Request step allows you to send HTTP/1.1 requests. The step is using PROC HTTP to execute the HTTP requests. 
You can use this step to validate data, enrich data in your data flow, update data via a REST call and more. 
There are various ways to receive data from the HTTP Request in order to use the HTTP result downstream in Studio Flow.

---

## User Interface<a name="userinterface-"></a>

### HTTP Request tab<a name="httprequesttab-"></a> 
At the HTTP Request tab you set general information for the http request.


   | Standalone mode | Flow mode |
   | --- | --- |                  
   | ![](img/HTTPRequest-HTTPRequest-sa.jpg) | ![](img/HTTPRequest-HTTPRequest-fl.jpg) |

   | UI Field | Comment|
   | --- | --- |
   | URL |Specify the fully qualified URL path that identifies the endpoint for the HTTP request.<br><br>If the URL has url parameters you need to mask the ampersand (&) sign. The & needs to be followed by a dot (.) e.g.:<br> ```https://myserver.com/search?name=Bob&.city=London```<br><br>You can also use SAS macro variables in the URL. In this case you must not mask the ampersand e.g.:<br>```https://&myserver/search?name=Bob&.city=London```<br><br>If you have an input table the URL will be called for each row in the table. You can pass in the column values for each row into the URL using the column names as parameters. The column name needs to be masked with a leading a tailing at-sign (@) in the URL e.g.:<br>```https://myserver.com/search?name=@firstname@&.city=@city@```<br><br>**Note:** If an ampersand for a URL parameter is not masked you will get a warning that a macro name cannot be resolved! |
   | Above specified URL is a relative-URL and points to a SAS Viya service | Check this box if you want to execute a SAS Viya service for the current Viya instance. <a href="https://developer.sas.com/rest-apis" target="_blank">SAS Viya services</a> are REST APIs to create and access SAS resources.<br>Insert the URL without server domain information (e.g.: /referenceData/domains).<br>:exclamation:**Note:** The SAS Viya environment needs to be set up to allow calling SAS Viya services from within SAS Studio (*calling internal IPs*). If you cannot call SAS Viya services you will receive a time out error. In this case check with your SAS Viya administrator. |
   | Method | Select a HTTP method from the drop down list. |
   | Payload | Specify the input data for the HTTP request.<br><br>If you have an input table you can pass in the column values for each row into the payload using the column names as parameters. The column name needs to be masked with a leading a tailing at-sign (@) in the payload e.g.:<br>```{ "name"="@firstname@", "city"="@city@" }```<br>You can also use SAS macro variables in the payload e.g.:<br>```{ "name"="@firstname@", "city"="&TOWN" }```<br><br>:exclamation:**Note:** The maximum length of the payload is 32,767 characters. This is the max length of SAS character variable. |

### Input Options tab<a name="inputoptionstab-"></a> 
At the Input Options tab you specify  input parameters for the HTTP request.

   <img src="img/HTTPRequest-InputOptions-fl.jpg" width="492" height="400">

   | Section | UI Field | Comment|
   | --- | --- | --- |
   | Headers | Header Lines | Set the number of header lines you want to submit. You can submit up to 8 header lines |
   || Header Line | Each header line has the format *'header' = 'value'* e.g.:<br>```"Content-Type": "application/json"```<br>The default value for header line 1 is "Content-Type": "application/json". If not appropriate you can change the value. | 
   | Authorization | Auth Type | Select how to authorize for the HTTP request. |
   ||| **No Auth** - Specifies that no authorization is used for the HTTP request. |
   ||| **Basic Auth** - Specifies to use user identity authentication to authenticate the connected server. The user name and password are supplied in the fields *Username* and *Password*. |
   ||| **Bearer Token** - Specifies to send an OAuth access token along with the HTTP call. The token value is supplied in field *Token*. This can be a direct token value or a SAS macro variable carrying the token. |

### Output Options tab<a name="outputoptionstab-"></a> 
At the Output Options tab you specify how to receive the data comming back from the HTTP request.

   <img src="img/HTTPRequest-OutputOptions-fl.jpg" width="616" height="1025">

#### Output Body<a name="outputbody-"></a> 
If the output format is json you can specify fields from the json structure to land in the output table.

   | Section | UI Field | Comment|
   | --- | --- | --- |
   | Output Table | Field Mapping | In the field mapping text box point to the field in the json structure that you want to output to the step's output table.<br>For information to map the fields see [JSON structure field mapping for HTTP result](#fieldmapping-). |
   || If field could not get mapped | If the field to be mapped cannot be found the map-column will be set to null. This can happen either because the map field does not exist in the json structure or there was no value returned for the field and hence it is missing in the json structure. In both cases the map-column will be set to null. You can set one of the three option to react to it:<br>* **No Message** - No message pops up if a field is missing.<br>* **Show Warning** - The SAS job will throw a warning message.<br>* **Show Error** - The SAS job will throw an error message and aborts the job. |
   || Add input columns to HTTP output table | If an input table exists, the step will output both input columns and output columns in the output table. |
   || Create SAS macro variable for output column | Tick the box and name the output columns you want to be copied to SAS macro variables. The step will create macro variables for the named output columns. This way you can copy a field value from the HTTP json output structure to a SAS macro variable. If the input table has more than one row only the values from the first result row will be copied to macro variables. The macro variables have the same names like the output column. To create more than one macro variable, use a comma separated list.|
   | Output Library || The json result from the HTTP request will be put in a SAS library using the json engine. The datasets in the library represent the json structure. This enables you to access the HTTP result using other steps like *Query* for example. |
   || Output to SAS library | Indicates whether to output the HTTP result to a SAS library. Default is not to write to a SAS Library. |
   || Output Library | Set the name of the SAS output library. The lib name can be up to 8 characters long. The default name is *HTTPOUT*. |
   | Output Folder<a name="httpoutputfolder-"></a> || The step can write the HTTP result to a file.<br>You can write the HTTP output to a file and then use the file in other steps, for example, opening the file in Python for further processing. |
   || HTTP Output Folder | Select the folder for the HTTP output file. The folder must be a folder on SAS Server. |
   || HTTP Output File Name | Set the name for the HTTP result file without file suffix. The default name is *httpoutAll*. This will create a file named *httpoutAll.json*.<br>The output file contains the output for all records passed through the step in json format. A key will indecate the record number. For example, if the step had three input records the format of the file will look like this:<br>```{"1":"-http result for rec 1-", "2":"-http result for rec 2-", "3": "-http result for rec 3-"}``` |

> :bulb: **Tip:** When running the step and an error occurs due to problems executing the URL. You can output the returned HTTP result to a json file. The output file may contain additional information on the execution problem.

#### Header Mapping<a name="headermapping-"></a> 
In the Header Mapping section you can map tags from the HTTP header result to SAS macro variables.
   
   | UI Field | Comment|
   | --- | --- |
   | Header Mappings | Set the number of tags you want to map from the HTTP header result. |
   | Edit Line | Set the tag and macro variable name to map. The mapping format is: *Header Tag : Macro Variable Name* |
   | Tag name is case sensitive | Indicate to look for the tag in case sensitive mode. Default is *not case sensitive*. |

### Batch tab<a name="batchtab-"></a>
At the Batch tab you define the json batch structure and set the number of records submitted in batch mode.

   <img src="img/HTTPRequest-Batch-fl.jpg" width="488" height="376">

> :memo: **Note:** Batch Mode requires that it is supported by the HTTP request and needs to be called in POST, PUT or PATCH mode.

   | UI Field | Comment|
   | --- | --- |
   | Record group size | Set the number of records from the input table to be grouped together to submit them in one HTTP call.<br>***Note:*** When setting the number of grouped records, consider the record size as the overall payload size must not exceed 10MB. | 
   | Repeated json Structure | The part of the json payload that holds information for one record. |
   | Batch structure name | The name of the variable token for the json structure used in the payload (HTTP Request tab). The default variable token name is *batch_records*.


### Settings tab<a name="settingstab-"></a>
At the Settings tab can you switch on/off hyperlinks in the UI.

   <img src="img/HTTPRequest-Settings-fl.jpg" width="568" height="481">

#### Timeout<a timeout="debug-"></a> 
Under Timeout you can set how long a HTTP request is waiting to receive an answer.
   | UI Field | Comment|
   | --- | --- |
   | Timeout | Set the number of seconds of inactivity to wait before cancelling the HTTP request. 0 indecates no timeout. |



#### Debug<a name="debug-"></a> 
Under Debug you can set the debug level to get additional log information.

   | UI Field | Comment|
   | --- | --- |
   | HTTP Debug Level | Set the debug level for this step. You can set level 1 - 3. Depending on the level PROC HTTP will write additional information to the log.<br>If you have set the [*Output Folder*](#httpoutputfolder-) the step will write a http json result file for each row (each http request execution) to the output folder. |

#### Hyperlinks<a name="hyperlinks-"></a> 
Under Hyperlinks can you switch on/off hyperlinks unsed in the UI.


   | UI Field | Comment|
   | --- | --- |
   | Show hyperlinks in step | In the Step UI are hyper-links to deliver more information and help on some subjects. By default hyper-links in steps are disabled. The SAS Viya administrators can use SAS Environment Manager to enable this functionality and to specify the validation rules for links. |
   
   > :memo: **Note:** You can use the below validation rules for the links used in this step:<br>
   ```
   ^https?:\/\/(?:.+\.)?github\.com(?::\d+)?(?:\/.*)?||^https?:\/\/(?:.+\.)?developer\.sas\.com(?::\d+)?(?:\/.*)?
   ```
> For more information see [SAS Studio documentation](https://go.documentation.sas.com/doc/en/webeditorcdc/v_047/webeditorsteps/n1mo7ndvgpomx3n1ir6sm9xzzny0.htm) and also blog [SAS Viya: Link Control for Custom Steps](https://communities.sas.com/t5/SAS-Communities-Library/SAS-Viya-Link-Control-for-Custom-Steps/ta-p/919005) on how to set *Link Control* validation rules.

---

## JSON structure field mapping for HTTP result<a name="fieldmapping-"></a>
Field mapping offers you a convenient way to map fields from the result json structure to a column in the output table.<br>
The mapping format is: *json structure path | map column name*<br>
For Example, assuming you have a json result like this:
```
                                           | zip              | country         |
{                                          | ---------------- | --------------- |
    "status": 200,                         |                  |                 |
    "result": [                            | *** result ***   | *** result ***  |
        {                                  |                  |                 |
            "query": "U3 4AB",             |                  |                 |
            "result": null                 |                  |                 |
        },                                 |                  |                 |
        {                                  | *** 1 ***        | *** 1 ***       |
            "query": "AL3 8EE",            |                  |                 |
            "result": {                    | *** result ***   | *** result ***  |
                "postcode": "AL3 8EE", --> | *** postcode *** |                 |
                "quality": 1,              |                  |                 |
                "eastings": 507817,        |                  |                 |
                "northings": 214437,       |                  |                 |
                "country": "England"   ----+----------------> | *** country *** |
            }                              |                  |                 |
        }                                  |                  |                 |
    ]                                      |                  |                 |
}                                          |                  |                 |

```
Assuming you want to map the fields *postcode* and *country* from row 2 of array *result* to columns *zip* and *country*. The mapping structure will look like this:
```
result/1/result/postcode | zip,
result/1/result/country  | country
```
This will produce an output table with columns *zip* and *country* with values from json fields *postcode* and *country*.

> :memo: **Note:** If you point at a json array the whole json array will be copied into the column.<br>
> For the above structure if you point at ```result/0 | allinfo``` the value of column *allinfo* will look like<br>
> ```{"query": "U3 4AB", "result": null}```.

---

## Calling HTTP request in batch mode<a name="batchmode-"></a>
> :memo: **Note:** The HTTP request to be called needs to support batch mode calls! The json payload structure needs to have a repeat section.<br> 

* The HTTP request needs to be called with method POST, PUT or PATCH.<br>
* The *HTTP Request* step needs to have an input table.<br>
* The payload needs to have a repeat structure for the batch records to be submitted.<br>

### Prepare batch mode:<br>

**Example:**<br>
Assuming we have an input table with person information in each row. One column is named *lastname*. We want to submit several lastnames per HTTP PUT method call.<br>
The payload structure looks like:
```
{
   "names": ["name_1", "name_2", "name_3", ... "name_n"]
}
```

At tab *HTTP Request* set *Method* to PUT and the Payload to:
```
{
   "names" : [@lastname_group@]
}
```

At tab *Batch* set field *Record group size* to 50 and *Repeated json structure* to:
```
"@lastname@"
```
Also set field *Batch structure name* to *lastname_group*<br>

We group the *lastname* from several rows together to submit them in one call. This way, if we have 120 rows in the table and group 50 rows together, we need to call the HTTP request 3 times (50, 50, 20) instead of 120 times.<br>

By putting @lastname@ (the table column name) into *Batch structure name* and setting *Record group size* to 50 we group the names from 50 rows together and assign them to batch structure token *lastname_group*:
```
lastname_group= "name_1", "name_2", "name_3", ... "name_50"
```
When setting the payload in tab *HTTP Request* we use the batch structure token *lastname_group* to add the batch data to the payload.

The step is now prepared for batch mode. With all other settings in place we can run the step.

See  [Batch Demo I](extras/BatchMode_I/README.md) and [Batch Demo II](extras/BatchMode_II/README.md) for more information.

---

## Requirements <a name="requirements-"></a>
* SAS Viya 2024.06 or later.
* Python needs to be installed and configured to work with SAS Studio.
* *Link Control* validation rules need to be configured to use the hyper-links in the Step UI. For more information see [here](#settingstab-).
* The SAS Viya environment needs to be set up to allow calling SAS Viya services from within SAS Studio. If you cannot call SAS Viya services you will receive a time out error. In this case check with your SAS Viya administrator.

---

## Usage<a name="usage-"></a> 

Use the HTTP Request step to enrich data in a table. The table country has a column country with different counties. Using the HTTP Request we enrich the country information with capital, language and continent information.<br>

![](img/HTTPRequest.gif)

For more example using the HTTP Request Step see [here](extras/README.md)

---

## Change Log<a name="changelog-"></a> 
Version 1.1 (21NOV2024)<br>
   * Added capability to submit batch requests

Version 1.0.1 (17OCT2024)<br>
   * Increased size of variable containing URL payload
   * Changed UI labels from using term "macro" to "SAS macro variable"<br>

Version 1.0 (15OCT2024)<br>
   * Initial version 

 