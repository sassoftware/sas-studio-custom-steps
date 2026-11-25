%let base_uri=%sysfunc(getoption(SERVICESBASEURL));

/*
	From the _report macro variable create a separate value for report and path.
*/
data _null_;
	call symputx('report', kreverse(kscan(kreverse(kscan("&_report", 2, ':')), 1, '/')));
	call symputx("path", kreverse(ksubstr(kreverse(kscan("&_report", 2, ':')), kfind(kreverse(kscan("&_report", 2, ':')), '/'))));
run;

/*
	Based on the 'path' macro variable retrieve the endpoint to give me the folder members/content.
*/
filename ref temp ;
proc http
    url = "&base_uri./folders/folders/@item"
    	query = ("path" = "&path")
	    oauth_bearer = sas_services
	out= ref;
    headers
         'Accept'= 'application/vnd.sas.content.folder+json';
run;
libname ref json;

/*
	From the links table, store the member end-point and the content type into macro variables.
*/
proc sql noprint;
    select 
		href, 
		type into :endpoint, :type
    from 
		ref.links
    where 
		method = "GET" and 
		rel = "members";
quit; 

/*
	Retrieve the members/content within the directory
	
	Note the limit addition.
*/
filename members temp; 
proc http
    url = "&base_uri.%trim(&endpoint)?limit=100"
		oauth_bearer = sas_services
    out= members;
    headers
        "Accept"= "%trim(&type)+json";
run; 
libname members json;

/*
	Get the reportId, reportName, the report creation/update timestamps and the creater/updater from the response file.
*/
proc sql noprint;
	select
		kstrip(kreverse(kscan(kreverse(uri), 1, '/'))) as reportId length=64,
		name as reportName, 
		modifiedBy,
		createdBy, 
		put(input(creationTimeStamp, E8601DT19.), datetime22.) as reportCreateTS,
		put(input(modifiedTimeStamp, E8601DT19.), datetime22.) as reportUpdateTS	 
			into 
				:reportId, 
				:reportName, 
				:reportModifiedBy, 
				:reportCreatedBy, 
				:reportCreateTS, 
				:reportUpdateTS
	from
		members.items
	where
		name = "&report";
quit;

/*
	Show the extracted information in the log.
*/
%put &=reportId;
%put &=reportName;
%put &=reportCreatedBy;
%put &=reportModifiedBy;
%put &=reportCreateTS;
%put &=reportUpdateTS;

%macro columns_in_item
(
	dataset=,
	item=,
	columns_key=,
	item_key=
);
	%let expressions = 0;
	
	%if %sysfunc(exist(resp.&dataset.)) %then %do;
		%let expressions = 1;
		proc sql noprint;
			select &item_key from resp.&dataset.;
		quit;
	
		%if &sqlobs eq 0 or &expressions eq 0 %then %do;
			%put NOTE: No &item columns found.;
		%end;
		%else %do;
			%if &dataset eq ITEMS_EXPRESSION %then %do;
				proc sql noprint;
					select
						name into :all_columns separated by ' '
					from
						resp.BUSINESSITEMFOLDER_ITEMS 
					where 
						_element eq "DataItem";
				quit;
			
				%if &sqlobs eq 0 or &all_columns eq %then %do;
					%put NOTE: No calculated columns found.;	
				%end;
				%else %do;
					%let in_calculated_columns =;
					%local i next_name;

					%do i = 1 %to %sysfunc(kcountw(&all_columns));
						%let next_name = %scan(&all_columns, &i);

						data k;
							set
								resp.ITEMS_EXPRESSION;
							b = kfind(value, "{"||"&next_name"||",");
						run;

						proc sql noprint;
							select
								*
							from
								k
							where
								b ne 0;
						quit;

						proc delete data=k; run;

						%if &sqlobs ne 0 %then %do;
							%let in_calculated_columns = &in_calculated_columns "&next_name";
						%end;
					%end;
				
				%end;
				%if &in_calculated_columns eq %then %do;
					%let in_calculated_columns = '';
					%put NOTE: No calculated columns found.;
				%end;
			%end;
		
			proc sql noprint;
				create table item_table_temp as
				select distinct
					bf.name as columnid length=64,
					bf.xref as xref length=64,
					bf.label as label length=64,
					bf._element as columnType length=32,
					bf.ordinal_businessItemFolder as data,
					"" as dataset length=64,
					"" as expression length=512,
					"" as expression_raw length=512
				from
					resp.BUSINESSITEMFOLDER_ITEMS bf,
					resp.&dataset cd
			
				%if &dataset ne ITEMS_EXPRESSION %then %do;
					where
						bf.&columns_key. = cd.&item_key. and
						bf._element eq "DataItem"
				%end;
				%else %do;
					where
						bf.name in (&in_calculated_columns);
				%end;
				;
			quit;

			proc sql noprint;
				select distinct
					quote(kstrip(columnid)) into :&item separated by ' '
				from
					item_table_temp;				
			quit;

			%if &sqlobs. ne 0 %then %do;
				data temp_item;
					set
						columns;
				run;

				proc sql noprint;
					create table columns as
					select
						*
					from 
						temp_item union all
						(
							select
								*
							from
								item_table_temp except all select * from temp_item
						);
				quit;
			%end;
		%end;
	%end;
	%else %do;
		%put NOTE: &item columns found. resp.&dataset does not exist.;
	%end;
