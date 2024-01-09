# SAS Content - Copy File from File System
==========================================

This custom step copies a file from the file system connected to SAS Viya Compute (also referred to as "shared storage" or the SAS server) to a target SAS Content folder location. SAS Content is implemented using the [SAS Viya Platform Files service](https://go.documentation.sas.com/doc/en/pgmsascdc/default/pgmgs/p1xx7ixqx0y1ldn1f7rkexhbol71.htm), and the files are maintained in the SAS Infrastructure Data Server database.

This facilitates operations where code and supporting files are sourced from the file system but are better suited for execution within SAS Content.  For example, users may access source code from GitHub or GitLab repositories.  

## General Idea
![SAS Content - Copy File from File System](./img/SAS_Content_Copy_Files_from_File_System.gif)

## Parameters

Note that this step only makes a copy of the file, and does not perform a cut (or move) operation. Source files continue to remain on the file system unless explicitly deleted.

This custom step also wraps proc http calls to a SAS Viya endpoint.  While it's likely that your environment's administrator has ensured the same, verify that north-south communication among pods is enabled / whitelisted in your environment.  Proc http won't work for Viya endpoints (though they may for other endpoints) in such a case.  Viya may consider the SAS Studio session pod IP (which is making the call) as not recognizable and therefore timeout the request.  A quick check for this would be to run a simple proc http call (e.g. a get request) to your SAS Viya endpoint and note if you are able to get a response code of 200 (OK).


### Input Parameters

1. **Source file from file system** (file selector, required): specify the full path of a file to be transferred to SAS Content.  Note this custom step makes use of the same file name when saving to SAS Content.

2. **Target folder in SAS Content** (folder selector, required): select a folder inside SAS Content.  

### Output Specifications

The custom step provides a note informing that the file has been transferred. 

In addition,  additional macro variables are created to facilitate downstream tasks.

1. **targetFolderURI** (global macro variable): this macro variable is created to hold the URI of the new folder for any downstream activity.

2. **contentFolderExists** (global macro variable): this macro variable has a value of 1 if the SAS Content folder exists, a value of 0 in case it is not found, and 99 in case of other errors encountered during the check.  Downstream code may consume these values.


## Optional: Run-time Control

Note: Run-time control is optional.  You may choose whether to execute the main code of this step or not, based on upstream conditions set by earlier SAS programs.  This includes nodes run prior to this custom step earlier in a SAS Studio Flow, or a previous program in the same session.

Refer this blog (https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526) for more details on the concept.

The following macro variable,

```sas
_cff_run_trigger
```

will initialize with a value of 1 by default, indicating an "enabled" status and allowing the custom step to run.

If you wish to control execution of this custom step, include code in an upstream SAS program to set this variable to 0.  This "disables" execution of the custom step.

To "disable" this step, run the following code upstream:

```sas
%global _cff_run_trigger;
%let _cff_run_trigger =0;
```

To "enable" this step again, run the following (it's assumed that this has already been set as a global variable):

```sas
%let _cff_run_trigger =1;
```

IMPORTANT: Be aware that disabling this step means that none of its main execution code will run, and any  downstream code which was dependent on this code may fail.  Change this setting only if it aligns with the objective of your SAS Studio program.


## Documentation

1. [SAS Documentation on the fcopy() function used for copying files](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lefunctionsref/n10dz22b5ixohin1vwzilweetek0.htm)

2. Documentation for the [SAS Viya Platform Files service](https://go.documentation.sas.com/doc/en/pgmsascdc/default/pgmgs/p1xx7ixqx0y1ldn1f7rkexhbol71.htm).

3. [SAS Communities article](https://communities.sas.com/t5/SAS-Communities-Library/Making-SAS-programs-stored-on-the-file-system-available-to-SAS/ta-p/525688) by Gerry Nelson which provides an example based on the fcopy() function which is used in this step. 

4. [Reference macro from Bruno Mueller](https://blogs.sas.com/content/sasdummy/files/2013/09/binaryfilecopy.sas_.txt) which provides another approach for transferring binary files.

5. Note this [section within the documentation](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lestmtsglobal/p0qapul7pyz9hmn0zfoefj0c278a.htm#p0nscb67k9xhr5n1fqx4pvnoed4f) on the filesrvc filename reference method.  Note that the filesrvc filename reference results in an automatically generated macro variable containing the URI, which is in fact used within this custom step.  However, the direct use of the filesrvc reference on a non-existent folder results in an error, which is handled by this custom step.  

6. The 'proc http' sections of this steps inspired by similar code by David Weik for the purpose of transferring custom steps.  His full code is located [here](https://github.com/Criptic/sas_snippets/blob/master/Upload-and-Register-all-Custom-Steps.sas)

7. [Identify whether a fileref exists](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lefunctionsref/p0b6qacxrmnzc4n145t9jps0yzdc.htm) 

8. [Details on the optional run-time trigger control](https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526)


## SAS Program

Refer [here](./extras/SAS%20Content%20-%20Copy%20File%20from%20File System.sas) for the SAS program used by the step.  You'd find this useful for situations where you wish to execute this step through non-SAS Studio Custom Step interfaces such as the [SAS Extension for Visual Studio Code](https://github.com/sassoftware/vscode-sas-extension), with minor modifications. 

## Installation & Usage

- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).


## Created/contact: 

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)

Also, thanks to the following (SAS) colleagues whose earlier work helped in the creation (and future direction) of this step.

- Bruno Mueller 
- Gerry Nelson 
- David Weik 
- Bo Bistrup 


## Change Log

* Version: 1.01  (09JAN2024)
  * README and About tab edits including references to the file system

* Version: 1.0  (02JAN2024)
  * Version submitted to GitHub

* Version: 0.1  (07DEC2023)
  * Initial version
