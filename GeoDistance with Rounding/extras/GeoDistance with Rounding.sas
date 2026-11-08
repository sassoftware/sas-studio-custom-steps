/* Set Input and Output Data */
data &outTable ;
	set &inTable ;


/* newColumn is a hidden control in the UI.  The code sets the name of the new output column. */

/* Calculate GeoDistance in Miles */
%if &disType=Miles %then %do ;
	%let newColumn_name=distance_in_Miles ;
	&newColumn_name=geodist(&loc1_1_name, &loc1_2_name, &loc2_1_name, &loc2_2_name, 'M') ;
%end;

/* Calculate GeoDistance in Kilometers */
%else %do ;
	%let newColumn_name=distance_in_Kilometers ;
	&newColumn_name=geodist(&loc1_1_name, &loc1_2_name, &loc2_1_name, &loc2_2_name, 'K') ;
%end ;


/* Round GeoDistance Value */
%if &round=1 %then %do ;
	select(&decimalPlaces) ;
		when(0)  &newColumn_name=round(distance_in_&disType) ;
    	when(1)  &newColumn_name=round(distance_in_&disType,0.1) ;
		when(2)  &newColumn_name=round(distance_in_&disType,0.01) ;
		when(3)  &newColumn_name=round(distance_in_&disType,0.001) ;
		when(4)  &newColumn_name=round(distance_in_&disType,0.0001) ;
		when(5)  &newColumn_name=round(distance_in_&disType,0.00001) ;
    end;
%end;
run;