/*---------------------------------------------------------------------------------------- *
    This custom step allow the user serialize input data into a datagrid using DCM_SERIALIZEGRID macro function. 
	Some additional actions are performed to ensure a proper datagrid result (trim & basic validation).
	By default the datagrid column lentgh is the max length of 32,767 bytes. 
 *------------------------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------------------- *
    Serialization into DataGrid
	Macro DCM_SERIALIZED : https://go.documentation.sas.com/doc/en/edmcdc/default/edmdatagrids/n16ywg120fchftn1fxqdw245jax5.htm
 *------------------------------------------------------------------------------------------*/

%DCM_SERIALIZEGRID (
   GRIDCOLNAME=&data_grid_column_name.,
   GRIDSOURCETABLE=&inputtable.,
   OUTPUTTABLE=&outputtable.,
   CLASSVARS=&classvars.,
   GRIDCOLS=&gridcols.
)

/*---------------------------------------------------------------------------------------- *
    Data trim and basic datagrid validation 
		--> Character variables are not properly trimmed during serialization. 
			Trailing blanks are removed below by regex. 
		--> If serialized DataGrid is > 32,767 bytes then the datagrid will be truncated. 
			Basic validation is performed to detected theses cases. 
			If unbalance brakets are detected, a valid_datagrid flag = 0 and a warning is printed to the log. 
 *------------------------------------------------------------------------------------------*/

data &outputtable. (drop= nof_open_curly nof_close_curly nof_open_square nof_close_square) ; 
   set &outputtable. ;
   valid_datagrid = 1 ; 
   &data_grid_column_name.=prxchange('s/\[\"\s+/["/', -1, &data_grid_column_name.);
   &data_grid_column_name.=prxchange('s/\s+\"\]/"]/', -1, &data_grid_column_name.);
   &data_grid_column_name.=prxchange('s/\s+\"\,/",/', -1, &data_grid_column_name.);
   nof_open_curly = countc(&data_grid_column_name., '{');
   nof_close_curly = countc(&data_grid_column_name., '}');
   nof_open_square = countc(&data_grid_column_name., '[');
   nof_close_square = countc(&data_grid_column_name., ']');
   if nof_open_curly ne nof_close_curly or nof_open_square ne nof_close_square then do ; 
      valid_datagrid = 0 ; 	
      put "WARNING: invalid datagrid at dataset line " _N_ ; 
   end ; 
run ;
