%macro _stm_sendMessage();
	%local _stm_msg;

    %if &messageType. = simple %then %do;
        * Creation of a simple message - just one line;
        data _null_;
            schema = '"$schema": "http://adaptivecards.io/schemas/adaptive-card.json",';
            type = '"type": "AdaptiveCard",';
            version = '"version": "1.0",';
            text = '"text": "' || "&message." || '"';
            message = "'{" || schema || type || version || text || "}'";
            call symput('_stm_msg', message);
        run;
    
        * Publish to Teams channel with a webhook;
        proc http
            method='POST'
            url="&teams_endpoint."
		    ct='application/json'
            in=&_stm_msg.;
        run;
    %end;
    %else %if &messageType. = info %then %do;
		* Creation of the info message - title, colored line and body content;
        filename msgFile temp;
    
        data _null_;
            file msgFile;
            put '{';
            put '    "@type": "MessageCard",';
            put '    "@context": "https://schema.org/extensions",';
            put '    "summary": "This is the summary property",';
            color = '    "themeColor": "'!! "&msgThemeColor." !!'",';
            put color;
            put '    "sections": [';
            put '    {';
            put '    "startGroup": true,';
            header = '    "title": "'!! "&msgTitle." !!'",';
            put header;
            put '   "activityImage": "",';
            put '   "activityTitle": "",';
            put '   "activitySubtitle": "",';
            put '   "facts": [';
            put '    {';
            put '       "name": "Content:",';
            content = '       "value": "'!! "&msgBody." !!'"';
            put content;
            put '     }';
            put '     ]';
            put '    }' ;
            put '  ]';
            put '}';
        run;
    
        proc http
          method='POST'
          url="&teams_endpoint."
		  ct='application/json'
          in=msgFile;
        run;

		filename msgFile clear;
    %end;

	* Check HTTP response code and notify the user accordingly;
	data _null_;
		if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
	    	putlog 'ERROR: The Teams Message could not be sent';
			putlog "ERROR: The request returned with &SYS_PROCHTTP_STATUS_CODE. - &SYS_PROCHTTP_STATUS_PHRASE.";
	  	end;
	  	else putlog 'NOTE: The Teams Message was sent successfully';
	run;
%mend _stm_sendMessage;

%_stm_sendMessage();

%sysmacdelete _stm_sendMessage;