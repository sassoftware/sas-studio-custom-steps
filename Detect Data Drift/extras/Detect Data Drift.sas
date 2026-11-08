/******************************************************************************************************************
    Detecting Data Drift based on a date variable

    For more information on the time interval values check the SAS Documentation:
    https://go.documentation.sas.com/doc/en/pgmsascdc/default/lefunctionsref/p10v3sa3i4kfxfn1sovhi5xzxh8n.htm

    All variables, macros and datasets created by this custom step are prefixed  with _ddd_, which is shorthand
    for detecting data drift.
******************************************************************************************************************/
* Create the current and baseline dataset;
%macro _ddd_create_datasets();
    * Check for datetime formatted variable;
    proc contents data=&_ddd_input_table.(keep=&_ddd_date.) out=work._ddd_contents noPrint;
    run; quit;

    * Retrieve the category of the selected variable;
    proc sql noPrint;
        select name
            from work._ddd_contents
                where 'datetime'=fmtinfo(format,'cat');
    run; quit;

    * Select baseline & current data;
    * The intnx function needs a date formatted variable so based on the finding in the previous query the where condition has to differ;
    %if &sqlobs. EQ 0 %then %do;
        proc sql;
            create table work._ddd_baseline as
                select *
                    from &_ddd_input_table.
                        %if &_ddd_full_baseline. %then %do;
                            where &_ddd_date. LT intnx("&_ddd_interval.", today(), -1);
                        %end;
                        %else %do;
                            where &_ddd_date. GE intnx("&_ddd_interval.", today(), -2) and &_ddd_date. LT intnx("&_ddd_interval.", today(), -1);
                        %end;
            
            create table work._ddd_current as
                select *
                    from &_ddd_input_table.
                        where &_ddd_date. GE intnx("&_ddd_interval.", today(), -1);
        run; quit;
    %end;
    %else %do;
        proc sql;
            create table work._ddd_baseline as
                select *
                    from &_ddd_input_table.
                        %if &_ddd_full_baseline. %then %do;
                            where &_ddd_date. LT intnx("&_ddd_interval.", today(), -1);
                        %end;
                        %else %do;
                            where datepart(&_ddd_date.) GE intnx("&_ddd_interval.", today(), -2) and datepart(&_ddd_date.) LT intnx("&_ddd_interval.", today(), -1);
                        %end;
            
            create table work._ddd_current as
                select *
                    from &_ddd_input_table.
                        where datepart(&_ddd_date.) GE intnx("&_ddd_interval.", today(), -1);
        run; quit;
    %end;
%mend _ddd_create_datasets;

%_ddd_create_datasets();

* Check if the baseline or current dataset is empty;
%let dsid = %sysfunc(open(work._ddd_baseline));
%let nobsB =%sysfunc(attrn(&dsid,nlobs));
%let rc = %sysfunc(close(&dsid));
%let dsid = %sysfunc(open(work._ddd_current));
%let nobsC =%sysfunc(attrn(&dsid,nlobs));
%let rc = %sysfunc(close(&dsid));

%if &nobsB. LE 1 OR &nobsC. LE 1 %then %do;
    data _null_;
        put 'ERROR: The data drift detection will be aboarded';
        put 'ERROR: There were no observations found for either baseline or current dataset';
		put 'ERROR: Common causes are a date variable that does not have a SAS date or datetime format or the date variable does not contain currente data';
		abort 42;
    run;
%end;

%symdel dsid nobsB nobsC rc;

