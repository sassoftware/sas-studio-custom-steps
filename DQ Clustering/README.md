# DQ - Cluster  

## Description  

The **DQ - Cluster** allows you to create a cluster match code using columns that can be defined with 1 or 3 rules.  

## User Interface

* ### Match and Cluster tab ###

   | Standalone mode | Flow mode |
   | --- | --- |                  
   | ![](img/dqcluster-tabMatchStandAlone.png) | ![](img/dqcluster-tabMatchFlowMode.png) |

1. **Cluster records based on following rule(s).** - Defines up to three rules for creating the cluster, several columns can be inserted in each rule.  

* ### Options tab ###

   ![](img/dqcluster-tabOptions.png)

## Requirements

2021.1.1 or later  

## Usage

![Using the DQ - Cluster Custom Step](img/demo_dqcluster.gif)   

## Download Step file  

[DQ - Cluster Custom Step](./dqcluster.step)

## Prompt UI  
```json  
{
	"showPageContentOnly": true,
	"pages": [
		{
			"id": "entityRes",
			"type": "page",
			"label": "Match and Cluster",
			"children": [
				{
					"id": "inTable",
					"type": "inputtable",
					"label": "Select an input table:",
					"required": true
				},
				{
					"id": "clusterName",
					"type": "textfield",
					"label": "New column name:",
					"required": true
				},
				{
					"id": "cluster_text",
					"type": "text",
					"text": "Cluster records based on following rule(s)."
				},
				{
					"id": "rule1",
					"type": "columnselector",
					"label": "Rule 1 columns:",
					"table": "inTable",
					"order": true,
					"max": 0,
					"min": 1
				},
				{
					"id": "addRule2",
					"type": "checkbox",
					"label": "Add Rule 2"
				},
				{
					"id": "rule2",
					"type": "columnselector",
					"label": "Rule 2 columns:",
					"table": "inTable",
					"order": true,
					"max": 0,
					"min": 1,
					"visible": "$addRule2"
				},
				{
					"id": "addRule3",
					"type": "checkbox",
					"label": "Add Rule 3"
				},
				{
					"id": "rule3",
					"type": "columnselector",
					"label": "Rule 3 columns:",
					"table": "inTable",
					"order": true,
					"max": 0,
					"min": 1,
					"visible": "$addRule3"
				},
				{
					"id": "outTable",
					"type": "outputtable",
					"label": "Specify the output table:",
					"required": true
				}
			]
		},
		{
			"id": "matchOptions",
			"type": "page",
			"label": "Options",
			"children": [
				{
					"id": "clusonly",
					"type": "checkbox",
					"label": "Excludes input character values that are not part of a cluster."
				},
				{
					"id": "blanks1",
					"type": "dropdown",
					"label": "Specifies how to process blank values",
					"items": [
						{
							"value": "CLUSTER_BLANKS",
							"label": "Specifies that blank values are written to the output data set"
						},
						{
							"value": "NO_CLUSTER_BLANKS",
							"label": "Specifies that blank values are not written to the output data set"
						}
					],
					"required": true,
					"placeholder": "",
					"visible": ""
				}
			]
		}
	],
	"values": {
		"clusterName": "Cluster_ID",
		"blanks1": {
			"value": "CLUSTER_BLANKS",
			"label": "Specifies that blank values are written to the output data set"
		}
	}
}  
```

## Program   
```sas  
%macro usr_dqmatch() ;

	proc dqmatch data=&intable 
		out=&outtable
		cluster=&clusterName
		
		&blanks1
		%if &clusonly=1 %then %do ;
			CLUSTERS_ONLY
		%end ;
		;                                                                                                               

		%let con=1 ;

		%do con=1 %to 3 ;
			%do i = 1 %to &&rule&con._count;
				criteria condition=&con var=&&rule&con._&i._name exact;   
			%end;
		%end ;
	run;

%mend ;
%usr_dqmatch() ;  
``` 

## Change Log

* Version 1 (14SEP2022)
    * Initial version
