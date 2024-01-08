# Natural Language Processing(NLP) - Categories Testing Framework

This custom step facilitates testing, assessment and continuous improvement of a SAS Visual Text Analytics (VTA) categorization model. 

Rapid AI prototyping improves time to value.  Implement processes based on this custom step (and [custom reporting templates](./extras/Import%20Report%20Templates.md) provided in the same repo) to assess the current progress of your model.  An example application is to run this step in parallel with your NLP model development and visualize assessment output using SAS Visual Analytics.

## A general idea 

### Overview (click on pic below to access YouTube video)

[![NLP - Categories Testing Framework](./img/NLP%20-%20Categories%20Testing%20Framework.png)](https://youtu.be/Uy81JNpg9vg)

https://youtu.be/Uy81JNpg9vg

### Example Assessment Report
![Example Report](./img/Example%20assessment%20Report.png)

## SAS Viya Version Support
Tested in Viya 4, Stable 2023.12

## Requirements

1. A SAS Viya 4 environment (monthly release 2023.12 or later) with SAS Studio Flows.

2. SAS Visual Text Analytics should be licensed.

## Parameters

This custom step requires a SAS Visual Text Analytics (VTA) license. It runs on data loaded to a SAS Cloud Analytics Services (CAS) library (known as a caslib). Ensure you are connected to CAS before running this step. Make sure the step has permissions to write to the output caslib, and also that caslibs are assigned once you've established a connection to CAS.

### Input Parameters

1. Input table containing a text column (input port, required): attach a CAS table to this port

2. Analytics project caslib (text field, required):  paste the location of your VTA project.  Here's how you find the location:
   1.   Open the project in Model Studio 
   2.  Navigate to the Data tab
   3. Copy the location from the properties menu (right-hand side).  Feel free to copy the entire string instead of just the \"Analytics_project...\" portion.

3. Model binary name (text field, required): paste the model binary filename here.  To identify the model binary, 
   1. Right-click on your Categories node and select Results.
   2. Copy the binary referred in the score code.

4. Unique ID (column selector, required): select the unique identifier for each observation in your table.

5. Text variable (column selector, required): select a character variable containing text you wish to analyze.

6. Actuals (column selector, required): select a column to serve as the basis for assessment (also known as  target, ground truth or category role).

### Output Specifications

This custom step creates a single output table and automatically promotes it to global scope. Promotion facilitates downstream analysis in SAS Visual Analytics. 

1.  Output table (output table port, required): attach a CAS table.  Note that you will obtain multiple observations per document ranging across candidate categories. 

2.  Promote to global scope (checked):  currently, the option to promote the output table is frozen.  Future versions may provide you the flexibility to choose whether to promote or not.

A selection of some important columns in the output table:

1. Category_Level: all candidate categories which are assessed
2. Record_Type: a flag indicating whether the record is a True Positive, False Positive, True Negative or a False Negative
3. Unique_ID: a new unique identifier variable  created for each observation in the output table to facilitate further discovery
4.  _match_text_: keywords contributing to the categories matched in the output table, to facilitate qualitative analysis

### Run-time Control

Note: Run-time control is optional.  You may choose whether to execute the main code of this step or not, based on upstream conditions set by earlier SAS programs.  This includes nodes run prior to this custom step earlier in a SAS Studio Flow, or a previous program in the same session.

Refer this blog (https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526) for more details on the concept.

The following macro variable,

```sas
_nctf_run_trigger
```

will initialize with a value of 1 by default, indicating an \"enabled\" status and allowing the custom step to run.

If you wish to control execution of this custom step, include code in an upstream SAS program to set this variable to 0.  This \"disables\" execution of the custom step.

To \"disable\" this step, run the following code upstream:

```sas
%global _nctf_run_trigger;
%let _nctf_run_trigger =0;
```

To \"enable\" this step again, run the following (it's assumed that this has already been set as a global variable):

```sas
%let _nctf_run_trigger =1;
```

IMPORTANT: Be aware that disabling this step means that none of its main execution code will run, and any  downstream code which was dependent on this code may fail.  Change this setting only if it aligns with the objective of your SAS Studio program.

## Documentation
1.  [Documentation on the textRuleScore.applyCategory action](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casvtapg/cas-textrulescore-applycategory.htm)

2. This custom step uses FedSQL to join CAS tables.  The dynamic cardinality feature proves useful for joins involving 3+ tables (also taking their size into consideration).  Thanks to Andy Therber, SAS, for details.  [Documentation.](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casfedsql/p0lrihvbn5xnfdn1a86poyhemp9f.htm)

3. Documentation on the [fedsql.execDirect action.](https://go.documentation.sas.com/doc/en/pgmsascdc/default/caspg/cas-fedsql-execdirect.htm)

4. From a use-case perspective, refer this (slightly old but still relevant) [SAS Communities article](https://communities.sas.com/t5/SAS-Communities-Library/Priming-the-pump-for-better-risk-assessment/ta-p/565370) for an example application. 

## Bonus: Templates for Visualization

The [extras](./extras/) folder provides instructions on how to import three SAS Visual Analytics page templates which will help you visualize and assess the output data.  Refer [here](/extras/Import%20Report%20Templates.md) for instructions.

### NLP Categories - Confusion Matrix

![NLP Categories - Confusion Matrix](./img/NLP%20Categories%20-%20Confusion%20Matrix.png)

### NLP Categories - Evaluation

![NLP Categories - Evaluation](./img/NLP%20Categories%20-%20Evaluation.png)

### NLP Categories - Coverage

![NLP Categories - Coverage](./img/NLP%20Categories%20-%20Coverage.png)

## SAS Program

Refer [here](./extras/NLP%20-%20Categories%20Testing%20Framework.sas) for the SAS program used by the step.  You'd find this useful for situations where you wish to execute this step through non-SAS Studio Custom Step interfaces such as the [SAS Extension for Visual Studio Code](https://github.com/sassoftware/vscode-sas-extension), with minor modifications. 


## Installation & Usage
- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).

## Created / contact : 

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)
- Renato Luppi (renato.luppi@sas.com)

## Change Log

* Version: 1.0  (03JAN2024)
  * Submitted to GitHub