/*============================================================
  SYNTHETIC DATA COMPARISON — Custom Step Macro
  ============================================================
  PURPOSE
    Compare a real table against a synthetic table across
    four evaluation dimensions and produce a composite
    similarity score.

  VERSION
    1.1 (01JUL2026)

  DIMENSIONS
    1. Numeric Univariate    — mean / median / std comparison
    2. Categorical Univariate — TVD + JSD on category frequencies
    3. Categorical Relationship — pairwise Cramér's V delta
    4. Numeric Relationship    — pairwise Spearman ρ delta

  PARAMETERS
    realTable        Two-level name of real dataset
    synthTable       Two-level name of synthetic dataset
    filterCondition  Optional WHERE expression
    outLib           Output library (default WORK)
    summary          Summary output table name (default similarity_scores)
    tablePrefix      Optional prefix prepended to output table names
    extraTables      1/0 — also write the four detail tables (default 1)

  OUTPUT TABLES (written to &outLib.)
    <prefix_>similarity_scores               (always)
    <prefix_>detail_num_univariate           (only if extraTables=1)
    <prefix_>detail_cat_univariate           (only if extraTables=1)
    <prefix_>detail_cat_relationship         (only if extraTables=1)
    <prefix_>detail_num_relationship         (only if extraTables=1)
============================================================*/

/*********************************************
  MACRO DEFINITION
*********************************************/

