data _null_; 
	call symputx('viyaHost', kreverse(ksubstr(ksubstr(kreverse("&_BASEURL."), 2), kfind(ksubstr(kreverse("&_BASEURL."), 2), '/') + 1)));
    call symputx("flowPath", kscan("&_flowFolder", 2, ':'));
    call symputx("codePath", kscan("&_codeFolder", 2, ':'));
    
    /*
        The custom step supports only physical directories to write the resulting code files to.
    */
    call symputx("codePathType", kscan("&_codeFolder", 1, ':'));
   
    /*
        The JSON request only accepts true of false, not 1 or 0.
    */
    call symputx("userAutoExec", ifc(&_userAutoExec, 'true', 'false'));
    call symputx("wrapperCode", ifc(&_wrapperCode, 'true', 'false'));
    call symputx("initCode", ifc(&_initCode, 'true', 'false'));

    /*
        Determine the content type of 'flowPath', 'content' or 'compute'.
    */
    call symputx("flowPathType", ifc(upcase(kscan("&_flowFolder", 1, ':')) = "SASCONTENT", "content", "compute"));
run;

/*
    The 'flows' macro variable will contain the names of the flows
    to export, separated with an |, independed from the contentType (= content or compute).

    'nbrFlows' will contain the number of flows to be processed.
*/
%let flows=;
%let nbrFlows=0;

%macro directoryContent(
    contentType=
);
    %put NOTE: == Input parameters for macro: directoryContent ==;
    %put NOTE: &=contentType;
    %put NOTE: == Input end ==;
    
    /*
        The macro variable contentType is used to indicate where the flow(s) is/are located:
        - content: The flow is located in SAS content
        - compute: The flow is located on a physical location.
    */
    %if &contentType eq content %then %do;
        /*
            The flows are located in SAS content.
            
            Get the directory URI to retrieve the members within the specified content directory.
        */
        filename ref temp;
        proc http
            url = "&viyaHost./folders/folders/@item"
                query = ("path" = "&flowPath")
            oauth_bearer = sas_services
            out= ref;
            headers
                'Accept'= 'application/vnd.sas.content.folder+json';
        run;
        %if %sysfunc(fexist(ref)) %then %do;
            libname ref json;
            /*
                From the links table, store the end-point and the content type into macro variables.
            */
            proc sql noprint;
                select 
                    href, 
                    type into :endpoint, :type
                from 
                    ref.links
                where 
                    upcase(method) = "GET" and 
                    upcase(rel) = "MEMBERS";
            quit;
            /*
                Removing unnecessary objects.
            */
            libname ref clear;
            filename ref clear;

            /*
                Retrieve the flows from the specified contents directory.

                Note the maxFlows macro variable.
            */
            filename members temp; 
            proc http
                url = "&viyaHost.%trim(&endpoint)?limit=&_maxFlows"
                oauth_bearer = sas_services
                out = members;
                headers
                    "Accept"= "%trim(&type)+json";
            run; 
            %if %sysfunc(fexist(members)) %then %do;    
                /*
                    Put all the flow names into the 'flows' macro variable.
                */
                libname members json;
                proc sql noprint;
                    select 
                        strip(name) into :flows separated by '|'
                    from
                        members.items
                    where
                        /*
                            The contents can also contain non-flow objects.
                        */
                        upcase(contentType) = "DATAFLOW";
                quit;

                /*
                    Removing unnecessary objects.
                */
                libname members clear;
                filename members clear;
            %end;
            %else %do;
                %put ERROR: Unable to retrieve content directory members.;
            %end;
        %end;
        %else %do;
            %put ERROR: Unable to retrieve content directory.;
        %end;
    %end;
    %else %do;
        /*
            The directory containing flows is located on a physical directory.
        */
        %let regexp =%sysfunc(tranwrd(*.flw ,.,\.));
	    %let regexp2=%sysfunc(tranwrd(&regexp,*,.*));
	    %let regexp3=%sysfunc(tranwrd(&regexp2,?,.));
	    %let pattern =/&regexp3/;         
         
	    data items(keep=filename);          
		    length      
			    fref $8
                directory $256
	    		filename $256;         
     
		    if ksubstr(kreverse("&flowPath"), 1, 1) ^= '/' then do;         
			    directory = strip("&flowPath" || '/');	         
		    end;         
		    else do;         
			    directory = strip("&flowPath");         
		    end;         
         
		    rc = filename(fref, "'&flowPath'");          
		    if rc = 0 then do;          
			    did = dopen(fref);          
		    end;          
		    else do;          
			    length msg $200.;          
    			msg = sysmsg();          
	    		put msg=;          
		    	did = .;          
    		end;          
          
		    if did <= 0 then          
			    put 'ERROR: unable to open compute directory.';
          
		    dnum = dnum(did);          
		    regexp = prxparse("&pattern");
 		    do i = 1 to dnum;          
			    filename = dread(did, i);          
			    rc = prxmatch(regexp, filename);         
			    if (rc > 0) then do;
                    directory = kstrip(directory);
 	    			filename = kstrip(filename);         
		    		output;          
			    end;         
		    end;          
	    run;

        /*
            Put all the flows names in the 'flows' macro variable.
        */
        proc sql noprint;
            select 
                strip(filename) into :flows separated by '|'
            from
                work.items
            order by
                filename;
        quit;

        /*
            Remove the items dataset, it is not needed anymore.
        */
        proc datasets library=work nolist;
            delete items;
        quit;
    %end;
    /*
        Count the number of flows in the flows macro variable.
    */
    data _null_;
        call symputx("nbrFlows", count("&flows", '|') + 1);
    run;
