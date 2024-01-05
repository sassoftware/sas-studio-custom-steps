# Python - Load Objects to SAS

The Python - Load Objects to SAS custom step enables you to load different Python objects from a Python session to corresponding objects in SAS Viya.

The following are some examples of the major object types handled:

1.  Pandas dataframes ==> CAS tables / SAS datasets 
2.  Standard Python objects (int, str etc.) ==> SAS macro variables
3.  Lists ==> CAS tables / SAS datasets
4.  Dicts ==> CAS tables / SAS datasets

**Why go to this trouble?**  

In a unified, integrated pipeline, once your Python program has done its job,  you can transfer desired data objects to a SAS Viya in-memory environment for more performant compute.  At the same time, you can easily free up memory taken up by these objects within Python.


## A general idea (the below is an animated gif)

![Load objects to SAS](./img/Python%20-%20Load%20Objects%20to%20SAS.gif)

## Wait!  What about the SAS object in Proc Python? 

Yes, the SAS.df2sd callback object in proc python accomplishes something similar.  By all means, continue to use SAS callback methods if you're comfortable with the same.  

SAS.df2sd is based on the premise of transferring Pandas dataframes over to SAS datasets (i.e. sas7bdat).  This custom step extends similar functionality to other data objects - Python lists, dicts, and even simple objects (ints or strings), directly to targets in SAS Cloud Analytics Services (CAS).

It's a convenient, low-code interface and where required, uses the SAS callback object and the CAS-centric swat package.

A bonus: there's also an option to easily delete Pandas dataframes after they've served their purpose, and free memory.  Very useful for those of us who curse memory limits while forgetting to clean up after ourselves....


## SAS Viya Version Support
Tested in Viya 4, Stable 2023.08


## Requirements

SAS Viya environment 2023.08 or later.  Ensure:

1. SAS Viya has access to an active Python environment.  Proc Python makes use of this Python environment.

2. Required Python packages (see section "Python packages required") are installed.

3. Preferable / recommended:  Administrators could make use of the SAS Configurator for Open Source (also commonly known as sas-pyconfig) to install and configure Python access from SAS Viya.  Refer SAS Viya Deployment Guide (monthly stable 2023.08 onwards) for instructions on the same. Documentation provided below.


### Python packages required

This custom step requires Python (through proc python)  to be enabled inside SAS compute and makes use of the following Python packages: 

1. swat
2. pandas

Refer documentation link below for package details.

## Parameters:

### Input parameters:

You can select your desired option, and fill up the corresponding field:

1. Name of Pandas dataframe (text box): enter the name of a Pandas dataframe which has been referred in upstream Python code.

2. Name of standard Python objects (text box): enter any "variable" names (strictly, Python does not have variables, and therefore we refer to them as objects) for integer or string values, which you wish to continue using in downstream SAS code as macro variables.

3. Name of Python list (text box): enter the name of a Python list which you have used in upstream Python code.  Note that this list object would be converted to a Pandas dataframe and then transferred to a SAS dataset / CAS table.

4. Name of Python dict (text box): enter the name of a Python dict which you have used in upstream Python code.  Note that this dict object would be converted to a Pandas dataframe and then transferred to a SAS dataset / CAS table.


### Output specifications:

1. Output table (output port, optional):  select / attach a table to this output port, which can either be a SAS dataset or a CAS table.

Note that where available, an existing CAS session will be used as the local scope (context) for the output table.  In case you have chosen to promote this table, it will be made available globally.  In case a CAS session is not available, Python establishes a new connection to CAS and transfers the table.  Therefore, be mindful of the correct CAS session in order to locate this table. 

2. Delete Pandas dataframe after load (checked by default, optional, conditional upon Pandas dataframe selection):  Keep this checked in order to free memory, on the assumption that you'll now use the CAS table and don't require the Pandas dataframe any longer.

3. Promote CAS table to global scope (check box, optional, conditional upon Pandas dataframe, list, or dict selection):  check this only if you have chosen to transfer the Python object to a CAS (and not a sas7bdat) table,  and if you wish for this table to be made available for all users of the caslib.

4. SAS macro variable name (text box, required for standard Python object selection): provide a name of a corresponding SAS macro variable to hold the values of a Python object (int, string etc.) you wish to transfer.

5. Desired name for list column in output table (text box, required for list selection): provide a name which will be used as the column name for the output SAS object containing the list (in table form).  The name should conform to SAS / CAS column naming conventions, as applicable.

### Configuration 

1. CAS server hostname (text box, default applied, modifiable): If you've chosen a CAS table as your output, this field is used to establish a connection to the CAS server.

2. CAS server port (numeric field, default applied, modifiable): If you've chosen a CAS table as your output, this field is used to establish a connection to the CAS server


## Documentation:

1. [Here's](https://sassoftware.github.io/python-swat/) documentation on the swat package. 

2. [Here's](https://go.documentation.sas.com/doc/da/pgmsascdc/default/proc/p0z7ahqmabxu6kn193kdojjhc477.htm) documentation on the SAS callback object and methods.  

3. [Here's](https://pypi.org/project/pandas/) documentation on the Pandas package. 

4. [Scott McCauley's SAS Communities article](https://communities.sas.com/t5/SAS-Communities-Library/Configuring-SAS-Viya-for-Python-Integration/ta-p/847459) on configuring Viya for Python integration.

5. The [SAS Viya Platform Deployment Guide](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/p1n66p7u2cm8fjn13yeggzbxcqqg.htm?fromDefault=#p19cpvrrjw3lurn135ih46tjm7oi) (refer to SAS Configurator for Open Source within). 

6. This [SAS Communities article](https://communities.sas.com/t5/SAS-Communities-Library/Hotwire-your-SWAT-inside-SAS-Studio/ta-p/835956) provides details on the environment variables which facilitate connecting to CAS using the swat package within SAS Studio. 

7. Peter Styliadis provided this [helpful post ](https://communities.sas.com/t5/SAS-Viya/Programmatically-detect-an-active-CAS-session/m-p/890914#M1985) (SAS documentation link contained therein) on how to identify a current active CAS session. 


## Installation & Usage
- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).


## Created / contact : 

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)


## Change Log

Version 1.0 (01SEP2023) 
* Initial Step Creation

