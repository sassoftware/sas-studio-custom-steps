/***************************************************************************
* Custom Step: HTTP Request
* --------------------------------------------------------------------------
* This custom step executes HTTP requests for methods:
* GET, PUT, POST, DELETE, HEAD, TRACE, PATCH, OPTION, CONNECT 
* --------------------------------------------------------------------------
* Note: Macros starting with an underscore contain UI variable values
****************************************************************************/
/* ----------------------------------------------------------------------- */
/* print message for when debugging                                        */
/* ----------------------------------------------------------------------- */
%macro debugMsg(msg);
	%if &_debugLevel > 0 %then %do;
		%put ===> %nrquote(&msg);
	%end;
%mend debugMsg;


/* ----------------------------------------------------------------------- */
/* Check if an error returned and output appropriate message               */ 
/* The message can be a warning or error. In case of error an              */
/* the job will stop.                                                      */
/* ----------------------------------------------------------------------- */
%macro checkError();
	%debugMsg(checkError());
	%if &mapKeyError = W %then %do;
		data _null_;
			file print;	
			put 'WARNING: Could not map field!';
			put "&mapKeyErrorMsg";
			put "&mapKeyErrorMsg2";
		run;
		data _null_;
			put 'WARNING: Could not map field!';
			put "&mapKeyErrorMsg";
			put "&mapKeyErrorMsg2";
		run;
	%end;
	%if &mapKeyError = E %then %do;
		data _null_;
			file print;	
			put "ERROR: Error in field mapping!";
			put "&mapKeyErrorMsg";
			put "&mapKeyErrorMsg2";
			error "ERROR: Error in field mapping!";
			abort;
		run;
	%end;
%mend checkError;


/* ----------------------------------------------------------------------- */
/* Check http status. If an error occurs stop the job and print message.   */
/* ----------------------------------------------------------------------- */
%macro checkHTTPStatus();
	%debugMsg(checkHTTPStatus());
	%if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
		%if &SYS_PROCHTTP_STATUS_CODE >= 300 %then %do;
			/* we call combineHTTPOutput here so we can make the json output available as it might show more error information */
			%combineHTTPOutput();
			/*show that there is an error and stop the job */
			data _null_;
				file print;	
				put "ERROR: Could not execute HTTP request!";
				put "HTTP Status: &SYS_PROCHTTP_STATUS_CODE Message: &SYS_PROCHTTP_STATUS_PHRASE";
				put "---";
				put "In step configuration go to ""Output Options tab -> Output Body -> Output Folder"" and set output folder for HTTP output file.";
				put "The file may contain more information if it exists!";
				put "Also check if you got a CATS function warning. This could mean that the payload is too big. Max Payload is 32767!";
				error "ERROR: Could not execute HTTP request! HTTP Status: &SYS_PROCHTTP_STATUS_CODE Message: &SYS_PROCHTTP_STATUS_PHRASE";
				error "In step configuration go to ""Output Options tab -> Output Body -> Output Folder"" and set output folder for HTTP output file.";
				error "The file may contain more information if it exists!";
				error "Also check if you got a CATS function warning. This could mean that the payload is too big. Max Payload is 32767!";
				abort;
			run;
		%end;
	%end;
%mend checkHTTPStatus;


/* ----------------------------------------------------------------------- */
/* If set in the ui map the output column to macros. The macros have       */
/* the same names as the columns. Only the first row will be mapped        */
/* ----------------------------------------------------------------------- */
%macro mapMacros();
	%debugMsg(mapMacros());
	/* make the macros global. Have to do it in a loop as the macrolist is comma separated */
	%let macName=.;
	%let i=1;
	%do %until (&macName = );
		%let macName= %scan(&_macros, &i);
		%let i=%eval(&i+1);
		%if &macName ~= %then %do;
			%global &macName;
		%end;
	%end;

	data _null_;
		set &_outputtable;

		%let macName=.;
		%let i=1;
		%do %until (&macName = );
			%let macName= %scan(&_macros, &i);
			%let i=%eval(&i+1);
			%if &macName ~= %then %do;
				/* we only map the first row of the result set to macros */
				if _n_ = 1 then
					call symput("&macName", &macName);
			%end;
		%end;
	run;
%mend mapMacros;

/* ----------------------------------------------------------------------- */
/* Generate the url for internal SAS Viya API calls                        */
/* ----------------------------------------------------------------------- */
%macro generateInternalUrl();
	%debugMsg(generateInternalUrl());
	/* get the local server name */
	%let viyaHost=%sysfunc(getoption(SERVICESBASEURL));
	/* set server and URI */
	data _null_;
		length url $2500;
		url= cats("&viyaHost", "&_SASServiceURL");
		call symputx('_url', url);
		put url=;
	run;
