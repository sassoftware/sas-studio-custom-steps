/*-------------------------------------------------------------------------------------------------------------------*
 Macro to retrieve the selections from a column selector and generate a list using CASL action parameter value syntax 
 *-------------------------------------------------------------------------------------------------------------------*/

%macro _flw_get_column_list_CASL(_flw_prefix = %nrstr());
   %let _delim=%str(,);
   {%do _flw_index=1 %to %unquote(&&&_flw_prefix._count);%str(%')%nrquote(&&&_flw_prefix._&_flw_index._name_base)%str(%')%if &_flw_index.<%unquote(&&&_flw_prefix._count)%then&_delim.; %end;}
%mend;

/***********************************/
/* Some code to test it standalone */
/***********************************/
%let columnControl_count=2;
%let columnControl_1_name=Colname1;
%let columnControl_2_name=Colname2;

%put CASL-like list: %_flw_get_column_list_CASL(_flw_prefix=columnControl);
