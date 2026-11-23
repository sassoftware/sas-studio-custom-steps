* _etm is short for extract text metadata;

%macro _etm_create_base_metadata;
    * Count different metadata contained in the text;
    * And concatenating user mentions, hashtags and links;
    data &outTable.;
        set &inTable.;
    
        %if &concatAtSigns. or &concatHashtags. or &concatLinks. or &useTextAnalytics. %then %do;
            length _etm_ID 8.;
            label _etm_ID = 'Unqiue Document ID';
            
            _etm_ID = _N_;
        %end;
    
        length _etm_N_FullStop _etm_N_Quest _etm_N_Exclam 
            _etm_wrd_cnt _etm_chrctr_cnt _etm_i 8.;

        %if &createPercentUsed. %then %do;
            length _etm_prcntUsd 8.;
            label _etm_prcntUsd = 'Percentage used of the maximum allowed characters';
        %end;

        %if &createUserMentions. %then %do;
            length _etm_N_AtSigns 8.;
            label _etm_at_term = 'All User mentions in the text concatenated';
            _etm_N_AtSigns = count(&textCol_1_name_base.,'@');
        %end;
        %if &createHashtags. %then %do;
            length _etm_N_HashTags 8.;
            label _etm_hshtg_term = 'All Hashtags in the text concatenated';
            _etm_N_HashTags = count(&textCol_1_name_base.,'#');
        %end;
        %if &createLinks. %then %do;
            length _etm_N_Links  8.;
            label _etm_lnks_term = 'All links in the text concatenated';
            _etm_N_Links = count(&textCol_1_name_base.,'http');
        %end;
    
        length _etm_tmp_at_term _etm_tmp_hshtg_term _etm_tmp_lnks_term 
            _etm_at_term _etm_hshtg_term _etm_lnks_term $&textCol_1_rawlength.;
    
        label _etm_N_FullStop = 'Number of Periods in the Text'
            _etm_N_Quest = 'Number of Question Marks in the Text'
            _etm_N_Exclam = 'Number of Exclamations Points in the Text'
            _etm_N_AtSigns = 'Number of At Signs in the Text'
            _etm_N_HashTags = 'Number of Hashtags in the Text'
            _etm_N_Links = 'Number of Links in the Text'
            _etm_wrd_cnt = 'Number of Words in a Text'
            _etm_chrctr_cnt = 'Number of Characters in a Text';
    
        _etm_N_FullStop = count(&textCol_1_name_base.,'.');
        _etm_N_Quest = count(&textCol_1_name_base.,'?');
        _etm_N_Exclam = count(&textCol_1_name_base.,'!');
        _etm_wrd_cnt = countw(strip(&textCol_1_name_base.), ' ');
        _etm_chrctr_cnt = length(&textCol_1_name_base.);
    
        %if &createPercentUsed. %then %do;
            _etm_prcntUsd = _etm_chrctr_cnt / &maxCharsAllowed.;
        %end;
    
        * Create concataned Values;
        %if &concatAtSigns. or &concatHashtags. or &concatLinks. %then %do;
            length _etm_tmp_at_term _etm_tmp_hshtg_term _etm_tmp_lnks_term $&textCol_1_rawlength.;

            if _etm_N_AtSigns > 0 or _etm_N_HashTags > 0 or _etm_N_Links > 0 then do;
                _etm_i = 1;
                do while(_etm_i <= _etm_wrd_cnt);
    
                    * Search for User mentions;
                    %if &concatAtSigns. %then %do;
                        length _etm_at_term $&textCol_1_rawlength.;
                        label _etm_at_term = 'Concatenated List of all User Mentions in the Text';                        

                        if _etm_N_AtSigns > 0 then do;
                            _etm_tmp_at_term = scan(strip(&textCol_1_name_base.), _etm_i);
                            if substr(_etm_tmp_at_term, 1, 1) = '@' then do;
                                _etm_tmp_at_term = lowcase(strip(_etm_tmp_at_term));
                                _etm_at_term = strip(_etm_at_term) || ' ' || substr(_etm_tmp_at_term, 2);
                            end;
                        end;
                    %end;

                    * Search for Hashtags;
                    %if &concatHashtags. %then %do;
                        length _etm_hshtg_term $&textCol_1_rawlength.;
                        label _etm_hshtg_term = 'Concatenated List of all Hashtags in the Text';

                        if _etm_N_HashTags > 0 then do;
                            _etm_tmp_hshtg_term = scan(strip(&textCol_1_name_base.), _etm_i);
                            if substr(_etm_tmp_hshtg_term, 1, 1) = '#' then do;
                                _etm_tmp_hshtg_term = lowcase(strip(_etm_tmp_hshtg_term));
                                _etm_hshtg_term = strip(_etm_hshtg_term) || ' ' || substr(_etm_tmp_hshtg_term, 2);
                            end;
                        end;
                    %end;
    
                    * Search for Links;
                    %if &concatLinks. %then %do;
                        length _etm_lnks_term $&textCol_1_rawlength.;
                        label _etm_lnks_term = 'Concatenated List of all Links in the Text';

                        if _etm_N_Links > 0 then do;
                            _etm_tmp_lnks_term = scan(strip(&textCol_1_name_base.), _etm_i, ' ');
                            if substr(_etm_tmp_lnks_term, 1, 4) = 'http' then do;
                                _etm_lnks_term = strip(_etm_lnks_term) || ' ' || strip(_etm_tmp_lnks_term);
                            end;
                        end;
                    %end;
    
                    _etm_i + 1;
                end;
            end;

            drop _etm_i _etm_tmp_at_term _etm_tmp_hshtg_term _etm_tmp_lnks_term;
        %end;
    run;
%mend _etm_create_base_metadata;

%_etm_create_base_metadata;

* Remove the macro;
proc catalog cat=work.sasmacr;
    delete _etm_create_base_metadata.macro;
run;

* Check if the users wants the concatenated values as seperated columns;
%if &singleAtSigns. or &singleHashtags. or &singleLinks. %then %do;
    * Get the max number of outputs;
    proc sql noprint;
        select max(_etm_N_AtSigns) into :_etm_max_AtSign
                from &outTable.;
    
        select max(_etm_N_HashTags) into :_etm_max_HashTags
                from &outTable.;
    
        select max(_etm_N_Links) into :_etm_max_Links
                from &outTable.;
    run;

    %macro _etm_create_individual_cols;
        data &outTable.;
            set &outTable.;

            * Separated Columns for User Mentions;
            %if &singleAtSigns. %then %do;
                %do i=1 %to &_etm_max_AtSign.;
                    length _etm_AtSign_&i. $&textCol_1_rawlength.;
                    label _etm_AtSign_&i. = "&i.. user mention in the text";
                    _etm_AtSign_&i. = scan(_etm_at_term, &i.);
                %end;
            %end;

            * Separated Columns for Hashtags;
            %if &singleHashtags. %then %do;
                %do i=1 %to &_etm_max_HashTags.;
                    length _etm_HashTags_&i. $&textCol_1_rawlength.;
                    label _etm_HashTags_&i. = "&i.. hashtag in the text";
                    _etm_HashTags_&i. = scan(_etm_hshtg_term, &i.);
                %end;
            %end;

            * Separated Columns for User Links;
            %if &singleLinks. %then %do;
                %do i=1 %to &_etm_max_Links.;
                    length _etm_lnks_&i. $&textCol_1_rawlength.;
                    label _etm_lnks_&i. = "&i.. link in the text";
                    _etm_lnks_&i. = scan(_etm_lnks_term, &i., ' ');
                %end;
            %end;
        run;
    %mend _etm_create_individual_cols;

    %_etm_create_individual_cols;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
       delete _etm_create_individual_cols.macro;
    run;

    * Remove macro variables, that where created in the step;
    %symdel _etm_max_AtSign _etm_max_HashTags _etm_max_Links;
%end;


