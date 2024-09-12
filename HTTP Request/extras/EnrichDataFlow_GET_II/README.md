# Enrich data flow using GET method
The example is calling to a REST API using the GET method to enrich address data with longitude & latitude information.<br>
The columns from the input table are used as parameters in the URL to set the URL input parameters.<br>
The longitude & latitude fields from the HTTP result are mapped to columns in the output table.<br>
The address columns from the input table are also passed through to the output table.

![](../../img/HTTPRequest_ex3.gif)

Use the following settings and code to recreate the example in SAS Studio.