%macro syntheticDataComparison(
    realTable       = ,
    synthTable      = ,
    filterCondition = ,
    outLib          = WORK,
    summary         = ,
    tablePrefix     = ,
    extraTables     = 1
);

    /* ============================================================
       0.  SETUP
       ============================================================ */
    %local wc char_vars num_vars nChar nNum i var prefix
           sc_numUni sc_catUni sc_catRel sc_numRel
           tbl_summary tbl_numUni tbl_catUni tbl_catRel tbl_numRel
           writeDetails _sumLib _sumName _sumVal;

    options nosyntaxcheck;

    /* --- reusable WHERE-clause dataset option --- */
    %if %length(&filterCondition.) > 0 %then
        %let wc = (where=(&filterCondition.));
    %else
        %let wc = ;

    /* --- optional prefix --- */
    %if %length(&tablePrefix.) > 0 %then
        %let prefix = &tablePrefix._;
    %else
        %let prefix = ;

    /* --- summary table: ignore SAS Studio's auto-generated placeholder
           names (containing "_FLW") so the default applies --- */
    %let _sumVal = &summary.;
    %if %index(%upcase(&_sumVal.), _FLW) > 0 %then
        %let _sumVal = ;

    %if %length(&_sumVal.) = 0 %then %do;
        %let _sumLib  = &outLib.;
        %let _sumName = similarity_scores;
    %end;
    %else %if %index(&_sumVal., .) > 0 %then %do;
        %let _sumLib  = %scan(&_sumVal., 1, .);
        %let _sumName = %scan(&_sumVal., 2, .);
    %end;
    %else %do;
        %let _sumLib  = &outLib.;
        %let _sumName = &_sumVal.;
    %end;
    %let tbl_summary = &_sumLib..&prefix.&_sumName.;

    /* --- detail tables always use the standard name in outLib + prefix --- */
    %let tbl_numUni = &outLib..&prefix.detail_num_univariate;
    %let tbl_catUni = &outLib..&prefix.detail_cat_univariate;
    %let tbl_catRel = &outLib..&prefix.detail_cat_relationship;
    %let tbl_numRel = &outLib..&prefix.detail_num_relationship;

    /* --- decide whether to keep the detail tables after the run --- */
    %let writeDetails = 0;
    %if %symexist(extraTables) %then %do;
        %if &extraTables. = 1 %then %let writeDetails = 1;
    %end;
    %else %do;
        %let writeDetails = 1;
    %end;

    /* --- discover character variables --- */
    proc sql noprint;
        select name into :char_vars separated by ' '
        from dictionary.columns
        where libname = upcase(scan("&realTable.", 1, '.'))
          and memname = upcase(scan("&realTable.", 2, '.'))
          and type    = 'char';
    quit;
    %let nChar = %sysfunc(countw(&char_vars.));

    /* --- discover numeric variables --- */
    proc sql noprint;
        select name into :num_vars separated by ' '
        from dictionary.columns
        where libname = upcase(scan("&realTable.", 1, '.'))
          and memname = upcase(scan("&realTable.", 2, '.'))
          and type    = 'num';
    quit;
    %let nNum = %sysfunc(countw(&num_vars.));

    /* initialise component scores to missing */
    %let sc_numUni = .;
    %let sc_catUni = .;
    %let sc_catRel = .;
    %let sc_numRel = .;


    /* ============================================================
       1.  NUMERIC UNIVARIATE SIMILARITY
       ============================================================ */
    %if &nNum. > 0 %then %do;

        proc means data=&realTable.&wc. noprint;
            var &num_vars.;
            output out=_nv_real mean= median= std= / autoname;
        run;

        proc means data=&synthTable.&wc. noprint;
            var &num_vars.;
            output out=_nv_fake mean= median= std= / autoname;
        run;

        proc transpose data=_nv_real(drop=_TYPE_ _FREQ_)
             out=_nv_real_t(rename=(_NAME_=statistic col1=real_value));
        run;
        proc transpose data=_nv_fake(drop=_TYPE_ _FREQ_)
             out=_nv_fake_t(rename=(_NAME_=statistic col1=fake_value));
        run;

        proc sort data=_nv_real_t; by statistic; run;
        proc sort data=_nv_fake_t; by statistic; run;

        data &tbl_numUni;
            merge _nv_real_t _nv_fake_t;
            by statistic;

            length variable $32 stat_type $10;
            stat_type = scan(statistic, -1, '_');
            variable  = substr(statistic, 1,
                          length(statistic) - length(stat_type) - 1);

            denom          = max(abs(real_value), abs(fake_value), 1);
            pct_similarity = 100 - 100 * abs(real_value - fake_value) / denom;

            drop denom;
        run;

        proc means data=&tbl_numUni noprint;
            var pct_similarity;
            output out=_nv_agg mean=_mean;
        run;

        data _null_;
            set _nv_agg;
            call symputx('sc_numUni', _mean / 100);
        run;

    %end;


    /* ============================================================
       2.  CATEGORICAL UNIVARIATE SIMILARITY
       ============================================================ */
    %if &nChar. > 0 %then %do;

        %do i = 1 %to &nChar.;
            %let var = %scan(&char_vars., &i.);

            proc freq data=&realTable.&wc. noprint;
                tables &var. / out=_cf_r_&i.;
            run;

            data _cf_r_&i.(keep=varname category PERCENT);
                length varname $32 category $256;
                set _cf_r_&i.;
                varname  = "&var.";
                category = strip(&var.);
            run;
        %end;

        data _cf_real;
            set %do i = 1 %to &nChar.; _cf_r_&i. %end;;
        run;

        %do i = 1 %to &nChar.;
            %let var = %scan(&char_vars., &i.);

            proc freq data=&synthTable.&wc. noprint;
                tables &var. / out=_cf_s_&i.;
            run;

            data _cf_s_&i.(keep=varname category PERCENT);
                length varname $32 category $256;
                set _cf_s_&i.;
                varname  = "&var.";
                category = strip(&var.);
            run;
        %end;

        data _cf_fake;
            set %do i = 1 %to &nChar.; _cf_s_&i. %end;;
        run;

        proc sort data=_cf_real; by varname category; run;
        proc sort data=_cf_fake; by varname category; run;

        data _cf_merged;
            merge _cf_real(rename=(PERCENT=real_pct))
                  _cf_fake(rename=(PERCENT=fake_pct));
            by varname category;

            real_p = coalesce(real_pct, 0) / 100;
            fake_p = coalesce(fake_pct, 0) / 100;

            tvd_i = abs(real_p - fake_p);

            M = (real_p + fake_p) / 2;

            if real_p > 0 and M > 0 then kl_r = real_p * log2(real_p / M);
            else kl_r = 0;

            if fake_p > 0 and M > 0 then kl_f = fake_p * log2(fake_p / M);
            else kl_f = 0;
        run;

        proc means data=_cf_merged noprint;
            by varname;
            var tvd_i kl_r kl_f;
            output out=_cf_summary
                sum(tvd_i) = tvd_raw
                sum(kl_r)  = kl_real
                sum(kl_f)  = kl_fake;
        run;

        data &tbl_catUni(keep=varname TVD JSD);
            set _cf_summary;
            JSD = sqrt(0.5 * (kl_real + kl_fake));
            TVD = 0.5 * tvd_raw;
        run;

        proc means data=&tbl_catUni mean max noprint;
            var TVD JSD;
            output out=_cf_agg
                mean = Mean_TVD Mean_JSD
                max  = Max_TVD  Max_JSD;
        run;

        data _null_;
            set _cf_agg;
            _tvd = mean((1 - Mean_TVD), (1 - Max_TVD));
            _jsd = mean((1 - Mean_JSD), (1 - Max_JSD));
            call symputx('sc_catUni', mean(_tvd, _jsd));
        run;

    %end;


    /* ============================================================
       3.  CATEGORICAL RELATIONSHIP FIDELITY (Cramér's V)
       ============================================================ */
    %if &nChar. >= 2 %then %do;

        ods exclude all;
        proc freq data=&realTable.&wc.;
            tables (&char_vars.) * (&char_vars.) / chisq;
            ods output ChiSq = _cv_real_chi;
        run;
        ods exclude none;

        data _cv_real(keep=Var1 Var2 Real_V);
            length Var1 Var2 $32;
            set _cv_real_chi(where=(statistic = "Cramer's V"));
            Var1   = scan(table, 2, ' ');
            Var2   = scan(table, 4, ' ');
            Real_V = value;
            if Var1 < Var2;
        run;

        ods exclude all;
        proc freq data=&synthTable.&wc.;
            tables (&char_vars.) * (&char_vars.) / chisq;
            ods output ChiSq = _cv_fake_chi;
        run;
        ods exclude none;

        data _cv_fake(keep=Var1 Var2 Fake_V);
            length Var1 Var2 $32;
            set _cv_fake_chi(where=(statistic = "Cramer's V"));
            Var1   = scan(table, 2, ' ');
            Var2   = scan(table, 4, ' ');
            Fake_V = value;
            if Var1 < Var2;
        run;

        proc sort data=_cv_real; by Var1 Var2; run;
        proc sort data=_cv_fake; by Var1 Var2; run;

        data &tbl_catRel;
            merge _cv_real _cv_fake;
            by Var1 Var2;
            if Real_V = . then Real_V = 0;
            if Fake_V = . then Fake_V = 0;
            Abs_Delta = abs(Real_V - Fake_V);
        run;

        proc means data=&tbl_catRel noprint;
            var Abs_Delta;
            output out=_cv_agg mean=_mean;
        run;

        data _null_;
            set _cv_agg;
            call symputx('sc_catRel', 1 - _mean);
        run;

    %end;


    /* ============================================================
       4.  NUMERIC RELATIONSHIP FIDELITY (Spearman)
       ============================================================ */
    %if &nNum. >= 2 %then %do;

        proc corr data=&realTable.&wc. spearman noprint outp=_sp_real;
            var &num_vars.;
        run;
        proc corr data=&synthTable.&wc. spearman noprint outp=_sp_fake;
            var &num_vars.;
        run;

        data _sp_real_long(keep=Var1 Var2 Real_Corr);
            set _sp_real(where=(_TYPE_ = 'CORR'));
            array v {*} &num_vars.;
            length Var1 Var2 $32;
            Var1 = _NAME_;
            do _j = 1 to dim(v);
                Var2      = vname(v[_j]);
                Real_Corr = v[_j];
                if Var1 < Var2 then output;
            end;
        run;

        data _sp_fake_long(keep=Var1 Var2 Fake_Corr);
            set _sp_fake(where=(_TYPE_ = 'CORR'));
            array v {*} &num_vars.;
            length Var1 Var2 $32;
            Var1 = _NAME_;
            do _j = 1 to dim(v);
                Var2      = vname(v[_j]);
                Fake_Corr = v[_j];
                if Var1 < Var2 then output;
            end;
        run;

        proc sort data=_sp_real_long; by Var1 Var2; run;
        proc sort data=_sp_fake_long; by Var1 Var2; run;

        data &tbl_numRel;
            merge _sp_real_long _sp_fake_long;
            by Var1 Var2;
            if Real_Corr = . then Real_Corr = 0;
            if Fake_Corr = . then Fake_Corr = 0;
            Abs_Delta = min(abs(Real_Corr - Fake_Corr), 1.0);
        run;

        proc means data=&tbl_numRel noprint;
            var Abs_Delta;
            output out=_sp_agg mean=_mean;
        run;

        data _null_;
            set _sp_agg;
            call symputx('sc_numRel', 1 - _mean);
        run;

    %end;


    /* ============================================================
       5.  FINAL SIMILARITY SCORES
       ============================================================ */
    data &tbl_summary;
        format overall_similarity_pct
               statistical_similarity_pct
               relational_similarity_pct
               num_similarity_pct
               char_similarity_pct
               char_corr_pct
               num_corr_pct percent10.3;

        num_similarity_pct  = &sc_numUni.;
        char_similarity_pct = &sc_catUni.;
        char_corr_pct       = &sc_catRel.;
        num_corr_pct        = &sc_numRel.;

        _nw = ifn(num_similarity_pct  = ., 0, &nNum.);
        _cw = ifn(char_similarity_pct = ., 0, &nChar.);

        if (_nw + _cw) > 0 then
            statistical_similarity_pct =
                (_nw * num_similarity_pct + _cw * char_similarity_pct)
                / (_nw + _cw);
        else
            statistical_similarity_pct = .;

        _nw_r = ifn(num_corr_pct  = ., 0, &nNum.);
        _cw_r = ifn(char_corr_pct = ., 0, &nChar.);

        if (_nw_r + _cw_r) > 0 then
            relational_similarity_pct =
                (_nw_r * num_corr_pct + _cw_r * char_corr_pct)
                / (_nw_r + _cw_r);
        else
            relational_similarity_pct = .;

        overall_similarity_pct = mean(
            statistical_similarity_pct,
            relational_similarity_pct
        );

        drop _nw _cw _nw_r _cw_r;
    run;


    /* ============================================================
       CLEANUP
       Always remove intermediate WORK tables.
       If extraTables=0, also remove the four detail tables.
       ============================================================ */
    proc datasets lib=WORK nolist nowarn;
        delete
            _nv_real _nv_fake _nv_real_t _nv_fake_t _nv_agg
            _cf_r_: _cf_s_: _cf_real _cf_fake _cf_merged
            _cf_summary _cf_agg
            _cv_real_chi _cv_fake_chi _cv_real _cv_fake _cv_agg
            _sp_real _sp_fake _sp_real_long _sp_fake_long _sp_agg
        ;
    quit;

    %if &writeDetails. = 0 %then %do;
        proc datasets lib=&outLib. nolist nowarn;
            delete &prefix.detail_num_univariate
                   &prefix.detail_cat_univariate
                   &prefix.detail_cat_relationship
                   &prefix.detail_num_relationship;
        quit;
    %end;


    %put NOTE: =====================================================;
    %put NOTE: Synthetic Data Comparison Complete                    ;
    %put NOTE: Num Univar   : &sc_numUni.                           ;
    %put NOTE: Cat Univar   : &sc_catUni.                           ;
    %put NOTE: Cat Relation : &sc_catRel.                           ;
    %put NOTE: Num Relation : &sc_numRel.                           ;
    %put NOTE: Output lib   : &outLib.                              ;
    %put NOTE: Detail tables: %sysfunc(ifc(&writeDetails.=1, kept, removed));
    %put NOTE: =====================================================;

%mend syntheticDataComparison;


/*********************************************
  EXECUTION CODE
*********************************************/

%syntheticDataComparison(
    realTable       = &realTable,
    synthTable      = &synthTable,
    filterCondition = &filterCondition,
    outLib          = &outLib,
    summary         = &summary,
    tablePrefix     = &tablePrefix,
    extraTables     = &extraTables
);


/*********************************************
  CLEAN UP
*********************************************/

%sysmacdelete syntheticDataComparison / nowarn;

%symdel
    realTable
    synthTable
    filterCondition
    outLib
    summary
    tablePrefix
    extraTables
    / nowarn
;