* Macro to track the interval metrics for both the baseline and current;
%macro _ddd_interval_metrics();
    %local i j;

    * Collect the information for the baseline;
    title 'Proc Means result for the baseline data';
    %if &_ddd_full_baseline. %then %do;
        title2 "The baseline dataset is defined as &_ddd_interval. -1 < today";
    %end;
    %else %do;
        title2 "The baseline dataset is defined as &_ddd_interval. -2 >= today < &_ddd_interval. -1";
    %end;
    proc means data=work._ddd_baseline
        skewness kurtosis n nmiss css cv min max sum mean median std stderr range uss prt t var p1 p25 p75 p99 clm lclm uclm mode qrange;
        ods output Summary=work._ddd_baseline_interval;
    run; quit;
    title;

    * Transpose the baseline;
    data work._ddd_baseline_transposed;
        length name $32. sum min max mean median nmiss css cv prt range std stderr t uss var p1 p25 p75 p99 lclm uclm mode qrange count total kurtosis skewness numberOfCategories differingCategories 8.;
        set work._ddd_baseline_interval;

        %do i=1 %to &_ddd_interval_vars_count.;
            name = "&&_ddd_interval_vars_&i._name.";
            sum = &&_ddd_interval_vars_&i._name._Sum;
            min = &&_ddd_interval_vars_&i._name._Min;
            max = &&_ddd_interval_vars_&i._name._Max;
            mean = &&_ddd_interval_vars_&i._name._Mean;
            median = &&_ddd_interval_vars_&i._name._Median;
            nmiss = &&_ddd_interval_vars_&i._name._NMiss;
            css = &&_ddd_interval_vars_&i._name._CSS;
            cv = &&_ddd_interval_vars_&i._name._CV;
            prt = &&_ddd_interval_vars_&i._name._Probt;
            range = &&_ddd_interval_vars_&i._name._Range;
            std = &&_ddd_interval_vars_&i._name._StdDev;
            stderr = &&_ddd_interval_vars_&i._name._StdErr;
            t = &&_ddd_interval_vars_&i._name._t;
            uss = &&_ddd_interval_vars_&i._name._USS;
            var = &&_ddd_interval_vars_&i._name._Var;
            p1 = &&_ddd_interval_vars_&i._name._P1;
            p25 = &&_ddd_interval_vars_&i._name._P25;
            p75 = &&_ddd_interval_vars_&i._name._P75;
            p99 = &&_ddd_interval_vars_&i._name._P99;
            lclm = &&_ddd_interval_vars_&i._name._LCLM;
            uclm = &&_ddd_interval_vars_&i._name._UCLM;
            mode = &&_ddd_interval_vars_&i._name._Mode;
            qrange = &&_ddd_interval_vars_&i._name._QRange;
            count = &&_ddd_interval_vars_&i._name._N;
            total = count + nmiss;
            kurtosis = &&_ddd_interval_vars_&i._name._Kurt;
            skewness = &&_ddd_interval_vars_&i._name._Skew;
            output;
        %end;

        keep name sum min max mean median nmiss css cv prt range std stderr t uss var p1 p25 p75 p99 lclm uclm mode qrange count total kurtosis skewness numberOfCategories differingCategories;
    run;

    * Collect the information for the current;
    title 'Proc Means result for the current data';
    title2 "The current dataset is defined as &_ddd_interval -1 >= today";
    proc means data=work._ddd_current
        skewness kurtosis n nmiss css cv min max sum mean median std stderr range uss prt t var p1 p25 p75 p99 clm lclm uclm mode qrange;
        ods output Summary=work._ddd_current_interval;
    run; quit;
    title;

    * Transpose the current;
    data work._ddd_current_transposed;
        length name $32. sum min max mean median nmiss css cv prt range std stderr t uss var p1 p25 p75 p99 lclm uclm mode qrange count total kurtosis skewness numberOfCategories differingCategories 8.;
        set work._ddd_current_interval;

        %do j=1 %to &_ddd_interval_vars_count.;
            name = "&&_ddd_interval_vars_&j._name";
            sum = &&_ddd_interval_vars_&j._name._Sum;
            min = &&_ddd_interval_vars_&j._name._Min;
            max = &&_ddd_interval_vars_&j._name._Max;
            mean = &&_ddd_interval_vars_&j._name._Mean;
            median = &&_ddd_interval_vars_&j._name._Median;
            nmiss = &&_ddd_interval_vars_&j._name._NMiss;
            css = &&_ddd_interval_vars_&j._name._CSS;
            cv = &&_ddd_interval_vars_&j._name._CV;
            prt = &&_ddd_interval_vars_&j._name._Probt;
            range = &&_ddd_interval_vars_&j._name._Range;
            std = &&_ddd_interval_vars_&j._name._StdDev;
            stderr = &&_ddd_interval_vars_&j._name._StdErr;
            t = &&_ddd_interval_vars_&j._name._t;
            uss = &&_ddd_interval_vars_&j._name._USS;
            var = &&_ddd_interval_vars_&j._name._Var;
            p1 = &&_ddd_interval_vars_&j._name._P1;
            p25 = &&_ddd_interval_vars_&j._name._P25;
            p75 = &&_ddd_interval_vars_&j._name._P75;
            p99 = &&_ddd_interval_vars_&j._name._P99;
            lclm = &&_ddd_interval_vars_&j._name._LCLM;
            uclm = &&_ddd_interval_vars_&j._name._UCLM;
            mode = &&_ddd_interval_vars_&j._name._Mode;
            qrange = &&_ddd_interval_vars_&j._name._QRange;
            count = &&_ddd_interval_vars_&j._name._N;
            total = count + nmiss;
            kurtosis = &&_ddd_interval_vars_&j._name._Kurt;
            skewness = &&_ddd_interval_vars_&j._name._Skew;
            output;
        %end;

        keep name sum min max mean median nmiss css cv prt range std stderr t uss var p1 p25 p75 p99 lclm uclm mode qrange count total kurtosis skewness numberOfCategories differingCategories;
    run;
