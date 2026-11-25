* Download the Google Sheet as a csv file to work;
filename sheet "%sysfunc(getoption(WORK))/sheet.csv";
proc http
	url="https://docs.google.com/feeds/download/spreadsheets/Export?key=&sheetID.%str(&)exportFormat=csv%str(&)gid=&gid."
	out=sheet;
run;

* Check HTTP response code and notify the user accordingly;
data _null_;
	if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
    	putlog 'ERROR: Google Sheet could not be downloaded';
  	end;
  	else putlog 'INFO: Google Sheet was successfully downloaded';
run;

* Import the csv file;
proc import
 	file=sheet
	out=&outputtable1.
	dbms=csv
	replace;
	guessingrows=&guessingrows.;
run;

* Clean up;
%let rc = %sysfunc(fdelete(sheet));
%symdel rc;
filename sheet clear;