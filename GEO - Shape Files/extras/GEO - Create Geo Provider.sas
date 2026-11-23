/* Put the body of the JSON content in external file */
FILENAME ADD_OUT TEMP ENCODING='UTF-8';
FILENAME ADD_hd TEMP ENCODING='UTF-8';

%let CASLIB = %scan(&inputtable1,1,'.');
%put CASLIB = &CASLIB;

%let TABLE = %scan(&inputtable1,2,'.');
%put TABLE = &TABLE;

%LET casTableUri = %STR(/servers/cas-shared-default/caslibs/&CASLIB/tables/&TABLE);

%PUT name            = &name            ;
%PUT label           = &label           ;
%PUT type            = &type            ;
%PUT casTableUri     = &casTableUri     ;
%PUT coordinate 	 = &coordinate 		;
%PUT filecoordinate  = &filecoordinate 	;
%PUT geometryType    = &geometryType    ;
%PUT idColumn        = &idColumn        ;
%PUT segmentColumn   = &segmentColumn   ;
%PUT sequenceColumn  = &sequenceColumn  ;
%PUT xColumn         = &xColumn         ;
%PUT yColumn         = &yColumn         ;

%let Proj = %Scan(&filecoordinate,2,':');
%put PRJ = &Proj;

data work.projection;
infile "&Proj" truncover scanover;
format Projection $10000.;
input  Projection $10000.;
call symput('coordinate',%trim(Projection));
run;

%LET coordinateSpace1  = %sysfunc(tranwrd(%quote(&coordinate),%str(%"),%str(\%%%")));
%PUT &coordinateSpace1;

%let IN =  %STR({ %"name%": %"&name.%" , 
	%"label%": %"&label.%" , 
	%"type%": %"&type.%" ,
	%"geometryType%": %"&geometryType.%" ,
	%"casTableUri%": %"&casTableUri.%" ,
	%"idColumn%": %"&idColumn.%" ,
	%"sequenceColumn%": %"&sequenceColumn.%" ,
	%"xColumn%": %"&xColumn.%" ,
	%"yColumn%": %"&yColumn.%" ,
	%"segmentColumn%": %"&segmentColumn.%" ,
	%"coordinateSpace%": %"&coordinateSpace1.%" } );
%put IN = &IN;

/*Create the provider*/

%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));

PROC HTTP METHOD="POST" oauth_bearer=sas_services OUT=ADD_OUT headerout=ADD_hd
	URL = "&BASE_URI/maps/providers"
	IN=%QUOTE("&IN");
    HEADERS "Accept" = "application/vnd.sas.maps.provider+json"
			"Content-Type" = "application/json" ;
/* debug level=3; */
RUN;

proc delete data=work.projection; run;