%mend _ddd_interval_metrics;

%_ddd_interval_metrics();

* Macro to track the nominal metrics for both the baseline and current;
%macro _ddd_nominal_metrics();
    %local i j k l m
        _ddd_cat_base_nobs
        _ddd_cat_curr_nobs
        dsid nobs rc;

    * Collect the information for the baseline;
    proc sql;
        create table work._ddd_baseline_nominal as
            select
                %do i = 1 %to &_ddd_nominal_vars_count.;
                    "&&_ddd_nominal_vars_&i._name." as name_&i.,
                    count(&&_ddd_nominal_vars_&i._name.) as count_&i.,
                    %if &i. EQ &_ddd_nominal_vars_count. %then %do;
                        nmiss(&&_ddd_nominal_vars_&i._name.) as nmiss_&i.
                    %end;
                    %else %do;
                        nmiss(&&_ddd_nominal_vars_&i._name.) as nmiss_&i.,
                    %end;
                %end;
        from work._ddd_baseline;
    run; quit;

    * Create a table for each category;
    proc sql;
        %do i = 1 %to &_ddd_nominal_vars_count.;
            create table work._ddd_nominal_base_&i. as
                select &&_ddd_nominal_vars_&i._name. as variable,
                    count(*) as frequncyOfCategory
                    from work._ddd_baseline
                        group by &&_ddd_nominal_vars_&i._name.;
        %end;
    run; quit;

    * Get the number of categories;
    proc sql noPrint;
        select nobs into :_ddd_cat_base_nobs separated by ' '
            from dictionary.tables
                where libname='WORK' and memname contains '_DDD_NOMINAL_BASE_';
    quit;

     * Transpose the baseline;
    data work._ddd_baseline_transposed_1;
        length name $32. sum min max mean median nmiss css cv prt range std stderr t uss var p1 p25 p75 p99 lclm uclm mode qrange count total kurtosis skewness numberOfCategories differingCategories 8.;
        set work._ddd_baseline_nominal;

        %do j=1 %to &_ddd_nominal_vars_count.;
            name = name_&j.;
            count = count_&j.;
            nmiss = nmiss_&j.;
            total = count + nmiss;
            numberOfCategories = scan("&_ddd_cat_base_nobs.", &j., ' ');
            output;
        %end;

        keep name sum min max mean median nmiss css cv prt range std stderr t uss var p1 p25 p75 p99 lclm uclm mode qrange count total kurtosis skewness numberOfCategories differingCategories;
    run;

    * Collect the information for the current;
    proc sql;
        create table work._ddd_current_nominal as
            select
                %do k = 1 %to &_ddd_nominal_vars_count.;
                    "&&_ddd_nominal_vars_&k._name." as name_&k.,
                    count(&&_ddd_nominal_vars_&k._name.) as count_&k.,
                    %if &k. EQ &_ddd_nominal_vars_count. %then %do;
                        nmiss(&&_ddd_nominal_vars_&k._name.) as nmiss_&k.
                    %end;
                    %else %do;
                        nmiss(&&_ddd_nominal_vars_&k._name.) as nmiss_&k.,
                    %end;
                %end;
        from work._ddd_current;
    run; quit;

    * Create a table for each category;
    proc sql;
        %do k = 1 %to &_ddd_nominal_vars_count.;
            create table work._ddd_nominal_curr_&k. as
                select &&_ddd_nominal_vars_&k._name. as variable,
                    count(*) as frequncyOfCategory
                    from work._ddd_current
                        group by &&_ddd_nominal_vars_&k._name.;
        %end;
    run; quit;

    * Get the number of categories;
    proc sql noPrint;
        select nobs into :_ddd_cat_curr_nobs separated by ' '
            from dictionary.tables
                where libname='WORK' and memname contains '_DDD_NOMINAL_CURR_';
    quit;

     * Transpose the current;
    data work._ddd_current_transposed_1;
        length name $32. sum min max mean median nmiss css cv prt range std stderr t uss var p1 p25 p75 p99 lclm uclm mode qrange count total kurtosis skewness numberOfCategories differingCategories 8.;
        set work._ddd_current_nominal;

        %do l=1 %to &_ddd_nominal_vars_count.;
            name = name_&l.;
            count = count_&l.;
            nmiss = nmiss_&l.;
            total = count + nmiss;
            numberOfCategories = scan("&_ddd_cat_curr_nobs.", &l., ' ');
            output;
        %end;

        keep name sum min max mean median nmiss css cv prt range std stderr t uss var p1 p25 p75 p99 lclm uclm mode qrange count total kurtosis skewness numberOfCategories differingCategories;
    run;

    * Identify differences in the categories;
    %do m=1 %to &_ddd_nominal_vars_count.;
        proc sort data=work._ddd_nominal_base_&m.;
            by variable;
        run; quit;

        proc sort data=work._ddd_nominal_curr_&m.;
            by variable;
        run; quit;

        * Output the differences;
        data work._ddd_nominal_compare_&m.;
            merge work._ddd_nominal_base_&m.(in=a keep=variable)
                work._ddd_nominal_curr_&m.(in=b keep=variable);
            by variable;

            if a and not b then do;
                sourceTable = 'baseline';
                output;
            end;
            else if b and not a then do;
                sourceTable = 'current';
                output;
            end;
        run;

        %let dsid = %sysfunc(open(work._ddd_nominal_compare_&m.));
        %let nobs =%sysfunc(attrn(&dsid,nlobs));
        %let rc = %sysfunc(close(&dsid));

        proc sql;
            update work._ddd_current_transposed_1
                set differingCategories=&nobs.
                    where name EQ "&&_ddd_nominal_vars_&m._name.";
        run; quit;
    %end;
