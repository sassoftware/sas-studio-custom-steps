* -----------------------------------------------------------------------------;
* Export SAS dataset to Parquet;
*;
* SAS Viya LIBNAME Engines for ORC and Parquet: Reference;
* https://go.documentation.sas.com/doc/en/pgmsascdc/default/enghdff/titlepage.htm;
* -----------------------------------------------------------------------------;

* Print macro variables passed from custom step;
/*
%put NOTE: &=inTable;
%put NOTE: &=folder;
%put NOTE: &=deleteIfExists;
%put NOTE: &=partition_type;
%put NOTE: &=partition_by;
%put NOTE: &=file_name_extension;
%put NOTE: &=compress;
%put NOTE: &=exportCharAsString;
*/

* -----------------------------------------------------------------------------;
* Parse the folder value to get the path;
* -----------------------------------------------------------------------------;

data _null_;
  if index("&folder",":")>0 then do;
    store=scan("&folder",1,":");
    if store="sasserver" then do;
      * OK - User used Folder Selector Control to choose sasserver folder;
      errorFlag=0;
      call symput("folderLoc",scan("&folder",2,":"));
    end;
    else if store="sascontent" then do;
      * Error - User used Folder Selector Control to choose sascontent folder;
      errorFlag=1;
    end;
  end;
  else if substr("&folder",1,1)="/" then do;
    * User manually entered path;
    errorFlag=0;
    call symput("folderLoc","&folder");
  end;
  else errorFlag=1;
  call symput("errorFlag",trim(put(errorFlag,4.-l)));
run;

%if &errorFlag %then %do;
  %put ERROR: The export folder must be on the file system, not in SAS Content.;
%end;
%else %do;
  *%put NOTE: &=folderLoc;
%end;

* -----------------------------------------------------------------------------;
* Delete existing folders / files;
* -----------------------------------------------------------------------------;

%if &errorFlag=0 %then %do;
proc python;
submit;
import os
import shutil

# Get SAS macro variables
folderLoc = SAS.symget('folderLoc')
deleteIfExists = int(SAS.symget('deleteIfExists'))
inTable_name = SAS.symget('inTable_name').lower()
partition_type = SAS.symget('partition_type')
file_name_extension = SAS.symget('file_name_extension')

# Set target file / folder flag exists to 0
targetExists = 0

if partition_type in ('DIRECTORY', 'FILENAME', 'HIVE'):
  # Delete folder-based data
  fname = f'{folderLoc}/{inTable_name}'
  if os.path.isdir(fname):
    if deleteIfExists == 1:
      shutil.rmtree(fname)
      print(f'Deleted folder {fname}')
    else:
      targetExists = 1
elif partition_type in ('None'):
  # Delete file-based data
  fname = f'{folderLoc}/{inTable_name}.{file_name_extension}'
  if os.path.exists(fname):
    if deleteIfExists == 1:
      os.remove(fname)
      print(f'Deleted file {fname}')
    else:
      targetExists = 1

# Create SAS macro variable with target file / folder exists flag
rc = SAS.symput('targetExists',str(targetExists))

endsubmit;
run;
%end;
%else %do;
  %let targetExists=0;
%end;

*%put NOTE: &=targetExists;
%if &targetExists %then %do;
  * If the export file / folder exists, stop further processing;
  %put ERROR: Export file / folder exists. Check the 'Delete output data if it already exists' box or delete manually.; 
  %let errorFlag=1;
%end;
*%put NOTE: &=errorFlag;

* -----------------------------------------------------------------------------;
* Create LIBNAME statement options;
* -----------------------------------------------------------------------------;

data _null_;
  attrib liboptions length=$128;
  liboptions="compress=&compress";
  if "&partition_type"="None" then do;
    liboptions=trim(liboptions)!!" file_name_extension=(&file_name_extension)";
  end;
  call symput("libOptions",trim(left(liboptions)));
run;
*%put NOTE: &=libOptions;

* -----------------------------------------------------------------------------;
* Create Data Set options;
* -----------------------------------------------------------------------------;

