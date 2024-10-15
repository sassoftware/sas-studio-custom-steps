/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   This block of code checks whether the user has selected a PDF from within the filesystem,
   and not from SAS Content. The name of the file is obtained and stored inside a macro 
   variable.
*------------------------------------------------------------------------------------------*/

%let storageType=%upcase(%scan("&fileName.",1,":"));

%if "&storageType."="SASSERVER" %then %do;
   data _null_;
      call symput("fileNamePDF",scan("&fileName.",2,":","MO"));
   run;
%end;
%else %do;
   %put ERROR:Select a PDF file from the filesystem.;
   data _null_;
      abort exit 4321;
   run;
%end;


/*-----------------------------------------------------------------------------------------*
   The following section contains Python code run within a proc python SAS procedure. For
   ease of readability, comments are not provided within the proc python submit- endsubmit 
   block.  
   
   In this section, values are extracted from the UI and used to call the read_pdf function 
   of tabula_py.  Arguments provided to the function include the file name, the page number,
   and the table number (counter).

   Upon extraction, the result (which is a pandas dataframe) is written to a specified SAS 
   output dataset using the inbuilt SAS method.

*------------------------------------------------------------------------------------------*/

proc python;
submit;

fileNamePDF=SAS.symget("fileNamePDF")
pageNumber=SAS.symget("pageNumber")
tableNumber=SAS.symget("tableNumber")
outputtable1=SAS.symget("outputtable1")
outputtable2=SAS.symget("outputtable2")

if not(tableNumber):
   SAS.submit("%put NOTE: No Table number specified.  The first identified table will be extracted.;")
   tableNumber=1

SAS.submit("%put NOTE: Table number : {};".format(tableNumber))

import tabula

if pageNumber:
   SAS.submit("%put NOTE: Page number : {};".format(pageNumber))
   table = tabula.read_pdf(fileNamePDF,pages=int(pageNumber))
   SAS.submit("%put NOTE: {} table(s) extracted;".format(len(table)))
   new_df=table[int(tableNumber)-1]
else:
   SAS.submit("%put NOTE: All tables to be extracted;")
   table = tabula.read_pdf(fileNamePDF,pages="all")
   SAS.submit("%put NOTE: {} table(s) extracted;".format(len(table)))
   new_df=table[int(tableNumber)-1]


if outputtable1:
   SAS.submit("%put NOTE: Output table : {};".format(outputtable1))
   ndf=SAS.df2sd(new_df,dataset=outputtable1)
   SAS.submit("%put NOTE: PDF table {} from page {} has been extracted and saved in {};".format(tableNumber,pageNumber,outputtable1))

table_dict={"table_number":[],"column_list":[]}
tnum=0

for eachDf in table:
   tnum=tnum+1
   table_dict["table_number"].append(tnum)
   table_dict["column_list"].append("|".join([col for col in eachDf]))

if outputtable2:
   SAS.submit("%put NOTE: Table containing column information : {};".format(outputtable2))
   import pandas
   allTableCols=SAS.df2sd(pandas.DataFrame(table_dict),dataset=outputtable2)
   

endsubmit;
quit;

