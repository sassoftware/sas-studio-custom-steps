/*
    SAS Documentation: https://developer.sas.com/rest-apis/glossary

    Initialize the following two macro variables.
*/
data _null_; 
	call symputx('viyaHost', kreverse(ksubstr(ksubstr(kreverse("&_BASEURL."), 2), kfind(ksubstr(kreverse("&_BASEURL."), 2), '/') + 1)));
run;
%let inError=0;

%macro getTermTypes;
    /*
        The first of three steps. Get all, with a maximum of '_limit', term types from the Viya system.
    */
    filename tTypes temp;
    proc http
        method ='get'
        url = "&viyaHost./glossary/termTypes?limit=&_limit%nrstr(&)sortBy=&_sortBy"
        oauth_bearer = sas_services
        out = tTypes;
        headers
            "Accept"="application/json, application/vnd.sas.collection+json, application/vnd.sas.error+json"
            "Accept-Item"="application/vnd.sas.glossary.term.type.summary+json";
    run;

    %if %sysfunc(fexist(tTypes)) %then %do;
        libname tTypes json;
        proc sql;
            create table &_output1 as
            select
                id as termTypeId length=36 format=$36.,
                version format=8.,
                name length=512 format=$512.,
                label length=512 format=$512.,
                description length=1024 format=$1024.,
                usageCount format=8.,
                attributeCount format=8.,
                input(creationTimeStamp, E8601DZ.) as creationTimeStamp format=datetime22.3,
                input(modifiedTimeStamp, E8601DZ.) as modifiedTimeStamp format=datetime22.3,
                createdBy length=64 format=$64.,
                modifiedBy length=64 format=$64.
            from
                tTypes.items;
        quit;
    %end;
    %else %do;
        %put ERROR: No response file received for macro 'getTermTypes'. Please review the log for more details.;
        /*
            The following macro variable will prevent the custom step from running further and generating more errors/warnings.
        */
        %let inError = 1;
    %end;
%mend;
%getTermTypes;

/*
    The following table is an intermediate table for _output2.
    The label and name column need to be renamed. 
*/
data termTypeAttributes;
    attrib termTypeId length=$36.;
    attrib name length=$36.;
    attrib label length=$36.;
    attrib description length=$1024.;
    attrib type length=$32.;
    attrib required length=8.;
    attrib defaultValue length=$32.;
    stop;
run;

/*
    The template for the table that contains the values an end-user can choose.

    Note that following table layout is not the final one.
*/
data &_output3;
    attrib attributeId length=$36.;
    attrib items1 length=$32.;
    attrib items2 length=$32.;
    attrib items3 length=$32.;
    attrib items4 length=$32.;
    attrib items5 length=$32.;
    attrib items6 length=$32.;
    attrib items7 length=$32.;
    attrib items8 length=$32.;
    attrib items9 length=$32.;
    attrib items10 length=$32.;
    attrib items11 length=$32.;
    attrib items12 length=$32.;
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
            upcase(libname) = 'TTATTRIB' and
            upcase(memname) = "&tableName" and
            upcase(name) not like '%ORDINAL_%';
    quit;
%mend;

%macro getTermTypeById
(
    termTypeId=
);

    filename ttAttrib temp;
    proc http
        method ='get'
        url = "&viyaHost./glossary/termTypes/&termTypeId"
        oauth_bearer = sas_services
        out = ttAttrib;
        headers
            "Accept"="application/json, application/vnd.sas.collection+json, application/vnd.sas.error+json"
            "Accept-Item"="application/vnd.sas.glossary.term.type.summary+json";
    run;
    
    %if %sysfunc(fexist(ttAttrib)) %then %do;
        libname ttAttrib json;

        /*
            Get the available columns for this instance of the response file.
        */
        %let existing_columns =;
        %existingColumns(tableName=ATTRIBUTES);

        %if &existing_columns ne %then %do;
            proc sql noprint;
                insert into termTypeAttributes
                (
                    termTypeId,
                    &existing_columns
                )
                select
                    "&termTypeId",
                    &existing_columns
                from
                    ttAttrib.attributes;
            quit;
        %end;

        /*
            Make the term type attribut items/values available only in case the
            corresponding table exists.
        */
        %if %sysfunc(exist(TTATTRIB.ATTRIBUTES_ITEMS)) %then %do;
            %let existing_columns =;
            %existingColumns(tableName=ATTRIBUTES_ITEMS);
            proc sql;
                insert into &_output3
                (
                    attributeId,
                    &existing_columns
                )
                select
                    A.name as attributeId length=36 format=$36.,
                    &existing_columns
                from
                    TTATTRIB.ATTRIBUTES A inner join 
                    TTATTRIB.ATTRIBUTES_ITEMS AI on A.ordinal_attributes = AI.ordinal_attributes;
            quit;
        %end;
    %end;
    %else %do;
        %put ERROR: No response file received for macro 'getTermTypeById'. Please review the log for more details.;
        %let inError = 1;
    %end;
%mend;

%macro getTermTypeAttributes;
    /*
        Load each termTypeId into memory
    */
    %let nbr_ids=0;
    data _null_;
        set 
            &_output1(keep=termTypeId) end=last;
        call symputx('termTypeId'||kstrip(put(_N_, 8.)), strip(termTypeId));
        if last then call symputx('nbr_ids', _n_);
    run;

    /*
        And run for each termTypeId the specified macro.
    */
    %do index = 1 %to &nbr_ids;
        %put NOTE: Processing termTypeId (&index of &nbr_ids): &&termTypeId&index;
        %getTermTypeById
            (
                termTypeId = &&termTypeId&index
            );
    %end;

    /*
        Now normalize and clean the _output3 table.

        1. Sort the table
    */
    proc sort data=&_output3; 
        by 
            attributeId; 
    run;

    /*
        2. Transpose the table
    */
    proc transpose 
        data=
            &_output3 
        out=
            &_output3
                (
                    drop=_name_ 
                    rename=(col1=value)
                );
        by 
            attributeId;
        var 
            items1 
            items2 
            items3
            items4
            items5
            items6
            items7
            items8
            items9
            items10
            items11
            items12;
    run;

    /*
        3. Remove the empty values from the table.
    */
    data &_output3;
        set
            &_output3
                (
                    where=(value ne '')
                );
    run;
%mend;

/*
    Only start the gathering of the term type attributes in case 
    we have term types.
*/
%if &inError eq 0 %then %do;
    %getTermTypeAttributes;
%end;

/*
    Create the second output table and rename some of the columns.
*/
data &_output2;
    set
        termTypeAttributes
            (
                rename=
                    (
                        name=attributeId 
                        label=name
                    )
            );
run;

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

libname ttAttrib clear;
filename ttAttrib clear;
%clearTable(tableName=termTypeAttributes);

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
%SYSMACDELETE getTermTypeAttributes / NOWARN;
%SYSMACDELETE getTermTypeById / NOWARN;
%SYSMACDELETE existingColumns / NOWARN;
%SYSMACDELETE getTermTypes / NOWARN;