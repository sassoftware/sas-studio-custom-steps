/* --------------------------------------------------------------------------*
 TODO list:
   - Cleanup SAS macros and SAS macro variables at the end of the step
   - _template.step provides sample code snippets for these cleanup routines
 * --------------------------------------------------------------------------*/

/* **************************************** */
/*             INPUT NEW PROMPT             */
/* **************************************** */

* Specify source of your query input = 'Use a table';
* (E.g. &queryInputChoice. = 'table');
%macro useQueryTable();
	proc sql noprint;
	    create table work.txt001 as
		    select &queryColumn. as txt length=32767
	            from &queryTable. (keep=&queryColumn.);
	quit;
%mend useQueryTable;

* Specify source of your query input = 'Enter manually';
* (E.g. &queryInputChoice. = 'enter');
%macro createQueryTable(name, keepCol);
	proc sql noprint;
		create table &name. (&keepCol. char(32767));
			insert into &name.
			    set &keepCol. = %nrstr("&queryText.");
	quit;
%mend createQueryTable;

* Specify source of your prompt input = 'Custom prompt';
* (E.g. &promptInputChoice. = 'custom');
%macro createPromptTable(name,keepCol);
	proc sql noprint;
		create table &name (&keepCol. char(32767));
			insert into &name.
			    set &keepCol. = %nrstr("&customPrompt.");
	quit;
%mend createPromptTable;

%macro createFinalTable1();
	proc sql;
	    create table work.joined_table as
		    select *, catx(' ',"Given this:",txt,prompt) as content length=32767
	            from work.txt001 (keep=txt)
	                full join work.prompt001 (keep=prompt)
                        on 1 = 1;
	quit;
	
	data &responseTable. (drop=content);
	     length txt $32767.;
	     length prompt $32767.;
	     length response $32767.;
		 call execute('%loopOverDatasets('|| size ||')');
		 stop;
  		 set work.joined_table nobs=size;
	run;
%mend createFinalTable1;

/* **************************************** */
/*           INPUT PROMPT CATALOG           */
/* **************************************** */

* Specify source of your prompt input = 'Prompt catalog';
* (E.g. &promptInputChoice. = 'catalog');
%macro createFinalTable2();
	%if &suggestedPromptCheckbox. = 1 %then %do;
        data work.prompt001 (keep=prompt); 
            set &promptTable.;
			rename &promptCol. = prompt;
            if &suggestedPromptCol. = 'True' then output;
        run;
	%end;

	%if &suggestedPromptCheckbox. = 0 %then %do;
        data work.prompt001 (keep=prompt); 
            set &promptTable.;
			rename &promptCol. = prompt;
            if &promptIDColumn. = &promptDropdown. then output;
        run;
	%end;

	proc sql;
	    create table work.joined_table as
		    select *, catx(' ', 'Given this:', txt, prompt) as content length=32767
	            from work.txt001 (keep=txt)
	                full join work.prompt001
                        on 1 = 1;
	quit;
	
	data &responseTable. (drop=content);
	    length txt $32767.;
	    length prompt $32767.;
	    length response $32767.;
		call execute('%loopOverDatasets('|| size ||')');
		stop;
  		set work.joined_table nobs=size;
	run;
%mend createFinalTable2;

/* **************************************** */
/*        SELECT LARGE LANGUAGE MODEL       */
/* **************************************** */

%macro loopOverDatasets(datasetCount);
    %local iter;

    * Initiate loop;
    %do iter=1 %to &datasetCount;
        * Get libref and dataset name for dataset you will work on during this iteration;
        data work.msgs_json;
            set work.joined_table (firstobs=&iter. obs=&iter. keep=content);
            role = 'assistant';
        run;

        * Prepare the json files for in and out;
        filename json_in temp;
        filename json_out temp;

        * Input the texts for json_in;
        proc json out=json_in pretty;
            write values "model" "%trim(&llmDropdown.)"; 
            write values "messages";
            write open array;
            export work.msgs_json / nosastags;
            write close;  
            write values "temperature" 0.1;
            write values "max_tokens" 1000;
        run;   
 
        * Send the json_in to LLM by API;
        proc http
	        url="%trim(%nrstr(&APIURL))"
	        method='Post'
	        in=json_in
	        out=json_out;
	        headers
	            'Authorization' = "%trim(%nrstr(&Token.))"
	            'Content-Type' = 'application/json';
        run;

        * Print the response from gtp;
        libname jlib json fileref=json_out;

        proc print data=jlib.choices_message(keep=content);
        run;

        data work.row_response;
	        merge work.joined_table(firstobs=&iter. obs=&iter. drop=content) jlib.choices_message(keep=content rename=(content=response));
	    run;

	    proc append base=&responseTable. data=work.row_response force;
	    run;
    %end;
	
	* Cleanup;
	proc delete data=work.txt001 work.joined_table work.row_response work.msgs_json;
    run;
%mend loopOverDatasets;

* Call LLM API;
data _null_;
	* Use Query Table;
	if strip("&queryInputChoice.") = 'table' then do;
		call execute('%useQueryTable()');
	end;

	* Create Query Table if needed;
	if strip("&queryInputChoice.") = 'enter' then do;
		call execute('%createQueryTable(txt001, txt)');
		call symput('queryTable', 'txt001');	
		call symput('queryColumn', 'txt');
	end;

	* Create Prompt Table if needed;
	if strip("&promptInputChoice.") = 'custom' then do;
		call execute('%createPromptTable(prompt001, prompt)');	
		call symput('promptTable', 'prompt001');
		call symput('promptCol', 'prompt');
	end; 
