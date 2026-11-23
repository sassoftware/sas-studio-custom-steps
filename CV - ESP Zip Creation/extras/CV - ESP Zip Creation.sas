
/*-----------------------------------------------------------------------------------------*
Macro to check if a given libref belongs to a SAS or CAS engine.
/*------------------------------------------------------------------------------------------*/
%if "%upcase(&tbleforESP_engine)" ne "CAS" %then %do;

	data _null_;
		putlog "ERROR: The selected table is not a CAS table.";
		putlog "ERROR: Please select a library that points to a caslib.";
		abort 42;
	run;

%end;
%else %do;
	%let _tm_nameCaslib=%sysfunc(getlcaslib(&tbleforESP_lib));
	%put CASLIB name: &tbleforESP_lib;
%end;


/*-----------------------------------------------------------------------------------------*
Macro to check if a the required columns exist in the data.
/*------------------------------------------------------------------------------------------*/
%macro columnExists(datasetName, columnName);
	%* Assumes that datasetName exists;
	%* Returns 1 when columnName exists, otherwise 0;
	%local dsid colnum rcColumnExists;
	%let dsid=%sysfunc(open(&datasetName));
	%let colnum=%sysfunc(varnum(&dsid,&columnName));
	%let rc=%sysfunc(close(&dsid));

	%if &colnum>0 %then %let rcColumnExists=1;
     	         %else %let rcColumnExists=0;
	&rcColumnExists;
%mend columnExists;



data _null_;
	call symput("Inser_caslibESP", scan(%cmpres("&tbleforESP."), 1, ".", "MO"));
	call symput("Inser_tbleESP", scan(%cmpres("&tbleforESP."), 2, ".", "MO"));
run;

data _null_;
	x="&ESP_zip_location";
	y=find(x, ':');
	z=substr(x, (find(x, ':')+1));
	call symputx("ESPziplocation", z);
run;

data _null_;
	x="&_usrvidfile_";
	y=find(x, ':');
	z=substr(x, (find(x, ':')+1));
	call symputx("_uservidfile_", z);
run;

data _null_;
	thevidtestfile2=scan("&_usrvidfile_", -1, '/');
	call symputx("replacevideonamehere", thevidtestfile2);
run;

/* check if the user is trying to save or reference files in the SAS content, which is not allowed */
data _null_;
	location=scan("&ESP_zip_location.", 1, ':', 'MO');

	if location eq 'sascontent' then do;
		putlog "ERROR: Please ensure that the directory containing images is located in SAS Server not in SAS Content";
		abort 42;
	end;
run;

data _null_;
	location=scan("&_usrvidfile_.", 1, ':', 'MO');

	if location eq 'sascontent' then do;
		putlog "ERROR: Please ensure that the directory containing images is located in SAS Server not in SAS Content";
		abort 42;
	end;
run;





%put Does column type exist?: %columnExists(&tbleforESP_lib..&tbleforESP_name,type);
%put Does column name exist?: %columnExists(&tbleforESP_lib..&tbleforESP_name,name);


data _null_;
	set &tbleforESP_lib..&tbleforESP_name;
	retain 	found_model_folder 
			found_model_name 
			found_model_type
			found_image_height
			found_image_width
			found_number_of_objects;

	if type="model_folder" then do;
		call symputx("mac_project_path", name);
		found_model_folder=1;
	end;

	if type="model_name" then do;
		call symputx("mac_model_name", name);
		found_model_name=1; 
	end;

	if type="model_type" then do;
		call symputx("mac_model_type", name);
		found_model_type=1;
	end;

	if type="image_height" then do;
		call symputx(%cmpres("mac_image_height"), name);
		found_image_height=1;
	end;

	if type="image_width" then do;
		call symputx(%cmpres("mac_image_width"), name);
		found_image_width=1;
	end;

	if type="number_of_objects" then do;
		call symputx("mac_num_objs", name);
		found_number_of_objects=1;
	end;
run;