* Check if the users wants Co-Occurences to be added;
%if &createAtOccurences. or &createHTOccurences. or &createLKOccurences. %then %do;
    * Add a binary field on Co-Occurence 0 = No and 1 = Yes;
    %macro _etm_cooccurence;
        * Create a table containing a row per value and id;
        data %if &createAtOccurences. %then work._etm_all_mentions(keep=_etm_ID _etm_tmp_at_term);
            %if &createHTOccurences. %then work._etm_all_hashtags(keep=_etm_ID _etm_tmp_hshtg_term);
            %if &createLKOccurences. %then work._etm_all_links(keep=_etm_ID _etm_tmp_lnks_term);
            ;
        
            length %if &createAtOccurences. %then _etm_tmp_at_term;
                %if &createHTOccurences. %then _etm_tmp_hshtg_term;
                %if &createLKOccurences. %then _etm_tmp_lnks_term;
                 $&textCol_1_rawlength.;

            set &outTable.;
        
            * User Mentions;
            %if &createAtOccurences. %then %do;
                _etm_i = 1;
                if _etm_N_AtSigns > 0 then do;
                    do until(_etm_i <= _etm_N_AtSigns);
                        _etm_tmp_at_term = scan(_etm_at_term, _etm_i);
                        output work._etm_all_mentions;
                    end;
                end;
            %end;
        
            * HashTags;
            %if &createHTOccurences %then %do;
                _etm_i = 1;
                if _etm_N_HashTags > 0 then do;
                    do until(_etm_i <= _etm_N_HashTags);
                        _etm_tmp_hshtg_term = scan(_etm_hshtg_term, _etm_i);
                        output work._etm_all_hashtags;
                    end;
                end;
            %end;
        
            * Links;
            %if &createLKOccurences. %then %do;
                _etm_i = 1;
                if _etm_N_Links > 0 then do;
                    do until(_etm_i <= _etm_N_Links);
                        _etm_tmp_lnks_term = scan(_etm_lnks_term, _etm_i, ' ');
                        output work._etm_all_links;
                    end;
                end;
            %end;
        run;
        
        * Create a count per mention, hashtag and link;
            proc sql noprint;
        %if &createAtOccurences. %then %do;
            proc sql noprint;
                create table work._etm_all_mentions_grp as
                    select count(*) as count_texts, _etm_tmp_at_term
                        from work._etm_all_mentions
                            group by _etm_tmp_at_term
                                having count_texts > &numOfAtOccurences.
                                    order by count_texts desc;
            run;

            proc sql noprint;
                select _etm_tmp_at_term into :_etm_tmp_at_term separated by '|'
                    from work._etm_all_mentions_grp(obs=&numOfAtOutputs.);
            run;
        
            data &outTable.;
                set &outTable.;
                %do i= 1 %to &sqlobs.;
                     _etm_cooc_At_&i=(strip(_etm_at_term) eq "%scan(&_etm_tmp_at_term.,&i.,'|')");
                     Label _etm_cooc_At_&i.="Co-Occurence At_&i.: %scan(&_etm_tmp_at_term.,&i.,'|')";
                %end;
            run;

            * Remove datasets;
            proc datasets library=work nolist;
                delete _etm_all_mentions _etm_all_mentions_grp;
            run;
        %end;

        %if &createHTOccurences. %then %do;
            proc sql noprint;
                create table work._etm_all_hashtags_grp as
                    select count(*) as count_texts, _etm_tmp_hshtg_term
                        from work._etm_all_hashtags
                            group by _etm_tmp_hshtg_term
                                having count_texts > &numOfHTOccurences.
                                    order by count_texts desc;
            run;

            proc sql noprint;
                select _etm_tmp_hshtg_term into :_etm_tmp_hshtg_term separated by '|'
                    from work._etm_all_hashtags_grp(obs=&numOfHTOutputs.);
            run;
        
            data &outTable.;
                set &outTable.;
                %do i= 1 %to &sqlobs.;
                     _etm_cooc_HashTag_&i=(strip(_etm_hshtg_term) eq "%scan(&_etm_tmp_hshtg_term.,&i.,'|')");
                     Label _etm_cooc_HashTag_&i.="Co-Occurence HashTag_&i.: %scan(&_etm_tmp_hshtg_term.,&i.,'|')";
                %end;
            run;

            * Remove datasets;
            proc datasets library=work nolist;
                delete _etm_all_hashtags _etm_all_hashtags_grp;
            run;
        %end;
        %if &createLKOccurences. %then %do;
            proc sql noprint;
                create table work._etm_all_links_grp as
                    select count(*) as count_texts, _etm_tmp_lnks_term
                        from work._etm_all_links
                            group by _etm_tmp_lnks_term
                                having count_texts > &numOfLKOccurences.
                                    order by count_texts desc;
            run;

            proc sql noprint;
                select _etm_tmp_lnks_term into :_etm_tmp_lnks_term separated by '|'
                    from work._etm_all_links_grp(obs=&numOfLKOutputs.);
            run;
        
            data &outTable.;
                set &outTable.;
                %do i= 1 %to &sqlobs.;
                     _etm_cooc_Link_&i=(strip(_etm_lnks_term) eq "%scan(&_etm_tmp_lnks_term.,&i.,'|')");
                     Label _etm_cooc_Link_&i.="Co-Occurence Link_&i.: %scan(&_etm_tmp_lnks_term.,&i.,'|')";
                %end;
            run;

            * Remove datasets;
            proc datasets library=work nolist;
                delete _etm_all_links _etm_all_links_grp;
            run;
        %end;
    
    %mend _etm_cooccurence;

    %_etm_cooccurence;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
       delete _etm_cooccurence.macro;
    run;
%end;

* Extract a user specified RegEx Pattern as additional features;
%if &extractCustomRegEx. %then %do;

    %macro _etm_regex_extraction;
        %let _etm_len_snip=%sysevalf(&textCol_1_rawlength.+2*&snipplet_window.);
        
        %if &regExTargetCheck. %then %do;
            %let minTgMean = %sysevalf(&minTgMean. / 10);
            %let maxTgMean = %sysevalf(&maxTgMean. / 10);
        %end;

        data work._etm_regex_trans(drop=start length stop REGEX len pos);
            length _etm_occurance _etm_occurance_lc $&textCol_1_rawlength.. _etm_snipplet $&_etm_len_snip..;
            label _etm_occurance = "Value extracted by the RegEx Pattern: &prxPattern."
                _etm_occurance_lc = "Value extracted by the RegEx Pattern: &prxPattern."
                _etm_snipplet = "Added &snipplet_window. charachters around the found RegEx pattern to provide context";
        
            if _n_ eq 1 then do;
                REGEX=prxparse("&prxPattern.");
                if REGEX < 1 then put 'ERROR: Your specified RegEx Pattern was invalid, please check it!';
            end;
        
            set &outTable.(keep=&textCol_1_name_base. _etm_ID %if &regExTargetCheck. %then %do; &regExTarget_1_name_base. %end;);
        
            start = 1;
            _etm_snipplet = '';
            length = &textCol_1_rawlength.;
            stop = length;
            len = stop - start + 1;

            call prxnext(REGEX, start, stop, &textCol_1_name_base., pos, len);
        
            do while (pos gt 0);
                _etm_occurance=ksubstr(&textCol_1_name_base., pos, len);
                _etm_occurance_lc=lowcase(_etm_occurance);
                _etm_snipplet=ksubstr(&textCol_1_name_base.,
                    Max(1, pos - &snipplet_window.),
                    Min(len + %sysevalf(2 * &snipplet_window.), &snipplet_window. + length - pos + 1)
                );
        
                output;
                call prxnext(REGEX, start, stop, &textCol_1_name_base., pos, len);
            end;
        
            if _etm_occurance eq '' then output;
        
            retain REGEX;
        run;

        %if &createSnippetTable. %then %do;
            data &outTableRexExContext.(drop=_etm_occurance_lc);
                set work._etm_regex_trans(where=(strip(_etm_occurance) ne ''));
            run;
        %end;
        
        proc sql;
            create table work._etm_occurance_cnt as
                select  _etm_occurance_lc as _etm_occurance, count(distinct _etm_ID) as _etm_doc_cnt label = 'Number of documents containing each term extracted by the RegEx Pattern'
                    %if &regExTargetCheck. %then %do;
                        , mean(&regExTarget_1_name_base.) as _etm_&regExTarget_1_name_base._Mean
                    %end;
                    from work._etm_regex_trans
                        group by _etm_occurance_lc
                            order by
                                %if &regExTargetCheck. %then %do;
                                    _etm_&regExTarget_1_name_base._Mean descending,
                                %end;
                                _etm_doc_cnt descending;
        quit;
        
        %if &createCustomRegExGraphics %then %do;
            proc print data=work._etm_occurance_cnt;
                Title "Lowcase Pattern Matches in Column &textCol_1_name_base.";
                Footnote "RegEx Pattern: &prxPattern.";
            run;
            title;
            footnote;
        %end;

        proc sql noprint;
                select _etm_occurance into : Terms separated by '�'
                    from work._etm_occurance_cnt(where=(_etm_doc_cnt ge &MinDocCnt.
                        and strip(_etm_occurance) ne ''
                        %if &regExTargetCheck. %then %do;
                            and (_etm_&regExTarget_1_name_base._mean ge &MinTgMean.
                            or _etm_&regExTarget_1_name_base._mean le &MaxTgMean. )
                        %end;
                    ));
        quit;

        ods noproctitle;

        %if &sqlobs. gt 0 %then %do;
            data &outTable.(rename=(_etm_prx=_etm_prx_0));
                set &outTable.;
        
                %do i= 1 %to &sqlobs.;
                    _etm_prx_&i.=(find(&textCol_1_name_base.,"%scan(&terms., &i., '�')", 'i') gt 1);
                    label _etm_prx_&i.="RegEx Pattern Term &i.: %scan(&terms., &i., '�')";
                %end;
        
                _etm_prx=(sum(of _etm_prx_:) gt 0);
                Label _etm_prx="RegEx Pattern Term All: &prxPattern.";
            run;

            %if &createCustomRegExGraphics %then %do;
                proc freq data=&outTable.;
                    Tables %if &regExTargetCheck. ne %then %do; &regExTarget_1_name_base. %end; _etm_prx_:;
                    Title "Feature Statistics";
                    %if &regExTargetCheck. %then %do;
                        Footnote "RegEx Pattern: &prxPattern., MinDocCnt=&MinDocCnt., MinTgMean=&MinTgMean., MaxTgMean=&MaxTgMean.";
                    %end;
                    %else %do;
                        Footnote "RegEx Pattern: &prxPattern., MinDocCnt=&MinDocCnt.";
                    %end;
                run;
                title;
                footnote;

                proc summary data=&outTable. print stackods Mean;
                    Title "Feature Mean";
                    Footnote "RegEx Pattern: &prxPattern., MinDocCnt=&MinDocCnt.";
                    var _etm_prx_:;
                run;
                title;
                footnote;
            %end;
            
            %if &regExTargetCheck. %then %do;
                proc freq data=&outTable.;
                    Tables &regExTarget_1_name_base.*_etm_prx_:;
                    Title "Feature Association with Target Variable &regExTarget_1_name_base.";
                    Footnote "RegEx Pattern: &prxPattern., MinDocCnt=&MinDocCnt., MinTgMean=&MinTgMean., MaxTgMean=&MaxTgMean.";
                run;
                title;
                footnote;

                proc summary data=&outTable. print stackods Mean;
                    Title "Feature Mean within Target Variable: &regExTarget_1_name_base.";
                    Footnote "RegEx Pattern: &prxPattern., MinDocCnt=&MinDocCnt., MinTgMean=&MinTgMean., MaxTgMean=&MaxTgMean.";
                    var _etm_prx_:;
                    ways 0 1;
                    class &regExTarget_1_name_base.;
                run;
                title;
                footnote;
            %end;
        %end;

        ods;

        * Remove the datasets;
        proc datasets library=work nolist;
            delete _etm_regex_trans _etm_occurance_cnt;
        run; quit;
    %mend _etm_regex_extraction;

    %_etm_regex_extraction;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
        delete _etm_regex_extraction.macro;
    run; quit;
