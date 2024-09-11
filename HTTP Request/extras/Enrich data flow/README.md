
# Enrich data flow
We have a table with UK post codes. We call a REST service to get county, council and parish information for each post code.

![](../img/HTTPRequest_ex1.gif)

Use the following settings and code to recreate the example in SAS Studio.

**URL**
```
http://api.postcodes.io/postcodes
```
**Payload**
```
{
"postcodes" : ["@PO1@", "@PO2@", "@PO3@"]
}
```
**Headers**
```
"Content-Type"="application/json"
```
```
"Accept"="application/json"
```
**Field Mapping**
```
result/0/result/admin_county    | county_1,
result/0/result/admin_district  | council_1,
result/0/result/parish          | parish_1,
result/1/result/admin_county    | county_2,
result/1/result/admin_district  | council_2,
result/1/result/parish          | parish_2,
result/2/result/admin_county    | county_3,
result/2/result/admin_district  | council_3,
result/2/result/parish          | parish_3
```
**Test Data**
```
data postcodes;
	length po1-po03 $10;
	infile cards dlm=",";
	input po1 po2 po3 $;
	cards;
AL3 8EE,AL4 0RQ,W2 1JU
OX49 5NU,M32 0JG,NE30 1DP
;
run;
```
