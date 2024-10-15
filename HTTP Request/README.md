# HTTP Request

## Description 
The HTTP Request step allows you to send HTTP/1.1 requests. The step is using PROC HTTP to execute the HTTP requests. 
You can use this step to validate data, enrich data in your data flow, update data via a REST call and more. 
There are various ways to receive data from the HTTP Request in order to use the HTTP result downstream in Studio Flow.

---

## User Interface 

### HTTP Request tab 
At the HTTP Request tab you set general information for the http request.


   | Standalone mode | Flow mode |
   | --- | --- |                  
   | ![](img/HTTPRequest-HTTPRequest-sa.jpg) | ![](img/HTTPRequest-HTTPRequest-fl.jpg) |

   | UI Field | Comment|
   | --- | --- |
   | URL |Specify the fully qualified URL path that identifies the endpoint for the HTTP request.<br><br>If the URL has url parameters you need to mask the ampersand (&) sign. The & needs to be followed by a dot (.) e.g.:<br> ```https://myserver.com/search?name=Bob&.city=London```<br><br>You can also use SAS macros in the URL. In this case you must not mask the ampersand e.g.:<br>```https://&myserver/search?name=Bob&.city=London```<br><br>If you have an input table the URL will be called for each row in the table. You can pass in the column values for each row into the URL using the column names as parameters. The column name needs to be masked with a leading a tailing at-sign (@) in the URL e.g.:<br>```https://myserver.com/search?name=@firstname@&.city=@city@```<br><br>**Note:** If an ampersand for a URL parameter is not masked you will get a warning that a macro name cannot be resolved! |
   | Above specified URL is a relative-URL and points to a SAS Viya service | Check this box if you want to execute a SAS Viya service for the current Viya instance. <a href="https://developer.sas.com/rest-apis" target="_blank">SAS Viya services</a> are REST APIs to create and access SAS resources.<br>Insert the URL without server domain information (e.g.: /referenceData/domains).<br>:exclamation:**Note:** The SAS Viya environment needs to be set up to allow calling SAS Viya services from within SAS Studio (*calling internal IPs*). If you cannot call SAS Viya services you will receive a time out error. In this case check with your SAS Viya administrator. |
   | Method | Select a HTTP method from the drop down list. |
   | Payload | Specify the input data for the HTTP request.<br><br>If you have an input table you can pass in the column values for each row into the payload using the column names as parameters. The column name needs to be masked with a leading a tailing at-sign (@) in the payload e.g.:<br>```{ "name"="@firstname@", "city"="@city@" }```<br>You can also use SAS macros in the payload e.g.:<br>```{ "name"="@firstname@", "city"="&TOWN" }```<br><br>:exclamation:**Note:** The maximum length of the payload is 65,534 characters, as this is the max length of the SAS Macro holding the payload content.|

### Input Options tab 
At the Input Options tab you specify  input parameters for the HTTP request.

   <img src="img/HTTPRequest-InputOptions-fl.jpg" width="568" height="545">

   | Section | UI Field | Comment|
   | --- | --- | --- |
   | Headers | Header Lines | Set the number of header lines you want to submit. You can submit up to 8 header lines |
   || Header Line | Each header line has the format *'header' = 'value'* e.g.:<br>```"Content-Type": "application/json"```<br>The default value for header line 1 is "Content-Type": "application/json". If not appropriate you can change the value. | 
   | Authorization | Auth Type | Select how to authorize for the HTTP request. |
   ||| **No Auth** - Specifies that no authorization is used for the HTTP request. |
   ||| **Basic Auth** - Specifies to use user identity authentication to authenticate the connected server. The user name and password are supplied in the fields *Username* and *Password*. |
   ||| **Bearer Token** - Specifies to send an OAuth access token along with the HTTP call. The token value is supplied in field *Token*. This can be a direct token value or a macro carrying the token. |
   | Timeout | | Set the number of seconds of inactivity to wait before cancelling the HTTP request. 0 indecates no timeout. |

### Output Options tab 
At the Output Options tab you specify how to receive the data comming back from the HTTP request.

   <img src="img/HTTPRequest-OutputOptions-fl.jpg" width="637" height="1185">

