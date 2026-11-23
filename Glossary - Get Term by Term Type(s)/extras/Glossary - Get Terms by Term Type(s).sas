/*
    SAS Documentation: https://developer.sas.com/rest-apis/glossary

    Initialize the following two macro variables.
*/
data _null_; 
	call symputx('viyaHost', reverse(substr(substr(reverse("&_BASEURL."), 2), find(substr(reverse("&_BASEURL."), 2), '/') + 1)));
run;
%let inError=0;

/*
    The basis for the _output1 table.
    Note that columns need to be renamed and converted from character to timestamp for the final output table.
*/
data terms;
    attrib Id length=$36.;
    attrib termTypeId length=$36.;
    attrib termTypeLabel length=$512.;
    attrib version length=8.;
    attrib name length=$512.;
    attrib description length=$8192.;
    attrib definition length=$1024.;
    attrib parentId length=$36.;
    attrib assetCount length=8.;
    attrib isDraft length=8.;
    attrib status length=$16.;
    attrib createdBy length=$64.;
    attrib creationTimeStamp length=$24.;
    attrib modifiedBy length=$64.;
    attrib modifiedTimeStamp length=$24.;
    stop;
run;

data &_output2;
    attrib termId length=$36.;
    attrib attributeId length=$36.;
    attrib attributeValue length=$1024.;
    stop;
run;

/*
    Not all columns are available for each term type.
    The following macro gives me the columns that ARE available.
*/
%macro existingColumns
(
    tableName=
);    
    proc sql noprint;
        select
            name into :existing_columns separated by ', '
        from
            dictionary.columns
        where
            upcase(libname) = 'TERMS' and
            upcase(memname) = "&tableName" and
            upcase(name) not like '%ORDINAL_%';
    quit;
%mend;

%macro getTermsByTermType
(
    termTypeId=
);
    filename terms temp;
    /*
        The following API call extracts terms for the specified termTypeId and for the given
        'draft' filtering.
    */
    proc http
        method ='get'
        url = "&viyaHost./glossary/terms?filter=eq(termTypeId, '&termTypeId')%nrstr(&)allowDrafts=&_allowDraft%nrstr(&)limit=&_limit"
        oauth_bearer = sas_services
        out = terms;
        headers
            "Accept"="application/json, application/vnd.sas.collection+json, application/vnd.sas.error+json"
            "Accept-Item"="application/vnd.sas.glossary.term+json";
    run;

    /*
        Only add the terms if we've received feedback.
    */
    %if %sysfunc(fexist(terms)) %then %do;
        libname terms json;

        %let existing_columns =;
        %existingColumns(tableName=ITEMS);

        %if &existing_columns ne %then %do;
            proc sql noprint;
                insert into terms
                (
                    &existing_columns
                )
                select
                    &existing_columns
                from
                    terms.items;
            quit;
        %end;
    %end;
    %else %do;
        %put ERROR: No response file received for macro 'getTermsByTermType'. Please review the log for more details.;
        %let inError = 1;
    %end;
%mend;

%macro getTermsByTermTypeId;
    /*
        Load each termTypeId into memory
    */
    %let nbr_ids=0;
    data _null_;
        set 
            &_input1(keep=&_idColumn) end=last;
        call symputx("&&_idColumn"||kstrip(put(_N_, 8.)), strip(&_idColumn));
        if last then call symputx('nbr_ids', _n_);
    run;

    /*
        And run for each termTypeId the specified macro.
    */
    %do index = 1 %to &nbr_ids;
        %put NOTE: Processing termTypeId (&index of &nbr_ids): &&&_idColumn&index;
        %getTermsByTermType
            (
                termTypeId = &&&_idColumn&index
            );
    %end;
%mend;

%if &inError eq 0 %then %do;
    %getTermsByTermTypeId;
%end;