%macro mac4testvid;
	%global _incdtestvidfile_;
	%let _incdtestvidfile_=;

	%if &includevidfile_=yes %then %do;
		%let _incdtestvidfile_=ods package(ESPOutput) add file="&_uservidfile_" 
			path="test_files";
		;
	%end;
%mend;

%mac4testvid;

/* Create a the following XML file in the specified location using the DATA step */
filename xml_cl "&ESPziplocation./model.xml";

/* Number of objects to created */
/* %let numObjectsToCreate = &mac_num_objs; */
/* Create the XML file robertclean1.xml */
data _NULL_;
	/* Read in the datalines text specified under datalines */
	infile datalines truncover;

	/* Column to store the string for each row from the datalines */
	input row_string $500.;

	/*<-------Modify length of column based on your needs */
	/* File to create from above */
	file xml_cl;

	/*********************************************************************/
	/*Stuff to change as the DATA step loops over each line in datalines */
	/*********************************************************************/
	/* Change random thing for that row */
	if find(row_string, '_renamemodel_')>1 then do;
		row_string=trim(left(TRANSTRN(row_string, '_renamemodel_', 
			"&mac_model_name")));
		row_string=trim(left(row_string));
	end;

	if find(row_string, '_renamemodeltype_')>1 then 
		row_string=trim(left(TRANSTRN(trim(left(row_string)), '_renamemodeltype_', 
		"&mac_model_type")));

	if find(row_string, '_recodeimgheight_')>1 then do;
		row_string=trim(left(TRANSTRN(trim(left(row_string)), '_recodeimgheight_', 
			"&mac_image_height")));
		row_string=trim(left(row_string));
	end;

	if find(row_string, '_recodeimgwidth_')>1 then 
		row_string=trim(left(TRANSTRN(trim(left(row_string)), '_recodeimgwidth_', 
		"&mac_image_width")));

	if find(row_string, '_video_test_file_')>1 then do;
		row_string=trim(left(TRANSTRN(row_string, '_video_test_file_', 
			"&replacevideonamehere")));
		row_string=trim(left(row_string));
	end;

	/* Create n number of objects in xml file - Use the last default Object0_height value to start loop */
	if row_string='<field name="_Object0_height" type="double"/>' then do;

		/* Write the 0 height row out to the xml file */
		put row_string;

		/*Create new objects for XML file based on amount specified */
		i=1;

		do while(i<&mac_num_objs);

			/* Make loop number a character to replace N value for each object */
			makeNumericValueCharacter=strip(put(i, 8.));

			/* Create the following columns for N object value */
			_ObjectN_=tranwrd('<field name="_ObjectN_" type="string"/>', 'N', 
				strip(makeNumericValueCharacter));
			_P_ObjectN_=tranwrd('<field name="_P_ObjectN_" type="double"/>', 'N', 
				strip(makeNumericValueCharacter));
			_ObjectN_x=tranwrd('<field name="_ObjectN_x" type="double"/>', 'N', 
				strip(makeNumericValueCharacter));
			_ObjectN_y=tranwrd('<field name="_ObjectN_y" type="double"/>', 'N', 
				strip(makeNumericValueCharacter));
			_ObjectN_width=tranwrd('<field name="_ObjectN_width" type="double"/>', 'N', 
				strip(makeNumericValueCharacter));
			_ObjectN_height=tranwrd('<field name="_ObjectN_height" type="double"/>', 
				'N', strip(makeNumericValueCharacter));

			/* Write values out to XML file */
			put _ObjectN_;
			put _P_ObjectN_;
			put _ObjectN_x;
			put _ObjectN_y;
			put _ObjectN_width;
			put _ObjectN_height;
			i+1;

			/* Continue this loop for n objects */
		end;
	end;
	else do;
		put row_string;

		/* Write the row of data to the new file in the file statement instead of loop*/
	end;

	/* XML file pasted text below under datalines */
	datalines;
