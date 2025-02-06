/* Set email options */
options 
	emailsys=smtp
	emailhost=&smtpHost 
	emailport=&smtpPort
;


/* if emailBody_count is empty (doesnt exist) create it and create emailBody_1 */
%global emailBody_count ;
%if &emailBody_count eq %then %do ; 
	%let emailBody_count=1 ;
	%let emailBody_1=&emailBody ;
%end ;


/* Format input information if multiple email addresses entered */
data _null_ ;
    newEmailTo=cats(transtrn(strip(compbl(translate("&emailTo"," ",",")))," ",'" "')) ;
    call symput('emailTo',strip(newEmailTo)) ;
    newEmailCC=cats(transtrn(strip(compbl(translate("&emailCC"," ",",")))," ",'" "')) ;
    call symput('emailCC',strip(newEmailCC)) ;
    newEmailBCC=cats(transtrn(strip(compbl(translate("&emailBCC"," ",",")))," ",'" "')) ;
    call symput('emailBCC',strip(newEmailBCC)) ;
run ;


/* Format and send email */
filename outmail email
	from="&emailFrom"
 	to=("&emailTo")
	cc=("&emailCC")
	bcc=("&emailBCC")
	subject="&emailSubject"
 	importance="&importance" /* Low Normal High.  Default is Normal */
	/* If ReadReceipt option is checked */
	%if &readReceipt %then %do ;
		readreceipt
	%end ;
 	ct="text/html"
;


/* Build the body of the email */
data _null_ ;
	file outmail ;
	put "<html><body>" ;
    put "<p style='color: #&textColor'>" ;
	do i = 1 to &emailBody_count ;
        if symget("emailBody_" || strip(put(i,12.))) eq '' then do ;
			text=cats("<br>") ;
        end ;
        else do ;
			text=cats(symget("emailBody_" || strip(put(i,12.))),"<br>") ;
		end ;
		put text ;
	end ;
    put "</p>" ;
	put "</body></html>" ;
run ;


/* Clear macro */
%symdel emailBody_count ;