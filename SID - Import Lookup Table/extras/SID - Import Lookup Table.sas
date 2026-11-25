/*----------------------------------------------------------------------------------------*
    This custom step to import and activate (or not) a lookup table for intelligent decisioning from an input table. 
*------------------------------------------------------------------------------------------*/

%macro _import_lkp_table ;

    %put NOTE: ### STEP : SASID - Import lookup table : start ### ;
    
    /*----------------------------------------------------------------------------------------*
        SET lookup table location
    *------------------------------------------------------------------------------------------*/

        %let lkpdir_rc = 0 ; 
        %let _lookup_folder = ; 

        %if &location_type. = Browse to location %then %do ; 
            %let _lookup_folder = &location_browsed. ; 
        %end ;
        %else %if &location_type. = Enter location path %then %do ; 
            %let _lookup_folder = &location_string. ; 
        %end ; 

        %if %sysfunc(kfind(&_lookup_folder., sasserver:))>0 %then %do ; 
            %let lkpdir_rc = 1 ; 
            %put ERROR: # STEP : Invalid lookup table location. Folder must be located on the SAS Content. ;
        %end;
        %else %do ;

            %let _lookup_folder = %sysfunc(tranwrd(&_lookup_folder.,sascontent:,)) ;

            %put NOTE: # STEP : Lookup location folder = "&_lookup_folder" # ;
    
            filename pathinfo temp;
    
            data _null_;
                file pathinfo;
                folder_path = symget('_lookup_folder') ; 
                if substr(folder_path,1,1) = '/' then do ; 
                    folder_path = substr(folder_path, 2) ; 
                end ; 
                folder_array = '"'||strip(tranwrd(folder_path, '/', '","'))||'"' ; 
                json_input = '{"items": ['||strip(folder_array)||'], "contentType": "folder"}';
                put json_input;
            run;
        
            proc http 
             method='POST' 
             url="%sysfunc(getoption(SERVICESBASEURL))/folders/paths" 
             in=pathinfo 
             oauth_bearer=sas_services 
             ;
                headers 'Content-Type'='application/vnd.sas.content.folder.path+json';
            quit;
    
        
            %if &SYS_PROCHTTP_STATUS_CODE. = 404 %then %do;
                %let lkpdir_rc = 1 ; 
                %put ERROR: # STEP : Invalid lookup table location. Folder not found. ; 
            %end ;
            %else %if &SYS_PROCHTTP_STATUS_CODE. ne 200 %then %do;
                %let lkpdir_rc = 1 ; 
                %put ERROR: # STEP : Invalid lookup table location. Bad Request. ; 
            %end ;
    
            filename pathinfo clear ; 

        %end ; 

    /*----------------------------------------------------------------------------------------*
        Create lookup CSV
    *------------------------------------------------------------------------------------------*/

        %let lkp_rc = 1 ;
    
        filename lkp_csv temp ;
        
        proc sql noprint ; 
            create table lookup as 
            select distinct
                "&lookup_nm." as LOOKUP_NM, 
                "&lookup_desc." as DESCRIPTION, 
                "&_lookup_folder" as FOLDER_PATH, 
                &lookup_keys as NAME, 
                &lookup_values as VALUE, 
                "" as DISABLED, 
                "" as ENTITY_SQ_NO, 
                "lookup" as TYPE_NM
            from &inputtable1. ;
        run ;
        quit ; 

        proc export data=lookup 
                    outfile=lkp_csv
                    dbms=csv replace;
        run ; 

        %put NOTE: # STEP : CSV lookup fileref = "lkp_csv" # ; 

        %put NOTE: # STEP : CSV lookup file path = "%sysfunc(pathname(lkp_csv))" # ; 

        data _null_ ; 
            fid = fopen("lkp_csv", "i") ; 
            if fid <= 0 then do ; 
                m=sysmsg(); 
                put m; 
                put "ERROR: # STEP : Invalid lookup CSV file. File could not be opened." ; 
            end ;  
            else do ; 
                rc = fclose(fid) ; 
                call symputx('lkp_rc', "0") ; 
            end ; 
        run ; 
    
    /*----------------------------------------------------------------------------------------*
        Activate Lookup table?
    *------------------------------------------------------------------------------------------*/

        %let _active = NO; 
        %if &activate. = 1 %then %let _active = YES ; 
    
        %put NOTE: # STEP : ACTIVE = "&_active" # ;

    /*----------------------------------------------------------------------------------------*
        Create SAS ID LOOKUP table : DCM_IMPORT_LOOKUP. 
        https://go.documentation.sas.com/doc/en/edmcdc/5.4/edmmacro/n0ni2e3h31k5x3n1v1w4e46z7rnh.htm
    *------------------------------------------------------------------------------------------*/

        %put NOTE: # STEP : Parameters validation --> All rc parameters must return 0 for the import to be executed. ;
        %put NOTE: # STEP : Parameters validation (1) : Lookup table location rc = &lkpdir_rc ; 
        %put NOTE: # STEP : Parameters validation (2) : Lookup file rc = &lkp_rc ; 

        %if %eval (&lkpdir_rc. + &lkp_rc.) = 0 %then %do ; 
            %put NOTE: # STEP : Import lookup macro "DCM_IMPORT_LOOKUP" starting... # ;
                %DCM_IMPORT_LOOKUP (CSV=lkp_csv, ACTIVE=&_active.) ;
            %put NOTE: # STEP : Import lookup macro "DCM_IMPORT_LOOKUP" completed. # ;
        %end ; 
        %else %do ; 
            %put ERROR: # STEP : At least one rc parameter is not valid. Import lookup Cancelled. # ; 
        %end ; 
    
        filename lkp_csv clear ; 
    
    %put NOTE: ### STEP : SASID - Import lookup table : end ### ;

%mend _import_lkp_table ; 

%_import_lkp_table ; 

/*----------------------------------------------------------------------------------------*
   Cleanup SAS macros and SAS macro variables that are not needed anymore
*----------------------------------------------------------------------------------------*/
%sysmacdelete _import_lkp_table /nowarn;
