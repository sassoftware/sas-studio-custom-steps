# Report Lineage

## Description

This custom step extracts lineage information from a SAS Visual Analytics report. The mentioned lineage starts with the CAS librar(y)(ies) and follows the CAS table(s), the CAS table columns, the report columns, the calculated columns and the use of the report/calculated columns in the different report objects.

## SAS Viya Support

Created and tested on Viya 4, Stable 2023.05

## Potential issue

When the JSON format for a SAS VA report changes, it might be possible that this custom step needs to be updated.

## Typical usage

This custom step generates the lineage for 1 report. The output can be stored in your data warehouse and/or be stored directly in CAS to create a report on.

Note that this custom step is able to run under the control of the [Loop Deployed Object](../Loop%20Deployed%20Object/README.md) custom step to generate the report lineage for more than one report at a time.

# User Interface

## Tab: Report Lineage Properties

![Properties](img/UI_Properties.PNG)

- **Select report**: Here you can select the report for which you want to generate the lineage.

Note that: 
- Make sure that, in case of using the [Loop Deployed Object](../Loop%20Deployed%20Object/README.md) custom step, the macro variable as specified in the flow that contains the [Loop Deployed Object](../Loop%20Deployed%20Object/README.md) custom step, needs to be used as shown below, where you can ignore the red cross. After that you can deploy the flow as a job to make it available to the [Loop Deployed Object](../Loop%20Deployed%20Object/README.md) custom step.
- The macro variable, 'reportPath', is just an example.

![macro variable](img/UI_Properties_01.PNG)

## Tab: About
![About](img/UI_About.PNG)

## Usage

Download the .step file, upload it into your environment and start using it, for example, as shown:

![usage](img/Usage_01.PNG)

In this simple example, the output of the report lineage custom step is directly append, by the 'Load to CAS' custom step, into a CAS table to build a report on.

Note that the flow shown can be used by the [Loop Deployed Object](../Loop%20Deployed%20Object/README.md) custom step.

## Output port

The custom step has one output table with the following information:
![output](img/Output%20port.PNG)

## Change Log

Version 1.2 (08APR2024) : Added UTF8 support and first public release.

Version 1.1 (08AUG2023) : Code with additional functionality, added by Michael Herrmann, has been merged and tested.

Version 1 (18JUL2023)   : Initial version.