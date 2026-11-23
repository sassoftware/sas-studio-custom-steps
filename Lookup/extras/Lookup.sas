/*==========================================================================* 
 * Custom Step:     Lookup                                                  * 
 * Transform:       Lookup                                                  * 
 * Description:     Do lookup using hash object.                            * 
 *==========================================================================*/ 

/*
Required macro variables

BaseTable
BaseKeepColumns_count

For each BaseTableKeepColumn:
BaseKeepColumns_<N>_name
BaseKeepColumns_<N>_type
BaseKeepColumns_<N>_rawlength

KeyNotFoundValue

LookupKeyColumns_count

For each LookupKeyColumn:
LookupKeyColumns_<N>_name

LookupTable
ReturnColumn_1_name
ReturnColumn_1_type
ReturnColumn_1_rawlength

ResultTable
ResultTable_lib
ResultTable_name
*/

%macro combineparameters(
       parameterID=
      ,formula=name
      ,resultVariableSuffix=
      ,delimiter=
   );
   %local i TypeBefore;
   %global &parameterID.&resultVariableSuffix.;
   
   %** Initialize variables **;
   %let &parameterID.&resultVariableSuffix. = ;

   data _NULL_;
      call symputx('formula',
                     prxchange(
                         prxparse('s/(format|informat|label|name|name_base|rawlength|type)/&&&parameterID._&i._$1/')
                        ,-1,"&formula.")
                    ,'L');
   run;
   
   %do i=1 %to &&&parameterID._count.;
      %let TypeBefore = &&&parameterID._&i._type;
      %if %upcase(&&&parameterID._&i._type)=CHAR or %upcase(&&&parameterID._&i._type)=CHARACTER %then %let &parameterID._&i._type = $;
      %else %if %upcase(&&&parameterID._&i._type)=NUMERIC %then %let &parameterID._&i._type=;
      %if &i.>1 %then %let &parameterID.&resultVariableSuffix. = &&&parameterID.&resultVariableSuffix.&delimiter.;
      %let &parameterID.&resultVariableSuffix. = &&&parameterID.&resultVariableSuffix. &formula.;
      
      %** Reset column selector TYPE macro variable **;
      %let &parameterID._&i._type = &TypeBefore.;
   %end;
%mend combineParameters;

%macro lookup;

	%global KeyNotFoundValue;
   
   %**** Prepare Prompt Values ****;
   %combineParameters(
       parameterID=BaseKeepColumns
   );

   %combineParameters(
       parameterID=BaseKeepColumns
      ,formula=%str(name length=typerawlength)
      ,resultVariableSuffix=Attrib
   );
   
   %combineParameters(
       parameterID=LookupKeyColumns
      ,formula=%str(%"name%")
      ,resultVariableSuffix=DefineKey
      ,delimiter=%str(,)
   );

   %combineParameters(
       parameterID=LookupKeyColumns
      ,formula=%str(name)
      ,resultVariableSuffix=
      ,delimiter=%str(,)
   );

   %combineParameters(
       parameterID=LookupKeyColumns
      ,formula=%str(key: name)
      ,resultVariableSuffix=Key
      ,delimiter=%str(,)
   );

   %combineParameters(
       parameterID=LookupKeyColumns
      ,formula=%str(name length=typerawlength)
      ,resultVariableSuffix=Attrib
   );
   
   %let ReturnColumn = &ReturnColumn_1_name.;
   %combineParameters(
       parameterID=ReturnColumn
      ,formula=%str(name length=typerawlength)
      ,resultVariableSuffix=Attrib
   );

   %**** Delete result table ****;
   proc datasets lib = &ResultTable_lib. nolist nowarn memtype = (data view);
      delete &ResultTable_name.;
   quit;
   
   %****---- Begin DATA step to perform lookups  ----****; 
   DATA  &ResultTable.
            (keep = &BaseKeepColumns. &ReturnColumn_1_name. )
         ; 
      
      attrib &BaseKeepColumnsAttrib.
             &LookupKeyColumnsAttrib.
             &ReturnColumnAttrib.
             ; 
      
      retain missing0-missing0 0; 
      
      etls_assign_target_value = 0; 
      %** Build hash objects from lookup tables before reading first source row  **;
      if (_n_ = 1) then 
      do; 
         %** Build hash h0 from lookup table work.origin_dim **;
         nlobs = .; 
         dsid = open("&LookupTable."); 
         if (dsid > 0) then 
         do; 
            if ( attrc(dsid, 'MTYPE') = 'DATA' ) then 
               nlobs = attrn(dsid, 'NLOBS'); 
            else 
               nlobs = -1; 
               
            dsid = close(dsid); 
            if (nlobs ^= 0) then 
            do; 
               if (nlobs > 0) then 
                  exponent = ceil(log2(nlobs)); 
               else 
                  exponent = 8; 
               declare hash h0(dataset: "&LookupTable.", hashexp: exponent);
               h0.defineKey( &LookupKeyColumnsDefineKey.);
               h0.defineData( "&ReturnColumn.");
               h0.defineDone();
               if (nlobs = -1) then 
               do; 
                  if (h0.Num_Items < 1) then
                  do; 
                     put "NOTE: Lookup table is empty: &LookupTable.";
                     put "NOTE: Abort action indicated, condition= Lookup table is empty:"
                          " &LookupTable.";
                     abort 3; 
                  end; 
               end; 
            end; 
            else 
            do; 
               put "NOTE: Lookup table is empty: &LookupTable.";
               put "NOTE: Abort action indicated, condition= Lookup table is empty:"
                    " &LookupTable.";
               abort 3; 
            end; 
         end; 
         else 
         do; 
            put "NOTE: Lookup table does not exist or cannot be opened:"
                 " &LookupTable.";
            
            put "NOTE: Abort action indicated, condition= Lookup table missing:"
                 " &LookupTable.";
            abort 3; 
         end; 
         
         call missing (&LookupKeyColumns., &ReturnColumn.); 
      
      end; %** All hash objects have been defined **;
      
      %** Read a row from the source table  **;
      set &BaseTable. end = eof;
      
      %** Is the current key value stored in hash h0?  **;
      rc0 = h0.find(&LookupKeyColumnsKey.);
      %** Examine success of lookups  **;
      if ( rc0=0 ) then 
      do; 
         %** Write row to target  **;
         output &ResultTable.; 
      end; 
      else 
      do; 
         error_total + 1; 
         
         if (rc0 ^= 0) then 
         do; 
            exception_total + 1; 
            %** Check: Lookup value not found-Set target columns to missing  **;
            %if "&KeyNotFoundValue."="" %then %do;
               call missing (&ReturnColumn.); 
            %end;
            %else %do;
               %if "%upcase(&ReturnColumn_1_type.)"="CHARACTER" %then %do;
                  &ReturnColumn. = "&KeyNotFoundValue.";
               %end;
               %else %do;
                  &ReturnColumn. = &KeyNotFoundValue.;
               %end;
            %end;
            etls_assign_target_value = 1; 
         end; 
         
         %** Set target columns to value/missing requested?  **;
            %** Write row to target  **;
         if (etls_assign_target_value eq 1) then 
            output &ResultTable.; 
      
      end; %** One or more lookups failed **;
      
      if (eof = 1) then 
      do; 
         put "Source records with errors: " error_total ; 
         put "Total lookup exceptions: " exception_total ; 
      end; 
   
   run; 

%mend lookup;


%lookup;