run;

data _null_;
	* Select Prompt from Prompt Catalog;
	if strip("&promptInputChoice.") = 'catalog' then do;
	    call execute('%createFinalTable2()');
	end; 
	else do; 
		call execute('%createFinalTable1()');
	end;
run;

/* **************************************** */
/*     CREATE PROMPT HISTORY & CATALOG      */
/* **************************************** */

* Assign SAS library; 
%let outlib = &saslibName.;
%let outpath = "&saslibPath.";
libname &outlib. &outpath.;

* Assign CAS library;
%let VAlib = &caslibName.;
libname &VAlib. cas caslib=&VAlib.;

* Rename these if you would like to change the default prompt table names;
%let prompt_history = prompthistory;
%let prompt_catalog = promptcatalog;

* Create Prompt History Table, if needed;
%macro createHistoryTable();
	proc sql noprint;
		create table work.&prompt_history. as select txt, prompt, response, 1 as ID 
		from &responseTable.;
	quit;
%mend createHistoryTable;

* Create Prompt Catalog Table, if needed;
%macro createCatalogTable();
	proc sql noprint;
		create table work.&prompt_catalog. as select prompt, 1 as ID, "False" as suggested_prompt 
		from work.prompt001;
	quit;
%mend createCatalogTable;

data _null_;
	if strip("&promptHistoryChoice.") = 'new' then do;
		call execute('%createHistoryTable()');
		call execute('%createCatalogTable()');	
	end;
run;

/* **************************************** */
/*     ADD TO PROMPT HISTORY & CATALOG      */
/* **************************************** */

* Use existing Prompt History & Prompt Catalog tables, if exist;
%macro useExistingTables();
	* Copy latest Prompt History table into temporary Prompt History table;
	data work.&prompt_history.;
		set &historyTable.;
	run;

	* Copy latest Prompt Catalog table into temporary Prompt Catalog table;
	data work.&prompt_catalog.;
		set &catalogTable.;
	run;

	* Append to Prompt History table;
	proc sql;
		create table work.promptappend AS
		    select * from work.&prompt_history.
		        union ALL
		    select txt, prompt, response from &responseTable.;
	quit;
	
	* Add unique ID to the new prompt;
	data work.&prompt_history.(drop=ID_max);
		set work.promptappend;
		retain ID_max;
		ID_max = max(ID_max, ID);
		if ID = . then ID = ID_max + 1;
	run;
	
	* Find the latest prompt and ID;
	proc sql noprint;
	    select max(ID) into :maxID from work.&prompt_history.;
	    select prompt into :promptValue from work.prompt001;
	quit;

	* Insert the new row into work.promptcatalog;
	proc sql;
		insert into work.&prompt_catalog. (prompt, ID, suggested_prompt)
		    values ("&promptValue.", &maxID., 'False');
	quit;

	* Remove duplicates from Prompt Catalog;
	proc sort data=work.&prompt_catalog. out=work.&prompt_catalog. (keep=prompt ID suggested_prompt) nodupkey;
		by prompt;
	run;
	
	* Order by ID number;
	proc sort data=work.&prompt_catalog. out=work.&prompt_catalog.;
		by ID;
	run;
	
	proc sort data=work.&prompt_history. out=work.&prompt_history.;
		by ID;
	run;

	* Cleanup;
	proc delete data=work.promptappend;
    run;
%mend useExistingTables;

data _null_;
	if strip("&promptHistoryChoice.") = 'existing' then do;
		call execute('%useExistingTables()');
	end;
run;

/* **************************************** */
/*   SAVE & PROMOTE PROMPT HISTORY/CATALOG  */
/* **************************************** */

%if &savePromptCheckbox.=1 %then %do;
	data &outlib..&prompt_history.; 
		set work.&prompt_history.;
	run;

	data &outlib..&prompt_catalog.; 
		set work.&prompt_catalog.;
	run;
%end;

%if &promoteHistoryCheckbox.=1 %then %do;
	* Drop table;
	proc casutil;
		droptable casdata="&prompt_history." incaslib="&VAlib." quiet;
	quit;
	
	data &VAlib..&prompt_history.; 
		set work.&prompt_history.;
	run;
	
	* Promote table;
	proc casutil;
	   promote casdata="&prompt_history" casout="&prompt_history" incaslib="&VAlib" outcaslib="&VAlib";
	quit;
%end;

%if &promoteCatalogCheckbox.=1 %then %do;
	* Drop table;
	proc casutil;
		droptable casdata="&prompt_catalog." incaslib="&VAlib." quiet;
	quit;
	
	data &VAlib..&prompt_catalog.; 
		set work.&prompt_catalog.;
	run;

	* Promote table;
	proc casutil;
	   promote casdata="&prompt_catalog." casout="&prompt_catalog." incaslib="&VAlib." outcaslib="&VAlib.";
	quit;
%end;

* Cleanup;
proc delete data=work.prompt001 work.&prompt_catalog. work.&prompt_history.;
run;