%end;

* Get metadata from links;
%if &getLinkMetadata. %then %do;
    * Create a table of all links;
    data work._etm_links(keep=_etm_lnks);
        set &outTable.(where=(_etm_lnks_term ^= '') keep=_etm_lnks_term _etm_N_Links);
        _etm_i = 1;
        do while(_etm_i <= _etm_N_Links);
            _etm_lnks = scan(_etm_lnks_term, _etm_i, ' ');
            output;
            _etm_i + 1;
        end;
    run;

    * Only keep unique links to reduce querying;
    proc sql outobs=&urlLimiter.;
        create table work._etm_distinct_links as
            select count(_etm_lnks) as c1, _etm_lnks
                from work._etm_links
                    where _etm_lnks not in (' ', 'http', 'https')
                        order by c1;
    run;

    %let _etm_n_links = &sqlobs.;

    %macro _etm_py_link_meta;
        %do i = 1 %to %sysfunc(ceil(&_etm_n_links. / 25));
            %let _etm_firstob = %eval(&i. * 25);
            %let _etm_obsCount = %eval(&_etm_firstob. + 25);

            %if &i. = 1 %then %do;
                data work._etm_links;
                    set work._etm_distinct_links(obs=25);
                run;

                proc python restart infile=pgm;
                run;

                data work._etm_link_meta_all;
                    set work._etm_link_meta;
                run;
            %end;
            %else %if &i. = %sysfunc(ceil(&_etm_n_links. / 25)) %then %do;
                data work._etm_links;
                    set work._etm_distinct_links(firstobs=&_etm_firstob. obs=&_etm_obsCount.);
                run;

                proc python restart infile=pgm;
                run;

                proc append base=work._etm_link_meta_all data=work._etm_link_meta;
                run;
            %end;
            %else %do;
                data work._etm_links;
                    set work._etm_distinct_links(firstobs=&_etm_firstob.);
                run;

                proc python restart infile=pgm;
                run;

                proc append base=work._etm_link_meta_all data=work._etm_link_meta;
                run;
            %end;
        %end;

    %mend _etm_py_link_meta;

    filename pgm "_etm_link_meta.py";

    data _null_;
        file pgm;
        
        put "import pandas as pd";
        put "import requests";
        put "from bs4 import BeautifulSoup";

        if &allowUnverifiedRequests. then do;
            put "from urllib3.exceptions import InsecureRequestWarning";
            put "requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)";
        end;

        put " ";
        put "# Get the unique link table from SAS";
        put "_etm_df = SAS.sd2df('work._etm_links')";
        put " ";
        put "# Function to gather link information for each link";
        put "def get_link_metadata(row):";
        put "    try:";

        if &allowUnverifiedRequests. then do;
            put "        r = requests.get(row['_etm_lnks'], verify=False)";
        end;
        else do;
            put "        r = requests.get(row['_etm_lnks'])";
        end;

        put "        html = BeautifulSoup(r, 'html.parser')";
        put "        _etm_status_code = r.status_code";
        put "        _etm_title = html.find('meta', attrs={'property': 'og:title'})";
        put "        _etm_description = html.find('meta', attrs={'property': 'og:description'})";
        put "        _etm_url = html.find('meta', attrs={'property': 'og:url'})";
        put "        _etm_site_name = html.find('meta', attrs={'property': 'og:site_name'})";
        put "    except:";
        put "        _etm_status_code = 404";
        put "        _etm_title = 'Not available'";
        put "        _etm_description = 'Not available'";
        put "        _etm_url = 'Not available'";
        put "        _etm_site_name = 'Not available'";
        put "    return _etm_status_code, _etm_title, _etm_description, _etm_url, _etm_site_name";
        put " ";
        put "# Get the information for each link";
        put "_etm_df_meta = _etm_df.apply(get_link_metadata, axis='columns', result_type='expand')";
        put "_etm_df_all = pd.concat([_etm_df, _etm_df_meta], axis='columns')";
        put "_etm_df_all.rename(columns = {0:'_etm_status_code', 1:'_etm_title', 2:'_etm_description', 3:'_etm_url', 4:'_etm_site_name'}, inplace = True)";
        put " ";
        put "# Return the information to SAS";
        put "SAS.df2sd(_etm_df_all, 'work._etm_link_meta')";
    run;
    
    %_etm_py_link_meta;

    filename pgm clear;
    
    * Add the link metadata back to table;
    %macro _etm_add_link_meta;
        proc sql noprint;
            select max(_etm_N_Links) into :_etm_max_links
                from &outTable.;
        run;
        
        proc sql;
            create table work._etm_link_combined as
                select a.*,
                    %do i = 1 %to &_etm_max_links.;
                        %if &i. > 1 %then %do;
                            ,
                        %end;
                        t&i.._etm_status_code as _etm_status_code_&i. label="HTTP Status Code of the &i.. Link",
                        t&i.._etm_title as _etm_title_&i. label="Website Title of the &i.. Link",
                        t&i.._etm_description as _etm_description_&i. label="Website Description of the &i.. Link",
                        t&i.._etm_url as _etm_url_&i. label="Website URL of the &i.. Link",
                        t&i.._etm_site_name as _etm_site_name_&i. label="Website Name of the &i.. Link"
                    %end;
                        from &outTable. as a
                            %do i = 1 %to &_etm_max_links.;
                                left join work._etm_link_meta as t&i.
                                    on a._etm_lnks_&i. = t&i.._etm_lnks
                            %end;
        ;run;
    
        data &outTable.;
            set work._etm_link_combined;
        run;
    %mend _etm_add_link_meta;
    
    %_etm_add_link_meta;

    * Remove datasets;
    proc datasets library=work nolist;
        delete _etm_links _etm_distinct_links _etm_link_meta _etm_link_meta_all _etm_link_combined;
    run;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
       delete _etm_py_link_meta.macro _etm_add_link_meta.macro;
    run;
%end;