%mend generateInternalUrl;


/* ----------------------------------------------------------------------- */
/* Map the HTTP result to coulmns in a table according to the field mapping*/ 
/* from UI &_fieldMapping.                                                 */
/* ----------------------------------------------------------------------- */
%macro mapHTTPToColumns();
	%debugMsg(mapHTTPToColumns());

	/* we prepare the &_fieldMapping first. We concatenate all input lines      */ 
    /* and separate them with a comma (,). This way we can prevent an error     */
    /* if the user forgot to put a comma at the end on the input line in the UI. */
	%if %symexist(_fieldMapping_count) %then %do;
		%let _fieldMapping=;
		%let i= 1;
		%do %until(&i > &_fieldMapping_count);
	    	%let _fieldMapping= &_fieldMapping &&_fieldMapping_&i,;
			%let i= %eval(&i + 1);
		%end;
	%end;

	filename PCODE TEMP;
	data _null_;
		file PCODE;
		put "import pandas as pd";
		put "import json";
		put " ";
		put "moveTableToSAS= True";
		put "SAS.symput('mapKeyError_','No')";
		put "SAS.symput('mapKeyErrorMsg_', '')";
		put "SAS.symput('mapKeyErrorMsg2_', '')";
		put " ";
		put "httpoutFolder= SAS.symget('outputFolder')";
		put "httpoutAllFile= SAS.symget('_outputName')";
		put "fieldMapping= SAS.symget('_fieldMapping')";
		put "outputTable= SAS.symget('_outputtable')";
		put "fieldNotFoundMsg= SAS.symget('_fieldNotFoundMsg')";
		put " ";
		put "try:";
		put "    with open(httpoutFolder +""/"" +httpoutAllFile +"".json"", 'r') as fHttpAll:";
		put "        httpResultAll= json.load(fHttpAll)";
		put "except:";
		put "    httpResultAll= {}";
		put " ";
		put "###print(fieldMapping) ";
		put "fieldMap1= []";
		put "for map in fieldMapping.replace('\n',',').split(','):";
		put "    map= map.strip()";
		put "    if len(map) > 0:";
		put "        fieldMap1.append(map)";
		put "fieldMap2= []";
		put "#put the field mapping row ""columns"" in a list and remove leaning and trailing blanks";
		put "for row in fieldMap1:";
		put "    fieldMap2.append(row.replace(' ','').split('|')) ";
		put " ";
		put "#get column names";
		put "columns= []";
		put "for mapField in fieldMap2:";
		put "    #if the first char is # we ignore the row";
		put "    if mapField[0].strip()[0][0] != '#':";
		put "        try: ";
		put "            columns.append(mapField[1])";
		put "            if len(mapField) != 2:";
		put "                print('Error in field mapping!')";
		put "                print('Did you forget a comma? Check field mapping structure.')";
		put "                SAS.symput('mapKeyError_','E')";
		put "                SAS.symput('mapKeyErrorMsg_', 'Error in field mapping!')";
		put "                SAS.symput('mapKeyErrorMsg2_', 'Did you forget a comma? Check field mapping structure.')";
		put "                moveTableToSAS= False";
		put "        except:";
		put "            print('Error in field mapping!')";
		put "            print('Check field mapping structure.')";
		put "            SAS.symput('mapKeyError_','E')";
		put "            SAS.symput('mapKeyErrorMsg_', 'Error in field mapping!')";
		put "            SAS.symput('mapKeyErrorMsg2_', 'Check field mapping structure.')";
		put "            moveTableToSAS= False";
		put " ";
		put "rows= []";
		put "errorKeys= '' #variable to capture any key from the mapping if we cannot find them";
		put "for rowNum in httpResultAll:";
		put "    httpResult= httpResultAll[rowNum]";
		put " ";
		put "    row= []";
		put "    #go through field maps, read the data for each field and put it in the variables";
		put "    for mapField in fieldMap2:";
		put "        #if the first char is # we ignore the row";
		put "        if mapField[0].strip()[0][0] != '#':";
		put "            #split the field path and put in a list";
		put "            mappingKey= mapField[0].split('/')";
		put " ";
		put "            l= len(mappingKey) #read how deep the field path is";
		put "            for i in range(l):";
		put "                #if the fieldpath level is a number we convert it into an int variable";
		put "                try:";
		put "                    mappingKey[i]= int(mappingKey[i])";
		put "                except:";
		put "                    pass";
		put " ";
		put "            #copy the field we want to select into ""inputDataField""";
		put "            inputDataField= httpResult";
		put " ";
		put "            printError= True #we only want to print the error once per field mapping structure";
		put "            for key in mappingKey:";
		put "                try:";
		put "                    inputDataField= inputDataField[key]";
		put "                except:";
		put "                    if printError:";
		put "                        print(f""Cannot find key >{str(key)}< from mapping >{mapField[0]}< in row {str(rowNum)}"")";
		put "                        print(""Row ==> "" +str(httpResult))";
		put "                        printError= False";
		put "                        errorKeys+= f'>{mapField[0]}< '";
		put " ";
		put "                    SAS.symput('mapKeyErrorMsg_', f""Cannot find key(s) {errorKeys}in URL JSON return structure."")";
		put "                    SAS.symput('mapKeyErrorMsg2_', 'See log more more info!')";
		put "                    if fieldNotFoundMsg == 'Show Error':";
		put "                        SAS.symput('mapKeyError_','E')";
		put "                        moveTableToSAS= False";
		put "                    elif fieldNotFoundMsg == 'Show Warning':";
		put "                        inputDataField= ''";
		put "                        SAS.symput('mapKeyError_','W')";
		put "                        inputDataField= ''";
		put "                    else:";
		put "                        inputDataField= ''";
		put "            row.append(inputDataField)";
		put "    rows.append(row)";
		put " ";
		put "# Create the pandas DataFrame";
		put "if moveTableToSAS:";
		put "    df = pd.DataFrame(rows, columns=columns)";
		put "    SAS.df2sd(df, outputTable)";
	run;
	
	proc python infile= PCODE; quit;
	filename PCODE clear;

	%global mapKeyError; 
	%global mapKeyErrorMsg mapKeyErrorMsg2;
	%let mapKeyError= &mapKeyError_;
	%let mapKeyErrorMsg= %nrbquote(&mapKeyErrorMsg_);
	%let mapKeyErrorMsg2= %nrbquote(&mapKeyErrorMsg2_);

