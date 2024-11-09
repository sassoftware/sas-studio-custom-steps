/* Copied from the generated code for a SAS Studio Flow using release 2022.03 */

/* Macro to get a list of column names */
%macro _flw_get_column_list(_flw_prefix = %nrstr(), _delim=%str( ));
   %do _flw_index=1 %to %unquote(&&&_flw_prefix._count);%unquote(&&&_flw_prefix._&_flw_index._name)%if &_flw_index.<%unquote(&&&_flw_prefix._count)%then&_delim.; %end;
%mend;