%mend;

%macro GetReportResources
(
	reportName=,
	reportId=,
	reportModifiedBy=,
	reportCreatedBy=,
	reportCreateTS=,
	reportUpdateTS=
);
	/*
		Setup the REST API call to retrieve the rapport definition.
	*/
	filename resp temp;
	proc http
		method='get'
		url = "&base_uri./reports/reports/&reportId./content"
			oauth_bearer = sas_services
		out=resp;
		headers
			'Accept'='application/vnd.sas.report.content+json';
		debug level=0 OFF;
	run;

	/*
		Check if we have a response file.
	*/
	%if %sysfunc(fexist(resp)) %then %do;
		libname resp json NO_REOPEN_MSG NOALLDATA MEMLEAVE=ALL JSONCOMPRESS ORDINALCOUNT=2;

		/*
			Validate that the BUSINESSITEMFOLDER_ITEMS, DATADEFINITIONS_BUSINESSITEMS and VISUALELEMENTS_DATALIST tables exist.
			In case one of these tables do not exist, make it know to the end user by using the message: 
			'ERROR: Unable to extract report metadata for ...'
		*/
		%if %sysfunc(exist(resp.BUSINESSITEMFOLDER_ITEMS)) and 
			%sysfunc(exist(resp.DATADEFINITIONS_BUSINESSITEMS)) and 
			%sysfunc(exist(resp.VISUALELEMENTS_DATALIST)) %then %do;
			
			/*
				Check if the 'ITEMS_EXPRESSION' table exists.

				Note that this table only exists when the report contains calculated columns.
			*/
			%let table_exists = 0;
			%if %sysfunc(exist(resp.items_expression)) %then %do;
				%let table_exists = 1;
			%end;

			/*
				Create 'columns' table, to be used for the final output.
			*/
			proc sql noprint;
				create table columns as 
					select distinct 
						BF.name as columnid length=64, 
						BF.xref as xref length=64,
						BF.label as label length=64,
						BF._element as columnType length=32,
						BF.ordinal_businessItemFolder as data, 
						"" as dataset length=128,
						%if &table_exists %then %do;
							ie.value as expression length=512,
							ie.value as expression_raw length=512
						%end;
						%else %do;
							"" as expression length=512,
							"" as expression_raw length=512
						%end; 
					from 
						resp.BUSINESSITEMFOLDER_ITEMS BF 
							left outer join resp.DATADEFINITIONS_BUSINESSITEMS DF on BF.name = DF.base
							%if &table_exists %then %do;
								left outer join resp.items_expression ie on bf.ordinal_items = ie.ordinal_items
							%end;
					where 
						BF._element in 
						(
							'DataItem', 
							'CalculatedItem',
							'AggregateCalculatedItem',
							'DataSource_PredefinedDataItem'
						);
			quit;

			/*
				For specific reports the columns graphType and data do not exist.
			*/
			%let columnExists_gt = 0;
			%let columnExists_d = 0;
			%let dsid = %sysfunc(open(resp.visualelements));
			%if &dsid > 0 %then %do;
				%let columnExists_gt = %sysfunc(varnum(&dsid, graphType));
				%let columnExists_d = %sysfunc(varnum(&dsid, data));
			%end;
			%let rc = %sysfunc(close(&dsid));

			/*
				For specific reports the column valueVariable does not exist.
			*/
			%let columnExists_vv = 0;
			%let dsid = %sysfunc(open(resp.VISUALELEMENTS_PROMPTVISUAL));
			%if &dsid > 0 %then %do;
				%let columnExists_vv = %sysfunc(varnum(&dsid, valueVariable));
			%end;
			%let rc = %sysfunc(close(&dsid));
			
			/*
				Create table, which will be used to enrich the 'base' resulting table.
			*/
			proc sql noprint;
				create table report_detail_lineage as
					select
						(t1.labelattribute) as reportelement_name length=64,
						%if &columnExists_gt %then %do;
							kstrip(t1._element) || 
							case 
								when t1.graphType ~= '' then ' - ' || kstrip(t1.graphType) 
								else '' 
							end as reportelement_type length=64,
						%end;
						%else %do;
							kstrip(t1._element) as reportelement_type length=64,
						%end;	
						(t4.label) as sourceTableName length=64,
						(t6._element) as reportColumnType length=32,
						(t6.name) as columnId length=64,
						(coalesce(t6.xref, t6.label)) as columNname length=64
					from
						resp.visualelements t1
							inner join resp.visualelements_datalist t2 on (t1.ordinal_visualelements = t2.ordinal_visualelements)
							inner join resp.datadefinitions t3 on (t2.datalist1 = t3.name)
							inner join resp.datasources t4 on (t3.source = t4.name)
							inner join resp.datadefinitions_businessitems t5 on (t3.ordinal_datadefinitions = t5.ordinal_datadefinitions)
							inner join resp.businessitemfolder_items t6 on (t5.base = t6.name)

					%if &columnExists_vv %then %do;
						union all
						/*
							Add metadata in case the column VISUALELEMENTS_PROMPTVISUAL.valueVariable exists.
						*/
						select
							(t1.labelattribute) as reportelement_name length=64,
							kstrip(t2._element) as reportelement_type length=64,
							(t5.label) as sourceTableName length=64,
							(t6._element) as reportColumnType length=32,
							(t6.name) as columnId length=64,
							(coalesce(t6.xref, t6.label)) as columNname length=64				
						from
							resp.visualelements t1
								inner join resp.VISUALELEMENTS_PROMPTVISUAL t2 on (t1.ordinal_visualelements = t2.ordinal_visualelements)
								inner join resp.DATADEFINITIONS_BUSINESSITEMS t3 on (t2.valueVariable = t3.name)
								inner join resp.DATADEFINITIONS t4 on (t3.ordinal_dataDefinitions = t4.ordinal_dataDefinitions)
								inner join resp.datasources t5 on (t4.source = t5.name)
								inner join resp.businessitemfolder_items t6 on (t3.base = t6.name)
					%end;						
					%if &columnExists_d and %sysfunc(exist(RESP.VISUALELEMENTS_PROMPTVISUAL)) %then %do;
						union all
						/*
							Add metadata in case the column VISUALELEMENTS.data exists.
						*/
						select 
							t1.labelattribute as reportElement_name length=64,
							kstrip(t1._element) as reportElement_type length=64,
							t7.label as sourceTableName length=64,
							t4._element as reportColumnType length=32,
							t4.name as columnId length=64,
							coalesce(t4.xref, t4.label) as columnName length=64
						from
							resp.visualelements t1
							inner join resp.datadefinitions t2 on t1.data = t2.name
							inner join resp.DATADEFINITIONS_BUSINESSITEMS t3 on t2.ordinal_dataDefinitions = t3.ordinal_dataDefinitions
							inner join resp.DATADEFINITIONS t6 on (t3.ordinal_dataDefinitions = t6.ordinal_dataDefinitions)
							inner join resp.datasources t7 on (t6.source = t7.name)
							inner join resp.BUSINESSITEMFOLDER_ITEMS t4 on t3.base = t4.name
							left outer join resp.VISUALELEMENTS_PROMPTVISUAL t5 on t1.ordinal_visualElements = t5.ordinal_visualElements
						where 
							t5.ordinal_visualElements is null
					%end;
			/*
				Note the additional ;
			*/
			;quit;

			%let report_object = "";
			proc sql noprint;
				select distinct
					quote(columnid) into :report_object separated by ' '
				from
					report_detail_lineage;
			quit;

			%let calculated = "";
			%columns_in_item
			(
				dataset=ITEMS_EXPRESSION, 
				item=calculated, 
				columns_key=dummy, 
				item_key=value
			);

			%let custom_category = "";
			%columns_in_item
			(
				dataset=ITEMS_GROUPINGPARAMETERS, 
				item=custom_category, 
				columns_key=name, 
				item_key=parameter
			);

			%let hierarchy = "";
			%columns_in_item
			(
				dataset=ITEMS_LEVELLIST, 
				item=hierarchy, 
				columns_key=name, 
				item_key=reference
			);

			%let geo = "";
			%columns_in_item
			(
				dataset=ITEMS_GEOINFOS, 
				item=geo, 
				columns_key=ordinal_items, 
				item_key=ordinal_items
			);

			%let primary_key = "";
			%columns_in_item
			(
				dataset=ITEMS_PRIMARYKEY, 
				item=primary_key, 
				columns_key=ordinal_items, 
				item_key=ordinal_items
			);

			%let partition = "";
			%columns_in_item
			(
				dataset=ITEMS_PARTITIONS, 
				item=partition, 
				columns_key=ordinal_items, 
				item_key=ordinal_items
			);

			%let editor_properties = "";
			%columns_in_item
			(
				dataset=ITEMS_EDITORPROPERTIES, 
				item=editor_properties, 
				columns_key=ordinal_items, 
				item_key=ordinal_items
			);

			/*
				Update 'columns' table with data source table.
			*/
			proc sql noprint;
				update
					columns
				set 
					dataset =
					(
						select
							label
						from
							resp.datasources ds
						where
							ds.ordinal_dataSources = columns.data
					)
				where
					columns.data in
					(
						select 
							ordinal_dataSources
						from
							resp.datasources
					);
			quit;

			proc sql noprint;
				create table &_output1 as
				select
					"&reportId" as reportId length=64,
					"&reportName" as reportName length=128,
					"&path" as reportContentFolder length=256,
					"&reportCreatedBy" as reportCreator length=128,
					"&reportModifiedBy" as reportModifier length=128,
					"&reportCreateTS"dt as reportCreateTS length=8 format=datetime.,
					"&reportUpdateTS"dt as reportUpdateTS length=8 format=datetime.,
					upcase(cr.library) as library length=32,
					c.dataset,
					c.columnid as columnId,
					c.xref as columnName,
					c.label as columnLabel,
					c.columnType,
					rdl.reportelement_name,
					rdl.reportelement_type,
					c.expression_raw,
					c.expression,
					case
						when c.columnid in (&report_object) then 'Y' else 'N'
					end as in_report_object,
					case
						when c.columnid in (&calculated) then 'Y' else 'N'
					end as in_calculated,
					case
						when c.columnid in (&custom_category) then 'Y' else 'N'
					end as in_custom_category,
					case
						when c.columnid in (&hierarchy) then 'Y' else 'N'
					end as in_hierarchy,
					case
						when c.columnid in (&geo) then 'Y' else 'N'
					end as in_geo,
					case
						when c.columnid in (&primary_key) then 'Y' else 'N'
					end as in_primary_key,
					case
						when c.columnid in (&partition) then 'Y' else 'N'
					end as in_partition,
					case
						when c.columnid in (&editor_properties) then 'Y' else 'N'
					end as in_editor_properties
				from
					resp.datasources_casresource cr 
						left join columns c on  cr.table = c.dataset
						left outer join report_detail_lineage rdl on c.columnid = rdl.columnid and rdl.reportelement_name is not null;
			quit;

			proc sort data=&_output1 nodupkey;
				by _all_;
			run;

			* ### START OF CHANGE 26.07.2023 #GERMHN ... Enhance output: *;

			* set ColumnName=ColumnLabel when ColumnName is empty *;
			proc sql;
  				update 
					&_output1
  				set 
					ColumnName=ColumnLabel 
				where 
					ColumnName='';
			quit;

			/* 
				create mapping columnID->columnName, also include parameters from prompts!

				SNLRGO: Note that the column LABEL might not exist in the PROMPTDEFINITIONS table...
			*/;

			%let columnExists = 0;
			%let dsid = %sysfunc(open(resp.PROMPTDEFINITIONS));
			%if &dsid > 0 %then %do;
				%let columnExists = %sysfunc(varnum(&dsid, label));
			%end;
			%let rc = %sysfunc(close(&dsid));

			proc sql;
  				create table report_metadata_column_names as
    			select distinct 
					columnID, 
					columnName
    			from 
					&_output1 
				where 
					columnName ne ''
				/* 
					Only run the following code in case the table and column exists.
				*/
  				%if %sysfunc(exist(resp.PROMPTDEFINITIONS)) and &columnExists %then %do;
					union
    				select 
						name as columnID, 
						label as columnName
      				from 
						RESP.PROMPTDEFINITIONS
	      			where 
						label ne ""	
				%end;
				order by 
					columnID desc
				;
			quit; 

			* translate columnID -> columnName inside all expression via TRANWRD *; 
			data &_output1(drop=dsid rc);
  				set 
					&_output1;
  				if expression ne "" then do;
    				dsid=open('WORK.report_metadata_column_names','i');
    				rc=fetch(dsid);
    				do while(rc = 0);
      					expression=tranwrd(expression, trim(getvarc(dsid,varnum(dsid,'ColumnID'))), trim(getvarc(dsid,varnum(dsid,'ColumnName'))));
      					rc=fetch(dsid);
    				end;
    				rc=close(dsid);
  				end;
			run;

			* ### END OF CHANGE 26.07.2023 #GERMHN ... enhance output: *;

		%end;
		%else %do;
			%put NOTE: Essential tables not available.;
			%put ERROR: Unable to extract report metadata for "&reportName".;
		%end;
	%end;
	%else %do;
		%put ERROR: No response file received.;
	%end;
%mend;

%GetReportResources
(
	reportName = %bquote(&reportName),
	reportId = &reportId,
	reportModifiedBy = &reportModifiedBy,
	reportCreatedBy = &reportCreatedBy,
	reportCreateTS = &reportCreateTS,
	reportUpdateTS = &reportUpdateTS
);

/*
	Clean-up user defined macros and macro variables.
*/
%symdel base_uri /nowarn;
%symdel reportId /nowarn;
%symdel reportName /nowarn;
%symdel reportModifiedBy /nowarn;
%symdel reportCreatedBy /nowarn;
%symdel reportCreateTS /nowarn;
%symdel reportUpdateTS /nowarn;
%symdel table_exists /nowarn;
%symdel columnExists_gt /nowarn;
%symdel columnExists_vv /nowarn;
%symdel columnExists_d /nowarn;
%symdel dsid /nowarn;
%symdel rc /nowarn;
%symdel path /nowarn;
%symdel columnExists /nowarn;

%sysmacdelete columns_in_item /nowarn;
%sysmacdelete GetReportResources /nowarn;