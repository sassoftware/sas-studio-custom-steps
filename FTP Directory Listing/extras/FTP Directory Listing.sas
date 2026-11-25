/*
	Create a reference to the FTP listing command.
*/
filename ftplist 
	ftp
	%if &_passive %then %do;
		passive
	%end;
	user="&_username"
	pass="&_password"
	host="&_ftphost"
	%if &_debug %then %do;
		debug
	%end;
	cd="&_directory"
	ls
	lsfile="&_filter";

/*
	Execute the reference and make a dataset out-of-it.
	Note that this step makes sure that rows with empty filenames are not
	taken into account.
*/
data &_output(where=(strip(filename) NE ''));
	length directory $256;
	length filename $256;

	infile ftplist missover;

	directory = strip("&_directory");
	input
		filename $;
	filename = strip(filename);
run;
	