* Add a language to the dataset;
%if &useTextAnalytics. %then %do;
    * Sort the data by ID for results merge at the end;
    proc sort data=&outTable.;
        by _etm_ID;
    run;

    cas _etm_sess sessopts=(caslib=casuser);
    libname _etm_cas cas caslib='casuser' datalimit=all;

    %macro _etm_add_language;
        * Automatic language detection;
        %if &howLanguage. %then %do;
            * Load the data into CAS;
            proc casutil session=_etm_sess;
                load data=&outTable. outcaslib='casuser'
                casout='_etm_lang_detect' replace;
            run;
            
            * Detect the language of each text;
            proc cas;
               session _etm_sess;
            
                output log;
            
                textManagement.identifyLanguage /
                    casOut={name='_etm_lang_detected', replace=True}
                    docId='_etm_ID'
                    table={name='_etm_lang_detect'}
                    text="&textCol_1_name_base.";
            run; quit;
            
            * Pull the data down from CAS into SPRE;
            data work._etm_lang(rename=(_language_=_etm_lang));
                set _etm_cas._etm_lang_detected(where=(_language_^=' '));
                label _language_ = 'Language of the text';
            run;
        
            proc sort data=work._etm_lang;
                by _etm_ID;
            run;
            
            * Add the data to the output dataset;
            data &outTable.;
                merge &outTable. work._etm_lang;
                by _etm_ID;
            run;

            * Create a bar chart of the detected languages;
            %if &createLanguagePlot. %then %do;
                ods graphics / reset imagemap;
                title3 "Distribution of the Detected Languages";
                proc sgplot data = &outTable.;
                    vbar _etm_lang;
                run;
                title3;
            %end;

            * Remove datasets;
            proc datasets library=work nolist;
                delete _etm_lang;
            run;
        %end;
        %else %do;
            * Language specified by the user;
            data &outTable.;
                set &outTable.;

                length _etm_lang $2.;
                label _etm_lang = 'Language of the text';

                _etm_lang = "&userSpecifiedLanguage.";

                * Handle the case of empty text;
                if &textCol_1_name_base. = '' then do;
                    _etm_lang = ' ';
                end;
            run;
        %end;
    %mend _etm_add_language;

    %_etm_add_language;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
        delete _etm_add_language.macro;
    run; quit;
%end;

* Create translation of shorthand language to long formn language;
* This dataset is used by actions that run for each language;
%if &profileText. or &createTopics. or &createPredefinedConcepts. or &useCustomConcepts. or &createBoolRules. %then %do;
    * Long name of language for proc textmine;
    data work._etm_lang_trans;
        infile datalines delimiter=',';
        length _etm_long_lang $15 _etm_short_lang $2;
        input _etm_long_lang $ _etm_short_lang $;
             
        datalines;
Arabic, AR
Chinese, ZH
Croatian, HR
Czech, CS
Danish, DA
Dutch, NL
English, EN
Finnish, FI
French, FR
German, DE
Greek, EL
Hebrew, IW
Hindi, HI
Hungarian, HU
Indonesian, IN
Italian, IT
Japanese, JA
Kazakh, KK
Korean, KO
Norwegian, NO
Persian, FA
Polish, PL
Portuguese, PT
Romanian, RO
Russian, RU
Slovak, SK
Slovene, SL
Spanish, ES
Swedish, SV
Tagalog, TL
Thai, TH
Turkish, TR
Vietnamese, VI
;
    run;
%end;

* Profile the text corpus;
%if &profileText. %then %do;
    proc casutil session=_etm_sess;
        load data=&outTable. outcaslib='casuser'
        casout='_etm_profile_text' replace;
    run;
    
    %macro _etm_profile_text;
        * Select all distinct languages in the dataset;
        proc sql noprint;
            select distinct _etm_lang, count(distinct _etm_lang) into :_etm_lang1-, :_etm_lang_cnt
                from &outTable.
                    where _etm_lang ne ' ';
        run;

        %do i=1 %to &_etm_lang_cnt.;
            * Create a separate dataset for each language;
            data _etm_cas._etm_lang_&&_etm_lang&i.;
                set &outTable.(where=(_etm_lang="&&_etm_lang&i."));
            run;

            data _null_;
                set work._etm_lang_trans(where=(lowcase(_etm_short_lang) eq "&&_etm_lang&i."));
                call symputx('_etm_long_lang', _etm_long_lang);
            run;

            *Run the text profiling;
            proc cas;
                session _etm_sess;
                        
                output log;
            
                textManagement.profileText /
                casOut = {name = '_etm_profile_text_out', replace = True}
    
                %if &compareReferenceCorpus. %then %do;
                    referenceData = True
                %end;
    
                documentId = '_etm_ID'
                documentOut = {name = '_etm_document_out', replace = True}
                language = "&_etm_long_lang."
                table = {name = '_etm_profile_text'}
                text = "&textCol_1_name_base.";
            run; quit;
    
            ods noproctitle;

            * Print the Results of the Profiling action to the Results;
            title3 "Profile Text for the &_etm_long_lang. texts in the Corpus";
            proc cas;
                session _etm_sess;
    
                table.fetch / table= {name = '_etm_profile_text_out'};
            run; quit;
            title3;

            * Print Word and Sentence Count Graphs;
            %if &createProfileTextGraphs. %then %do;
                title "Sentences Count in Documents for &_etm_long_lang.";
                proc sgplot data=_etm_cas._etm_document_out;
                    vbar _num_sentences_;
                    yaxis label='Number of Documents' grid;
                    xaxis label='Number of Sentences';
                run;
                title;

                title "Word Count in Documents for &_etm_long_lang.";
                proc sgplot data=&outTable.;
                    vbar _etm_wrd_cnt;
                    yaxis label='Number of Documents' grid;
                    xaxis label='Number of Words';
                run;
                title;
            %end;

        %end;

        * Add new features derived from the Profiling action;
        %if &createNumSentences. or &createMaxTokenSentence. %then %do;
            proc sql;
                create table work._etm_profile_text as
                    select _etm_ID
                        %if &createNumSentences. %then %do;
                            , _num_sentences_ as _etm_num_sentences label = 'Number of sentences in the Text'
                        %end;
                        %if &createMaxTokenSentence. %then %do;
                            , _max_tokens_sentence_ as _etm_max_tokens_sentence label = 'Number of Tokens in the longest Sentence in the Text'
                        %end;
                        from _etm_cas._etm_document_out
                            order by _etm_ID;
            run;

            data &outTable.;
                merge &outTable. work._etm_profile_text;
                by _etm_ID;
            run;

            * Remove datasets;
            proc datasets library=work nolist;
                delete _etm_profile_text;
            run; quit;
        %end;

    %mend _etm_profile_text;
    
    %_etm_profile_text;


    * Remove the macro;
    proc catalog cat=work.sasmacr;
        delete _etm_profile_text.macro;
    run; quit;
%end;

* Detect the sentiment of each text;
%if &detectSentiment. %then %do;
    %macro _etm_by_lang;
        * Select all distinct languages in the dataset;
        proc sql noprint;
            select distinct _etm_lang, count(distinct _etm_lang) into :_etm_lang1-, :_etm_lang_cnt
                from &outTable.
                    where _etm_lang ne ' ';
        run;
    
        %do i=1 %to &_etm_lang_cnt.;
            * If text profiling is not selected, then the language split has to be created;
            %if not &profileText. %then %do;
                * Create a separate dataset for each language;
                data _etm_cas._etm_lang_&&_etm_lang&i.;
                    set &outTable.(where=(_etm_lang="&&&&_etm_lang&i."));
                run;
            %end;

            data _null_;
                set work._etm_lang_trans(where=(lowcase(_etm_short_lang) eq "&&_etm_lang&i."));
                call symputx('_etm_long_lang', _etm_long_lang);
            run;
    
            * Score the sentiment for each text;
            proc cas;
                 session _etm_sess;
            
                output log;
            
                sentimentAnalysis.applySent /
                        docId='_etm_ID'
                        text="&textCol_1_name_base."
                        language="&_etm_long_lang."
                        table={name="_etm_lang_&&_etm_lang&i."}
                        casOut={name="_etm_sent_&&_etm_lang&i.", replace=True};
                run; 
            quit;

            * Move the sentiment data from CAS to SPRE;
            data work._etm_sent_&&_etm_lang&i.;
                length _etm_sentiment $32. _etm_sentiment_score 8.;
                label _etm_sentiment = 'Sentiment of the text'
                    _etm_sentiment_score = 'Score value for the sentiment of the text';

                set _etm_cas._etm_sent_&&_etm_lang&i.;

                _etm_sentiment = _sentiment_;
                _etm_sentiment_score = _score_;

                drop _sentiment_ _score_;
            run;

            proc sort data=work._etm_sent_&&_etm_lang&i.;
                by _etm_ID;
            run;

            * Add the sentiment and score to the data;
            data &outTable.;
                merge &outTable. work._etm_sent_&&_etm_lang&i.;
                by _etm_ID;
            run;
    
            * Remove datasets;
            proc datasets library=work nolist;
                delete _etm_sent_&&_etm_lang&i.;
            run; quit;
        %end;

        * Create a bar chart of the sentiment languages;
        %if &createSentimentPlot. %then %do;
            ods graphics / reset imagemap;
            title3 "Distribution of the Sentiment by Languages";
            proc sgplot data = &outTable.;
                vbar _etm_sentiment / group = _etm_lang groupdisplay=stack;
            run;
            title3;
        %end;
    %mend _etm_by_lang;
    
    %_etm_by_lang;
    
    * Remove the macro;
    proc catalog cat=work.sasmacr;
       delete _etm_by_lang.macro;
    run; quit;
