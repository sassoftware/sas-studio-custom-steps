/*
	Remove the directory type, sascontent or sasserver, from the _targetdir macro variable
*/
data _null_;
	call symputx("_targetdir", scan(strip("&_targetdir"), 2, ':') || '/');
run;

/*
	Initialize the output table.
*/
data &_output;
	attrib source_directory length=$256;
	attrib source_file length=$256;
	attrib target_directory length=$256;
	attrib rmv_src_after_dwnld length=$8;
	attrib rmv_trgt_bfr_dwnld length=$8;
	attrib processed_dttm length=8 format=datetime22.3;
	stop;
run;

/*
	The macro that does the actual download and, of requested, removes the source file from the FTP server.
*/
%macro download
(
	source_dir=,
	source_file=
);

	/*
		Put the input variables in the log for debugging.
	*/
	%put NOTE: &source_dir;
	%put NOTE: &source_file;

	/*
		Remove the target file if requested.
	*/
	%if &_removeTargetFile EQ Yes %then %do;
		data _null_;
			length ref $8;
			/*
				Create a reference to the file about to be deleted.
			*/
			rc = filename(ref, cats("&_targetdir", "&source_file"));
			if rc = 0 and fexist(ref) then do;
				rc = fdelete(ref);
				if rc = 0 then do;
					put "NOTE: The file &_targetdir.&source_file has been removed.";
				end;
				else do;
					put "ERROR: The file &_targetdir.&source_file could not be removed.";
					abort;
				end;	
			end;
			else do;
				put "NOTE: Not able to create a file reference or the file, &_targetdir.&source_file doesn't exist.";
			end;		
		run;
	%end;

	/*
		Create a reference to the remote file.
	*/
	filename ftp_file FTP
		"&source_dir./&source_file"
		%if &_passive %then %do;
			passive
		%end;
		cd="&source_dir"
		user="&_userName"
		pass="&_password"
		host="&_ftpHost"
		%if &_debug %then %do;
			debug
		%end;
		recfm=s;

	/*
		Download / copy the file to the target directory.
	*/
	filename trgt "&_targetdir.&source_file" recfm=n;
	data _null_;
		n=1;
		infile ftp_file nbyte=n;
		input;
		file trgt;
		put _infile_ @@;
	run;

	/*
		Validate that the file has been copied and that the filename operation went as planned.
	*/
	%if &syserr eq 0 %then %do;
		%put NOTE: the file &_targetdir.&source_file has been transterred succesfully.;
		
		/*
			Delete the source file if requested.
		*/
		%if &_removeSourceFile EQ Yes %then %do;
			/*
				Create a reference for the command that removes the source file.
			*/
			filename ftp_file FTP ''
				%if &_passive %then %do;
					passive
				%end;
				cd="&source_dir./"
				user="&_userName"
				pass="&_password"
				host="&_ftpHost"
				%if &_debug %then %do;
					debug
				%end;
				rcmd="DELE &source_file";
			
			/*
				Execute the FTP command, removing the source file.
			*/
			data _null_;
				file ftp_file;
			run;

			/*
				Check for errors.
			*/
			%if &syserr eq 0 %then %do;
				%put NOTE: The file &source_dir./&source_file has been removed.;
			%end;
			%else %do;
				%put ERROR: The file &source_dir./&source_file failed to be removed.;
			%end;
		%end;

		/*
			Add the file to the output table.
		*/
		data status_record;
			attrib source_directory length=$256;
			attrib source_file length=$256;
			attrib target_directory length=$256;
			attrib rmv_src_after_dwnld length=$8;
			attrib rmv_trgt_bfr_dwnld length=$8;
			attrib processed_dttm length=8 format=datetime22.3;
			
			source_directory = "&source_dir";
			source_file = "&source_file";
			target_directory = "&_targetdir";
			rmv_src_after_dwnld = "&_removeSourceFile";
			rmv_trgt_bfr_dwnld = "&_removeTargetFile";
			processed_dttm = datetime();
			output;			
		run;
		proc append base=&_output data=work.status_record force; run;
	%end;
	%else %do;
		%PUT ERROR: The file &source_dir./&source_file failed to copy.;
	%end;
%mend download;

/*
	For each row in the input table, call the download macro.
*/
data _null_;
	set
		&_input;

	call execute
		(
			cats
			(
				'%download(source_dir= %STR(',
				strip(&_sourceDir_1_name),
				'), source_file=%STR(',
				strip(&_sourceFile_1_name),
				'))'
			)
		);
run;