# Get CAS Library Name 

## Background

In certain scenarios your custom step code generator might want to directly invoke a CAS action using proc cas when the selected input table is a CAS table.

As a custom step always uses SAS Compute, the inputtable and outputtable UI controls in a custom step return the selected table as **libref.tablename**. 

The code generator then first needs to check whether the libref points to a caslib, and then check which caslib that is. This because the CAS action only understands about caslib names and not about SAS Compute libraries. And you cannot guarantee that the libref used by the libname points to a caslib with the exact same name.

Here is an example showing libname **casdata** pointing to caslib **mydat42**:
 ![](Compute%20and%20CAS%20-%20libname%20vs%20caslib%20-%20highres.png)

Now assume the user has selected table **casdata.class_castable** in your custom step for an input table control named **inputtable1**. 

TODO: Add screenshot here

This would result in the following SAS macro variables being generated:
```sas
/* Macro variable(s) for UI control with ID of inputtable1 */
%let inputtable1=CASDATA.CLASS_CASTABLE;
%let inputtable1_engine=CAS;
%let inputtable1_label=;
%let inputtable1_lib=CASDATA;
%let inputtable1_name=CLASS_CASTABLE;
%let inputtable1_name_base=CLASS_CASTABLE;
%let inputtable1_tblType=table;
%let inputtable1_type=dataTable;
```

You would use the inputtable1 **_engine** macro variable and check its value. If its value is "CAS" then use data step function **getlcaslib** ([SAS Documentation link](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lefunctionsref/p0wma0o1tqtwein160lshpt672fl.htm)) to retrieve the caslib name associated with the libref provided in macro variable **inputtable1_lib**

Here is a code sample: 

```sas
%if "%upcase(&inputtable1_engine)"="CAS" %then %do; 
   %let _usr_inputtable1_caslib=%sysfunc(getlcaslib(&inputtable1_lib)); 

   proc cas;
      action table.tableInfo / caslib="&_usr_inputtable1_caslib" name="&inputtable1_name";
   run;
%end;
%else %do;
   data _null_;
      putlog "ERROR: The selected input library does not point to a CASlib";
      abort;
   run;
%end;
```

***Notes***: 
 * The code above uses a PUTLOG statement to write an error message to the SAS log in case the pre-conditions for this custom step
   have not been met and then stops flow execution using the abort statement. See [Programatically stop Flow execution](./Programmatically-Stop-Flow-Execution/README.md) for more details.
 * See [PUT Statement - Arguments: Log Output Controls in SAS Documentation](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lestmtsref/n1spe7nmkmi7ywn175002rof97fv.htm#p0tnlpfud6rh6bn1s1ut67aq4bzx) for more details about using "ERROR:" in a put/putlog statement.
 * In SAS Studio releases before 2022.12 the ***_engine*** variable was not created for all engines (like the SAS Base engine), so you would have to use symexist("inputtable_engine") first and if this returns true, only then retrieve the value of the *_engine macro variable. Otherwise, you would get runtime errors for when the user has selected a table in say a Base SAS library. 


---
## DEPRECATED: Old approach using SAS dictionary tables
---
<details>
   <summary>Click here to show details...</summary>
   
```sas
proc sql;
   select sysvalue from dictionary.libnames
       where upcase("<libname-goes-here>") and upcase (sysname)="CASLIB";
quit;
```

The macro [_usr_getNameCaslib](_usr_getNameCaslib.sas) takes care of this.

Here is some sample code you could use for a custom step that runs the table.tableInfo action in case the input table is a CAS table.
```sas
/* SAS templated code goes here */

/*----------------------------------------------------------------*
   This custom step uses an Input Table control named inputtable1,
   and requires a CAS table as input.
 *----------------------------------------------------------------*/

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname=upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;

%if "%upcase(&inputtable1_engine)"="CAS" %then %do; 
   %_usr_getNameCaslib(&inputtable1_lib);

   proc cas;
      action table.tableInfo / caslib="&_usr_nameCaslib" name="&inputtable1_name";
   run;
%end;
%else %do;
   %put ERROR: The selected input library does not point to a CASlib;
%end;
```
</details>