* If SAS characters are to be converted to Parquet STRING logical type;
%if &exportCharAsString %then %do;
  * Get count of character columns in SAS dataset;
  proc sql noprint;
    select count(*) into: nCharColumns
    from dictionary.columns
    where libname="&inTable_lib" and memname="&inTable_name" and type="char";
  quit;
  
  * Create data set DBTYPE option syntax to set Parquet logical type to STRING;
  proc sql noprint;
    select trim(name)!!"=string" into: dbtype separated by " "
    from dictionary.columns
    where 
      libname="&inTable_lib" and 
      memname="&inTable_name" and
      type="char";
  quit;
%end;
%else %do;
  %let nCharColumns=0;
  %let dbtype=;
%end;
*%put NOTE: &=nCharColumns;
*%put NOTE: &=dbtype;

* Create dataset options for export;
data _null_;
  attrib dsoptions length=$16384;
  * PARTITION_TYPE and PARTITION_BY options;
  if "&partition_type" ne "None" then do;
    dsoptions=trim(dsoptions)!!"partition_type=&partition_type";
    if "&partition_by" ne "" then do;
      dsoptions=trim(dsoptions)!!" partition_by=(&partition_by)";
    end;
  end;
  * DBTYPE option;
  if &exportCharAsString and &nCharColumns>0 then do;
    dsoptions=trim(dsoptions)!!" dbtype=(&dbtype)";
  end;
  * Combine PARTITION_TYPE, PARTITION_BY and DBTYPE options into a;
  * single dsoptions macro variable;
  if dsoptions ne "" then do;
    call symput("dsOptions","("!!trim(left(dsoptions))!!")");
  end;
  else do;
    call symput("dsOptions"," ");
  end;
run;
*%put NOTE: &=dsOptions;

* -----------------------------------------------------------------------------;
* Export SAS dataset to Parquet;
* -----------------------------------------------------------------------------;

%if &errorFlag=0 %then %do;

* Create a temporary libname for the export;
*libname _pqt_ parquet "&folderLoc" compress=&compress file_name_extension=(&file_name_extension);
libname _pqt_ parquet "&folderLoc" &libOptions;
%put NOTE: Use this libname syntax to read exported Parquet; %put NOTE: libname mypqt parquet "&folderLoc" &libOptions%str(;);

* Do the export;
data _pqt_.%lowcase(&inTable_name) &dsOptions;
  set &inTable;
run;

* Clear the libname;
libname _pqt_ clear;

%end;

* -----------------------------------------------------------------------------;
* Get exported Parquet file's metadata;
* -----------------------------------------------------------------------------;

%if &errorFlag=0 %then %do;
proc python;
submit;

try:
  import pyarrow.parquet as pq
except:
  print('NOTE: PyArrow module not available, unable to report Parquet metadata')
else:
  # Get SAS macro variables
  folderLoc = SAS.symget('folderLoc')
  partition_type = SAS.symget('partition_type')
  file_name_extension = SAS.symget('file_name_extension')
  inTable_name = (SAS.symget('inTable_name')).lower()
  
  if partition_type in ('DIRECTORY', 'FILENAME', 'HIVE'):
    fname = f'{folderLoc}/{inTable_name}'
  elif partition_type in ('None'):
    fname = f'{folderLoc}/{inTable_name}.{file_name_extension}'
  
  ParquetDataset = pq.ParquetDataset(fname, use_legacy_dataset=False)
  
  print('-- Parquet schema:')
  print(ParquetDataset.schema)
  
  print('-- Parquet file(s):')
  for file in ParquetDataset.files:
    print(file)

endsubmit;
run;
%end;

* -----------------------------------------------------------------------------;
* Delete macro variables;
* -----------------------------------------------------------------------------;

%if %symexist(errorFlag) %then %do;
  %symdel errorFlag;
%end;
%if %symexist(folderLoc) %then %do;
  %symdel folderLoc;
%end;
%if %symexist(targetExists) %then %do;
  %symdel targetExists;
%end;
%if %symexist(libOptions) %then %do;
  %symdel libOptions;
%end;
%if %symexist(dsOptions) %then %do;
  %symdel dsOptions;
%end;
%if %symexist(nCharColumns) %then %do;
  %symdel nCharColumns;
%end;
%if %symexist(dbtype) %then %do;
  %symdel dbtype;
%end;

* -----------------------------------------------------------------------------;