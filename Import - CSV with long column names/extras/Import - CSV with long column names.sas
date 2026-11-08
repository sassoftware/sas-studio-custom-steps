/***********************************************************************
 
Custom Step for importing a CSV with long column names

***********************************************************************/

%macro importcsv();

    filename labels temp;
    %let locationType=%sysfunc(scan(&infile_origfile,1,:,M));
    %let fullpath=%sysfunc(scan(&infile_origfile,2,:,M));
    %if &locationType=sascontent %then %do;
        %let file = %scan(&fullpath., -1, '/');
        %let path = %substr(&fullpath.,1,%length(&fullpath.)-%length(&file.));
        filename reffile filesrvc folderpath="&path." filename="&file." lrecl=32767;
    %end;
    %else %if &locationType=sasserver %then %do;
        filename reffile disk "&fullpath." lrecl=32767;
    %end;

    %if &radiogrp_col2lab_delimiter=tab %then %do;
        options validvarname=v7;
        proc import datafile=reffile dbms=tab out=&outputTable_data. replace;
        run;
        options validvarname=any;
    %end;
    %else %if &radiogrp_col2lab_delimiter=other %then %do;
        options validvarname=v7;
        proc import datafile=reffile dbms=dlm out=&outputTable_data. replace;
            delimiter="&inttxt_col2lab_del.";
        run;
        options validvarname=any;
    %end;

    proc transpose data=&outputTable_data.(obs=0) out=work.temp;
        var _all_;
    run;

    filename code temp;

    data work.temp;
        length _name_ $32 _label_ $256 ;
        set work.temp;
        infile reffile dsd truncover obs=1;
        input _label_ @@;
        file code;
        put "label '" _name_  "'n=" _label_ :$quote. ";" ;
    run;

    proc datasets nolist lib=&outputTable_data_lib.;
        modify &outputTable_data_name.;
        %include code / source2;
    run;

    proc delete data=work.temp;
    run;

    filename code clear;
    filename reffile clear; 

%mend importcsv;

%importcsv();