/*
    The following macro creates the 'in' clause based on the selected CHAR columns that
    need to be converted to VARCHAR.

    The result will be something like: (COLUMN_01, COLUMN_02, ..., COLUMN_xx).
*/
%macro createINClause;
    %if &_convert_count > 0 %then %do;
        %do index = 1 %to &_convert_count;
            /*
                For the first column, start with a (
            */
            %if &index > 1 %then %do;
                %let inClause=&inClause., %upcase("&&_convert_&index._name");
            %end;
            %else %do;
                %let inClause=("&&_convert_&index._name";
            %end;
        %end;
        /*
            End the result with a )
        */
        %let inClause=&inClause);
        %put NOTE: Generated IN clause &inclause;
    %end;
    %else %do;
        %put NOTE: No columns selected to convert.;
    %end;
%mend;

%macro createDSStatements
(
    srcTable=
);    
    /*
        Extract the library- and table name.
    */
    data _null_;
        call symputx('lib', kstrip(kscan("&srcTable", 1, '.')));
        call symputx('table', kstrip(kscan("&srcTable", 2, '.')));
    run;
    
    /*
        Create the IN clause based on the end-user selected columns.
    */
    %let inClause=;
    %createINClause;

    /*
        The following PROC SQL creates the specified 'statement' variables to be used 
        during the CHAR to VARCHAR conversion.

        A typical conversion script would look like:

        data casuser.source_loaded_varchar(drop=_COLUMN_01 _COLUMN_02 rename=(_COLUMN_01=COLUMN_01 _COLUMN_02=COLUMN_02));
            set
                casuser.source_loaded;
            length
                _COLUMN_01 varchar(x)
                _COLUMN_02 varchar(y);
            
            _COLUMN_01 = strip(COLUMN_01);
            _COLUMN_02 = strip(COLUMN_02);
        run;
    */
    proc sql noprint;
        select
            /*
                lengthStatement

                Example: _COLUMN_01 varchar(x) _COLUMN_02 varchar(y)
                
            */
            '_' ||
            strip(name) || 
            ' varchar(' || 
            strip(put(length, 8.)) || 
            ')',
            /*
                copyStatement

                Example: _COLUMN_01 = strip(COLUMN_01); _COLUMN_02 = strip(COLUMN_02);
            */            
            '_' ||
            strip(name) || 
            ' = strip(' ||
            strip(name) ||
            ')',
            /*
                dropStatement

                Example: _COLUMN_01 _COLUMN_02
            */
            strip(name),
            /*
                renameStatement

                Example: _COLUMN_01=COLUMN_01 _COLUMN_02=COLUMN_02
            */
            '_' ||
            strip(name) || 
            ' = ' ||
            strip(name)            
            into 
                :lengthStatement separated by ' ',
                :copyStatement separated by '; ',
                :dropStatement separated by ' ',
                :renameStatement separated by ' '
        from
            dictionary.columns
        where
            upcase(libname) = upcase("&lib") and
            upcase(memname) = upcase("&table") and
            upcase(type) = "CHAR" and
            /*
                inClause only contains the columns the end-user selected to be converted.
            */
            upcase(name) in &inClause;
    quit;
%mend;