%end;

* Apply the SAS Predefined Concepts to the data;
%if &createPredefinedConcepts. and &conceptList_count. > 0 %then %do;
    %macro _etm_predefined_concepts;
        * Bring the user selected concepts in the format for a where clause;
        data _null_;
            _etm_prcncpt_all = "'" || "&conceptList_1." || "'"
            %do j = 1 %to &conceptList_count.;
                || ",'" || "&&conceptList_&j." || "'"
            %end;
            ;
            call symputx('_etm_prcncpt_all', _etm_prcncpt_all);
        run;

        * Select all distinct languages in the dataset;
        proc sql noprint;
            select distinct _etm_lang, count(distinct _etm_lang) into :_etm_lang1-, :_etm_lang_cnt
                from &outTable.
                    where _etm_lang ne ' ';
        run;

        %do i=1 %to &_etm_lang_cnt.;
            * If text profiling and sentiment detection are not selected, then the language split has to be created;
            %if not &profileText. and not &detectSentiment. %then %do;
                * Create a separate dataset for each language;
                data _etm_cas._etm_lang_&&_etm_lang&i.;
                    set &outTable.(where=(_etm_lang="&&_etm_lang&i."));
                run;
            %end;

            data _null_;
                set work._etm_lang_trans(where=(lowcase(_etm_short_lang) eq "&&_etm_lang&i."));
                call symputx('_etm_long_lang', _etm_long_lang);
            run;

            * Apply the SAS predefined concepts to the text;
            proc cas;
                session _etm_sess;
            
                output log;
            
                textRuleDevelop.compileConcept /
                        casOut = {name = '_etm_comp_Concepts', replace = True}
                        enablePredefined = True
                        language = "&_etm_long_lang.";
                run;
            
                textRuleScore.applyConcept /
                        casOut = {name = "_etm_concepts_&&_etm_lang&i.", replace = True}
                        language = "&_etm_long_lang."
                        docId = '_etm_ID'
                        model = {name = '_etm_comp_Concepts'}
                        table = {name = "_etm_lang_&&_etm_lang&i."}
                        text = "&textCol_1_name_base.";
               run;
            quit;
        %end;

        * Append all concepts in one table;
        data work._etm_all_concepts(drop=_start_ _end_ _canonical_form_ _path_);
            length _etm_match_text $&textCol_1_rawlength. _etm_concept $15.;
            label _etm_match_text = 'The matched text for the concept'
                _etm_concept = 'The concept that was found in the text';
            set
        %do i=1 %to &_etm_lang_cnt.;
            _etm_cas._etm_concepts_&&_etm_lang&i.(where=(_concept_ in (&_etm_prcncpt_all.)))
        %end;
            ;
            _etm_match_text = _match_text_;
            _etm_concept = _concept_;
            drop _match_text_ _concept_;
        run;

        * Sort the data by the document ID to do by group processing;
        proc sort data=work._etm_all_concepts;
            by _etm_ID _etm_concept;
        run;

        * Generate the new features based on the predefined concepts;
        data work._etm_all_concepts;
            set work._etm_all_concepts;
            by _etm_ID _etm_concept;
        
            * New Features from Concepts;
            length _etm_total_concepts 8.;
            label _etm_total_concepts = 'Total Number of Concepts found in the Text';

            * Columns per Selected Predefined Concept;
            %do k=1 %to &conceptList_count.;
                length _etm_&&conceptList_&k.._count 8.;
                label _etm_&&conceptList_&k.._count = "Count for &&conceptList_&k. in the Text";
            %end;

            %if &createConcatedPreConcepts. %then %do;
                %do l=1 %to &conceptList_count.;
                    length _etm_&&conceptList_&l.._cat $&textCol_1_rawlength.;
                    label _etm_&&conceptList_&l.._cat = "Concatenated List of all Matched Texts for the Concept _etm_&&conceptList_&l.._cat";
                %end;
            %end;

            if first._etm_concept then do;
                %do m=1 %to &conceptList_count.;
                    _etm_&&conceptList_&m.._count = 1;

                    %if &createConcatedPreConcepts. %then %do;
                        _etm_&&conceptList_&m.._cat = '';
                        if _etm_concept = "&&conceptList_&m." then do;
                            _etm_&&conceptList_&m.._cat = _etm_match_text;
                        end;
                    %end;
                %end;
            end;
            else do;
                %do n=1 %to &conceptList_count.;
                    if _etm_concept = "&&conceptList_&n." then do;
                        _etm_&&conceptList_&n.._count + 1;

                        %if &createConcatedPreConcepts. %then %do;
                            _etm_&&conceptList_&n.._cat = strip(_etm_&&conceptList_&n.._cat) || '||' || _etm_match_text;
                        %end;
                    end;
                %end;
            end;

            if first._etm_ID and last._etm_ID then do;
                _etm_total_concepts = 1;
                output;
            end;
            else if first._etm_ID then do;
                _etm_total_concepts = 1;
            end;
            else if last._etm_ID then do;
                _etm_total_concepts + 1;
                output;
            end;
            else do;
                _etm_total_concepts + 1;
            end;

            retain _etm_total_concepts
            %do o=1 %to &conceptList_count.;
                _etm_&&conceptList_&o.._count
                %if &createConcatedPreConcepts. %then %do;
                    _etm_&&conceptList_&o.._cat
                %end;
            %end;
            ;
        run;

        data &outTable.;
            merge &outTable. work._etm_all_concepts;
            by _etm_ID;
        run;

        * Create a bar chart of the extracted SAS Predefined Concepts;
        %if &createPreConceptPlot. %then %do;
            ods graphics / reset imagemap;
            title3 "Distribution of the Extracted SAS Predefined Concepts by Languages";
            proc sgplot data = &outTable.;
                vbar _etm_concept / group=_etm_lang;
            run;
            title3;
        %end;

        * Remove datasets;
        proc datasets library=work nolist;
            delete _etm_all_concepts;
        run; quit;
    %mend _etm_predefined_concepts;

    %_etm_predefined_concepts;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
        delete _etm_predefined_concepts.macro;
    run; quit;
%end;

%if &singlePreConcepts. %then %do;
    %macro _etm_create_single_precon;
        * Get the max number of concepts per Text;
        proc sql noprint;
                %do i=1 %to &conceptList_count.;
                    select max(_etm_&&conceptList_&i.._count) into :_etm_max_&&conceptList_&i.
                        from &outTable.;
                %end;
        run;

        %do j=1 %to &conceptList_count.;
            data &outTable.;
                set &outTable.;
                %do k=1 %to &conceptList_count.;
                    %do m=1 %to &&&&_etm_max_&&conceptList_&k.;
                        length _etm_&&conceptList_&k.._&m. $&textCol_1_rawlength.;
                        label _etm_&&conceptList_&k.._&m. = "&m.. &&conceptList_&k. Concept in the Text";
                        _etm_&&conceptList_&k.._&m. = scan(_etm_&&conceptList_&k.._cat, &m., '||');
                    %end;
                %end;
            run;
        %end;

    %mend _etm_create_single_precon;

    %_etm_create_single_precon;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
       delete _etm_create_single_precon.macro;
    run;
%end;