%mend mapHTTPToColumns;


/* ----------------------------------------------------------------------- */
/* Create SAS lib for the http output                                      */
/* ----------------------------------------------------------------------- */
%macro outputToLibrary();
	%debugMsg(outputToLibrary());

	/* if in the UI is set to output to SAS library */
	%if &_httpoutLib = 1 %then %do;
		filename httpout "&outputFolder./&_outputName..json";

		libname &_httpout JSON fileref=httpout NOALLDATA;
	%end;
%mend outputToLibrary;


/* ----------------------------------------------------------------------- */
/* Build dynamic URL/Payload and put it into macro variable parsedString.  */
/* The parameters in the URL/Payload need to match the column names of the */
/* input table. E.g. Parameter @ASD@ = column name ASD                     */
/* The value of the macro variable is a SAS cats() statement.              */
/* When the statement is executed the parameters are replaced              */
/* with column values                                                      */
/* ----------------------------------------------------------------------- */
%macro setParamaters(stringToParse_, strtype_);
	%debugMsg(setParamaters());

	%let stringToParse= &stringToParse_;
	%let strtype= &strtype_;
	filename PCODE TEMP;
	/* Python script to build the dynamic URL */
	data _null_;
		file PCODE;
		put "import re";
		put "inputStr= SAS.symget('stringToParse')";
		put "strtype= SAS.symget('strtype')";
		put "#need to escape singel quote (with 4 quotes!!) to prevent errors downstream in SAS environment ";
		put "inputStr= inputStr.replace(""'"", ""''''"")	";
		put "outputStr= ''";
		put "  ";
		put "#need to replace '&.' with & as only using & will trigger a SAS macro";
		put "inputStr= inputStr.replace(""&."", ""&"")";
		put "  ";
		put "regex = r'@[A-Za-z0-9_]*@'";
		put "matches= re.finditer(regex, inputStr, re.IGNORECASE | re.MULTILINE)";
		put " ";
		put "#find the parameters and assemble the output line";
		put "start=0";
		put "end=0";
		put "outputStr= ""cats(""";
		put "for match in matches:";
		put "    end= match.start()";
		put "    if strtype == 'escDQuote':"; /* escape double quote */
		put "        outputStr+= ""'"" +inputStr[start:end] +""', tranwrd("" +inputStr[match.start()+1:match.end()-1] +"""""", '""', '\\""'), """"""";
		put "    else:";
		put "        outputStr+= ""'"" +inputStr[start:end] +""', "" +inputStr[match.start()+1:match.end()-1] +"", """;
		put "    start= match.end()";
		put "#add the rest after the last parameter and close the cats statement     ";
		put "outputStr+= ""'"" +inputStr[start:] +""')"" ";
		put " ";
		put "SAS.symput('parsedString_', outputStr)	";
		put "#print('Parsed String: ', outputStr)";
	run;

	proc python infile= PCODE; quit;
	filename PCODE clear;

	%global parsedString;
	%let parsedString= &parsedString_;