%macro load_to_cas;
    data _null_;
        call symputx("trgtLIB", kstrip(kscan("&_output", 1, '.')));
    run;
    
 	%let _flw_table_exist = %eval(%sysfunc(exist(&_input, data)) or %sysfunc(exist(&_input, view)));
    /*
		Only continue in case the source table exists.
	*/
	%if &_flw_table_exist eq 1 %then %do;
        %let _cas_table_exist = %eval(%sysfunc(exist(&_output, data)));
		/*
			If the CAS table does exist and append is chosen, we append.
		*/
		%if &_cas_table_exist eq 1 and &_append eq 1 %then %do;
            %put NOTE: Appending &_input to the table &_output_name;

            %put NOTE: Source table engine: &_input_engine;
            %if &_input_engine eq V9 %then %do;
                %if &_convert_count > 0 %then %do;
                    /*
                        The source- and target tables differ in data types (CHAR vs. VARCHAR). This will create a problem
                        when trying to append the source table to the target table directly. To prevent an error
                        the following steps are to be taken.

                        1. Read the source table, as-is, into the casuser CASlib.
                    */
                    proc casutil;
                        load
                        data=&_input
			        	outcaslib="casuser"
				        casout="source_loaded"
    				    replace;
                    quit;

                    /*
                        2. Perform the CHAR to VARCHART conversion for the selected columns.
                    */
                    %let lengthStatement=;
                    %let copyStatement=;
                    %let dropStatement=;
                    %let renameStatement=;
                    %createDSStatements
                    (
                        srcTable=casuser.source_loaded
                    );                    
                
                    data casuser.source_loaded_varchar(drop=&dropStatement rename=(&renameStatement));
              			set 
                            casuser.source_loaded;
                        length 
                            &lengthStatement;
                        &copyStatement;
        		    run; 

                    /*
                        3. Append the temporary CAS table with the converted columns to the target CAS table.

                        Note that the source is automatically compresses if the target is compressed.
                    */
                    proc casutil;
	    		    	append
		    		    srccaslib=casuser
                        source='source_loaded_varchar'
	    		    	tgtcaslib="&trgtLIB"
		    		    target="&_output_name"; 
			        quit;
                    /*
                        4. Drop both temporary tables.
                    */
                    proc casutil;
                        droptable casdata="source_loaded" incaslib="casuser";
                        droptable casdata="source_loaded_varchar" incaslib="casuser";
                    quit;
                %end;
                %else %do;
                    proc casutil;
	        			load
		        		data=&_input
			        	outcaslib="&trgtLIB"
				        casout="&_output_name"
    				    copies=0
	    			    append; 
		    	    quit;
                %end;
            %end;
            %else %do;
                %if &_convert_count > 0 %then %do;
                    %put WARNING: Conversion to VARCHAR is canceled because of an incompatible source table engine.; 
                %end;
                /*
                    This section is reached because of:
                    1. The source table exists.
                    2. The source table engine is not V9.
                    3. We have might have columns to convert.
                
                    Let's try to append the source table as-is, which might fail.
                */
                proc casutil;
	        		load
		        	data=&_input
			        outcaslib="&trgtLIB"
				    casout="&_output_name"
    				copies=0
	    			append; 
		    	quit;                    
            %end;
        %end;
		/*
			If the CAS table does not exist or we do a replace we can also set the Memory Format
		*/
		%else %if &_cas_table_exist eq 0 or &_append eq 0  %then %do;
			/*
				Note that: 
                - At this stage is doesn't really matter what the value for _append is.
                - The table doesn't exist, that makes the if statement true. (Could be removed completely?)
            
                The custom step is set to drop and create the CAS table.

                The dropTable action is used to drop tables from memory. If a session-scoped (local)
				table and global-scoped table have identical names, the dropTable action drops the
				session scoped table only when executed. To drop the global-scoped table with the
				same name, you must run the dropTable action a second time after dropping the
				session-scope table.
			*/
			%put NOTE: Dropping the CAS table &_output_name;
			proc cas;
				table.droptable / caslib="&trgtLIB" name="&_output_name" quiet=true;
				table.droptable / caslib="&trgtLIB" name="&_output_name" quiet=true;
			quit;

			%put NOTE: Loading the table &_output_name;
            %if &_convert_count > 0 %then %do;
                %if &_input_engine eq V9 %then %do;
                    %put NOTE: Converting CHAR to VARCHAR.;
                    /*
                        Initialize the following macro variables.
                    */
                    %let lengthStatement=;
                    %let copyStatement=;
                    %let dropStatement=;
                    %let renameStatement=;

                    /*
                        Generate each datastep part for the CHAR to VARCHAR conversion.
                    */
                    %createDSStatements
                    (
                        srcTable=&_input
                    );
                    /*
                        Run the conversion while loading the source dataset into memory.
                    */
                    %if &_compress eq 1 %then %do;
                        %put NOTE: Compressing CAS table.;
                        data &trgtLIB..&_output_name(drop=&dropStatement rename=(&renameStatement) compress=Yes);
                    %end;
                    %else %do;
                        data &trgtLIB..&_output_name(drop=&dropStatement rename=(&renameStatement));
                    %end;
	        			set 
                            &_input;
                        length 
                            &lengthStatement;
                        &copyStatement;
    		    	run;                
                %end;
                %else %do;
                    %put WARNING: Conversion to VARCHAR is canceled because of incompatible source table engine.;
                    %if &_compress eq 1 %then %do;
                        %put NOTE: Compressing CAS table.;
                        data &trgtLIB..&_output_name(compress=Yes);
                    %end;
                    %else %do;
                        data &trgtLIB..&_output_name;
                    %end;
	    			    set &_input;
		    	    run;
                %end;
            %end;    
            %else %do;
                %if &_compress eq 1 %then %do;
                    %put NOTE: Compressing CAS table.;
                    data &trgtLIB..&_output_name(compress=Yes);
                %end;
                %else %do;
                    data &trgtLIB..&_output_name;
                %end;
	    			set &_input;
		    	run;
            %end;
			/*
	 			Use DVR Memory Format to compress the table.
			*/
            %if &_memfmt ^= INHERIT %then %do; /* INHERIT is the default */
				%put NOTE: Setting Memory Format &_memfmt for the table &_output_name;
	            proc cas;
					table.copyTable / 
	                  table={
                        caslib="&trgtLIB", 
                        name="&_output_name"
                        } 
					  casOut={
                        caslib="&trgtLIB", 
                        name="&_output_name" , 
                        memoryFormat="&_memfmt", 
                        replace=True, 
                        replication=0, 
                        compress=TRUE
                        };
				quit;
            %end;
		%end;
       	/*
			The custom step is set to promote the table, after checking the scope
		*/
        %if &_promote eq 1 %then %do;
		    proc cas;
				table.tableExists result=r / caslib="&trgtLIB", name="&_output_name";
	
				if r.exists=0 then do;
					print "NOTE: The CAS table &_output_name does not exist.";
				end;
	
				if r.exists=1 then do;
					print "NOTE: The CAS table &_output_name has a session scope.";
					print "NOTE: Promoting the CAS table &_output_name..";
	
					/*
					    Promote the table.
					*/
					table.promote / caslib="&trgtLIB", name="&_output_name", target="&_output_name", targetlib="&trgtLIB";
				end;
	
				if r.exists=2 then do;
					print "The CAS table &_output_name has a global scope.";
				end;
			quit;
		%end;
        /*
			The custom step is set to generate a CASLib contents in the log.
		*/
		%if &_listing eq 1 %then %do;
			proc casutil;
				contents incaslib="&trgtLIB" casdata="&_output_name";
			quit;
		%end;
	%end;
	%else %do;
		%put ER%str()ROR: The source table &_input does not exist. Aborting process;
		%abort;
	%end;
%mend;

%if &_output_engine eq CAS %then %do;
    /*
        The target table is a CAS table, continue the load it.
    */
    %load_to_cas;
%end;
%else %do;
    %PUT ERROR: The target table is not a CAS table.;
%end;

/*
    Remove all macro variables from memory.
*/
%symdel lib /NOWARN;
%symdel table /NOWARN;
%symdel lengthStatement /NOWARN;
%symdel copyStatement /NOWARN;
%symdel dropStatement /NOWARN;
%symdel renameStatement /NOWARN;
%symdel engine /NOWARN;
%symdel inClause /NOWARN;

/*
    Remove all macros from memory.
*/
%SYSMACDELETE load_to_cas / NOWARN;
%SYSMACDELETE createDSStatements / NOWARN;
%SYSMACDELETE createINClause / NOWARN;