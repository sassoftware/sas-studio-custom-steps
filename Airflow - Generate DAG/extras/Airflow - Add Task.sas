%macro DAGtask ;

   %local __maxInputs __input_tables __new_seq __task_id ;

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
   
   /* Set task id */
   %let __task_id=task&__new_seq ;
   
   data __task__ ;
      length __task_name              $    36
             __task_id                $    36
             __task_seq                     8  
             __task_predecessor_id    $    36
             __task_type              $    10
             __task_object_path       $  1000
             __task_code              $ 32767
             __task_fs_file           $  1000
             __task_fs_con_name       $    50
             __task_fs_poke                 8
             __task_fs_timeout              8
             __task_fs_mode           $    10
             __task_trigger_rule      $    30
             __compute_context        $    50 
             __connection_name        $    50 
             __exec_log               $     7 
             __codegen_init_code      $     7 
             __codegen_wrap_code      $     7
             __job_airflow_macrovars  $     7
             __dag_parameters         $  1000
             __dag_parameter_method   $     7
             __output_var_prefix      $  1000
             __task_datasets_produced $  1000
      ;
      set &__input_tables end=eof ;
      __task_predecessor_id=__task_id ;
      __task_id="&__task_id" ;
      __task_seq=&__new_seq ;
      __task_name="&__task_name" ;
      __task_type="&__task_type" ;
      __task_object_path="&__task_object_path" ;
      __task_code="&__task_code" ;
      __task_fs_file="&__task_fs_file" ;
      __task_fs_con_name="&__task_fs_con_name" ;
      __task_fs_poke=&__task_fs_poke ;
      __task_fs_timeout=&__task_fs_timeout ;
      __task_fs_mode="&__task_fs_mode" ;
      __task_trigger_rule="&__task_trigger_rule" ;
   
      __compute_context=strip("&__compute_context") ;
      __connection_name=strip("&__connection_name") ;
      __exec_log=strip("&__exec_log") ;
      __codegen_init_code=strip("&__codegen_init_code") ;
      __codegen_wrap_code=strip("&__codegen_wrap_code") ;
      __job_airflow_macrovars=strip("&__job_airflow_macrovars") ;
      __dag_parameters=strip("&__dag_parameters") ;
      __dag_parameter_method=strip("&__dag_parameter_method") ;
      __output_var_prefix=upcase(strip("&__output_var_prefix")) ;
      __task_datasets_produced=strip("&__task_datasets_produced") ;
   run ;
   
   data &output_step_1 ;
      length __task_id $ 36 ;
      __task_id="&__task_id" ;
   run ;
   
   data __dag__ ;
      set __dag__ __task__ ;
   run ;

%mend DAGtask ;

%DAGtask ;


/* Clean-up */

/* Clean-up macros */

%if %sysmacexist(DAGtask)=1 %then %do ; 
   %sysmacdelete DAGtask ;
%end ;