%mend setParamaters;


/* ----------------------------------------------------------------------- */
/* Make http call.                                                         */
/* We give each json file a number (rowNum) for each call we make.         */
/* All files will get combined later in combineHTTPOutput()                */
/* ----------------------------------------------------------------------- */
%macro executeHTTP(rowNum);
	%debugMsg(executeHTTP());

	filename hdinfo '/tmp/hdinfo.txt';

	/* if we make a bach call we submit the payload via a file as it can then be a bigger payload */
	%if &batchcall = Yes %then %do;
		filename payload '/tmp/payload.txt';
	%end;

	%if &_debugLevel > 0 %then %do;
		%put URL: &exe_url;
		%if %symexist(exe_payload) and (&_method = PUT or &_method = POST or &_method = PATCH) %then %do;
			%put The length of the payload is: %length(&exe_payload);
			%put Payload: &exe_payload;
		%end;
	%end;

	/*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/
	/* HTTP Request                              */
	/*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/
	filename httpout "&outputFolder./httpout&rowNum..json";
	proc http
		method= "&_method"
		url= &exe_url 

		%if %symexist(exe_payload) and (&_method = PUT or &_method = POST or &_method = PATCH) %then %do;
			%if &batchcall = Yes %then %do;
				in= payload	
			%end;
			%else %do;
				in= &exe_payload
			%end;
		%end;

		out= httpout
		headerout= hdinfo

		/*if we call a SAS Service and they are not enabled in SAS Studio we set a timeout for 10 sec to not to wait too long */ 
		/*the Viya admin can enable SAS Services to be reached from SAS Studio */ 
		%if &_isSASServiceURL = 1 %then %do;
			%put If "ERROR: HTTP Operation Timed Out." occurs check with SAS Viya administrator if calling SAS Viya services from SAS Studio is enabled.;
			timeout= 10
		%end;
		%else %do;
			timeout= &_timeout.
		%end;

		CLEAR_CACHE 

		%if &_authtype = Basic Auth %then %do;
			username= "&_username"
			password= "&_password"
		%end;


		%if &_authtype = Bearer Token %then %do;
			/* in case there are leading or trailing blanks coming in from the UI we need to get rid of them */
			oauth_bearer= %tslit(%sysFunc(strip(&_bearer_token)))
		%end;

		%if &_isSASServiceURL = 1 %then %do;
			oauth_bearer= sas_services
		%end;
		;
	 	headers 
			%unquote(&_headerLine_0)
			%unquote(&_headerLine_1)
			%unquote(&_headerLine_2)
			%unquote(&_headerLine_3)
			%unquote(&_headerLine_4)
			%unquote(&_headerLine_5)
			%unquote(&_headerLine_6)
			%unquote(&_headerLine_7)
		;

		debug level= &_debugLevel;
	quit;

	filename hdinfo clear;
	filename httpout clear;

	%if &batchcall = Yes %then %do;
		filename payload clear;
	%end;
%mend executeHTTP;


/* ----------------------------------------------------------------------- */
/* combine the output from all http calls into one json file               */
/* we have several http calls if we have several rows in the input table   */
/* In this case we put the result from all calls into one json file.       */
/* ----------------------------------------------------------------------- */
%macro combineHTTPOutput();
	%debugMsg(combineHTTPOutput());

	filename PCODE TEMP;
	data _null_;
		file PCODE;
		put "import json";
		put "import os";
		put "httpoutFolder= SAS.symget('outputFolder')";
		put "httpoutAllFile= SAS.symget('_outputName')";
		put "debugLevel= int(SAS.symget('_debugLevel'))";
		put "try:";
		put "    filesCnt= int(SAS.symget('rowCnt'))";
		put "except:";
		put "    filesCnt= 0";
		put "httpAll={}";
		put " ";
		put "for i in range(filesCnt):";
		put "    try:";
		put "        with open(httpoutFolder +f'/httpout{i+1}.json', 'r') as fHttp:";
		put "            httpOut= json.load(fHttp)";
		put "            httpAll['R' +str(i+1)]= httpOut";
		put "    except:";
		put "        httpAll[i+1]= {}";
		put " ";
		put "if debugLevel == 0:";
		put "    for i in range(filesCnt):";
		put "        try:";
		put "            os.remove(httpoutFolder +f'/httpout{i+1}.json')";	
		put "        except:";
		put "            continue";
		put " ";
		put "httpAllJson= json.dumps(httpAll)";
		put "with open(httpoutFolder +f'/{httpoutAllFile}.json', 'w') as fHttpAll:";
		put "    fHttpAll.write(httpAllJson)";
	run;

	proc python infile= PCODE; quit;
	filename PCODE clear;