%macro getTermsByTermId
(
    termId=
);
    filename terms temp;
    proc http
        method ='get'
        url = "&viyaHost./glossary/terms/&termId?allowDraft=&_allowDraft%nrstr(&)limit=&_limit"
        oauth_bearer = sas_services
        out = terms;
        headers
            "Accept"="application/vnd.sas.glossary.term+json, application/vnd.sas.error+json";
    run;

    /*
        The attributes section of the json response file can't be processed
        using the json libname engine. So we do it the old fashioned way.

        Assmumptions here are:
        - The size of the response file has a maximum of 32 Kb.
        - The response file contains a json string on 1 line.
    */
    %if %sysfunc(fexist(terms)) %then %do;
        data termAttributes
            (
                keep=
                    termId
                    attributeId
                    attributeValue
            );
            infile 
                terms 
                lrecl=32767
                truncover;

            attrib json length=$32767.;
            attrib attrs length=$32767.;
            attrib pair length=$1024.;
            attrib termId length=$36.;
            attrib attributeId length=$36.;
            attrib attributeValue length=$1024.;

            input json $char32767.;
            
            /*
                Only continue processing in case we have attributes to process.            
            */
            if kindex(json,'"attributes"') = 0 then stop;

            /* 
                Extract content inside attributes:{ ... } 
            */
            attrs = prxchange('s/.*"attributes":\{//', 1, json);
            attrs = prxchange('s/}.*$//', 1, attrs);
            termId = "&termId";

            /*
                Only continue in case there are attributes to process.
            */
            if missing(attrs) then stop;

            /* 
                Regex to split on commas OUTSIDE quotes 
            */
            retain rxSplit;
            if _n_ = 1 then
                rxSplit = prxparse('/,(?=(?:[^"]*"[^"]*")*[^"]*$)/');

            pos = 1;
            start = 1;

            /* 
                Loop through comma-separated key:value pairs 
            */
            do while (prxmatch(rxSplit, ksubstr(attrs, pos)));
                offset = prxmatch(rxSplit, ksubstr(attrs, pos));
                len = offset - 1;

                pair = ksubstr(attrs, start, len);
                call missing(attributeId, attributeValue);

                pair = kcompress(kstrip(pair), '"');

                attributeId = kstrip(kscan(pair, 1, ':'));
                attributeValue = kstrip(ksubstr(pair, klength(attributeId) + 2));

                pos + offset;
                start + offset;
        
                if not missing(attributeId) then output;
            end;

            /*
                Process the last one.
            */
            pair  = compress(kstrip(ksubstr(attrs, start)), '"');
            attributeId = kstrip(kscan(pair, 1, ':'));
            attributeValue = kstrip(ksubstr(pair, klength(attributeId) + 2));

            if not missing(attributeId) then output;
        run;

        /*
            Add the current batch of attributes to the second output table.
        */
        proc sql noprint;
            insert into &_output2 select * from termAttributes;
        quit;
    %end;
    %else %do;
        %put ERROR: No response file received for macro 'getTermsByTermId'. Please review the log for more details.;
        %let inError = 1;
    %end;
%mend;

%macro getTermAttrValues;
    /*
        Load each termId into memory
    */
    %let nbr_ids=0;
    data _null_;
        set 
            &_output1
                (
                    keep=termId
                ) end=last;
        call symputx("termId"||kstrip(put(_N_, 8.)), strip(termId));
        if last then call symputx('nbr_ids', _n_);
    run;

    /*
        And run for each termTypeId the specified macro.
    */
    %do index = 1 %to &nbr_ids;
        %put NOTE: Processing termId (&index of &nbr_ids): &&termId&index;
        %getTermsByTermId
            (
                termId = &&termId&index
            );
    %end;
%mend;

/*
    Sort the resulting table according to the end-user's requirments.
*/
proc sort data=terms;
    by 
        &_sortBy;
run;

/*
    Create the first output table based on:

    1. The terms table.
    2. a renamed id column.
    3. converted creation- and modifiedTimeStamp
*/

data &_output1
    (
        drop=
            _creationTimeStamp 
            _modifiedTimeStamp 
            termTypeLabel
        rename=
            (id = termId)
    );
    attrib creationTimeStamp length=8. format=datetime22.3;
    attrib modifiedTimeStamp length=8. format=datetime22.3;

    set
        terms
            (
                rename=
                    (
                        creationTimeStamp=_creationTimeStamp 
                        modifiedTimeStamp=_modifiedTimeStamp
                    )
            );
    /*
        Convert the source columns to be of type datetime22.3
    */
    creationTimeStamp = input(_creationTimeStamp, E8601DZ.);
    modifiedTimeStamp = input(_modifiedTimeStamp, E8601DZ.);
run;

/*
    The following macro depends on the _output1 table to be done and ready.
*/
%if &inError eq 0 %then %do;
    %getTermAttrValues;
%end;

/*
    Clear libname-, filename references and work tables.
*/
%macro clearTable
(
    tableName=
);
    proc datasets library=WORK memtype=(data view) nolist nowarn;
        delete &tableName;
    quit;
%mend;

libname terms clear;
filename terms clear;
%clearTable(tableName=terms);
%clearTable(tableName=termAttributes);

/*
    Remove all macro variables from memory.
*/
%symdel inError /NOWARN;
%symdel nbr_ids /NOWARN;
%symdel existing_columns /NOWARN;
%symdel viyaHost /NOWARN;

/*
    Remove all macros from memory.
*/
%SYSMACDELETE clearTable / NOWARN;
%SYSMACDELETE getTermAttrValues / NOWARN;
%SYSMACDELETE getTermsByTermId / NOWARN;
%SYSMACDELETE existingColumns / NOWARN;
%SYSMACDELETE getTermsByTermTypeId / NOWARN;