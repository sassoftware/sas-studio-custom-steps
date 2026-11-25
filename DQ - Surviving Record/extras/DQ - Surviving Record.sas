%macro usr_dqsurvr ;

	%let _rowRule1=(&Rule1Operator, &rowRule1) ;
	%if &row1columnvalue ne %str() or &row1value ne %str() %then %do ;
		%if %upcase(&row1type)=VALUE %then %do ;
			%if	&Rule1Operator ne %str(equal to)
				and %str(&Rule1Operator) ne %str(greater than)
				and %str(&Rule1Operator) ne %str(less than)
				and %str(&Rule1Operator) ne %str(greater or equal to)
				and %str(&Rule1Operator) ne %str(less than or equal to) %then %do ;
				
				%put WARNING: You can use VALUE only with relational operator equal to: equal, less, greater, less equal or greater equal. ;
				%put WARNING: VALUE Ignored. ;
				
			%end ;
			%else %do ;
				%let _rowRule1=(&Rule1Operator, &rowRule1, &row1value) ;
			%end ;
		%end ;
		%else %do ;
			%let _rowRule1=(&Rule1Operator, &rowRule1, &row1columnvalue) ;
		%end ;
	%end ;
	
	%let _rowRule2= ;
	%if &rowRulesOperator ne %str() %then %do ;
		%let _rowRule2=(&Rule2Operator, &rowRule2);
		%if &row2columnvalue ne %str() or &row2value ne %str()  %then %do ;
			%if %upcase(&row2type)=VALUE %then %do ;
				%if	&Rule2Operator ne %str(equal to)
					and %str(&Rule2Operator) ne %str(greater than)
					and %str(&Rule2Operator) ne %str(less than)
					and %str(&Rule2Operator) ne %str(greater or equal to)
					and %str(&Rule2Operator) ne %str(less than or equal to) %then %do ;
					
					%put WARNING: You can use VALUE only with relational operator equal to: equal, less, greater, less equal or greater equal. ;
					%put WARNING: VALUE Ignored. ;
					
				%end ;
				%else %do ;
					%let _rowRule2=(&Rule2Operator, &rowRule2, &row2value) ;
				%end ;	
			%end ;
			%else %do ;
				%let _rowRule2=(&Rule2Operator, &rowRule2, &row2columnvalue) ;
			%end ;
		%end ;
	%end ;
	
	%let _fColRuleAppCols= ;
	%if &fColRuleAppCols_count > 0 %then %do ;
		%let _fColRuleAppCols=%str(( &fColRuleAppCols )) ;
	%end ;
	
	%let _columnselector1= ;
	%if &columnselector1 ne %str() %then %do ;
		%let _columnselector1=(&ColumnRule1Operator, &columnselector1) ;
		%if &column1value ne %str() or &column1columnvalue ne %str() %then %do ;
			%if %upcase(&ColumnRule1_type)=VALUE %then %do ;
				%if	&ColumnRule1Operator ne %str(equal to)
					and %str(&ColumnRule1Operator) ne %str(greater than)
					and %str(&ColumnRule1Operator) ne %str(less than)
					and %str(&ColumnRule1Operator) ne %str(greater or equal to)
					and %str(&ColumnRule1Operator) ne %str(less than or equal to) %then %do ;
					
					%put WARNING: You can use VALUE only with relational operator equal to: equal, less, greater, less equal or greater equal. ;
					%put WARNING: VALUE Ignored. ;
					
				%end ;
				%else %do ;
					%let _columnselector1=(&ColumnRule1Operator, &columnselector1, &column1value) ;
				%end ;	
			%end ;
			%else %do ;
				%let _columnselector1=(&ColumnRule1Operator, &columnselector1, &column1columnvalue) ;
			%end ;
		%end ;
	%end ;
	
	%let _columnselector2= ;
	%if %str(&columnoperator) ne %str() %then %do ;
		%let _columnselector2=(&ColumnRule2Operator, &columnselector2) ;
		%if &column2value ne %str() or &column2columnvalue ne %str() %then %do ;
			%if %upcase(&ColumnRule2_type)=VALUE %then %do ;
				%if	&ColumnRule2Operator ne %str(equal to)
					and %str(&ColumnRule2Operator) ne %str(greater than)
					and %str(&ColumnRule2Operator) ne %str(less than)
					and %str(&ColumnRule2Operator) ne %str(greater or equal to)
					and %str(&ColumnRule2Operator) ne %str(less than or equal to) %then %do ;
					
					%put WARNING: You can use VALUE only with relational operator equal to: equal, less, greater, less equal or greater equal. ;
					%put WARNING: VALUE Ignored. ;
					
				%end ;
				%else %do ;
					%let _columnselector2=(&ColumnRule2Operator, &columnselector2, &column2value) ;
				%end ;
			%end ;
			%else %do ;
				%let _columnselector2=(&ColumnRule2Operator, &columnselector2, &column2columnvalue) ;
			%end ;
		%end ;
	%end ;
	
	%let _columnselector3= ;
	%if &columnselector3 ne %str() %then %do ;
		%let _columnselector3=(&ColumnRule3Operator, &columnselector3) ;
		%if &column3value ne %str() or &column3columnvalue ne %str() %then %do ;
			%if %upcase(&ColumnRule3_type)=VALUE %then %do ;
				%if	&ColumnRule3Operator ne %str(equal to)
					and %str(&ColumnRule3Operator) ne %str(greater than)
					and %str(&ColumnRule3Operator) ne %str(less than)
					and %str(&ColumnRule3Operator) ne %str(greater or equal to)
					and %str(&ColumnRule3Operator) ne %str(less than or equal to) %then %do ;
					
					%put WARNING: You can use VALUE only with relational operator equal to: equal, less, greater, less equal or greater equal. ;
					%put WARNING: VALUE Ignored. ;
					
				%end ;
				%else %do ;
					%let _columnselector3=(&ColumnRule3Operator, &columnselector3, &column3value) ;
				%end ;	
			%end ;
			%else %do ;
				%let _columnselector3=(&ColumnRule3Operator, &columnselector3, &column3columnvalue) ;
			%end ;
		%end ;
	%end ;
	
	%let _columnselector4= ;
	%if %str(&columnoperator2) ne %str() %then %do ;
		%let _columnselector4=(&ColumnRule4Operator, &columnselector4) ;
		%if &column4value ne %str() or &column4columnvalue ne %str() %then %do ;
			%if %upcase(&ColumnRule4_type)=VALUE %then %do ;
				%if	&ColumnRule4Operator ne %str(equal to)
					and %str(&ColumnRule4Operator) ne %str(greater than)
					and %str(&ColumnRule4Operator) ne %str(less than)
					and %str(&ColumnRule4Operator) ne %str(greater or equal to)
					and %str(&ColumnRule4Operator) ne %str(less than or equal to) %then %do ;
					
					%put WARNING: You can use VALUE only with relational operator equal to: equal, less, greater, less equal or greater equal. ;
					%put WARNING: VALUE Ignored. ;
					
				%end ;
				%else %do ;
					%let _columnselector4=(&ColumnRule4Operator, &columnselector4, &column4value) ;
				%end ;	
			%end ;
			%else %do ;
				%let _columnselector4=(&ColumnRule4Operator, &columnselector4, &column4columnvalue) ;
			%end ;
		%end ;
	%end ;
	
	
	%let _sColRuleAppCols= ;
	%if &sColRuleAppCols_count > 0 %then %do ;
		%let _sColRuleAppCols=%str(( &sColRuleAppCols )) ;
	%end ;
	
	%let _survivingR_name=&survivingRecordID_name ;
	%if &keepDuplicate=0 %then %do ;
		%let _survivingR_name= ;
	%end ;
	
	%if &gDistinctSurvivor=1 and &usePkAsDupFlag=1 %then %do ;
		%put WARNING: Both generateDistinctSurvivor and usePrimaryKey cannot be set to Yes at the same time. ;
		%put WARNING: usePrimaryKey Ignored. ;
		%let usePkAsDupFlag=0 ;
	%end ; 

	%let _pkcol= ;
	%if &usePkAsDupFlag=1 %then %do ;
		%let _pkcol=&pkcol ;
	%end ;



	%dqsurvr (inTable=&_input1,
	           outTable=&_output1,
	           clusterColumn=&clusterColumn,
	           rowRule1=&_rowRule1,
	           rowRule1BoolOperator=&rowRulesOperator,
	           rowRule2=&_rowRule2,
	
	           firstColumnRule1=&_columnselector1,
	           firstColumnRule1BoolOperator=&columnoperator,
	           firstColumnRule2=&_columnselector2,
	           firstColumnRuleAppliedCols=&_fColRuleAppCols,
	
	
	           secondColumnRule1=&_columnselector3,
	           secondColumnRule1BoolOperator=&columnoperator2,
	           secondColumnRule2=&_columnselector4,
	           secondColumnRuleAppliedCols=&_sColRuleAppCols,
			   
	           keepDuplicates=&keepDuplicate,
	           survivingRecordID=&_survivingR_name,
	           generateDistinctSurvivor=&gDistinctSurvivor,
	           usePkAsDupFlag=&usePkAsDupFlag,
	           pkCol=&_pkcol,
	           promoteToCas=&promoteToCas
			   );
		   
%mend usr_dqsurvr ;
%usr_dqsurvr ;