#### Output Body 
If the output format is json you can specify fields from the json structure to land in the output table.

   | Section | UI Field | Comment|
   | --- | --- | --- |
   | Output Table | Field Mapping | In the field mapping text box point to the field in the json structure that you want to output to the step's output table.<br>For information to map the fields see [JSON structure field mapping for HTTP result](#fieldmapping-). |
   || If field could not get mapped | If the field to be mapped cannot be found the map-column will be set to null. This can happen either because the map field does not exist in the json structure or there was no value returned for the field and hence it is missing in the json structure. In both cases the map-column will be set to null. You can set one of the three option to react to it:<br>* **No Message** - No message pops up if a field is missing.<br>* **Show Warning** - The SAS job will throw a warning message.<br>* **Show Error** - The SAS job will throw an error message and aborts the job. |
   || Add input columns to HTTP output table | If an input table exists, the step will output both input columns and output columns in the output table. |
   || Create macro for output column | Tick the box and name the output columns you want to be copied to SAS marcors. The step will create macros for the named output columns. This way you can copy a field value from the HTTP json output structure to a macro. If the input table has more than one row only the values from the first result row will be mapped to macros. The macros have the same names like the output column. |
   | Output Library || The json result from the HTTP request will be put in a SAS library using the json engine. The datasets in the library represent the json structure. This enables you to access the HTTP result using other steps like *Query* for example. |
   || Output to SAS library | Indicates whether to output the HTTP result to a SAS library. Default is not to write to a SAS Library. |
   || Output Library | Set the name of the SAS output library. The lib name can be up to 8 characters long. The default name is *HTTPOUT*. |
   | Output Folder || The step can write the HTTP result to a file.<br>You can write the HTTP output to a file and then use the file in other steps, for example, opening the file in Python for further processing. |
   || HTTP Output Folder | Select the folder for the HTTP output file. The folder must be a folder on SAS Server. |
   || HTTP Output File Name | Set the name for the HTTP result file without file suffix. The default name is *httpoutAll*. This will create a file named *httpoutAll.json*.<br>The output file contains the output for all records passed through the step in json format. A key will indecate the record number. For example, if the step had three input records the format of the file will look like this:<br>```{"1":"-http result for rec 1-", "2":"-http result for rec 2-", "3": "-http result for rec 3-"}``` |

> :bulb: **Tip:** When running the step and an error occurs due to problems executing the URL. You can output the returned HTTP result to a json file. The output file may contain additional information on the execution problem.

#### Header Mapping ####
In the Header Mapping section you can map tags from the HTTP header result to SAS macro variables.
   
   | UI Field | Comment|
   | --- | --- |
   | Header Mappings | Set the number of tags you want to map from the HTTP header result. |
   | Edit Line | Set the tag and macro variable to map. The mapping format is: *Header Tag : Macro Variable Name* |
   | Tag name is case sensitive | Indicate to look for the tag in case sensitive mode. Default is *not case sensitive*. |
   
#### Options ####
Under Options you can set additional options.

   | UI Field | Comment|
   | --- | --- |
   | HTTP Debug Level | Set the debug level for this step. You can set level 1 - 3. Depending on the level PROC HTTP will write additional information to the log. |

### Settings tab<a name="settingstab-"></a>
At the Settings tab can you switch on/off hyperlinks in the UI.

   <img src="img/HTTPRequest-Settings-fl.jpg" width="645" height="264">

In the Step UI are hyper-links to deliver more information and help on some subjects. By default hyper-links in steps are disabled. The SAS Viya administrators can use SAS Environment Manager to enable this functionality and to specify the validation rules for links.<br>
You can use the below validation rules for the links used in this step:
   ```
   ^https?:\/\/(?:.+\.)?github\.com(?::\d+)?(?:\/.*)?||^https?:\/\/(?:.+\.)?developer\.sas\.com(?::\d+)?(?:\/.*)?
   ```
For more information see [SAS Studio documentation](https://go.documentation.sas.com/doc/en/webeditorcdc/v_047/webeditorsteps/n1mo7ndvgpomx3n1ir6sm9xzzny0.htm) and also blog [SAS Viya: Link Control for Custom Steps](https://communities.sas.com/t5/SAS-Communities-Library/SAS-Viya-Link-Control-for-Custom-Steps/ta-p/919005) on how to set *Link Control* validation rules.

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

## Requirements <a name="requirements-"></a>
* SAS Viya 2024.06 or later.
* Python needs to be installed and configured to work with SAS Studio.
* *Link Control* validation rules need to be configured to use the hyper-links in the Step UI. For more information see [here](#settingstab-).
* The SAS Viya environment needs to be set up to allow calling SAS Viya services from within SAS Studio. If you cannot call SAS Viya services you will receive a time out error. In this case check with your SAS Viya administrator.

---

## Usage

Use the HTTP Request step to enrich data in a table. The table country has a column country with different counties. Using the HTTP Request we enrich the country information with capital, language and continent information.<br>

![](img/HTTPRequest.gif)

For more example using the HTTP Request Step see [here](extras/README.md)

---

## Change Log
Version 1.0 (15OCT2024)
 * Initial version 
