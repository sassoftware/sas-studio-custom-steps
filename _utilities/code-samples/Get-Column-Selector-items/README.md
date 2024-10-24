# Get Column Selector Items

## Background

A column selector control allows for the selection of one or more columns, depending how the custom step author configured the control.

The custom step framework generates various macro variables for each selection in this control. Details can be found in the [Understanding Macro Variables](https://go.documentation.sas.com/doc/en/sasstudiocdc/default/webeditorcdc/webeditorsteps/n1nmkkmrxrohysn1t7n9y66l0awv.htm) section of the SAS Studio with SAS Viya Programming documentation.

Depending on how you want to use the list of selected variables your code generator might need a slightly different format for the list of items. Most likely you need a list that is blank separated. But when the list is needed in (proc)SQL, the list would need to comma-separated, and when the list is used in CAS action calls, the values need to be enclosed in quotes and separated by blanks and the complete list needs to be surrounded by curly braces.

Example:
The user has selected the columns named ***name***, ***age***, and ***height*** in a column selector.
```SAS
%let blankSeparatedList=name age sex;
%let commaSeparatedList=name,age,sex;
%let CASLstyleList={"name","age","sex"};
```

When the column names contain special characters, SAS Compute syntax requires the use of [SAS Name Literals](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lepg/p0z9rbr2w2vtd1n1q8lty9b13iv3.htm). However, CASL does not use SAS Name Literals. So when the user has selected columns named ***a&b***, ***c d***, and ***e;f*** in a column selector, the column lists would look something like this:
```SAS
%let blankSeparatedList='a&b'n "c d"n "e;f"n;
%let commaSeparatedList='a&b'n,"c d"n,"e;f"n;
%let CASLstyleList={'a&b','c d', 'e;f'};

```

The SAS Studio custom step framework automatically generates the macro ***_flw_get_column_list*** that you can use to a generate blank-separated list or a comma-separated list. You can see how these macros are defined as folows: Create a Flow and use a custom step that has a column selector control, generate code for the flow, and in the generated code expand the section shown as ***region: Generated macro initialization***. 

If the name/ID of the column selector was ***columnListInputTable***, then you could use the following SAS code in your code generator:
```SAS
/*--------------------------------------------------------------------------------------------------------------------------------------*
   Since release 2022.12, the macro variable associated with the ID of the column selector contains the blank separated list of columns. 
   So from that release onwards, calling the _flw_get_column_list macro is only needed when you need a comma separated list.
 *--------------------------------------------------------------------------------------------------------------------------------------*/

%let blankSeparatedOld=%_flw_get_column_list(_flw_prefix=columListInputTable);
%let blankSeparated=&columnListInputTable; /* This requires 2022.12 or later */
%let commaSeparated=%_flw_get_column_list(_flw_prefix=columListInputTable, _delim=%str(,));
```
If you need a list of columns that uses syntax that is needed by CAS action parameters, meaning column names without using SAS Name Literals, enclosed in double quotes, separated by commas, and the whole string inside curly brackets, then you can use the ***_flw_get_column_list_CASL_syntax*** macro that is provided in this folder. 

The macro definition is stored in [_flw_get_column_list_CASL_syntax.sas](./_flw_get_column_list_CASL_syntax.sas). It is a
slight adaptation of the ***_flw_get_column_list*** macro and uses the Custom Step framework generated macro varaible that represents how many selections were made, and for each selection a set of macro variables is generated that represent the various properties of the column.