<project heartbeat-interval="1" index="pi_EMPTY" name="project_package_astore" pubsub="auto" threads="4">
  <!--As best practice the project name should include the model, if different from zip file name the zip name prevail-->
  <metadata>
    <meta id="studioUploadedBy">appadmin</meta>
    <meta id="studioUploaded">1698665688966</meta>
    <meta id="studioModifiedBy">appadmin</meta>
    <meta id="studioModified">1699006255529</meta>
    <meta id="layout">{"cq1":{"w_counter":{"x":50,"y":420},"w_model_reader":{"x":330,"y":420},"w_resize":{"x":190,"y":175},"w_score":{"x":190,"y":295},"w_source":{"x":190,"y":50}}}</meta>
  </metadata>
  <properties>
    <!--change depending on model-->
<property name="MODEL_NAME"><![CDATA[_renamemodel_._renamemodeltype_]]></property>
<property name="SCORE_IMAGE_WIDTH"><![CDATA[_recodeimgwidth_]]></property>
<property name="SCORE_IMAGE_HEIGHT"><![CDATA[_recodeimgheight_]]></property>
    <property name="SCORE_IMAGE_RESIZE_TYPE"><![CDATA[basic]]></property><!--basic or letterbox-->
    <property name="TEST_VIDEO_FILE"><![CDATA[_video_test_file_]]></property>
    <!-- end of change depending on model-->
  </properties>
  <contqueries>
    <contquery name="cq1">
      <windows>
        <window-source insert-only="true" name="w_source">
          <schema>
            <fields>
              <field key="true" name="id" type="int64"/>
              <field name="_image_" type="blob"/>
            </fields>
          </schema>
          <connectors>
            <connector class="videocap" name="pub_video_file">
              <properties>
                <property name="type"><![CDATA[pub]]></property>
                <property name="filename"><![CDATA[@ESP_PROJECT_HOME@/test_files/@TEST_VIDEO_FILE@]]></property>
                <property name="publishformat"><![CDATA[wide]]></property>
                <property name="publishrate"><![CDATA[30]]></property>
              </properties>
            </connector>
          </connectors>
        </window-source>
        <window-calculate algorithm="ImageProcessing" name="w_resize">
          <schema>
            <fields>
              <field key="true" name="id" type="int64"/>
              <field name="_image_" type="blob"/>
              <field name="_resized_image_" type="blob"/>
            </fields>
          </schema>
          <parameters>
            <properties>
              <property name="function"><![CDATA[resize]]></property>
              <property name="coordType"><![CDATA[RECT]]></property>
              <property name="preFlip"><![CDATA[-1000]]></property>
              <property name="x"><![CDATA[0]]></property>
              <property name="y"><![CDATA[0]]></property>
              <property name="xMin"><![CDATA[0]]></property>
              <property name="yMin"><![CDATA[0]]></property>
              <property name="xMax"><![CDATA[0]]></property>
              <property name="yMax"><![CDATA[0]]></property>
              <property name="width"><![CDATA[@SCORE_IMAGE_WIDTH@]]></property>
              <property name="height"><![CDATA[@SCORE_IMAGE_HEIGHT@]]></property>
              <property name="outputWidth"><![CDATA[0]]></property>
              <property name="outputHeight"><![CDATA[0]]></property>
              <property name="outputEncoding"><![CDATA[jpg]]></property>
              <property name="alpha"><![CDATA[0]]></property>
              <property name="beta"><![CDATA[0]]></property>
              <property name="delta"><![CDATA[0]]></property>
              <property name="theta"><![CDATA[0]]></property>
              <property name="value"><![CDATA[0]]></property>
              <property name="minValue"><![CDATA[0]]></property>
              <property name="maxValue"><![CDATA[0]]></property>
              <property name="type"><![CDATA[0]]></property>
              <property name="flag1"><![CDATA[0]]></property>
              <property name="flag2"><![CDATA[0]]></property>
              <property name="flag3"><![CDATA[0]]></property>
              <property name="flag4"><![CDATA[0]]></property>
              <property name="flag5"><![CDATA[0]]></property>
              <property name="scale"><![CDATA[0]]></property>
              <property name="resizeType"><![CDATA[@SCORE_IMAGE_RESIZE_TYPE@]]></property>
              <property name="interpolation"><![CDATA[linear]]></property>
              <property name="padding"><![CDATA[constant]]></property>
              <property name="b"><![CDATA[0]]></property>
              <property name="g"><![CDATA[0]]></property>
              <property name="r"><![CDATA[0]]></property>
              <property name="smoothType"><![CDATA[Gaussian]]></property>
              <property name="normalizeType"><![CDATA[zero_one]]></property>
              <property name="kernelHeight"><![CDATA[3]]></property>
              <property name="kernelWidth"><![CDATA[3]]></property>
              <property name="padType"><![CDATA[size_divisible]]></property>
              <property name="sizeDivisor"><![CDATA[8]]></property>
              <property name="cropType"><![CDATA[basic]]></property>
            </properties>
          </parameters>
          <input-map>
            <properties>
              <property name="imageInput"><![CDATA[_image_]]></property>
            </properties>
          </input-map>
          <output-map>
            <properties>
              <property name="imageOutput"><![CDATA[_resized_image_]]></property>
            </properties>
          </output-map>
        </window-calculate>
        <window-score name="w_score">
          <schema>
            <fields>
              <field key="true" name="id" type="int64"/>
              <field name="_image_" type="blob"/>
              <field name="_resized_image_" type="blob"/>
