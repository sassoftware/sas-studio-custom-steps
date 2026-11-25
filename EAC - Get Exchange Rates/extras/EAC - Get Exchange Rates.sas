%macro _ger_exchangeRates();
	%local _ger_previousDay;

	%if &latestRate. %then %do;
		%if &apiEndpoint. EQ eraio %then %do;
			filename _ger_xr temp;
			proc http
				method='get'
				url="http://api.exchangeratesapi.io/v1/latest?access_key=&apiKey.%nrstr(&)base=&baseCurrency."
				out=_ger_xr;
			quit;
			libname _ger_xr json;

			data &outputtable1.;
				length currencyCode $3. exchangeRate 8.;
				label currencyCode = 'Code of the currency for each exchange rate'
					exchangeRate = 'Exchange code for each currency';
				set _ger_xr.alldata(where=(P=2));
				
				currencyCode = p2;
				exchangeRate = input(value, 8.);

				keep currencyCode exchangeRate;
			run;

			libname _ger_xr clear;
			filename _ger_xr clear;
		%end;
		%else %do;
			%put ERROR: The endpoint &apiEndpoint. is not fully implemented.;
		%end;
	%end;
	%else %do;
		%let _ger_previousDay = %sysfunc(putn(%eval(%sysfunc(today())-1),yymmdd10.));
		%if &pastDate. GT &_ger_previousDay. %then %do;
			%put ERROR: The past date is equal to or greater then the current date;
			%put ERROR: Please use the mode to get the latest exchange rates or fix the date;
		%end;
		%else %do;
			%if &apiEndpoint. EQ eraio %then %do;
				filename _ger_xr temp;
				proc http
					method='get'
					url="http://api.exchangeratesapi.io/v1/&pastDate.?access_key=&apiKey.%nrstr(&)base=&baseCurrency."
					out=_ger_xr;
				quit;
				libname _ger_xr json;
	
				data &outputtable1.;
					length currencyCode $3. exchangeRate 8.;
					label currencyCode = 'Code of the currency for each exchange rate'
						exchangeRate = 'Exchange code for each currency';
					set _ger_xr.alldata(where=(P=2));
					
					currencyCode = p2;
					exchangeRate = input(value, 8.);
	
					keep currencyCode exchangeRate;
				run;
	
				libname _ger_xr clear;
				filename _ger_xr clear;
			%end;
			%else %do;
				%put ERROR: The endpoint &apiEndpoint. is not fully implemented.;
			%end;
		%end;
	%end;
%mend _ger_exchangeRates;

%_ger_exchangeRates();

%sysmacdelete _ger_exchangeRates;