%mend combineHTTPOutput;


/* ----------------------------------------------------------------------- */
/* group records together for the batch call. The size of the group        */
/* depends on &firstrec and &lastrec.                                      */
/* execute http request for the group/slice                                */
/* ----------------------------------------------------------------------- */
%macro silceAndExecute(firstrec, lastrec, slice);
	%debugMsg(silceAndExecute());

	/* get records we want to group together */
	proc sql noprint;
		create table work._httpRq_batch_slice as
		select * 
		  from &_inputtable (firstobs=&firstrec obs=&lastrec);

		select count(*) as rowCntSilce
		  into :rowCntSilce
		from work._httpRq_batch_slice;
	quit;

	/* put macro values into file so we can read it from python. We only need to do this the first time we call  silceAndExecute() */
	%if &firstrec = 1 %then %do;
		filename plstruc "/tmp/pls.txt";
		data _null_;
			file plstruc;
			put  "&_payload";
		run;
		filename plstruc clear;
	%end;

	/* generate the payload with the batch data */
	%if &rowCntSilce > 0 %then %do;
		proc ds2;
		data _null_;
			dcl package pymas py;
			dcl nvarchar(5000) pypgm;
			dcl double rc revision;
			dcl varchar(10485760) batch_records;
		
			retain batch_records;
		
			method buidPayload(in_out varchar batchData, varchar(50) batchToken);
			    dcl nvarchar(50) pyCodeFile;
			    pyCodeFile= 'buidPayload_02';
		
			    /* Create python object */
			    py= _new_ pymas();
			
			    /* test object in case it was already loaded into memory */
			    rc= py.useModule(pyCodeFile, 1);
			
			    if rc then do;
					rc= py.appendSrcLine('def buidPayload(batchData, batchToken):');
					rc= py.appendSrcLine('    ''Output:None''');
					rc= py.appendSrcLine('    with open("/tmp/pls.txt", "r") as f:');
					rc= py.appendSrcLine('        payloadStructure= f.read()');
					rc= py.appendSrcLine('    ');
					rc= py.appendSrcLine('    batchToken= "@" +batchToken +"@"');
					rc= py.appendSrcLine('');
					rc= py.appendSrcLine('    batchTokenIdx= payloadStructure.find(batchToken)');
					rc= py.appendSrcLine('    if batchTokenIdx < 0:');
					rc= py.appendSrcLine('        print("Error: Batch token not found in payload structure!")');
					rc= py.appendSrcLine('');
					rc= py.appendSrcLine('    payloadHead= payloadStructure[0:batchTokenIdx]');
					rc= py.appendSrcLine('    payloadTail= payloadStructure[batchTokenIdx+len(batchToken):]');
					rc= py.appendSrcLine('');
					rc= py.appendSrcLine('    payload= payloadHead +batchData +payloadTail');
					rc= py.appendSrcLine('');
					rc= py.appendSrcLine('    with open("/tmp/payload.txt", "w") as f:');
					rc= py.appendSrcLine('        f.write(payload)');
					rc= py.appendSrcLine('    return');
			
			        /* get Python code and push it to the Python interpreter */
			        pypgm= py.getSource();
			        revision= py.publish(pypgm, pyCodeFile);
				end;	
				
				/* set python function to execute */
				rc= py.useMethod('buidPayload');
			
			    /* set parameter for python funtion */
				rc= py.setString ('batchData', batchData);
				rc= py.setString ('batchToken', batchToken);
		
				/* execute python function */
			    rc= py.execute();
			end;
		
			method run();
				dcl varchar(5242880) batch_structure;
				dcl varchar(2) comma;		
		
				set work._httpRq_batch_slice;
		
				if _N_ = 1 then do;
					comma= ' ' ;
				end;
				else do;
					comma= ',' ;
				end;
		
				batch_structure= &batch_structure;
				batch_records= cats(batch_records, comma, batch_structure);
			end;
		
			method term();
				dcl varchar(50) batchToken;
		
				batchToken= %tslit(&_batch_records);
		
				buidPayload(batch_records, batchToken);
			end;
		enddata;
		run;quit;

		/* prepare the rest of the http call and execute the http request for this batch slice */
		%prepAndCallRequest(No, &slice);
	%end;
%mend silceAndExecute;