%mend _ddd_nominal_metrics;

%_ddd_nominal_metrics();

* Combine the data sets;
proc append base=work._ddd_baseline_transposed data=work._ddd_baseline_transposed_1;
run; quit;

proc append base=work._ddd_current_transposed data=work._ddd_current_transposed_1;
run; quit;

* Calculate the differences;
proc sql;
    create table &_ddd_result_table. as
        select today() as comparisonDate format date9.,
            b.name,
            c.sum - b.sum as sumDifference,
            ((c.sum - b.sum) / b.sum) * 100 as sumDifferencePCT,
            c.min - b.min as minDifference,
            ((c.min - b.min) / b.min) * 100 as minDifferencePCT,
            c.max - b.max as maxDifference,
            ((c.max - b.max) / b.max) * 100 as maxDifferencePCT,
            c.mean - b.mean as meanDifference,
            ((c.mean - b.mean) / b.mean) * 100 as meanDifferencePCT,
            c.median - b.median as medianDifference,
            ((c.median - b.median) / b.median) * 100 as medianDifferencePCT,
            c.nmiss - b.nmiss as nmissDifference,
            ((c.nmiss - b.nmiss) / b.nmiss) * 100 as nmissDifferencePCT,
            c.css - b.css as cssDifference,
            ((c.css - b.css) / b.css) * 100 as cssDifferencePCT,
            c.cv - b.cv as cvDifference,
            ((c.cv - b.cv) / b.cv) * 100 as cvDifferencePCT,
            c.prt - b.prt as prtDifference,
            ((c.prt - b.prt) / b.prt) * 100 as prtDifferencePCT,
            c.range - b.range as rangeDifference,
            ((c.range - b.range) / b.range) * 100 as rangeDifferencePCT,
            c.std - b.std as stdDifference,
            ((c.std - b.std) / b.std) * 100 as stdDifferencePCT,
            c.stderr - b.stderr as stderrDifference,
            ((c.stderr - b.stderr) / b.stderr) * 100 as stderrDifferencePCT,
            c.t - b.t as tDifference,
            ((c.t - b.t) / b.t) * 100 as tDifferencePCT,
            c.uss - b.uss as ussDifference,
            ((c.uss - b.uss) / b.uss) * 100 as ussDifferencePCT,
            c.var - b.var as varDifference,
            ((c.var - b.var) / b.var) * 100 as varDifferencePCT,
            c.p1 - b.p1 as p1Difference,
            ((c.p1 - b.p1) / b.p1) * 100 as p1DifferencePCT,
            c.p25 - b.p25 as p25Difference,
            ((c.p25 - b.p25) / b.p25) * 100 as p25DifferencePCT,
            c.p75 - b.p75 as p75Difference,
            ((c.p75 - b.p75) / b.p75) * 100 as p75DifferencePCT,
            c.p99 - b.p99 as p99Difference,
            ((c.p99 - b.p99) / b.p99) * 100 as p99DifferencePCT,
            c.lclm - b.lclm as lclmDifference,
            ((c.lclm - b.lclm) / b.lclm) * 100 as lclmDifferencePCT,
            c.uclm - b.uclm as uclmDifference,
            ((c.uclm - b.uclm) / b.uclm) * 100 as uclmDifferencePCT,
            c.mode - b.mode as modeDifference,
            ((c.mode - b.mode) / b.mode) * 100 as modeDifferencePCT,
            c.qrange - b.qrange as qrangeDifference,
            ((c.qrange - b.qrange) / b.qrange) * 100 as qrangeDifferencePCT,
            c.kurtosis - b.kurtosis as kurtosisDifference,
            ((c.kurtosis - b.kurtosis) / b.kurtosis) * 100 as kurtosisDifferencePCT,
            c.skewness - b.skewness as skewnessDifference,
            ((c.skewness - b.skewness) / b.skewness) * 100 as skewnessDifferencePCT,
            c.count - b.count as countDifference,
            ((c.count - b.count) / b.count) * 100 as countDifferencePCT,
            c.total - b.total as totalDifference,
            ((c.total - b.total) / b.total) * 100 as totalDifferencePCT,
            c.numberOfCategories as numberOfCategoriesBaseline,
            c.numberOfCategories as numberOfCategoriesCurrent,
            c.numberOfCategories - b.numberOfCategories as numberOfCategoriesDifference,
            ((c.numberOfCategories - b.numberOfCategories) / b.numberOfCategories) * 100 as numberOfCategoriesDifferencePCT,
            b.differingCategories
            from work._ddd_baseline_transposed as b
                inner join work._ddd_current_transposed as c
                    on b.name EQ c.name;
