## How to install a newer version of a Custom Step that has become available in this repository?

Download the **.step** file, and upload it to the same location in your SAS Content folder where you stored the previous version.

|***Some background info***|
|---|
| When you have flows that are using custom steps that are stored in SAS Content, the flow uses a UUID to reference the custom step. When uploading a newer version of the .step file (name unchanged), upload it to the folder in SAS Content that contains the older version, and when asked whether you want to overwrite it, select **yes**. This will maintain the existing UUID of the previous version, and your existing flows should still be able to resolve the reference to the custom step. |

|***Note on UI behaviour when opening a Flow that references Custom Steps that have been updated***|
|---|
| On opening flows that reference custom steps that have been updated, a notification is shown explaining that some of the custom steps being used in the flow have been updated. All custom step nodes in the flow diagram that reference updated steps will show an exclamation mark overlay, and the user needs to click on those nodes to trigger a refresh and overlay to disappear. Depending on the change(s) in the custom step definition, the user will have to open the node in the flow and take actions. For example to provide values for newly added required elements in the UI. |

## How to share SAS macro definitions across multiple Custom Steps?

In this scenario you have multiple custom steps that all use the same SAS macro(s) and don't want to have to maintain the SAS macro definition(s)
in multiple places, or perhaps you want to manage the SAS macro definition using Git as well and when they are updated have them being used by
your custom steps automatically. 

A common approach is to extract the SAS macro definition(s) into its own file(s), and store the files(s) in a so called SAS autocall macro library.
This is a directory containing individual files, each of which contains one SAS macro definition. That directory can live on a file system
accessible by the SAS Compute Server or live in a folder in SAS Content.

Once you have put the SAS macro definitions in separate files and stored them in a directory or in a folder in SAS Content, then the SAS session needs to be made aware of this location. 

Here is a code snippet showing how to make the SAS session aware of SAS macro definitions are stored in a SAS Content folder: 
```SAS
/* Extend the search path for SAS autocall library to use SAS Content folder */
filename mymacr filesrvc folderpath="/Public/SASMacros";
options sasautos=(sasautos, mymacr) mautosource mcompilenote=all mrecall;
```

And here is a code snippet for when the SAS macro definitions are stored on a file system:
```SAS
/* Extend the search path for SAS autocall library to use a directory on disk */
filename mymacr "/nfs/SASMacros";
options sasautos=(sasautos, mymacr) mautosource mcompilenote=all mrecall;
```

A SAS administrator wculd then use SAS Environment Manager to add these statements to the **autoexec** of the **SAS Studio Compute context**, which makes these SAS macros available to **all users** of that context. The autoexec option is found in the Advanced tab of the Compute context. 

An individual user could add these statements to **their autoexec** in **SAS Studio**, using **Options -> Autoexec file** from the pulldown menu, so they run each time that user starts SAS Studio.

For more details on defining **autoexec** see the following entries in SAS documentation:
* [Context page in SAS Environment Manager](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=evfun&docsetTarget=p1dkdadd9rkbmdn1fpv562l2p5vy.htm)
* [Editing the Autoexec File in SAS Studio](https://documentation.sas.com/?cdcId=webeditorcdc&cdcVersion=default&docsetId=webeditorug&docsetTarget=n1rxiyysdwthokn1c9szd5175pmh.htm)

More details about **SAS Autocall libraries** can be found in
**SAS Macro Language Reference Guide**, see [SASAUTOS= Macro System Option](https://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=default&docsetId=mcrolref&docsetTarget=p12b2qq72dkxpsn1e19y57emerr6.htm)

## How to easily transfer a Flow and a Custom Step to another SAS Viya environment?

If both the flow and the custom step it uses are stored in the same folder in SAS Content on the source environment, you can create
a so called **export package** that contains both items. This can be done using the **transfer-plugin to the SAS Viya CLI** or using 
the Export option available from the Content page in SAS Environment Manager.

In the target deployment you would use that same **CLI** or use **SAS Environment Manager** to import the package.

More details can be found in [Migration within SAS Viya: Tasks](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calpromotion&docsetTarget=n0ucexhkgs4rfgn12219vojr14nf.htm)

## What sample data is available for use in SAS Studio in a SAS Viya deployment?

1. The sashelp library - available in each SAS Studio session 
2. The sampsio library - a lesser known collection of SAS sample data that is available in every SAS Viya deployment
     - This library is not visible by default in the Libraries panel in SAS Studio. Here is how to make this library available in SAS Studio:
         * Open SAS Program using New -> SAS Program from the main menu
         * Run the following SAS code to get a listing of all the SAS datasets in the sampsio sample library that should be part of a default SAS deployment
           ```sas
           proc datasets library=sampsio; run;
           ```
         * This will display a list of tables in the Results window and will make the library sampsio available in the Libraries panel for your current SAS Studio session
         * TIP: Watch this [SAS Sample Data for Forecasting](https://www.youtube.com/watch?v=wX6mdBgYmXo&t=271s) recording on Youtube for more pointers to interesting sample data available from SAS