/* ----------------------------------------------------------------------- */
/* prepare the bacth call by grouping records and put them into            */
/* a table and then runn the http request on the group.                    */
/* Prerequisite is that the REST call does support this kind of call.      */
/* The advantage is that we don't need to call the HTTP request for every  */
/* record in the input table.                                              */
/* ----------------------------------------------------------------------- */
%macro execBatchRequest();
	%debugMsg(execBatchRequest());
	%let firstrec= 1;
	%let lastrec= %eval(&firstrec + &_batch_size-1);
	%let rowCntSilce= 0; /* this is further set in macro %groupRecords() */
	%let slice= 1;

	/* group records and call http request forn the group */
	%do %until (&rowCntSilce = 0);
		 %silceAndExecute(&firstrec, &lastrec, &slice);

		/* increase values to get the next group */
		%let firstrec= %eval(&firstrec + &_batch_size); 
		%let lastrec= %eval(&firstrec + &_batch_size - 1); 
		%let slice= %eval(&slice + 1); 	
	%end;

	/* delete temp table */
	proc delete data= work._httpRq_batch_slice; run;
%mend execBatchRequest;


/* ----------------------------------------------------------------------- */
/* call http for each row in the input table.                              */
/* ----------------------------------------------------------------------- */
%macro prepAndCallRequest(hasInputTable, rowCntSilce);
	%debugMsg(prepAndCallRequest());
	%global rowCnt;

	data _null_;
		length executeHTTP url $2500;
		length payload $32767;

		%if &hasInputTable = Yes %then %do;
			set &_inputtable end= _last_;
			rowNum= _n_; 
		%end;
		%else %do;
			rowNum= &rowCntSilce; 
		%end;

		url= &url; /* &url can either be the generated or the original url. */
		call symput("exe_url", cats("'", trim(url), "'"));

		%if &_method = PUT or &_method = POST or &_method = PATCH %then %do;
			payload= &payload;  /* &payload can either be the generated or the original payload */

			call symput("exe_payload", quote(trim(payload), "'"));
		%end;

		/* execute macro */
		executeHTTP= cats('%executeHTTP(', rowNum, ')');
		call execute(executeHTTP); /* %executeHTTP() */

		%if &hasInputTable = 'Yes' %then %do;
			if _last_ then
		%end;
				call symput("rowCnt", rowNum); /* need to know how often we called http*/
	run;
%mend prepAndCallRequest;


/* ----------------------------------------------------------------------- */
/* merge the columns from the input table with the columns from            */
/* the http result row by row                                              */
/* ----------------------------------------------------------------------- */
%macro mergeInOut();
	%debugMsg(mergeInOut());

	data &_outputtable;
	  if (eof1 and eof2) then stop;
	  if not eof1 then set &_inputtable end=eof1 ;
	  if not eof2 then set &_outputtable end=eof2 ;
	  output;
	  call missing(of _all_);
	run;
%mend mergeInOut;


/* ----------------------------------------------------------------------- */
/* Map the HTTP result header to SAS variables according to the            */ 
/* Header Mapping section in the UI                                        */
/* ----------------------------------------------------------------------- */
%macro mapHeaderTag(mapline);
	%debugMsg(mapHeaderTag());

	filename PCODE TEMP;
	data _null_;
		file PCODE;
		put"SAS.symput('mapKeyError_','No')";
		put"SAS.symput('mapKeyErrorMsg_', '')";
		put"SAS.symput('mapKeyErrorMsg2_', '')";
		put"mapToken= True";
		put" ";
		put"mapline= int(SAS.symget('mapline'))";
		put"headerMappingIn= str(SAS.symget(f'_headerMapping_{mapline}'))";
		put"tagCaseSensetive= int(SAS.symget('_tagCaseSensetive'))";
		put"headerMapping= headerMappingIn.split(':')";
		put" ";
		put"tagCaseSensetive= 0";
		put"tag= headerMapping[0].strip()";
		put"try:";
		put"    macro= headerMapping[1].strip()";
		put"except:";
		put"    print(f""Error in header mapping line {mapline+1}: >"" +SAS.symget(f'_headerMapping_{mapline}') +""<"")";
		put"    print('Check that tag and macro are mapped correctly.')";
		put"    SAS.symput('mapKeyError_','E')";
		put"    SAS.symput('mapKeyErrorMsg_', f""Error in header mapping line {mapline+1}: >"" +SAS.symget(f'_headerMapping_{mapline}') +""<"")";
		put"    SAS.symput('mapKeyErrorMsg2_', 'Check that tag and macro are mapped correctly.')";
		put"    mapToken= False";
		put" ";
		put"#only continue if the token - macro mapping is ok";
		put"if mapToken:";
		put"    value= ''";
		put"    #read the header info file";
		put"    with open('/tmp/hdinfo.txt', 'r') as header:";
		put"        lines= header.readlines()";
		put " ";
		put"    #go through the file and find the tag.";
		put"    for line in lines:";
		put"        line= line.strip()";
		put"        if tagCaseSensetive:";
		put"            if tag == line[0:len(tag)]:";
		put"                value= line[len(tag)+1:].strip()";
		put"        else:";
		put"            if tag.lower() == line[0:len(tag)].lower():";
		put"                value= line[len(tag)+1:].strip()";
		put" ";
		put"    #if tag was found map value to SAS macro";
		put"    if len(value) > 0:";
		put"        SAS.symput('macroName', macro)";
		put"        SAS.symput('macroValue', value)";
		put"    else:";
		put"        print(f'Warning: Could not find tag >{tag}< in header mapping line {mapline+1}')";
		put"        SAS.symput('mapKeyError_','W')";
		put"        SAS.symput('mapKeyErrorMsg_', f'Could not find tag >{tag}< in header mapping line {mapline+1}')";
		put"        SAS.symput('mapKeyErrorMsg2_', 'Make sure tag does exist.')";	
	run;
	
	proc python infile= PCODE; quit;
	filename PCODE clear;

	/* only if we reveived a value we can make it global */	
	%if &mapKeyError_ = No %then %do;
		/* output token and value to the log */
		%put &macroName => &macroValue;
		%global &macroName; 
		%let &macroName= &macroValue;
	%end;

	%global mapKeyError mapKeyErrorMsg mapKeyErrorMsg2;
	%let mapKeyError= &mapKeyError_;
	%let mapKeyErrorMsg= &mapKeyErrorMsg_;
	%let mapKeyErrorMsg2= &mapKeyErrorMsg2_;