run; quit;

%if &_ddd_visualize. %then %do;
    title 'Display information about the table';
    ods select attributes variables enginehost directory;
    proc datasets;
        contents data=&_ddd_input_table. order=collate;
    quit;
    title;

    title 'Descriptive Statistics for Interval Variables in the baseline';
    proc means data=work._ddd_baseline n nmiss min mean median max std;
        var &_ddd_interval_vars.;
    run;
    title;

    title 'Histograms, Q-Q Plots & additional information for each interval variable in the baseline dataset';
    proc univariate data=work._ddd_baseline noPrint;
        histogram &_ddd_interval_vars. / normal kernel;
        qqplot &_ddd_interval_vars. / normal(mu=est sigma=est);
    run;
    title;

    title 'Descriptive Statistics for Interval Variables in the current';
    proc means data=work._ddd_current n nmiss min mean median max std;
        var &_ddd_interval_vars.;
    run;
    title;

    title 'Histograms, Q-Q Plots & additional information for each interval variable in the current dataset';
    proc univariate data=work._ddd_current noPrint;
        histogram &_ddd_interval_vars. / normal kernel;
        qqplot &_ddd_interval_vars. / normal(mu=est sigma=est);
    run;
    title;

    title 'Frequencies for Categorical Variables in the baseline';
    proc freq data=work._ddd_baseline;
        tables &_ddd_nominal_vars. /
            plots=(freqplot cumfreqplot) missing chisq binomial(p=0.5 cl=all) alpha=0.05;
    run;
    title;

    title 'Frequencies for Categorical Variables in the current';
    proc freq data=work._ddd_current;
        tables &_ddd_nominal_vars. / 
            plots=(freqplot cumfreqplot) missing chisq binomial(p=0.5 cl=all) alpha=0.05;
    run;
    title;

    title 'Differences between the two intervals';
    proc print data=&_ddd_result_table.;
    run; quit;
    title;
