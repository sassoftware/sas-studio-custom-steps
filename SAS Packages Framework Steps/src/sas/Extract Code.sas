%let input_folder_fqp = sascontent:/Users/Stu.Sztukowski@sas.com/My Folder/SPF;

%let input_folder_is_sascontent = %sysevalf(%qscan(%qupcase(&input_folder_fqp), 1, /) = SASCONTENT:, boolean);
%let input_folder_fqp           = %qsubstr(&input_folder_fqp, %index(&input_folder_fqp, /));

%if &input_folder_is_sascontent %then %do;
    filename _steps_ filesrvc
        folderpath=%sysfunc(quote(&input_folder_fqp))
    ;

    %let workdir = %sysfunc(pathname(work));
%end;
    %else %do;
        filename _steps_ %sysfunc(quote(&input_folder_fqp));
    %end;

data a;
    length step $500 step_list $32767;
    did = dopen('_steps_');
    
    do i = 1 to dnum(did);
        step = dread(did,i);
        if upcase(scan(dread(did,i), -1, '.')) = 'STEP' then do;
            if &input_folder_is_sascontent then do;
                fid = filename(
                    '_sfile_',
                    '',
                    'filesrvc', 
                    cat("folderpath=", %sysfunc(quote(&input_folder_fqp)), "filename=", quote(strip(step)))
                );
                
                rc = fcopy('_sfile_', 'workdir');
            end;

            step_list = catx(',', step_list, quote(strip(step)));
            output;
        end;
    end;

    did = dclose(did);

    call symputx('step_list', step_list);

    keep step rc;
run;

