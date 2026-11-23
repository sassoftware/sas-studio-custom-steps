data __dag__ ;

   length __dag_name                      $   32
          __dag_description               $  256
          __dag_folder                    $ 1000
          __dag_replace                   $    5
          __dag_unpause                   $    5  
          __dag_tags                      $ 1000
          __dag_schedule_type             $   10 
          __dag_schedule_expression       $  256
          __dag_schedule_datasets         $ 1000
          __dag_start_date                $   10
          __dag_end_date                  $   10
          __dag_catchup                   $    5
          __dag_optimization_method       $    8  
          __global_compute_context        $   50 
          __global_connection_name        $   50 
          __global_exec_log               $    5 
          __global_codegen_init_code      $    5 
          __global_codegen_wrap_code      $    5
          __global_job_airflow_macrovars  $    5
          __global_dag_parameters         $ 1000
          __global_dag_parameter_method   $    4
          __task_seq                           8
   ;

   __dag_name=strip("&__dag_name") ;
   __dag_description=strip("&__dag_description") ;
   __dag_folder=strip("&__dag_folder") ;
   __dag_replace=strip("&__dag_replace") ;
   __dag_unpause=strip("&__dag_unpause") ;
   __dag_tags=strip("&__dag_tags") ;
   __dag_schedule_type=strip("&__dag_schedule_type") ;
   __dag_schedule_expression=strip("&__dag_schedule_expression") ;
   __dag_schedule_datasets=strip("&__dag_schedule_datasets") ;
   __dag_start_date=strip("&__dag_start_date") ;
   __dag_end_date=strip("&__dag_end_date") ;
   __dag_catchup=strip("&__dag_catchup") ;
   __dag_optimization_method=strip("&__dag_optimization_method") ;

   __global_compute_context=strip("&__global_compute_context") ;
   __global_connection_name=strip("&__global_connection_name") ;
   __global_exec_log=strip("&__global_exec_log") ;
   __global_codegen_init_code=strip("&__global_codegen_init_code") ;
   __global_codegen_wrap_code=strip("&__global_codegen_wrap_code") ;
   __global_job_airflow_macrovars=strip("&__global_job_airflow_macrovars") ;
   __global_dag_parameters=strip("&__global_dag_parameters") ;
   __global_dag_parameter_method=strip("&__global_dag_parameter_method") ;

   __task_seq=0 ;

run ;

data &output_step_1 ;
   length __task_id $ 32 ;
   __task_id="__INIT__" ;
run ;
