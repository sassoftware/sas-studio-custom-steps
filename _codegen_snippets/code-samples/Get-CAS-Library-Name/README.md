# Get CAS Library Name 

## Background

In certain scenarios as a custom step author, you might want to know whether a selected table lives in a CAS Library and if so, which library that is. As a custom step always uses SAS Compute, the inputtable and outputtable UI controls in a custom step return the selected table as **libref.tablename**. 

A typical use case is where you want to invoke a CAS action if the selected table is a CAS table. In this case your code needs to know what the **caslib** is that is associated with that table, as CAS actions require the caslib name. You cannot guarantee that the libref used by the libname that points to a caslib with the exact same name. 

Here is a  picture that tries to illustrate this:
 ![](Compute%20and%20CAS%20-%20libname%20vs%20caslib%20-%20highres.png)

This example shows a libname **casdata** that points to caslib **mydat42**. If your SAS code then wants to execute a CAS action when the selected table is a CAS table, your code generator needs to know which caslib is being used by the libname. This because the **caslib=** parameter of a CAS action only understands about caslib names and not about libnames.

***Note***:
In SAS Studio releases before 2022.12 the ***_engine*** variable was not created for all engines (like the SAS Base engine), so you would have to use symexist("inputtable_engine") first and if this returns true, only then retrieve the value of the *_engine macro variable. Otherwise, you would get runtime errors for when the user has selected a table in say a Base SAS library. 

(**31JUL2024**) The data step function getlcaslib ([doc link here](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lefunctionsref/p0wma0o1tqtwein160lshpt672fl.htm)) allows you to retrieve the caslib name associated with a libref that uses the CAS engine. So no need to use SAS dictionary tables for this. Btw. this function has existed for at least a couple of years. 

If the libname points to a caslib then you can use the SAS dictionary tables to retrieve the name of the associated caslib.

Here is some sample code you could use for a custom step that checks the selected table is a CAS table using the **getlcaslib** data step function and then runs the table.tableInfo action (UI control is named ***inputtable1)***:
 

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

***Note***: The code above uses a PUTLOG statement to write an error message to the SAS log in case the pre-conditions
for this custom step have not been met. The SAS Studio framework scans the log and puts nodes in the flow in error
status when it encounters "ERROR:" and shows that message when the user hovers their mouse over the step in the flow.
See section [PUT Statement - Arguments: Log Output Controls](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lestmtsref/n1spe7nmkmi7ywn175002rof97fv.htm#p0tnlpfud6rh6bn1s1ut67aq4bzx) for more details.


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