%mend directoryContent;

%macro exportFlowCode(
    contentDirectory=,
    codeDirectory=,
    flowName=,
    contentType=
);
    
    %put NOTE: == Input parameters for macro: exportFlowCode ==;
    %put NOTE: &=contentDirectory;
    %put NOTE: &=codeDirectory;
    %put NOTE: &=flowName;
    %put NOTE: &=contentType;
    %put NOTE: == Input end ==;
    
    /*
        Create the request for the end-point.

        Documentation: https://developer.sas.com/rest-apis/studioDevelopment/getGeneratedCode
    */
    filename request temp;
    proc json out=request nosastags pretty;
	    write open object;
		    write values "reference";
    		write open object;
	    		write values "type" "&contentType";
		    	write values "path" "&contentDirectory./&flowName";
			    write values "mediaType" "application/vnd.sas.dataflow";
    		write close;	
            /*
                SAS session initialization.
            */
            write values "initCode" &initCode;
		    write values "wrapperCode" &wrapperCode;
            /*
                SAS Studio autoexec. Only works in case initCode is true.

                Note that the default value is true if not specified.
                
                I really need it to be explicit! (The option is only true if the end-user
                sets this option to true.)
            */
            %if &initcode eq true %then %do;
                write values "userAutoExec" &userAutoExec;
            %end;
            %else %do;
                write values "userAutoExec" false;
            %end;
	    write close;
    run;

    /*
        Call the end-point with the request.

        Documentation: https://developer.sas.com/rest-apis/studioDevelopment/getGeneratedCode
    */
    filename response temp;
    proc http
        method ='post'
        url = "&viyaHost./studioDevelopment/code"
        in = request
    	out= response
        timeout=&_httpTimeOut
        oauth_bearer = sas_services;
        headers
	    	'Content-Type'='application/json;charset=utf-8'
		    'Accept'='application/json';
    run;

    %if &sys_prochttp_status_code eq 200 %then %do;
        /*
            The HTTP request was successful, process the response file 
            and try to create a .sas file.
        */

        %if not %sysfunc(fexist(_python)) %then %do;
            /*
                Only (re)create the Python code when needed.
            */
            %put NOTE: Python code does not exist, creating python code.;
            
            filename _python temp;
            data _null_;
                file _python lrecl=32676;
                put 'submit;'
                    /
                    / 'import os'
                    / 'import json'
                    /
                    / "responseLocation = SAS.symget('responseLocation')"
                    / "sasFile = SAS.symget('sasFile')"
                    / 
                    / 'try:'
                    / '    if not responseLocation:'
                    / '        raise ValueError("ERROR: Macro variable responseLocation is missing or empty.")'
                    / '    if not sasFile:'
                    / '        raise ValueError("ERROR: Macro variable sasFile is missing or empty")'
                    / '    if not os.path.isfile(responseLocation):'
                    / '        raise FileNotFoundError(f"ERROR: The file {responseLocation} does not exist.")'
                    / '    with open(responseLocation, "r") as json_file:'
                    / '      try:'
                    / '          data = json.load(json_file)'
                    / '      except json.JSONDecodeError as e:'
                    / '          raise ValueError(f"ERROR: Invalid JSON format: {e}")'
                    / '    if not isinstance(data, dict):'
                    / '        raise TypeError("ERROR: JSON root element must be an object")'
                    / '    if "code" not in data:'
                    / '        raise KeyError("ERROR: JSON does not contain the required key: CODE")'
                    / "    if not isinstance(data['code'], str):"
                    / '        raise TypeError("ERROR: The code element must be a string.")'
                    / "    if not data['code'].strip():"
                    / '        raise ValueError("ERROR: The code element is empty.")'
                    / '    with open(sasFile, "w") as codeFile:'
                    / "        codeFile.write(data['code'])"
                    / '    print(f"{sasFile} file successfully created.")'
                    / 'except Exception as err:'
                    / '    print(f"Exception caught: {err}")'
                    / 'endsubmit;';
            run;
        %end;
        %else %do;
            /*
                Re-using the existing Python code.
            */
            %put NOTE: Python code already exists, re-using it.;
        %end;

        /*
            Create the variables used by the python code.
            Note that the .flw extension is replaced with the .sas extension.
        */
        data _null_;
            flowName = tranwrd("&flowName", '.flw', '.sas');

		    call symputx('responseLocation', strip(pathname('response')));
            call symputx('sasFile', "&codeDirectory./" || strip(flowName));
	    run;

        /*
            Run the Pyhon code.
        */
        proc python;
            %inc _python;
        run;
    %end;
    %else %do;
        %put ERROR: Unable to generate code for &contentDirectory./&flowName;

        /*
            Try to read the error message from the response file.
        */
        %if %sysfunc(fexist(response)) %then %do;
            libname response json;
            %if %sysfunc(exist(response.ERRORS_ERRORS, data)) %then %do;
                proc sql noprint;
                    select 
                        strip(message) into :errorMessage
                    from
                        response.ERRORS_ERRORS;
                quit;
                %put ERROR: &errorMessage;
            %end;
            %else %do;
                %put ERROR: Unable to retrieve the error message.;
            %end;
            libname response clear;
        %end;
        %else %do;
            %put ERROR: No error message response file received.;
        %end;
    %end;

    filename request clear;
    filename response clear;
