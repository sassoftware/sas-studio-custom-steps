/***********************************************************************
 
Custom Step for adding labels to columns names on an existing dataset

***********************************************************************/

%macro setlabels(inputtable);
    
        data _null_;
            set &inputtable end=eof;
            file labels;
            if _n_=1 then put 'label';
            put @3 column_name '=' column_label :$quote.;
            if eof then put ';';
        run;

        %if &inputTable_data.^=&outputTable_data. %then %do;
            data &outputTable_data.;
                set &inputTable_data.;
            run;
        %end;
               
        proc datasets lib=&outputTable_data_lib nolist;
            modify &outputTable_data_name;
            %include labels / source2;
        quit;

%mend setlabels;



%macro execute();
    filename labels temp;

    /**************/
    /* Table Mode */
    /**************/

    %if &radiogrp_updatecolumnmode=table %then %do;

        %setlabels(inputtable=&inputTable_metadata);

        filename labels clear;

    %end;

    /********************/
    /* Interactive Mode */
    /********************/

	%else %if &radiogrp_updatecolumnmode=interactive %then %do;
      
        data work.temp;
            length column_name $8. column_label $200.;
            %do i=1 %to &numkey.;
                %let mykey=&&key&i.;
                %let mylabel=&&label&i.;
                column_name=%tslit(%superq(mykey));
                column_label=%tslit(%superq(mylabel));
                output;
            %end;
        run;
        
        %setlabels(inputtable=work.temp);
        
        proc delete data=work.temp;
        run;
        
        filename labels clear;

    %end;

    /********************/
    /* Import file Mode */
    /********************/

    %else %if &radiogrp_updatecolumnmode=impfile %then %do;

        %let locationType=%sysfunc(scan(&infile_metadatafile.,1,:,M));
        %let fullpath=%sysfunc(scan(&infile_metadatafile.,2,:,M));
        %if &locationType=sasserver %then %do;
            filename reffile disk "&fullpath.";
        %end;
        %else %if &locationType=sascontent %then %do;
            %let file = %scan(&fullpath., -1, '/');
            %let path = %substr(&fullpath.,1,%length(&fullpath.)-%length(&file.));
            filename reffile filesrvc folderpath="&path."  filename="&file.";
        %end;

        %if &radiogrp_impfile_delimiter=tab %then %do;
            %let dlm='09'x;
        %end;
        %else %if &radiogrp_impfile_delimiter=other %then %do;
            %let dlm="&inttxt_impfile_del.";
        %end;

        data work.temp;
             infile reffile DLMSTR=&dlm. firstobs=2 truncover ;
             length  column_name $8. column_label $200.;
             input column_name $ column_label $;
        run;

        %setlabels(inputtable=work.temp);
       
        proc delete data=work.temp;
        run;

        filename labels clear;
        filename reffile clear;
    
    %end;

%mend execute;

%execute();