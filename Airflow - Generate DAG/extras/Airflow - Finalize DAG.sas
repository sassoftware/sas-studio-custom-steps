/* Generate DAG */

%macro DAGend() ;

   %local __maxInputs __input_tables __new_seq ;

   /* According to the number of inputs permitted - can be changed */
   %let __maxInputs=10 ;
   %let __input_tables= ;
   %do i=1 %to &__maxInputs ;
      %global input_step_&i ;
      %let __input_tables=&__input_tables &&input_step_&i ;
   %end ;
   
   %put &=__input_tables ;

   /* Derive new sequence number */
   data _null_ ;
      retain seq 0 ;
      set __dag__ end=eof ;
      if __task_seq>seq then seq=__task_seq ;
      if eof then call symput("__new_seq",strip(put(seq+1,12.))) ;
   run ;
   %put &=__new_seq ;
   
   data __task__ ;
      length __task_seq 8 __task_id __task_predecessor_id $ 36 ;
      set &__input_tables end=eof ;
      __task_seq=&__new_seq ;
      __task_predecessor_id=__task_id ;
      __task_id="__END__" ;
   run ;
   %put _user_ ;
   
   data __dag__ ;
      /* add last tasks to existing dag definition */
      set __dag__ __task__ ;
      /* Standardize dag_name and task_name
      /* remove characters other than ., -, _, digits, and English letters */
      __dag_name=compress(__dag_name,'.-',"nk") ;
      __task_name=compress(__task_name,'.-',"nk") ;
   run ;

   /* Manage target file location */
   /* Put global parameters back as macro-variables */
   data _null_ ;
      set __dag__(obs=1) ;
      if upcase(scan(__dag_folder,1,":"))="SASSERVER" then do ;
         call execute(cats("filename dag_file '",scan(__dag_folder,2,":"),"/",__dag_name,".py","' ;")) ;
      end ;
      else do ;
         call execute(cats("filename dag_file filesrvc folderPath='",scan(__dag_folder,2,":"),"' filename='",__dag_name,".py' ;")) ;
      end ;
      array global_options{*} __global: ;
      do i=1 to dim(global_options) ;
         call symput(vname(global_options{i}),global_options{i}) ;
      end ;
   run ;
   
   /* Manage overwrite */
   %global stop_now ;
   %let stop_now=0 ;
   data _null_ ;
      set __dag__(obs=1) ;
      dag_filename=cats(scan(__dag_folder,2,":"),"/",__dag_name,".py") ;
      exist=fexist("dag_file") ;
      if exist=1 then putlog "NOTE: DAG file " dag_filename "already exists." ;
      else putlog "NOTE: DAG file " dag_filename "does not exist." ;
      dag_replace=input(__dag_replace,1.) ;
      if dag_replace=1 then putlog "NOTE: Replace DAG file is set." ;
      else putlog "NOTE: Replace DAG file is not set." ;
      if exist=1 and dag_replace=0 then call symput("stop_now","1") ;
   run ;
   %if &stop_now=1 %then %do ;
      %put ERROR: DAG file already exists and replace option is not set. ;
      %return ;
   %end ;
      
   data _null_ ;
      file dag_file ;
      put "from datetime import datetime, timedelta" ;
      put "from airflow import DAG, Dataset" ;
      put "from airflow.sensors.filesystem import FileSensor" ;
      put "from sas_airflow_provider.operators.sas_studio import SASStudioOperator" ;
      put "from sas_airflow_provider.operators.sas_jobexecution import SASJobExecutionOperator" ;
      put "from sas_airflow_provider.operators.sas_create_session import SASComputeCreateSession" ;
      put "from sas_airflow_provider.operators.sas_delete_session import SASComputeDeleteSession" ;
   run ;

   data _null_ ;
      file dag_file mod ;
      set __dag__(obs=1) ;

      put ;
      put "dag = DAG(dag_id=""" __dag_name +(-1) """," ;

      if __dag_description ne "" then do ;
         put "   description=""" __dag_description +(-1) """," ;
      end ;

      if __dag_schedule_type = "EXPRESSION" then do ;
         if substr(strip(__dag_schedule_expression),1,10)="timedelta(" then do ;
            put "   schedule=" __dag_schedule_expression +(-1) "," ;
         end ;
         else if __dag_schedule_expression ne "" then do ;
            put "   schedule=""" __dag_schedule_expression +(-1) """," ;
         end ;
         else put "   schedule=None," ;
      end ;
      else if __dag_schedule_type = "DATASET" then do ;
         if __dag_schedule_datasets ne "" then do ;
            put +3 "schedule=[" @ ;
            length ds $ 256 ;
            c2=countw(__dag_schedule_datasets,",","q") ;
            do j=1 to c2 ;
               ds=strip(scan(__dag_schedule_datasets,j,",","q")) ;
               if j<c2 then put "Dataset(""" ds +(-1) """)," @ ;
               else put "Dataset(""" ds +(-1) """)" @ ;
            end ;
            put "]," ;
         end ;
      end ;
   
      if __dag_start_date ne "" then do ;
         sd=input(__dag_start_date,yymmdd10.) ;
         __dag_start_date_custom=cats("datetime(",strip(put(sd,year.)),",",strip(put(sd,month.)),",",strip(put(sd,day.)),")") ;
   
         put "   start_date=" __dag_start_date_custom +(-1) "," ;
   
      end ;
   
      if __dag_end_date ne "" then do ;
         ed=input(__dag_end_date,yymmdd10.) ;
   
         __dag_end_date_custom=cats("datetime(",strip(put(ed,year.)),",",strip(put(ed,month.)),",",strip(put(ed,day.)),")") ;
   
         put "   end_date=" __dag_end_date_custom +(-1) "," ;
   
      end ;

      if __dag_unpause ne "0" then do ;
         put "   is_paused_upon_creation=False," ;
      end ;


      if __dag_tags ne "" then do ;
         put "   tags=[" __dag_tags +(-1) "]," ;
      end ;
   
      put "   catchup=" __dag_catchup +(-1) ")" ;
      
      put ;

      if __global_dag_parameters ne "" then do ;
         length param $ 256 ;
         put "global_params = {" ;
         c=countw(__global_dag_parameters,",","q") ;
         do i=1 to c ;
            param=strip(scan(__global_dag_parameters,i,",","q")) ;
            if i<c then put +3 param +(-1) "," ;
            else put +3 param ;
         end ;
         put "}" ;
         put ;
      end ;

      if __dag_optimization_method = "SERIAL" then do ;
         length session_name $ 36 ;
         session_name=uuidgen() ;
         put "__task0 = SASComputeCreateSession(task_id=""0_create_session""," ;
         put "   compute_context_name=""" __global_compute_context +(-1) """," ;
         put "   connection_name=""" __global_connection_name +(-1) """," ;
         put "   session_name=""" session_name +(-1) """," ;
         put "   dag=dag)" ;
         put ;
         put "__task9999 = SASComputeDeleteSession(task_id=""9999_delete_session""," ;
         put "   connection_name=""" __global_connection_name +(-1) """," ;
         put "   compute_session_id=""{{ ti.xcom_pull(key='compute_session_id', task_ids=['0_create_session'])|first }}""," ;
         put "   dag=dag)" ;
         put ;
      end ;

      /* Put __dag_optimization_method as global macro-variable for later use */
      call symput("__dag_optimization_method",strip(__dag_optimization_method)) ;
   
   run ;
   
   proc freq data=__dag__(firstobs=2 where=(__task_id ne "__END__")) noprint order=data ;
      tables __task_id*__task_name*__task_type*__task_object_path*__task_code*
             __task_fs_file*__task_fs_con_name*__task_fs_poke*__task_fs_timeout*__task_fs_mode*__task_trigger_rule*
             __compute_context*__connection_name*__exec_log*__codegen_init_code*__codegen_wrap_code*__job_airflow_macrovars*
             __dag_parameters*__dag_parameter_method*__task_datasets_produced*__output_var_prefix
         / out=__distinct_tasks__(drop=count percent) ;
   run ;
   
   data _null_ ;
      length task_label       $  256 
             object_path_type $    7
             object_path      $ 1000 
             object_name      $  256
             object_type      $    7
             param_dict_name  $   32
             code_name        $   32
             fs_file          $  256 ;
      file dag_file mod ;
      set __distinct_tasks__ ;

      if upcase(__task_type)="CODE" then object_path_type="raw" ;
      else if upcase(scan(__task_object_path,1,":"))="SASSERVER" then object_path_type="compute" ;
      else object_path_type="content" ;
   
      object_path=scan(__task_object_path,2,":") ;
   
      object_name=scan(__task_object_path,-1,":/") ;

      /* Assuming an object ending with .flw is a FLOW, and .sas (or embedded code) is a PROGram, otherwise it's a JOB */
      if upcase(scan(object_name,-1,'.'))="FLW" then object_type="flow" ;
      else if upcase(scan(object_name,-1,'.'))="SAS" or upcase(__task_type)="CODE" then object_type="program" ;
      else object_type="job" ;

      /* If task_name not empty, take it, otherwise take object name */
      /* remove characters other than ., -, _, digits, and English letters */
      task_label=ifc(strip(__task_name) ne "",strip(__task_name),catx("_",put(_n_,12.),compress(object_name,'.-',"nk"))) ;

      /* Manage embedded code */
      if object_path_type="raw" then do ;
         task_label=ifc(strip(__task_name) ne "",strip(__task_name),catx("_",put(_n_,12.),"code")) ;
         code_name=cats(__task_id,"_code") ;
         put code_name "= '''" ;
         length line $ 256 ;
         c1=countw(__task_code,";","q") ;
         do i=1 to c1 ;
            line=scan(__task_code,i,";","q") ;
            put line ";" ;
         end ;
         put "'''" ;
         put ;
      end ; 
   
      if __compute_context = "INHERIT" then __compute_context = "&__global_compute_context" ;
      if __connection_name = "INHERIT" then __connection_name = "&__global_connection_name" ;
      if __exec_log = "INHERIT" then __exec_log = "&__global_exec_log" ;
      if __codegen_init_code = "INHERIT" then __codegen_init_code = "&__global_codegen_init_code" ;
      if __codegen_wrap_code = "INHERIT" then __codegen_wrap_code = "&__global_codegen_wrap_code" ;
      if __job_airflow_macrovars = "INHERIT" then __job_airflow_macrovars = "&__global_job_airflow_macrovars" ;
      if __dag_parameters not in ("","INHERIT") then do ;
         length param $ 256 ;
         param_dict_name=cats(__task_id,"_params") ;
         put param_dict_name "= {" ;
         c2=countw(__dag_parameters,",","q") ;
         do j=1 to c2 ;
            param=strip(scan(__dag_parameters,j,",","q")) ;
            if j<c2 then put +3 param +(-1) "," ;
            else put +3 param ;
         end ;
         put "}" ;
         put ;
      end ;
      else if __dag_parameters = "INHERIT" and symget("__global_dag_parameters") ne "" then param_dict_name="global_params" ;
      else param_dict_name="" ;

      if __dag_parameter_method = "INHERIT" then __dag_parameter_method = "&__global_dag_parameter_method" ;


      if upcase(__task_type)="FILESENSOR" then do ;
         task_label=ifc(strip(__task_name) ne "",strip(__task_name),catx("_",put(_n_,12.),"wait_for_file")) ;
         fs_file=scan(__task_fs_file,2,":") ;
         put __task_id +(-1) " = FileSensor(task_id=""" task_label +(-1) """," ;
         put "   filepath=""" fs_file +(-1) """," ;
         put "   fs_conn_id=""" __task_fs_con_name +(-1) """," ;
         put "   poke_interval=" __task_fs_poke +(-1) "," ;
         put "   timeout=" __task_fs_timeout +(-1) "," ;
         put "   mode=""" __task_fs_mode +(-1) """," ;
      end ;
      else if object_type in ("flow","program") then do ;   
         put __task_id +(-1) " = SASStudioOperator(task_id=""" task_label +(-1) """," ;
         put "   exec_type=""" object_type +(-1) """," ;
         put "   path_type=""" object_path_type +(-1) """," ;
         if object_path_type="raw" then 
            put "   path=" code_name +(-1) "," ;
         else put "   path=""" object_path +(-1) """," ;
         if symget("__dag_optimization_method") = "SERIAL"
            then put "   compute_session_id=""{{ ti.xcom_pull(key='compute_session_id', task_ids=['0_create_session'])|first }}""," ;
         put "   compute_context=""" __compute_context +(-1) """," ;
         put "   connection_name=""" __connection_name +(-1) """," ;
         put "   exec_log=" __exec_log +(-1) "," ;
         put "   codegen_init_code=" __codegen_init_code +(-1) "," ;
         put "   codegen_wrap_code=" __codegen_wrap_code +(-1) "," ;
         if param_dict_name ne "" then do ;
            if __dag_parameter_method in ("MV","BOTH") then do ;
               put "   macro_vars=" param_dict_name +(-1) "," ;
            end ;
            if __dag_parameter_method in ("EV","BOTH") then do ;
               put "   env_vars=" param_dict_name +(-1) "," ;
            end ;
         end ;
         if __output_var_prefix ne "" then do ;
            put "   output_macro_var_prefix=""" __output_var_prefix +(-1) """," ;
         end ;
      end ;
      else if object_type="job" then do ;   
         put __task_id +(-1) " = SASJobExecutionOperator(task_id=""" task_label +(-1) """," ;
         put "   job_name=""" object_path +(-1) """," ;
         put "   connection_name=""" __connection_name +(-1) """," ;
         put "   job_exec_log=" __exec_log +(-1) "," ;
         put "   add_airflow_vars=" __job_airflow_macrovars +(-1) "," ;
         if param_dict_name ne "" then do ;
            put "   parameters=" param_dict_name +(-1) "," ;
         end ;
         else put "   parameters={}," ;
      end ;

      if __task_datasets_produced ne "" then do ;
         put +3 "outlets=[" @ ;
         length ds $ 256 ;
         c3=countw(__task_datasets_produced,",","q") ;
         do k=1 to c3 ;
            ds=strip(scan(__task_datasets_produced,k,",","q")) ;
            if k<c3 then put "Dataset(""" ds +(-1) """)," @ ;
            else put "Dataset(""" ds +(-1) """)" @ ;
         end ;
         put "]," ;
      end ;

      put "   trigger_rule='" __task_trigger_rule +(-1) "'," ;

      put "   dag=dag)" ;
      put ;
   
   run ;
   
   /* If SERIAL, set __task0 as first step */
   %if "&__dag_optimization_method" = "SERIAL" %then %do ;
      data _null_ ;
         file dag_file mod ;
         set __dag__(where=(__task_predecessor_id="__INIT__")) ;
         put "__task0 >> " __task_id ;
      run ;
   %end ;

   data _null_ ;
      file dag_file mod ;
      set __dag__(firstobs=2) ;
      if __task_id ne "__END__" and __task_predecessor_id ne "__INIT__" then do ;
         put __task_predecessor_id ">> " __task_id ;
      end ;
   run ;

   /* If SERIAL, set __task9999 as last step */
   %if "&__dag_optimization_method" = "SERIAL" %then %do ;
      data _null_ ;
         file dag_file mod ;
         set __dag__(where=(__task_id="__END__")) ;
         put __task_predecessor_id ">> __task9999" ;
      run ;
   %end ;


%mend DAGend ;

%DAGend ;


/* Clean-up */

/* Clean-up custom steps tables */

proc datasets lib=work nowarn noprint ;
   delete __dag__ __distinct_tasks__ __task__ ;
quit ;

/* Clean-up macros */

%if %sysmacexist(DAGend)=1 %then %do ; 
   %sysmacdelete DAGend ;
%end ;