%mend exportFlowCode;

%macro processFlows;
    
    %put NOTE: == Input parameters for macro: processFlows ==;
    %put NOTE: No input variables.;
    %put NOTE: == Input end ==; 
    /*
        Only start processing when the directory the generated sas code needs to be
        written to is a physical one.
    */
    %if &codePathType eq sasserver %then %do;
        %if %sysfunc(fileexist(&codePath)) %then %do;
            %directoryContent(
                contentType=&flowPathType
            );
            %if "&flows" ne "" %then %do;
                %let index = 1;
                %do %while (%qscan(&flows, &index, '|') ne %str());
                    %let flow = %qscan(&flows, &index, '|');
                    %put NOTE: Processing flow (&index of &nbrFlows): &flow;

                    %exportFlowCode(
                        contentDirectory=&flowPath,
                        codeDirectory=&codePath,
                        flowName=&flow,
                        contentType=&flowPathType
                    );
                    %let index = %eval(&index + 1);
                %end;
                /*
                    Correct for the last increment.
                */
                %let index = %eval(&index - 1);
                %put NOTE: Number of flows processed: &index;
                /*
                    The Python code file can finally be removed.
                */
                filename _python clear;            
            %end;
            %else %do;
                %put WARNING: No flow(s) to process.;
            %end;
        %end;
        %else %do;
            %put ERROR: The target directory does not exist.;
        %end;
    %end;
    %else %do;
        %put ERROR: The custom step only supports physical directories to write the .sas file(s) to.;
    %end;
%mend processFlows;
%processFlows;

/*
    Remove all macro variables from memory.
*/
%symdel viyaHost /NOWARN;
%symdel flowPath /NOWARN;
%symdel codePath /NOWARN;
%symdel codePathType /NOWARN;
%symdel userAutoExec /NOWARN;
%symdel wrapperCode /NOWARN;
%symdel initCode /NOWARN;
%symdel flowPathType /NOWARN;
%symdel flows /NOWARN;
%symdel nbrFlows /NOWARN;

/*
    Remove all macros from memory.
*/
%sysmacdelete directoryContent / NOWARN;
%sysmacdelete exportFlowCode / NOWARN;
%sysmacdelete processFlows / NOWARN;