%mend mapHeaderTag;


/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
/* MAIN                                                                    */
/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
%macro main();
	%debugMsg(main());

	/* Check output folder if set to "sasserver" - if it was set in the UI*/
	%if &_http_output_dir ~= %then %do;
		%let outputFolder= %substr(&_http_output_dir, 11);
		%let folderserver= %substr(&_http_output_dir, 1, 9);
		data _null_;
			length folderserver $500;
			file print;	
			folderserver= "&folderserver";
			if folderserver ~= "sasserver" then do;
				put "ERROR: Wrong output folder!";
				put "Please select a folder from sasserver not from sascontent.";
				error "ERROR: Wrong output folder! The folder needs to be on sasserver!";
				abort;
			end;
		run;
	%end;
	%else %do;
		%let outputFolder= /tmp; /* default location for the http output files */
	%end;

	/* set the output name for the json file if it is not set in the UI */
	%if &_outputName = %then %do;
		%let _outputName= httpoutAll;
	%end;

	/* if _outputtable variable exists but has no value set to default value */
	%if %symexist(_outputtable) %then %do;
		%if &_outputtable = %then %do;
			%let _outputtable= _HTTP_RESULT; /* default value */
		%end;
	%end;
	%else %do;
		%let _outputtable= _HTTP_RESULT; /* default value */
	%end;

	/*we need to create an empty output table here to prevent an error in case _mergeInOut is ticked but there are no field mappings */
	data &_outputtable;
	run;

	/* if we use an internal API, we have to generate the appropriate URL */	
	%if &_isSASServiceURL = 1 %then %do;
		%generateInternalUrl();
	%end;

	/* prepare url for execution. We need to replace parameters with values if there are parameters in the url */
	%setParamaters(&_URL, -); /* build the dynamic url */
	%let url= &parsedString;

	%debugMsg(URL: %qtrim(&url));

	%if &_method = PUT or &_method = POST or &_method = PATCH %then %do;
		%let payload= ;
		/* if there is a payload prepare it for execution. We need to replace parameters with values if there are parameters in the payload */
		%if &_payload ~= %then %do;
			%if &_batch_size = 0 %then %do; /* if not running batch mode */
				%setParamaters(&_payload, escDQuote); /* build the dynamic payload. Replace parameters in payload with values and escape double quotes in the column values */
			%end;
			%else %do; /* if running batch mode */
				%setParamaters(&_payload, - ); /* build the dynamic payload. Replace parameters in payload with value */
			%end;
			%let payload= &parsedString;
			%debugMsg("Payload: %qtrim(&parsedString)");
		%end;
	%end;

	%let isInputTable= No; /* indicate there is no input table */
	%if %symexist(_inputtable) %then %do; /* if input table variable does exist */
		%if &_inputtable ~= %then %do; /* if there is data coming from an input table */
			%let isInputTable= Yes;
			%if %symexist(_batch_size) = 0 or &_batch_size = %then %do; /* to be compatible with older versions we create &_batch_size if it does not exist */
				%let _batch_size= 0;
			%end;
			%if &_batch_size = 0 %then %do; /* we are NOT running in batch mode */
				%let batchcall= No;
				%prepAndCallRequest(Yes, 0); /* call the http request for each row in the input table */
			%end;
			%else %do; /* Running in BATCH mode: if batch_size > 0 then we call HTTP as batch grouping several input records together*/
				%if (&_method = PUT or &_method = POST or &_method = PATCH) %then %do;
					%let batchcall= Yes;
					%setParamaters(&_batch_structure, escDQuote); /* build the dynamic payload. Replace parameters in payload with values and escape double quotes in the column values */
					%let batch_structure= &parsedString;
					%debugMsg("Batch Structure: %qtrim(&parsedString)");
					/* group records by slice size and call http request */
					%execBatchRequest();
				%end;
				%else %do;
					data _null_;
						file print;	
						put "ERROR: Wrong value in tab Batch 'Record goup seize'!";
						put "Value has to be 0 if http method not like PUT, POST or PATCH";
						error "ERROR: Error in tab Batch 'Record goup seize'. Value has to be 0 if http method not like PUT, POST or PATCH";
						abort;
					run;
				%end;
			%end;
		%end;
	%end;

	/* if there is NO input table */
	%if &isInputTable = No %then %do;
		%let batchcall= No;
		%let rowCnt= 1; /* need to set row count to 1 */
		data _null_;
			length url $2500;
			length payload $32767;
			url= &url; /* &url can either be the generated or the original url. */
			call symput("exe_url", cats("'", trim(url), "'"));

			%if &_method = PUT or &_method = POST or &_method = PATCH %then %do;
				payload= &payload;  /* &payload can either be the generated or the original payload */
				call symput("exe_payload", cats("'", trim(payload), "'"));
			%end;
		run;	
		%executeHTTP(1); /* need to set row count to 1 */
	%end;

	/* check the http staus here as otherwise we might no capture a potential error. */
	%checkHTTPStatus();

	%combineHTTPOutput(); /* put all json output (from each row in the input table) into one file */

	%outputToLibrary(); /* output http result to SAS lib */

	/* if &_fieldMapping in the UI has any input data we map the http result to output columns */
	%if &_fieldMapping ~= %then %do;
		%mapHTTPToColumns(); /* map http result */
		/* if anything went wrong with the mapping we raise an error */
		%checkError();
		/* if set in the ui create macros for the mapped output columns */
		%if &_outputToMacro = 1 %then %do;
			%mapMacros();
		%end;
	%end;

	/* if set in the ui merge http result and input table */
	%if &_mergeInOut = 1 %then %do;
		%mergeInOut();
	%end;

	/* read header output information and map to macros if required in the ui */
	%let i= 0;
	%do %while(&i < &_headerMappingCnt);
		%mapHeaderTag(&i);
		%checkError();
		%let i= %eval(&i+ 1);
	%end;