%end;

* Clean up;
%macro _ddd_table_clean_up();
    %local i j;
    
    %if &_ddd_keep_categories. EQ 0 %then %do;
        proc datasets library=work nolist;
            delete 
                %do i=1 %to &_ddd_nominal_vars_count.;
                    _ddd_nominal_base_&i.
                    _ddd_nominal_curr_&i.
                %end;
            ;
        run;
    %end;

    %if &_ddd_keep_transposed. EQ 0 %then %do;
        proc datasets library=work nolist;
            delete _ddd_baseline_transposed _ddd_current_transposed;
        run;
    %end;

    %if &_ddd_keep_compare. EQ 0 %then %do;
        proc datasets library=work nolist;
            delete 
                %do j=1 %to &_ddd_nominal_vars_count.;
                    _ddd_nominal_compare_&j.
                %end;
            ;
        run;
    %end;
%mend _ddd_table_clean_up;

%_ddd_table_clean_up();
%sysmacdelete _ddd_create_datasets;
%sysmacdelete _ddd_interval_metrics;
%sysmacdelete _ddd_nominal_metrics;
%sysmacdelete _ddd_table_clean_up;
proc datasets library=work nolist;
    delete _ddd_contents _ddd_baseline _ddd_current _ddd_baseline_interval _ddd_baseline_nominal _ddd_current_nominal _ddd_current_interval _ddd_baseline_transposed_1 _ddd_current_transposed_1;
run;