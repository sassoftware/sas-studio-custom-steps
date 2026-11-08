/*==========================================================================* 
 * Custom Step:     Append                                                  * 
 * Transform:       Append                                                  * 
 * Description:     This macro appends data to target table, optionally     *
 *                  maintaining an column with and unique incremental id    *
 *==========================================================================*/
%macro append( force=
			,nowarn=
			,columnToAssignIncrementalId= 
			);
	%if %sysfunc(exist(&outputtable1)) ne 1 %then %do;
		%let startId=0;

		/* Copy table as is */
		data &outputtable1;
			set &inputtable1;

			%if %str(&columnToAssignIncrementalId) ne %str() %then %do;
				attrib &columnToAssignIncrementalId length=8 format=best.;
				&columnToAssignIncrementalId=&startId+_n_;
			%end;
		run;

	%end;
	%else %do;

		/* Determine startId */
		%if %str(&columnToAssignIncrementalId) ne %str() %then %do;

			proc sql noprint;
				select max(&columnToAssignIncrementalId) into:startId
					from &outputtable1;
			quit;

			/* Create temp table with id */
			data work.__appendUniqueId;
				set &inputtable1;
				attrib &columnToAssignIncrementalId length=8 format=best.;
				&columnToAssignIncrementalId=max(&startId,0)+_n_;
			run;

			proc append base=&outputtable1. 
				data=work.__appendUniqueId
				%if &force. = Yes %then 
					force;
				%if &nowarn. = Yes %then
					nowarn;;
			run;

		%end;
		%else %do;

			proc append base=&outputtable1. 
				data=&inputtable1.
				%if &force. = Yes %then 
					force;
				%if &nowarn. = Yes %then
					nowarn;;
			run;

		%end;
	%end;
%mend append;

%append( force=&force., nowarn=&nowarn., columnToAssignIncrementalId=&incrementalIdColumn_name);