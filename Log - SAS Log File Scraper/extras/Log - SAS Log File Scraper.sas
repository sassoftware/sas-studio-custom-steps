%macro directory_contents(directory, pattern);         
         
	%let regexp =%sysfunc(tranwrd(&pattern ,.,\.));         
	%let regexp2=%sysfunc(tranwrd(&regexp,*,.*));         
	%let regexp3=%sysfunc(tranwrd(&regexp2,?,.)) ;          
	%let pattern =/&regexp3/;         
         
	data log_files(keep=filename file_dt file_tm);          
         
		length      
			fref $8      
			filename $256;         
     
		attrib file_dt length=8 format=date9.;
		attrib file_tm length=8 format=time.;     
         
		/*
			Add the '/' character if needed.
		*/
		if ksubstr(kreverse("&directory"), 1, 1) ^= '/' then do;         
			directory = strip("&directory" || '/');	         
		end;         
		else do;         
			directory = strip("&directory");         
		end;         
         
		/*
			try to open the specified directory.
		*/
		rc = filename(fref, "'&directory'");          
		if rc = 0 then do;          
			did = dopen(fref);          
			rc = filename(fref);          
		end;          
		else do;          
			length msg $200.;          
			msg = sysmsg();          
			put msg=;          
			did = .;          
		end;          
          
		if did <= 0 then          
			put 'error: unable to open directory.';          
          
		dnum = dnum(did);          
		regexp = prxparse("&pattern");         
 		do i = 1 to dnum;          
			filename = dread(did, i);          
			rc = prxmatch(regexp, filename);         
			if (rc > 0) then do;
				rc = filename('fid', strip(directory) || strip(filename));
				fid = fopen('fid'); 
 				filename = strip(directory) || strip(filename);         
                /*
					generate the file_dt and file_tm based on the 'last modified' file property.
				*/
				file_dt = datepart(input(finfo(fid,'last modified'), datetime.));
                file_tm = timepart(input(finfo(fid,'last modified'), datetime.));
                rc = fclose(fid);
				/*
					apply the date range filter.
					When in range, write to the output table.
				*/
				if file_dt >= date() - &today_min_days then do;
					output;
				end;
			end;         
		end;          
		rc = dclose(did);          
	run;          
%mend directory_contents;    

%macro searchlog;      
	/*      
		create and initialize the 'all_messages' table.      
		this is done in case there are no files.      
	*/      
	data &_output1;      
		attrib logfile length=$256;     
		attrib file_dt length=8. format=date9.;     
		attrib file_tm length=8. format=time.;     
		attrib path length=$256;      
		attrib text length=$512;      
		attrib linenum length=8.;     
		stop;      
    run;      
      
	%do i = 1 %to &totobs;      
		%let rc = %sysfunc(filename(filrf, &&inlog&i));      
		%if %sysfunc(fileref(&filrf)) = 0 %then %do;      
			%let fid = %sysfunc(fopen(&filrf));       
			%if &fid ne 0 %then %do;      
				data log_messages(drop=regexp_search);      
					attrib file_dt length=8. format=date9.;     
					attrib file_tm length=8. format=time.;     
					format       
						logfile $256.      
						path $256.       
						text $512. ;      
					infile &filrf length = len;      
					input text $varying500. len;      
					linenum = _n_;      
					    
					regexp_search = prxparse("/^ERROR(.*):|^WARNING(.*)/");
					if prxmatch(regexp_search, text) > 0 then do;    
						path = "&log_dir";      
						logfile = kreverse(kscan(kreverse("&&inlog&i"), 1, '/'));     
						file_dt = input("&&filedt&i", date9.);     
						file_tm = input("&&filetm&i", time.);     
						output;      
					end;        
				run;      
			%end;      
			%else %do;      
				%put WARNING: file in use: &&inlog&i;      
				data log_messages;      
					attrib file_dt length=8. format=date9.;     
					attrib file_tm length=8. format=time.;    
					format       
						logfile $256.      
						path $256.       
						text $512. ;      
					linenum = 1;      
					path = "&log_dir";      
					logfile = kreverse(kscan(kreverse("&&inlog&i"), 1, '/'));      
					file_dt = input("&&filedt&i", date9.);     
					file_tm = input("&&filetim&i", time.);     
					text = "checklog message: logfile could not be opened because the job was not finished at the time of checking the logs";      
					output;      
				run;      
			%end;      
			%let cfid=%sysfunc(fclose(&fid));      
			%let rc=%sysfunc(filename(&filrf));      
			proc append data=log_messages base=&_output1 force;run;      
		%end;      
  		%else %do;        
			%let message = %sysfunc(sysmsg());
			%put &message;      
			%let filrf = ;      
		%end;
	%end;      
%mend searchlog;  

%macro check_batch_log;      
    
	/*
		remove the directory type, sascontent or sasserver, from the log_dir macro variable
	*/
	data _null_;
		call symput ("log_dir", scan("&logfile_dir", 2, ':'));
		call symput ("dir_type", scan("&logfile_dir", 1, ':'));
	run;

	/*
		This custom step only supports physical files.
	*/
	%if &dir_type eq sasserver %then %do;
      
		/*
			search for log files in the log directory
		*/
		%directory_contents      
			(      
				&log_dir,       
				*.log      
			);      
      
		/*      
			put the log files, and related information, in memory, ready to be used.	      
		*/      
		%let totobs = 0;
		data _null_;      
			set       
				work.log_files end = final;      
	   		length       
				macvar $12.;      
			macvar = 'inlog'||kcompress(put(_n_,3.));     
			filedt = 'filedt'||kcompress(put(_n_,3.));     
			filetm = 'filetm'||kcompress(put(_n_,3.));     
     
			call symput(macvar,filename);      
			call symput(filedt,kcompress(put(file_dt, date9.)));     
			call symput(filetm,kcompress(put(file_tm, time.)));     
     
			if final then call symput('totobs',kcompress(put(_n_,3.)));      
		run;
     
		/*      
			search for errors and warnings in the log files.      
		*/
		%put NOTE: &totobs log files encountered for the given date range.;
		%searchlog;
	%end;
	%else %do;
		%put ERROR: Please select a location on the SAS Server. SAS Content folders are not supported by this custom step;
		%abort exit;
	%end;
%mend check_batch_log;      
%CHECK_BATCH_LOG; 

/*
	Remove all macro variables from memory.
*/
%symdel log_dir /NOWARN;
%symdel dir_type /NOWARN;
%symdel totobs /NOWARN;

/*
	Remove all macros from memory.
*/
%SYSMACDELETE directory_contents / NOWARN;
%SYSMACDELETE searchlog / NOWARN;
%SYSMACDELETE check_batch_log / NOWARN;