* Extract Custom Concepts from the Text;
%if &useCustomConcepts. %then %do;
    %macro addCustomConcepts;
        * Load the data into CAS;
        %if not &compiledCustomConcepts %then %do;
            proc casutil session=_etm_sess;
                load data=&custConInTable. outcaslib='casuser'
                casout='_etm_custom_concept' replace;
            run;
        %end;
        %else %do;
            proc casutil session=_etm_sess;
                load casdata="&custConInTable_Name." incaslib="&custConInTable_Lib."
                casout='_etm_custom_concept' outcaslib='casuser' replace;
            run;
        %end;

        * Select all distinct languages in the dataset;
        proc sql noprint;
            select distinct _etm_lang, count(distinct _etm_lang) into :_etm_lang1-, :_etm_lang_cnt
                from &outTable.
                    where _etm_lang ne ' ';
        run;

        %do i=1 %to &_etm_lang_cnt.;
            * If the language split has to be created;
            %if not &profileText. and not &detectSentiment. and not &createPredefinedConcepts. %then %do;
                * Create a separate dataset for each language;
                data _etm_cas._etm_lang_&&_etm_lang&i.;
                    set &outTable.(where=(_etm_lang="&&_etm_lang&i."));
                run;
            %end;

            data _null_;
                set work._etm_lang_trans(where=(lowcase(_etm_short_lang) eq "&&_etm_lang&i."));
                call symputx('_etm_long_lang', _etm_long_lang);
            run;

            proc cas;

                session _etm_sess;

                output log;
                
                %if not &compiledCustomConcepts. and &i. eq 1 %then %do;
                    textRuleDevelop.compileConcept /
                            casOut={name='_etm_custom_concept', replace=True} 
                            config="&customConInTable_1_name_base."
                            table={name='_etm_custom_concept'};
                        run;
                %end;

                textRuleScore.applyConcept /
                        casOut = {name = "_etm_cus_concepts_&&_etm_lang&i.", replace = True}
                        language = "&_etm_long_lang."
                        docId = '_etm_ID'
                        model = {name = '_etm_custom_concept'}
                        table = {name = "_etm_lang_&&_etm_lang&i."}
                        text = "&textCol_1_name_base.";
                    run;
            quit;
        %end;

        * Append all concepts in one table;
        data work._etm_all_custom_concepts(drop=_start_ _end_ _canonical_form_ _path_);
            length _etm_custom_match_text $&textCol_1_rawlength. _etm_custom_concept $256.;
            label _etm_custom_match_text = 'The matched text for the concept'
                _etm_custom_concept = 'The concept that was found in the text';
            set
        %do i=1 %to &_etm_lang_cnt.;
            _etm_cas._etm_cus_concepts_&&_etm_lang&i.
        %end;
            ;
            _etm_custom_match_text = _match_text_;
            _etm_custom_concept = _concept_;
            drop _match_text_ _concept_;
        run;

        * Sort the data by the document ID to do by group processing;
        proc sort data=work._etm_all_custom_concepts;
            by _etm_ID _etm_custom_concept;
        run;

        * Count the number of distinct custom concepts found in the data;
        proc sql noprint;
            select distinct _etm_custom_concept into :_etm_custom_concept_1-
                from work._etm_all_custom_concepts;

            select count(distinct _etm_custom_concept) into :_etm_custom_concept_cnt
                from work._etm_all_custom_concepts;
        run;

        * Generate the new features based on the predefined concepts;
        data work._etm_all_custom_concepts;
            set work._etm_all_custom_concepts;
            by _etm_ID _etm_custom_concept;
        
            * New Features from Concepts;
            length _etm_total_custom_concepts 8.;
            label _etm_total_custom_concepts = 'Total Number of Custom Concepts found in the Text';

            * Columns per Selected Predefined Concept;
            %do k=1 %to &_etm_custom_concept_cnt.;
                length _etm_&&_etm_custom_concept_&k.._count 8.;
                label _etm_&&_etm_custom_concept_&k.._count = "Count for &&_etm_custom_concept_&k. in the Text";
            %end;

            %if &createConcatedCustomConcepts. %then %do;
                %do l=1 %to &_etm_custom_concept_cnt.;
                    length _etm_&&_etm_custom_concept_&l.._cat $&textCol_1_rawlength.;
                    label _etm_&&_etm_custom_concept_&l.._cat = "Concatenated List of all Matched Texts for the Concept _etm_&&_etm_custom_concept_&l.._cat";
                %end;
            %end;

            if first._etm_custom_concept then do;
                %do m=1 %to &_etm_custom_concept_cnt.;
                    _etm_&&_etm_custom_concept_&m.._count = 1;

                    %if &createConcatedCustomConcepts. %then %do;
                        _etm_&&_etm_custom_concept_&m.._cat = '';
                        if _etm_custom_concept = "&&_etm_custom_concept_&m." then do;
                            _etm_&&_etm_custom_concept_&m.._cat = _etm_custom_match_text;
                        end;
                    %end;
                %end;
            end;
            else do;
                %do n=1 %to &_etm_custom_concept_cnt.;
                    if _etm_custom_concept = "&&_etm_custom_concept_&n." then do;
                        _etm_&&_etm_custom_concept_&n.._count + 1;

                        %if &createConcatedCustomConcepts. %then %do;
                            _etm_&&_etm_custom_concept_&n.._cat = strip(_etm_&&_etm_custom_concept_&n.._cat) || '||' || _etm_custom_match_text;
                        %end;
                    end;
                %end;
            end;

            if first._etm_ID and last._etm_ID then do;
                _etm_total_custom_concepts = 1;
                output;
            end;
            else if first._etm_ID then do;
                _etm_total_custom_concepts = 1;
            end;
            else if last._etm_ID then do;
                _etm_total_custom_concepts + 1;
                output;
            end;
            else do;
                _etm_total_custom_concepts + 1;
            end;

            retain _etm_total_custom_concepts

            %do o=1 %to &_etm_custom_concept_cnt.;
                _etm_&&_etm_custom_concept_&o.._count
                %if &createConcatedCustomConcepts. %then %do;
                    _etm_&&_etm_custom_concept_&o.._cat
                %end;
            %end;
            ;
        run;

        data &outTable.;
            merge &outTable. work._etm_all_custom_concepts;
            by _etm_ID;
        run;

        data &outTable.;
            merge &outTable. work._etm_all_custom_concepts;
            by _etm_ID;
        run;

        * Create a bar chart of the extracted Custom Concepts;
        %if &createCustomConceptPlot. %then %do;
            ods graphics / reset imagemap;
            title3 "Distribution of the Extracted Custom Concepts by Languages";
            proc sgplot data = &outTable.;
                vbar _etm_custom_concept / group=_etm_lang;
            run;
            title3;
        %end;
    %mend addCustomConcepts;

    %addCustomConcepts;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
        delete addCustomConcepts.macro;
    run; quit;
%end;

* Create separated columns for the Custom Concepts;
%if &singleCustomConcepts. %then %do;
    %macro _etm_create_single_custom_con;
        * Count the number of distinct custom concepts found in the data;
        proc sql noprint;
            select distinct _etm_custom_concept into :_etm_custom_concept_1-
                from work._etm_all_custom_concepts;

            select count(distinct _etm_custom_concept) into :_etm_custom_concept_cnt
                from work._etm_all_custom_concepts;
        run;

        * Get the max number of concepts per Text;
        proc sql noprint;
                %do i=1 %to &_etm_custom_concept_cnt.;
                    select max(_etm_&&_etm_custom_concept_&i.._count) into :_etm_max_&&_etm_custom_concept_&i.
                        from &outTable.;
                %end;
        run;

        %do j=1 %to &_etm_custom_concept_cnt.;
            data &outTable.;
                set &outTable.;
                %do k=1 %to &_etm_custom_concept_cnt.;
                    %do m=1 %to &&&&_etm_max_&&_etm_custom_concept_&k.;
                        length _etm_&&_etm_custom_concept_&k.._&m. $&textCol_1_rawlength.;
                        label _etm_&&_etm_custom_concept_&k.._&m. = "&m.. &&_etm_custom_concept_&k. Concept in the Text";
                        _etm_&&_etm_custom_concept_&k.._&m. = scan(_etm_&&_etm_custom_concept_&k.._cat, &m., '||');
                    %end;
                %end;
            run;
        %end;
    %mend _etm_create_single_custom_con;

    %_etm_create_single_custom_con;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
       delete _etm_create_single_custom_con.macro;
    run;
%end;

