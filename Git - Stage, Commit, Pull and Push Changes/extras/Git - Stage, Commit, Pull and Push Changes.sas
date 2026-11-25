* Extract only the path + filename from the user inputs;
data _null_;
	call symput("gitRepo", scan("&gitRepo.", 2, ':', 'MO'));

	%if &gitAuthMethod. = ssh %then %do;
		call symput("publicKeyFile", scan("&publicKeyFile.", 2, ':', 'MO'));
		call symput("privateKeyFile", scan("&privateKeyFile.", 2, ':', 'MO'));
	%end;
run;

* Stage all changes;
%if &stageChanges. = all %then %do;
	data _null_;
		length path $1024. status $64. staged $32.;
	
		numOfChanges = git_status("&gitRepo.");
	
		do i = 1 to numOfChanges;
			rc1=git_status_get(i, "&gitRepo.", 'Path', path);
			rc2=git_status_get(i, "&gitRepo.", 'Status', status);
			rc3=git_status_get(i, "&gitRepo.", 'Staged', staged);
	
			if staged = 'FALSE'	then do;
				rc = git_index_add("&gitRepo.", strip(path), status);
				if rc = 0 then putlog 'NOTE: The Stage-Git operation was successful.';
				else putlog 'ERROR: The Stage-Git operation failed';
			end;
		end;
	run;
%end;

* Stage changes based on a table;
%if &stageChanges. = fromTable %then %do;
	data _null_;

		set &repoChangesTable.;

		if staged = 'FALSE'	then do;
			rc = git_index_add("&gitRepo.", strip(path), status);
			if rc = 0 then putlog 'NOTE: The Stage-Git operation was successful.';
			else putlog 'ERROR: The Stage-Git operation failed';
		end;
	run;
%end;

* Commit to Git;
data _null_;
	rc = git_commit("&gitRepo.", 'HEAD', "&gitUser.", "&gitUserMail.", "&gitCommitMessage");

	* Check Git response code and inform user;
	if rc = 0 then putlog 'NOTE: The Commit-Git operation was successful.';
	else putlog 'ERROR: The Commit-Git operation failed.';
run;

* Pull from Git - User and Password/Token based;
%if &alsoPull. and &gitAuthMethod. = user %then %do;
	data _null_;
		rc = git_pull("&gitRepo.", "&gitUser.", "&gitPassword.");
	
		* Check Git response code and inform user;
		if rc = 0 then putlog 'NOTE: The Git-Pull operation was successful.';
		else if rc = 1 then putlog 'NOTE: The local repository was already up-to-data.';
		else putlog 'ERROR: The Git-Pull operation failed.';
	run;
%end;

* Pull from Git - SSH key based;
%if &alsoPull. and &gitAuthMethod. = ssh %then %do;
	data _null_;
		rc = git_pull("&gitRepo.", "&sshUser.", "&sshKeyPassword.", "&publicKeyFile.", "&privateKeyFile.");
	
		* Check Git response code and inform user;
		if rc = 0 then putlog 'NOTE: The Git-Pull operation was successful.';
		else if rc = 1 then putlog 'NOTE: The local repository was already up-to-data.';
		else putlog 'ERROR: The Git-Pull operation failed.';
	run;
%end;

* Pull from Git - Kerberos based;
%if &alsoPull. and &gitAuthMethod. = kerberos %then %do;
	data _null_;
		rc = git_pull("&gitRepo.", '', '', '', '', '', 1);
	
		* Check Git response code and inform user;
		if rc = 0 then putlog 'NOTE: The Git-Pull operation was successful.';
		else if rc = 1 then putlog 'NOTE: The local repository was already up-to-data.';
		else putlog 'ERROR: The Git-Pull operation failed.';
	run;
%end;

* Push to Git - User and Password/Token based;
%if &alsoPush. and &gitAuthMethod. = user %then %do;
	data _null_;
		rc = git_push("&gitRepo.", "&gitUser.", "&gitPassword.");
	
		* Check Git response code and inform user;
		if rc = 0 then putlog 'NOTE: The Git-Push operation was successful.';
		else putlog 'ERROR: The Git-Push operation failed.';
	run;
%end;

* Push to Git - SSH key based;
%if &alsoPush. and &gitAuthMethod. = ssh %then %do;
	data _null_;
		rc = git_push("&gitRepo.", "&sshUser.", "&sshKeyPassword.", "&publicKeyFile.", "&privateKeyFile.");
	
		* Check Git response code and inform user;
		if rc = 0 then putlog 'NOTE: The Git-Push operation was successful.';
		else putlog 'ERROR: The Git-Push operation failed.';
	run;
%end;

* Push to Git - Kerberos based;
%if &alsoPush. and &gitAuthMethod. = kerberos %then %do;
	data _null_;
		rc = git_push("&gitRepo.", '', '', '', '', '', 1);
	
		* Check Git response code and inform user;
		if rc = 0 then putlog 'NOTE: The Git-Push operation was successful.';
		else putlog 'ERROR: The Git-Push operation failed.';
	run;
%end;