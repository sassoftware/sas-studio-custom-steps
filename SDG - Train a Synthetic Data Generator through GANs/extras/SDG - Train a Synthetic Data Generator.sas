/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Create a global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
*------------------------------------------------------------------------------------------ */

%global _tsdg_run_trigger;

%if %sysevalf(%superq(_tsdg_run_trigger)=, boolean)  %then %do;
	%put NOTE: Trigger macro variable _tsdg_run_trigger does not exist. Creating it now.;
    %let _tsdg_run_trigger=1;
%end;


/*--------------------------------------------------------------------------------------*
   Macro variables to hold the selected interval and nominal input variables.
*---------------------------------------------------------------------------------------*/

%let blankSeparatedIntervalVars = %_flw_get_column_list(_flw_prefix=intervalVars);
%let blankSeparatedNominalVars = %_flw_get_column_list(_flw_prefix=nominalVars);


/*--------------------------------------------------------------------------------------*
   Macro to execute string substitution for "GPU Devices" in case the user enables GPU & 
   specifies a GPU device ID. 

   Note : For those interested, a little dated but insightful SAS Global Forum paper on 
   the best way to evaluate if a macro variable is blank (as used below), provided here:
   http://support.sas.com/resources/papers/proceedings09/022-2009.pdf 
*---------------------------------------------------------------------------------------*/

%macro gpu_status_string_substitute;
   %global deviceArgumentString;
   %if &gpuEnabled.=0 %then %do;
      %let deviceArgumentString=;
   %end;
   %else %do;
      %if %sysevalf(%superq(numDevices)=,boolean) %then %do;
         %let deviceArgumentString=;
      %end;
      %else %do;
         data _null_;
            call symput("deviceArgumentString",",device=&numDevices.");
         run;
      %end;
   %end;

%mend gpu_status_string_substitute;

/* -----------------------------------------------------------------------------------------* 
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
*------------------------------------------------------------------------------------------ */

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;


/* -----------------------------------------------------------------------------------------* 
   This macro loops through all selected input interval variables and creates centroid tables
   for them.
*------------------------------------------------------------------------------------------ */
%macro _tsdg_create_centroids_table;

	data centroids;
		set _null_;
	run;

     /* Loop over all variables that need centroids generation */
     %do i=1 %to &intervalVars_count.;

         %let name&i = %scan(%nrquote(&blankSeparatedIntervalVars.), &i., %str(" "));
         %put NOTE: Running centroid table creation for variable &&name&i.;

         /* Call the GMM action to cluster each variable */
         proc cas ;
         /* -----------------------------------------------------------------------------------------* 
            Obtain values from UI and store inside variables
         *------------------------------------------------------------------------------------------ */
             input_table_name=symget("inputtable1_name_base");
             input_table_lib =symget("inputCaslib");
             print(input_table_lib);
             nonParametricBayes.gmm result=R/
                 table       = {name=input_table_name, caslib=input_table_lib},
                 inputs      = ${&&name&i.},  
                 seed        = 1234567890,
                 maxClusters = 10,
                 alpha       = 1,
                 infer       = {method="VB",
                                maxVbIter =30,
                                covariance="diagonal",
                                threshold=0.01},
                 output      = {casOut={name='_tsdg_score',caslib=input_table_lib, replace=true},
                                copyVars=${&blankSeparatedIntervalVars.}},
                 display     = {names={ "ClusterInfo"}}
                ;
             run;
             saveresult R.ClusterInfo replace dataset=work.weights&i;
         run;
         quit;


         data  weights&i;
             format varname $100.;
             informat varname $100.;
             set  weights&i(rename=(&&name&i.._Mean=Mean
                                    &&name&i.._Variance=Var));
		     varname = "&&name&i";
             std = sqrt(Var);
             drop Var;
         run;

  
         data centroids;
             set weights&i. centroids ;
         run;

     %end;
 %mend _tsdg_create_centroids_table;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
*------------------------------------------------------------------------------------------*/

%macro main_execution_code;

/*-----------------------------------------------------------------------------------------*
   Run the libref check macro in order to obtain the correct Caslib for desired tables.
*------------------------------------------------------------------------------------------*/
      %global inputCaslib;
      %global outputCaslib;
      %global modelCaslib;

      %_usr_getNameCaslib(&inputtable1_lib.);
      %let inputCaslib=&_usr_nameCaslib.;
      %put NOTE: &inputCaslib. is the input caslib.;
      %let _usr_nameCaslib=;

      %_usr_getNameCaslib(&outputtable1_lib.);
      %let outputCaslib=&_usr_nameCaslib.;
      %let _usr_nameCaslib=;

      %_usr_getNameCaslib(&outputtable2_lib.);
      %let modelCaslib=&_usr_nameCaslib.;
      %let _usr_nameCaslib=;


   /* -----------------------------------------------------------------------------------------* 
      Run the _tsdg_create_centroids_table macro to generate the centroids table.
   *------------------------------------------------------------------------------------------ */
   %_tsdg_create_centroids_table;

   data casuser.centroids;
      set centroids;
   run;

   /* -----------------------------------------------------------------------------------------* 
      Execute the gpu_status_string_substitute macro.
   *------------------------------------------------------------------------------------------ */
   %gpu_status_string_substitute;

   proc cas;

      /* -----------------------------------------------------------------------------------------* 
         Obtain values from UI and store inside variables
      *------------------------------------------------------------------------------------------ */
      input_table_name =symget("inputtable1_name_base");
      input_table_lib  =symget("inputCaslib");
      model_table_name =symget("outputtable2_name_base");
      model_table_lib  =symget("modelCaslib");
      output_table_name=symget("outputtable1_name_base");
      output_table_lib =symget("outputCaslib");

      loadactionset "generativeAdversarialNet";   
      generativeAdversarialNet.tabularGanTrain result = r /
         table           = {name = input_table_name, caslib=input_table_lib,vars = ${&blankSeparatedIntervalVars. &blankSeparatedNominalVars.}},
         centroidsTable  = {name = "CENTROIDS", caslib="CASUSER"},
         nominals        = ${&blankSeparatedNominalVars.},
         gpu             = {useGPU=&gpuEnabled. &deviceArgumentString.}
         miniBatchSize   = &miniBatchSize.,  
         optimizerAe     = {method = "ADAM", numEpochs = &aeEpochs.},
         optimizerGan    = {method = "ADAM", numEpochs = &ganEpochs.},
         seed            = 12345,
         scoreSeed       = 0,
         numSamples      = &numSamples.,
         saveState       = {name = model_table_name, caslib=model_table_lib, replace=True},
         casOut          = {name = output_table_name, caslib=output_table_lib, replace = True};
      print r;
	
      table.save /
         table  ={name = model_table_name, caslib=model_table_lib}
         name   =model_table_name
         caslib =model_table_lib
         replace=True
      ;
   quit;


%mend main_execution_code;

/*-----------------------------------------------------------------------------------------*
   END OF MACROS
*------------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/



%if &_tsdg_run_trigger. = 1 %then %do;
   %main_execution_code;
%end;
%if &_tsdg_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled.  Nothing to do.;
%end;