<!--Below you need to specify the output fields of the Astore. Note that ESP uses different variable types-->
<field name="_nObjects_" type="double"/>              
<field name="_Object0_" type="string"/>              
<field name="_P_Object0_" type="double"/>              
<field name="_Object0_x" type="double"/>             
<field name="_Object0_y" type="double"/>              
<field name="_Object0_width" type="double"/>              
<field name="_Object0_height" type="double"/>
<!-- end of change depending on model-->
            </fields>
          </schema>
          <models>
            <offline model-type="_renamemodeltype_">
              <input-map>
                <properties>
                  <property name="_image_"><![CDATA[_resized_image_]]></property>
                  <!--This maps the _resized_image_ field in ESP to the _image_ variable that the Astore expects. Change if needed-->
                </properties>
              </input-map>
            </offline>
          </models>
        </window-score>
        <window-model-reader model-type="_renamemodeltype_" name="w_model_reader">
          <parameters>
            <properties>
              <property name="reference"><![CDATA[@ESP_PROJECT_HOME@/analytics/@MODEL_NAME@]]></property>
              <property name="USEGPUESP"><![CDATA[1]]></property>
              <!--The model will use a GPU if available, otherwise it will use a CPU-->
            </properties>
          </parameters>
        </window-model-reader>
        <window-counter count-interval="1 seconds" name="w_counter"/>
      </windows>
      <edges>
        <edge role="data" source="w_source" target="w_resize"/>
        <edge role="data" source="w_resize" target="w_score"/>
        <edge role="model" source="w_model_reader" target="w_score"/>
        <edge source="w_score" target="w_counter"/>
      </edges>
    </contquery>
  </contqueries>
</project>

;
run;

data _null_;
	call symputx("newmac_model_name", %LOWCASE("&mac_model_name"));
run;

ods package(ESPOutput) open nopf;
ods package(ESPOutput) add file="&ESPziplocation./model.xml" path="model";
ods package(ESPOutput) add 
	file="&mac_project_path./&newmac_model_name..&mac_model_type" path="analytics";
&_incdtestvidfile_;
ods package(ESPOutput) publish archive
properties(archive_name="&ESPzipfilename..zip"
archive_path="&ESPziplocation");
ods package(ESPOutput) close;
%SYMDEL
ESPzipfilename
ESPziplocation
mac_project_path
newmac_model_name
mac_model_type
list_of_caslibs
_incdtestvidfile_
includevidfile_
mac_num_objs
mac_image_width
mac_image_height
replacevideonamehere / NOWARN;
%SYSMACDELETE mac4testvid;
%SYSMACDELETE columnExists;