* Create Text Topics for each Language;
%if &createTopics. %then %do;
    %macro _etm_topic_discovery;

        * Select all distinct languages in the dataset;
        * Filter languages that have more then 50 rows;
        proc sql noprint;
            create table work._etm_lang_grp as
            select count(_etm_lang) as _etm_lang_cnt, _etm_lang
                from &outTable.
                    group by _etm_lang
                        having _etm_lang ne ' ';
        run;

        proc sql noprint;
            select distinct _etm_lang, count(distinct _etm_lang) into :_etm_lang1-, :_etm_lang_cnt
                from work._etm_lang_grp
                    where _etm_lang ne ' ' and _etm_lang_cnt >= 50;
        run;
        
        ods noproctitle;
    
        %do i=1 %to &_etm_lang_cnt.;
    
            * If the language split has to be created;
            %if not &profileText. and not &detectSentiment. and not &createPredefinedConcepts. and not &useCustomConcepts. %then %do;
                * Create a separate dataset for each language;
                data _etm_cas._etm_lang_&&_etm_lang&i.;
                    set &outTable.(where=(_etm_lang="&&_etm_lang&i."));
                run;
            %end;
    
            * Load default stop lists;
            proc casutil;
                load casdata="&&_etm_lang&i.._stoplist.sashdat" incaslib='referencedata'
                    casout="_etm_&&_etm_lang&i.._stoplist" outcaslib='casuser' replace;
            quit;

            data _null_;
                set work._etm_lang_trans(where=(lowcase(_etm_short_lang) eq "&&_etm_lang&i."));
                call symputx('_etm_long_lang', _etm_long_lang);
            run;
    
            %if &useBestPractise. %then %do;
                * Create the text topics;
                proc cas;
                    session _etm_sess;

                    output log;

                    textMining.tmMine /
                        language = "&_etm_long_lang."
                        documents = "_etm_lang_&&_etm_lang&i."
                        text = "&textCol_1_name_base."
                        docid = "_etm_ID"

                        stopList = {name = "_etm_&&_etm_lang&i.._stoplist"}
                        nounGroups = False
                        tagging = False
                        entities = 'NONE'
                        reduce = 4
                        resolution = 'MED'
                        rotate = 'VARIMAX'
                        maxK = 100
                        numLabels = 20

                        %if &createScreePlotSVD. %then %do;
                            s = {name = "_etm_&&_etm_lang&i.._svds", replace = True}
                        %end;

                        %if &useTopicCreationTbD. %then %do;
                            parent = {name = "_etm_parent_&&_etm_lang&i.", replace = True}
                            terms = {name = "_etm_terms_&&_etm_lang&i.", replace = True}
                        %end;

                        docPro = {name = "_etm_&&_etm_lang&i.._doc_pro", replace = True}
                        topics = {name = "_etm_&&_etm_lang&i.._topics", replace = True};
                run;
            %end;
            %else %do;
                %if &selectEntities. %then %do;
                    %if &createPredefinedConcepts. %then %do;
                        data _null_;
                            _etm_prcncpt_all = "'" || "&conceptList_1." || "'"
                            %do j = 1 %to &conceptList_count.;
                                || ",'" || "&&conceptList_&j." || "'"
                            %end;
                            ;
                            call symputx('_etm_prcncpt_all', _etm_prcncpt_all);
                        run;
                    %end;
                    %if &useCustomConcepts. %then %do;
                        proc sql noprint;
                            select distinct _etm_custom_concept into :_etm_custom_concept_1-
                                from work._etm_all_custom_concepts;
                
                            select count(distinct _etm_custom_concept) into :_etm_custom_concept_cnt
                                from work._etm_all_custom_concepts;
                        run;
                
                        data _null_;
                            _etm_custcncpt_all = "'" || "&_etm_custom_concept_1." || "'"
                            %do j = 1 %to &_etm_custom_concept_cnt.;
                                || ",'" || "&&_etm_custom_concept_&j." || "'"
                            %end;
                            ;
                            call symputx('_etm_custcncpt_all', _etm_custcncpt_all);
                        run;
                    %end;
                %end;
            
                proc cas;

                    session _etm_sess;

                    output log;
            
                    textMining.tmMine /
                            language = "&_etm_long_lang."
                            documents = {name = "_etm_lang_&&_etm_lang&i."}
                            docId = "_etm_ID"
            
                            entities = %if &extractEntities. %then %do; 'std' %end;
                            %else %do; 'none' %end;
            
                            noungroups = %if &posTagging. %then %do; True %end;
                            %else %do; False %end;
            
                            stemming = %if &stemTerms. %then %do; True %end;
                            %else %do; False %end;
                            
                            tagging = %if &extractNounGroups. %then %do; True %end;
                            %else %do; False %end;
            
                            reduce = &minOccKeep.
            
                            cellWeight = %if &cellWeight. %then %do; 'log' %end;
                            %else %do; 'none' %end;
            
                            termWeight = "&termWeight."
            
                            %if &useStopWords. %then %do;
                                stopList = {name = "_etm_&&_etm_lang&i.._stoplist"}
                            %end;
            
                            norm = "&normProjects."
                            
                            %if &numTopics. %then %do;
                                k = &numTopicsK.
                            %end;
                            %else %do;
                                maxK = &numTopicsMaxK.
                            %end;
            
                            resolution = "&resolutionLevel."
            
                            rotate = "&rotationType."
            
                            numLabels = &numLabels.
            
                            %if &selectEntities. %then %do;
                                selectEntity={tagList={
                                    %if &createPredefinedConcepts. and &useCustomConcepts. %then %do;
                                        &_etm_prcncpt_all., &_etm_custcncpt_all.
                                    %end;
                                    %else %if &createPredefinedConcepts. %then %do;
                                        &_etm_prcncpt_all.
                                    %end;
                                    %else %do;
                                        &_etm_custcncpt_all.
                                    %end;
                                }}
            
                                %if &useCustomConcepts. %then %do;
                                    defaultEntitiesPriority = &defaultEntityPrio.

                                    liti={name='_etm_custom_concept',
                                    computedVars={name='_priority_'}
                                    %if not &hasCustomPrio. %then %do;
                                        , computedVarsProgram="_priority_ = %sysevalf(&defaultEntityPrio. + 1);"
                                    %end;
                                    }
                                %end;
                            %end;

                            text = "&textCol_1_name_base."

                            %if &createScreePlotSVD. %then %do;
                                s = {name = "_etm_&&_etm_lang&i.._svds", replace = True}
                            %end;

                            %if &useTopicCreationTbD. %then %do;
                                parent = {name = "_etm_parent_&&_etm_lang&i.", replace = True}
                                terms = {name = "_etm_terms_&&_etm_lang&i.", replace = True}
                            %end;

                            docPro = {name = "_etm_&&_etm_lang&i.._doc_pro", replace = True}
                            topics = {name = "_etm_&&_etm_lang&i.._topics", replace = True};
                        run;
                quit;
            %end;
    
            %if &createScreePlotSVD. %then %do;
                ods graphics / reset imagemap;
                title3 "Scree Plot of SVD for &&_etm_lang&i.";
                proc sgplot data = _etm_cas._etm_&&_etm_lang&i.._svds;
                    vline _id_ / 
                        response = _s_
                        nostatlabel 
                        stat = Mean 
                        markers;
                    xaxis label='Topic';
                    yaxis grid label='Singular Value';
                run;
                title3;
            %end;
    
            proc sort data=_etm_cas._etm_&&_etm_lang&i.._doc_pro out=work._etm_&&_etm_lang&i.._doc_pro;
                by _etm_ID;
            run;

            %let _etm_dsid=%sysfunc(open(work._etm_&&_etm_lang&i.._doc_pro));
            %let _etm_n=%sysfunc(attrn(&_etm_dsid., nvars));

            * Rename the topic columns to start with _etm_;
            data work._etm_&&_etm_lang&i.._doc_pro(rename=(_etm__etm_id=_etm_id));
                set work._etm_&&_etm_lang&i.._doc_pro(rename=(

                %do j = 2 %to &_etm_n.;
                    %let _etm_var=%sysfunc(varname(&_etm_dsid., &j.));
                    &_etm_var. = _etm_&&_etm_lang&i.._&_etm_var.
                %end;));

                %let _etm_rc=%sysfunc(close(&_etm_dsid.));
            run;

            data &outTable.;
                merge &outTable. work._etm_&&_etm_lang&i.._doc_pro;
                by _etm_ID;
            run;

            * Remove datasets;
            proc datasets library=work nolist;
                delete _etm_lang_grp _etm_&&_etm_lang&i.._doc_pro;
            run; quit;

            ods proctitle;
        %end;
    %mend _etm_topic_discovery;

    %_etm_topic_discovery;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
        delete _etm_topic_discovery.macro;
    run; quit;
%end;