%mend main;


%main();

/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
/* CLEAN UP                                                                */
/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
/* ----------------------------------------------------------------------- */
/* clean up macros variables used in this step                             */
/* ----------------------------------------------------------------------- */
%symdel url / nowarn;
%symdel rowCnt / nowarn;
%symdel exe_url / nowarn;
%symdel outputFolder / nowarn;
%symdel folderserver / nowarn;
%symdel mapKeyError / nowarn;
%symdel mapKeyErrorMsg / nowarn;
%symdel mapKeyErrorMsg2 / nowarn;
%symdel parsedString / nowarn;
%symdel payload / nowarn;
%symdel exe_payload / nowarn;
%symdel isInputTable / nowarn;
%symdel batch_records / nowarn;
%symdel batchcall / nowarn;

/* ----------------------------------------------------------------------- */
/* clean up macros used in this step                                       */
/* ----------------------------------------------------------------------- */
%sysmacdelete main / nowarn;
%sysmacdelete setParamaters / nowarn; 
%sysmacdelete prepAndCallRequest / nowarn;
%sysmacdelete executeHTTP / nowarn;
%sysmacdelete combineHTTPOutput / nowarn;
%sysmacdelete mergeInOut / nowarn;
%sysmacdelete mapHeaderTag / nowarn;
%sysmacdelete checkError / nowarn;
%sysmacdelete outputToLibrary / nowarn;
%sysmacdelete mapHTTPToColumns / nowarn;
%sysmacdelete generateInternalUrl / nowarn;
%sysmacdelete checkHTTPStatus / nowarn;
%sysmacdelete mapMacros / nowarn;
%sysmacdelete execBatchRequest / nowarn;
%sysmacdelete debugMsg / nowarn;
%sysmacdelete groupRecords / nowarn;