* Create BoolRules for a target variable associated wiht the text;
%if &createBoolRules. %then %do;
    %macro _etm_create_boolRule;

        ods noproctitle;

        * Select all distinct languages in the dataset;
        * Filter languages that have more then 50 rows;
        proc sql noprint;
            create table work._etm_lang_grp as
            select count(_etm_lang) as _etm_lang_cnt, _etm_lang
                from &outTable.
                    group by _etm_lang
                        having _etm_lang ne ' ';
        run;

        proc sql noprint;
            select distinct _etm_lang, count(distinct _etm_lang) into :_etm_lang1-, :_etm_lang_cnt
                from work._etm_lang_grp
                    where _etm_lang ne ' ' and _etm_lang_cnt >= 50;
        run;
        
        %do i=1 %to &_etm_lang_cnt.;
            * If the language split has to be created;
            %if not &profileText. and not &detectSentiment. and not &createPredefinedConcepts. and not &useCustomConcepts. and not &createTopics. %then %do;
                * Create a separate dataset for each language;
                data _etm_cas._etm_lang_&&_etm_lang&i.;
                    set &outTable.(where=(_etm_lang="&&_etm_lang&i."));
                run;
            %end;

            * Load the stop word list if it not loaded already;
            %if not &createTopics. %then %do;
                * Load default stop lists;
                proc casutil;
                    load casdata="&&_etm_lang&i.._stoplist.sashdat" incaslib='referencedata'
                        casout="_etm_&&_etm_lang&i.._stoplist" outcaslib='casuser' replace;
                quit;
            %end;

            options label;

            * If the user does jas a termByDoc and terms from a previous topic creation step;
            %if not &useTopicCreationTbD. %then %do;
                proc cas;
                    session _etm_sess;

                    output log;

                    textMining.tmMine /
                        documents = "_etm_lang_&&_etm_lang&i."
                        text = "&textCol_1_name_base."
                        docid = "_etm_ID"
                        parent = {name = "_etm_parent_&&_etm_lang&i.", replace = True}
                        terms = {name = "_etm_terms_&&_etm_lang&i.", replace = True}
                        stopList = {name = "_etm_&&_etm_lang&i.._stoplist"}
                        nounGroups = False
                        tagging = False;
                run;
            %end;

            proc cas;
                session _etm_sess;

                output log;

                boolRule.brTrain /
                    table = "_etm_parent_&&_etm_lang&i."
                    docid = '_document_'
                    termid = '_termnum_'

                    gPositive = &gPosBR.
                    mPositive = &mPosBR.
                    gNegative = &gNegBR.
                    mNegative = &mNegBR.

                    minSupports = &minSupportsBR.
                    maxCandidates = &maxCandidatesBR.
                    maxTriesIn = &maxTriesInBR.
                    maxTriesOut = &maxTriesOutBR.

                    docinfo = {
                        table = "_etm_lang_&&_etm_lang&i.",
                        id = '_etm_ID',
                        targetType = "&boolRuleTargetType."
                        targets = {"&boolRuleTarget_1_name_base."}
                    }

                    termInfo = {table = "_etm_terms_&&_etm_lang&i.", id = '_termnum_', label = '_term_'}
                    casOuts = {rules = {name = "_etm_rules_&&_etm_lang&i.", replace = True}
                        ruleTerms = {name = "_etm_ruleTerms_&&_etm_lang&i.", replace = True}
                        candidateTerms = {name = "_etm_cnddtTerms_&&_etm_lang&i.", replace = True}
                    };
            run;

            proc sql noprint;
                select _ruleid_,
                    compress(translate(strip(_rule_),'|','&'),' ~')
                    into : _etm_ranks separated by '|', : _etm_terms separated by '|'
                    from _etm_cas._etm_rules_&&_etm_lang&i.
                        order by _ruleid_;
            quit;
            
            data work._etm_boolRule_base;
                set &outTable.;
            
                %do j=1 %to &sqlobs.;
                    _etm_BR_&j.=(find(&textCol_1_name_base.,"%scan(&_etm_terms.,&j.,'|')",'i') gt 0);
                    Label _etm_BR_&j.="BoolRule_&j.: %scan(&_etm_terms.,&j.,'|')";
                %end;
            run;
            
            proc sort data=work._etm_boolRule_base;
                by _etm_ID;
            run;

            data &outTable.;
                merge &outTable. work._etm_boolRule_base;
                by _etm_ID;
            run;
            
            proc sort data=_etm_cas._etm_rules_&&_etm_lang&i. out=work._etm_butterfly;
                by _ruleid_;
            run;
            
            data work._etm_butterfly;
                retain lrecall;
                set work._etm_butterfly;
                
                rPrecision = _RuleTP_ / _RuleSupport_;
                if _n_ eq 1 then rRecall = _Recall_;
                if _n_ gt 1 then rRecall = _Recall_ - lrecall;
                lRecall = _Recall_;
            run;
            
            data work._etm_butterfly;
                set work._etm_butterfly;
            
                rPrecision = -rPrecision;
                rRecall = -rRecall;
                Zero = 0;
                Rule1    = strip(_rule_)||' ('||strip(put(_RuleSupport_, 8.))||')';
            
                call symputx('_etm_Precision', put(_Precision_, f4.2));
                call symputx('_etm_Recall', put(_Recall_, f4.2));
            run;
            
            proc format;
                picture positive low-<0='0000'
                    0<-high='0000';
            run;
            
            Title1 "Top 100 Boole Rules for Text Variable &textCol_1_name_base. and Target Variable &boolRuleTarget_1_name_base.";
            Title2 "Filter Criteria: gPositive=&gPosBR. mPositive=&mPosBR. gNegative=&gNegBR. mNegative=&mNegBR.";
            
            ods layout gridded columns = 2;
            ods region;
            ods graphics on / width = 800 Height = 1850;
            proc sgplot data = work._etm_butterfly(obs = 100) noautolegend;
            
            Title "Single Rule - Support - Cumul. Rule";
            footnote;
            
            format _Precision_ _Recall_ rPrecision rRecall positive.;
            hbarparm category=rule1 response=_precision_ / dataskin=gloss name='Precision'
                fillattrs=graphdata1  datalabelattrs=(size=10) transparency=0;
            hbarparm category=rule1 response=rPrecision /  name='rPrecision'
                fillattrs=graphdata1  datalabelattrs=(size=10) dataskin=gloss transparency=0;
            hbarparm category=rule1 response=_Recall_ / dataskin=gloss name='Recall'
                fillattrs=graphdata2  datalabelattrs=(size=10) transparency=0;
            hbarparm category=rule1 response=rRecall / dataskin=gloss name='rRecall'
                fillattrs=graphdata2  datalabelattrs=(size=10) transparency=0;
            refline &_etm_Precision. / axis=x label="Cumultive Precision=&_etm_Precision."
                labelloc=inside labelpos=min lineattrs=graphdata1;
            refline &_etm_Recall. / axis=x label="Cumultive Recall=&_etm_Recall."
                labelloc=inside labelpos=max  lineattrs=graphdata2;
            scatter x=zero y=Rule1 / markerchar=Rule1 markercharattrs=(size=8  color=black);
            keylegend 'Precision' 'Recall' 'F1';
            xaxis values=(-1 to 1 by .2)  grid offsetmin=0.05 offsetmax=0.05 values=(-1 to 1 by .2) display=(nolabel)
            Label='Single Prec & Rec - Rule(Support) - Cumul. Prec & Rec';
            yaxis display=(noticks novalues nolabel);
            scatter y=rule1 x=_f1_  / markerattrs=(Color=red symbol='CircleFilled' size=2) name="_F1_" legendlabel="F1";
            run;
            
            data work._etm_butterfly;
                set work._etm_butterfly;

                rPrecision=-rPrecision;
                rRecall=-rRecall;
            run;
            
            ods region;
            proc print data=work._etm_butterfly(Obs=100) label;
                format rPrecision rRecall  _Precision_ _Recall_  _F1_ f5.3;
                Id _RuleID_ _Rule_;
                var rPrecision rRecall _RuleSupport_ _Precision_ _Recall_  _F1_ _RuleTP_ _RuleFP_  _RuleSetTP_ _RuleSetFP_ _RuleSetSupport_;
            run;
            ods layout end;
            title;
            ods;

            * Remove datasets;
            proc datasets library=work nolist;
                delete _etm_butterfly _etm_boolRule_base;
            run; quit;

            * Remove the Custom Format;
            proc catalog cat=work.formats;
                delete positive / et=format;
            run;
        %end;
    %mend _etm_create_boolRule;

    %_etm_create_boolRule;

    * Remove the macro;
    proc catalog cat=work.sasmacr;
        delete _etm_create_boolRule.macro;
    run; quit;

%end;

* This dataset is used by different actions that run for each language in the dataset;
%if &profileText. or &createTopics. or &createPredefinedConcepts. or &useCustomConcepts. or &createBoolRules. %then %do;
    * Remove language translation dataset;
    proc datasets library=work nolist;
        delete _etm_lang_trans;
    run; quit;
%end;

* This dataset is used by actions that levarage the custom concepts;
%if &useCustomConcepts. %then %do;
    * Remove datasets;
    proc datasets library=work nolist;
        delete _etm_all_custom_concepts;
    run; quit;
%end;

%if &useTextAnalytics. %then %do;
    * End the CAS session;
    cas _etm_sess terminate;
%end;