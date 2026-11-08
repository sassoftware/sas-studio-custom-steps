options nomprint nomlogic;
caslib _all_ assign;
options NOSERR;
options casdatalimit="ALL";

data _null_;
	x="&_insert_projectpath";
	y=find(x, ':');
	z=substr(x, (find(x, ':')+1));
	z_nogo=substr(x, 1, (y-1));
	call symput("tempprojpath_lib_", z);
	call symput("chk_projectpath__", z_nogo);
run;

data _null_;
	x="&_insert_modepath";
	y=find(x, ':');
	z=substr(x, (find(x, ':')+1));
	z_nogo=substr(x, 1, (y-1));
	call symput("tempmodelpath_lib_", z);
	call symput("chk_modelpath__", z_nogo);
run;

/* check if the user is trying to save or reference files in the SAS content, which is not allowed */
%if &chk_modelpath__=sascontent %then %do;

	data _null_;
		putlog "ERROR: The folder storing the models must be stored in the SAS server (not SAS Content)";
		putlog "ERROR: In order for this step please store your models in a folder located on the SAS Server";
		abort 42;
	run;

%end;

%if &chk_projectpath__=sascontent %then %do;

	data _null_;
		putlog
		"ERROR: The project folder must be stored in the SAS server (not SAS Content)";
		putlog "ERROR: In order for this step please create the project folder on the SAS Server";
		abort 42;
	run;

%end;

/* -------------------------------------------------------------------------------------------*
This code ensures that the user specifies a valid CASLIB for output table's library name
 *-------------------------------------------------------------------------------------------- */
/* %global _tm_nameCaslib; */
%if "%upcase(&insert_intabl__engine)" ne "CAS" %then %do;

	data _null_;
		putlog "ERROR: The selected table is not a CAS table.";
		putlog "ERROR: Please select a library that points to a caslib.";
		abort 42;
	run;

%end;
%else %do;
	%let _tm_nameCaslib=%sysfunc(getlcaslib(&insert_intabl__lib));
	%put CASLIB name: &_tm_nameCaslib;
%end;

data _null_;
	/* object scale search */
	if &_checkbox_obj_scale=1 then do;
		call symput("_CV_onoff_search_obj", 'yes');
	end;

	if &_checkbox_obj_scale=0 then do;
		call symput("_CV_onoff_search_obj", 'no');
	end;

	/* no object scale search */
	if &_checkbox_noobj_scale=1 then do;
		call symput("_CV_onoff_search_noobj", 'yes');
	end;

	if &_checkbox_noobj_scale=0 then do;
		call symput("_CV_onoff_search_noobj", 'no');
	end;

	/* coord scale search */
	if &_checkbox_coord_scale=1 then do;
		call symput("_CV_onoff_search_coord", 'yes');
	end;

	if &_checkbox_coord_scale=0 then do;
		call symput("_CV_onoff_search_coord", 'no');
	end;

	/* class scale search */
	if &_checkbox_class_scale=1 then do;
		call symput("_CV_onoff_search_class", 'yes');
	end;

	if &_checkbox_class_scale=0 then do;
		call symput("_CV_onoff_search_class", 'no');
	end;

	/* detection threshold search */
	if &_checkbox_detec_threshold=1 then do;
		call symput("_CV_onoff_search_detthresh", 'yes');
	end;

	if &_checkbox_detec_threshold=0 then do;
		call symput("_CV_onoff_search_detthresh", 'no');
	end;

	/* iou threshold search */
	if &_checkbox_iou_threshold=1 then do;
		call symput("_CV_onoff_search_iouthresh", 'yes');
	end;

	if &_checkbox_iou_threshold=0 then do;
		call symput("_CV_onoff_search_iouthresh", 'no');
	end;

	/* train iou threshold search */
	if &_checkbox_trainiou_thrhold=1 then do;
		call symput("_CV_onoff_search_trainiou", 'yes');
	end;

	if &_checkbox_trainiou_thrhold=0 then do;
		call symput("_CV_onoff_search_trainiou", 'no');
	end;

	/* FC neuron count search */
	if &_checkbox_addfc=1 then do;
		call symput("_CV_onoff_search_FCneuronnum", 'yes');
	end;

	if &_checkbox_addfc=0 then do;
		call symput("_CV_onoff_search_FCneuronnum", 'no');
	end;

	/* FC neuron activation function search */
	if &_checkbox_fcactivation=1 then do;
		call symput("_CV_onoff_search_FCactfunc", 'yes');
	end;

	if &_checkbox_fcactivation=0 then do;
		call symput("_CV_onoff_search_FCactfunc", 'no');
	end;

	/* learning rate search */
	if &_checkbox_lr=1 then do;
		call symput("_CV_onoff_search_lr", 'yes');
	end;

	if &_checkbox_lr=0 then do;
		call symput("_CV_onoff_search_lr", 'no');
	end;

	/* beta difference search */
	if &_checkbox_betadiff=1 then do;
		call symput("_CV_onoff_search_betadiff", 'yes');
	end;

	if &_checkbox_betadiff=0 then do;
		call symput("_CV_onoff_search_betadiff", 'no');
	end;

	/* minibatch search */
	if &_checkbox_minibatch=1 then do;
		call symput("_CV_onoff_search_miniBSize", 'yes');
	end;

	if &_checkbox_minibatch=0 then do;
		call symput("_CV_onoff_search_miniBSize", 'no');
	end;

	/* step size search */
	if &_checkbox_stepsize=1 then do;
		call symput("_CV_onoff_search_stepsize", 'yes');
	end;

	if &_checkbox_stepsize=0 then do;
		call symput("_CV_onoff_search_stepsize", 'no');
	end;

	/* gamma search */
	if &_checkbox_gamma=1 then do;
		call symput("_CV_onoff_search_gamma", 'yes');
	end;

	if &_checkbox_gamma=0 then do;
		call symput("_CV_onoff_search_gamma", 'no');
	end;

	/* l1 reg search */
	if &_checkbox_l1reg=1 then do;
		call symput("_CV_onoff_search_l1reg", 'yes');
	end;

	if &_checkbox_l1reg=0 then do;
		call symput("_CV_onoff_search_l1reg", 'no');
	end;

	/* l2 reg search */
	if &_checkbox_l2reg=1 then do;
		call symput("_CV_onoff_search_l2reg", 'yes');
	end;

	if &_checkbox_l2reg=0 then do;
		call symput("_CV_onoff_search_l2reg", 'no');
	end;

	/* dropout search */
	if &_checkbox_dropsearch=1 then do;
		call symput("_CV_dropValue", 'yes');
	end;

	if &_checkbox_dropsearch=0 then do;
		call symput("_CV_dropValue", 'no');
	end;

	/* backbone activation function search */
	if &_checkbox_activation_1=1 then do;
		call symput("_CV_onoff_search_actfunc", 'yes');
	end;

	if &_checkbox_activation_1=0 then do;
		call symput("_CV_onoff_search_actfunc", 'no');
	end;

	/* gradient clipping search */
	if &_checkbox_clipgrad=1 then do;
		call symput("_CV_onoff_search_gradclips", 'yes');
	end;

	if &_checkbox_clipgrad=0 then do;
		call symput("_CV_onoff_search_gradclips", 'no');
	end;
run;

%let _CV_caslib_=Teimglib;
%let _CV_objectdetectiondata_=&insert_intabl__name;
%let _CV_regressiontable_=&insert_intabl__name;
%let _CV_location_for_results_data=&tempprojpath_lib_;
%let _CV_CVmodel_location=&tempmodelpath_lib_;
%let _imageDS_=model_input_images_;
%let _CV_partition_var_=&_insert_partvar_name;
%let _CV_valid_partition_per_=&_insert_valid_percent;

/*Range from zero to 100 (_insert_valid_percent) */
%let _CV_modelBackbone_=&_insert_modelbackbone;
%let _CV_partition_seed=&_insert_partitionseed;

/*OD (_insert_od_image_size), images must be: 224 416 640 1280.  Classification or regression, images must be >=64by64*/
%let _image_input_height_=&_insert_imageheight;
%let _image_input_width_=&_insert_imagewidth;
%let n_threads_=&_insert_nthreads;
%let _image_input_color_=&_insert_image_color_count;

/*color or greyscale  (_insert_image_color_count)*/
%let _CV_tarVar_name_=&_insert_tarvar_1;
%let _CV_tarVar_commaname_=, "&_insert_tarvar_1";
%let _CV_inpVar_name_=&_insert_imagecolumn;
%let _CV_modeltask_=&_insert_modelingtask;

/* objectdetection classification regression multitask (_insert_modelingtask)*/
%let _CV_usegpu_T_F=&_insert_useGPU;

/* (_insert_useGPU)*/
%let _CV_fliptype_=&_insert_fliping;

/* _insert_fliping */
%let _CV_random_mutate=&_insert_imagemutation;

/*_insert_imagemutation*/
%let _CV_crop_RESIZE_THENCROP=&_insert_croprand;
%let _CV_num_epochs_=&_insert_finalmodel_e;
%let _CV_finalweightstable_=&_insertfinal_weights_table;
%let _CV_percentimages_to_inspect=&_insert_percent_to_inspect;

%macro check(file);
	%if %sysfunc(fileexist(&file)) ge 1 %then %do;
		%let rc=%sysfunc(filename(temp, &file));
		%let rc=%sysfunc(fdelete(&temp));
	%end;
	%else %put The file &file does not exist;
%mend check;

%check(&_CV_location_for_results_data/CVmodeldevelopmentLog.txt);

proc printto NEW log="&_CV_location_for_results_data/CVmodeldevelopmentLog.txt"
	new;
run;

data _null_;
	_updatevar_filtersizes_="&_CV_modeltask_";

	if _updatevar_filtersizes_="objectdetection" then do;
		call symput("_image_input_height_", &_insert_od_image_size);
		call symput("_image_input_width_", &_insert_od_image_size);
	end;
run;

%let _CV_saveautotune_results=&_checkbox_saveatuotunehtml;
%let _CV_autotuneresults_name=&_insert_tuneresultshtml;

/*object detection only options */
%let _CV_OD_class_num=&_insert_OD_classcount;

/*(_insert_OD_classcount)*/
%let _CV_OD_cluster_criterion=&_insert_clustercriterion;

/* FIRSTMAXWITHSTD FIRSTPEAK GLOBALPEAK */
/*(_insert_clustercriterion)*/
%let _CV_maxnumclusters=&_insert_maxbb;

/*(_insert_maxbb)*/
/* regression only options */
%let _CV_reg_error=&_insert_regerror;

/* Gamma Normal Poisson L1 */
/* (_insert_regerror) */
%let _CV_reg_out_act_function=&_insert_regactivation;

/* Identity Exponent */
/*(_insert_regactivation)*/
%let _CV_reg_out_standardization=&_insert_regtargetstd;

/* MIDRANGE none STD*/
/*(_insert_regtargetstd)*/
%let _CV_Global_autotune_initiate=&_insert_globalautotune;

/***************/
/* Global autotune */
/***************/
%let _CV_population_s=&_insert_startingpop;
%let _CV_gsslocal_s=&_insert_localpermutations;
%let _CV_gagenerations_s=&_insert_gagenerations;
%let _CV_maxtraintime=&_insert_maxeagls_time;
%let _CV_autotuneseed=&_insert_autotuneseed;
%let _CV_eval_epochs=&_insert_autotune_evalcount;
%let _CV_continue_previous_search=&_insert_useprevioussearch;

/* yes or no */
/*(_insert_useprevioussearch)*/
%let _CV_howmanytouseforfirstgen=&_insert_numofpreviousevals;

/*specifies how many observations should be used for the first generation of continued search */
%let _CV_name_autotuneresults_save=&_insert_saveautotune_results;
%let _CV_name_autotuneresults_load=&_insert_previousautoresults;

/*(_insert_previousautoresults)*/
/***************/
/* OD autotune */
/***************/
%let _CV_onoff_search_lc_width=no;

/* yes no */
%let _CV_OD_lastConvo_width=1;

/*&_insert_lc_width;*/
%let _CV_lb_OD_lconvo_width_value_=1;

/*&_insert_lcwidth_lb;*/
%let _CV_ub_OD_lconvo_width_value_=1;

/*&_insert_lcwidth_ub;*/
%let _CV_onoff_search_lc_height=no;

/* yes no */
%let _CV_OD_lastConvo_height=1;

/*&_insert_lc_height;*/
%let _CV_lb_OD_lconvo_height_value_=1;

/*&_insert_lcheight_lb;*/
%let _CV_ub_OD_lconvo_height_value_=1;

/*&_insert_lcheight_ub;*/
/* %let _CV_onoff_search_obj=yes; 				 */
%let _CV_OD_Obj_scale_=&_insert_obj_scalar;
%let _CV_lb_OD_Obj_value_=&_insert_od_obj_lbscalar;

/* (_insert_od_objpresent_lb)*/
%let _CV_ub_OD_Obj_value_=&_insert_od_obj_ubscalar;

/* %let _CV_onoff_search_noobj=yes; 				 */
%let _CV_OD_Not_Obj_scale_=&_insert_noobj_scalar;
%let _CV_lb_Not_Obj_value_=&_insert_noobj_lbscalar;

/*_insert_noobj_lb*/
%let _CV_ub_Not_Obj_value_=&_insert_noobj_ubscalar;

/* %let _CV_onoff_search_coord=yes; 			 */
%let _CV_OD_coord_scale_=&_insert_coord_scalar;
%let _CV_lb_coord_value_=&_insert_coord_lbscalar;
%let _CV_ub_coord_value_=&_insert_coord_ubscalar;

/* %let _CV_onoff_search_class=no; 				 */
%let _CV_OD_class_scale_=&_insert_class_scalar;
%let _CV_lb_class_value_=&_insert_class_lbscalar;
%let _CV_ub_class_value_=&_insert_class_ubscalar;

/* %let _CV_onoff_search_detthresh=yes; 			 */
%let _CV_OD_detection_thresh_=&_insert_detectthreshold;
%let _CV_lb_detection_thresh_value_=&_insert_detecthre_lb;
%let _CV_ub_detection_thresh_value_=&_insert_detecthre_ub;

/* %let _CV_onoff_search_iouthresh=yes; 				 */
%let _CV_OD_iouthreshold_=&_insert_iouthreshold;
%let _CV_lb_iouthreshold_value_=&_insert_iouthhold_lb;
%let _CV_ub_iouthreshold_value_=&_insert_iouthhold_ub;

/* %let _CV_onoff_search_trainiou=yes; 				 */
%let _CV_iouTrainThreshold_=&_insert_trainiouthrhold;
%let _CV_lb_iouTrainThreshold_value_=&_insert_trainiou_lb;
%let _CV_ub_iouTrainThreshold_value_=&_insert_trainiou_ub;

/* Class and regression Autotune */
%let _CV_include_FC_layer=&_insert_addfclayer;

/* yes no */
/* %let _CV_onoff_search_FCneuronnum=yes; 				 */
%let _CV_FC_neuron_num=&_insert_FC_neuroncount;
%let _CV_lb_FC_neuron_value_=&_insert_FCneuron_lb;
%let _CV_ub_FC_neuron_value_=&_insert_FCneuron_ub;

/* %let _CV_onoff_search_FCactfunc=yes; 				 */
%let _CV_FC_act_function=&_insert_fc_act;

/**************************/
/*  Global Autotune */
/**************************/
/*NEW*/
%let _CV_onoff_search_firstc_fsize=&_checkbox_fl_filtersize;

/* yes no */
%let _CV_assigned_firstc_fsize=&_insert_fcl_filtersize;

/* yes no */
/*NEW*/
/* %let _CV_onoff_search_gradclips=yes; */
/* yes no */
%let _CV_gradclips_value=&_insert_gradclip;
%let _CV_lb_gradclips_value=&_insert_gradc_lb_;
%let _CV_ub_gradclips_value=&_insert_gradc_ub_;

/* %let _CV_onoff_search_gamma=yes;				 */
%let _CV_gam_value_=&_insert_gamma;
%let _CV_lb_gamma_value_=&_insert_gam_lb;
%let _CV_ub_gamma_value_=&_insert_gam_ub;

/* %let _CV_onoff_search_stepsize=yes; 				 */
%let _CV_stepSize_value_=&_insert_stepsize;
%let _CV_lb_stepSize_value_=&_insert_steps_lb;
%let _CV_ub_stepSize_value_=&_insert_steps_ub;

/* %let _CV_onoff_search_miniBSize=yes; 				 */
%let _CV_miniBSize_value_=&_insert_minibatchsize;
%let _CV_lb_miniBSize_value_=&_insert_minibatch_lb;
%let _CV_ub_miniBSize_value_=&_insert_minibatch_ub;

/* %let _CV_onoff_search_lr=yes; 				 */
%let _CV_lr_value_=&_insert_learnr;
%let _CV_lb_lr_value_=&_insert_lr_lb;
%let _CV_ub_lr_value_=&_insert_lr_ub;

/* %let _CV_onoff_search_betadiff=yes; 				 */
%let _CV_betadiff_value_=&_insert_betdiff;
%let _CV_lb_betadiff_value_=&_insert_betadiff_lb;
%let _CV_ub_betadiff_value_=&_insert_betadiff_ub;

/* %let _CV_onoff_search_l1reg=yes; 				 */
%let _CV_l1reg_value_=&_insert_l1reg;
%let _CV_lb_l1reg_value_=&_insert_l1r_lb;
%let _CV_ub_l1reg_value_=&_insert_l1r_ub;

/* %let _CV_onoff_search_l2reg=yes; 				 */
%let _CV_l2reg_value_=&_insert_l2reg;
%let _CV_lb_l2reg_value_=&_insert_l2r_lb;
%let _CV_ub_l2reg_value_=&_insert_l2r_ub;

/* %let _CV_onoff_search_actfunc=yes; 				*/
%let _CV_act_function=&_insert_actfunc_1;

/* multi-task macro variables */
%let _CV_multitlayercount=%SYSEVALF(&inserttargetcount-1);
%let _CV_multitoutput_0=&_insert_trg_0;
%let _CV_multitoutput_1=&_insert_trg_1;
%let _CV_multitoutput_2=&_insert_trg_2;
%let _CV_multitoutput_3=&_insert_trg_3;
%let _CV_multitoutput_4=&_insert_trg_4;
%let _CV_multitoutput_5=&_insert_trg_5;
%let _CV_multitoutput_6=&_insert_trg_6;
%let _CV_multitoutput_7=&_insert_trg_7;
%let _CV_multitoutput_8=&_insert_trg_8;
%let _CV_multitoutput_9=&_insert_trg_9;
%let _CV_multitoutput_10=&_insert_trg_10;
%let _CV_multitoutput_11=&_insert_trg_11;
%let _CV_multitoutput_12=&_insert_trg_12;
%let _CV_multitoutput_13=&_insert_trg_13;
%let _CV_multitoutput_14=&_insert_trg_14;
%let _CV_multitoutput_15=&_insert_trg_15;
%let _CV_multitoutput_16=&_insert_trg_16;
%let _CV_multitoutput_17=&_insert_trg_17;
%let _CV_multitoutput_18=&_insert_trg_18;
%let _CV_multitoutput_19=&_insert_trg_19;
%let _CV_multitoutput_20=&_insert_trg_20;

/* use to indicate target variable is nominal */
%let _CV_multitoutputtype_0=&_insert_trgtype_0;
%let _CV_multitoutputtype_1=&_insert_trgtype_1;
%let _CV_multitoutputtype_2=&_insert_trgtype_2;
%let _CV_multitoutputtype_3=&_insert_trgtype_3;
%let _CV_multitoutputtype_4=&_insert_trgtype_4;
%let _CV_multitoutputtype_5=&_insert_trgtype_5;
%let _CV_multitoutputtype_6=&_insert_trgtype_6;
%let _CV_multitoutputtype_7=&_insert_trgtype_7;
%let _CV_multitoutputtype_8=&_insert_trgtype_8;
%let _CV_multitoutputtype_9=&_insert_trgtype_9;
%let _CV_multitoutputtype_10=&_insert_trgtype_10;
%let _CV_multitoutputtype_11=&_insert_trgtype_11;
%let _CV_multitoutputtype_12=&_insert_trgtype_12;
%let _CV_multitoutputtype_13=&_insert_trgtype_13;
%let _CV_multitoutputtype_14=&_insert_trgtype_14;
%let _CV_multitoutputtype_15=&_insert_trgtype_15;
%let _CV_multitoutputtype_16=&_insert_trgtype_16;
%let _CV_multitoutputtype_17=&_insert_trgtype_17;
%let _CV_multitoutputtype_18=&_insert_trgtype_18;
%let _CV_multitoutputtype_19=&_insert_trgtype_19;
%let _CV_multitoutputtype_20=&_insert_trgtype_20;
%let multaskevals=%SYSEVALF(3+&_CV_multitlayercount);
%let _CV_search_slt0=&_insert_yesno_scalar_0;
%let _CV_search_slt1=&_insert_yesno_scalar_1;
%let _CV_search_slt2=&_insert_yesno_scalar_2;
%let _CV_search_slt3=&_insert_yesno_scalar_3;
%let _CV_search_slt4=&_insert_yesno_scalar_4;
%let _CV_search_slt5=&_insert_yesno_scalar_5;
%let _CV_search_slt6=&_insert_yesno_scalar_6;
%let _CV_search_slt7=&_insert_yesno_scalar_7;
%let _CV_search_slt8=&_insert_yesno_scalar_8;
%let _CV_search_slt9=&_insert_yesno_scalar_9;
%let _CV_search_slt_10=&_insert_yesno_scalar_10;
%let _CV_search_slt_11=&_insert_yesno_scalar_11;
%let _CV_search_slt_12=&_insert_yesno_scalar_12;
%let _CV_search_slt_13=&_insert_yesno_scalar_13;
%let _CV_search_slt_14=&_insert_yesno_scalar_14;
%let _CV_search_slt_15=&_insert_yesno_scalar_15;
%let _CV_search_slt_16=&_insert_yesno_scalar_16;
%let _CV_search_slt_17=&_insert_yesno_scalar_17;
%let _CV_search_slt_18=&_insert_yesno_scalar_18;
%let _CV_search_slt_19=&_insert_yesno_scalar_19;
%let _CV_search_slt_20=&_insert_yesno_scalar_20;

/* %let _CV_dropValue=yes;							 */
%let _CV_dropout_block1=%SYSEVALF(&_insert_drop_l1*20);

/* value from zero to one */
%let _CV_dropout_block2=%SYSEVALF(&_insert_drop_l2*20);

/* value from zero to one */
%let _CV_dropout_block3=%SYSEVALF(&_insert_drop_l3*20);

/* value from zero to one */
%let _CV_dropout_block4=%SYSEVALF(&_insert_drop_l4*20);

/* value from zero to one */
%let _CV_dropout_block5=%SYSEVALF(&_insert_drop_l5*20);

/* value from zero to one */
%let _CV_dropout_block6=%SYSEVALF(&_insert_drop_l6*20);

/* value from zero to one */
%let _CV_dropout_block7=%SYSEVALF(&_insert_drop_l7*20);

/* value from zero to one */
%let _CV_dropout_block8=%SYSEVALF(&_insert_drop_l8*20);

/* value from zero to one */
%let _CV_dropout_block9=%SYSEVALF(&_insert_drop_l9*20);

/* value from zero to one */
%let _CV_dropout_block10=%SYSEVALF(&_insert_dropl10*20);

/* value from zero to one */
%let _CV_dropout_block11=%SYSEVALF(&_insert_dropl11*20);

/* value from zero to one */
%let _CV_dropout_block12=%SYSEVALF(&_insert_dropl12*20);

/* value from zero to one */
%let _CV_dropout_block13=%SYSEVALF(&_insert_dropl13*20);

/* value from zero to one */
%let _CV_dropout_block14=%SYSEVALF(&_insert_dropl14*20);

/* value from zero to one */
%let _CV_dropout_block15=%SYSEVALF(&_insert_dropl15*20);

/* value from zero to one */
%let _CV_dropout_block16=%SYSEVALF(&_insert_dropl16*20);

/* value from zero to one */
%macro _useprevioussearch_;
	%if &_CV_continue_previous_search=yes %then %do;

		proc sort data=casuser.loaded__search_results_
			out=work.loaded__search_results_;
			by objVal;
		run;

		data casuser._firstgen_table;
			set work.loaded__search_results_ (obs=&_CV_howmanytouseforfirstgen);
			where objVal ne .;
		run;

		data work.Cachein_NASv1;
			set work.loaded__search_results_;
			where objVal ne .;

			if _n_>&_CV_howmanytouseforfirstgen;
		run;

		data work.Cachein_NASv2;
			set work.loaded__search_results_;
			where objVal=.;
		run;

		data casuser._Cachein_table;
			set work.Cachein_NASv2 work.Cachein_NASv1;
		run;

	%end;
%mend _useprevioussearch_;

/***************************/
/* Object detection macros */
/***************************/
%global _CVdm_odfixformatsv2c _CVdm_odfixformatsv3 _CVdm_odfixformatsv2
_CVdm_odfixformatsv1;
%let _CVdm_odfixformatsv1=data casuser.new_cas_table_maxLengths%nrstr(;




);
%let _CVdm_odfixformatsv2=$AddLengthStatement;
%let _CVdm_odfixformatsv3=set casuser.imgdata_w_id%nrstr(;




)run%nrstr(;




);
%let _CVdm_odfixformatsv2c=;

/* %put &_CV_object_num_; */
%macro _FindAnchorBoxes_ (minclusters=, size=);
	%global _CV_object_num_;
	%global anchor_box_coord;
	%global _CV_OD_preds_per_grid;
	%let _CV_object_num_=0;
	%let _CV_OD_preds_per_grid=0;
	%let anchor_box_coord=0;

	%if &_CV_modeltask_=objectdetection %then %do;

		data work._findmax_objs_;
			set CASUSER._determine_num_clusters_;
		run;

		proc sql noprint;
			select max(_nObjects_) into: _CV_object_num_
			from work._findmax_objs_;
		quit;

		data CASUSER._My_temp_data_;
			set CASUSER._determine_num_clusters_;

			%do objnum_i=0 %to &_CV_object_num_;
				height=_object&objnum_i._height;
				width=_object&objnum_i._width;
				output;
			%end;
		run;

		data CASUSER.keepImportantVars;
			set CASUSER._My_temp_data_;
			where height ne .;
			keep height width;
		run;

		ods output WithinClusStats=Clusstats;

		proc kclus data=CASUSER.keepImportantVars
			maxclusters=&_CV_maxnumclusters MAXITER=1000 seed=1234
			NOC=ABC(B=100 minclusters=&minclusters align=none
			criterion=&_CV_OD_cluster_criterion) STANDARDIZE=none DISTANCE=EUCLIDEAN
			STOPCRITERION=CLUSTER_CHANGE INIT=FORGY;
			input height width;
			ods output ABCStats=ABCStats1;
		run;

		proc sort data=Clusstats;
			by Cluster decending Variable;
		run;

		title "Bounding Box Anchors";

		proc sql;
			select Mean*&size
			into : anchor_box_coord separated by ', '
			from Clusstats;
		run;

		quit;
		title;
		title "Number of Bounding Box Anchors";

		proc sql;
			select count(Mean)/2
			into : _CV_OD_preds_per_grid separated by ', '
			from Clusstats;
		run;

		title;

		proc cas;
			table.dropTable / caslib="CASUSER", name="keepImportantVars";
			table.dropTable / caslib="CASUSER", name="_My_temp_data_";
			table.dropTable / caslib="CASUSER", name="_determine_num_clusters_";
		quit;

	%end;
%mend _FindAnchorBoxes_;

proc cas;
	table.addCasLib result=suppress / name="libres", 
		path="&_CV_location_for_results_data" subdirectories=true activeOnAdd=FALSE;
	table.save / Caslib="libres"
	table={name="&insert_intabl__name", caslib="&insert_intabl__lib"} 
		name="&_imageDS_..sashdat"
		permission="PUBLICWRITE"
		replace=True;
	table.dropCaslib result=suppress / caslib="libres" quiet=TRUE;
run;

_verify_previous_search="&_CV_continue_previous_search";

/* yes no */
if _verify_previous_search="yes" then do;
table.addCasLib / name="libres", path="&_CV_location_for_results_data"
subdirectories=true;
table.loadTable /caslib="libres", path="&_CV_name_autotuneresults_load..sashdat"
casOut={name="loaded__search_results_", caslib="casuser", replace=true};
table.dropCaslib result=suppress / caslib="libres" quiet=TRUE;
end;
_verify_modeling_task_="&_CV_modeltask_";

/* classification, regression or objectdetection */
if _verify_modeling_task_="objectdetection" then do;
table.copyTable / table={name="&insert_intabl__name", 
	caslib="&insert_intabl__lib"}, casOut={name="_determine_num_clusters_", 
	caslib="CASUSER", replace=True};
table.alterTable / caslib="CASUSER", name="_determine_num_clusters_", 
	drop={"_image_"};
end;
quit;

/**********************************************************/
/* Add macro to add weight var to classification outcomes */
/**********************************************************/
%macro applytrgweight();
	%global _weghtcodtrain_;
	%let _weghtcodtrain_=;

	%if &_onoff_cntrldcrule_=1 %then %do;
		%let _weghtcodtrain_=weight="central_decision_rule";
	%end;
%mend applytrgweight;

%applytrgweight;

%macro sbbcodeclassreg();
	%global _dcodeclassreg;
	%let _dcodeclassreg=;

	%if &_CV_modeltask_=classification or &_CV_modeltask_=regression %then %do;
		%if &_insert_globalautotune=yes and &_checkbox_addfc=1 %then %do; 
		%let _dcodeclassreg={name='_decision_FCneuronnum', type='I', 
			lb=_setup_lb_FCneuronnum, ub=_setup_ub_FCneuronnum, 
			init=_setup_init_FCneuronnum} {name='_decision_FCactfunc', type='I', 
			lb=_setup_lb_FCactfunc, ub=_setup_ub_FCactfunc, init=_setup_init_FCactfunc};
		%end;
		%else %do;
				%let _dcodeclassreg={name='_decision_FCneuronnum', type='I', 
			lb=_setup_init_FCneuronnum, ub=_setup_init_FCneuronnum, 
			init=_setup_init_FCneuronnum} {name='_decision_FCactfunc', type='I', 
			lb=_setup_init_FCactfunc, ub=_setup_init_FCactfunc, init=_setup_init_FCactfunc};
		%end;
	%end;
%mend sbbcodeclassreg;

/****************************************************************/
/*		multi-task macros										*/
/****************************************************************/
/* no autotune version of the code */
%macro NOcreatemultitasklayer();
	%global _CVdm_dltraincodemultitaskres _CVdm_dltraincodemultitasktin
	_CVdm_dltraincodemultitaskshuf _CVdm_decidenominal;
	%let _CVdm_dltraincodemultitaskres=;
	%let _CVdm_dltraincodemultitasktin=;
	%let _CVdm_dltraincodemultitaskshuf=;

	%if &_CV_modeltask_=multitask %then %do;
		%let _CVdm_dltraincodemultitaskres={data="_image_", layer="data", 
			type='IMAGE'};
		%let _CVdm_dltraincodemultitasktin={data="_image_", layer="input1", 
			type='IMAGE'};
		%let _CVdm_dltraincodemultitaskshuf={data="_image_", layer="data", 
			type='IMAGE'};
		%let _CVdm_decidenominal=;

		%do layercount=0 %to &_CV_multitlayercount;

			%if &&_CV_multitoutputtype_&layercount=1 %then %do;
				%let _CVdm_decidenominal=nominals="&&_CV_multitoutput_&layercount", ;
			%end;

			%if &&_CV_multitoutputtype_&layercount ne 1 %then %do;
				%let _CVdm_decidenominal=;
			%end;
			%put &&_CV_multitoutputtype_&layercount;
			;
			%let
			_CVdm_tempdltraincode_&layercount={data="&&_CV_multitoutput_&layercount", 
				layer="mtlayer_&layercount", 
				lossScaleFactor=&&_CV_search_init_slt&layercount., &_CVdm_decidenominal
				type='numericnominal'};
			%let _CVdm_dltraincodemultitaskres=&_CVdm_dltraincodemultitaskres %nrstr(, 
				 
				  
				 ) &&_CVdm_tempdltraincode_&layercount;
			%let _CVdm_dltraincodemultitasktin=&_CVdm_dltraincodemultitasktin %nrstr(, 
				 
				  
				 ) &&_CVdm_tempdltraincode_&layercount;
			%let _CVdm_dltraincodemultitaskshuf=&_CVdm_dltraincodemultitaskshuf %nrstr(, 
				 
				 
				 
				 
				) &&_CVdm_tempdltraincode_&layercount;
		%end;
	%end;

	%if &_CV_modeltask_ ne multitask %then %do;
		%let _CVdm_dltraincodemultitaskres=;
		%let _CVdm_dltraincodemultitasktin=;
		%let _CVdm_dltraincodemultitaskshuf=;
	%end;
%mend NOcreatemultitasklayer;

/* no autotune version of the code */
%macro A_createmultitasklayer;
	%global _CVdm_dltraincodemultitaskres _CVdm_dltraincodemultitasktin
	_CVdm_dltraincodemultitaskshuf _CVdm_decidenominal;
	%let _CVdm_dltraincodemultitaskres=;
	%let _CVdm_dltraincodemultitasktin=;
	%let _CVdm_dltraincodemultitaskshuf=;

	%if &_CV_modeltask_=multitask %then %do;
		%let _CVdm_dltraincodemultitaskres={data="_image_", layer="data", 
			type='IMAGE'};
		%let _CVdm_dltraincodemultitasktin={data="_image_", layer="input1", 
			type='IMAGE'};
		%let _CVdm_dltraincodemultitaskshuf={data="_image_", layer="data", 
			type='IMAGE'};
		%let _CVdm_decidenominal=;

		%do layercount=0 %to &_CV_multitlayercount;

			%if &&_CV_multitoutputtype_&layercount=1 %then %do;
				%let _CVdm_decidenominal=nominals="&&_CV_multitoutput_&layercount", ;
			%end;

			%if &&_CV_multitoutputtype_&layercount ne 1 %then %do;
				%let _CVdm_decidenominal=;
			%end;
			%put &&_CV_multitoutputtype_&layercount;
			;
			%let
			_CVdm_tempdltraincode_&layercount={data="&&_CV_multitoutput_&layercount", 
				layer="mtlayer_&layercount", lossScaleFactor=_decision_slt&layercount., 
				&_CVdm_decidenominal
				type='numericnominal'};
			%let _CVdm_dltraincodemultitaskres=&_CVdm_dltraincodemultitaskres %nrstr(, 
				 
				  
				 ) &&_CVdm_tempdltraincode_&layercount;
			%let _CVdm_dltraincodemultitasktin=&_CVdm_dltraincodemultitasktin %nrstr(, 
				 
				  
				 ) &&_CVdm_tempdltraincode_&layercount;
			%let _CVdm_dltraincodemultitaskshuf=&_CVdm_dltraincodemultitaskshuf %nrstr(, 
				 
				 
				 
				 
				) &&_CVdm_tempdltraincode_&layercount;
		%end;
	%end;

	%if &_CV_modeltask_ ne multitask %then %do;
		%let _CVdm_dltraincodemultitaskres=;
		%let _CVdm_dltraincodemultitasktin=;
		%let _CVdm_dltraincodemultitaskshuf=;
	%end;
%mend A_createmultitasklayer;

%macro A_createaddlayermultitask;
	%global _CVdm_addlayercodemultitask;
	%let _CVdm_addlayercodemultitask=;

	/* %let _CVdm_decidenominal=; */
	%if &_CV_modeltask_=multitask %then %do;

		%do layercount=0 %to &_CV_multitlayercount;
			%let _CVdm_tempaddlayercode_&layercount=if
			_verify_modelbackbone_="resnet50_caffe" then do %nrstr(;
			
			
			
			
			) _verify_FC_include_="&_CV_include_FC_layer" %nrstr(;
			
			
			
			
			) /* include projection layer for multi-task? */
			if _verify_FC_include_="yes" then do %nrstr(;
			
			
			
			
			) /* Add a projection layer with Batch Normalization */
			deepLearn.AddLayer result=suppress / model='resnet50_caffe' name="projlayer&layercount"
			layer={type='CONVO' nFilters=_decision_projfilternum&layercount width=1
			height=1 stride=1 act='identity' dropout=&_tm_projdropoutrate} 
				srcLayers={'pool5'} %nrstr(;
			
			
			
			
			) /* add new output layer */
			deepLearn.AddLayer result=suppress / model="resnet50_caffe" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"projlayer&layercount"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) if _verify_FC_include_ ne "yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model="resnet50_caffe"
			name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"pool5"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) /*end ResNet model setup for multitask*/
			if _verify_modelbackbone_="Tiny-Yolov2" then do %nrstr(;
			
			
			
			
			) _verify_FC_include_="&_CV_include_FC_layer" %nrstr(;
			
			
			
			
			) /* include projection layer for class and reg task? */
			if _verify_FC_include_="yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
			layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'}%nrstr(;
			
			
			
			
			) deepLearn.AddLayer / model='Tiny-Yolov2' name='poolavg' layer={type='POOL' width=0
			height=0 stride=1 pool='AVERAGE'} srcLayers={'b_n_9'} %nrstr(;
			
			
			
			
			) /* Add a projection layer with Batch Normalization */
			deepLearn.AddLayer result=suppress / model='Tiny-Yolov2' name="projlayer&layercount"
			layer={type='CONVO' nFilters=_decision_projfilternum&layercount width=1
			height=1 stride=1 act='identity' dropout=&_tm_projdropoutrate} 
				srcLayers={'poolavg'} %nrstr(;
			
			
			
			
			) /* add new output layer */
			deepLearn.AddLayer result=suppress / model="Tiny-Yolov2" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"projlayer&layercount"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) if _verify_FC_include_ ne "yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
			layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'}%nrstr(;
			
			
			
			
			) deepLearn.AddLayer / model='Tiny-Yolov2' name='poolavg' layer={type='POOL' width=0
			height=0 stride=1 pool='AVERAGE'} srcLayers={'b_n_9'} %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model="Tiny-Yolov2"
			name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"poolavg"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) /*end Tiny-Yolov2 model setup for multitask*/
			if _verify_modelbackbone_="ShuffleNetV2" or
			_verify_modelbackbone_="ShuffleNetV2_x15" or
			_verify_modelbackbone_="ShuffleNetV2_x20" or
			_verify_modelbackbone_="ShuffleNetV2_x25" then do%nrstr(;
			
			
			
			
			) _verify_FC_include_="&_CV_include_FC_layer" %nrstr(;
			
			
			
			
			) /* include projection layer for class and reg task? */
			if _verify_FC_include_="yes" then do %nrstr(;
			
			
			
			
			) /* Add a projection layer with Batch Normalization */
			deepLearn.AddLayer result=suppress / model='ShuffleNetV2' name="projlayer&layercount"
			layer={type='CONVO' nFilters=_decision_projfilternum&layercount width=1
			height=1 stride=1 act='identity' dropout=&_tm_projdropoutrate} 
				srcLayers={'global_avg_pool'} %nrstr(;
			
			
			
			
			) /* add new output layer */
			deepLearn.AddLayer result=suppress / model="ShuffleNetV2" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"projlayer&layercount"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) if _verify_FC_include_ ne "yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model="ShuffleNetV2"
			name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"global_avg_pool"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) /*end ShuffleNetV2 model setup for multitask*/
			if _verify_modelbackbone_="Xception" then do %nrstr(;
			
			
			
			
			) _verify_FC_include_="&_CV_include_FC_layer" %nrstr(;
			
			
			
			
			) /* include projection layer for multi-task? */
			if _verify_FC_include_="yes" then do %nrstr(;
			
			
			
			
			) /* Add a projection layer with Batch Normalization */
			deepLearn.AddLayer result=suppress / model='Xception' name="projlayer&layercount"
			layer={type='CONVO' nFilters=_decision_projfilternum&layercount width=1
			height=1 stride=1 act='identity' dropout=&_tm_projdropoutrate} 
				srcLayers={'final_avepool'} %nrstr(;
			
			
			
			
			) /* add new output layer */
			deepLearn.AddLayer result=suppress / model="Xception" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"projlayer&layercount"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) if _verify_FC_include_ ne "yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model="Xception" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"final_avepool"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) /*end Xception model setup for multitask*/;

			%if &layercount=0 %then %do;
				%let _CVdm_addlayercodemultitask=&_CVdm_addlayercodemultitask &&_CVdm_tempaddlayercode_&layercount;
			%end;

			%if &layercount ne 0 %then %do;
				%let _CVdm_addlayercodemultitask=&_CVdm_addlayercodemultitask %nrstr(;
				
				
				
				
				) &&_CVdm_tempaddlayercode_&layercount;
			%end;
		%end;
	%end;

	%if &_CV_modeltask_ ne multitask %then %do;
		%let _CVdm_addlayercodemultitask=;
	%end;
%mend A_createaddlayermultitask;

%macro NOcreateaddlayermultitask;
	%global _CVdm_addlayercodemultitask;
	%let _CVdm_addlayercodemultitask=;

	/* %let _CVdm_decidenominal=; */
	%if &_CV_modeltask_=multitask %then %do;

		%do layercount=0 %to &_CV_multitlayercount;
			%let _CVdm_tempaddlayercode_&layercount=if
			_verify_modelbackbone_="resnet50_caffe" then do%nrstr(;
			
			
			
			
			) _verify_FC_include_="&_CV_include_FC_layer" %nrstr(;
			
			
			
			
			) /* include projection layer for multi-task?   */
			if _verify_FC_include_="yes" then do %nrstr(;
			
			
			
			
			) /* Add a projection layer with Batch Normalization */
			AddLayer result=suppress / model='resnet50_caffe' name="projlayer&layercount"
			layer={type='CONVO'
			nFilters=&&_CV_search_init_projfilternum&layercount width=1 height=1
			stride=1 act='identity' dropout=&_tm_projdropoutrate} 
				srcLayers={'pool5'} %nrstr(;
			
			
			
			
			) /* add new output layer */
			AddLayer result=suppress / model="resnet50_caffe" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"projlayer&layercount"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) if _verify_FC_include_ ne "yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model="resnet50_caffe"
			name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"pool5"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) /*end ResNet model setup for multitask*/
			if _verify_modelbackbone_="Tiny-Yolov2" then do%nrstr(;
			
			
			
			
			) _verify_FC_include_="&_CV_include_FC_layer" %nrstr(;
			
			
			
			
			) /* include projection layer for class and reg task?   */
			if _verify_FC_include_="yes" then do %nrstr(;
			
			
			
			
			) /* Add a projection layer with Batch Normalization */
			AddLayer result=suppress / model='Tiny-Yolov2' name="projlayer&layercount"
			layer={type='CONVO'
			nFilters=&&_CV_search_init_projfilternum&layercount width=1 height=1
			stride=1 act='identity' dropout=&_tm_projdropoutrate} 
				srcLayers={'convo.9'} %nrstr(;
			
			
			
			
			) /* add new output layer */
			AddLayer result=suppress / model="Tiny-Yolov2" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"projlayer&layercount"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) if _verify_FC_include_ ne "yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model="Tiny-Yolov2"
			name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"convo.9"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) /*end Tiny-Yolov2 model setup for multitask*/
			if _verify_modelbackbone_="ShuffleNetV2" or
			_verify_modelbackbone_="ShuffleNetV2_x15" or
			_verify_modelbackbone_="ShuffleNetV2_x20" or
			_verify_modelbackbone_="ShuffleNetV2_x25" then do%nrstr(;
			
			
			
			
			) _verify_FC_include_="&_CV_include_FC_layer" %nrstr(;
			
			
			
			
			) /* include projection layer for class and reg task?   */
			if _verify_FC_include_="yes" then do %nrstr(;
			
			
			
			
			) /* Add a projection layer with Batch Normalization */
			AddLayer result=suppress / model='ShuffleNetV2' name="projlayer&layercount"
			layer={type='CONVO'
			nFilters=&&_CV_search_init_projfilternum&layercount width=1 height=1
			stride=1 act='identity' dropout=&_tm_projdropoutrate} 
				srcLayers={'global_avg_pool'} %nrstr(;
			
			
			
			
			) /* add new output layer */
			AddLayer result=suppress / model="ShuffleNetV2" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"projlayer&layercount"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) if _verify_FC_include_ ne "yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model="ShuffleNetV2"
			name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"global_avg_pool"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) /*end ShuffleNetV2 model setup for multitask*/
			if _verify_modelbackbone_="Xception" then do%nrstr(;
			
			
			
			
			) _verify_FC_include_="&_CV_include_FC_layer" %nrstr(;
			
			
			
			
			) /* include projection layer for multi-task?   */
			if _verify_FC_include_="yes" then do %nrstr(;
			
			
			
			
			) /* Add a projection layer with Batch Normalization */
			AddLayer result=suppress / model='Xception' name="projlayer&layercount"
			layer={type='CONVO'
			nFilters=&&_CV_search_init_projfilternum&layercount width=1 height=1
			stride=1 act='identity' dropout=&_tm_projdropoutrate} 
				srcLayers={'final_avepool'} %nrstr(;
			
			
			
			
			) /* add new output layer */
			AddLayer result=suppress / model="Xception" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"projlayer&layercount"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) if _verify_FC_include_ ne "yes" then do %nrstr(;
			
			
			
			
			) deepLearn.AddLayer result=suppress / model="Xception" name="mtlayer_&layercount"
			layer={type='output'} srcLayers={"final_avepool"} %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) end %nrstr(;
			
			
			
			
			) /*end Xception model setup for multitask*/;

			%if &layercount=0 %then %do;
				%let _CVdm_addlayercodemultitask=&_CVdm_addlayercodemultitask &&_CVdm_tempaddlayercode_&layercount;
			%end;

			%if &layercount ne 0 %then %do;
				%let _CVdm_addlayercodemultitask=&_CVdm_addlayercodemultitask %nrstr(;
				
				
				
				
				) &&_CVdm_tempaddlayercode_&layercount;
			%end;
		%end;
	%end;

	%if &_CV_modeltask_ ne multitask %then %do;
		%let _CVdm_addlayercodemultitask=;
	%end;
%mend NOcreateaddlayermultitask;

%macro retaindecsionvars;
	%global _retainmultitaskdec_;
	%let _retainmultitaskdec_=;

	%if &_CV_modeltask_=multitask %then %do;

		%do layercount=0 %to &_CV_multitlayercount;
			%let _CVdm_tempretain_&layercount=_decision_slt&layercount
			_decision_projfilternum&layercount;
			%let
			_retainmultitaskdec_=&_retainmultitaskdec_ &&_CVdm_tempretain_&layercount;
		%end;
	%end;
%mend retaindecsionvars;

%macro labelsdecsionvars;
	%global _labelsmultitaskdec_;
	%let _labelsmultitaskdec_=;

	%if &_CV_modeltask_=multitask %then %do;

		%do layercount=0 %to &_CV_multitlayercount;
			%let tempslt=%str(Scaler Loss for Target &layercount);
			%let tempprojfil=%str(Number of Projection Filters for Target &layercount);
			%let
			_CVdm_templabels_&layercount=_decision_slt&layercount=%bquote('&tempslt') 
				_decision_projfilternum&layercount=%bquote('&tempprojfil');
			%let
			_labelsmultitaskdec_=&_labelsmultitaskdec_ &&_CVdm_templabels_&layercount;
		%end;
	%end;
%mend labelsdecsionvars;

%macro crtTrgVarList4Multitask;
	%global _CVdm_TrgVarList;
	%let _CVdm_TrgVarList=;

	%if &_CV_modeltask_=multitask %then %do;
		%let _CV_tarVar_commaname_=;

		%do layercount=0 %to &_CV_multitlayercount;
			%let _CVdm_tempTrgVarList_&layercount="&&_CV_multitoutput_&layercount";

			%if &layercount=0 %then %do;
				%let
				_CVdm_TrgVarList=&_CVdm_TrgVarList &&_CVdm_tempTrgVarList_&layercount %nrstr(, 
					 
					 
					 
					 
					);
			%end;

			%if &layercount ne 0 %then %do;
				%let
				_CVdm_TrgVarList=&_CVdm_TrgVarList  &&_CVdm_tempTrgVarList_&layercount %nrstr(, 
					 
					 
					 
					 
					);
			%end;
		%end;
	%end;
%mend crtTrgVarList4Multitask;

%macro sbbcodemultitask;
	%global _dcodemultitask;
	%let _dcodemultitask=;

	%if &_CV_modeltask_=multitask %then %do;
		%let _dcodemultitask=;

		%do layercount=0 %to &_CV_multitlayercount;
			%let _tempcodemultitask&layercount={name="_decision_slt&layercount", 
				type='C', lb=_setup_lb_slt&layercount, ub=_setup_ub_slt&layercount, 
				init=_setup_init_slt&layercount} 
				{name="_decision_projfilternum&layercount", type='I', 
				lb=_setup_lb_projfilternum&layercount, 
				ub=_setup_ub_projfilternum&layercount, 
				init=_setup_init_projfilternum&layercount};
			%let _dcodemultitask=&_dcodemultitask &&_tempcodemultitask&layercount;
		%end;
	%end;
%mend sbbcodemultitask;

%macro updatemultiTaskS;
	%global _CVsclaremacroupdate;
	%let _CVsclaremacroupdate=;

	%if &_CV_modeltask_=multitask %then %do;
		%let _CVsclaremacroupdate=;

		%do layercount=0 %to &_CV_multitlayercount;
			%let _tempfiltmacroupd&layercount=;
			%let _tempsclaremacroupd&layercount=call symput("_CV_search_slt&layercount", 
				_decision_slt&layercount)%nrstr(;
			
			
			
			
			);

			%if &_CV_onoff_search_FCactfunc=yes %then %do;
				%let _tempfiltmacroupd&layercount=call
				symput("_CV_search_init_projfilternum&layercount", 
					_decision_projfilternum&layercount)%nrstr(;
				
				
				
				
				);
			%end;
			%let _CVsclaremacroupdate=&_CVsclaremacroupdate &&_tempsclaremacroupd&layercount &&_tempfiltmacroupd&layercount;
		%end;
	%end;
%mend updatemultiTaskS;

%_useprevioussearch_;
%_FindAnchorBoxes_ (minclusters=2, size=&_image_input_height_);
%put here are the maximum nubmer of objects: &_CV_object_num_;

/*multi-task code setup: */
%A_createaddlayermultitask;
%A_createmultitasklayer;
%sbbcodemultitask;
%crtTrgVarList4Multitask;

/* done with multi-task code setup */
%sbbcodeclassreg;

proc cas;
	_verify_autotune_init="&_CV_Global_autotune_initiate";

	if _verify_autotune_init="yes" then do;
		_verify_saveautotuneresults=&_CV_saveautotune_results;

		if _verify_saveautotuneresults=1 then do;
			ods html
			file="&_CV_location_for_results_data/&_CV_autotuneresults_name..html";
		end;

		/* search gamma */
		_verify_search_gamma="&_CV_onoff_search_gamma";

		if _verify_search_gamma="yes" then do;
			_setup_init_gamma=&_CV_gam_value_;
			_setup_lb_gamma=&_CV_lb_gamma_value_;
			_setup_ub_gamma=&_CV_ub_gamma_value_;
		end;

		if _verify_search_gamma ne "yes" then do;
			_setup_init_gamma=&_CV_gam_value_;
			_setup_lb_gamma=&_CV_gam_value_;
			_setup_ub_gamma=&_CV_gam_value_;
		end;

		/* search stepsize */
		_verify_search_stepsize="&_CV_onoff_search_stepsize";

		if _verify_search_stepsize="yes" then do;
			_setup_init_stepsize=&_CV_stepSize_value_;
			_setup_lb_stepsize=&_CV_lb_stepSize_value_;
			_setup_ub_stepsize=&_CV_ub_stepSize_value_;
		end;

		if _verify_search_stepsize ne "yes" then do;
			_setup_init_stepsize=&_CV_stepSize_value_;
			_setup_lb_stepsize=&_CV_stepSize_value_;
			_setup_ub_stepsize=&_CV_stepSize_value_;
		end;

		/* search minibatch size */
		_verify_search_miniBSize="&_CV_onoff_search_miniBSize";

		if _verify_search_miniBSize="yes" then do;
			_setup_init_miniBSize=&_CV_miniBSize_value_;
			_setup_lb_miniBSize=&_CV_lb_miniBSize_value_;
			_setup_ub_miniBSize=&_CV_ub_miniBSize_value_;
		end;

		if _verify_search_miniBSize ne "yes" then do;
			_setup_init_miniBSize=&_CV_miniBSize_value_;
			_setup_lb_miniBSize=&_CV_miniBSize_value_;
			_setup_ub_miniBSize=&_CV_miniBSize_value_;
		end;

		/* search learning rate */
		_verify_search_lr="&_CV_onoff_search_lr";

		if _verify_search_lr="yes" then do;
			_setup_init_lr=&_CV_lr_value_;
			_setup_lb_lr=&_CV_lb_lr_value_;
			_setup_ub_lr=&_CV_ub_lr_value_;
		end;

		if _verify_search_lr ne "yes" then do;
			_setup_init_lr=&_CV_lr_value_;
			_setup_lb_lr=&_CV_lr_value_;
			_setup_ub_lr=&_CV_lr_value_;
		end;

		/* search second order learning rate */
		_verify_search_betadiff="&_CV_onoff_search_betadiff";

		if _verify_search_betadiff="yes" then do;
			_setup_init_betadiff=&_CV_betadiff_value_;
			_setup_lb_betadiff=&_CV_lb_betadiff_value_;
			_setup_ub_betadiff=&_CV_ub_betadiff_value_;
		end;

		if _verify_search_betadiff ne "yes" then do;
			_setup_init_betadiff=&_CV_betadiff_value_;
			_setup_lb_betadiff=&_CV_betadiff_value_;
			_setup_ub_betadiff=&_CV_betadiff_value_;
		end;

		/* search l1 reg */
		_verify_search_l1reg="&_CV_onoff_search_l1reg";

		if _verify_search_l1reg="yes" then do;
			_setup_init_l1reg=&_CV_l1reg_value_;
			_setup_lb_l1reg=&_CV_lb_l1reg_value_;
			_setup_ub_l1reg=&_CV_ub_l1reg_value_;
		end;

		if _verify_search_l1reg ne "yes" then do;
			_setup_init_l1reg=&_CV_l1reg_value_;
			_setup_lb_l1reg=&_CV_l1reg_value_;
			_setup_ub_l1reg=&_CV_l1reg_value_;
		end;

		/* search l2 reg */
		_verify_search_l2reg="&_CV_onoff_search_l2reg";

		if _verify_search_l2reg="yes" then do;
			_setup_init_l2reg=&_CV_l2reg_value_;
			_setup_lb_l2reg=&_CV_lb_l2reg_value_;
			_setup_ub_l2reg=&_CV_ub_l2reg_value_;
		end;

		if _verify_search_l2reg ne "yes" then do;
			_setup_init_l2reg=&_CV_l2reg_value_;
			_setup_lb_l2reg=&_CV_l2reg_value_;
			_setup_ub_l2reg=&_CV_l2reg_value_;
		end;

		/* search cilpgrads */
		_verify_gradclips="&_CV_onoff_search_gradclips";

		if _verify_gradclips="yes" then do;
			_setup_init_gradclips=&_CV_gradclips_value;
			_setup_lb_gradclips=&_CV_lb_gradclips_value;
			_setup_ub_gradclips=&_CV_ub_gradclips_value;
		end;

		if _verify_gradclips ne "yes" then do;
			_setup_init_gradclips=&_CV_gradclips_value;
			_setup_lb_gradclips=&_CV_gradclips_value;
			_setup_ub_gradclips=&_CV_gradclips_value;
		end;

		/* search first convo filter sizes */
		_verify_firstconvo_fsize="&_CV_onoff_search_firstc_fsize";

		if _verify_firstconvo_fsize=1 then do;
			_setup_init_fconvo_size=&_CV_assigned_firstc_fsize;
			_setup_lb_fconvo_size=1;
			_setup_ub_fconvo_size=7;
		end;
		_verify_firstconvo_fsize="&_CV_onoff_search_firstc_fsize";

		if _verify_firstconvo_fsize=0 then do;
			_setup_init_fconvo_size=&_CV_assigned_firstc_fsize;
			_setup_lb_fconvo_size=&_CV_assigned_firstc_fsize;
			_setup_ub_fconvo_size=&_CV_assigned_firstc_fsize;
		end;

		/****************************/
		/*model activation function */
		/* 	ELU = 10 				*/
		/*	RELU = 8 				*/
		/*	Leaky = 12 				*/
		/*	Softplus = 9 			*/
		/*	Hyperbolic Tangent = 6	*/
		/****************************/
		_verify_search_actfunc="&_CV_onoff_search_actfunc";

		if _verify_search_actfunc="yes" then do;
			_setup_init_actfunc=&_CV_act_function;
			_setup_lb_actfunc=8;
			_setup_ub_actfunc=12;
		end;

		if _verify_search_actfunc ne "yes" then do;
			_setup_init_actfunc=&_CV_act_function;
			_setup_lb_actfunc=&_CV_act_function;
			_setup_ub_actfunc=&_CV_act_function;
		end;
		_verify_modeling_task_="&_CV_modeltask_";

		/* classification, regression or objectdetection */
		if _verify_modeling_task_="objectdetection" then do;

			/*last convo filter width*/
			_verify_search_lc_width="&_CV_onoff_search_lc_width";

			if _verify_search_lc_width="yes" then do;
				_setup_init_lc_width=&_CV_OD_lastConvo_width;
				_setup_lb_lc_width=&_CV_lb_OD_lconvo_width_value_;
				_setup_ub_lc_width=&_CV_ub_OD_lconvo_width_value_;
			end;

			if _verify_search_lc_width ne "yes" then do;
				_setup_init_lc_width=&_CV_OD_lastConvo_width;
				_setup_lb_lc_width=&_CV_OD_lastConvo_width;
				_setup_ub_lc_width=&_CV_OD_lastConvo_width;
			end;

			/*last convo filter height*/
			_verify_search_lc_height="&_CV_onoff_search_lc_height";

			if _verify_search_lc_height="yes" then do;
				_setup_init_lc_height=&_CV_OD_lastConvo_height;
				_setup_lb_lc_height=&_CV_lb_OD_lconvo_height_value_;
				_setup_ub_lc_height=&_CV_ub_OD_lconvo_height_value_;
			end;

			if _verify_search_lc_height ne "yes" then do;
				_setup_init_lc_height=&_CV_OD_lastConvo_height;
				_setup_lb_lc_height=&_CV_OD_lastConvo_height;
				_setup_ub_lc_height=&_CV_OD_lastConvo_height;
			end;

			/*object scale*/
			_verify_search_obj="&_CV_onoff_search_obj";

			if _verify_search_obj="yes" then do;
				_setup_init_obj=&_CV_OD_Obj_scale_;
				_setup_lb_obj=&_CV_lb_OD_Obj_value_;
				_setup_ub_obj=&_CV_ub_OD_Obj_value_;
			end;

			if _verify_search_obj ne "yes" then do;
				_setup_init_obj=&_CV_OD_Obj_scale_;
				_setup_lb_obj=&_CV_OD_Obj_scale_;
				_setup_ub_obj=&_CV_OD_Obj_scale_;
			end;

			/*no object scale*/
			_verify_search_noobj="&_CV_onoff_search_noobj";

			if _verify_search_noobj="yes" then do;
				_setup_init_noobj=&_CV_OD_Not_Obj_scale_;
				_setup_lb_noobj=&_CV_lb_Not_Obj_value_;
				_setup_ub_noobj=&_CV_ub_Not_Obj_value_;
			end;

			if _verify_search_noobj ne "yes" then do;
				_setup_init_noobj=&_CV_OD_Not_Obj_scale_;
				_setup_lb_noobj=&_CV_OD_Not_Obj_scale_;
				_setup_ub_noobj=&_CV_OD_Not_Obj_scale_;
			end;

			/*coordinate scale*/
			_verify_search_coord="&_CV_onoff_search_coord";

			if _verify_search_coord="yes" then do;
				_setup_init_coord=&_CV_OD_coord_scale_;
				_setup_lb_coord=&_CV_lb_coord_value_;
				_setup_ub_coord=&_CV_ub_coord_value_;
			end;

			if _verify_search_coord ne "yes" then do;
				_setup_init_coord=&_CV_OD_coord_scale_;
				_setup_lb_coord=&_CV_OD_coord_scale_;
				_setup_ub_coord=&_CV_OD_coord_scale_;
			end;

			/*class scale*/
			_verify_search_class="&_CV_onoff_search_class";

			if _verify_search_class="yes" then do;
				_setup_init_class=&_CV_OD_class_scale_;
				_setup_lb_class=&_CV_lb_class_value_;
				_setup_ub_class=&_CV_ub_class_value_;
			end;

			if _verify_search_class ne "yes" then do;
				_setup_init_class=&_CV_OD_class_scale_;
				_setup_lb_class=&_CV_OD_class_scale_;
				_setup_ub_class=&_CV_OD_class_scale_;
			end;

			/*detection threshold*/
			_verify_search_detthresh="&_CV_onoff_search_detthresh";

			if _verify_search_detthresh="yes" then do;
				_setup_init_detthresh=&_CV_OD_detection_thresh_;
				_setup_lb_detthresh=&_CV_lb_detection_thresh_value_;
				_setup_ub_detthresh=&_CV_ub_detection_thresh_value_;
			end;

			if _verify_search_detthresh ne "yes" then do;
				_setup_init_detthresh=&_CV_OD_detection_thresh_;
				_setup_lb_detthresh=&_CV_OD_detection_thresh_;
				_setup_ub_detthresh=&_CV_OD_detection_thresh_;
			end;

			/*iou threshold*/
			_verify_search_iouhresh="&_CV_onoff_search_iouthresh";

			if _verify_search_iouhresh="yes" then do;
				_setup_init_iouthresh=&_CV_OD_iouthreshold_;
				_setup_lb_iouthresh=&_CV_lb_iouthreshold_value_;
				_setup_ub_iouthresh=&_CV_ub_iouthreshold_value_;
			end;

			if _verify_search_iouhresh ne "yes" then do;
				_setup_init_iouthresh=&_CV_OD_iouthreshold_;
				_setup_lb_iouthresh=&_CV_OD_iouthreshold_;
				_setup_ub_iouthresh=&_CV_OD_iouthreshold_;
			end;

			/*train iou threshold*/
			_verify_search_trainiou="&_CV_onoff_search_trainiou";

			if _verify_search_trainiou="yes" then do;
				_setup_init_trainiou=&_CV_iouTrainThreshold_;
				_setup_lb_trainiou=&_CV_lb_iouTrainThreshold_value_;
				_setup_ub_trainiou=&_CV_ub_iouTrainThreshold_value_;
			end;

			if _verify_search_trainiou ne "yes" then do;
				_setup_init_trainiou=&_CV_iouTrainThreshold_;
				_setup_lb_trainiou=&_CV_iouTrainThreshold_;
				_setup_ub_trainiou=&_CV_iouTrainThreshold_;
			end;
		end;

		/* end object detection search variable setup */
		_verify_modeling_task_="&_CV_modeltask_";

		/* classification, regression or objectdetection */
		if _verify_modeling_task_="classification" or
		_verify_modeling_task_="regression" then do;
			_setup_init_FCneuronnum=&_CV_FC_neuron_num;
			_setup_lb_FCneuronnum=&_CV_FC_neuron_num;
			_setup_ub_FCneuronnum=&_CV_FC_neuron_num;
			_setup_init_FCactfunc=&_CV_FC_act_function;
			_setup_lb_FCactfunc=&_CV_FC_act_function;
			_setup_ub_FCactfunc=&_CV_FC_act_function;
			_verify_search_FCinclude="&_CV_include_FC_layer";

			if _verify_search_FCinclude="yes" then do;

				/*FC neuron count*/
				_verify_search_FCneuronnum="&_CV_onoff_search_FCneuronnum";

				if _verify_search_FCneuronnum="yes" then do;
					_setup_init_FCneuronnum=&_CV_FC_neuron_num;
					_setup_lb_FCneuronnum=&_CV_lb_FC_neuron_value_;
					_setup_ub_FCneuronnum=&_CV_ub_FC_neuron_value_;
				end;

				if _verify_search_FCneuronnum ne "yes" then do;
					_setup_init_FCneuronnum=&_CV_FC_neuron_num;
					_setup_lb_FCneuronnum=&_CV_FC_neuron_num;
					_setup_ub_FCneuronnum=&_CV_FC_neuron_num;
				end;
				_verify_search_FCactfunc="&_CV_onoff_search_FCactfunc";

				if _verify_search_FCactfunc="yes" then do;
					_setup_init_FCactfunc=&_CV_FC_act_function;
					_setup_lb_FCactfunc=8;
					_setup_ub_FCactfunc=12;
				end;

				if _verify_search_FCactfunc ne "yes" then do;
					_setup_init_FCactfunc=&_CV_FC_act_function;
					_setup_lb_FCactfunc=&_CV_FC_act_function;
					_setup_ub_FCactfunc=&_CV_FC_act_function;
				end;
			end;

			/* end FC attributes */
		end;

		/* end of classification and regression */
		/* slt0 */
		verify_search_slt0=&_CV_search_slt0;

		if verify_search_slt0=1 then do;
			_setup_init_slt0=&_CV_search_init_slt0;
			_setup_lb_slt0=&_CV_search_lb_slt0;
			_setup_ub_slt0=&_CV_search_ub_slt0;
		end;

		if verify_search_slt0=0 then do;
			_setup_init_slt0=&_CV_search_init_slt0;
			_setup_lb_slt0=&_CV_search_init_slt0;
			_setup_ub_slt0=&_CV_search_init_slt0;
		end;

		/* slt1 */
		verify_search_slt1=&_CV_search_slt1;

		if verify_search_slt1=1 then do;
			_setup_init_slt1=&_CV_search_init_slt1;
			_setup_lb_slt1=&_CV_search_lb_slt1;
			_setup_ub_slt1=&_CV_search_ub_slt1;
		end;

		if verify_search_slt1=0 then do;
			_setup_init_slt1=&_CV_search_init_slt1;
			_setup_lb_slt1=&_CV_search_init_slt1;
			_setup_ub_slt1=&_CV_search_init_slt1;
		end;

		/* slt2 */
		verify_search_slt2=&_CV_search_slt2;

		if verify_search_slt2=1 then do;
			_setup_init_slt2=&_CV_search_init_slt2;
			_setup_lb_slt2=&_CV_search_lb_slt2;
			_setup_ub_slt2=&_CV_search_ub_slt2;
		end;

		if verify_search_slt2=0 then do;
			_setup_init_slt2=&_CV_search_init_slt2;
			_setup_lb_slt2=&_CV_search_init_slt2;
			_setup_ub_slt2=&_CV_search_init_slt2;
		end;

		/* slt3 */
		verify_search_slt3=&_CV_search_slt3;

		if verify_search_slt3=1 then do;
			_setup_init_slt3=&_CV_search_init_slt3;
			_setup_lb_slt3=&_CV_search_lb_slt3;
			_setup_ub_slt3=&_CV_search_ub_slt3;
		end;

		if verify_search_slt3=0 then do;
			_setup_init_slt3=&_CV_search_init_slt3;
			_setup_lb_slt3=&_CV_search_init_slt3;
			_setup_ub_slt3=&_CV_search_init_slt3;
		end;

		/* slt4 */
		verify_search_slt4=&_CV_search_slt4;

		if verify_search_slt4=1 then do;
			_setup_init_slt4=&_CV_search_init_slt4;
			_setup_lb_slt4=&_CV_search_lb_slt4;
			_setup_ub_slt4=&_CV_search_ub_slt4;
		end;

		if verify_search_slt4=0 then do;
			_setup_init_slt4=&_CV_search_init_slt4;
			_setup_lb_slt4=&_CV_search_init_slt4;
			_setup_ub_slt4=&_CV_search_init_slt4;
		end;

		/* slt5 */
		verify_search_slt5=&_CV_search_slt5;

		if verify_search_slt5=1 then do;
			_setup_init_slt5=&_CV_search_init_slt5;
			_setup_lb_slt5=&_CV_search_lb_slt5;
			_setup_ub_slt5=&_CV_search_ub_slt5;
		end;

		if verify_search_slt5=0 then do;
			_setup_init_slt5=&_CV_search_init_slt5;
			_setup_lb_slt5=&_CV_search_init_slt5;
			_setup_ub_slt5=&_CV_search_init_slt5;
		end;

		/* slt6 */
		verify_search_slt6=&_CV_search_slt6;

		if verify_search_slt6=1 then do;
			_setup_init_slt6=&_CV_search_init_slt6;
			_setup_lb_slt6=&_CV_search_lb_slt6;
			_setup_ub_slt6=&_CV_search_ub_slt6;
		end;

		if verify_search_slt6=0 then do;
			_setup_init_slt6=&_CV_search_init_slt6;
			_setup_lb_slt6=&_CV_search_init_slt6;
			_setup_ub_slt6=&_CV_search_init_slt6;
		end;

		/* slt7 */
		verify_search_slt7=&_CV_search_slt7;

		if verify_search_slt7=1 then do;
			_setup_init_slt7=&_CV_search_init_slt7;
			_setup_lb_slt7=&_CV_search_lb_slt7;
			_setup_ub_slt7=&_CV_search_ub_slt7;
		end;

		if verify_search_slt7=0 then do;
			_setup_init_slt7=&_CV_search_init_slt7;
			_setup_lb_slt7=&_CV_search_init_slt7;
			_setup_ub_slt7=&_CV_search_init_slt7;
		end;

		/* slt8 */
		verify_search_slt8=&_CV_search_slt8;

		if verify_search_slt8=1 then do;
			_setup_init_slt8=&_CV_search_init_slt8;
			_setup_lb_slt8=&_CV_search_lb_slt8;
			_setup_ub_slt8=&_CV_search_ub_slt8;
		end;

		if verify_search_slt8=0 then do;
			_setup_init_slt8=&_CV_search_init_slt8;
			_setup_lb_slt8=&_CV_search_init_slt8;
			_setup_ub_slt8=&_CV_search_init_slt8;
		end;

		/* slt9 */
		verify_search_slt9=&_CV_search_slt9;

		if verify_search_slt9=1 then do;
			_setup_init_slt9=&_CV_search_init_slt9;
			_setup_lb_slt9=&_CV_search_lb_slt9;
			_setup_ub_slt9=&_CV_search_ub_slt9;
		end;

		if verify_search_slt9=0 then do;
			_setup_init_slt9=&_CV_search_init_slt9;
			_setup_lb_slt9=&_CV_search_init_slt9;
			_setup_ub_slt9=&_CV_search_init_slt9;
		end;

		/* slt_10 */
		verify_search_slt_10=&_CV_search_slt_10;

		if verify_search_slt_10=1 then do;
			_setup_init_slt10=&_CV_search_init_slt10;
			_setup_lb_slt10=&_CV_search_lb_slt10;
			_setup_ub_slt10=&_CV_search_ub_slt10;
		end;

		if verify_search_slt_10=0 then do;
			_setup_init_slt10=&_CV_search_init_slt10;
			_setup_lb_slt10=&_CV_search_init_slt10;
			_setup_ub_slt10=&_CV_search_init_slt10;
		end;

		/* slt_11 */
		verify_search_slt_11=&_CV_search_slt_11;

		if verify_search_slt_11=1 then do;
			_setup_init_slt11=&_CV_search_init_slt11;
			_setup_lb_slt11=&_CV_search_lb_slt11;
			_setup_ub_slt11=&_CV_search_ub_slt11;
		end;

		if verify_search_slt_11=0 then do;
			_setup_init_slt11=&_CV_search_init_slt11;
			_setup_lb_slt11=&_CV_search_init_slt11;
			_setup_ub_slt11=&_CV_search_init_slt11;
		end;

		/* slt_12 */
		verify_search_slt_12=&_CV_search_slt_12;

		if verify_search_slt_12=1 then do;
			_setup_init_slt12=&_CV_search_init_slt12;
			_setup_lb_slt12=&_CV_search_lb_slt12;
			_setup_ub_slt12=&_CV_search_ub_slt12;
		end;

		if verify_search_slt_12=0 then do;
			_setup_init_slt12=&_CV_search_init_slt12;
			_setup_lb_slt12=&_CV_search_init_slt12;
			_setup_ub_slt12=&_CV_search_init_slt12;
		end;

		/* slt_13 */
		verify_search_slt_13=&_CV_search_slt_13;

		if verify_search_slt_13=1 then do;
			_setup_init_slt13=&_CV_search_init_slt13;
			_setup_lb_slt13=&_CV_search_lb_slt13;
			_setup_ub_slt13=&_CV_search_ub_slt13;
		end;

		if verify_search_slt_13=0 then do;
			_setup_init_slt13=&_CV_search_init_slt13;
			_setup_lb_slt13=&_CV_search_init_slt13;
			_setup_ub_slt13=&_CV_search_init_slt13;
		end;

		/* slt_14 */
		verify_search_slt_14=&_CV_search_slt_14;

		if verify_search_slt_14=1 then do;
			_setup_init_slt14=&_CV_search_init_slt14;
			_setup_lb_slt14=&_CV_search_lb_slt14;
			_setup_ub_slt14=&_CV_search_ub_slt14;
		end;

		if verify_search_slt_14=0 then do;
			_setup_init_slt14=&_CV_search_init_slt14;
			_setup_lb_slt14=&_CV_search_initslt14;
			_setup_ub_slt14=&_CV_search_initslt14;
		end;

		/* slt_15 */
		verify_search_slt_15=&_CV_search_slt_15;

		if verify_search_slt_15=1 then do;
			_setup_init_slt15=&_CV_search_init_slt15;
			_setup_lb_slt15=&_CV_search_lb_slt15;
			_setup_ub_slt15=&_CV_search_ub_slt15;
		end;

		if verify_search_slt_15=0 then do;
			_setup_init_slt15=&_CV_search_init_slt15;
			_setup_lb_slt15=&_CV_search_init_slt15;
			_setup_ub_slt15=&_CV_search_init_slt15;
		end;

		/* slt_16 */
		verify_search_slt_16=&_CV_search_slt_16;

		if verify_search_slt_16=1 then do;
			_setup_init_slt16=&_CV_search_init_slt16;
			_setup_lb_slt16=&_CV_search_lb_slt16;
			_setup_ub_slt16=&_CV_search_ub_slt16;
		end;

		if verify_search_slt_16=0 then do;
			_setup_init_slt16=&_CV_search_init_slt16;
			_setup_lb_slt16=&_CV_search_init_slt16;
			_setup_ub_slt16=&_CV_search_init_slt16;
		end;

		/* slt_17 */
		verify_search_slt_17=&_CV_search_slt_17;

		if verify_search_slt_17=1 then do;
			_setup_init_slt17=&_CV_search_init_slt17;
			_setup_lb_slt17=&_CV_search_lb_slt17;
			_setup_ub_slt17=&_CV_search_ub_slt17;
		end;

		if verify_search_slt_17=0 then do;
			_setup_init_slt17=&_CV_search_init_slt17;
			_setup_lb_slt17=&_CV_search_init_slt17;
			_setup_ub_slt17=&_CV_search_init_slt17;
		end;

		/* slt_18 */
		verify_search_slt_18=&_CV_search_slt_18;

		if verify_search_slt_18=1 then do;
			_setup_init_slt18=&_CV_search_init_slt18;
			_setup_lb_slt18=&_CV_search_lb_slt18;
			_setup_ub_slt18=&_CV_search_ub_slt18;
		end;

		if verify_search_slt_18=0 then do;
			_setup_init_slt18=&_CV_search_init_slt18;
			_setup_lb_slt18=&_CV_search_init_slt18;
			_setup_ub_slt18=&_CV_search_init_slt18;
		end;

		/* slt_19 */
		verify_search_slt_19=&_CV_search_slt_19;

		if verify_search_slt_19=1 then do;
			_setup_init_slt19=&_CV_search_init_slt19;
			_setup_lb_slt19=&_CV_search_lb_slt19;
			_setup_ub_slt19=&_CV_search_ub_slt19;
		end;

		if verify_search_slt_19=0 then do;
			_setup_init_slt19=&_CV_search_init_slt19;
			_setup_lb_slt19=&_CV_search_init_slt19;
			_setup_ub_slt19=&_CV_search_init_slt19;
		end;

		/* slt_20 */
		verify_search_slt_20=&_CV_search_slt_20;

		if verify_search_slt_20=1 then do;
			_setup_init_slt20=&_CV_search_init_slt20;
			_setup_lb_slt20=&_CV_search_lb_slt20;
			_setup_ub_slt20=&_CV_search_ub_slt20;
		end;

		if verify_search_slt_20=0 then do;
			_setup_init_slt20=&_CV_search_init_slt20;
			_setup_lb_slt20=&_CV_search_init_slt20;
			_setup_ub_slt20=&_CV_search_init_slt20;
		end;

		/* projfilternum0 */
		verify_search_projfilternum0=&_CV_search_projfilternum0;

		if verify_search_projfilternum0=1 then do;
			_setup_init_projfilternum0=&_CV_search_init_projfilternum0;
			_setup_lb_projfilternum0=&_CV_search_lb_projfilternum0;
			_setup_ub_projfilternum0=&_CV_search_ub_projfilternum0;
		end;

		if verify_search_projfilternum0=0 then do;
			_setup_init_projfilternum0=&_CV_search_init_projfilternum0;
			_setup_lb_projfilternum0=&_CV_search_init_projfilternum0;
			_setup_ub_projfilternum0=&_CV_search_init_projfilternum0;
		end;

		/* projfilternum1 */
		verify_search_projfilternum1=&_CV_search_projfilternum1;

		if verify_search_projfilternum1=1 then do;
			_setup_init_projfilternum1=&_CV_search_init_projfilternum1;
			_setup_lb_projfilternum1=&_CV_search_lb_projfilternum1;
			_setup_ub_projfilternum1=&_CV_search_ub_projfilternum1;
		end;

		if verify_search_projfilternum1=0 then do;
			_setup_init_projfilternum1=&_CV_search_init_projfilternum1;
			_setup_lb_projfilternum1=&_CV_search_init_projfilternum1;
			_setup_ub_projfilternum1=&_CV_search_init_projfilternum1;
		end;

		/* projfilternum2 */
		verify_search_projfilternum2=&_CV_search_projfilternum2;

		if verify_search_projfilternum2=1 then do;
			_setup_init_projfilternum2=&_CV_search_init_projfilternum2;
			_setup_lb_projfilternum2=&_CV_search_lb_projfilternum2;
			_setup_ub_projfilternum2=&_CV_search_ub_projfilternum2;
		end;

		if verify_search_projfilternum2=0 then do;
			_setup_init_projfilternum2=&_CV_search_init_projfilternum2;
			_setup_lb_projfilternum2=&_CV_search_init_projfilternum2;
			_setup_ub_projfilternum2=&_CV_search_init_projfilternum2;
		end;

		/* projfilternum3 */
		verify_search_projfilternum3=&_CV_search_projfilternum3;

		if verify_search_projfilternum3=1 then do;
			_setup_init_projfilternum3=&_CV_search_init_projfilternum3;
			_setup_lb_projfilternum3=&_CV_search_lb_projfilternum3;
			_setup_ub_projfilternum3=&_CV_search_ub_projfilternum3;
		end;

		if verify_search_projfilternum3=0 then do;
			_setup_init_projfilternum3=&_CV_search_init_projfilternum3;
			_setup_lb_projfilternum3=&_CV_search_init_projfilternum3;
			_setup_ub_projfilternum3=&_CV_search_init_projfilternum3;
		end;

		/* projfilternum4 */
		verify_search_projfilternum4=&_CV_search_projfilternum4;

		if verify_search_projfilternum4=1 then do;
			_setup_init_projfilternum4=&_CV_search_init_projfilternum4;
			_setup_lb_projfilternum4=&_CV_search_lb_projfilternum4;
			_setup_ub_projfilternum4=&_CV_search_ub_projfilternum4;
		end;

		if verify_search_projfilternum4=0 then do;
			_setup_init_projfilternum4=&_CV_search_init_projfilternum4;
			_setup_lb_projfilternum4=&_CV_search_init_projfilternum4;
			_setup_ub_projfilternum4=&_CV_search_init_projfilternum4;
		end;

		/* projfilternum5 */
		verify_search_projfilternum5=&_CV_search_projfilternum5;

		if verify_search_projfilternum5=1 then do;
			_setup_init_projfilternum5=&_CV_search_init_projfilternum5;
			_setup_lb_projfilternum5=&_CV_search_lb_projfilternum5;
			_setup_ub_projfilternum5=&_CV_search_ub_projfilternum5;
		end;

		if verify_search_projfilternum5=0 then do;
			_setup_init_projfilternum5=&_CV_search_init_projfilternum5;
			_setup_lb_projfilternum5=&_CV_search_init_projfilternum5;
			_setup_ub_projfilternum5=&_CV_search_init_projfilternum5;
		end;

		/* projfilternum6 */
		verify_search_projfilternum6=&_CV_search_projfilternum6;

		if verify_search_projfilternum6=1 then do;
			_setup_init_projfilternum6=&_CV_search_init_projfilternum6;
			_setup_lb_projfilternum6=&_CV_search_lb_projfilternum6;
			_setup_ub_projfilternum6=&_CV_search_ub_projfilternum6;
		end;

		if verify_search_projfilternum6=0 then do;
			_setup_init_projfilternum6=&_CV_search_init_projfilternum6;
			_setup_lb_projfilternum6=&_CV_search_init_projfilternum6;
			_setup_ub_projfilternum6=&_CV_search_init_projfilternum6;
		end;

		/* projfilternum7 */
		verify_search_projfilternum7=&_CV_search_projfilternum7;

		if verify_search_projfilternum7=1 then do;
			_setup_init_projfilternum7=&_CV_search_init_projfilternum7;
			_setup_lb_projfilternum7=&_CV_search_lb_projfilternum7;
			_setup_ub_projfilternum7=&_CV_search_ub_projfilternum7;
		end;

		if verify_search_projfilternum7=0 then do;
			_setup_init_projfilternum7=&_CV_search_init_projfilternum7;
			_setup_lb_projfilternum7=&_CV_search_init_projfilternum7;
			_setup_ub_projfilternum7=&_CV_search_init_projfilternum7;
		end;

		/* projfilternum8 */
		verify_search_projfilternum8=&_CV_search_projfilternum8;

		if verify_search_projfilternum8=1 then do;
			_setup_init_projfilternum8=&_CV_search_init_projfilternum8;
			_setup_lb_projfilternum8=&_CV_search_lb_projfilternum8;
			_setup_ub_projfilternum8=&_CV_search_ub_projfilternum8;
		end;

		if verify_search_projfilternum8=0 then do;
			_setup_init_projfilternum8=&_CV_search_init_projfilternum8;
			_setup_lb_projfilternum8=&_CV_search_init_projfilternum8;
			_setup_ub_projfilternum8=&_CV_search_init_projfilternum8;
		end;

		/* projfilternum9 */
		verify_search_projfilternum9=&_CV_search_projfilternum9;

		if verify_search_projfilternum9=1 then do;
			_setup_init_projfilternum9=&_CV_search_init_projfilternum9;
			_setup_lb_projfilternum9=&_CV_search_lb_projfilternum9;
			_setup_ub_projfilternum9=&_CV_search_ub_projfilternum9;
		end;

		if verify_search_projfilternum9=0 then do;
			_setup_init_projfilternum9=&_CV_search_init_projfilternum9;
			_setup_lb_projfilternum9=&_CV_search_init_projfilternum9;
			_setup_ub_projfilternum9=&_CV_search_init_projfilternum9;
		end;

		/* projfilternum_10 */
		verify_search_projfilternum_10=&_CV_search_projfilternum10;

		if verify_search_projfilternum_10=1 then do;
			_setup_init_projfilternum10=&_CV_search_init_projfilternum10;
			_setup_lb_projfilternum10=&_CV_search_lb_projfilternum10;
			_setup_ub_projfilternum10=&_CV_search_ub_projfilternum10;
		end;

		if verify_search_projfilternum_10=0 then do;
			_setup_init_projfilternum10=&_CV_search_init_projfilternum10;
			_setup_lb_projfilternum10=&_CV_search_init_projfilternum10;
			_setup_ub_projfilternum10=&_CV_search_init_projfilternum10;
		end;

		/* projfilternum_11 */
		verify_search_projfilternum_11=&_CV_search_projfilternum11;

		if verify_search_projfilternum_11=1 then do;
			_setup_init_projfilternum11=&_CV_search_init_projfilternum11;
			_setup_lb_projfilternum11=&_CV_search_lb_projfilternum11;
			_setup_ub_projfilternum11=&_CV_search_ub_projfilternum11;
		end;

		if verify_search_projfilternum_11=0 then do;
			_setup_init_projfilternum11=&_CV_search_init_projfilternum11;
			_setup_lb_projfilternum11=&_CV_search_init_projfilternum11;
			_setup_ub_projfilternum11=&_CV_search_init_projfilternum11;
		end;

		/* projfilternum_12 */
		verify_search_projfilternum_12=&_CV_search_projfilternum12;

		if verify_search_projfilternum_12=1 then do;
			_setup_init_projfilternum12=&_CV_search_init_projfilternum12;
			_setup_lb_projfilternum12=&_CV_search_lb_projfilternum12;
			_setup_ub_projfilternum12=&_CV_search_ub_projfilternum12;
		end;

		if verify_search_projfilternum_12=0 then do;
			_setup_init_projfilternum12=&_CV_search_init_projfilternum12;
			_setup_lb_projfilternum12=&_CV_search_init_projfilternum12;
			_setup_ub_projfilternum12=&_CV_search_init_projfilternum12;
		end;

		/* projfilternum_13 */
		verify_search_projfilternum_13=&_CV_search_projfilternum13;

		if verify_search_projfilternum_13=1 then do;
			_setup_init_projfilternum13=&_CV_search_init_projfilternum13;
			_setup_lb_projfilternum13=&_CV_search_lb_projfilternum13;
			_setup_ub_projfilternum13=&_CV_search_ub_projfilternum13;
		end;

		if verify_search_projfilternum_13=0 then do;
			_setup_init_projfilternum13=&_CV_search_init_projfilternum13;
			_setup_lb_projfilternum13=&_CV_search_init_projfilternum13;
			_setup_ub_projfilternum13=&_CV_search_init_projfilternum13;
		end;

		/* projfilternum_14 */
		verify_search_projfilternum_14=&_CV_search_projfilternum14;

		if verify_search_projfilternum_14=1 then do;
			_setup_init_projfilternum14=&_CV_search_init_projfilternum14;
			_setup_lb_projfilternum14=&_CV_search_lb_projfilternum14;
			_setup_ub_projfilternum14=&_CV_search_ub_projfilternum14;
		end;

		if verify_search_projfilternum_14=0 then do;
			_setup_init_projfilternum14=&_CV_search_init_projfilternum14;
			_setup_lb_projfilternum14=&_CV_search_init_projfilternum14;
			_setup_ub_projfilternum14=&_CV_search_init_projfilternum14;
		end;

		/* projfilternum_15 */
		verify_search_projfilternum_15=&_CV_search_projfilternum15;

		if verify_search_projfilternum_15=1 then do;
			_setup_init_projfilternum15=&_CV_search_init_projfilternum15;
			_setup_lb_projfilternum15=&_CV_search_lb_projfilternum15;
			_setup_ub_projfilternum15=&_CV_search_ub_projfilternum15;
		end;

		if verify_search_projfilternum_15=0 then do;
			_setup_init_projfilternum15=&_CV_search_init_projfilternum15;
			_setup_lb_projfilternum15=&_CV_search_init_projfilternum15;
			_setup_ub_projfilternum15=&_CV_search_init_projfilternum15;
		end;

		/* projfilternum_16 */
		verify_search_projfilternum_16=&_CV_search_projfilternum16;

		if verify_search_projfilternum_16=1 then do;
			_setup_init_projfilternum16=&_CV_search_init_projfilternum16;
			_setup_lb_projfilternum16=&_CV_search_lb_projfilternum16;
			_setup_ub_projfilternum16=&_CV_search_ub_projfilternum16;
		end;

		if verify_search_projfilternum_16=0 then do;
			_setup_init_projfilternum16=&_CV_search_init_projfilternum16;
			_setup_lb_projfilternum16=&_CV_search_init_projfilternum16;
			_setup_ub_projfilternum16=&_CV_search_init_projfilternum16;
		end;

		/* projfilternum_17 */
		verify_search_projfilternum_17=&_CV_search_projfilternum17;

		if verify_search_projfilternum_17=1 then do;
			_setup_init_projfilternum17=&_CV_search_init_projfilternum17;
			_setup_lb_projfilternum17=&_CV_search_lb_projfilternum17;
			_setup_ub_projfilternum17=&_CV_search_ub_projfilternum17;
		end;

		if verify_search_projfilternum_17=0 then do;
			_setup_init_projfilternum17=&_CV_search_init_projfilternum17;
			_setup_lb_projfilternum17=&_CV_search_init_projfilternum17;
			_setup_ub_projfilternum17=&_CV_search_init_projfilternum17;
		end;

		/* projfilternum_18 */
		verify_search_projfilternum_18=&_CV_search_projfilternum18;

		if verify_search_projfilternum_18=1 then do;
			_setup_init_projfilternum18=&_CV_search_init_projfilternum18;
			_setup_lb_projfilternum18=&_CV_search_lb_projfilternum18;
			_setup_ub_projfilternum18=&_CV_search_ub_projfilternum18;
		end;

		if verify_search_projfilternum_18=0 then do;
			_setup_init_projfilternum18=&_CV_search_init_projfilternum18;
			_setup_lb_projfilternum18=&_CV_search_init_projfilternum18;
			_setup_ub_projfilternum18=&_CV_search_init_projfilternum18;
		end;

		/* projfilternum_19 */
		verify_search_projfilternum_19=&_CV_search_projfilternum19;

		if verify_search_projfilternum_19=1 then do;
			_setup_init_projfilternum19=&_CV_search_init_projfilternum19;
			_setup_lb_projfilternum19=&_CV_search_lb_projfilternum19;
			_setup_ub_projfilternum19=&_CV_search_ub_projfilternum19;
		end;

		if verify_search_projfilternum_19=0 then do;
			_setup_init_projfilternum19=&_CV_search_init_projfilternum19;
			_setup_lb_projfilternum19=&_CV_search_init_projfilternum19;
			_setup_ub_projfilternum19=&_CV_search_init_projfilternum19;
		end;

		/* projfilternum_20 */
		verify_search_projfilternum_20=&_CV_search_projfilternum20;

		if verify_search_projfilternum_20=1 then do;
			_setup_init_projfilternum20=&_CV_search_init_projfilternum20;
			_setup_lb_projfilternum20=&_CV_search_lb_projfilternum20;
			_setup_ub_projfilternum20=&_CV_search_ub_projfilternum20;
		end;

		if verify_search_projfilternum_20=0 then do;
			_setup_init_projfilternum20=&_CV_search_init_projfilternum20;
			_setup_lb_projfilternum20=&_CV_search_init_projfilternum20;
			_setup_ub_projfilternum20=&_CV_search_init_projfilternum20;
		end;

		/* 	end; */
		verify_search_dropout="&_CV_dropValue";

		if verify_search_dropout="yes" then do;

			/* Block 1 */
			_setup_init_Dropoutblock_1=&_CV_dropout_block1;
			_setup_lb_Dropoutblock_1=-10;
			_setup_ub_Dropoutblock_1=19;

			/* Block 2 */
			_setup_init_Dropoutblock_2=&_CV_dropout_block2;
			_setup_lb_Dropoutblock_2=-10;
			_setup_ub_Dropoutblock_2=19;

			/* Block 3 */
			_setup_init_Dropoutblock_3=&_CV_dropout_block3;
			_setup_lb_Dropoutblock_3=-10;
			_setup_ub_Dropoutblock_3=19;

			/* Block 4 */
			_setup_init_Dropoutblock_4=&_CV_dropout_block4;
			_setup_lb_Dropoutblock_4=-10;
			_setup_ub_Dropoutblock_4=19;

			/* Block 5 */
			_setup_init_Dropoutblock_5=&_CV_dropout_block5;
			_setup_lb_Dropoutblock_5=-10;
			_setup_ub_Dropoutblock_5=19;

			/* Block 6 */
			_setup_init_Dropoutblock_6=&_CV_dropout_block6;
			_setup_lb_Dropoutblock_6=-10;
			_setup_ub_Dropoutblock_6=19;

			/* Block 7 */
			_setup_init_Dropoutblock_7=&_CV_dropout_block7;
			_setup_lb_Dropoutblock_7=-10;
			_setup_ub_Dropoutblock_7=19;

			/* Block 8 */
			_setup_init_Dropoutblock_8=&_CV_dropout_block8;
			_setup_lb_Dropoutblock_8=-10;
			_setup_ub_Dropoutblock_8=19;

			/* Block 9 */
			_setup_init_Dropoutblock_9=&_CV_dropout_block9;
			_setup_lb_Dropoutblock_9=-10;
			_setup_ub_Dropoutblock_9=19;

			/* Block 10 */
			_setup_init_Dropoutblock_10=&_CV_dropout_block10;
			_setup_lb_Dropoutblock_10=-10;
			_setup_ub_Dropoutblock_10=19;

			/* Block 11 */
			_setup_init_Dropoutblock_11=&_CV_dropout_block11;
			_setup_lb_Dropoutblock_11=-10;
			_setup_ub_Dropoutblock_11=19;

			/* Block 12 */
			_setup_init_Dropoutblock_12=&_CV_dropout_block12;
			_setup_lb_Dropoutblock_12=-10;
			_setup_ub_Dropoutblock_12=19;

			/* Block 13 */
			_setup_init_Dropoutblock_13=&_CV_dropout_block13;
			_setup_lb_Dropoutblock_13=-10;
			_setup_ub_Dropoutblock_13=19;

			/* Block 14 */
			_setup_init_Dropoutblock_14=&_CV_dropout_block14;
			_setup_lb_Dropoutblock_14=-10;
			_setup_ub_Dropoutblock_14=19;

			/* Block 15 */
			_setup_init_Dropoutblock_15=&_CV_dropout_block15;
			_setup_lb_Dropoutblock_15=-10;
			_setup_ub_Dropoutblock_15=19;
			_verify_modelbackbone_="&_CV_modelBackbone_";

			if _verify_modelbackbone_="resnet50_caffe" or
			_verify_modelbackbone_="autotune" or
			_verify_modelbackbone_="ShuffleNetV2" or
			_verify_modelbackbone_="ShuffleNetV2_x15" or
			_verify_modelbackbone_="ShuffleNetV2_x20" or
			_verify_modelbackbone_="ShuffleNetV2_x25" or
			_verify_modelbackbone_="Xception"
			then do;

				/* Block 16 */
				_setup_init_Dropoutblock_16=&_CV_dropout_block16;
				_setup_lb_Dropoutblock_16=-10;
				_setup_ub_Dropoutblock_16=19;
			end;

			if _verify_modelbackbone_="Tiny-Yolov2" then do;

				/* Block 16 */
				_setup_init_Dropoutblock_16=0;
				_setup_lb_Dropoutblock_16=0;
				_setup_ub_Dropoutblock_16=0;
			end;
		end;

		/*ending dropout search = yes*/
		if verify_search_dropout ne "yes" then do;

			/* Block 1 */
			_setup_init_Dropoutblock_1=&_CV_dropout_block1;
			_setup_lb_Dropoutblock_1=&_CV_dropout_block1;
			_setup_ub_Dropoutblock_1=&_CV_dropout_block1;

			/* Block 2 */
			_setup_init_Dropoutblock_2=&_CV_dropout_block2;
			_setup_lb_Dropoutblock_2=&_CV_dropout_block2;
			_setup_ub_Dropoutblock_2=&_CV_dropout_block2;

			/* Block 3 */
			_setup_init_Dropoutblock_3=&_CV_dropout_block3;
			_setup_lb_Dropoutblock_3=&_CV_dropout_block3;
			_setup_ub_Dropoutblock_3=&_CV_dropout_block3;

			/* Block 4 */
			_setup_init_Dropoutblock_4=&_CV_dropout_block4;
			_setup_lb_Dropoutblock_4=&_CV_dropout_block4;
			_setup_ub_Dropoutblock_4=&_CV_dropout_block4;

			/* Block 5 */
			_setup_init_Dropoutblock_5=&_CV_dropout_block5;
			_setup_lb_Dropoutblock_5=&_CV_dropout_block5;
			_setup_ub_Dropoutblock_5=&_CV_dropout_block5;

			/* Block 6 */
			_setup_init_Dropoutblock_6=&_CV_dropout_block6;
			_setup_lb_Dropoutblock_6=&_CV_dropout_block6;
			_setup_ub_Dropoutblock_6=&_CV_dropout_block6;

			/* Block 7 */
			_setup_init_Dropoutblock_7=&_CV_dropout_block7;
			_setup_lb_Dropoutblock_7=&_CV_dropout_block7;
			_setup_ub_Dropoutblock_7=&_CV_dropout_block7;

			/* Block 8 */
			_setup_init_Dropoutblock_8=&_CV_dropout_block8;
			_setup_lb_Dropoutblock_8=&_CV_dropout_block8;
			_setup_ub_Dropoutblock_8=&_CV_dropout_block8;

			/* Block 9 */
			_setup_init_Dropoutblock_9=&_CV_dropout_block9;
			_setup_lb_Dropoutblock_9=&_CV_dropout_block9;
			_setup_ub_Dropoutblock_9=&_CV_dropout_block9;

			/* Block 10 */
			_setup_init_Dropoutblock_10=&_CV_dropout_block10;
			_setup_lb_Dropoutblock_10=&_CV_dropout_block10;
			_setup_ub_Dropoutblock_10=&_CV_dropout_block10;

			/* Block 11 */
			_setup_init_Dropoutblock_11=&_CV_dropout_block11;
			_setup_lb_Dropoutblock_11=&_CV_dropout_block11;
			_setup_ub_Dropoutblock_11=&_CV_dropout_block11;

			/* Block 12 */
			_setup_init_Dropoutblock_12=&_CV_dropout_block12;
			_setup_lb_Dropoutblock_12=&_CV_dropout_block12;
			_setup_ub_Dropoutblock_12=&_CV_dropout_block12;

			/* Block 13 */
			_setup_init_Dropoutblock_13=&_CV_dropout_block13;
			_setup_lb_Dropoutblock_13=&_CV_dropout_block13;
			_setup_ub_Dropoutblock_13=&_CV_dropout_block13;

			/* Block 14 */
			_setup_init_Dropoutblock_14=&_CV_dropout_block14;
			_setup_lb_Dropoutblock_14=&_CV_dropout_block14;
			_setup_ub_Dropoutblock_14=&_CV_dropout_block14;

			/* Block 15 */
			_setup_init_Dropoutblock_15=&_CV_dropout_block15;
			_setup_lb_Dropoutblock_15=&_CV_dropout_block15;
			_setup_ub_Dropoutblock_15=&_CV_dropout_block15;

			/* Block 16 */
			_setup_init_Dropoutblock_16=&_CV_dropout_block16;
			_setup_lb_Dropoutblock_16=&_CV_dropout_block16;
			_setup_ub_Dropoutblock_16=&_CV_dropout_block16;
		end;

		/*ending dropout search = no*/
		/* identify model backbone */
		_verify_modelbackbone_="&_CV_modelBackbone_";

		if _verify_modelbackbone_="autotune" then do;
			_setup_init_backbone=3;
			_setup_lb_backbone=1;
			_setup_ub_backbone=7;
		end;

		if _verify_modelbackbone_ ne "autotune" then do;

			if _verify_modelbackbone_="resnet50_caffe" then do;
				_setup_init_backbone=1;
				_setup_lb_backbone=1;
				_setup_ub_backbone=1;
			end;

			if _verify_modelbackbone_="Tiny-Yolov2" then do;
				_setup_init_backbone=2;
				_setup_lb_backbone=2;
				_setup_ub_backbone=2;
			end;

			if _verify_modelbackbone_="ShuffleNetV2" then do;
				_setup_init_backbone=3;
				_setup_lb_backbone=3;
				_setup_ub_backbone=3;
			end;

			if _verify_modelbackbone_="ShuffleNetV2_x15" then do;
				_setup_init_backbone=4;
				_setup_lb_backbone=4;
				_setup_ub_backbone=4;
			end;

			if _verify_modelbackbone_="ShuffleNetV2_x20" then do;
				_setup_init_backbone=5;
				_setup_lb_backbone=5;
				_setup_ub_backbone=5;
			end;

			if _verify_modelbackbone_="ShuffleNetV2_x25" then do;
				_setup_init_backbone=6;
				_setup_lb_backbone=6;
				_setup_ub_backbone=6;
			end;

			if _verify_modelbackbone_="Xception" then do;
				_setup_init_backbone=7;
				_setup_lb_backbone=7;
				_setup_ub_backbone=7;
			end;
		end;
		_verify_modeling_task_="&_CV_modeltask_";

		if _verify_modeling_task_ ne "objectdetection" then do;
			source caslInit;
			filename="&_CV_location_for_results_data" || "/init.txt";
			file nodes filename;
			loadactionset 'deeplearn';
			loadactionset 'image';
			loadactionset 'table';
			loadactionset 'sampling';
			table.addCasLib

			/*result=suppress*/ / name="libres", path="&_CV_location_for_results_data"
			subdirectories=true;
			table.addCasLib

			/*result=suppress*/ / name='libCVmod', path="&_CV_CVmodel_location"
			subdirectories=true;
			table.loadTable / caslib='libres', path="&_imageDS_..sashdat"
			casOut={name="&_imageDS_", replace=true, caslib='libres'} 
				importOptions={fileType="HDAT"};
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression, objectdetection or multitask */
			/* Resize the images to 224 by 224 */
			image.processImages result=suppress / casout={name="&_imageDS_", replace=1, 
				caslib="libres"} 
				copyVars={&_CVdm_TrgVarList '_path_' &_CV_tarVar_commaname_}
				nThreads=&_insert_imageprepnthreads_ 
				image="&_CV_inpVar_name_", imageTable={name="&_imageDS_", caslib="libres"} 
				imageFunctions={{functionOptions={functionType='RESIZE', 
				height=&_image_input_height_, width=&_image_input_width_}}};
			_verify_image_color="&_image_input_color_";

			/* yes no */
			if _verify_image_color="greyscale" then do;
				image.processImages result=suppress / casout={name="&_imageDS_", 
					replace=True, caslib="libres"} 
					copyVars={&_CVdm_TrgVarList '_path_' &_CV_tarVar_commaname_} 
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", 
					imagefunctions={{functionOptions={functionType='CONVERT_COLOR'
					type="COLOR2GRAY"}}} table={name="&_imageDS_", caslib="libres"};
			end;

			/***************************************************************************/
			/* Apply inverse prior weights for classification target - create variable */
			/***************************************************************************/
			if &_onoff_cntrldcrule_=1 and _verify_modeling_task_="classification" then 
					do;
				table.loadTable / caslib='libres', path="&_imageDS_..sashdat"
				casOut={name="tempimgdatadrop", replace=true, caslib='casuser'};
				table.alterTable / caslib="casuser", name="tempimgdatadrop", 
					drop={"&_insert_imagecolumn"};
				freqTab.freqTab / table={name="tempimgdatadrop", caslib="casuser"}, 
					tabulate={"&_insert_tarvar_1"} 
					outputTables={names={"OneWayFreqs"={name="tarfreqsper", 
					caslib="casuser"}}};
				datastep.runCode / code="
Data casuser.happydays;
merge casuser.tarfreqsper casuser.tempimgdatadrop;
by &_insert_tarvar_1;
temp_precprior=Percent/100;
central_decision_rule=1/temp_precprior;
keep &_insert_tarvar_1 central_decision_rule _path_;
run;
";
				deepLearn.dlJoin / annotatedTable={name="happydays", caslib="casuser"} 
					casOut={name="&_imageDS_", replace=1, caslib="libres", replication=0, 
					maxMemSize=200G, compress=TRUE} id="_path_"

					/* 	  						nthreads=1, */
					joinType="full", table={name="&_imageDS_", caslib="libres"};
			end;
			_set_train_sample_percent_=100-&_CV_valid_partition_per_;

			/* Create sample for localization model */
			action sampling.srs result=suppress / table={name="&_imageDS_", caslib="libres"} 
				samppct=_set_train_sample_percent_
				sampPct2=&_CV_valid_partition_per_
				seed=&_CV_partition_seed
				partInd=true
				output={casout={name="&_imageDS_", replace="TRUE", caslib="libres", 
				replication=0, maxMemSize=200G, compress=TRUE}, copyvars="ALL", 
				partIndName="&_CV_partition_var_"};

			/* Shuffle data per good practice */
			table.shuffle result=suppress / table={name="&_imageDS_", caslib="libres"} 
				casout={name="&_imageDS_", replace=1, caslib="libres", replication=0, 
				maxMemSize=200G, compress=TRUE};
			;
			_verify_modelbackbone_="&_CV_modelBackbone_";

			if _tm_warmstart ne 1 then do;

				if _verify_modelbackbone_="autotune" then do;
					table.loadTable /caslib='libCVmod', path='resnet50_caffe_weights.sashdat'
					casOut={name='resnet50_caffe_weights', replace=true};
					table.loadTable /caslib='libCVmod', 
						path='resnet50_caffe_weights_attr.sashdat'
						casOut={name='resnet50_caffe_weights_attr', replace=true};
					table.attribute / task='add' name='resnet50_caffe_weights'
					table='resnet50_caffe_weights_attr';
					table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights.sashdat'
					casOut={name='Tiny-Yolov2_weights', replace=true};
					table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights_attr.sashdat'
					casOut={name='Tiny-Yolov2_weights_attr', replace=true};
					table.attribute / task='add' name='Tiny-Yolov2_weights'
					table='Tiny-Yolov2_weights_attr';
					table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights.sashdat'
					casOut={name='ShuffleNetV2_weights', replace=true};
					table.loadTable /caslib='libCVmod', 
						path='ShuffleNetV2_weights_attr.sashdat'
						casOut={name='ShuffleNetV2_weights_attr', replace=true};
					table.attribute / task='add' name='ShuffleNetV2_weights'
					table='ShuffleNetV2_weights_attr';

					/* NOTE: Using random weights for XceptionNet*/
				end;

				if _verify_modelbackbone_="resnet50_caffe" then do;
					table.loadTable /caslib='libCVmod', path='resnet50_caffe_weights.sashdat'
					casOut={name='resnet50_caffe_weights', replace=true};
					table.loadTable /caslib='libCVmod', 
						path='resnet50_caffe_weights_attr.sashdat'
						casOut={name='resnet50_caffe_weights_attr', replace=true};
					table.attribute / task='add' name='resnet50_caffe_weights'
					table='resnet50_caffe_weights_attr';
				end;

				if _verify_modelbackbone_="Tiny-Yolov2" then do;
					table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights.sashdat'
					casOut={name='Tiny-Yolov2_weights', replace=true};
					table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights_attr.sashdat'
					casOut={name='Tiny-Yolov2_weights_attr', replace=true};
					table.attribute / task='add' name='Tiny-Yolov2_weights'
					table='Tiny-Yolov2_weights_attr';
				end;

				if _verify_modelbackbone_="ShuffleNetV2" or
				_verify_modelbackbone_="ShuffleNetV2_x15" or
				_verify_modelbackbone_="ShuffleNetV2_x20" or
				_verify_modelbackbone_="ShuffleNetV2_x25" then do;
					table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights.sashdat'
					casOut={name='ShuffleNetV2_weights', replace=true};
					table.loadTable /caslib='libCVmod', 
						path='ShuffleNetV2_weights_attr.sashdat'
						casOut={name='ShuffleNetV2_weights_attr', replace=true};
					table.attribute / task='add' name='ShuffleNetV2_weights'
					table='ShuffleNetV2_weights_attr';
				end;
			end;

			if _tm_warmstart=1 then do;
				_verify_ws_modelbbone_="&_tm_wsbackbone";

				if _verify_ws_modelbbone_="resnet50_caffe" then do;
					table.loadTable /caslib='libres', path='autotune_bestweights_.sashdat'
					casOut={name='resnet50_caffe_weights', replace=true};
					table.loadTable /caslib='libres', 
						path='autotune_bestweights_.ATTRS.sashdat'
						casOut={name='resnet50_caffe_weights_attr', replace=true};
					table.attribute / task='add' name='resnet50_caffe_weights'
					table='resnet50_caffe_weights_attr';
				end;

				if _verify_ws_modelbbone_="Tiny-Yolov2" then do;
					table.loadTable /caslib='libres', path='autotune_bestweights_.sashdat'
					casOut={name='Tiny-Yolov2_weights', replace=true};
					table.loadTable /caslib='libres', 
						path='autotune_bestweights_.ATTRS.sashdat'
						casOut={name='Tiny-Yolov2_weights_attr', replace=true};
					table.attribute / task='add' name='Tiny-Yolov2_weights'
					table='Tiny-Yolov2_weights_attr';
				end;

				if _verify_ws_modelbbone_="ShuffleNetV2" or
				_verify_ws_modelbbone_="ShuffleNetV2_x15" or
				_verify_ws_modelbbone_="ShuffleNetV2_x20" or
				_verify_ws_modelbbone_="ShuffleNetV2_x25" then do;
					table.loadTable /caslib='libres', path='autotune_bestweights_.sashdat'
					casOut={name='ShuffleNetV2_weights', replace=true};
					table.loadTable /caslib='libres', 
						path='autotune_bestweights_.ATTRS.sashdat'
						casOut={name='ShuffleNetV2_weights_attr', replace=true};
					table.attribute / task='add' name='ShuffleNetV2_weights'
					table='ShuffleNetV2_weights_attr';
				end;
			end;

			/* NOTE: Using random weights for XceptionNet*/
			table.dropTable / caslib="casuser" name="objectivefunctionhold" quiet=TRUE;
			datastep.runCode / 
				code="
data casuser.objectivefunctionhold;
currentobj=99999999;
run;
";
			endsource;
			source evalcode;
			filename="&_CV_location_for_results_data" || "/" || (String)_bbEvalTag_ || ".txt";
			file nodes filename;

			/* Set first convo filter size */
			if _decision_fconvo_size=1 then do;
				_CV_firstConvo_width=3+0;
				_CV_firstConvo_height=3+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
			end;

			if _decision_fconvo_size=2 then do;
				_CV_firstConvo_width=3+0;
				_CV_firstConvo_height=5+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
			end;

			if _decision_fconvo_size=3 then do;
				_CV_firstConvo_width=5+0;
				_CV_firstConvo_height=3+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
			end;

			if _decision_fconvo_size=4 then do;
				_CV_firstConvo_width=5+0;
				_CV_firstConvo_height=5+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
			end;

			if _decision_fconvo_size=5 then do;
				_CV_firstConvo_width=5+0;
				_CV_firstConvo_height=7+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
			end;

			if _decision_fconvo_size=6 then do;
				_CV_firstConvo_width=7+0;
				_CV_firstConvo_height=5+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
			end;

			if _decision_fconvo_size=7 then do;
				_CV_firstConvo_width=7+0;
				_CV_firstConvo_height=7+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
			end;

			/*********************/
			/*Setup for Dropout */
			/*********************/
			_dec_Drop_out_block_1=_decision_Dropoutblock_1_;
			_dec_Drop_out_block_2=_decision_Dropoutblock_2;
			_dec_Drop_out_block_3=_decision_Dropoutblock_3;
			_dec_Drop_out_block_4=_decision_Dropoutblock_4;
			_dec_Drop_out_block_5=_decision_Dropoutblock_5;
			_dec_Drop_out_block_6=_decision_Dropoutblock_6;
			_dec_Drop_out_block_7=_decision_Dropoutblock_7;
			_dec_Drop_out_block_8=_decision_Dropoutblock_8;
			_dec_Drop_out_block_9=_decision_Dropoutblock_9;
			_dec_Drop_out_block__10=_decision_Dropoutblock_10;
			_dec_Drop_out_block__11=_decision_Dropoutblock_11;
			_dec_Drop_out_block__12=_decision_Dropoutblock_12;
			_dec_Drop_out_block__13=_decision_Dropoutblock_13;
			_dec_Drop_out_block__14=_decision_Dropoutblock_14;
			_dec_Drop_out_block__15=_decision_Dropoutblock_15;
			_dec_Drop_out_block__16=_decision_Dropoutblock_16;

			/*********************************/
			/* Classification modeling */
			/*********************************/
			/* identify model backbone */
			_verify_modelbackbone_="&_CV_modelBackbone_";

			if _verify_modelbackbone_="autotune" then do;

				if _decision_modelbackbone=1 then _verify_modelbackbone_="resnet50_caffe";

				if _decision_modelbackbone=2 then _verify_modelbackbone_="Tiny-Yolov2";

				if _decision_modelbackbone=3 then _verify_modelbackbone_="ShuffleNetV2";

				if _decision_modelbackbone=4 then _verify_modelbackbone_="ShuffleNetV2_x15";

				if _decision_modelbackbone=5 then _verify_modelbackbone_="ShuffleNetV2_x20";

				if _decision_modelbackbone=6 then _verify_modelbackbone_="ShuffleNetV2_x25";

				if _decision_modelbackbone=7 then _verify_modelbackbone_="Xception";
			end;

			if _verify_modelbackbone_="resnet50_caffe" then do;
				table.loadTable /caslib='libCVmod', path='resnet50_caffe.sashdat'
				casOut={name='resnet50_caffe', replace=true};

				/*ResNet Apply Dropout to input layer*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};


				/* remove current output layer */
				removelayer result=suppress / model='resnet50_caffe' name='fc1000';

				/* Set last pooling layer to transform tensor into vector */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/* Adjust first convo layer filter sizes */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="classification" then do;
					_verify_FC_include_="&_CV_include_FC_layer";

					/* include FC layer for class and reg task?   */
					if _verify_FC_include_="yes" then do;

						/* Add a projection layer with Batch Normalization */
						AddLayer result=suppress / model='resnet50_caffe' name='fclayer1'
						layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
						stride=1 act='elu' dropout=&_tm_projdropoutrate} srcLayers={'pool5'};

						/* add new output layer */
						AddLayer result=suppress / model='resnet50_caffe' name='output1'
						layer={type='output' act='SOFTMAX'} srcLayers={'fclayer1'};

						/* change model activation functions */
						_verify_FC_activation_function=_decision_FCactfunc;

						if _verify_FC_activation_function=11 then 
							_new_FC_activation_value_=(string)6;

						if _verify_FC_activation_function ne 11 then 
							_new_FC_activation_value_=(string)_verify_FC_activation_function;
						mytbl.name="resnet50_caffe";
						mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
						table.update / table=mytbl set={{var="_DLNumVal_", 
							value=_new_FC_activation_value_}};
					end;

					if _verify_FC_include_ ne "yes" then do;

						/* add new output layer */
						AddLayer result=suppress / model='resnet50_caffe' name='output1'
						layer={type='output' act='SOFTMAX'} srcLayers={'pool5'};
					end;
				end;

				/* finished output layer setup for classification model */
				if _verify_modeling_task_="regression" then do;
					_verify_FC_include_="&_CV_include_FC_layer";

					/* include FC layer for class and reg task?   */
					if _verify_FC_include_="yes" then do;

						/* Add a projection layer with Batch Normalization */
						AddLayer result=suppress / model='resnet50_caffe' name='fclayer1'
						layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
						stride=1 act='elu' dropout=&_tm_projdropoutrate} srcLayers={'pool5'};

						/* add new output layer */
						AddLayer result=suppress / model='resnet50_caffe' name='output1'
						layer={type='output' error="&_CV_reg_error"
						act="&_CV_reg_out_act_function"
						targetStd="&_CV_reg_out_standardization"} srcLayers={'fclayer1'};

						/* change model activation functions */
						_verify_FC_activation_function="&_CV_FC_act_function";

						if _verify_FC_activation_function=11 then 
							_new_FC_activation_value_=(string)6;

						if _verify_FC_activation_function ne 11 then 
							_new_FC_activation_value_=(string)_verify_FC_activation_function;
						mytbl.name="resnet50_caffe";
						mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
						table.update / table=mytbl set={{var="_DLNumVal_", 
							value=_new_FC_activation_value_}};
					end;

					if _verify_FC_include_ ne "yes" then do;

						/* add new output layer */
						AddLayer result=suppress / model='resnet50_caffe' name='output1'
						layer={type='output' error="&_CV_reg_error"
						act="&_CV_reg_out_act_function"
						targetStd="&_CV_reg_out_standardization"} srcLayers={'pool5'};
					end;
				end;

				/* finished output layer setup for regression model */
				/*****************************/
				/* Add multi-task layers */
				/*****************************/
				if _verify_modeling_task_="multitask" then do;
					&_CVdm_addlayercodemultitask;
				end;

				/*****************************/
				/* Remove bias from convo1 */
				/*****************************/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.no_bias'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};

				/*********************/
				/*Apply Dropout */
				/*********************/
				_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;

				if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
				_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2a_branch1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;

				if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
				_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;

				if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
				_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;

				if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
				_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3a_branch1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;

				if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
				_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;

				if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
				_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;

				if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
				_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3d_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3d_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3d_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;

				if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
				_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4a_branch1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;

				if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
				_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;

				if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
				_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;

				if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
				_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4d_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4d_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4d_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;

				if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
				_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4e_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4e_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4e_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;

				if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
				_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4f_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4f_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4f_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;

				if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
				_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5a_branch1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;

				if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
				_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;

				if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
				_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};

				/* change model activation functions */
				_verify_activation_function=_decision_actfunction;

				if _verify_activation_function=11 then _new_activation_value_=(string)6;

				if _verify_activation_function ne 11 then 
					_new_activation_value_=(string)_verify_activation_function;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				_verify_crop_="&_CV_crop_RESIZE_THENCROP";

				if _verify_crop_="RESIZETHENCROP" then do;

					/* Apply crop */
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;

				if _verify_crop_="none" then do;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_mutation_="&_CV_random_mutate";

				if _verify_mutation_="random" then do;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;

				if _verify_mutation_="none" then do;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_fliptype_="&_CV_fliptype_";

				if _verify_fliptype_="none" then do;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;

				if _verify_fliptype_="horizontal" then do;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;

				if _verify_fliptype_="vertical" then do;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
				end;

				if _verify_fliptype_="both" then do;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_height_"}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_width_"}};

				/* Change the number of channels to match greyscale if condition exist */
				_verify_image_color="&_image_input_color_";

				/* yes no */
				if _verify_image_color="greyscale" then do;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
					table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
				end;
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;

				if _chk_image_height_<244 or _chk_image_width_<244 then do;

					/* Update Stride for last pool layer */
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.stride'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.stride_height'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.stride_width'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.height'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.width'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
				end;
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="classification" then do;
					_set_beta1_value=.999-_decision_betadiff+0;
					lower_clipgrad=0+_decision_gradclips*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
						caslib="libres"} model='resnet50_caffe'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
						initWeights='resnet50_caffe_weights'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F
						&_weghtcodtrain_
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
						caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
						algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
						stepsize=_decision_stepsize, learningrate=_decision_lr, 
						beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
						clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
						regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;

					/* return flipping back to "no flip" for OD model scoring and deployment */
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
					table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

					/* remove dropout */
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey1_ = 'convopts.dropout'";
					table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
					table.tableExists result=d / name='autotune_bestweights_', 
						caslib="casuser";

					/*Reset ResNet Dropout in input layer back to 0*/
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
					table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};


					if d=1 then do;
						deeplearn.dlScore result=s / table={name="&_imageDS_", 
							where="&_CV_partition_var_=2", caslib="libres"} model='resnet50_caffe'
							initWeights={name='autotune_bestweights_', caslib="casuser"} 
							gpu=&_CV_usegpu_T_F;
						Error1=0+s['ScoreInfo'][3]['Value'];

						if _bbEvalTag_=1 and Error1 ne . then do;
							_holdvalue_=Error1;
							newobjfunc=(string)_holdvalue_;
							table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
								set={{var="currentobj", value=newobjfunc}};
							table.save / saveAttrs=True
							Caslib="libres"
							table={name="autotune_bestweights_", caslib="casuser"} 
								name="autotune_bestweights_.sashdat"
								permission="PUBLICWRITE"
								replace=True;
						end;
						table.fetch result=r / table={caslib="casuser"
						name="objectivefunctionhold"};
						grab_obj_value=0+r['Fetch'][1]['currentobj'];
						globalobj=0+grab_obj_value;

						if Error1 ne . then do;

							if Error1 < globalobj then do;
								_holdvalue_=Error1;
								newobjfunc=(string)_holdvalue_;
								table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
									set={{var="currentobj", value=newobjfunc}};
								table.save / saveAttrs=True
								Caslib="libres"
								table={name="autotune_bestweights_", caslib="casuser"} 
									name="autotune_bestweights_.sashdat"
									permission="PUBLICWRITE"
									replace=True;
							end;
						end;
						f['objVal']=Error1+0;
					end;

					if d ne 1 then do;
						Error1=.;
						f['objVal']=Error1;
					end;
					send_response(f);
				run;

				end;

				/* End classification model training code  */
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="regression" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='resnet50_caffe'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='resnet50_caffe_weights'
					inputs="&_CV_inpVar_name_"
					target="&_CV_tarVar_name_"
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_

					/* 		weight="weight" */
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove dropout */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='resnet50_caffe'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					gpu=&_CV_usegpu_T_F;
				Error1=0+s['ScoreInfo'][3]['Value'];
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/* End regression model training code  */
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression, objectdetection, or multitask */
				if _verify_modeling_task_="multitask" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='resnet50_caffe'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='resnet50_caffe_weights'
					dataSpecs={&_CVdm_dltraincodemultitaskres} GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_

					/* 		weight="weight" */
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='resnet50_caffe'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					GPU=&_CV_usegpu_T_F;
				Error1=0;
				do i=3 to &multaskevals by 1;
				multilossi=0+s['ScoreInfo'][i]['Value'];
				Error1=Error1+0+multilossi;
				end;
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/* End regression model training code  */
				end;

				/* End ResNet50 model setup */
				/************************************/
				/* tiny-YOLOv2 for classification */
				/************************************/
				_verify_modelbackbone_="&_CV_modelBackbone_";
				if _verify_modelbackbone_="autotune" then do;
				if _decision_modelbackbone=1 then _verify_modelbackbone_="resnet50_caffe";
				if _decision_modelbackbone=2 then _verify_modelbackbone_="Tiny-Yolov2";
				if _decision_modelbackbone=3 then _verify_modelbackbone_="ShuffleNetV2";
				if _decision_modelbackbone=4 then _verify_modelbackbone_="ShuffleNetV2_x15";
				if _decision_modelbackbone=5 then _verify_modelbackbone_="ShuffleNetV2_x20";
				if _decision_modelbackbone=6 then _verify_modelbackbone_="ShuffleNetV2_x25";
				if _decision_modelbackbone=7 then _verify_modelbackbone_="Xception";
				end;
				if _verify_modelbackbone_="Tiny-Yolov2" then do;
				table.loadTable /caslib='libCVmod', path='Tiny-Yolov2.sashdat'
				casOut={name='Tiny-Yolov2', replace=true};
				/*Tiny_Yolov2 Apply Dropout to input layer*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

				removelayer / model='Tiny-Yolov2' name='detection1';
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="classification" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;
				AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
				layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'};
				AddLayer / model='Tiny-Yolov2' name='poolavg' layer={type='POOL' width=0
				height=0 stride=1 pool='AVERAGE'} srcLayers={'b_n_9'};
				AddLayer result=suppress / model='Tiny-Yolov2' name='fclayer1'
				layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
				stride=1 act='elu' dropout=&_tm_projdropoutrate} srcLayers={'poolavg'};
				AddLayer result=suppress / model='Tiny-Yolov2' name='output1'
				layer={type='output' act='SOFTMAX'} srcLayers={'fclayer1'};
				_verify_FC_activation_function=_decision_FCactfunc;
				if _verify_FC_activation_function=11 then
				_new_FC_activation_value_=(string)6;
				if _verify_FC_activation_function ne 11 then
				_new_FC_activation_value_=(string)_verify_FC_activation_function;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_FC_activation_value_}};
				end;
				if _verify_FC_include_ ne "yes" then do;
				AddLayer / model='Tiny-Yolov2' name='poolavg' layer={type='POOL' width=0
				height=0 stride=1 pool='AVERAGE'} srcLayers={'convo.9'};
				AddLayer result=suppress / model='Tiny-Yolov2' name='output1'
				layer={type='output' act='SOFTMAX'} srcLayers={'poolavg'};
				end;
				end;
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="regression" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;
				AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
				layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'};
				AddLayer result=suppress / model='Tiny-Yolov2' name='poolavg'
				layer={type='POOL' width=0 height=0 stride=1 pool='AVERAGE'} 
					srcLayers={'b_n_9'};
				AddLayer result=suppress / model='Tiny-Yolov2' name='fclayer1'
				layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
				stride=1 act='elu' dropout=&_tm_projdropoutrate} srcLayers={'poolavg'};
				AddLayer result=suppress / model='Tiny-Yolov2' name='output1'
				layer={type='output' error="&_CV_reg_error" act="&_CV_reg_out_act_function"
				targetStd="&_CV_reg_out_standardization"} srcLayers={'fclayer1'};
				_verify_FC_activation_function="&_CV_FC_act_function";
				if _verify_FC_activation_function=11 then
				_new_FC_activation_value_=(string)6;
				if _verify_FC_activation_function ne 11 then
				_new_FC_activation_value_=(string)_verify_FC_activation_function;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_FC_activation_value_}};
				end;
				if _verify_FC_include_ ne "yes" then do;
				AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
				layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'};
				AddLayer result=suppress / model='Tiny-Yolov2' name='poolavg'
				layer={type='POOL' width=0 height=0 stride=1 pool='AVERAGE'} 
					srcLayers={'b_n_9'};
				AddLayer result=suppress / model='Tiny-Yolov2' name='output1'
				layer={type='output' error="&_CV_reg_error" act="&_CV_reg_out_act_function"
				targetStd="&_CV_reg_out_standardization"} srcLayers={'poolavg'};
				end;
				end;
				if _verify_modeling_task_="multitask" then do;
				&_CVdm_addlayercodemultitask;
				end;
				_verify_activation_function=_decision_actfunction;
				if _verify_activation_function=11 then _new_activation_value_=(string)6;
				if _verify_activation_function ne 11 then
				_new_activation_value_=(string)_verify_activation_function;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Leaky Activation Function'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				verify_apply_dropout="&_CV_dropValue";
				_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
				if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
				_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
				if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
				_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool1' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
				if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
				_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.2' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
				if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
				_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool2' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
				if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
				_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.3' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
				if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
				_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool3' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
				if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
				_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.4' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
				if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
				_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool4' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
				if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
				_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.5' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
				if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
				_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
				if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
				_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.6' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
				if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
				_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool6' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
				if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
				_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.7' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
				if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
				_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.8' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
				if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
				_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.9' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				_verify_crop_="&_CV_crop_RESIZE_THENCROP";
				if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;
				if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_mutation_="&_CV_random_mutate";
				if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_fliptype_="&_CV_fliptype_";
				if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				if _verify_fliptype_="horizontal" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_fliptype_="vertical" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
				end;
				if _verify_fliptype_="both" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;

				/* Change the expected input size - height */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_height_"}};

				/* Change the expected input size - width */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_width_"}};

				/* Change the number of channels to match greyscale if condition exist */
				_verify_image_color="&_image_input_color_";

				/* yes no */
				if _verify_image_color="greyscale" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
				end;
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="classification" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;

				/*begin Tiny-Yolov2 for classification*/
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='Tiny-Yolov2'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='Tiny-Yolov2_weights'
					inputs="&_CV_inpVar_name_"
					target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_
					&_weghtcodtrain_
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/*remove dropout*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'poolingopts.dropout' or  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
	
				/*Reset Tiny-Yolov2 Dropout in input layer back to 0*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='Tiny-Yolov2'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					gpu=&_CV_usegpu_T_F;
				Error1=0+s['ScoreInfo'][3]['Value'];
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="regression" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='Tiny-Yolov2'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='Tiny-Yolov2_weights'
					inputs="&_CV_inpVar_name_"
					target="&_CV_tarVar_name_"
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/*remove dropout*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'poolingopts.dropout' or  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Tiny-Yolov2 Dropout in input layer back to 0*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='Tiny-Yolov2'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					gpu=&_CV_usegpu_T_F;
				Error1=0+s['ScoreInfo'][3]['Value'];
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression, objectdetection, multitask */
				if _verify_modeling_task_="multitask" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='Tiny-Yolov2'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='Tiny-Yolov2_weights'
					dataSpecs={&_CVdm_dltraincodemultitasktin} GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/*remove dropout*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'poolingopts.dropout' or  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Tiny-Yolov2 Dropout in input layer back to 0*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='Tiny-Yolov2'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					GPU=&_CV_usegpu_T_F;
				Error1=0;
				do i=3 to &multaskevals by 1;
				multilossi=0+s['ScoreInfo'][i]['Value'];
				Error1=Error1+0+multilossi;
				end;

				/* save best model weights */
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;
				end;

				/************************************/
				/* ShuffleNetV2 for classification */
				/************************************/
				_verify_modelbackbone_="&_CV_modelBackbone_";
				if _verify_modelbackbone_="autotune" then do;
				if _decision_modelbackbone=1 then _verify_modelbackbone_="resnet50_caffe";
				if _decision_modelbackbone=2 then _verify_modelbackbone_="Tiny-Yolov2";
				if _decision_modelbackbone=3 then _verify_modelbackbone_="ShuffleNetV2";
				if _decision_modelbackbone=4 then _verify_modelbackbone_="ShuffleNetV2_x15";
				if _decision_modelbackbone=5 then _verify_modelbackbone_="ShuffleNetV2_x20";
				if _decision_modelbackbone=6 then _verify_modelbackbone_="ShuffleNetV2_x25";
				if _decision_modelbackbone=7 then _verify_modelbackbone_="Xception";
				end;
				if _verify_modelbackbone_="ShuffleNetV2" or
				_verify_modelbackbone_="ShuffleNetV2_x15" or
				_verify_modelbackbone_="ShuffleNetV2_x20" or
				_verify_modelbackbone_="ShuffleNetV2_x25" then do;
				table.loadTable /caslib='libCVmod', path='ShuffleNetV2.sashdat'
				casOut={name='ShuffleNetV2', replace=true};

				/*ShuffleNetV2 Apply Dropout to input layer*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

				/* step 1 remove output layer - line 922 reference */
				removelayer result=suppress / model='ShuffleNetV2' name='outputlayer_2';
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*adjust complexcity of shuffleNet*/
				if _decision_modelbackbone=4 then do;

				/* Adjust the model complexity */
				/*352.00 to 704.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="704.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="704.00"}};

				/*176.00 to 352.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="352.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="352.00"}};

				/*88.00 to 176.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="176.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="176.00"}};
				end;
				if _decision_modelbackbone=5 then do;

				/* Adjust the model complexity */
				/*352.00 to 976.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="976.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="976.00"}};

				/*176.00 to 488.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="488.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="488.00"}};

				/*88.00 to 244.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="244.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="244.00"}};
				end;
				if _decision_modelbackbone=6 then do;

				/* Adjust the model complexity */
				/*352.00 to 1216.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1248.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1248.00"}};

				/*176.00 to 488.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="624.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="624.00"}};

				/*88.00 to 244.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="312.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="312.00"}};

				/* increase convo1 from 24 to 28 filters */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv_2' and  _DLChrVal_ = 'ngroups'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv_2' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = '1x1conv5_out' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="2048.00"}};
				end;

				/* Adjust first convo layer filter sizes */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="classification" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

				/* Add a projection layer with Batch Normalization */
				AddLayer result=suppress / model='ShuffleNetV2' name='fclayer1'
				layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
				stride=1 act='elu' dropout=&_tm_projdropoutrate} 
					srcLayers={'global_avg_pool'};

				/* add new output layer */
				AddLayer result=suppress / model='ShuffleNetV2' name='output1'
				layer={type='output' act='SOFTMAX'} srcLayers={'fclayer1'};

				/* change model activation functions */
				_verify_FC_activation_function=_decision_FCactfunc;
				if _verify_FC_activation_function=11 then
				_new_FC_activation_value_=(string)6;
				if _verify_FC_activation_function ne 11 then
				_new_FC_activation_value_=(string)_verify_FC_activation_function;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_FC_activation_value_}};
				end;
				if _verify_FC_include_ ne "yes" then do;

				/* add new output layer */
				AddLayer result=suppress / model='ShuffleNetV2' name='output1'
				layer={type='output' act='SOFTMAX'} srcLayers={'global_avg_pool'};
				end;
				end;

				/* finished output layer setup for classification model */
				if _verify_modeling_task_="regression" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

				/* Add a projection layer with Batch Normalization */
				AddLayer result=suppress / model='ShuffleNetV2' name='fclayer1'
				layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
				stride=1 act='elu' dropout=&_tm_projdropoutrate} 
					srcLayers={'global_avg_pool'};

				/* add new output layer */
				AddLayer result=suppress / model='ShuffleNetV2' name='output1'
				layer={type='output' error="&_CV_reg_error" act="&_CV_reg_out_act_function"
				targetStd="&_CV_reg_out_standardization"} srcLayers={'fclayer1'};

				/* change model activation functions */
				_verify_FC_activation_function="&_CV_FC_act_function";
				if _verify_FC_activation_function=11 then
				_new_FC_activation_value_=(string)6;
				if _verify_FC_activation_function ne 11 then
				_new_FC_activation_value_=(string)_verify_FC_activation_function;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_FC_activation_value_}};
				end;
				if _verify_FC_include_ ne "yes" then do;

				/* add new output layer */
				AddLayer result=suppress / model='ShuffleNetV2' name='output1'
				layer={type='output' error="&_CV_reg_error" act="&_CV_reg_out_act_function"
				targetStd="&_CV_reg_out_standardization"} srcLayers={'global_avg_pool'};
				end;
				end;

				/* finished output layer setup for regression model */
				if _verify_modeling_task_="multitask" then do;
				&_CVdm_addlayercodemultitask;
				end;
				_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
				if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
				_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
				if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
				_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
				if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
				_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
				if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
				_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
				if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
				_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
				if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
				_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
				if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
				_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
				if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
				_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
				if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
				_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block5/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
				if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
				_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block6/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
				if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
				_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block7/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
				if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
				_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block8/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
				if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
				_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage4/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
				if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
				_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage4/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
				if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
				_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage4/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;
				if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
				_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage4/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};

				/* change model activation functions */
				_verify_activation_function=_decision_actfunction;
				if _verify_activation_function=11 then _new_activation_value_=(string)6;
				if _verify_activation_function ne 11 then
				_new_activation_value_=(string)_verify_activation_function;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				_verify_crop_="&_CV_crop_RESIZE_THENCROP";
				if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;
				if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_mutation_="&_CV_random_mutate";
				if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_fliptype_="&_CV_fliptype_";
				if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				if _verify_fliptype_="horizontal" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_fliptype_="vertical" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
				end;
				if _verify_fliptype_="both" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;

				/* Change the expected input size - height */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_height_"}};

				/* Change the expected input size - width */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_width_"}};

				/* Change the number of channels to match greyscale if condition exist */
				_verify_image_color="&_image_input_color_";

				/* yes no */
				if _verify_image_color="greyscale" then do;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
				end;
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				if _chk_image_height_<244 or _chk_image_width_<244 then do;

				/* Update Stride for last pool layer */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.stride'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.stride_height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.stride_width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
				end;
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="classification" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='ShuffleNetV2'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='ShuffleNetV2_weights'
					inputs="&_CV_inpVar_name_"
					target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
					GPU=&_CV_usegpu_T_F
					&_weghtcodtrain_
					nthreads=&n_threads_
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset ShuffleNetV2 Dropout in input layer back to 0*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				if d=1 then do;
				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='ShuffleNetV2'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					gpu=&_CV_usegpu_T_F;
				Error1=0+s['ScoreInfo'][3]['Value'];

				/* save best model weights */
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/* End classification model training code  */
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="regression" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='ShuffleNetV2'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='ShuffleNetV2_weights'
					inputs="&_CV_inpVar_name_"
					target="&_CV_tarVar_name_"
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_

					/* 		weight="weight" */
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* Remove dropout */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset ShuffleNetV2 Dropout in input layer back to 0*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='ShuffleNetV2'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					gpu=&_CV_usegpu_T_F;
				Error1=0+s['ScoreInfo'][3]['Value'];
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/* End regression model training code  */
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression objectdetection multitask */
				if _verify_modeling_task_="multitask" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='ShuffleNetV2'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='ShuffleNetV2_weights'
					dataSpecs={&_CVdm_dltraincodemultitaskshuf} GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_

					/* 		weight="weight" */
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* Remove dropout */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset ShuffleNetV2 Dropout in input layer back to 0*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='ShuffleNetV2'
					initWeights={name="autotune_bestweights_", caslib="casuser"} 
					GPU=&_CV_usegpu_T_F;
				Error1=0;
				do i=3 to &multaskevals by 1;
				multilossi=0+s['ScoreInfo'][i]['Value'];
				Error1=Error1+0+multilossi;
				end;

				/* save best model weights */
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/* End regression model training code  */
				end;

				/* End ShuffleNetV2-style model setup */
				/************************************/
				/* Xception for classification */
				/************************************/
				_verify_modelbackbone_="&_CV_modelBackbone_";
				if _verify_modelbackbone_="autotune" then do;
				if _decision_modelbackbone=1 then _verify_modelbackbone_="resnet50_caffe";
				if _decision_modelbackbone=2 then _verify_modelbackbone_="Tiny-Yolov2";
				if _decision_modelbackbone=3 then _verify_modelbackbone_="ShuffleNetV2";
				if _decision_modelbackbone=4 then _verify_modelbackbone_="ShuffleNetV2_x15";
				if _decision_modelbackbone=5 then _verify_modelbackbone_="ShuffleNetV2_x20";
				if _decision_modelbackbone=6 then _verify_modelbackbone_="ShuffleNetV2_x25";
				if _decision_modelbackbone=7 then _verify_modelbackbone_="Xception";
				end;
				if _verify_modelbackbone_="Xception" then do;
				table.loadTable /caslib='libCVmod', path='Xception.sashdat'
				casOut={name='Xception', replace=true};
				/*Xception Apply Dropout to input layer*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

				/* remove current output layer */
				removelayer result=suppress / model='Xception' name='outlayer';
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/* Adjust first convo layer filter sizes */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};
				_verify_modeling_task_="&_CV_modeltask_";
				if _verify_modeling_task_="classification" then do;
				_verify_FC_include_="&_CV_include_FC_layer";
				if _verify_FC_include_="yes" then do;

				/* Add a projection layer with Batch Normalization */
				AddLayer result=suppress / model='Xception' name='fclayer1'
				layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
				stride=1 act='elu' dropout=&_tm_projdropoutrate} 
					srcLayers={'final_avepool'};

				/* add new output layer */
				AddLayer result=suppress / model='Xception' name='outlayer'
				layer={type='output' act='SOFTMAX'} srcLayers={'fclayer1'};

				/* change model activation functions */
				_verify_FC_activation_function=_decision_FCactfunc;
				if _verify_FC_activation_function=11 then
				_new_FC_activation_value_=(string)6;
				if _verify_FC_activation_function ne 11 then
				_new_FC_activation_value_=(string)_verify_FC_activation_function;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_FC_activation_value_}};
				end;
				if _verify_FC_include_ ne "yes" then do;

				/* add new output layer */
				AddLayer result=suppress / model='Xception' name='outlayer'
				layer={type='output' act='SOFTMAX'} srcLayers={'final_avepool'};
				end;
				end;

				/* finished output layer setup for classification model */
				if _verify_modeling_task_="regression" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

				/* Add a projection layer with Batch Normalization */
				AddLayer result=suppress / model='Xception' name='fclayer1'
				layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
				stride=1 act='elu' dropout=&_tm_projdropoutrate} 
					srcLayers={'final_avepool'};

				/* add new output layer */
				AddLayer result=suppress / model='Xception' name='outlayer'
				layer={type='output' error="&_CV_reg_error" act="&_CV_reg_out_act_function"
				targetStd="&_CV_reg_out_standardization"} srcLayers={'fclayer1'};

				/* change model activation functions */
				_verify_FC_activation_function="&_CV_FC_act_function";
				if _verify_FC_activation_function=11 then
				_new_FC_activation_value_=(string)6;
				if _verify_FC_activation_function ne 11 then
				_new_FC_activation_value_=(string)_verify_FC_activation_function;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_FC_activation_value_}};
				end;
				if _verify_FC_include_ ne "yes" then do;

				/* add new output layer */
				AddLayer result=suppress / model='Xception' name='outlayer'
				layer={type='output' error="&_CV_reg_error" act="&_CV_reg_out_act_function"
				targetStd="&_CV_reg_out_standardization"} srcLayers={'final_avepool'};
				end;
				end;

				/*****************************/
				/* Add multi-task layers */
				/*****************************/
				if _verify_modeling_task_="multitask" then do;
				&_CVdm_addlayercodemultitask;
				end;

				/*********************/
				/*Apply Dropout */
				/*********************/
				_dec_Drop_out_block_1=_decision_Dropoutblock_1_;
				_dec_Drop_out_block_2=_decision_Dropoutblock_2;
				_dec_Drop_out_block_3=_decision_Dropoutblock_3;
				_dec_Drop_out_block_4=_decision_Dropoutblock_4;
				_dec_Drop_out_block_5=_decision_Dropoutblock_5;
				_dec_Drop_out_block_6=_decision_Dropoutblock_6;
				_dec_Drop_out_block_7=_decision_Dropoutblock_7;
				_dec_Drop_out_block_8=_decision_Dropoutblock_8;
				_dec_Drop_out_block_9=_decision_Dropoutblock_9;
				_dec_Drop_out_block__10=_decision_Dropoutblock_10;
				_dec_Drop_out_block__11=_decision_Dropoutblock_11;
				_dec_Drop_out_block__12=_decision_Dropoutblock_12;
				_dec_Drop_out_block__13=_decision_Dropoutblock_13;
				_dec_Drop_out_block__14=_decision_Dropoutblock_14;
				_dec_Drop_out_block__15=_decision_Dropoutblock_15;
				_dec_Drop_out_block__16=_decision_Dropoutblock_16;
				_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
				if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
				_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
				if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
				_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
				if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
				_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_1seperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
				if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
				_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_1seperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
				if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
				_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_2reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
				if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
				_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_3reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
				if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
				_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_4reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
				if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
				_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_5reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
				if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
				_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_6reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
				if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
				_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_7reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
				if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
				_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_8reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
				if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
				_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_9reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
				if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
				_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_10reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
				if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
				_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_11reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
				if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
				_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_12reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;
				if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
				_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'seperablebnrelu_exit1__pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};

				/* change model activation functions */
				_verify_activation_function=_decision_actfunction;
				if _verify_activation_function=11 then _new_activation_value_=(string)6;
				if _verify_activation_function ne 11 then
				_new_activation_value_=(string)_verify_activation_function;
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'reshapeopts.act' and  _DLChrVal_ = 'Rectifier'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				_verify_crop_="&_CV_crop_RESIZE_THENCROP";
				if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;
				if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_mutation_="&_CV_random_mutate";
				if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_mutation_="none" then do;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_fliptype_="&_CV_fliptype_";
				if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				if _verify_fliptype_="horizontal" then do;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_fliptype_="vertical" then do;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
				end;
				if _verify_fliptype_="both" then do;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;

				/* Change the expected input size - height */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_height_"}};

				/* Change the expected input size - width */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_width_"}};

				/* Change the number of channels to match greyscale if condition exist */
				_verify_image_color="&_image_input_color_";

				/* yes no */
				if _verify_image_color="greyscale" then do;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
				end;
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				if _chk_image_height_<244 or _chk_image_width_<244 then do;

				/* Update Stride for last pool layer */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.stride'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.stride_height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.stride_width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
				end;
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="classification" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='Xception'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					/* 						initWeights='Xceptionweights' */
					inputs="&_CV_inpVar_name_"
					target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
					GPU=&_CV_usegpu_T_F
					&_weghtcodtrain_
					nthreads=&n_threads_
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Xception Dropout in input layer back to 0*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;
				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='Xception'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					gpu=&_CV_usegpu_T_F;
				Error1=0+s['ScoreInfo'][3]['Value'];

				/* save best model weights */
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/* End classification model training code  */
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="regression" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='Xception'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					/* 						initWeights='Xceptionweights' */
					inputs="&_CV_inpVar_name_"
					target="&_CV_tarVar_name_"
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for classification model scoring and deployment */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Xception Dropout in input layer back to 0*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='Xception'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					gpu=&_CV_usegpu_T_F;
				Error1=0+s['ScoreInfo'][3]['Value'];

				/* save best model weights */
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/* End regression model training code  */
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression, objectdetection, or multitask */
				if _verify_modeling_task_="multitask" then do;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;
				deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='Xception'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					/* 						initWeights='Xceptionweights' */
					dataSpecs={&_CVdm_dltraincodemultitaskres} GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad} loglevel=1, regL1=_decision_l1reg, 
					regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for classification model scoring and deployment */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Xception Dropout in input layer back to 0*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='Xception'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					GPU=&_CV_usegpu_T_F;
				Error1=0;
				do i=3 to &multaskevals by 1;
				multilossi=0+s['ScoreInfo'][i]['Value'];
				Error1=Error1+0+multilossi;
				end;

				/* save best model weights */
				if _bbEvalTag_=1 and Error1 ne . then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if Error1 ne . then do;
				if Error1 < globalobj then do;
				_holdvalue_=Error1;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=Error1+0;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/* End regression model training code  */
				end;

				/* End Xception model setup */
				table.dropTable / caslib="libCVmod" name="resnet50_caffe" quiet=TRUE;
				table.dropTable / caslib="libCVmod" name="Tiny-Yolov2" quiet=TRUE;
				table.dropTable / caslib="libCVmod" name="ShuffleNetV2" quiet=TRUE;
				table.dropTable / caslib="libCVmod" name="Xception" quiet=TRUE;
				endsource;
				source cvcleanup;
				table.save / Caslib="libres"
				table={name="&_imageDS_", caslib="libres"} name="&_imageDS_..sashdat"
				permission="PUBLICWRITE"
				replace=True;
				table.save / Caslib="libres"
				table={name="objectivefunctionhold", caslib="casuser"} 
					name="objectivefunctionhold"
					permission="PUBLICWRITE"
					replace=True;
				table.dropCaslib result=suppress / caslib="libres" quiet=TRUE;
				endsource;
				_verify_previous_search="&_CV_continue_previous_search";

				/* classification, regression or objectdetection */
				if _verify_previous_search ne "yes" then do;
				optimization.solveblackbox / decVars={{name='_decision_modelbackbone', 
					type='I', lb=_setup_lb_backbone, ub=_setup_ub_backbone, 
					init=_setup_init_backbone} {name='_decision_gamma', type='C', 
					lb=_setup_lb_gamma, ub=_setup_ub_gamma, init=_setup_init_gamma} 
					{name='_decision_stepsize', type='I', lb=_setup_lb_stepsize, 
					ub=_setup_ub_stepsize, init=_setup_init_stepsize} 
					{name='_decision_minibatch', type='I', lb=_setup_lb_miniBSize, 
					ub=_setup_ub_miniBSize, init=_setup_init_miniBSize} {name='_decision_lr', 
					type='C', lb=_setup_lb_lr, ub=_setup_ub_lr, init=_setup_init_lr} 
					{name='_decision_betadiff', type='C', lb=_setup_lb_betadiff, 
					ub=_setup_ub_betadiff, init=_setup_init_betadiff} {name='_decision_l1reg', 
					type='C', lb=_setup_lb_l1reg, ub=_setup_ub_l1reg, init=_setup_init_l1reg} 
					{name='_decision_l2reg', type='C', lb=_setup_lb_l2reg, ub=_setup_ub_l2reg, 
					init=_setup_init_l2reg} {name='_decision_gradclips', type='C', 
					lb=_setup_lb_gradclips, ub=_setup_ub_gradclips, 
					init=_setup_init_gradclips} {name='_decision_actfunction', type='I', 
					lb=_setup_lb_actfunc, ub=_setup_ub_actfunc, init=_setup_init_actfunc} 
					{name='_decision_fconvo_size', type='I', lb=_setup_lb_fconvo_size, 
					ub=_setup_ub_fconvo_size, init=_setup_init_fconvo_size} &_dcodemultitask
					&_dcodeclassreg
					{name='_decision_Dropoutblock_1_', type='I', lb=_setup_lb_Dropoutblock_1, 
					ub=_setup_ub_Dropoutblock_1, init=_setup_init_Dropoutblock_1} 
					{name='_decision_Dropoutblock_2', type='I', lb=_setup_lb_Dropoutblock_2, 
					ub=_setup_ub_Dropoutblock_2, init=_setup_init_Dropoutblock_2} 
					{name='_decision_Dropoutblock_3', type='I', lb=_setup_lb_Dropoutblock_3, 
					ub=_setup_ub_Dropoutblock_3, init=_setup_init_Dropoutblock_3} 
					{name='_decision_Dropoutblock_4', type='I', lb=_setup_lb_Dropoutblock_4, 
					ub=_setup_ub_Dropoutblock_4, init=_setup_init_Dropoutblock_4} 
					{name='_decision_Dropoutblock_5', type='I', lb=_setup_lb_Dropoutblock_5, 
					ub=_setup_ub_Dropoutblock_5, init=_setup_init_Dropoutblock_5} 
					{name='_decision_Dropoutblock_6', type='I', lb=_setup_lb_Dropoutblock_6, 
					ub=_setup_ub_Dropoutblock_6, init=_setup_init_Dropoutblock_6} 
					{name='_decision_Dropoutblock_7', type='I', lb=_setup_lb_Dropoutblock_7, 
					ub=_setup_ub_Dropoutblock_7, init=_setup_init_Dropoutblock_7} 
					{name='_decision_Dropoutblock_8', type='I', lb=_setup_lb_Dropoutblock_8, 
					ub=_setup_ub_Dropoutblock_8, init=_setup_init_Dropoutblock_8} 
					{name='_decision_Dropoutblock_9', type='I', lb=_setup_lb_Dropoutblock_9, 
					ub=_setup_ub_Dropoutblock_9, init=_setup_init_Dropoutblock_9} 
					{name='_decision_Dropoutblock_10', type='I', lb=_setup_lb_Dropoutblock_10, 
					ub=_setup_ub_Dropoutblock_10, init=_setup_init_Dropoutblock_10} 
					{name='_decision_Dropoutblock_11', type='I', lb=_setup_lb_Dropoutblock_11, 
					ub=_setup_ub_Dropoutblock_11, init=_setup_init_Dropoutblock_11} 
					{name='_decision_Dropoutblock_12', type='I', lb=_setup_lb_Dropoutblock_12, 
					ub=_setup_ub_Dropoutblock_12, init=_setup_init_Dropoutblock_12} 
					{name='_decision_Dropoutblock_13', type='I', lb=_setup_lb_Dropoutblock_13, 
					ub=_setup_ub_Dropoutblock_13, init=_setup_init_Dropoutblock_13} 
					{name='_decision_Dropoutblock_14', type='I', lb=_setup_lb_Dropoutblock_14, 
					ub=_setup_ub_Dropoutblock_14, init=_setup_init_Dropoutblock_14} 
					{name='_decision_Dropoutblock_15', type='I', lb=_setup_lb_Dropoutblock_15, 
					ub=_setup_ub_Dropoutblock_15, init=_setup_init_Dropoutblock_15} 
					{name='_decision_Dropoutblock_16', type='I', lb=_setup_lb_Dropoutblock_16, 
					ub=_setup_ub_Dropoutblock_16, init=_setup_init_Dropoutblock_16}}, 
					obj={{name='objVal', type='min'}}, outputTables={includeall=true} 
					display={excludeAll=FALSE} primalOut={name='primal_out', replace=TRUE} 
					CACHEOUT={name="_temp_ds_results_", replace=true, caslib="casuser"} 
					func={init=caslInit, eval=evalcode, cleanup=cvcleanup}, nParallel=1, 
					popsize=&_CV_population_s, nlocal=&_CV_gsslocal_s, 
					maxGen=&_CV_gagenerations_s, nabsfconv=100000000, maxtime=&_CV_maxtraintime
					Seed=&_CV_autotuneseed;
				end;
				_verify_previous_search="&_CV_continue_previous_search";

				/* classification, regression or objectdetection */
				if _verify_previous_search="yes" then do;
				optimization.solveblackbox / decVars={{name='_decision_modelbackbone', 
					type='I', lb=_setup_lb_backbone, ub=_setup_ub_backbone, 
					init=_setup_init_backbone} {name='_decision_gamma', type='C', 
					lb=_setup_lb_gamma, ub=_setup_ub_gamma, init=_setup_init_gamma} 
					{name='_decision_stepsize', type='I', lb=_setup_lb_stepsize, 
					ub=_setup_ub_stepsize, init=_setup_init_stepsize} 
					{name='_decision_minibatch', type='I', lb=_setup_lb_miniBSize, 
					ub=_setup_ub_miniBSize, init=_setup_init_miniBSize} {name='_decision_lr', 
					type='C', lb=_setup_lb_lr, ub=_setup_ub_lr, init=_setup_init_lr} 
					{name='_decision_betadiff', type='C', lb=_setup_lb_betadiff, 
					ub=_setup_ub_betadiff, init=_setup_init_betadiff} {name='_decision_l1reg', 
					type='C', lb=_setup_lb_l1reg, ub=_setup_ub_l1reg, init=_setup_init_l1reg} 
					{name='_decision_l2reg', type='C', lb=_setup_lb_l2reg, ub=_setup_ub_l2reg, 
					init=_setup_init_l2reg} {name='_decision_actfunction', type='I', 
					lb=_setup_lb_actfunc, ub=_setup_ub_actfunc, init=_setup_init_actfunc} 
					{name='_decision_gradclips', type='C', lb=_setup_lb_gradclips, 
					ub=_setup_ub_gradclips, init=_setup_init_gradclips} &_dcodemultitask
					&_dcodeclassreg
					{name='_decision_fconvo_size', type='I', lb=_setup_lb_fconvo_size, 
					ub=_setup_ub_fconvo_size, init=_setup_init_fconvo_size} 
					{name='_decision_Dropoutblock_1_', type='I', lb=_setup_lb_Dropoutblock_1, 
					ub=_setup_ub_Dropoutblock_1, init=_setup_init_Dropoutblock_1} 
					{name='_decision_Dropoutblock_2', type='I', lb=_setup_lb_Dropoutblock_2, 
					ub=_setup_ub_Dropoutblock_2, init=_setup_init_Dropoutblock_2} 
					{name='_decision_Dropoutblock_3', type='I', lb=_setup_lb_Dropoutblock_3, 
					ub=_setup_ub_Dropoutblock_3, init=_setup_init_Dropoutblock_3} 
					{name='_decision_Dropoutblock_4', type='I', lb=_setup_lb_Dropoutblock_4, 
					ub=_setup_ub_Dropoutblock_4, init=_setup_init_Dropoutblock_4} 
					{name='_decision_Dropoutblock_5', type='I', lb=_setup_lb_Dropoutblock_5, 
					ub=_setup_ub_Dropoutblock_5, init=_setup_init_Dropoutblock_5} 
					{name='_decision_Dropoutblock_6', type='I', lb=_setup_lb_Dropoutblock_6, 
					ub=_setup_ub_Dropoutblock_6, init=_setup_init_Dropoutblock_6} 
					{name='_decision_Dropoutblock_7', type='I', lb=_setup_lb_Dropoutblock_7, 
					ub=_setup_ub_Dropoutblock_7, init=_setup_init_Dropoutblock_7} 
					{name='_decision_Dropoutblock_8', type='I', lb=_setup_lb_Dropoutblock_8, 
					ub=_setup_ub_Dropoutblock_8, init=_setup_init_Dropoutblock_8} 
					{name='_decision_Dropoutblock_9', type='I', lb=_setup_lb_Dropoutblock_9, 
					ub=_setup_ub_Dropoutblock_9, init=_setup_init_Dropoutblock_9} 
					{name='_decision_Dropoutblock_10', type='I', lb=_setup_lb_Dropoutblock_10, 
					ub=_setup_ub_Dropoutblock_10, init=_setup_init_Dropoutblock_10} 
					{name='_decision_Dropoutblock_11', type='I', lb=_setup_lb_Dropoutblock_11, 
					ub=_setup_ub_Dropoutblock_11, init=_setup_init_Dropoutblock_11} 
					{name='_decision_Dropoutblock_12', type='I', lb=_setup_lb_Dropoutblock_12, 
					ub=_setup_ub_Dropoutblock_12, init=_setup_init_Dropoutblock_12} 
					{name='_decision_Dropoutblock_13', type='I', lb=_setup_lb_Dropoutblock_13, 
					ub=_setup_ub_Dropoutblock_13, init=_setup_init_Dropoutblock_13} 
					{name='_decision_Dropoutblock_14', type='I', lb=_setup_lb_Dropoutblock_14, 
					ub=_setup_ub_Dropoutblock_14, init=_setup_init_Dropoutblock_14} 
					{name='_decision_Dropoutblock_15', type='I', lb=_setup_lb_Dropoutblock_15, 
					ub=_setup_ub_Dropoutblock_15, init=_setup_init_Dropoutblock_15} 
					{name='_decision_Dropoutblock_16', type='I', lb=_setup_lb_Dropoutblock_16, 
					ub=_setup_ub_Dropoutblock_16, init=_setup_init_Dropoutblock_16}}, 
					obj={{name='objVal', type='min'}}, outputTables={includeall=true} 
					display={excludeAll=FALSE} primalOut={name='primal_out', replace=TRUE} 
					CACHEIN={name='_Cachein_table', caslib="casuser"} 
					firstgen={name='_firstgen_table', caslib="casuser"} 
					CACHEOUT={name="_temp_ds_results_", replace=true, caslib="casuser"} 
					func={init=caslInit, eval=evalcode, cleanup=cvcleanup}, nParallel=1, 
					popsize=&_CV_population_s, nlocal=&_CV_gsslocal_s, 
					maxGen=&_CV_gagenerations_s, nabsfconv=100000000, maxtime=&_CV_maxtraintime
					Seed=&_CV_autotuneseed;
				end;
				end;

				/******************************/
				/* Begin Object _Detection_		*/
				/******************************/
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				if _verify_modeling_task_="objectdetection" then do;
				source caslInit;
				loadactionset 'deeplearn';
				loadactionset 'image';
				loadactionset 'table';
				loadactionset 'sampling';
				table.addCasLib result=suppress / name="libres", 
					path="&_CV_location_for_results_data" subdirectories=true;
				table.addCasLib result=suppress / name='libCVmod', 
					path="&_CV_CVmodel_location" subdirectories=true;
				filename="&_CV_location_for_results_data" || "/init.txt";
				file nodes filename;
				table.loadTable / caslib='libres', path="&_imageDS_..sashdat"
				casOut={name="&_imageDS_", replace=true, caslib='libres'} 
					importOptions={fileType="HDAT"};
				name="_Object";
				appendNames={"_", "_x", "_y", "_width", "_height"};
				_ObjectTargets_={"_nObjects_"};
				i=0;
				do until (i=&_CV_object_num_);
				do col over appendNames;
				value=name || i || col;
				_ObjectTargets_=_ObjectTargets_ + value;
				end;
				i=i+1;
				end;
				/*break data apart to prevent memory overload*/
			action sampling.srs result=suppress / table={name="&_imageDS_", caslib="libres"} 
				samppct=33
				sampPct2=33
				seed=12345
				partInd=true
				output={casout={name="&_imageDS_", replace="TRUE", caslib="libres"}, copyvars="ALL", 
				partIndName="_only1_3_sample_"};


				image.processImages result=suppress / casout={name="&_imageDS_.v0", replace=1, 
					caslib="libres"} 
					copyVars=_ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", imageTable={name="&_imageDS_", caslib="libres", where="_only1_3_sample_=0"} 
					imageFunctions={{functionOptions={functionType='RESIZE', 
					height=&_image_input_height_, width=&_image_input_width_}}};
				_verify_image_color="&_image_input_color_";
				if _verify_image_color="greyscale" then do;
				image.processImages result=suppress / casout={name="&_imageDS_.v0", 
					replace=True, caslib="libres"} copyVars=ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", 
					imagefunctions={{functionOptions={functionType='CONVERT_COLOR'
					type="COLOR2GRAY"}}} table={name="&_imageDS_.v0", caslib="libres"};
				end;

				image.processImages result=suppress / casout={name="&_imageDS_.v1", replace=1, 
					caslib="libres"} 
					copyVars=_ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", imageTable={name="&_imageDS_", caslib="libres", where="_only1_3_sample_=1"} 
					imageFunctions={{functionOptions={functionType='RESIZE', 
					height=&_image_input_height_, width=&_image_input_width_}}};
				_verify_image_color="&_image_input_color_";
				if _verify_image_color="greyscale" then do;
				image.processImages result=suppress / casout={name="&_imageDS_.v1", 
					replace=True, caslib="libres"} copyVars=ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", 
					imagefunctions={{functionOptions={functionType='CONVERT_COLOR'
					type="COLOR2GRAY"}}} table={name="&_imageDS_.v1", caslib="libres"};
				end;

				image.processImages result=suppress / casout={name="&_imageDS_.v2", replace=1, 
					caslib="libres"} 
					copyVars=_ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", imageTable={name="&_imageDS_", caslib="libres", where="_only1_3_sample_=2"} 
					imageFunctions={{functionOptions={functionType='RESIZE', 
					height=&_image_input_height_, width=&_image_input_width_}}};
				_verify_image_color="&_image_input_color_";
				if _verify_image_color="greyscale" then do;
				image.processImages result=suppress / casout={name="&_imageDS_.v2", 
					replace=True, caslib="libres"} copyVars=ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", 
					imagefunctions={{functionOptions={functionType='CONVERT_COLOR'
					type="COLOR2GRAY"}}} table={name="&_imageDS_.v2", caslib="libres"};
				end;

				deepLearn.dlJoin /                                 
				annotatedTable={name="&_imageDS_.v1", caslib="libres"}
				casOut={name="&_imageDS_.v0_1", caslib="libres", replace=1}
				joinType="Append"
				table={name="&_imageDS_.v0", caslib="libres"};

				table.dropTable / caslib="libres", name="&_imageDS_.v0", quiet=TRUE;
				table.dropTable / caslib="libres", name="&_imageDS_.v1", quiet=TRUE;

				deepLearn.dlJoin /                                 
				annotatedTable={name="&_imageDS_.v2", caslib="libres"}
				casOut={name="&_imageDS_", caslib="libres", replace=1}
				joinType="Append"
				table={name="&_imageDS_.v0_1", caslib="libres"};

				table.dropTable / caslib="libres", name="&_imageDS_.v0_1", quiet=TRUE;
				table.dropTable / caslib="libres", name="&_imageDS_.v2", quiet=TRUE;

				table.alterTable / caslib="libres", name="&_imageDS_", drop="_only1_3_sample_";

				/*DONE: breaking data apart to prevent memory overload*/
				_set_train_sample_percent_=100-&_CV_valid_partition_per_;

				/* Create sample for localization model */
				action sampling.srs result=suppress / table={name="&_imageDS_", caslib="libres"} 
					samppct=_set_train_sample_percent_
					sampPct2=&_CV_valid_partition_per_ seed=&_CV_partition_seed partInd=true
					output={casout={name="&_imageDS_", replace="TRUE", caslib="libres", 
					replication=0, maxMemSize=200G, compress=TRUE}, copyvars="ALL", 
					partIndName="&_CV_partition_var_"};

				/* Shuffle data per good practice */
				table.shuffle result=suppress / table={name="&_imageDS_", caslib="libres"} 
					casout={name="&_imageDS_", replace=1, caslib="libres", replication=0, 
					maxMemSize=200G, compress=TRUE};
				;

				/*************************************************/
				/* Ensure consistent format across object vars */
				/*************************************************/
				if &_insert_OD_classcount > 1 then do;
				table.shuffle / table={name="&_imageDS_", caslib="libres", 
					computedVars={{name="_uniqueid_"}}, computedVarsProgram="_uniqueid_=left(strip(idjoin))||left(strip(_size_))||left(strip(put(_threadid_,8.)))||strip(trim(Put(_n_,8.)));"} 
					casout={name='imgdata_w_id', replace=true, caslib="casuser", 
					replication=0, maxMemSize=200G, compress=TRUE};
				table.dropTable / caslib="libres", name="&_imageDS_", quiet=TRUE;
				table.copyTable / table={name='imgdata_w_id', caslib="casuser"} 
					casout={name="imgdata_w_id_copy" caslib="casuser", replace=1, 
					replication=0, maxMemSize=200G, compress=TRUE};
				table.alterTable / name="imgdata_w_id_copy" caslib="casuser"
				keep={"_uniqueid_", "_image_"};
				table.alterTable / name="imgdata_w_id" caslib="casuser"
				drop={"_image_"};
				tbl={name='imgdata_w_id', caslib='casuser'};
				table.columnInfo result=ci / table=tbl;

				/* Get all varchar and char columns */
				rtbl=ci
				.ColumnInfo[, {"Column", "Type", "rawLength"}] 
					.where(lowcase(Type)='varchar');

				/* Find the max length of a char or varchar column */
				maxCharLength=max(rtbl[, 'rawLength']);

				/* Makes them all CHAR, so if there is varchar an if condition will be required */
				lengthStatement='length ';
				do colName over getcolumn(rtbl, 'column');
				LengthStatement=cat(lengthStatement, colName, cat(' varchar(', 
					maxCharLength, ') '));
				end;
				LengthStatement=cat(" ", lengthStatement, '; ');
				print LengthStatement;

				/* Add dynamic length statement from loop */
				createNewCasTable=tranwrd("&_CVdm_odfixformatsv2", '$AddLengthStatement', 
					LengthStatement);
				print createNewCasTable;
				call symputx('_CVdm_odfixformatsv2c', createNewCasTable, 'L');
				run;

				/* Run the code */
				dataStep.runCode / 
					code="&_CVdm_odfixformatsv1"|| createNewCasTable || "&_CVdm_odfixformatsv3";
				deepLearn.dlJoin / annotatedTable={name="new_cas_table_maxLengths", 
					caslib="casuser"} casOut={name="&_imageDS_", caslib="libres", replace=1, 
					replication=0, maxMemSize=200G, compress=TRUE} id="_uniqueid_"
					table={name="imgdata_w_id_copy", caslib="casuser"};
				table.dropTable / caslib="casuser", name="imgdata_w_id_copy", quiet=TRUE;
				table.dropTable / caslib="casuser", name="new_cas_table_maxLengths", 
					quiet=TRUE;

				/* 	table.dropTable / */
				/* 				caslib="casuser", */
				/* 				name="imgdata_w_id", */
				/* 				quiet=TRUE; */
				end;
				_verify_modelbackbone_="&_CV_modelBackbone_";
				if _tm_warmstart ne 1 then do;
				if _verify_modelbackbone_="autotune" then do;
				table.loadTable /caslib='libCVmod', path='resnet50_caffe_weights.sashdat'
				casOut={name='resnet50_caffe_weights', replace=true};
				table.loadTable /caslib='libCVmod', 
					path='resnet50_caffe_weights_attr.sashdat'
					casOut={name='resnet50_caffe_weights_attr', replace=true};
				table.attribute / task='add' name='resnet50_caffe_weights'
				table='resnet50_caffe_weights_attr';
				table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights.sashdat'
				casOut={name='Tiny-Yolov2_weights', replace=true};
				table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights_attr.sashdat'
				casOut={name='Tiny-Yolov2_weights_attr', replace=true};
				table.attribute / task='add' name='Tiny-Yolov2_weights'
				table='Tiny-Yolov2_weights_attr';
				table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights.sashdat'
				casOut={name='ShuffleNetV2_weights', replace=true};
				table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights_attr.sashdat'
				casOut={name='ShuffleNetV2_weights_attr', replace=true};
				table.attribute / task='add' name='ShuffleNetV2_weights'
				table='ShuffleNetV2_weights_attr';

				/* NOTE: Using random weights for XceptionNet*/
				end;
				if _verify_modelbackbone_="resnet50_caffe" then do;
				table.loadTable /caslib='libCVmod', path='resnet50_caffe_weights.sashdat'
				casOut={name='resnet50_caffe_weights', replace=true};
				table.loadTable /caslib='libCVmod', 
					path='resnet50_caffe_weights_attr.sashdat'
					casOut={name='resnet50_caffe_weights_attr', replace=true};
				table.attribute / task='add' name='resnet50_caffe_weights'
				table='resnet50_caffe_weights_attr';
				end;
				if _verify_modelbackbone_="Tiny-Yolov2" then do;
				table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights.sashdat'
				casOut={name='Tiny-Yolov2_weights', replace=true};
				table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights_attr.sashdat'
				casOut={name='Tiny-Yolov2_weights_attr', replace=true};
				table.attribute / task='add' name='Tiny-Yolov2_weights'
				table='Tiny-Yolov2_weights_attr';
				end;
				if _verify_modelbackbone_="ShuffleNetV2" or
				_verify_modelbackbone_="ShuffleNetV2_x15" or
				_verify_modelbackbone_="ShuffleNetV2_x20" or
				_verify_modelbackbone_="ShuffleNetV2_x25" then do;
				table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights.sashdat'
				casOut={name='ShuffleNetV2_weights', replace=true};
				table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights_attr.sashdat'
				casOut={name='ShuffleNetV2_weights_attr', replace=true};
				table.attribute / task='add' name='ShuffleNetV2_weights'
				table='ShuffleNetV2_weights_attr';
				end;

				/* NOTE: Using random weights for XceptionNet*/
				end;
				if _tm_warmstart=1 then do;
				_verify_ws_modelbbone_="&_tm_wsbackbone";
				if _verify_ws_modelbbone_="resnet50_caffe" then do;
				table.loadTable /caslib='libres', path='autotune_bestweights_.sashdat'
				casOut={name='resnet50_caffe_weights', replace=true};
				table.loadTable /caslib='libres', path='autotune_bestweights_.ATTRS.sashdat'
				casOut={name='resnet50_caffe_weights_attr', replace=true};
				table.attribute / task='add' name='resnet50_caffe_weights'
				table='resnet50_caffe_weights_attr';
				end;
				if _verify_ws_modelbbone_="Tiny-Yolov2" then do;
				table.loadTable /caslib='libres', path='autotune_bestweights_.sashdat'
				casOut={name='Tiny-Yolov2_weights', replace=true};
				table.loadTable /caslib='libres', path='autotune_bestweights_.ATTRS.sashdat'
				casOut={name='Tiny-Yolov2_weights_attr', replace=true};
				table.attribute / task='add' name='Tiny-Yolov2_weights'
				table='Tiny-Yolov2_weights_attr';
				end;
				if _verify_ws_modelbbone_="ShuffleNetV2" or
				_verify_ws_modelbbone_="ShuffleNetV2_x15" or
				_verify_ws_modelbbone_="ShuffleNetV2_x20" or
				_verify_ws_modelbbone_="ShuffleNetV2_x25" then do;
				table.loadTable /caslib='libres', path='autotune_bestweights_.sashdat'
				casOut={name='ShuffleNetV2_weights', replace=true};
				table.loadTable /caslib='libres', path='autotune_bestweights_.ATTRS.sashdat'
				casOut={name='ShuffleNetV2_weights_attr', replace=true};
				table.attribute / task='add' name='ShuffleNetV2_weights'
				table='ShuffleNetV2_weights_attr';
				end;
				end;
				table.dropTable / caslib="casuser" name="objectivefunctionhold" quiet=TRUE;
				datastep.runCode / 
					code="
data casuser.objectivefunctionhold;
currentobj=99999999;
run;
";
				endsource;
				source evalcode;
				filename="&_CV_location_for_results_data" || "/" || (String)_bbEvalTag_ || ".txt";
				file nodes filename;

				/* Set first convo filter size */
				if _decision_fconvo_size=1 then do;
				_CV_firstConvo_width=3+0;
				_CV_firstConvo_height=3+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
				end;
				if _decision_fconvo_size=2 then do;
				_CV_firstConvo_width=3+0;
				_CV_firstConvo_height=5+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
				end;
				if _decision_fconvo_size=3 then do;
				_CV_firstConvo_width=5+0;
				_CV_firstConvo_height=3+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
				end;
				if _decision_fconvo_size=4 then do;
				_CV_firstConvo_width=5+0;
				_CV_firstConvo_height=5+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
				end;
				if _decision_fconvo_size=5 then do;
				_CV_firstConvo_width=5+0;
				_CV_firstConvo_height=7+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
				end;
				if _decision_fconvo_size=6 then do;
				_CV_firstConvo_width=7+0;
				_CV_firstConvo_height=5+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
				end;
				if _decision_fconvo_size=7 then do;
				_CV_firstConvo_width=7+0;
				_CV_firstConvo_height=7+0;
				_CV_firstConvo_width=(string)_CV_firstConvo_width;
				_CV_firstConvo_height=(string)_CV_firstConvo_height;
				end;

				/*********************/
				/*Setup to apply Dropout */
				/*********************/
				_dec_Drop_out_block_1=_decision_Dropoutblock_1_;
				_dec_Drop_out_block_2=_decision_Dropoutblock_2;
				_dec_Drop_out_block_3=_decision_Dropoutblock_3;
				_dec_Drop_out_block_4=_decision_Dropoutblock_4;
				_dec_Drop_out_block_5=_decision_Dropoutblock_5;
				_dec_Drop_out_block_6=_decision_Dropoutblock_6;
				_dec_Drop_out_block_7=_decision_Dropoutblock_7;
				_dec_Drop_out_block_8=_decision_Dropoutblock_8;
				_dec_Drop_out_block_9=_decision_Dropoutblock_9;
				_dec_Drop_out_block__10=_decision_Dropoutblock_10;
				_dec_Drop_out_block__11=_decision_Dropoutblock_11;
				_dec_Drop_out_block__12=_decision_Dropoutblock_12;
				_dec_Drop_out_block__13=_decision_Dropoutblock_13;
				_dec_Drop_out_block__14=_decision_Dropoutblock_14;
				_dec_Drop_out_block__15=_decision_Dropoutblock_15;
				_dec_Drop_out_block__16=_decision_Dropoutblock_16;
				name="_Object";
				appendNames={"_", "_x", "_y", "_width", "_height"};
				_ObjectTargets_={"_nObjects_"};
				i=0;
				do until (i=&_CV_object_num_);
				do col over appendNames;
				value=name || i || col;
				_ObjectTargets_=_ObjectTargets_ + value;
				end;
				i=i+1;
				end;
				_verify_modelbackbone_="&_CV_modelBackbone_";
				if _verify_modelbackbone_="autotune" then do;
				if _decision_modelbackbone=1 then _verify_modelbackbone_="resnet50_caffe";
				if _decision_modelbackbone=2 then _verify_modelbackbone_="Tiny-Yolov2";
				if _decision_modelbackbone=3 then _verify_modelbackbone_="ShuffleNetV2";
				if _decision_modelbackbone=4 then _verify_modelbackbone_="ShuffleNetV2_x15";
				if _decision_modelbackbone=5 then _verify_modelbackbone_="ShuffleNetV2_x20";
				if _decision_modelbackbone=6 then _verify_modelbackbone_="ShuffleNetV2_x25";
				if _decision_modelbackbone=7 then _verify_modelbackbone_="Xception";
				end;

				/*********************************/
				/* ResNet50 for Object Detection */
				/*********************************/
				if _verify_modelbackbone_="resnet50_caffe" then do;
				table.loadTable /caslib='libCVmod', path='resnet50_caffe.sashdat'
				casOut={name='resnet50_caffe', replace=true};

				/*ResNet Apply Dropout to input layer*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

				/* remove current output layer */
				removelayer result=suppress / model='resnet50_caffe' name='fc1000';

				/* remove pool layer before output because task=object detection */
				removelayer result=suppress / model='resnet50_caffe' name='pool5';

				/* Adjust first convo layer filter sizes */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};

				/* add new output layer */
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				run;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.no_bias'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};

				/*********************/
				/*Apply Dropout */
				/*********************/
				verify_apply_dropout="&_CV_dropValue";
				_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
				if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
				_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2a_branch1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
				if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
				_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
				if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
				_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res2c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
				if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
				_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3a_branch1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
				if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
				_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
				if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
				_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
				if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
				_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3d_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3d_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res3d_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
				if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
				_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4a_branch1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
				if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
				_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
				if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
				_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
				if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
				_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4d_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4d_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4d_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
				if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
				_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4e_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4e_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4e_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
				if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
				_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4f_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4f_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res4f_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
				if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
				_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5a_branch1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
				if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
				_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;
				if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
				_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'res5c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				%put RobertApril: preds per grid: &_CV_OD_preds_per_grid;
				%put RobertApril: class num: &_CV_OD_class_num;
				_OD_depth=&_CV_OD_preds_per_grid * (&_CV_OD_class_num + 5)+0;
				print "RobertApril" _OD_depth;
				AddLayer result=suppress / model='resnet50_caffe' name='_convolast_'
				layer={type='CONVO'
				nFilters=_OD_depth width=_decision_lc_width_ height=_decision_lc_height_
				stride=1 act='identity' includeBias=FALSE} srcLayers={'res5c'};

				/* change model activation functions */
				_verify_activation_function=_decision_actfunction;
				if _verify_activation_function=11 then _new_activation_value_=(string)6;
				if _verify_activation_function ne 11 then
				_new_activation_value_=(string)_verify_activation_function;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				_update_grid_size=0+0;
				if _chk_image_height_=224 or _chk_image_width_=224 then _update_grid_size=7;
				if _chk_image_height_=416 or _chk_image_width_=416 then
				_update_grid_size=13;
				if _chk_image_height_=640 or _chk_image_width_=640 then
				_update_grid_size=20;
				if _chk_image_height_=1280 or _chk_image_width_=1280 then
				_update_grid_size=40;
				AddLayer result=suppress / model='resnet50_caffe'
				name='detection1' layer={type='detection'
				detectionModelType="YOLOV2"
				classNumber=&_CV_OD_class_num
				gridNumber=_update_grid_size
				coordNumber=4
				predictionsPerGrid=&_CV_OD_preds_per_grid
				anchors={&anchor_box_coord} softMaxForClassProb=True

				/* Error function scalers: */
				objectScale=_decision_obj_scale
				predictionNotAObjectScale=_decision_noobj_scale
				classScale=_decision_class_scale
				coordScale=_decision_coord_scale
				maxLabelPerImage=&_CV_object_num_

				/* end, error function scalers */
				coordType="YOLO"

				/* Prediction thresholds */
				detectionThreshold=_decision_detthreshold
				iouThreshold=_decision_iouthreshold
				trainIouThreshold=_decision_trainiou} srcLayers={'_convolast_'};
				_verify_crop_="&_CV_crop_RESIZE_THENCROP";
				if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;
				if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_mutation_="&_CV_random_mutate";
				if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_mutation_="none" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_fliptype_="&_CV_fliptype_";
				if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				if _verify_fliptype_="horizontal" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_fliptype_="vertical" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
				end;
				if _verify_fliptype_="both" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;

				/* Change the expected input size - height */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_height_"}};

				/* Change the expected input size - width */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_width_"}};

				/* Change the number of channels to match greyscale if condition exist */
				_verify_image_color="&_image_input_color_";
				if _verify_image_color="greyscale" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
				end;
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				_verify_modeling_task_="&_CV_modeltask_";

				/* classification, regression or objectdetection */
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;

				/*begin Resnet for object detection*/
				deeplearn.dlTrain result=t / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='resnet50_caffe'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='resnet50_caffe_weights'
					dataSpecs={{data=_ObjectTargets_, layer='detection1', 
					type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_

					/* 		weight="weight" */
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad}, ignoreTrainingError=true, loglevel=1, 
					regL1=_decision_l1reg, regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} 
					seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove dropout */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='resnet50_caffe'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					GPU=&_CV_usegpu_T_F;
				_temp_num_eval_epochs=ceil(&_CV_eval_epochs/5);
				k1_Error=0;
				do i=&_CV_eval_epochs to _temp_num_eval_epochs by -1;
				vfitErrori=0+t['OptIterHistory'][i]['ValidError'];
				k1_Error=k1_Error+0+vfitErrori;
				end;
				k1_Loss_error=(k1_Error/ceil(&_CV_eval_epochs/5));
				k1_iouassessment=0+s['ScoreInfo'][3]['Value'];
				k1_iou_assessment_v2=1-k1_iouassessment;
				k1_final_error=(k1_iou_assessment_v2+k1_Loss_error)/2;

				/* save best model weights */
				if _bbEvalTag_=1 and k1_final_error ne . then do;
				_holdvalue_=k1_final_error;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if k1_final_error ne . then do;
				if k1_final_error <=globalobj then do;
				_holdvalue_=k1_final_error;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=k1_final_error;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/************************************/
				/* tiny-YOLOv2 for Object detection */
				/************************************/
				_verify_modelbackbone_="&_CV_modelBackbone_";
				if _verify_modelbackbone_="autotune" then do;
				if _decision_modelbackbone=1 then _verify_modelbackbone_="resnet50_caffe";
				if _decision_modelbackbone=2 then _verify_modelbackbone_="Tiny-Yolov2";
				if _decision_modelbackbone=3 then _verify_modelbackbone_="ShuffleNetV2";
				if _decision_modelbackbone=4 then _verify_modelbackbone_="ShuffleNetV2_x15";
				if _decision_modelbackbone=5 then _verify_modelbackbone_="ShuffleNetV2_x20";
				if _decision_modelbackbone=6 then _verify_modelbackbone_="ShuffleNetV2_x25";
				if _decision_modelbackbone=7 then _verify_modelbackbone_="Xception";
				end;
				if _verify_modelbackbone_="Tiny-Yolov2" then do;
				table.loadTable /caslib='libCVmod', path='Tiny-Yolov2.sashdat'
				casOut={name='Tiny-Yolov2', replace=true};

				/*ResNet Apply Dropout to input layer*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

				removelayer result=suppress / model='Tiny-Yolov2' name='detection1';

				/* Adjust first convo layer filter sizes */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				%put RobertApril: preds per grid: &_CV_OD_preds_per_grid;
				%put RobertApril: class num: &_CV_OD_class_num;
				_OD_depth=&_CV_OD_preds_per_grid * (&_CV_OD_class_num + 5)+0;
				print "RobertApril" _OD_depth;
				AddLayer result=suppress / model='Tiny-Yolov2' name='_convolast_'
				layer={type='CONVO'
				nFilters=_OD_depth width=_decision_lc_width_ height=_decision_lc_height_
				stride=1 act='identity' includeBias=FALSE} srcLayers={'convo.9'};

				/* change model activation functions */
				_verify_activation_function=_decision_actfunction;
				if _verify_activation_function=11 then _new_activation_value_=(string)6;
				if _verify_activation_function ne 11 then
				_new_activation_value_=(string)_verify_activation_function;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Leaky Activation Function'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.9' and  _DLKey1_ = 'convopts.act'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				_update_grid_size=0+0;
				if _chk_image_height_=224 or _chk_image_width_=224 then _update_grid_size=7;
				if _chk_image_height_=416 or _chk_image_width_=416 then
				_update_grid_size=13;
				if _chk_image_height_=640 or _chk_image_width_=640 then
				_update_grid_size=20;
				if _chk_image_height_=1280 or _chk_image_width_=1280 then
				_update_grid_size=40;
				AddLayer result=suppress / model='Tiny-Yolov2'
				name='detection1' layer={type='detection'
				detectionModelType="YOLOV2"
				classNumber=&_CV_OD_class_num
				gridNumber=_update_grid_size
				coordNumber=4
				predictionsPerGrid=&_CV_OD_preds_per_grid
				anchors={&anchor_box_coord} softMaxForClassProb=True

				/* Error function scalers: */
				objectScale=_decision_obj_scale
				predictionNotAObjectScale=_decision_noobj_scale
				classScale=_decision_class_scale
				coordScale=_decision_coord_scale
				maxLabelPerImage=&_CV_object_num_

				/* end, error function scalers */
				coordType="YOLO"

				/* Prediction thresholds */
				detectionThreshold=_decision_detthreshold
				iouThreshold=_decision_iouthreshold
				trainIouThreshold=_decision_trainiou} srcLayers={'_convolast_'};
				verify_apply_dropout="&_CV_dropValue";

				/* if verify_apply_dropout="yes" then do; */
				_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
				if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
				_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
				if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
				_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool1' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
				if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
				_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.2' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
				if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
				_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool2' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
				if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
				_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.3' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
				if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
				_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool3' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
				if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
				_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.4' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
				if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
				_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool4' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
				if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
				_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.5' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
				if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
				_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
				if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
				_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.6' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
				if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
				_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'pool6' and  _DLKey1_ = 'poolingopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
				if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
				_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.7' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
				if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
				_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.8' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
				if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
				_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'convo.9' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				_verify_crop_="&_CV_crop_RESIZE_THENCROP";
				if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;
				if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_mutation_="&_CV_random_mutate";
				if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_fliptype_="&_CV_fliptype_";
				if _verify_fliptype_="none" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				if _verify_fliptype_="horizontal" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_fliptype_="vertical" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
				end;
				if _verify_fliptype_="both" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;

				/* Change the expected input size - height */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_height_"}};

				/* Change the expected input size - width */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_width_"}};

				/* Change the number of channels to match greyscale if condition exist */
				_verify_image_color="&_image_input_color_";

				/* yes no */
				if _verify_image_color="greyscale" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
				end;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;

				/*begin tiny-yolov2 for object detection*/
				deeplearn.dlTrain result=t / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='Tiny-Yolov2'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='Tiny-Yolov2_weights'
					dataSpecs={{data=_ObjectTargets_, layer='detection1', 
					type='OBJECTDETECTION'} {data={'_image_'}, layer='input1', type='IMAGE'}} 
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_

					/* 		nthreads=32 */
					/* 		weight="weight" */
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad}, ignoreTrainingError=true, loglevel=1, 
					regL1=_decision_l1reg, regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} 
					seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/*remove dropout*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'poolingopts.dropout' or  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='Tiny-Yolov2'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					GPU=&_CV_usegpu_T_F;
				_temp_num_eval_epochs=ceil(&_CV_eval_epochs/5);
				k1_Error=0;
				do i=&_CV_eval_epochs to _temp_num_eval_epochs by -1;
				vfitErrori=0+t['OptIterHistory'][i]['ValidError'];
				k1_Error=k1_Error+0+vfitErrori;

				/*i=i-1;*/
				/*Robert to vet this change */
				end;
				k1_Loss_error=(k1_Error/ceil(&_CV_eval_epochs/5));
				k1_iouassessment=0+s['ScoreInfo'][3]['Value'];
				k1_iou_assessment_v2=1-k1_iouassessment;
				k1_final_error=(k1_iou_assessment_v2+k1_Loss_error)/2;

				/* save best model weights */
				if _bbEvalTag_=1 and k1_final_error ne . then do;
				_holdvalue_=k1_final_error;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if k1_final_error ne . then do;
				if k1_final_error <=globalobj then do;
				_holdvalue_=k1_final_error;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=k1_final_error;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/****************************************/
				/* ShuffleNetV2 Object Detection		*/
				/****************************************/
				if _verify_modelbackbone_="ShuffleNetV2" or
				_verify_modelbackbone_="ShuffleNetV2_x15" or
				_verify_modelbackbone_="ShuffleNetV2_x20" or
				_verify_modelbackbone_="ShuffleNetV2_x25" then do;
				table.loadTable /caslib='libCVmod', path='ShuffleNetV2.sashdat'
				casOut={name='ShuffleNetV2', replace=true};
				/*ShuffleNetV2 Apply Dropout to input layer*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

				/* remove current output layer */
				removelayer result=suppress / model='ShuffleNetV2' name='outputlayer_2';
				removelayer result=suppress / model='ShuffleNetV2' name='global_avg_pool';
				removelayer result=suppress / model='ShuffleNetV2' name='bn_1x1conv5_out';

				/*adjust complexcity of shuffleNet*/
				if _decision_modelbackbone=4 then do;

				/* Adjust the model complexity */
				/*352.00 to 704.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="704.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="704.00"}};

				/*176.00 to 352.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="352.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="352.00"}};

				/*88.00 to 176.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="176.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="176.00"}};
				end;
				if _decision_modelbackbone=5 then do;

				/* Adjust the model complexity */
				/*352.00 to 976.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="976.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="976.00"}};

				/*176.00 to 488.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="488.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="488.00"}};

				/*88.00 to 244.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="244.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="244.00"}};
				end;
				if _decision_modelbackbone=6 then do;

				/*352.00 to 1216.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1248.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1248.00"}};

				/*176.00 to 488.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="624.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="624.00"}};

				/*88.00 to 244.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="312.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="312.00"}};

				/* increase convo1 from 24 to 28 filters */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv_2' and  _DLChrVal_ = 'ngroups'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv_2' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = '1x1conv5_out' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="2048.00"}};
				end;

				/* Adjust first convo layer filter sizes */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};

				/* add new output layer */
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
				if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
				_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
				if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
				_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
				if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
				_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
				if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
				_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
				if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
				_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
				if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
				_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
				if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
				_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
				if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
				_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
				if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
				_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block5/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
				if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
				_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block6/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
				if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
				_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block7/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
				if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
				_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage3/block8/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
				if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
				_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage4/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
				if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
				_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage4/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
				if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
				_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage4/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;
				if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
				_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage4/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				%put RobertApril: preds per grid: &_CV_OD_preds_per_grid;
				%put RobertApril: class num: &_CV_OD_class_num;

				/* end;  end applying dropout */
				_OD_depth=&_CV_OD_preds_per_grid * (&_CV_OD_class_num + 5)+0;
				print "RobertApril" _OD_depth;
				AddLayer result=suppress / model='ShuffleNetV2' name='_convolast_'
				layer={type='CONVO'
				nFilters=_OD_depth width=_decision_lc_width_ height=_decision_lc_height_
				stride=1 act='identity' includeBias=FALSE} srcLayers={'1x1conv5_out'};

				/* change model activation functions */
				_verify_activation_function=_decision_actfunction;
				if _verify_activation_function=11 then _new_activation_value_=(string)6;
				if _verify_activation_function ne 11 then
				_new_activation_value_=(string)_verify_activation_function;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				_update_grid_size=0+0;
				if _chk_image_height_=224 or _chk_image_width_=224 then _update_grid_size=7;
				if _chk_image_height_=416 or _chk_image_width_=416 then
				_update_grid_size=13;
				if _chk_image_height_=640 or _chk_image_width_=640 then
				_update_grid_size=20;
				if _chk_image_height_=1280 or _chk_image_width_=1280 then
				_update_grid_size=40;
				AddLayer result=suppress / model='ShuffleNetV2'
				name='detection1' layer={type='detection'
				detectionModelType="YOLOV2"
				classNumber=&_CV_OD_class_num
				gridNumber=_update_grid_size
				coordNumber=4
				predictionsPerGrid=&_CV_OD_preds_per_grid
				anchors={&anchor_box_coord} softMaxForClassProb=True

				/* Error function scalers: */
				objectScale=_decision_obj_scale
				predictionNotAObjectScale=_decision_noobj_scale
				classScale=_decision_class_scale
				coordScale=_decision_coord_scale
				maxLabelPerImage=&_CV_object_num_

				/* end, error function scalers */
				coordType="YOLO"

				/* Prediction thresholds */
				detectionThreshold=_decision_detthreshold
				iouThreshold=_decision_iouthreshold
				trainIouThreshold=_decision_trainiou} srcLayers={'_convolast_'};
				_verify_crop_="&_CV_crop_RESIZE_THENCROP";
				if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;
				if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_mutation_="&_CV_random_mutate";
				if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_fliptype_="&_CV_fliptype_";
				if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				if _verify_fliptype_="horizontal" then do;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_fliptype_="vertical" then do;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
				end;
				if _verify_fliptype_="both" then do;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;

				/* Change the expected input size - height */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_height_"}};

				/* Change the expected input size - width */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_width_"}};

				/* Change the number of channels to match greyscale if condition exist */
				_verify_image_color="&_image_input_color_";

				/* yes no */
				if _verify_image_color="greyscale" then do;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
				end;
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;

				/*begin Resnet for object detection*/
				deeplearn.dlTrain result=t / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='ShuffleNetV2'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					initWeights='ShuffleNetV2_weights'
					dataSpecs={{data=_ObjectTargets_, layer='detection1', 
					type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad}, ignoreTrainingError=true, loglevel=1, 
					regL1=_decision_l1reg, regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} 
					seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* Remove dropout */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset ShuffleNetV2 Dropout in input layer back to 0*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='ShuffleNetV2'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					GPU=&_CV_usegpu_T_F;
				_temp_num_eval_epochs=ceil(&_CV_eval_epochs/5);
				k1_Error=0;
				do i=&_CV_eval_epochs to _temp_num_eval_epochs by -1;
				vfitErrori=0+t['OptIterHistory'][i]['ValidError'];
				k1_Error=k1_Error+0+vfitErrori;
				end;
				k1_Loss_error=(k1_Error/ceil(&_CV_eval_epochs/5));
				k1_iouassessment=0+s['ScoreInfo'][3]['Value'];
				k1_iou_assessment_v2=1-k1_iouassessment;
				k1_final_error=(k1_iou_assessment_v2+k1_Loss_error)/2;
				if _bbEvalTag_=1 and k1_final_error ne . then do;
				_holdvalue_=k1_final_error;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if k1_final_error ne . then do;
				if k1_final_error <=globalobj then do;
				_holdvalue_=k1_final_error;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=k1_final_error;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;

				/************************************/
				/* Xception for Object detection */
				/************************************/
				_verify_modelbackbone_="&_CV_modelBackbone_";
				if _verify_modelbackbone_="autotune" then do;
				if _decision_modelbackbone=1 then _verify_modelbackbone_="resnet50_caffe";
				if _decision_modelbackbone=2 then _verify_modelbackbone_="Tiny-Yolov2";
				if _decision_modelbackbone=3 then _verify_modelbackbone_="ShuffleNetV2";
				if _decision_modelbackbone=4 then _verify_modelbackbone_="ShuffleNetV2_x15";
				if _decision_modelbackbone=5 then _verify_modelbackbone_="ShuffleNetV2_x20";
				if _decision_modelbackbone=6 then _verify_modelbackbone_="ShuffleNetV2_x25";
				if _decision_modelbackbone=7 then _verify_modelbackbone_="Xception";
				end;
				if _verify_modelbackbone_="Xception" then do;

				/* OD start here */
				if _verify_modelbackbone_="Xception" then do;
				table.loadTable /caslib='libCVmod', path='Xception.sashdat'
				casOut={name='Xception', replace=true};
				/*Xception Apply Dropout to input layer*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

				/* remove current output layer */
				removelayer result=suppress / model='Xception' name='outlayer';
				removelayer result=suppress / model='Xception' name='final_avepool';
				removelayer result=suppress / model='Xception'
				name='seperablebnrelu_exit2__bn';

				/* Adjust first convo layer filter sizes */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_width}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_CV_firstConvo_height}};

				/* 						mytbl.name  ="Xception";  */
				/* 						mytbl.where = "_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.width'"; */
				/* 						table.update /  table=mytbl  set = {{var="_DLNumVal_", value=_CV_firstConvo_width}}; */
				/* 						mytbl.name  ="Xception";  */
				/* 						mytbl.where = "_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.height'"; */
				/* 						table.update /  table=mytbl  set = {{var="_DLNumVal_", value=_CV_firstConvo_height}}; */
				/* add new output layer */
				/* Depth = predictionsPerGrid + (ClassNumber + CoorNumber + 1)  */
				_chk_image_height_=&_image_input_height_+0;
				_chk_image_width_=&_image_input_width_+0;
				_OD_depth=&_CV_OD_preds_per_grid * (&_CV_OD_class_num + 5)+0;
				AddLayer result=suppress / model='Xception' name='_convolast_'
				layer={type='CONVO'
				nFilters=_OD_depth width=_decision_lc_width_ height=_decision_lc_height_
				stride=1 act='identity' includeBias=FALSE} 
					srcLayers={'seperablebnrelu_exit2__pw'};

				/*********************/
				/*Apply Dropout */
				/*********************/
				_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
				if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
				_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
				_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
				if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
				_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
				_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
				if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
				_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_1seperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
				_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
				if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
				_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_1seperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
				_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
				if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
				_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_2reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
				_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
				if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
				_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_3reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
				_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
				if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
				_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_4reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
				_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
				if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
				_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_5reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
				_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
				if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
				_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_6reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
				_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
				if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
				_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_7reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__10}};
				_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
				if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
				_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_8reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__11}};
				_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
				if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
				_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_9reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__12}};
				_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
				if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
				_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_10reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__13}};
				_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
				if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
				_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_11reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__14}};
				_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
				if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
				_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'block_12reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__15}};
				_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;
				if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
				_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'seperablebnrelu_exit1__pw' and  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_Dropout_block__16}};

				/* change model activation functions */
				_verify_activation_function=_decision_actfunction;
				if _verify_activation_function=11 then _new_activation_value_=(string)6;
				if _verify_activation_function ne 11 then
				_new_activation_value_=(string)_verify_activation_function;
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'reshapeopts.act' and  _DLChrVal_ = 'Rectifier'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value=_new_activation_value_}};
				_update_grid_size=0+0;
				if _chk_image_height_=224 or _chk_image_width_=224 then _update_grid_size=7;
				if _chk_image_height_=416 or _chk_image_width_=416 then
				_update_grid_size=13;
				if _chk_image_height_=640 or _chk_image_width_=640 then
				_update_grid_size=20;
				if _chk_image_height_=1280 or _chk_image_width_=1280 then
				_update_grid_size=40;
				AddLayer result=suppress / model='Xception'
				name='detection1' layer={type='detection'
				detectionModelType="YOLOV2"
				classNumber=&_CV_OD_class_num
				gridNumber=_update_grid_size
				coordNumber=4
				predictionsPerGrid=&_CV_OD_preds_per_grid
				anchors={&anchor_box_coord} softMaxForClassProb=True

				/* Error function scalers: */
				objectScale=_decision_obj_scale
				predictionNotAObjectScale=_decision_noobj_scale
				classScale=_decision_class_scale
				coordScale=_decision_coord_scale
				maxLabelPerImage=&_CV_object_num_

				/* end, error function scalers */
				coordType="YOLO"

				/* Prediction thresholds */
				detectionThreshold=_decision_detthreshold
				iouThreshold=_decision_iouthreshold
				trainIouThreshold=_decision_trainiou} srcLayers={'_convolast_'};
				_verify_crop_="&_CV_crop_RESIZE_THENCROP";
				if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;
				if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_mutation_="&_CV_random_mutate";
				if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				_verify_fliptype_="&_CV_fliptype_";
				if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				end;
				if _verify_fliptype_="horizontal" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				end;
				if _verify_fliptype_="vertical" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
				end;
				if _verify_fliptype_="both" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
				end;

				/* Change the expected input size - height */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_height_"}};

				/* Change the expected input size - width */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", 
					value="&_image_input_width_"}};

				/* Change the number of channels to match greyscale if condition exist */
				_verify_image_color="&_image_input_color_";

				/* yes no */
				if _verify_image_color="greyscale" then do;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
				end;
				_set_beta1_value=.999-_decision_betadiff+0;
				lower_clipgrad=0+_decision_gradclips*-1;

				/*begin Resnet for object detection*/
				deeplearn.dlTrain result=t / table={name="&_imageDS_", where="&_CV_partition_var_=1", 
					caslib="libres"} model='Xception'
					modelWeights={name='ConVTrainedWeights_d', replace=1} 
					bestweights={name='autotune_bestweights_', caslib="casuser", replace=1} 
					/* 				initWeights='Xceptionweights' */
					dataSpecs={{data=_ObjectTargets_, layer='detection1', 
					type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
					GPU=&_CV_usegpu_T_F
					nthreads=&n_threads_

					/* 		weight="weight" */
					ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} optimizer={minibatchsize=_decision_minibatch, 
					algorithm={method='ADAM', lrpolicy='Step', gamma=_decision_gamma, 
					stepsize=_decision_stepsize, learningrate=_decision_lr, 
					beta1=_set_beta1_value, clipGradMax=_decision_gradclips, 
					clipGradMin=lower_clipgrad}, ignoreTrainingError=true, loglevel=1, 
					regL1=_decision_l1reg, regL2=_decision_l2reg, maxepochs=&_CV_eval_epochs} 
					seed=12345;
				table.tableExists result=d / name='autotune_bestweights_', caslib="casuser";
				if d=1 then do;

				/* return flipping back to "no flip" for classification model scoring and deployment */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Xception Dropout in input layer back to 0*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore result=s / table={name="&_imageDS_", where="&_CV_partition_var_=2", 
					caslib="libres"} model='Xception'
					initWeights={name='autotune_bestweights_', caslib="casuser"} 
					GPU=&_CV_usegpu_T_F;
				_temp_num_eval_epochs=ceil(&_CV_eval_epochs/5);
				k1_Error=0;
				do i=&_CV_eval_epochs to _temp_num_eval_epochs by -1;
				vfitErrori=0+t['OptIterHistory'][i]['ValidError'];
				k1_Error=k1_Error+0+vfitErrori;
				end;
				k1_Loss_error=(k1_Error/ceil(&_CV_eval_epochs/5));
				k1_iouassessment=0+s['ScoreInfo'][3]['Value'];
				k1_iou_assessment_v2=1-k1_iouassessment;
				k1_final_error=(k1_iou_assessment_v2+k1_Loss_error)/2;

				/* save best model weights */
				if _bbEvalTag_=1 and k1_final_error ne . then do;
				_holdvalue_=k1_final_error;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				table.fetch result=r / table={caslib="casuser"
				name="objectivefunctionhold"};
				grab_obj_value=0+r['Fetch'][1]['currentobj'];
				globalobj=0+grab_obj_value;
				if k1_final_error ne . then do;
				if k1_final_error <=globalobj then do;
				_holdvalue_=k1_final_error;
				newobjfunc=(string)_holdvalue_;
				table.update / table={name="objectivefunctionhold", caslib="casuser"}, 
					set={{var="currentobj", value=newobjfunc}};
				table.save / saveAttrs=True
				Caslib="libres"
				table={name="autotune_bestweights_", caslib="casuser"} 
					name="autotune_bestweights_.sashdat"
					permission="PUBLICWRITE"
					replace=True;
				end;
				end;
				f['objVal']=k1_final_error;
				end;
				if d ne 1 then do;
				Error1=.;
				f['objVal']=Error1;
				end;
				send_response(f);
				run;
				end;
				end;
				table.dropTable / caslib="libCVmod" name="resnet50_caffe" quiet=TRUE;
				table.dropTable / caslib="libCVmod" name="Tiny-Yolov2" quiet=TRUE;
				table.dropTable / caslib="libCVmod" name="ShuffleNetV2" quiet=TRUE;
				table.dropTable / caslib="libCVmod" name="Xception" quiet=TRUE;
				endsource;
				source cvcleanup;
				table.save / Caslib="libres"
				table={name="&_imageDS_", caslib="libres"} name="&_imageDS_..sashdat"
				permission="PUBLICWRITE"
				replace=True;
				table.save / Caslib="libres"
				table={name="objectivefunctionhold", caslib="casuser"} 
					name="objectivefunctionhold"
					permission="PUBLICWRITE"
					replace=True;
				table.dropCaslib result=suppress / caslib="libres" quiet=TRUE;
				endsource;
				_verify_previous_search="&_CV_continue_previous_search";

				/* classification, regression or objectdetection */
				if _verify_previous_search ne "yes" then do;
				optimization.solveblackbox / decVars={{name='_decision_modelbackbone', 
					type='I', lb=_setup_lb_backbone, ub=_setup_ub_backbone, 
					init=_setup_init_backbone} {name='_decision_gamma', type='C', 
					lb=_setup_lb_gamma, ub=_setup_ub_gamma, init=_setup_init_gamma} 
					{name='_decision_stepsize', type='I', lb=_setup_lb_stepsize, 
					ub=_setup_ub_stepsize, init=_setup_init_stepsize} 
					{name='_decision_minibatch', type='I', lb=_setup_lb_miniBSize, 
					ub=_setup_ub_miniBSize, init=_setup_init_miniBSize} {name='_decision_lr', 
					type='C', lb=_setup_lb_lr, ub=_setup_ub_lr, init=_setup_init_lr} 
					{name='_decision_betadiff', type='C', lb=_setup_lb_betadiff, 
					ub=_setup_ub_betadiff, init=_setup_init_betadiff} {name='_decision_l1reg', 
					type='C', lb=_setup_lb_l1reg, ub=_setup_ub_l1reg, init=_setup_init_l1reg} 
					{name='_decision_l2reg', type='C', lb=_setup_lb_l2reg, ub=_setup_ub_l2reg, 
					init=_setup_init_l2reg} {name='_decision_gradclips', type='C', 
					lb=_setup_lb_gradclips, ub=_setup_ub_gradclips, 
					init=_setup_init_gradclips} {name='_decision_fconvo_size', type='I', 
					lb=_setup_lb_fconvo_size, ub=_setup_ub_fconvo_size, 
					init=_setup_init_fconvo_size} {name='_decision_actfunction', type='I', 
					lb=_setup_lb_actfunc, ub=_setup_ub_actfunc, init=_setup_init_actfunc} 
					{name='_decision_lc_width_', type='I', lb=_setup_lb_lc_width, 
					ub=_setup_ub_lc_width, init=_setup_init_lc_width} 
					{name='_decision_lc_height_', type='I', lb=_setup_lb_lc_height, 
					ub=_setup_ub_lc_height, init=_setup_init_lc_height} 
					{name='_decision_obj_scale', type='C', lb=_setup_lb_obj, ub=_setup_ub_obj, 
					init=_setup_init_obj} {name='_decision_noobj_scale', type='C', 
					lb=_setup_lb_noobj, ub=_setup_ub_noobj, init=_setup_init_noobj} 
					{name='_decision_coord_scale', type='C', lb=_setup_lb_coord, 
					ub=_setup_ub_coord, init=_setup_init_coord} {name='_decision_class_scale', 
					type='C', lb=_setup_lb_class, ub=_setup_ub_class, init=_setup_init_class} 
					{name='_decision_detthreshold', type='C', lb=_setup_lb_detthresh, 
					ub=_setup_ub_detthresh, init=_setup_init_detthresh} 
					{name='_decision_iouthreshold', type='C', lb=_setup_lb_iouthresh, 
					ub=_setup_ub_iouthresh, init=_setup_init_iouthresh} 
					{name='_decision_trainiou', type='C', lb=_setup_lb_trainiou, 
					ub=_setup_ub_trainiou, init=_setup_init_trainiou} 
					{name='_decision_Dropoutblock_1_', type='I', lb=_setup_lb_Dropoutblock_1, 
					ub=_setup_ub_Dropoutblock_1, init=_setup_init_Dropoutblock_1} 
					{name='_decision_Dropoutblock_2', type='I', lb=_setup_lb_Dropoutblock_2, 
					ub=_setup_ub_Dropoutblock_2, init=_setup_init_Dropoutblock_2} 
					{name='_decision_Dropoutblock_3', type='I', lb=_setup_lb_Dropoutblock_3, 
					ub=_setup_ub_Dropoutblock_3, init=_setup_init_Dropoutblock_3} 
					{name='_decision_Dropoutblock_4', type='I', lb=_setup_lb_Dropoutblock_4, 
					ub=_setup_ub_Dropoutblock_4, init=_setup_init_Dropoutblock_4} 
					{name='_decision_Dropoutblock_5', type='I', lb=_setup_lb_Dropoutblock_5, 
					ub=_setup_ub_Dropoutblock_5, init=_setup_init_Dropoutblock_5} 
					{name='_decision_Dropoutblock_6', type='I', lb=_setup_lb_Dropoutblock_6, 
					ub=_setup_ub_Dropoutblock_6, init=_setup_init_Dropoutblock_6} 
					{name='_decision_Dropoutblock_7', type='I', lb=_setup_lb_Dropoutblock_7, 
					ub=_setup_ub_Dropoutblock_7, init=_setup_init_Dropoutblock_7} 
					{name='_decision_Dropoutblock_8', type='I', lb=_setup_lb_Dropoutblock_8, 
					ub=_setup_ub_Dropoutblock_8, init=_setup_init_Dropoutblock_8} 
					{name='_decision_Dropoutblock_9', type='I', lb=_setup_lb_Dropoutblock_9, 
					ub=_setup_ub_Dropoutblock_9, init=_setup_init_Dropoutblock_9} 
					{name='_decision_Dropoutblock_10', type='I', lb=_setup_lb_Dropoutblock_10, 
					ub=_setup_ub_Dropoutblock_10, init=_setup_init_Dropoutblock_10} 
					{name='_decision_Dropoutblock_11', type='I', lb=_setup_lb_Dropoutblock_11, 
					ub=_setup_ub_Dropoutblock_11, init=_setup_init_Dropoutblock_11} 
					{name='_decision_Dropoutblock_12', type='I', lb=_setup_lb_Dropoutblock_12, 
					ub=_setup_ub_Dropoutblock_12, init=_setup_init_Dropoutblock_12} 
					{name='_decision_Dropoutblock_13', type='I', lb=_setup_lb_Dropoutblock_13, 
					ub=_setup_ub_Dropoutblock_13, init=_setup_init_Dropoutblock_13} 
					{name='_decision_Dropoutblock_14', type='I', lb=_setup_lb_Dropoutblock_14, 
					ub=_setup_ub_Dropoutblock_14, init=_setup_init_Dropoutblock_14} 
					{name='_decision_Dropoutblock_15', type='I', lb=_setup_lb_Dropoutblock_15, 
					ub=_setup_ub_Dropoutblock_15, init=_setup_init_Dropoutblock_15} 
					{name='_decision_Dropoutblock_16', type='I', lb=_setup_lb_Dropoutblock_16, 
					ub=_setup_ub_Dropoutblock_16, init=_setup_init_Dropoutblock_16}}, 
					obj={{name='objVal', type='min'}}, outputTables={includeall=true} 
					display={excludeAll=FALSE} primalOut={name='primal_out', replace=TRUE} 
					CACHEOUT={name="_temp_ds_results_", replace=true, caslib="casuser"} 
					func={init=caslInit, eval=evalcode, cleanup=cvcleanup}, nParallel=1, 
					popsize=&_CV_population_s, nlocal=&_CV_gsslocal_s, 
					maxGen=&_CV_gagenerations_s, nabsfconv=100000000, maxtime=&_CV_maxtraintime
					Seed=&_CV_autotuneseed;
				end;
				_verify_previous_search="&_CV_continue_previous_search";
				if _verify_previous_search="yes" then do;
				optimization.solveblackbox / decVars={{name='_decision_modelbackbone', 
					type='I', lb=_setup_lb_backbone, ub=_setup_ub_backbone, 
					init=_setup_init_backbone} {name='_decision_gamma', type='C', 
					lb=_setup_lb_gamma, ub=_setup_ub_gamma, init=_setup_init_gamma} 
					{name='_decision_stepsize', type='I', lb=_setup_lb_stepsize, 
					ub=_setup_ub_stepsize, init=_setup_init_stepsize} 
					{name='_decision_minibatch', type='I', lb=_setup_lb_miniBSize, 
					ub=_setup_ub_miniBSize, init=_setup_init_miniBSize} {name='_decision_lr', 
					type='C', lb=_setup_lb_lr, ub=_setup_ub_lr, init=_setup_init_lr} 
					{name='_decision_betadiff', type='C', lb=_setup_lb_betadiff, 
					ub=_setup_ub_betadiff, init=_setup_init_betadiff} {name='_decision_l1reg', 
					type='C', lb=_setup_lb_l1reg, ub=_setup_ub_l1reg, init=_setup_init_l1reg} 
					{name='_decision_l2reg', type='C', lb=_setup_lb_l2reg, ub=_setup_ub_l2reg, 
					init=_setup_init_l2reg} {name='_decision_gradclips', type='C', 
					lb=_setup_lb_gradclips, ub=_setup_ub_gradclips, 
					init=_setup_init_gradclips} {name='_decision_fconvo_size', type='I', 
					lb=_setup_lb_fconvo_size, ub=_setup_ub_fconvo_size, 
					init=_setup_init_fconvo_size} {name='_decision_actfunction', type='I', 
					lb=_setup_lb_actfunc, ub=_setup_ub_actfunc, init=_setup_init_actfunc} 
					{name='_decision_lc_width_', type='I', lb=_setup_lb_lc_width, 
					ub=_setup_ub_lc_width, init=_setup_init_lc_width} 
					{name='_decision_lc_height_', type='I', lb=_setup_lb_lc_height, 
					ub=_setup_ub_lc_height, init=_setup_init_lc_height} 
					{name='_decision_obj_scale', type='C', lb=_setup_lb_obj, ub=_setup_ub_obj, 
					init=_setup_init_obj} {name='_decision_noobj_scale', type='C', 
					lb=_setup_lb_noobj, ub=_setup_ub_noobj, init=_setup_init_noobj} 
					{name='_decision_coord_scale', type='C', lb=_setup_lb_coord, 
					ub=_setup_ub_coord, init=_setup_init_coord} {name='_decision_class_scale', 
					type='C', lb=_setup_lb_class, ub=_setup_ub_class, init=_setup_init_class} 
					{name='_decision_detthreshold', type='C', lb=_setup_lb_detthresh, 
					ub=_setup_ub_detthresh, init=_setup_init_detthresh} 
					{name='_decision_iouthreshold', type='C', lb=_setup_lb_iouthresh, 
					ub=_setup_ub_iouthresh, init=_setup_init_iouthresh} 
					{name='_decision_trainiou', type='C', lb=_setup_lb_trainiou, 
					ub=_setup_ub_trainiou, init=_setup_init_trainiou} 
					{name='_decision_Dropoutblock_1_', type='I', lb=_setup_lb_Dropoutblock_1, 
					ub=_setup_ub_Dropoutblock_1, init=_setup_init_Dropoutblock_1} 
					{name='_decision_Dropoutblock_2', type='I', lb=_setup_lb_Dropoutblock_2, 
					ub=_setup_ub_Dropoutblock_2, init=_setup_init_Dropoutblock_2} 
					{name='_decision_Dropoutblock_3', type='I', lb=_setup_lb_Dropoutblock_3, 
					ub=_setup_ub_Dropoutblock_3, init=_setup_init_Dropoutblock_3} 
					{name='_decision_Dropoutblock_4', type='I', lb=_setup_lb_Dropoutblock_4, 
					ub=_setup_ub_Dropoutblock_4, init=_setup_init_Dropoutblock_4} 
					{name='_decision_Dropoutblock_5', type='I', lb=_setup_lb_Dropoutblock_5, 
					ub=_setup_ub_Dropoutblock_5, init=_setup_init_Dropoutblock_5} 
					{name='_decision_Dropoutblock_6', type='I', lb=_setup_lb_Dropoutblock_6, 
					ub=_setup_ub_Dropoutblock_6, init=_setup_init_Dropoutblock_6} 
					{name='_decision_Dropoutblock_7', type='I', lb=_setup_lb_Dropoutblock_7, 
					ub=_setup_ub_Dropoutblock_7, init=_setup_init_Dropoutblock_7} 
					{name='_decision_Dropoutblock_8', type='I', lb=_setup_lb_Dropoutblock_8, 
					ub=_setup_ub_Dropoutblock_8, init=_setup_init_Dropoutblock_8} 
					{name='_decision_Dropoutblock_9', type='I', lb=_setup_lb_Dropoutblock_9, 
					ub=_setup_ub_Dropoutblock_9, init=_setup_init_Dropoutblock_9} 
					{name='_decision_Dropoutblock_10', type='I', lb=_setup_lb_Dropoutblock_10, 
					ub=_setup_ub_Dropoutblock_10, init=_setup_init_Dropoutblock_10} 
					{name='_decision_Dropoutblock_11', type='I', lb=_setup_lb_Dropoutblock_11, 
					ub=_setup_ub_Dropoutblock_11, init=_setup_init_Dropoutblock_11} 
					{name='_decision_Dropoutblock_12', type='I', lb=_setup_lb_Dropoutblock_12, 
					ub=_setup_ub_Dropoutblock_12, init=_setup_init_Dropoutblock_12} 
					{name='_decision_Dropoutblock_13', type='I', lb=_setup_lb_Dropoutblock_13, 
					ub=_setup_ub_Dropoutblock_13, init=_setup_init_Dropoutblock_13} 
					{name='_decision_Dropoutblock_14', type='I', lb=_setup_lb_Dropoutblock_14, 
					ub=_setup_ub_Dropoutblock_14, init=_setup_init_Dropoutblock_14} 
					{name='_decision_Dropoutblock_15', type='I', lb=_setup_lb_Dropoutblock_15, 
					ub=_setup_ub_Dropoutblock_15, init=_setup_init_Dropoutblock_15} 
					{name='_decision_Dropoutblock_16', type='I', lb=_setup_lb_Dropoutblock_16, 
					ub=_setup_ub_Dropoutblock_16, init=_setup_init_Dropoutblock_16}}, 
					obj={{name='objVal', type='min'}}, outputTables={includeall=true} 
					display={excludeAll=FALSE} primalOut={name='primal_out', replace=TRUE} 
					CACHEIN={name='_Cachein_table', caslib="casuser"} 
					firstgen={name='_firstgen_table', caslib="casuser"} 
					CACHEOUT={name="_temp_ds_results_", replace=true, caslib="casuser"} 
					func={init=caslInit, eval=evalcode, cleanup=cvcleanup}, nParallel=1, 
					popsize=&_CV_population_s, nlocal=&_CV_gsslocal_s, 
					maxGen=&_CV_gagenerations_s, nabsfconv=100000000, maxtime=&_CV_maxtraintime
					Seed=&_CV_autotuneseed;

				/* run; */
				end;
				end;
				end;
				end;
				quit;
				%updatemultiTaskS;

				%macro updatetransfervales;
					%if &_CV_Global_autotune_initiate=yes %then %do;

						proc sort data=casuser._temp_ds_results_ out=work._temp_ds_results_;
							by objVal;
						run;

						data _null_;
							set work._temp_ds_results_(where=(objVal ne .) obs=1);
							_updatevar_modelBackbone="&_CV_modelBackbone_";

							if _updatevar_modelBackbone="autotune" then do;

								if _decision_modelbackbone=1 then 
									_verify_modelbackbone_="resnet50_caffe";

								if _decision_modelbackbone=2 then _verify_modelbackbone_="Tiny-Yolov2";

								if _decision_modelbackbone=3 then _verify_modelbackbone_="ShuffleNetV2";

								if _decision_modelbackbone=4 then 
									_verify_modelbackbone_="ShuffleNetV2_x15";

								if _decision_modelbackbone=5 then 
									_verify_modelbackbone_="ShuffleNetV2_x20";

								if _decision_modelbackbone=6 then 
									_verify_modelbackbone_="ShuffleNetV2_x25";

								if _decision_modelbackbone=7 then _verify_modelbackbone_="Xception";
								call symput("_CV_modelBackbone_", _verify_modelbackbone_);
							end;

							if _decision_fconvo_size=1 then do;
								call symput("mac_firstConvo_width", "3");
								call symput("mac_firstConvo_height", "3");
							end;

							if _decision_fconvo_size=2 then do;
								call symput("mac_firstConvo_width", "3");
								call symput("mac_firstConvo_height", "5");
							end;

							if _decision_fconvo_size=3 then do;
								call symput("mac_firstConvo_width", "5");
								call symput("mac_firstConvo_height", "3");
							end;

							if _decision_fconvo_size=4 then do;
								call symput("mac_firstConvo_width", "5");
								call symput("mac_firstConvo_height", "5");
							end;

							if _decision_fconvo_size=5 then do;
								call symput("mac_firstConvo_width", "5");
								call symput("mac_firstConvo_height", "7");
							end;

							if _decision_fconvo_size=6 then do;
								call symput("mac_firstConvo_width", "7");
								call symput("mac_firstConvo_height", "5");
							end;

							if _decision_fconvo_size=7 then do;
								call symput("mac_firstConvo_width", "7");
								call symput("mac_firstConvo_height", "7");
							end;
							_updatevar_gamma="&_CV_onoff_search_gamma";

							if _updatevar_gamma="yes" then do;
								call symput("_CV_gam_value_", _decision_gamma);
							end;
							_updatevar_stepsize="&_CV_onoff_search_stepsize";

							if _updatevar_stepsize="yes" then do;
								call symput("_CV_stepSize_value_", _decision_stepsize);
							end;
							_updatevar_miniBSize="&_CV_onoff_search_miniBSize";

							if _CV_onoff_search_miniBSize="yes" then do;
								call symput("_CV_miniBSize_value_", _decision_minibatch);
							end;
							_updatevar_lrate="&_CV_onoff_search_lr";

							if _updatevar_lrate="yes" then do;
								call symput("_CV_lr_value_", _decision_lr);
							end;
							_updatevar_betadiff="&_CV_onoff_search_betadiff";

							if _updatevar_betadiff="yes" then do;
								call symput("_CV_betadiff_value_", _decision_betadiff);
							end;
							_updatevar_l1reg="&_CV_onoff_search_l1reg";

							if _updatevar_l1reg="yes" then do;
								call symput("_CV_l1reg_value_", _decision_l1reg);
							end;
							_updatevar_l2reg="&_CV_onoff_search_l2reg";

							if _updatevar_l2reg="yes" then do;
								call symput("_CV_l2reg_value_", _decision_l2reg);
							end;
							_updatevar_clipgrad="&_CV_onoff_search_gradclips";

							if _updatevar_clipgrad="yes" then do;
								call symput("_CV_gradclips_value", _decision_gradclips);
							end;
							_updatevar_actfunction="&_CV_onoff_search_actfunc";

							if _updatevar_actfunction="yes" then do;
								call symput("_CV_act_function", _decision_actfunction);
							end;

							/*dropout*/
							_updatevar_dropoutValue="&_CV_dropValue";

							if _updatevar_dropoutValue="yes" then do;
								call symput("_CV_dropout_block1", _decision_Dropoutblock_1_);
								call symput("_CV_dropout_block2", _decision_Dropoutblock_2);
								call symput("_CV_dropout_block3", _decision_Dropoutblock_3);
								call symput("_CV_dropout_block4", _decision_Dropoutblock_4);
								call symput("_CV_dropout_block5", _decision_Dropoutblock_5);
								call symput("_CV_dropout_block6", _decision_Dropoutblock_6);
								call symput("_CV_dropout_block7", _decision_Dropoutblock_7);
								call symput("_CV_dropout_block8", _decision_Dropoutblock_8);
								call symput("_CV_dropout_block9", _decision_Dropoutblock_9);
								call symput("_CV_dropout_block10", _decision_Dropoutblock_10);
								call symput("_CV_dropout_block11", _decision_Dropoutblock_11);
								call symput("_CV_dropout_block12", _decision_Dropoutblock_12);
								call symput("_CV_dropout_block13", _decision_Dropoutblock_13);
								call symput("_CV_dropout_block14", _decision_Dropoutblock_14);
								call symput("_CV_dropout_block15", _decision_Dropoutblock_15);
								call symput("_CV_dropout_block16", _decision_Dropoutblock_16);
							end;

							/* classification and regression only */
							_updatevar_modeltask="&_CV_modeltask_";

							if _updatevar_modeltask="classification" or
							_updatevar_modeltask="regression" then do;
								_updatevar_FClayer="&_CV_include_FC_layer";
								_updatevar_FCneuronnum="&_CV_onoff_search_FCneuronnum";

								if _updatevar_FClayer="yes" and _updatevar_FCneuronnum="yes" then do;
									call symput("_CV_FC_neuron_num", _decision_FCneuronnum);
								end;
								_updatevar_FCactfunc="&_CV_onoff_search_FCactfunc";

								if _updatevar_FClayer="yes" and _updatevar_FCactfunc="yes" then do;
									call symput("_CV_FC_act_function", _decision_FCactfunc);
								end;
							end;

							/* end classification and regression only updates */
							_updatevar_modeltask="&_CV_modeltask_";

							if _updatevar_modeltask="multitask" then do;
								&_CVsclaremacroupdate;
							end;

							if _updatevar_modeltask="objectdetection" then do;
								_updatevar_lc_width="&_CV_onoff_search_lc_width";

								if _updatevar_lc_width="yes" then do;
									call symput("_CV_OD_lastConvo_width", _decision_lc_width_);
								end;
								_updatevar_lc_height="&_CV_onoff_search_lc_height";

								if _updatevar_lc_height="yes" then do;
									call symput("_CV_OD_lastConvo_height", _decision_lc_height_);
								end;
								_updatevar_od_obj="&_CV_onoff_search_obj";

								if _updatevar_od_obj="yes" then do;
									call symput("_CV_OD_Obj_scale_", _decision_obj_scale);
								end;
								_updatevar_od_noobj="&_CV_onoff_search_noobj";

								if _updatevar_od_noobj="yes" then do;
									call symput("_CV_OD_Not_Obj_scale_", _decision_noobj_scale);
								end;
								_updatevar_od_coord="&_CV_onoff_search_coord";

								if _updatevar_od_coord="yes" then do;
									call symput("_CV_OD_coord_scale_", _decision_coord_scale);
								end;
								_updatevar_od_class="&_CV_onoff_search_class";

								if _updatevar_od_class="yes" then do;
									call symput("_CV_OD_class_scale_", _decision_class_scale);
								end;
								_updatevar_od_detthresh="&_CV_onoff_search_detthresh";

								if _updatevar_od_detthresh="yes" then do;
									call symput("_CV_OD_detection_thresh_", _decision_detthreshold);
								end;
								_updatevar_od_iouthreshold="&_CV_onoff_search_iouthresh";

								if _updatevar_od_iouthreshold="yes" then do;
									call symput("_CV_OD_iouthreshold_", _decision_iouthreshold);
								end;
								_updatevar_od_trainiou="&_CV_onoff_search_trainiou";

								if _updatevar_od_trainiou="yes" then do;
									call symput("_CV_iouTrainThreshold_", _decision_trainiou);
								end;
							end;

							/* end objectdetection only updates */
						run;

					%end;

					%if &_CV_Global_autotune_initiate ne yes %then %do;

						data _null_;
							if &_CV_assigned_firstc_fsize=1 then do;
								call symput("mac_firstConvo_width", "3");
								call symput("mac_firstConvo_height", "3");
							end;

							if &_CV_assigned_firstc_fsize=2 then do;
								call symput("mac_firstConvo_width", "3");
								call symput("mac_firstConvo_height", "5");
							end;

							if &_CV_assigned_firstc_fsize=3 then do;
								call symput("mac_firstConvo_width", "5");
								call symput("mac_firstConvo_height", "3");
							end;

							if &_CV_assigned_firstc_fsize=4 then do;
								call symput("mac_firstConvo_width", "5");
								call symput("mac_firstConvo_height", "5");
							end;

							if &_CV_assigned_firstc_fsize=5 then do;
								call symput("mac_firstConvo_width", "5");
								call symput("mac_firstConvo_height", "7");
							end;

							if &_CV_assigned_firstc_fsize=6 then do;
								call symput("mac_firstConvo_width", "7");
								call symput("mac_firstConvo_height", "5");
							end;

							if &_CV_assigned_firstc_fsize=7 then do;
								call symput("mac_firstConvo_width", "7");
								call symput("mac_firstConvo_height", "7");
							end;
						run;

					%end;
				%mend updatetransfervales;

				%updatetransfervales;
				%retaindecsionvars;

				/* retain decision variable list when multi-task is being used */
				%labelsdecsionvars;

				/* creates human readable labels for the decision variables */
				%put new value is gamma is:  &_CV_gam_value_;
				%put new value is stepsize is: &_CV_stepSize_value_;
				%put new value is activation function is: &_CV_act_function;
				%put new value is activation minibatch size is: &_CV_miniBSize_value_;

				proc cas;
					table.dropCaslib result=suppress / caslib="libres" quiet=TRUE;
					table.addCasLib result=suppress / name="libres", 
						path="&_CV_location_for_results_data" subdirectories=true;
					_verify_autotune_init="&_CV_Global_autotune_initiate";

					if _verify_autotune_init="yes" then do;
						table.save / Caslib="libres"
						table={name="_temp_ds_results_", caslib="casuser"} 
							name="&_CV_name_autotuneresults_save..sashdat"
							permission="PUBLICWRITE"
							replace=True;
						_verify_modeling_task_="&_CV_modeltask_";

						/* classification, regression or objectdetection */
						if _verify_modeling_task_="objectdetection" then do;

							/* update */
							datastep.runCode result=suppress / code="

data casuser._TEMP_DS_RESULTS_;
set casuser._TEMP_DS_RESULTS_;
ch__decision_modelbackbone = input(_decision_modelbackbone, $32.);
ch__decision_actfunction = input(_decision_actfunction, $32.); 
ch__decision_fconvo_size = input(_decision_fconvo_size, $32.);             

drop _decision_modelbackbone _decision_actfunction _decision_fconvo_size;                      
rename ch__decision_modelbackbone=_decision_modelbackbone ch__decision_actfunction=_decision_actfunction ch__decision_fconvo_size=_decision_fconvo_size;   

run;
";
							datastep.runCode / code="
data casuser._RESULTS_humanreadable;
RETAIN objVal _evalTime_ _decision_modelbackbone	_decision_actfunction _decision_fconvo_size _decision_gamma	_decision_stepsize	
_decision_minibatch	_decision_lr _decision_betadiff	_decision_l1reg _decision_l2reg _decision_gradclips _decision_lc_width_	_decision_lc_height_
_decision_obj_scale	_decision_noobj_scale	_decision_coord_scale	_decision_class_scale	_decision_detthreshold
_decision_iouthreshold	_decision_trainiou	_decision_Dropoutblock_1_	_decision_Dropoutblock_2	
_decision_Dropoutblock_3	_decision_Dropoutblock_4	_decision_Dropoutblock_5	_decision_Dropoutblock_6	
_decision_Dropoutblock_7	_decision_Dropoutblock_8	_decision_Dropoutblock_9	_decision_Dropoutblock_10	
_decision_Dropoutblock_11	_decision_Dropoutblock_12	_decision_Dropoutblock_13	_decision_Dropoutblock_14	
_decision_Dropoutblock_15	_decision_Dropoutblock_16	_tag_	_inf_	_iter_;		

set casuser._TEMP_DS_RESULTS_;

/* change model backbone to human interpretable */
if left(trim(_decision_modelbackbone))='1' then _decision_modelbackbone='resnet50_caffe';
if left(trim(_decision_modelbackbone))='2' then _decision_modelbackbone='Tiny-Yolov2';
if left(trim(_decision_modelbackbone))='3' then _decision_modelbackbone='ShuffleNetV2';
if left(trim(_decision_modelbackbone))='4' then _decision_modelbackbone='ShuffleNetV2_x15';
if left(trim(_decision_modelbackbone))='5' then _decision_modelbackbone='ShuffleNetV2_x20';
if left(trim(_decision_modelbackbone))='6' then _decision_modelbackbone='ShuffleNetV2_x25';
if left(trim(_decision_modelbackbone))='7' then _decision_modelbackbone='Xception';


/* change model activation function to human interpretable */
if left(trim(_decision_actfunction))='8' then _decision_actfunction='ReLU';
if left(trim(_decision_actfunction))='9' then _decision_actfunction='SoftPlus';
if left(trim(_decision_actfunction))='10' then _decision_actfunction='Exponential Linear Unit (ELU)';
if left(trim(_decision_actfunction))='11' then _decision_actfunction='Hyperbolic Tangent';
if left(trim(_decision_actfunction))='12' then _decision_actfunction='Leaky ReLU';

/* change model activation function to human interpretable */
if left(trim(_decision_fconvo_size))='1' then _decision_fconvo_size='3 by 3';
if left(trim(_decision_fconvo_size))='2' then _decision_fconvo_size='3 by 5';
if left(trim(_decision_fconvo_size))='3' then _decision_fconvo_size='5 by 3';
if left(trim(_decision_fconvo_size))='4' then _decision_fconvo_size='5 by 5';
if left(trim(_decision_fconvo_size))='5' then _decision_fconvo_size='5 by 7';
if left(trim(_decision_fconvo_size))='6' then _decision_fconvo_size='7 by 5';
if left(trim(_decision_fconvo_size))='7' then _decision_fconvo_size='7 by 7';


if _decision_Dropoutblock_1_<0 then _decision_Dropoutblock_1_=0;
if _decision_Dropoutblock_2<0 then _decision_Dropoutblock_2=0;
if _decision_Dropoutblock_3<0 then _decision_Dropoutblock_3=0;
if _decision_Dropoutblock_4<0 then _decision_Dropoutblock_4=0;
if _decision_Dropoutblock_5<0 then _decision_Dropoutblock_5=0;
if _decision_Dropoutblock_6<0 then _decision_Dropoutblock_6=0;
if _decision_Dropoutblock_7<0 then _decision_Dropoutblock_7=0;
if _decision_Dropoutblock_8<0 then _decision_Dropoutblock_8=0;
if _decision_Dropoutblock_9<0 then _decision_Dropoutblock_9=0;
if _decision_Dropoutblock_10<0 then _decision_Dropoutblock_10=0;
if _decision_Dropoutblock_11<0 then _decision_Dropoutblock_11=0;
if _decision_Dropoutblock_12<0 then _decision_Dropoutblock_12=0;
if _decision_Dropoutblock_13<0 then _decision_Dropoutblock_13=0;
if _decision_Dropoutblock_14<0 then _decision_Dropoutblock_14=0;
if _decision_Dropoutblock_15<0 then _decision_Dropoutblock_15=0;
if _decision_Dropoutblock_16<0 then _decision_Dropoutblock_16=0;

if _decision_modelbackbone='Tiny-Yolov2' then _decision_Dropoutblock_16=.;

_decision_Dropoutblock_1_=_decision_Dropoutblock_1_*.05;
_decision_Dropoutblock_2=_decision_Dropoutblock_2*.05;
_decision_Dropoutblock_3=_decision_Dropoutblock_3*.05;
_decision_Dropoutblock_4=_decision_Dropoutblock_4*.05;
_decision_Dropoutblock_5=_decision_Dropoutblock_5*.05;
_decision_Dropoutblock_6=_decision_Dropoutblock_6*.05;
_decision_Dropoutblock_7=_decision_Dropoutblock_7*.05;
_decision_Dropoutblock_8=_decision_Dropoutblock_8*.05;
_decision_Dropoutblock_9=_decision_Dropoutblock_9*.05;
_decision_Dropoutblock_10=_decision_Dropoutblock_10*.05;
_decision_Dropoutblock_11=_decision_Dropoutblock_11*.05;
_decision_Dropoutblock_12=_decision_Dropoutblock_12*.05;
_decision_Dropoutblock_13=_decision_Dropoutblock_13*.05;
_decision_Dropoutblock_14=_decision_Dropoutblock_14*.05;
_decision_Dropoutblock_15=_decision_Dropoutblock_15*.05;
_decision_Dropoutblock_16=_decision_Dropoutblock_16*.05;

label 
objVal = 'Objective Function'
_evalTime_ = 'Evaluation Time'
_decision_modelbackbone = 'Backbone Used'
_decision_actfunction = 'Activation Function'
_decision_fconvo_size = 'Size of First Convo Filter'
_decision_gamma = 'Gamma Value'
_decision_stepsize = 'Stepsize Value'
_decision_minibatch = 'Minibatch Size'
_decision_lr = 'Learning Rate'
_decision_betadiff = 'Difference Between Betas (ADAM)'
_decision_l1reg = 'L1 Regularization'
_decision_l2reg = 'L2 Regularization'
_decision_gradclips = 'Gradient Clips'

_decision_lc_width_ = 'Last Convolution Layer Filter Widths'
_decision_lc_height_ = 'Last Convolution Layer Filter Heights'
_decision_obj_scale = 'Scalar for Object Presence'
_decision_noobj_scale = 'Scalar for Non-Object Presence'
_decision_coord_scale = 'Scalar for Coordinate Predictions'
_decision_class_scale = 'Scalar for Class Predictions'
_decision_detthreshold = 'Detection Threshold'
_decision_iouthreshold = 'IoU Threshold'
_decision_trainiou = 'Training IoU Threshold'
_decision_Dropoutblock_1_ = 'Block1/Layer1 Dropout Percentage'
_decision_Dropoutblock_2 = 'Block2/Layer2 Dropout Percentage'
_decision_Dropoutblock_3 = 'Block3/Layer3 Dropout Percentage'
_decision_Dropoutblock_4 = 'Block4/Layer4 Dropout Percentage'
_decision_Dropoutblock_5 = 'Block5/Layer5 Dropout Percentage'
_decision_Dropoutblock_6 = 'Block6/Layer6 Dropout Percentage'
_decision_Dropoutblock_7 = 'Block7/Layer7 Dropout Percentage'
_decision_Dropoutblock_8 = 'Block8/Layer8 Dropout Percentage'
_decision_Dropoutblock_9 = 'Block9/Layer9 Dropout Percentage'
_decision_Dropoutblock_10 = 'Block10/Layer10 Dropout Percentage'
_decision_Dropoutblock_11 = 'Block11/Layer11 Dropout Percentage'
_decision_Dropoutblock_12 = 'Block12/Layer12 Dropout Percentage'
_decision_Dropoutblock_13 = 'Block13/Layer13 Dropout Percentage'
_decision_Dropoutblock_14 = 'Block14/Layer14 Dropout Percentage'
_decision_Dropoutblock_15 = 'Block15/Layer15 Dropout Percentage'
_decision_Dropoutblock_16 = 'Block16/Layer16 Dropout Percentage'

;
run;
";
						end;
						_verify_modeling_task_="&_CV_modeltask_";

						/* classification, regression or objectdetection */
						if _verify_modeling_task_="classification" or
						_verify_modeling_task_="regression" then do;

							/* update */
							datastep.runCode result=suppress / code="

data casuser._TEMP_DS_RESULTS_;
set casuser._TEMP_DS_RESULTS_;
ch__decision_modelbackbone = input(_decision_modelbackbone, $32.);
ch__decision_actfunction = input(_decision_actfunction, $32.); 
ch__decision_FCactfunc = input(_decision_FCactfunc, $32.);             
ch__decision_fconvo_size = input(_decision_fconvo_size, $32.);   

drop _decision_modelbackbone _decision_actfunction _decision_FCactfunc _decision_fconvo_size;                      
rename ch__decision_modelbackbone=_decision_modelbackbone ch__decision_actfunction=_decision_actfunction ch__decision_FCactfunc=_decision_FCactfunc ch__decision_fconvo_size=_decision_fconvo_size;   

run;
";
							datastep.runCode / code="
data casuser._RESULTS_humanreadable;
RETAIN objVal _evalTime_ _decision_modelbackbone	_decision_actfunction _decision_fconvo_size _decision_gamma	_decision_stepsize	
_decision_minibatch	_decision_lr	_decision_betadiff 
_decision_l1reg _decision_l2reg		_decision_gradclips _decision_FCneuronnum	_decision_FCactfunc	
_decision_Dropoutblock_1_	_decision_Dropoutblock_2	
_decision_Dropoutblock_3	_decision_Dropoutblock_4	_decision_Dropoutblock_5	_decision_Dropoutblock_6	
_decision_Dropoutblock_7	_decision_Dropoutblock_8	_decision_Dropoutblock_9	_decision_Dropoutblock_10	
_decision_Dropoutblock_11	_decision_Dropoutblock_12	_decision_Dropoutblock_13	_decision_Dropoutblock_14	
_decision_Dropoutblock_15	_decision_Dropoutblock_16	_tag_	_inf_	_iter_;		

set casuser._TEMP_DS_RESULTS_;

dropvar_projectionyesno='&_CV_include_FC_layer';
/* change model backbone to human interpretable */
if left(trim(_decision_modelbackbone))='1' then _decision_modelbackbone='resnet50_caffe';
if left(trim(_decision_modelbackbone))='2' then _decision_modelbackbone='Tiny-Yolov2';
if left(trim(_decision_modelbackbone))='3' then _decision_modelbackbone='ShuffleNetV2';
if left(trim(_decision_modelbackbone))='4' then _decision_modelbackbone='ShuffleNetV2_x15';
if left(trim(_decision_modelbackbone))='5' then _decision_modelbackbone='ShuffleNetV2_x20';
if left(trim(_decision_modelbackbone))='6' then _decision_modelbackbone='ShuffleNetV2_x25';
if left(trim(_decision_modelbackbone))='7' then _decision_modelbackbone='Xception';


/* change model activation function to human interpretable */
if left(trim(_decision_actfunction))='8' then _decision_actfunction='ReLU';
if left(trim(_decision_actfunction))='9' then _decision_actfunction='SoftPlus';
if left(trim(_decision_actfunction))='10' then _decision_actfunction='Exponential Linear Unit (ELU)';
if left(trim(_decision_actfunction))='11' then _decision_actfunction='Hyperbolic Tangent';
if left(trim(_decision_actfunction))='12' then _decision_actfunction='Leaky ReLU';

/* change model activation function to human interpretable */
if left(trim(_decision_FCactfunc))='8' then _decision_FCactfunc='ReLU';
if left(trim(_decision_FCactfunc))='9' then _decision_FCactfunc='SoftPlus';
if left(trim(_decision_FCactfunc))='10' then _decision_FCactfunc='Exponential Linear Unit (ELU)';
if left(trim(_decision_FCactfunc))='11' then _decision_FCactfunc='Hyperbolic Tangent';
if left(trim(_decision_FCactfunc))='12' then _decision_FCactfunc='Leaky ReLU';

/* change model activation function to human interpretable */
if left(trim(_decision_fconvo_size))='1' then _decision_fconvo_size='3 by 3';
if left(trim(_decision_fconvo_size))='2' then _decision_fconvo_size='3 by 5';
if left(trim(_decision_fconvo_size))='3' then _decision_fconvo_size='5 by 3';
if left(trim(_decision_fconvo_size))='4' then _decision_fconvo_size='5 by 5';
if left(trim(_decision_fconvo_size))='5' then _decision_fconvo_size='5 by 7';
if left(trim(_decision_fconvo_size))='6' then _decision_fconvo_size='7 by 5';
if left(trim(_decision_fconvo_size))='7' then _decision_fconvo_size='7 by 7';


if _decision_Dropoutblock_1_<0 then _decision_Dropoutblock_1_=0;
if _decision_Dropoutblock_2<0 then _decision_Dropoutblock_2=0;
if _decision_Dropoutblock_3<0 then _decision_Dropoutblock_3=0;
if _decision_Dropoutblock_4<0 then _decision_Dropoutblock_4=0;
if _decision_Dropoutblock_5<0 then _decision_Dropoutblock_5=0;
if _decision_Dropoutblock_6<0 then _decision_Dropoutblock_6=0;
if _decision_Dropoutblock_7<0 then _decision_Dropoutblock_7=0;
if _decision_Dropoutblock_8<0 then _decision_Dropoutblock_8=0;
if _decision_Dropoutblock_9<0 then _decision_Dropoutblock_9=0;
if _decision_Dropoutblock_10<0 then _decision_Dropoutblock_10=0;
if _decision_Dropoutblock_11<0 then _decision_Dropoutblock_11=0;
if _decision_Dropoutblock_12<0 then _decision_Dropoutblock_12=0;
if _decision_Dropoutblock_13<0 then _decision_Dropoutblock_13=0;
if _decision_Dropoutblock_14<0 then _decision_Dropoutblock_14=0;
if _decision_Dropoutblock_15<0 then _decision_Dropoutblock_15=0;
if _decision_Dropoutblock_16<0 then _decision_Dropoutblock_16=0;

if _decision_modelbackbone='Tiny-Yolov2' then _decision_Dropoutblock_16=.;

_decision_Dropoutblock_1_=_decision_Dropoutblock_1_*.05;
_decision_Dropoutblock_2=_decision_Dropoutblock_2*.05;
_decision_Dropoutblock_3=_decision_Dropoutblock_3*.05;
_decision_Dropoutblock_4=_decision_Dropoutblock_4*.05;
_decision_Dropoutblock_5=_decision_Dropoutblock_5*.05;
_decision_Dropoutblock_6=_decision_Dropoutblock_6*.05;
_decision_Dropoutblock_7=_decision_Dropoutblock_7*.05;
_decision_Dropoutblock_8=_decision_Dropoutblock_8*.05;
_decision_Dropoutblock_9=_decision_Dropoutblock_9*.05;
_decision_Dropoutblock_10=_decision_Dropoutblock_10*.05;
_decision_Dropoutblock_11=_decision_Dropoutblock_11*.05;
_decision_Dropoutblock_12=_decision_Dropoutblock_12*.05;
_decision_Dropoutblock_13=_decision_Dropoutblock_13*.05;
_decision_Dropoutblock_14=_decision_Dropoutblock_14*.05;
_decision_Dropoutblock_15=_decision_Dropoutblock_15*.05;
_decision_Dropoutblock_16=_decision_Dropoutblock_16*.05;

label 
objVal = 'Objective Function'
_evalTime_ = 'Evaluation Time'
_decision_modelbackbone = 'Backbone Used'
_decision_actfunction = 'Activation Function'
_decision_fconvo_size = 'Size of First Convo Filter'
_decision_gamma = 'Gamma Value'
_decision_stepsize = 'Stepsize Value'
_decision_minibatch = 'Minibatch Size'
_decision_lr = 'Learning Rate'
_decision_betadiff = 'Difference Between Betas (ADAM)'
_decision_l1reg = 'L1 Regularization'
_decision_l2reg = 'L2 Regularization'
_decision_gradclips = 'Gradient Clips'
_decision_FCneuronnum = 'Number of Filters in 1 by 1 Convo Layer'
_decision_FCactfunc = 'Activation Function Used in 1 by 1 Convo Layer'
_decision_Dropoutblock_1_ = 'Block1/Layer1 Dropout Percentage'
_decision_Dropoutblock_2 = 'Block2/Layer2 Dropout Percentage'
_decision_Dropoutblock_3 = 'Block3/Layer3 Dropout Percentage'
_decision_Dropoutblock_4 = 'Block4/Layer4 Dropout Percentage'
_decision_Dropoutblock_5 = 'Block5/Layer5 Dropout Percentage'
_decision_Dropoutblock_6 = 'Block6/Layer6 Dropout Percentage'
_decision_Dropoutblock_7 = 'Block7/Layer7 Dropout Percentage'
_decision_Dropoutblock_8 = 'Block8/Layer8 Dropout Percentage'
_decision_Dropoutblock_9 = 'Block9/Layer9 Dropout Percentage'
_decision_Dropoutblock_10 = 'Block10/Layer10 Dropout Percentage'
_decision_Dropoutblock_11 = 'Block11/Layer11 Dropout Percentage'
_decision_Dropoutblock_12 = 'Block12/Layer12 Dropout Percentage'
_decision_Dropoutblock_13 = 'Block13/Layer13 Dropout Percentage'
_decision_Dropoutblock_14 = 'Block14/Layer14 Dropout Percentage'
_decision_Dropoutblock_15 = 'Block15/Layer15 Dropout Percentage'
_decision_Dropoutblock_16 = 'Block16/Layer16 Dropout Percentage'


;

/* if dropvar_projectionyesno='no' then do; */
/* drop _decision_FCneuronnum dropvar_projectionyesno _decision_FCactfunc; */
/* end; */


run;
";
						end;
						_verify_modeling_task_="&_CV_modeltask_";

						/* classification, regression or objectdetection */
						if _verify_modeling_task_="multitask" then do;

							/* update */
							datastep.runCode result=suppress / code="

data casuser._TEMP_DS_RESULTS_;
set casuser._TEMP_DS_RESULTS_;
ch__decision_modelbackbone = input(_decision_modelbackbone, $32.);
ch__decision_actfunction = input(_decision_actfunction, $32.); 
ch__decision_fconvo_size = input(_decision_fconvo_size, $32.);   

drop _decision_modelbackbone _decision_actfunction  _decision_fconvo_size;                      
rename ch__decision_modelbackbone=_decision_modelbackbone ch__decision_actfunction=_decision_actfunction ch__decision_fconvo_size = _decision_fconvo_size;   
run;
";
							datastep.runCode / code="
data casuser._RESULTS_humanreadable;
RETAIN objVal _evalTime_ _decision_modelbackbone	_decision_actfunction _decision_fconvo_size _decision_gamma	_decision_stepsize	
_decision_minibatch	_decision_lr	_decision_betadiff 
_decision_l1reg _decision_l2reg		_decision_gradclips &_retainmultitaskdec_		
_decision_Dropoutblock_1_	_decision_Dropoutblock_2	
_decision_Dropoutblock_3	_decision_Dropoutblock_4	_decision_Dropoutblock_5	_decision_Dropoutblock_6	
_decision_Dropoutblock_7	_decision_Dropoutblock_8	_decision_Dropoutblock_9	_decision_Dropoutblock_10	
_decision_Dropoutblock_11	_decision_Dropoutblock_12	_decision_Dropoutblock_13	_decision_Dropoutblock_14	
_decision_Dropoutblock_15	_decision_Dropoutblock_16	_tag_	_inf_	_iter_;		

set casuser._TEMP_DS_RESULTS_;

/* change model backbone to human interpretable */
if left(trim(_decision_modelbackbone))='1' then _decision_modelbackbone='resnet50_caffe';
if left(trim(_decision_modelbackbone))='2' then _decision_modelbackbone='Tiny-Yolov2';
if left(trim(_decision_modelbackbone))='3' then _decision_modelbackbone='ShuffleNetV2';
if left(trim(_decision_modelbackbone))='4' then _decision_modelbackbone='ShuffleNetV2_x15';
if left(trim(_decision_modelbackbone))='5' then _decision_modelbackbone='ShuffleNetV2_x20';
if left(trim(_decision_modelbackbone))='6' then _decision_modelbackbone='ShuffleNetV2_x25';
if left(trim(_decision_modelbackbone))='7' then _decision_modelbackbone='Xception';


/* change model activation function to human interpretable */
if left(trim(_decision_actfunction))='8' then _decision_actfunction='ReLU';
if left(trim(_decision_actfunction))='9' then _decision_actfunction='SoftPlus';
if left(trim(_decision_actfunction))='10' then _decision_actfunction='Exponential Linear Unit (ELU)';
if left(trim(_decision_actfunction))='11' then _decision_actfunction='Hyperbolic Tangent';
if left(trim(_decision_actfunction))='12' then _decision_actfunction='Leaky ReLU';

/* change model activation function to human interpretable */
/* if left(trim(_decision_FCactfunc))='8' then _decision_FCactfunc='ReLU'; */
/* if left(trim(_decision_FCactfunc))='9' then _decision_FCactfunc='SoftPlus'; */
/* if left(trim(_decision_FCactfunc))='10' then _decision_FCactfunc='Exponential Linear Unit (ELU)'; */
/* if left(trim(_decision_FCactfunc))='11' then _decision_FCactfunc='Hyperbolic Tangent'; */
/* if left(trim(_decision_FCactfunc))='12' then _decision_FCactfunc='Leaky ReLU'; */

/* change model activation function to human interpretable */
if left(trim(_decision_fconvo_size))='1' then _decision_fconvo_size='3 by 3';
if left(trim(_decision_fconvo_size))='2' then _decision_fconvo_size='3 by 5';
if left(trim(_decision_fconvo_size))='3' then _decision_fconvo_size='5 by 3';
if left(trim(_decision_fconvo_size))='4' then _decision_fconvo_size='5 by 5';
if left(trim(_decision_fconvo_size))='5' then _decision_fconvo_size='5 by 7';
if left(trim(_decision_fconvo_size))='6' then _decision_fconvo_size='7 by 5';
if left(trim(_decision_fconvo_size))='7' then _decision_fconvo_size='7 by 7';


if _decision_Dropoutblock_1_<0 then _decision_Dropoutblock_1_=0;
if _decision_Dropoutblock_2<0 then _decision_Dropoutblock_2=0;
if _decision_Dropoutblock_3<0 then _decision_Dropoutblock_3=0;
if _decision_Dropoutblock_4<0 then _decision_Dropoutblock_4=0;
if _decision_Dropoutblock_5<0 then _decision_Dropoutblock_5=0;
if _decision_Dropoutblock_6<0 then _decision_Dropoutblock_6=0;
if _decision_Dropoutblock_7<0 then _decision_Dropoutblock_7=0;
if _decision_Dropoutblock_8<0 then _decision_Dropoutblock_8=0;
if _decision_Dropoutblock_9<0 then _decision_Dropoutblock_9=0;
if _decision_Dropoutblock_10<0 then _decision_Dropoutblock_10=0;
if _decision_Dropoutblock_11<0 then _decision_Dropoutblock_11=0;
if _decision_Dropoutblock_12<0 then _decision_Dropoutblock_12=0;
if _decision_Dropoutblock_13<0 then _decision_Dropoutblock_13=0;
if _decision_Dropoutblock_14<0 then _decision_Dropoutblock_14=0;
if _decision_Dropoutblock_15<0 then _decision_Dropoutblock_15=0;
if _decision_Dropoutblock_16<0 then _decision_Dropoutblock_16=0;

if _decision_modelbackbone='Tiny-Yolov2' then _decision_Dropoutblock_16=.;

_decision_Dropoutblock_1_=_decision_Dropoutblock_1_*.05;
_decision_Dropoutblock_2=_decision_Dropoutblock_2*.05;
_decision_Dropoutblock_3=_decision_Dropoutblock_3*.05;
_decision_Dropoutblock_4=_decision_Dropoutblock_4*.05;
_decision_Dropoutblock_5=_decision_Dropoutblock_5*.05;
_decision_Dropoutblock_6=_decision_Dropoutblock_6*.05;
_decision_Dropoutblock_7=_decision_Dropoutblock_7*.05;
_decision_Dropoutblock_8=_decision_Dropoutblock_8*.05;
_decision_Dropoutblock_9=_decision_Dropoutblock_9*.05;
_decision_Dropoutblock_10=_decision_Dropoutblock_10*.05;
_decision_Dropoutblock_11=_decision_Dropoutblock_11*.05;
_decision_Dropoutblock_12=_decision_Dropoutblock_12*.05;
_decision_Dropoutblock_13=_decision_Dropoutblock_13*.05;
_decision_Dropoutblock_14=_decision_Dropoutblock_14*.05;
_decision_Dropoutblock_15=_decision_Dropoutblock_15*.05;
_decision_Dropoutblock_16=_decision_Dropoutblock_16*.05;

label 
objVal = 'Objective Function'
_evalTime_ = 'Evaluation Time'
_decision_modelbackbone = 'Backbone Used'
_decision_actfunction = 'Activation Function'
_decision_fconvo_size = 'Size of First Convo Filter'
_decision_gamma = 'Gamma Value'
_decision_stepsize = 'Stepsize Value'
_decision_minibatch = 'Minibatch Size'
_decision_lr = 'Learning Rate'
_decision_betadiff = 'Difference Between Betas (ADAM)'
_decision_l1reg = 'L1 Regularization'
_decision_l2reg = 'L2 Regularization'
_decision_gradclips = 'Gradient Clips'
&_labelsmultitaskdec_
_decision_Dropoutblock_1_ = 'Block1/Layer1 Dropout Percentage'
_decision_Dropoutblock_2 = 'Block2/Layer2 Dropout Percentage'
_decision_Dropoutblock_3 = 'Block3/Layer3 Dropout Percentage'
_decision_Dropoutblock_4 = 'Block4/Layer4 Dropout Percentage'
_decision_Dropoutblock_5 = 'Block5/Layer5 Dropout Percentage'
_decision_Dropoutblock_6 = 'Block6/Layer6 Dropout Percentage'
_decision_Dropoutblock_7 = 'Block7/Layer7 Dropout Percentage'
_decision_Dropoutblock_8 = 'Block8/Layer8 Dropout Percentage'
_decision_Dropoutblock_9 = 'Block9/Layer9 Dropout Percentage'
_decision_Dropoutblock_10 = 'Block10/Layer10 Dropout Percentage'
_decision_Dropoutblock_11 = 'Block11/Layer11 Dropout Percentage'
_decision_Dropoutblock_12 = 'Block12/Layer12 Dropout Percentage'
_decision_Dropoutblock_13 = 'Block13/Layer13 Dropout Percentage'
_decision_Dropoutblock_14 = 'Block14/Layer14 Dropout Percentage'
_decision_Dropoutblock_15 = 'Block15/Layer15 Dropout Percentage'
_decision_Dropoutblock_16 = 'Block16/Layer16 Dropout Percentage'

;

if dropvar_projectionyesno='no' then do;
drop _decision_FCneuronnum dropvar_projectionyesno _decision_FCactfunc;
end;

run;
";
						end;
					run;

					table.fetch / table={name="_RESULTS_humanreadable", caslib="casuser"} 
						to=10000000 sortby={{name="objVal", order="ascending"}};

					/* don't forget to set up a macro value for this */
					end;
					table.dropCaslib result=suppress / caslib="libres" quiet=TRUE;
					quit;
					;

/***************************************************/

/* FINAL MODEL TRAINING */
/***************************************************/
/*multi-task code setup: */
%NOcreateaddlayermultitask;
;
%NOcreatemultitasklayer;
%check(&_CV_location_for_results_data./&_CV_modelBackbone_..sashdat);

/* done with multi-task code setup */
ods output OptIterHistory=ObjectModeliter;

proc cas;
	%put &_CV_modeltask_;
	_verify_modeling_task_="&_CV_modeltask_";

	/* classification, regression or objectdetection */
	if _verify_modeling_task_ ne "objectdetection" then do;
		loadactionset 'deeplearn';
		loadactionset 'image';
		loadactionset 'table';
		loadactionset 'sampling';
		table.addCasLib result=suppress / name="libres", 
			path="&_CV_location_for_results_data" subdirectories=true;
		table.addCasLib result=suppress / name='libCVmod', 
			path="&_CV_CVmodel_location" subdirectories=true;
		_verify_autotune_init="&_CV_Global_autotune_initiate";
		table.loadTable /caslib="libres", path="&_imageDS_..sashdat"
		casOut={name="&_imageDS_", replace=true};
		_verify_autotune_init="&_CV_Global_autotune_initiate";

		if _verify_autotune_init ne "yes" then do;

			/***************************************************************************/
			/* Apply inverse prior weights for classification target - create variable */
			/***************************************************************************/
			if &_onoff_cntrldcrule_1 and _verify_modeling_task_="classification"
			then do;
				table.loadTable /caslib='libres', path="&_imageDS_..sashdat"
				casOut={name="tempimgdatadrop", replace=true, caslib='casuser'} 
					importOptions={fileType="HDAT"};
				table.alterTable / caslib="libres", name="tempimgdatadrop", 
					drop={"&_insert_imagecolumn"};
				freqTab.freqTab result=per_out_ / table={name="tempimgdatadrop", 
					caslib="casuser"}, tabulate={"&_insert_tarvar_1"} 
					outputTables={names={"OneWayFreqs"={name="tarfreqsper", 
					caslib="casuser"}}};
				datastep.runCode / code="
Data casuser.happydays;
merge casuser.tarfreqsper casuser.tempimgdatadrop;
by &_insert_tarvar_1;
temp_precprior=Percent/100;
central_decision_rule=1/temp_precprior;
keep &_insert_tarvar_1 central_decision_rule _path_;
run;
";
				deepLearn.dlJoin / annotatedTable={name="happydays", caslib="casuser"} 
					casOut={name="&_imageDS_", replace=1, caslib="libres"} id="_path_"
					nthreads=1, joinType="full", table={name="&_imageDS_", caslib="libres"};
				table.dropTable / caslib="casuser", name="happydays", quiet=true;
				table.dropTable / caslib="casuser", name="tempimgdatadrop", quiet=true;
				table.dropTable / caslib="casuser", name="tarfreqsper", quiet=true;
			end;

			/* Resize the images to 224 by 224 */
			image.processImages result=suppress / casout={name="&_imageDS_", replace=1, 
				caslib="libres"} 
				copyVars={&_CVdm_TrgVarList '_path_' &_CV_tarVar_commaname_}
				nThreads=&_insert_imageprepnthreads_ 
				image="&_CV_inpVar_name_", imageTable={name="&_imageDS_", caslib="libres"} 
				imageFunctions={{functionOptions={functionType='RESIZE', 
				height=&_image_input_height_, width=&_image_input_width_}}};
			_verify_image_color="&_image_input_color_";

			/* yes no */
			if _verify_image_color="greyscale" then do;
				image.processImages result=suppress / casout={name="&_imageDS_", 
					replace=True, caslib="libres"} 
					copyVars={&_CVdm_TrgVarList '_path_' &_CV_tarVar_commaname_}
					nThreads=&_insert_imageprepnthreads_  
					image="&_CV_inpVar_name_", 
					imagefunctions={{functionOptions={functionType='CONVERT_COLOR'
					type="COLOR2GRAY"}}} table={name="&_imageDS_", caslib="libres"};
			end;
			_set_train_sample_percent_=100-&_CV_valid_partition_per_;

			/* Create sample for localization model */
			action sampling.srs result=suppress / table={name="&_imageDS_", caslib="libres"} 
				samppct=_set_train_sample_percent_
				sampPct2=&_CV_valid_partition_per_
				seed=&_CV_partition_seed
				partInd=true
				output={casout={name="&_imageDS_", replace="TRUE", caslib="libres", 
				replication=0, maxMemSize=200G, compress=TRUE}, copyvars="ALL", 
				partIndName="&_CV_partition_var_"};

			/* Shuffle data per good practice */
			table.shuffle result=suppress / table={name="&_imageDS_", caslib="libres"} 
				casout={name="&_imageDS_", replace=1, caslib="libres", replication=0, 
				maxMemSize=200G, compress=TRUE};
			;
		end;

		/*end data preparation for when there is no autotune*/;
		_verify_modelbackbone_="&_CV_modelBackbone_";
		_verify_autotune_init="&_CV_Global_autotune_initiate";

		if _verify_autotune_init="yes" then do;
			table.loadTable /caslib='libres', path='autotune_bestweights_.sashdat'
			casOut={name='autotune_bestweights_', replace=true};
			table.loadTable /caslib='libres', path='autotune_bestweights_.ATTRS.sashdat'
			casOut={name='autotune_bestweights__attr', replace=true};
			table.attribute / task='add' name='autotune_bestweights_'
			table='autotune_bestweights__attr';
		end;

		if _verify_autotune_init ne "yes" then do;
			_verify_modelbackbone_="&_CV_modelBackbone_";

			if _verify_modelbackbone_="resnet50_caffe" then do;
				table.loadTable /caslib='libCVmod', path='resnet50_caffe_weights.sashdat'
				casOut={name='resnet50_caffe_weights', replace=true};
				table.loadTable /caslib='libCVmod', 
					path='resnet50_caffe_weights_attr.sashdat'
					casOut={name='resnet50_caffe_weights_attr', replace=true};
				table.attribute / task='add' name='resnet50_caffe_weights'
				table='resnet50_caffe_weights_attr';
			end;

			if _verify_modelbackbone_="Tiny-Yolov2" then do;
				table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights.sashdat'
				casOut={name='Tiny-Yolov2_weights', replace=true};
				table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights_attr.sashdat'
				casOut={name='Tiny-Yolov2_weights_attr', replace=true};
				table.attribute / task='add' name='Tiny-Yolov2_weights'
				table='Tiny-Yolov2_weights_attr';
			end;

			if _verify_modelbackbone_="ShuffleNetV2" or
			_verify_modelbackbone_="ShuffleNetV2_x15" or
			_verify_modelbackbone_="ShuffleNetV2_x20" or
			_verify_modelbackbone_="ShuffleNetV2_x25" then do;
				table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights.sashdat'
				casOut={name='ShuffleNetV2_weights', replace=true};
				table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights_attr.sashdat'
				casOut={name='ShuffleNetV2_weights_attr', replace=true};
				table.attribute / task='add' name='ShuffleNetV2_weights'
				table='ShuffleNetV2_weights_attr';
			end;

			/* NOTE: Using random weights for XceptionNet*/
		end;

		/*********************************/
		/* Classification modeling */
		/*********************************/
		_dec_Drop_out_block_1=&_CV_dropout_block1;
		_dec_Drop_out_block_2=&_CV_dropout_block2;
		_dec_Drop_out_block_3=&_CV_dropout_block3;
		_dec_Drop_out_block_4=&_CV_dropout_block4;
		_dec_Drop_out_block_5=&_CV_dropout_block5;
		_dec_Drop_out_block_6=&_CV_dropout_block6;
		_dec_Drop_out_block_7=&_CV_dropout_block7;
		_dec_Drop_out_block_8=&_CV_dropout_block8;
		_dec_Drop_out_block_9=&_CV_dropout_block9;
		_dec_Drop_out_block__10=&_CV_dropout_block10;
		_dec_Drop_out_block__11=&_CV_dropout_block11;
		_dec_Drop_out_block__12=&_CV_dropout_block12;
		_dec_Drop_out_block__13=&_CV_dropout_block13;
		_dec_Drop_out_block__14=&_CV_dropout_block14;
		_dec_Drop_out_block__15=&_CV_dropout_block15;
		_dec_Drop_out_block__16=&_CV_dropout_block16;

		if _verify_modelbackbone_="resnet50_caffe" then do;
			table.loadTable /caslib='libCVmod', path='resnet50_caffe.sashdat'
			casOut={name='resnet50_caffe', replace=true};

			/*ResNet Apply Dropout to input layer*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};


			/* remove current output layer */
			removelayer / model='resnet50_caffe' name='fc1000';
			mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
			;

			/* Adjust first convo layer filter sizes */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_width"}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_height"}};
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="classification" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

					/* Add a projection layer with Batch Normalization */
					AddLayer result=suppress / model='resnet50_caffe' name='fclayer1'
					layer={type='CONVO' nFilters=&_CV_FC_neuron_num width=1 height=1
					stride=1 act='elu' dropout=&_tm_projdropoutrate} srcLayers={'pool5'};

					/* add new output layer */
					AddLayer result=suppress / model='resnet50_caffe' name='output1'
					layer={type='output' act='SOFTMAX'} srcLayers={'fclayer1'};

					/* change model activation functions */
					_verify_FC_activation_function=&_CV_FC_act_function;

					if _verify_FC_activation_function=11 then 
						_new_FC_activation_value_=(string)6;

					if _verify_FC_activation_function ne 11 then 
						_new_FC_activation_value_=(string)_verify_FC_activation_function;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
					table.update / table=mytbl set={{var="_DLNumVal_", 
						value=_new_FC_activation_value_}};
				end;

				if _verify_FC_include_ ne "yes" then do;

					/* add new output layer */
					AddLayer result=suppress / model='resnet50_caffe' name='output1'
					layer={type='output' act='SOFTMAX'} srcLayers={'pool5'};
				end;
			end;

			/* finished output layer setup for classification model */
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="regression" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

					/* Add a projection layer with Batch Normalization */
					AddLayer result=suppress / model='resnet50_caffe' name='fclayer1'
					layer={type='CONVO' nFilters=&_CV_FC_neuron_num width=1 height=1
					stride=1 act='elu' dropout=&_tm_projdropoutrate} srcLayers={'pool5'};

					/* add new output layer */
					AddLayer result=suppress / model='resnet50_caffe' name='output1'
					layer={type='output' error="&_CV_reg_error"
					act="&_CV_reg_out_act_function"
					targetStd="&_CV_reg_out_standardization"} srcLayers={'fclayer1'};

					/* change model activation functions */
					_verify_FC_activation_function="&_CV_FC_act_function";

					if _verify_FC_activation_function=11 then 
						_new_FC_activation_value_=(string)6;

					if _verify_FC_activation_function ne 11 then 
						_new_FC_activation_value_=(string)_verify_FC_activation_function;
					mytbl.name="resnet50_caffe";
					mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
					table.update / table=mytbl set={{var="_DLNumVal_", 
						value=_new_FC_activation_value_}};
				end;

				if _verify_FC_include_ ne "yes" then do;

					/* add new output layer */
					AddLayer result=suppress / model='resnet50_caffe' name='output1'
					layer={type='output' error="&_CV_reg_error"
					act="&_CV_reg_out_act_function"
					targetStd="&_CV_reg_out_standardization"} srcLayers={'pool5'};
				end;
			end;

			/* finished output layer setup for regression model */
			if _verify_modeling_task_="multitask" then do;
				&_CVdm_addlayercodemultitask;
			end;

			/*****************************/
			/* Remove biase from convo1 */
			/*****************************/
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.no_bias'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};

			/*********************/
			/*Apply Dropout */
			/*********************/
			_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;

			if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
			_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2a_branch1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;

			if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
			_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;

			if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
			_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;

			if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
			_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3a_branch1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;

			if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
			_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;

			if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
			_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;

			if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
			_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3d_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3d_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3d_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;

			if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
			_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4a_branch1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;

			if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
			_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;

			if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
			_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;

			if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
			_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4d_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4d_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4d_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;

			if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
			_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4e_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4e_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4e_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;

			if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
			_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4f_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4f_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4f_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;

			if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
			_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5a_branch1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;

			if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
			_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;

			if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
			_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};

			/* change model activation functions */
			_verify_activation_function=&_CV_act_function;

			if _verify_activation_function=11 then _new_activation_value_=(string)6;

			if _verify_activation_function ne 11 then 
				_new_activation_value_=(string)_verify_activation_function;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			_verify_crop_="&_CV_crop_RESIZE_THENCROP";

			if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_mutation_="&_CV_random_mutate";

			if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;

			if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_fliptype_="&_CV_fliptype_";

			if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;

			if _verify_fliptype_="horizontal" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;

			if _verify_fliptype_="vertical" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
			end;

			if _verify_fliptype_="both" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			/* Change the expected input size - height */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_height_"}};

			/* Change the expected input size - width */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_width_"}};

			/* Change the number of channels to match greyscale if condition exist */
			_verify_image_color="&_image_input_color_";

			/* yes no */
			if _verify_image_color="greyscale" then do;
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
			end;
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;

			if _chk_image_height_<244 or _chk_image_width_<244 then do;

				/* Update Stride for last pool layer */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.stride'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.stride_height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.stride_width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
			end;
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="classification" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='resnet50_caffe'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						&_weghtcodtrain_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='resnet50_caffe'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='resnet50_caffe_weights'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove dropout */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='resnet50_caffe'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_tarVar_name_", "&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End classification model training code  */
			_verify_modeling_task_="&_CV_modeltask_";

			if _verify_modeling_task_="regression" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='resnet50_caffe'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_"
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;

					/* quit; */
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='resnet50_caffe'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='resnet50_caffe_weights'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_"
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove dropout */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='resnet50_caffe'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_tarVar_name_", "&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End regression model training code  */
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression, objectdetection, multitask */
			if _verify_modeling_task_="multitask" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='resnet50_caffe'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						dataSpecs={&_CVdm_dltraincodemultitaskres} GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='resnet50_caffe'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='resnet50_caffe_weights'
						dataSpecs={&_CVdm_dltraincodemultitaskres} GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove dropout */
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="resnet50_caffe";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='resnet50_caffe'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End regression model training code  */
			table.save / saveAttrs=True
			Caslib="libres"
			table="resnet50_caffe"
			name="resnet50_caffe"
			permission="PUBLICWRITE"
			replace=True;
			datastep.runCode / code="
data &insert_outputtable1.;

/*save project path name*/
name='&tempprojpath_lib_';
type='projectpath';
output;

/*save model table name*/
name='resnet50_caffe';
type='modeltable';
output;

/*save model table weights name*/
name='&_CV_finalweightstable_';
type='modelweights';
output;

/*save image height*/
name='&_image_input_height_';
type='imageheight';
output;

/*save image width*/
name='&_image_input_width_';
type='imagewidth';
output;

/*save modeling task*/
name='&_CV_modeltask_';
type='modeltask';
output;


run;
";
		end;

		/* End ResNet50 model setup */
		/************************************/
		/* tiny-YOLOv2 for classification */
		/************************************/
		_verify_modelbackbone_="&_CV_modelBackbone_";

		if _verify_modelbackbone_="Tiny-Yolov2" then do;
			table.loadTable /caslib='libCVmod', path='Tiny-Yolov2.sashdat'
			casOut={name='Tiny-Yolov2', replace=true};

			/*ResNet Apply Dropout to input layer*/
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

			removelayer / model='Tiny-Yolov2' name='detection1';

			/* Adjust first convo layer filter sizes */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_width"}};
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_height"}};
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="classification" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

					/* Add a projection layer with Batch Normalization */
					AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
					layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'};
					AddLayer / model='Tiny-Yolov2' name='poolavg' layer={type='POOL'
					width=0 height=0 stride=1 pool='AVERAGE'} srcLayers={'b_n_9'};
					AddLayer result=suppress / model='Tiny-Yolov2' name='fclayer1'
					layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
					stride=1 act='elu' dropout=&_tm_projdropoutrate} srcLayers={'poolavg'};

					/* add new output layer */
					AddLayer result=suppress / model='Tiny-Yolov2' name='output1'
					layer={type='output' act='SOFTMAX'} srcLayers={'fclayer1'};

					/* change model activation functions */
					_verify_FC_activation_function=&_CV_FC_act_function;

					if _verify_FC_activation_function=11 then 
						_new_FC_activation_value_=(string)6;

					if _verify_FC_activation_function ne 11 then 
						_new_FC_activation_value_=(string)_verify_FC_activation_function;
					mytbl.name="Tiny-Yolov2";
					mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
					table.update / table=mytbl set={{var="_DLNumVal_", 
						value=_new_FC_activation_value_}};
				end;

				if _verify_FC_include_ ne "yes" then do;
					AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
					layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'};
					AddLayer / model='Tiny-Yolov2' name='poolavg' layer={type='POOL'
					width=0 height=0 stride=1 pool='AVERAGE'} srcLayers={'b_n_9'};

					/* add new output layer */
					AddLayer result=suppress / model='Tiny-Yolov2' name='output1'
					layer={type='output' act='SOFTMAX'} srcLayers={'poolavg'};
				end;
			end;
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="regression" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

					/* Add a projection layer with Batch Normalization */
					AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
					layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'};
					AddLayer / model='Tiny-Yolov2' name='poolavg' layer={type='POOL'
					width=0 height=0 stride=1 pool='AVERAGE'} srcLayers={'b_n_9'};
					AddLayer result=suppress / model='Tiny-Yolov2' name='fclayer1'
					layer={type='CONVO' nFilters=_decision_FCneuronnum width=1 height=1
					stride=1 act='elu' dropout=&_tm_projdropoutrate} srcLayers={'poolavg'};

					/* add new output layer */
					AddLayer result=suppress / model='Tiny-Yolov2' name='output1'
					layer={type='output' error="&_CV_reg_error"
					act="&_CV_reg_out_act_function"
					targetStd="&_CV_reg_out_standardization"} srcLayers={'fclayer1'};

					/* change model activation functions */
					_verify_FC_activation_function="&_CV_FC_act_function";

					if _verify_FC_activation_function=11 then 
						_new_FC_activation_value_=(string)6;

					if _verify_FC_activation_function ne 11 then 
						_new_FC_activation_value_=(string)_verify_FC_activation_function;
					mytbl.name="Tiny-Yolov2";
					mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
					table.update / table=mytbl set={{var="_DLNumVal_", 
						value=_new_FC_activation_value_}};
				end;

				if _verify_FC_include_ ne "yes" then do;
					AddLayer result=suppress / model='Tiny-Yolov2' name='b_n_9'
					layer={type='BATCHNORM' act='leaky'} srcLayers={'convo.9'};
					AddLayer / model='Tiny-Yolov2' name='poolavg' layer={type='POOL'
					width=0 height=0 stride=1 pool='AVERAGE'} srcLayers={'b_n_9'};

					/* add new output layer */
					AddLayer result=suppress / model='Tiny-Yolov2' name='output1'
					layer={type='output' error="&_CV_reg_error"
					act="&_CV_reg_out_act_function"
					targetStd="&_CV_reg_out_standardization"} srcLayers={'poolavg'};
				end;
			end;

			if _verify_modeling_task_="multitask" then do;
				&_CVdm_addlayercodemultitask;
			end;

			/* change model activation functions */
			_verify_activation_function=&_CV_act_function;

			if _verify_activation_function=11 then _new_activation_value_=(string)6;

			if _verify_activation_function ne 11 then 
				_new_activation_value_=(string)_verify_activation_function;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Leaky Activation Function'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			verify_apply_dropout="&_CV_dropValue";

			/* if verify_apply_dropout="yes" then do; */
			_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;

			if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
			_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;

			if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
			_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool1' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;

			if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
			_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.2' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;

			if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
			_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool2' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;

			if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
			_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.3' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;

			if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
			_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool3' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;

			if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
			_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.4' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;

			if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
			_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool4' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;

			if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
			_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.5' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;

			if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
			_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;

			if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
			_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.6' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;

			if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
			_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool6' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;

			if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
			_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.7' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;

			if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
			_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.8' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;

			if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
			_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.9' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};

			/* end;  end applying dropout */
			_verify_crop_="&_CV_crop_RESIZE_THENCROP";

			if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_mutation_="&_CV_random_mutate";

			if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;

			if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_fliptype_="&_CV_fliptype_";

			if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;

			if _verify_fliptype_="horizontal" then do;

				/* Apply flipping */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;

			if _verify_fliptype_="vertical" then do;

				/* Apply flipping */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
			end;

			if _verify_fliptype_="both" then do;

				/* Apply flipping */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			/* Change the expected input size - height */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_height_"}};

			/* Change the expected input size - width */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_width_"}};

			/* Change the number of channels to match greyscale if condition exist */
			_verify_image_color="&_image_input_color_";

			/* yes no */
			if _verify_image_color="greyscale" then do;
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
			end;
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="classification" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;

					/*begin Resnet for object detection*/
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Tiny-Yolov2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						&_weghtcodtrain_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				if _verify_autotune_init ne "yes" then do;
					lower_clipgrad=0+&_CV_gradclips_value*-1;

					/*begin Resnet for object detection*/
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Tiny-Yolov2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='Tiny-Yolov2_weights'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/*remove dropout*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'poolingopts.dropout' or  _DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='Tiny-Yolov2'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					copyVars={"&_CV_tarVar_name_", "&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"} 
					ENCODENAME=TRUE;
			end;
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="regression" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;

					/*begin Tiny-Yolov2 for object detection*/
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Tiny-Yolov2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_"
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 					nthreads=32 */
						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				if _verify_autotune_init ne "yes" then do;
					lower_clipgrad=0+&_CV_gradclips_value*-1;

					/*begin Tiny-Yolov2 for object detection*/
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Tiny-Yolov2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='Tiny-Yolov2_weights'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_"
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/*remove dropout*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='Tiny-Yolov2'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					copyVars={"&_CV_tarVar_name_", "&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"} 
					ENCODENAME=TRUE;
			end;
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression, objectdetection, multitask */
			if _verify_modeling_task_="multitask" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;

					/*begin Tiny-Yolov2 for object detection*/
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Tiny-Yolov2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						dataSpecs={&_CVdm_dltraincodemultitasktin} GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				if _verify_autotune_init ne "yes" then do;
					lower_clipgrad=0+&_CV_gradclips_value*-1;

					/*begin Tiny-Yolov2 for object detection*/
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Tiny-Yolov2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='Tiny-Yolov2_weights'
						dataSpecs={&_CVdm_dltraincodemultitasktin} GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove mutations */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* remove crop */
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/*remove dropout*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				/*Reset ResNet Dropout in input layer back to 0*/
				mytbl.name="Tiny-Yolov2";
				mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='Tiny-Yolov2'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					copyVars={"&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"} 
					ENCODENAME=TRUE;
			end;
			table.save / saveAttrs=True
			Caslib="libres"
			table="Tiny-Yolov2"
			name="Tiny-Yolov2"
			permission="PUBLICWRITE"
			replace=True;
			datastep.runCode / code="
data &insert_outputtable1.;
/*save project path name*/
name='&tempprojpath_lib_';
type='projectpath';
output;

/*save model table name*/
name='Tiny-Yolov2';
type='modeltable';
output;

/*save model table weights name*/
name='&_CV_finalweightstable_';
type='modelweights';
output;

/*save image height*/
name='&_image_input_height_';
type='imageheight';
output;

/*save image width*/
name='&_image_input_width_';
type='imagewidth';
output;

/*save modeling task*/
name='&_CV_modeltask_';
type='modeltask';
output;

run;
";
		end;

		/* End Tiny-YOLOv2 model for classification*/
		/************************************/
		/* ShuffleNetV2 for classification */
		/************************************/
		_verify_modelbackbone_="&_CV_modelBackbone_";

		if _verify_modelbackbone_="ShuffleNetV2" or
		_verify_modelbackbone_="ShuffleNetV2_x15" or
		_verify_modelbackbone_="ShuffleNetV2_x20" or
		_verify_modelbackbone_="ShuffleNetV2_x25" then do;
			table.loadTable /caslib='libCVmod', path='ShuffleNetV2.sashdat'
			casOut={name='ShuffleNetV2', replace=true};
			/*ShuffleNetV2 Apply Dropout to input layer*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

			/* step 1 remove output layer - line 922 reference */
			removelayer result=suppress / model='ShuffleNetV2' name='outputlayer_2';
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

			/*adjust complexcity of shuffleNet*/
			if _verify_modelbackbone_="ShuffleNetV2_x15" then do;

				/* Adjust the model complexity */
				/*352.00 to 704.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="704.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="704.00"}};

				/*176.00 to 352.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="352.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="352.00"}};

				/*88.00 to 176.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="176.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="176.00"}};
			end;

			if _verify_modelbackbone_="ShuffleNetV2_x20" then do;

				/* Adjust the model complexity */
				/*352.00 to 976.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="976.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="976.00"}};

				/*176.00 to 488.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="488.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="488.00"}};

				/*88.00 to 244.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="244.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="244.00"}};
			end;

			if _verify_modelbackbone_="ShuffleNetV2_x25" then do;

				/* Adjust the model complexity */
				/*352.00 to 1216.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1248.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1248.00"}};

				/*176.00 to 488.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="624.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="624.00"}};

				/*88.00 to 244.00*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="312.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
				table.update / table=mytbl set={{var="_DLNumVal_", value="312.00"}};

				/* increase convo1 from 24 to 28 filters */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'conv1' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv_2' and  _DLChrVal_ = 'ngroups'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv_2' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = '1x1conv5_out' and  _DLChrVal_ = 'nfilters'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="2048.00"}};
			end;

			/* Adjust first convo layer filter sizes */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_width"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_height"}};
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="classification" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

					/* Add a projection layer with Batch Normalization */
					AddLayer result=suppress / model='ShuffleNetV2' name='fclayer1'
					layer={type='CONVO' nFilters=&_CV_FC_neuron_num width=1 height=1
					stride=1 act='elu' dropout=&_tm_projdropoutrate} 
						srcLayers={'global_avg_pool'};

					/* add new output layer */
					AddLayer result=suppress / model='ShuffleNetV2' name='output1'
					layer={type='output' act='SOFTMAX'} srcLayers={'fclayer1'};

					/* change model activation functions */
					_verify_FC_activation_function=&_CV_FC_act_function;

					if _verify_FC_activation_function=11 then 
						_new_FC_activation_value_=(string)6;

					if _verify_FC_activation_function ne 11 then 
						_new_FC_activation_value_=(string)_verify_FC_activation_function;
					mytbl.name="ShuffleNetV2";
					mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
					table.update / table=mytbl set={{var="_DLNumVal_", 
						value=_new_FC_activation_value_}};
				end;

				if _verify_FC_include_ ne "yes" then do;

					/* add new output layer */
					AddLayer result=suppress / model='ShuffleNetV2' name='output1'
					layer={type='output' act='SOFTMAX'} srcLayers={'global_avg_pool'};
				end;
			end;

			/* finished output layer setup for classification model */
			if _verify_modeling_task_="regression" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

					/* Add a projection layer with Batch Normalization */
					AddLayer result=suppress / model='ShuffleNetV2' name='fclayer1'
					layer={type='CONVO' nFilters=&_CV_FC_neuron_num width=1 height=1
					stride=1 act='elu' dropout=&_tm_projdropoutrate} 
						srcLayers={'global_avg_pool'};

					/* add new output layer */
					AddLayer result=suppress / model='ShuffleNetV2' name='output1'
					layer={type='output' error="&_CV_reg_error"
					act="&_CV_reg_out_act_function"
					targetStd="&_CV_reg_out_standardization"} srcLayers={'fclayer1'};

					/* change model activation functions */
					_verify_FC_activation_function="&_CV_FC_act_function";

					if _verify_FC_activation_function=11 then 
						_new_FC_activation_value_=(string)6;

					if _verify_FC_activation_function ne 11 then 
						_new_FC_activation_value_=(string)_verify_FC_activation_function;
					mytbl.name="ShuffleNetV2";
					mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
					table.update / table=mytbl set={{var="_DLNumVal_", 
						value=_new_FC_activation_value_}};
				end;

				if _verify_FC_include_ ne "yes" then do;

					/* add new output layer */
					AddLayer result=suppress / model='ShuffleNetV2' name='output1'
					layer={type='output' error="&_CV_reg_error"
					act="&_CV_reg_out_act_function"
					targetStd="&_CV_reg_out_standardization"} srcLayers={'global_avg_pool'};
				end;
			end;

			/* finished output layer setup for regression model */
			if _verify_modeling_task_="multitask" then do;
				&_CVdm_addlayercodemultitask;
			end;
			_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;

			if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
			_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;

			if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
			_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;

			if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
			_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;

			if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
			_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;

			if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
			_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;

			if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
			_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;

			if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
			_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;

			if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
			_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;

			if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
			_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block5/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;

			if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
			_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block6/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;

			if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
			_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block7/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;

			if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
			_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block8/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;

			if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
			_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage4/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;

			if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
			_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage4/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;

			if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
			_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage4/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;

			if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
			_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage4/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};

			/* change model activation functions */
			_verify_activation_function=&_CV_act_function;

			if _verify_activation_function=11 then _new_activation_value_=(string)6;

			if _verify_activation_function ne 11 then 
				_new_activation_value_=(string)_verify_activation_function;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			_verify_crop_="&_CV_crop_RESIZE_THENCROP";

			if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_mutation_="&_CV_random_mutate";

			if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;

			if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_fliptype_="&_CV_fliptype_";

			if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;

			if _verify_fliptype_="horizontal" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;

			if _verify_fliptype_="vertical" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
			end;

			if _verify_fliptype_="both" then do;

				/* Apply flipping */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			/* Change the expected input size - height */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_height_"}};

			/* Change the expected input size - width */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_width_"}};

			/* Change the number of channels to match greyscale if condition exist */
			_verify_image_color="&_image_input_color_";

			/* yes no */
			if _verify_image_color="greyscale" then do;
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
			end;
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;

			if _chk_image_height_<244 or _chk_image_width_<244 then do;

				/* Update Stride for last pool layer */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.stride'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.stride_height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.stride_width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'global_avg_pool' and  _DLKey1_ = 'poolingopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="classification" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='ShuffleNetV2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F
						&_weghtcodtrain_
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='ShuffleNetV2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='ShuffleNetV2_weights'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F

						/* 		weight="weight" */
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* Remove dropout */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset ShuffleNetV2 Dropout in input layer back to 0*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='ShuffleNetV2'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_tarVar_name_", "&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End classification model training code  */
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="regression" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;

					/* proc cas; */
					/* _set_beta1_value=.999-&_CV_betadiff_value_+0; */
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='ShuffleNetV2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_"
						GPU=&_CV_usegpu_T_F

						/* 		weight="weight" */
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='ShuffleNetV2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='ShuffleNetV2_weights'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_"
						GPU=&_CV_usegpu_T_F

						/* 		weight="weight" */
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* Remove dropout */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset ShuffleNetV2 Dropout in input layer back to 0*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='ShuffleNetV2'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_tarVar_name_", "&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End regression model training code  */
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression, objectdetection, multitask */
			if _verify_modeling_task_="multitask" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='ShuffleNetV2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						dataSpecs={&_CVdm_dltraincodemultitaskshuf} GPU=&_CV_usegpu_T_F

						/* 		weight="weight" */
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='ShuffleNetV2'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='ShuffleNetV2_weights'
						dataSpecs={&_CVdm_dltraincodemultitaskshuf} GPU=&_CV_usegpu_T_F

						/* 		weight="weight" */
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=1, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for OD model scoring and deployment */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

				/* Remove dropout */
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey1_ = 'groupconvopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset ShuffleNetV2 Dropout in input layer back to 0*/
				mytbl.name="ShuffleNetV2";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='ShuffleNetV2'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End regression model training code  */
			table.save / saveAttrs=True
			Caslib="libres"
			table="ShuffleNetV2"
			name="ShuffleNetV2"
			permission="PUBLICWRITE"
			replace=True;
			datastep.runCode / code="
data &insert_outputtable1.;
/*save project path name*/
name='&tempprojpath_lib_';
type='projectpath';
output;

/*save model table name*/
name='ShuffleNetV2';
type='modeltable';
output;

/*save model table weights name*/
name='&_CV_finalweightstable_';
type='modelweights';
output;

/*save image height*/
name='&_image_input_height_';
type='imageheight';
output;

/*save image width*/
name='&_image_input_width_';
type='imagewidth';
output;

/*save modeling task*/
name='&_CV_modeltask_';
type='modeltask';
output;

run;
";
		end;

		/* End ShuffleNetV2 model setup */
		/************************************/
		/* Xception for classification */
		/************************************/
		if _verify_modelbackbone_="Xception" then do;
			table.loadTable /caslib='libCVmod', path='Xception.sashdat'
			casOut={name='Xception', replace=true};
			/*Xception Apply Dropout to input layer*/
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};


			/* remove current output layer */
			removelayer result=suppress / model='Xception' name='outlayer';
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

			/* Adjust first convo layer filter sizes */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_width"}};
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_height"}};

			/* 						mytbl.name  ="Xception";  */
			/* 						mytbl.where = "_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.width'"; */
			/* 						table.update /  table=mytbl  set = {{var="_DLNumVal_", value="&mac_firstConvo_width"}}; */
			/* 						mytbl.name  ="Xception";  */
			/* 						mytbl.where = "_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.height'"; */
			/* 						table.update /  table=mytbl  set = {{var="_DLNumVal_", value="&mac_firstConvo_height"}}; */
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="classification" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

					/* Add a projection layer with Batch Normalization */
					AddLayer result=suppress / model='Xception' name='fclayer1'
					layer={type='CONVO' nFilters=&_CV_FC_neuron_num width=1 height=1
					stride=1 act='elu' dropout=&_tm_projdropoutrate} 
						srcLayers={'final_avepool'};

					/* add new output layer */
					AddLayer result=suppress / model='Xception' name='outlayer'
					layer={type='output' act='SOFTMAX'} srcLayers={'fclayer1'};

					/* change model activation functions */
					_verify_FC_activation_function=&_CV_FC_act_function;

					if _verify_FC_activation_function=11 then 
						_new_FC_activation_value_=(string)6;

					if _verify_FC_activation_function ne 11 then 
						_new_FC_activation_value_=(string)_verify_FC_activation_function;
					mytbl.name="Xception";
					mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
					table.update / table=mytbl set={{var="_DLNumVal_", 
						value=_new_FC_activation_value_}};
				end;

				if _verify_FC_include_ ne "yes" then do;

					/* add new output layer */
					AddLayer result=suppress / model='Xception' name='outlayer'
					layer={type='output' act='SOFTMAX'} srcLayers={'final_avepool'};
				end;
			end;

			/* finished output layer setup for classification model */
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="regression" then do;
				_verify_FC_include_="&_CV_include_FC_layer";

				/* include FC layer for class and reg task?   */
				if _verify_FC_include_="yes" then do;

					/* Add a projection layer with Batch Normalization */
					AddLayer result=suppress / model='Xception' name='fclayer1'
					layer={type='CONVO' nFilters=&_CV_FC_neuron_num width=1 height=1
					stride=1 act='elu' dropout=&_tm_projdropoutrate} 
						srcLayers={'final_avepool'};

					/* add new output layer */
					AddLayer result=suppress / model='Xception' name='outlayer'
					layer={type='output' error="&_CV_reg_error"
					act="&_CV_reg_out_act_function"
					targetStd="&_CV_reg_out_standardization"} srcLayers={'fclayer1'};

					/* change model activation functions */
					_verify_FC_activation_function="&_CV_FC_act_function";

					if _verify_FC_activation_function=11 then 
						_new_FC_activation_value_=(string)6;

					if _verify_FC_activation_function ne 11 then 
						_new_FC_activation_value_=(string)_verify_FC_activation_function;
					mytbl.name="Xception";
					mytbl.where="_DLKey0_ = 'fclayer1' and  _DLKey1_ = 'fcopts.act'";
					table.update / table=mytbl set={{var="_DLNumVal_", 
						value=_new_FC_activation_value_}};
				end;

				if _verify_FC_include_ ne "yes" then do;

					/* add new output layer */
					AddLayer result=suppress / model='Xception' name='outlayer'
					layer={type='output' error="&_CV_reg_error"
					act="&_CV_reg_out_act_function"
					targetStd="&_CV_reg_out_standardization"} srcLayers={'final_avepool'};
				end;
			end;

			/* finished output layer setup for regression model */
			if _verify_modeling_task_="multitask" then do;
				&_CVdm_addlayercodemultitask;
			end;

			/*********************/
			/*Apply Dropout */
			/*********************/
			_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;

			if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
			_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;

			if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
			_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;

			if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
			_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_1seperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;

			if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
			_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_1seperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;

			if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
			_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_2reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;

			if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
			_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_3reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;

			if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
			_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_4reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;

			if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
			_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_5reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;

			if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
			_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_6reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;

			if _dec_update_Drop_out_block__10<0 then _dec_update_Drop_out_block__10=0;
			_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_7reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;

			if _dec_update_Drop_out_block__11<0 then _dec_update_Drop_out_block__11=0;
			_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_8reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;

			if _dec_update_Drop_out_block__12<0 then _dec_update_Drop_out_block__12=0;
			_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_9reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;

			if _dec_update_Drop_out_block__13<0 then _dec_update_Drop_out_block__13=0;
			_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_10reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;

			if _dec_update_Drop_out_block__14<0 then _dec_update_Drop_out_block__14=0;
			_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_11reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;

			if _dec_update_Drop_out_block__15<0 then _dec_update_Drop_out_block__15=0;
			_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_12reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;

			if _dec_update_Drop_out_block__16<0 then _dec_update_Drop_out_block__16=0;
			_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'seperablebnrelu_exit1__pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};

			/* change model activation functions */
			_verify_activation_function=&_CV_act_function;

			if _verify_activation_function=11 then _new_activation_value_=(string)6;

			if _verify_activation_function ne 11 then 
				_new_activation_value_=(string)_verify_activation_function;
			mytbl.name="Xception";
			mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			mytbl.name="Xception";
			mytbl.where="_DLKey1_ = 'reshapeopts.act' and  _DLChrVal_ = 'Rectifier'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			_verify_crop_="&_CV_crop_RESIZE_THENCROP";

			if _verify_crop_="RESIZETHENCROP" then do;

				/* Apply crop */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			if _verify_crop_="none" then do;

				/* Apply no crop */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_mutation_="&_CV_random_mutate";

			if _verify_mutation_="random" then do;

				/* Apply mutations */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;

			if _verify_mutation_="none" then do;

				/* Apply mutations */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_fliptype_="&_CV_fliptype_";

			if _verify_fliptype_="none" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;

			if _verify_fliptype_="horizontal" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;

			if _verify_fliptype_="vertical" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
			end;

			if _verify_fliptype_="both" then do;

				/* Apply flipping */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			/* Change the expected input size - height */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_height_"}};

			/* Change the expected input size - width */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_width_"}};

			/* Change the number of channels to match greyscale if condition exist */
			_verify_image_color="&_image_input_color_";

			/* yes no */
			if _verify_image_color="greyscale" then do;
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
			end;
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;

			if _chk_image_height_<244 or _chk_image_width_<244 then do;

				/* Update Stride for last pool layer */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.stride'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.stride_height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.stride_width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.height'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'final_avepool' and  _DLKey1_ = 'poolingopts.width'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='0'}};
			end;
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="classification" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Xception'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						&_weghtcodtrain_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Xception'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						/* 						initWeights='Xceptionweights' */
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_" nominal={"&_CV_tarVar_name_"} 
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						&_weghtcodtrain_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for classification model scoring and deployment */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Xception Dropout in input layer back to 0*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='Xception'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_tarVar_name_", "&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End classification model training code  */
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			if _verify_modeling_task_="regression" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;

					/* proc cas; */
					/* _set_beta1_value=.999-&_CV_betadiff_value_+0; */
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Xception'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_"
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;

					/* quit; */
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Xception'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='resnet50_caffe_weights'
						inputs="&_CV_inpVar_name_"
						target="&_CV_tarVar_name_"
						GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for classification model scoring and deployment */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Xception Dropout in input layer back to 0*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='Xception'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_tarVar_name_", "&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End regression model training code  */
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression, objectdetection, multitask */
			if _verify_modeling_task_="multitask" then do;
				_set_beta1_value=.999-&_CV_betadiff_value_+0;
				_verify_autotune_init="&_CV_Global_autotune_initiate";

				if _verify_autotune_init="yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Xception'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						initWeights='autotune_bestweights_'
						dataSpecs={&_CVdm_dltraincodemultitaskres} GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=_new_final_lr, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;

					/* quit; */
				end;

				/* no autotune applied training: */
				if _verify_autotune_init ne "yes" then do;
					_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
					lower_clipgrad=0+&_CV_gradclips_value*-1;
					deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
						model='Xception'
						modelWeights={name='ConVTrainedWeights_d', replace=1} 
						bestweights={name="&_CV_finalweightstable_", replace=1} 
						/* 						initWeights='Xceptionweights' */
						dataSpecs={&_CVdm_dltraincodemultitaskres} GPU=&_CV_usegpu_T_F
						nthreads=&n_threads_

						/* 		weight="weight" */
						ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
						optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
						lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
						learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
						clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad} loglevel=2, 
						regL1=&_CV_l1reg_value_, regL2=&_CV_l2reg_value_, 
						maxepochs=&_CV_num_epochs_} seed=12345;
				end;

				/* return flipping back to "no flip" for classification model scoring and deployment */
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
				table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
				mytbl.name="Xception";
				mytbl.where="_DLKey1_ = 'convopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
				/*Reset Xception Dropout in input layer back to 0*/
				mytbl.name="Xception";
				mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
				table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

				deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
					model='Xception'
					initWeights="&_CV_finalweightstable_"
					gpu=&_CV_usegpu_T_F
					ENCODENAME=TRUE
					copyVars={"&_CV_partition_var_", "&_CV_inpVar_name_"} 
					casout={name="tempscoreddata", replace=1, caslib="casuser"};
			end;

			/* End regression model training code  */
			table.save / saveAttrs=True
			Caslib="libres"
			table="Xception"
			name="Xception"
			permission="PUBLICWRITE"
			replace=True;
			datastep.runCode / code="
data &insert_outputtable1.;
/*save project path name*/
name='&tempprojpath_lib_';
type='projectpath';
output;

/*save model table name*/
name='Xception';
type='modeltable';
output;

/*save model table weights name*/
name='&_CV_finalweightstable_';
type='modelweights';
output;

/*save image height*/
name='&_image_input_height_';
type='imageheight';
output;

/*save image width*/
name='&_image_input_width_';
type='imagewidth';
output;

/*save modeling task*/
name='&_CV_modeltask_';
type='modeltask';
output;


run;
";
		end;

		/* End Xception model setup */
	end;
	%PUT &_CV_modeltask_;
	_verify_modeling_task_="&_CV_modeltask_";

	/* classification, regression or objectdetection */
	if _verify_modeling_task_="objectdetection" then do;
		loadactionset 'deeplearn';
		loadactionset 'image';
		loadactionset 'table';
		loadactionset 'sampling';

		/* 		table.addCaslib / name="&_CV_caslib_" path='/mnt/viya-share/data/Cifar10/' */
		subdirectories=true;
		table.addCasLib result=suppress / name='libCVmod', 
			path="&_CV_CVmodel_location" subdirectories=true;
		table.addCasLib result=suppress / name="libres", 
			path="&_CV_location_for_results_data" subdirectories=true;
		table.loadTable /caslib="libres", path="&_imageDS_..sashdat"
		casOut={name="&_imageDS_", replace=true} importOptions={fileType="HDAT"};
		_verify_autotune_init="&_CV_Global_autotune_initiate";

		if _verify_autotune_init ne "yes" then do;
			* Create set up variables *;
			name="_Object";
			appendNames={"_", "_x", "_y", "_width", "_height"};
			_ObjectTargets_={"_nObjects_"};
			* Create the ObjectsTarget variable with the list of names *;
			i=0;

			do until (i=&_CV_object_num_);

				/*     do i over {0,1,2}; */
				do col over appendNames;
					value=name || i || col;
					_ObjectTargets_=_ObjectTargets_ + value;
				end;
				i=i+1;
			end;

				/*break data apart to prevent memory overload*/
			action sampling.srs result=suppress / table={name="&_imageDS_", caslib="libres"} 
				samppct=33
				sampPct2=33
				seed=12345
				partInd=true
				output={casout={name="&_imageDS_", replace="TRUE", caslib="libres"}, copyvars="ALL", 
				partIndName="_only1_3_sample_"};


				image.processImages result=suppress / casout={name="&_imageDS_.v0", replace=1, 
					caslib="libres"} 
					copyVars=_ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", imageTable={name="&_imageDS_", caslib="libres", where="_only1_3_sample_=0"} 
					imageFunctions={{functionOptions={functionType='RESIZE', 
					height=&_image_input_height_, width=&_image_input_width_}}};
				_verify_image_color="&_image_input_color_";
				if _verify_image_color="greyscale" then do;
				image.processImages result=suppress / casout={name="&_imageDS_.v0", 
					replace=True, caslib="libres"} copyVars=ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", 
					imagefunctions={{functionOptions={functionType='CONVERT_COLOR'
					type="COLOR2GRAY"}}} table={name="&_imageDS_.v0", caslib="libres"};
				end;

				image.processImages result=suppress / casout={name="&_imageDS_.v1", replace=1, 
					caslib="libres"} 
					copyVars=_ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", imageTable={name="&_imageDS_", caslib="libres", where="_only1_3_sample_=1"} 
					imageFunctions={{functionOptions={functionType='RESIZE', 
					height=&_image_input_height_, width=&_image_input_width_}}};
				_verify_image_color="&_image_input_color_";
				if _verify_image_color="greyscale" then do;
				image.processImages result=suppress / casout={name="&_imageDS_.v1", 
					replace=True, caslib="libres"} copyVars=ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", 
					imagefunctions={{functionOptions={functionType='CONVERT_COLOR'
					type="COLOR2GRAY"}}} table={name="&_imageDS_.v1", caslib="libres"};
				end;

				image.processImages result=suppress / casout={name="&_imageDS_.v2", replace=1, 
					caslib="libres"} 
					copyVars=_ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", imageTable={name="&_imageDS_", caslib="libres", where="_only1_3_sample_=2"} 
					imageFunctions={{functionOptions={functionType='RESIZE', 
					height=&_image_input_height_, width=&_image_input_width_}}};
				_verify_image_color="&_image_input_color_";
				if _verify_image_color="greyscale" then do;
				image.processImages result=suppress / casout={name="&_imageDS_.v2", 
					replace=True, caslib="libres"} copyVars=ObjectTargets_
					nThreads=&_insert_imageprepnthreads_ 
					image="&_CV_inpVar_name_", 
					imagefunctions={{functionOptions={functionType='CONVERT_COLOR'
					type="COLOR2GRAY"}}} table={name="&_imageDS_.v2", caslib="libres"};
				end;

				deepLearn.dlJoin /                                 
				annotatedTable={name="&_imageDS_.v1", caslib="libres"}
				casOut={name="&_imageDS_.v0_1", caslib="libres", replace=1}
				joinType="Append"
				table={name="&_imageDS_.v0", caslib="libres"};

				table.dropTable / caslib="libres", name="&_imageDS_.v0", quiet=TRUE;
				table.dropTable / caslib="libres", name="&_imageDS_.v1", quiet=TRUE;

				deepLearn.dlJoin /                                 
				annotatedTable={name="&_imageDS_.v2", caslib="libres"}
				casOut={name="&_imageDS_", caslib="libres", replace=1}
				joinType="Append"
				table={name="&_imageDS_.v0_1", caslib="libres"};

				table.dropTable / caslib="libres", name="&_imageDS_.v0_1", quiet=TRUE;
				table.dropTable / caslib="libres", name="&_imageDS_.v2", quiet=TRUE;

				table.alterTable / caslib="libres", name="&_imageDS_", drop="_only1_3_sample_";

				/*DONE: breaking data apart to prevent memory overload*/
			_set_train_sample_percent_=100-&_CV_valid_partition_per_;

			/* Create sample for localization model */
			action sampling.srs result=suppress / table={name="&_imageDS_", caslib="libres"} 
				samppct=_set_train_sample_percent_
				sampPct2=&_CV_valid_partition_per_ seed=&_CV_partition_seed partInd=true
				output={casout={name="&_imageDS_", replace="TRUE", caslib="libres", 
				replication=0, maxMemSize=200G, compress=TRUE}, copyvars="ALL", 
				partIndName="&_CV_partition_var_"};

			/*************************************************/
			/* Ensure consistent format across object vars */
			/*************************************************/
			if &_insert_OD_classcount > 1 then do;
				table.shuffle / table={name="&_imageDS_", caslib="libres", 
					computedVars={{name="_uniqueid_"}}, computedVarsProgram="_uniqueid_=left(strip(idjoin))||left(strip(_size_))||left(strip(put(_threadid_,8.)))||strip(trim(Put(_n_,8.)));"} 
					casout={name='imgdata_w_id', replace=true, caslib="casuser", 
					replication=0, maxMemSize=200G, compress=TRUE};
				table.copyTable / table={name='imgdata_w_id', caslib="casuser"} 
					casout={name="imgdata_w_id_copy" caslib="casuser", replace=1};
				table.alterTable / name="imgdata_w_id_copy" caslib="casuser"
				keep={"_uniqueid_", "_image_"};
				table.alterTable / name="imgdata_w_id" caslib="casuser"
				drop={"_image_"};
				tbl={name='imgdata_w_id', caslib='casuser'};
				table.columnInfo result=ci / table=tbl;

				/* Get all varchar and char columns */
				rtbl=ci
				.ColumnInfo[, {"Column", "Type", "rawLength"}] 
					.where(lowcase(Type)='varchar');

				/* Find the max length of a char or varchar column */
				maxCharLength=max(rtbl[, 'rawLength']);

				/* Makes them all CHAR, so if there is varchar an if condition will be required */
				lengthStatement='length ';

				do colName over getcolumn(rtbl, 'column');
					LengthStatement=cat(lengthStatement, colName, cat(' varchar(', 
						maxCharLength, ') '));
					print LengthStatement;
				end;
				LengthStatement=cat(" ", lengthStatement, '; ');
				print LengthStatement;

				/* Add dynamic length statement from loop */
				createNewCasTable=tranwrd("&_CVdm_odfixformatsv2", '$AddLengthStatement', 
					LengthStatement);
				print createNewCasTable;
				call symputx('_CVdm_odfixformatsv2c', createNewCasTable, 'G');
			run;

			/* Run the code */
			dataStep.runCode / 
				code="&_CVdm_odfixformatsv1"|| createNewCasTable || "&_CVdm_odfixformatsv3";
			deepLearn.dlJoin / annotatedTable={name="new_cas_table_maxLengths", 
				caslib="casuser"} casOut={name="&_imageDS_", caslib="libres", replace=1, 
				replication=0, maxMemSize=200G, compress=TRUE} id="_uniqueid_"
				table={name="imgdata_w_id_copy", caslib="casuser"};
			table.dropTable / caslib="casuser", name="imgdata_w_id_copy", quiet=TRUE;
			table.dropTable / caslib="casuser", name="new_cas_table_maxLengths", 
				quiet=TRUE;
			table.dropTable / caslib="casuser", name="imgdata_w_id", quiet=TRUE;
			end;
			end;

			/*end data preparation for when there is no autotune*/;
			_verify_autotune_init="&_CV_Global_autotune_initiate";
			if _verify_autotune_init="yes" then do;
			table.loadTable /caslib='libres', path='autotune_bestweights_.sashdat'
			casOut={name='autotune_bestweights_', replace=true};
			table.loadTable /caslib='libres', path='autotune_bestweights_.ATTRS.sashdat'
			casOut={name='autotune_bestweights__attr', replace=true};
			table.attribute / task='add' name='autotune_bestweights_'
			table='autotune_bestweights__attr';
			end;
			_verify_modelbackbone_="&_CV_modelBackbone_";
			_verify_autotune_init="&_CV_Global_autotune_initiate";
			if _verify_autotune_init ne "yes" then do;
			if _verify_modelbackbone_="resnet50_caffe" then do;
			table.loadTable /caslib='libCVmod', path='resnet50_caffe_weights.sashdat'
			casOut={name='resnet50_caffe_weights', replace=true};
			table.loadTable /caslib='libCVmod', 
				path='resnet50_caffe_weights_attr.sashdat'
				casOut={name='resnet50_caffe_weights_attr', replace=true};
			table.attribute / task='add' name='resnet50_caffe_weights'
			table='resnet50_caffe_weights_attr';
			end;
			if _verify_modelbackbone_="Tiny-Yolov2" then do;
			table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights.sashdat'
			casOut={name='Tiny-Yolov2_weights', replace=true};
			table.loadTable /caslib='libCVmod', path='Tiny-Yolov2_weights_attr.sashdat'
			casOut={name='Tiny-Yolov2_weights_attr', replace=true};
			table.attribute / task='add' name='Tiny-Yolov2_weights'
			table='Tiny-Yolov2_weights_attr';
			end;
			if _verify_modelbackbone_="ShuffleNetV2" or
			_verify_modelbackbone_="ShuffleNetV2_x15" or
			_verify_modelbackbone_="ShuffleNetV2_x20" or
			_verify_modelbackbone_="ShuffleNetV2_x25" then do;
			table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights.sashdat'
			casOut={name='ShuffleNetV2_weights', replace=true};
			table.loadTable /caslib='libCVmod', path='ShuffleNetV2_weights_attr.sashdat'
			casOut={name='ShuffleNetV2_weights_attr', replace=true};
			table.attribute / task='add' name='ShuffleNetV2_weights'
			table='ShuffleNetV2_weights_attr';
			end;

			/* NOTE: Using random weights for XceptionNet*/
			end;
			_dec_Drop_out_block_1=&_CV_dropout_block1;
			_dec_Drop_out_block_2=&_CV_dropout_block2;
			_dec_Drop_out_block_3=&_CV_dropout_block3;
			_dec_Drop_out_block_4=&_CV_dropout_block4;
			_dec_Drop_out_block_5=&_CV_dropout_block5;
			_dec_Drop_out_block_6=&_CV_dropout_block6;
			_dec_Drop_out_block_7=&_CV_dropout_block7;
			_dec_Drop_out_block_8=&_CV_dropout_block8;
			_dec_Drop_out_block_9=&_CV_dropout_block9;
			_dec_Drop_out_block__10=&_CV_dropout_block10;
			_dec_Drop_out_block__11=&_CV_dropout_block11;
			_dec_Drop_out_block__12=&_CV_dropout_block12;
			_dec_Drop_out_block__13=&_CV_dropout_block13;
			_dec_Drop_out_block__14=&_CV_dropout_block14;
			_dec_Drop_out_block__15=&_CV_dropout_block15;
			_dec_Drop_out_block__16=&_CV_dropout_block16;
			verify_apply_dropout="&_CV_dropValue";
			* Create set up variables *;
			name="_Object";
			appendNames={"_", "_x", "_y", "_width", "_height"};
			_ObjectTargets_={"_nObjects_"};
			* Create the ObjectsTarget variable with the list of names *;
			i=0;
			do until (i=&_CV_object_num_);

			/*     do i over {0,1,2}; */
			do col over appendNames;
			value=name || i || col;
			_ObjectTargets_=_ObjectTargets_ + value;
			end;
			i=i+1;
			end;
			_verify_modelbackbone_="&_CV_modelBackbone_";
			if _verify_modelbackbone_="resnet50_caffe" then do;
			table.loadTable /caslib='libCVmod', path='resnet50_caffe.sashdat'
			casOut={name='resnet50_caffe', replace=true};

			/*ResNet Apply Dropout to input layer*/
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};


			/* remove current output layer */
			removelayer / model='resnet50_caffe' name='fc1000';

			/* remove pool layer before output because task=object detection */
			removelayer result=suppress / model='resnet50_caffe' name='pool5';

			/* Adjust first convo layer filter sizes */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_width"}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_height"}};

			/* add new output layer */
			/* Depth = predictionsPerGrid + (ClassNumber + CoorNumber + 1)  */
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;

			/*****************************/
			/* Remove biase from convo1 */
			/*****************************/
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.no_bias'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};

			/*********************/
			/*Apply Dropout */
			/*********************/
			/* if verify_apply_dropout="yes" then do; */
			_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
			if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
			_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2a_branch1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
			if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
			_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
			if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
			_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res2c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
			if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
			_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3a_branch1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
			if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
			_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
			if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
			_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
			if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
			_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3d_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3d_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res3d_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
			if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
			_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4a_branch1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
			if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
			_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
			if _dec_update_Drop_out_block__10<0 then
			_dec_update_Drop_out_block__10=0;
			_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
			if _dec_update_Drop_out_block__11<0 then
			_dec_update_Drop_out_block__11=0;
			_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4d_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4d_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4d_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
			if _dec_update_Drop_out_block__12<0 then
			_dec_update_Drop_out_block__12=0;
			_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4e_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4e_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4e_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
			if _dec_update_Drop_out_block__13<0 then
			_dec_update_Drop_out_block__13=0;
			_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4f_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4f_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res4f_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
			if _dec_update_Drop_out_block__14<0 then
			_dec_update_Drop_out_block__14=0;
			_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5a_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5a_branch1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5a_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5a_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
			if _dec_update_Drop_out_block__15<0 then
			_dec_update_Drop_out_block__15=0;
			_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5b_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5b_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5b_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;
			if _dec_update_Drop_out_block__16<0 then
			_dec_update_Drop_out_block__16=0;
			_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5c_branch2a' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5c_branch2b' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'res5c_branch2c' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};

			/* end;  end applying dropout */
			_OD_depth=&_CV_OD_preds_per_grid * (&_CV_OD_class_num + 5)+0;
			AddLayer result=suppress / model='resnet50_caffe' name='_convolast_'
			layer={type='CONVO'
			nFilters=_OD_depth
			width=&_CV_OD_lastConvo_width height=&_CV_OD_lastConvo_height
			stride=1 act='identity' includeBias=FALSE} srcLayers={'res5c'};

			/* change model activation functions */
			_verify_activation_function=&_CV_act_function;
			if _verify_activation_function=11 then _new_activation_value_=(string)6;
			if _verify_activation_function ne 11 then
			_new_activation_value_=(string)_verify_activation_function;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			_update_grid_size=0+0;
			if _chk_image_height_=224 or _chk_image_width_=224 then
			_update_grid_size=7;
			if _chk_image_height_=416 or _chk_image_width_=416 then
			_update_grid_size=13;
			if _chk_image_height_=640 or _chk_image_width_=640 then
			_update_grid_size=20;
			if _chk_image_height_=1280 or _chk_image_width_=1280 then
			_update_grid_size=40;
			AddLayer result=suppress / model='resnet50_caffe'
			name='detection1' layer={type='detection'
			detectionModelType="YOLOV2"
			classNumber=&_CV_OD_class_num
			gridNumber=_update_grid_size
			coordNumber=4
			predictionsPerGrid=&_CV_OD_preds_per_grid
			anchors={&anchor_box_coord} softMaxForClassProb=True

			/* Error function scalers: */
			objectScale=&_CV_OD_Obj_scale_
			predictionNotAObjectScale=&_CV_OD_Not_Obj_scale_
			classScale=&_CV_OD_class_scale_
			coordScale=&_CV_OD_coord_scale_
			maxLabelPerImage=&_CV_object_num_

			/* end, error function scalers */
			coordType="YOLO"

			/* Prediction thresholds */
			detectionThreshold=&_CV_OD_detection_thresh_
			iouThreshold=&_CV_OD_iouthreshold_
			trainIouThreshold=&_CV_iouTrainThreshold_} srcLayers={'_convolast_'};
			_verify_mutation_="&_CV_random_mutate";
			if _verify_mutation_="random" then do;

			/* Apply mutations */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			if _verify_mutation_="none" then do;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_fliptype_="&_CV_fliptype_";
			if _verify_fliptype_="none" then do;

			/* Apply flipping */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			if _verify_fliptype_="horizontal" then do;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			if _verify_fliptype_="vertical" then do;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
			end;
			if _verify_fliptype_="both" then do;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			/* Change the expected input size - height */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_height_"}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_width_"}};

			/* Change the number of channels to match greyscale if condition exist */
			_verify_image_color="&_image_input_color_";
			if _verify_image_color="greyscale" then do;
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
			end;
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;
			_verify_modeling_task_="&_CV_modeltask_";

			/* classification, regression or objectdetection */
			/* remove dropout */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
			_set_beta1_value=.999-&_CV_betadiff_value_+0;
			_verify_autotune_init="&_CV_Global_autotune_initiate";
			if _verify_autotune_init="yes" then do;
			_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
			lower_clipgrad=0+&_CV_gradclips_value*-1;
			deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
				model='resnet50_caffe'
				modelWeights={name='ConVTrainedWeights_d', replace=1} 
				bestweights={name="&_CV_finalweightstable_", replace=1} 
				initWeights='autotune_bestweights_'
				dataSpecs={{data=_ObjectTargets_, layer='detection1', 
				type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
				GPU=&_CV_usegpu_T_F
				nthreads=&n_threads_

				/* 		weight="weight" */
				ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
				lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
				learningrate=_new_final_lr, beta1=_set_beta1_value, 
				clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad}, 
				ignoreTrainingError=true, loglevel=2, regL1=&_CV_l1reg_value_, 
				regL2=&_CV_l2reg_value_, maxepochs=&_CV_num_epochs_} seed=12345;
			end;
			if _verify_autotune_init ne "yes" then do;
			lower_clipgrad=0+&_CV_gradclips_value*-1;
			deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
				model='resnet50_caffe'
				modelWeights={name='ConVTrainedWeights_d', replace=1} 
				bestweights={name="&_CV_finalweightstable_", replace=1} 
				initWeights='resnet50_caffe_weights'
				dataSpecs={{data=_ObjectTargets_, layer='detection1', 
				type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
				GPU=&_CV_usegpu_T_F
				nthreads=&n_threads_
				ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
				lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
				learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
				clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad}, 
				ignoreTrainingError=true, loglevel=2, regL1=&_CV_l1reg_value_, 
				regL2=&_CV_l2reg_value_, maxepochs=&_CV_num_epochs_} seed=12345;
			end;

			/* return flipping back to "no flip" for OD model scoring and deployment */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'No cropping'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

			/* remove dropout */
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

			/*Reset ResNet Dropout in input layer back to 0*/
			mytbl.name="resnet50_caffe";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

			deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				model='resnet50_caffe'
				initWeights="&_CV_finalweightstable_"
				GPU=&_CV_usegpu_T_F
				copyVars={/*'idjoin',*/"&_CV_partition_var_", "&_CV_inpVar_name_"} 
				casout={name="tempscoreddata", replace=1, caslib="casuser"};
			table.save / saveAttrs=True
			Caslib="libres"
			table="resnet50_caffe"
			name="resnet50_caffe"
			permission="PUBLICWRITE"
			replace=True;
			datastep.runCode / code="
data &insert_outputtable1.;
/*save project path name*/
name='&tempprojpath_lib_';
type='projectpath';
output;

/*save model table name*/
name='resnet50_caffe';
type='modeltable';
output;

/*save model table weights name*/
name='&_CV_finalweightstable_';
type='modelweights';
output;

/*save image height*/
name='&_image_input_height_';
type='imageheight';
output;

/*save image width*/
name='&_image_input_width_';
type='imagewidth';
output;

/*save modeling task*/
name='&_CV_modeltask_';
type='modeltask';
output;

run;
";
			end;

			/************************************/
			/* tiny-YOLOv2 for Object detection */
			/************************************/
			_verify_modelbackbone_="&_CV_modelBackbone_";
			if _verify_modelbackbone_="Tiny-Yolov2" then do;
			table.loadTable /caslib='libCVmod', path='Tiny-Yolov2.sashdat'
			casOut={name='Tiny-Yolov2', replace=true};

			/*ResNet Apply Dropout to input layer*/
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

			removelayer result=suppress / model='Tiny-Yolov2' name='detection1';

			/* Adjust first convo layer filter sizes */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_width"}};
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_height"}};
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;
			_OD_depth=&_CV_OD_preds_per_grid * (&_CV_OD_class_num + 5)+0;
			AddLayer result=suppress / model='Tiny-Yolov2' name='_convolast_'
			layer={type='CONVO'
			nFilters=_OD_depth
			width=&_CV_OD_lastConvo_width height=&_CV_OD_lastConvo_height
			stride=1 act='identity' includeBias=FALSE} srcLayers={'convo.9'};

			/* change model activation functions */
			_verify_activation_function=&_CV_act_function;
			if _verify_activation_function=11 then _new_activation_value_=(string)6;
			if _verify_activation_function ne 11 then
			_new_activation_value_=(string)_verify_activation_function;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Leaky Activation Function'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.9' and  _DLKey1_ = 'convopts.act'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			_update_grid_size=0+0;
			if _chk_image_height_=224 or _chk_image_width_=224 then
			_update_grid_size=7;
			if _chk_image_height_=416 or _chk_image_width_=416 then
			_update_grid_size=13;
			if _chk_image_height_=640 or _chk_image_width_=640 then
			_update_grid_size=20;
			if _chk_image_height_=1280 or _chk_image_width_=1280 then
			_update_grid_size=40;
			AddLayer result=suppress / model='Tiny-Yolov2'
			name='detection1' layer={type='detection'
			detectionModelType="YOLOV2"
			classNumber=&_CV_OD_class_num
			gridNumber=_update_grid_size
			coordNumber=4
			predictionsPerGrid=&_CV_OD_preds_per_grid
			anchors={&anchor_box_coord} softMaxForClassProb=True

			/* Error function scalers: */
			objectScale=&_CV_OD_Obj_scale_
			predictionNotAObjectScale=&_CV_OD_Not_Obj_scale_
			classScale=&_CV_OD_class_scale_
			coordScale=&_CV_OD_coord_scale_
			maxLabelPerImage=&_CV_object_num_

			/* end, error function scalers */
			coordType="YOLO"

			/* Prediction thresholds */
			detectionThreshold=&_CV_OD_detection_thresh_
			iouThreshold=&_CV_OD_iouthreshold_
			trainIouThreshold=&_CV_iouTrainThreshold_} srcLayers={'_convolast_'};

			/* if verify_apply_dropout="yes" then do; */
			_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
			if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
			_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
			if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
			_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool1' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
			if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
			_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.2' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
			if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
			_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool2' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
			if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
			_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.3' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
			if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
			_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool3' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
			if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
			_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.4' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
			if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
			_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool4' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
			if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
			_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.5' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
			if _dec_update_Drop_out_block__10<0 then
			_dec_update_Drop_out_block__10=0;
			_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool5' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
			if _dec_update_Drop_out_block__11<0 then
			_dec_update_Drop_out_block__11=0;
			_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.6' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
			if _dec_update_Drop_out_block__12<0 then
			_dec_update_Drop_out_block__12=0;
			_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'pool6' and  _DLKey1_ = 'poolingopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
			if _dec_update_Drop_out_block__13<0 then
			_dec_update_Drop_out_block__13=0;
			_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.7' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
			if _dec_update_Drop_out_block__14<0 then
			_dec_update_Drop_out_block__14=0;
			_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.8' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
			if _dec_update_Drop_out_block__15<0 then
			_dec_update_Drop_out_block__15=0;
			_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'convo.9' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};

			/* end;  end applying dropout */
			_verify_mutation_="&_CV_random_mutate";
			if _verify_mutation_="random" then do;

			/* Apply mutations */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			if _verify_mutation_="none" then do;

			/* Apply mutations */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_fliptype_="&_CV_fliptype_";
			if _verify_fliptype_="none" then do;

			/* Apply flipping */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			if _verify_fliptype_="horizontal" then do;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			if _verify_fliptype_="vertical" then do;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
			end;
			if _verify_fliptype_="both" then do;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			/* Change the expected input size - height */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_height_"}};
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_width_"}};

			/* Change the number of channels to match greyscale if condition exist */
			_verify_image_color="&_image_input_color_";
			if _verify_image_color="greyscale" then do;
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = '	inputopts.nchannels'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
			end;
			_set_beta1_value=.999-&_CV_betadiff_value_+0;
			_verify_autotune_init="&_CV_Global_autotune_initiate";
			if _verify_autotune_init="yes" then do;
			_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
			lower_clipgrad=0+&_CV_gradclips_value*-1;
			deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
				model='Tiny-Yolov2'
				modelWeights={name='ConVTrainedWeights_d', replace=1} 
				bestweights={name="&_CV_finalweightstable_", replace=1} 
				initWeights='autotune_bestweights_'
				dataSpecs={{data=_ObjectTargets_, layer='detection1', 
				type='OBJECTDETECTION'} {data={'_image_'}, layer='input1', type='IMAGE'}} 
				GPU=&_CV_usegpu_T_F
				nthreads=&n_threads_
				ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
				lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
				learningrate=_new_final_lr, beta1=_set_beta1_value, 
				clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad}, 
				ignoreTrainingError=true, loglevel=2, regL1=&_CV_l1reg_value_, 
				regL2=&_CV_l2reg_value_, maxepochs=&_CV_num_epochs_} seed=12345;
			end;
			if _verify_autotune_init ne "yes" then do;
			lower_clipgrad=0+&_CV_gradclips_value*-1;
			deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
				model='Tiny-Yolov2'
				modelWeights={name='ConVTrainedWeights_d', replace=1} 
				bestweights={name="&_CV_finalweightstable_", replace=1} 
				initWeights='Tiny-Yolov2_weights'
				dataSpecs={{data=_ObjectTargets_, layer='detection1', 
				type='OBJECTDETECTION'} {data={'_image_'}, layer='input1', type='IMAGE'}} 
				GPU=&_CV_usegpu_T_F
				nthreads=&n_threads_
				ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
				lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
				learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
				clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad}, 
				ignoreTrainingError=true, loglevel=1, regL1=&_CV_l1reg_value_, 
				regL2=&_CV_l2reg_value_, maxepochs=&_CV_num_epochs_} seed=12345;
			end;

			/* return flipping back to "no flip" for OD model scoring and deployment */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

			/* remove mutations */
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLChrVal_ = 'No cropping'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

			/*remove dropout*/
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey1_ = 'poolingopts.dropout' or  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

			/*Reset ResNet Dropout in input layer back to 0*/
			mytbl.name="Tiny-Yolov2";
			mytbl.where="_DLKey0_ = 'input1' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

			deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				model='Tiny-Yolov2'
				initWeights="&_CV_finalweightstable_"
				GPU=&_CV_usegpu_T_F
				copyVars={/*'idjoin',*/"&_CV_partition_var_", "&_CV_inpVar_name_"} 
				casout={name="tempscoreddata", replace=1, caslib="casuser"};
			table.save / saveAttrs=True
			Caslib="libres"
			table="Tiny-Yolov2"
			name="Tiny-Yolov2"
			permission="PUBLICWRITE"
			replace=True;
			datastep.runCode / code="
data &insert_outputtable1.;
/*save project path name*/
name='&tempprojpath_lib_';
type='projectpath';
output;

/*save model table name*/
name='Tiny-Yolov2';
type='modeltable';
output;

/*save model table weights name*/
name='&_CV_finalweightstable_';
type='modelweights';
output;

/*save image height*/
name='&_image_input_height_';
type='imageheight';
output;

/*save image width*/
name='&_image_input_width_';
type='imagewidth';
output;

/*save modeling task*/
name='&_CV_modeltask_';
type='modeltask';
output;

run;
";
			end;

			/****************************************/
			/* ShuffleNetV2 Object Detection		*/
			/****************************************/
			_verify_modelbackbone_="&_CV_modelBackbone_";
			if _verify_modelbackbone_="ShuffleNetV2" or
			_verify_modelbackbone_="ShuffleNetV2_x15" or
			_verify_modelbackbone_="ShuffleNetV2_x20" or
			_verify_modelbackbone_="ShuffleNetV2_x25" then do;
			table.loadTable /caslib='libCVmod', path='ShuffleNetV2.sashdat'
			casOut={name='ShuffleNetV2', replace=true};
			/*ShuffleNetV2 Apply Dropout to input layer*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

			/* remove current output layer */
			removelayer result=suppress / model='ShuffleNetV2' name='outputlayer_2';
			removelayer result=suppress / model='ShuffleNetV2'
			name='global_avg_pool';
			removelayer result=suppress / model='ShuffleNetV2'
			name='bn_1x1conv5_out';

			/*adjust complexcity of shuffleNet*/
			if _verify_modelbackbone_="ShuffleNetV2_x15" then do;

			/* Adjust the model complexity */
			/*352.00 to 704.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="704.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="704.00"}};

			/*176.00 to 352.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="352.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="352.00"}};

			/*88.00 to 176.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="176.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="176.00"}};
			end;
			if _verify_modelbackbone_="ShuffleNetV2_x20" then do;

			/* Adjust the model complexity */
			/*352.00 to 976.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="976.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="976.00"}};

			/*176.00 to 488.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="488.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="488.00"}};

			/*88.00 to 244.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="244.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="244.00"}};
			end;
			if _verify_modelbackbone_="ShuffleNetV2_x25" then do;

			/* Adjust the model complexity */
			/*352.00 to 1216.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 352.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="1248.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 352.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="1248.00"}};

			/*176.00 to 488.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 176.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="624.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 176.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="624.00"}};

			/*88.00 to 244.00*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'nfilters' and  _DLNumVal_ = 88.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="312.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLChrVal_ = 'ngroups' and  _DLNumVal_ = 88.00";
			table.update / table=mytbl set={{var="_DLNumVal_", value="312.00"}};

			/* increase convo1 from 24 to 28 filters */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLChrVal_ = 'nfilters'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv_2' and  _DLChrVal_ = 'ngroups'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv_2' and  _DLChrVal_ = 'nfilters'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="28.00"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = '1x1conv5_out' and  _DLChrVal_ = 'nfilters'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="2048.00"}};
			end;

			/* Adjust first convo layer filter sizes */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_width"}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_height"}};

			/* add new output layer */
			/* Depth = predictionsPerGrid + (ClassNumber + CoorNumber + 1)  */
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;
			_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
			if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
			_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
			if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
			_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
			if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
			_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
			if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
			_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage2/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
			if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
			_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
			if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
			_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
			if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
			_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
			if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
			_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
			if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
			_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block5/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
			if _dec_update_Drop_out_block__10<0 then
			_dec_update_Drop_out_block__10=0;
			_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block6/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
			if _dec_update_Drop_out_block__11<0 then
			_dec_update_Drop_out_block__11=0;
			_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block7/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
			if _dec_update_Drop_out_block__12<0 then
			_dec_update_Drop_out_block__12=0;
			_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage3/block8/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
			if _dec_update_Drop_out_block__13<0 then
			_dec_update_Drop_out_block__13=0;
			_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage4/block1/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
			if _dec_update_Drop_out_block__14<0 then
			_dec_update_Drop_out_block__14=0;
			_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage4/block2/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
			if _dec_update_Drop_out_block__15<0 then
			_dec_update_Drop_out_block__15=0;
			_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage4/block3/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;
			if _dec_update_Drop_out_block__16<0 then
			_dec_update_Drop_out_block__16=0;
			_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'stage4/block4/3x3dwconv' and  _DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;

			/* end;  end applying dropout */
			_OD_depth=&_CV_OD_preds_per_grid * (&_CV_OD_class_num + 5)+0;
			AddLayer result=suppress / model='ShuffleNetV2' name='_convolast_'
			layer={type='CONVO'
			nFilters=_OD_depth
			width=&_CV_OD_lastConvo_width height=&_CV_OD_lastConvo_height
			stride=1 act='identity' includeBias=FALSE} srcLayers={'1x1conv5_out'};

			/* change model activation functions */
			_verify_activation_function=&_CV_act_function;
			if _verify_activation_function=11 then _new_activation_value_=(string)6;
			if _verify_activation_function ne 11 then
			_new_activation_value_=(string)_verify_activation_function;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			_update_grid_size=0+0;
			if _chk_image_height_=224 or _chk_image_width_=224 then
			_update_grid_size=7;
			if _chk_image_height_=416 or _chk_image_width_=416 then
			_update_grid_size=13;
			if _chk_image_height_=640 or _chk_image_width_=640 then
			_update_grid_size=20;
			if _chk_image_height_=1280 or _chk_image_width_=1280 then
			_update_grid_size=40;
			AddLayer result=suppress / model='ShuffleNetV2'
			name='detection1' layer={type='detection'
			detectionModelType="YOLOV2"
			classNumber=&_CV_OD_class_num
			gridNumber=_update_grid_size
			coordNumber=4
			predictionsPerGrid=&_CV_OD_preds_per_grid
			anchors={&anchor_box_coord} softMaxForClassProb=True

			/* Error function scalers: */
			objectScale=&_CV_OD_Obj_scale_
			predictionNotAObjectScale=&_CV_OD_Not_Obj_scale_
			classScale=&_CV_OD_class_scale_
			coordScale=&_CV_OD_coord_scale_
			maxLabelPerImage=&_CV_object_num_

			/* end, error function scalers */
			coordType="YOLO"

			/* Prediction thresholds */
			detectionThreshold=&_CV_OD_detection_thresh_
			iouThreshold=&_CV_OD_iouthreshold_
			trainIouThreshold=&_CV_iouTrainThreshold_} srcLayers={'_convolast_'};
			_verify_mutation_="&_CV_random_mutate";
			if _verify_mutation_="random" then do;

			/* Apply mutations */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			if _verify_mutation_="none" then do;

			/* Apply mutations */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_fliptype_="&_CV_fliptype_";
			if _verify_fliptype_="none" then do;

			/* Apply flipping */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			if _verify_fliptype_="horizontal" then do;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			if _verify_fliptype_="vertical" then do;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
			end;
			if _verify_fliptype_="both" then do;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			/* Change the expected input size - height */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_height_"}};

			/* Change the expected input size - width */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_width_"}};
			_verify_crop_="&_CV_crop_RESIZE_THENCROP";
			if _verify_crop_="RESIZETHENCROP" then do;

			/* Apply crop */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;
			if _verify_crop_="none" then do;

			/* Apply no crop */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;

			/* Change the number of channels to match greyscale if condition exist */
			_verify_image_color="&_image_input_color_";
			if _verify_image_color="greyscale" then do;
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
			end;
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;

			/* end ShuffleNetV2 model setup*/
			_set_beta1_value=.999-&_CV_betadiff_value_+0;
			_verify_autotune_init="&_CV_Global_autotune_initiate";
			if _verify_autotune_init="yes" then do;
			_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
			lower_clipgrad=0+&_CV_gradclips_value*-1;

			/*begin ShuffleNetV2 for object detection*/
			deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
				model='ShuffleNetV2'
				modelWeights={name='ConVTrainedWeights_d', replace=1} 
				bestweights={name="&_CV_finalweightstable_", replace=1} 
				initWeights='autotune_bestweights_'
				dataSpecs={{data=_ObjectTargets_, layer='detection1', 
				type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
				GPU=&_CV_usegpu_T_F
				nthreads=&n_threads_
				ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
				lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
				learningrate=_new_final_lr, beta1=_set_beta1_value, 
				clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad}, 
				ignoreTrainingError=true, loglevel=1, regL1=&_CV_l1reg_value_, 
				regL2=&_CV_l2reg_value_, maxepochs=&_CV_num_epochs_} seed=12345;
			end;
			if _verify_autotune_init ne "yes" then do;
			lower_clipgrad=0+&_CV_gradclips_value*-1;
			deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
				model='ShuffleNetV2'
				modelWeights={name='ConVTrainedWeights_d', replace=1} 
				bestweights={name="&_CV_finalweightstable_", replace=1} 
				initWeights='ShuffleNetV2_weights'
				dataSpecs={{data=_ObjectTargets_, layer='detection1', 
				type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
				GPU=&_CV_usegpu_T_F
				nthreads=&n_threads_
				ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
				lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
				learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
				clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad}, 
				ignoreTrainingError=true, loglevel=1, regL1=&_CV_l1reg_value_, 
				regL2=&_CV_l2reg_value_, maxepochs=&_CV_num_epochs_} seed=12345;
			end;

			/* return flipping back to "no flip" for OD model scoring and deployment */
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

			/*remove dropout*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey1_ = 'groupconvopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
			/*Reset ShuffleNetV2 Dropout in input layer back to 0*/
			mytbl.name="ShuffleNetV2";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

			deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				model='ShuffleNetV2'
				initWeights="&_CV_finalweightstable_"
				GPU=&_CV_usegpu_T_F
				copyVars={/*'idjoin',*/"&_CV_partition_var_", "&_CV_inpVar_name_"} 
				casout={name="tempscoreddata", replace=1, caslib="casuser"};
			table.save / saveAttrs=True
			Caslib="libres"
			table="ShuffleNetV2"
			name="ShuffleNetV2"
			permission="PUBLICWRITE"
			replace=True;
			datastep.runCode / code="
data &insert_outputtable1.;

/*save project path name*/
name='&tempprojpath_lib_';
type='projectpath';
output;

/*save model table name*/
name='ShuffleNetV2';
type='modeltable';
output;

/*save model table weights name*/
name='&_CV_finalweightstable_';
type='modelweights';
output;

/*save image height*/
name='&_image_input_height_';
type='imageheight';
output;

/*save image width*/
name='&_image_input_width_';
type='imagewidth';
output;

/*save modeling task*/
name='&_CV_modeltask_';
type='modeltask';
output;

run;
";
			end;

			/****************************************/
			/* Xception Object Detection		*/
			/****************************************/
			_verify_modelbackbone_="&_CV_modelBackbone_";
			if _verify_modelbackbone_="Xception" then do;
			table.loadTable /caslib='libCVmod', path='Xception.sashdat'
			casOut={name='Xception', replace=true};
			/*Xception Apply Dropout to input layer*/
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="&_tm_insert_indropout_"}};

			/* remove current output layer */
			removelayer result=suppress / model='Xception' name='outlayer';
			removelayer result=suppress / model='Xception' name='final_avepool';
			removelayer result=suppress / model='Xception'
			name='seperablebnrelu_exit2__bn';

			/* Adjust first convo layer filter sizes */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_width"}};
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&mac_firstConvo_height"}};

			/* 						mytbl.name  ="Xception";  */
			/* 						mytbl.where = "_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.width'"; */
			/* 						table.update /  table=mytbl  set = {{var="_DLNumVal_", value="&mac_firstConvo_width"}}; */
			/* 						mytbl.name  ="Xception";  */
			/* 						mytbl.where = "_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.height'"; */
			/* 						table.update /  table=mytbl  set = {{var="_DLNumVal_", value="&mac_firstConvo_height"}}; */
			/*********************/
			/*Apply Dropout */
			/*********************/
			_dec_update_Drop_out_block_1=_dec_Drop_out_block_1*.05;
			if _dec_update_Drop_out_block_1<0 then _dec_update_Drop_out_block_1=0;
			_Dropout_block_1=(string)_dec_update_Drop_out_block_1;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'conv1' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_1}};
			_dec_update_Drop_out_block_2=_dec_Drop_out_block_2*.05;
			if _dec_update_Drop_out_block_2<0 then _dec_update_Drop_out_block_2=0;
			_Dropout_block_2=(string)_dec_update_Drop_out_block_2;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'conv2' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_2}};
			_dec_update_Drop_out_block_3=_dec_Drop_out_block_3*.05;
			if _dec_update_Drop_out_block_3<0 then _dec_update_Drop_out_block_3=0;
			_Dropout_block_3=(string)_dec_update_Drop_out_block_3;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_1seperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_3}};
			_dec_update_Drop_out_block_4=_dec_Drop_out_block_4*.05;
			if _dec_update_Drop_out_block_4<0 then _dec_update_Drop_out_block_4=0;
			_Dropout_block_4=(string)_dec_update_Drop_out_block_4;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_1seperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_4}};
			_dec_update_Drop_out_block_5=_dec_Drop_out_block_5*.05;
			if _dec_update_Drop_out_block_5<0 then _dec_update_Drop_out_block_5=0;
			_Dropout_block_5=(string)_dec_update_Drop_out_block_5;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_2reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_5}};
			_dec_update_Drop_out_block_6=_dec_Drop_out_block_6*.05;
			if _dec_update_Drop_out_block_6<0 then _dec_update_Drop_out_block_6=0;
			_Dropout_block_6=(string)_dec_update_Drop_out_block_6;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_3reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_6}};
			_dec_update_Drop_out_block_7=_dec_Drop_out_block_7*.05;
			if _dec_update_Drop_out_block_7<0 then _dec_update_Drop_out_block_7=0;
			_Dropout_block_7=(string)_dec_update_Drop_out_block_7;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_4reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_7}};
			_dec_update_Drop_out_block_8=_dec_Drop_out_block_8*.05;
			if _dec_update_Drop_out_block_8<0 then _dec_update_Drop_out_block_8=0;
			_Dropout_block_8=(string)_dec_update_Drop_out_block_8;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_5reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_8}};
			_dec_update_Drop_out_block_9=_dec_Drop_out_block_9*.05;
			if _dec_update_Drop_out_block_9<0 then _dec_update_Drop_out_block_9=0;
			_Dropout_block_9=(string)_dec_update_Drop_out_block_9;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_6reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value=_Dropout_block_9}};
			_dec_update_Drop_out_block__10=_dec_Drop_out_block__10*.05;
			if _dec_update_Drop_out_block__10<0 then
			_dec_update_Drop_out_block__10=0;
			_Dropout_block__10=(string)_dec_update_Drop_out_block__10;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_7reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__10}};
			_dec_update_Drop_out_block__11=_dec_Drop_out_block__11*.05;
			if _dec_update_Drop_out_block__11<0 then
			_dec_update_Drop_out_block__11=0;
			_Dropout_block__11=(string)_dec_update_Drop_out_block__11;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_8reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__11}};
			_dec_update_Drop_out_block__12=_dec_Drop_out_block__12*.05;
			if _dec_update_Drop_out_block__12<0 then
			_dec_update_Drop_out_block__12=0;
			_Dropout_block__12=(string)_dec_update_Drop_out_block__12;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_9reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__12}};
			_dec_update_Drop_out_block__13=_dec_Drop_out_block__13*.05;
			if _dec_update_Drop_out_block__13<0 then
			_dec_update_Drop_out_block__13=0;
			_Dropout_block__13=(string)_dec_update_Drop_out_block__13;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_10reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__13}};
			_dec_update_Drop_out_block__14=_dec_Drop_out_block__14*.05;
			if _dec_update_Drop_out_block__14<0 then
			_dec_update_Drop_out_block__14=0;
			_Dropout_block__14=(string)_dec_update_Drop_out_block__14;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_11reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__14}};
			_dec_update_Drop_out_block__15=_dec_Drop_out_block__15*.05;
			if _dec_update_Drop_out_block__15<0 then
			_dec_update_Drop_out_block__15=0;
			_Dropout_block__15=(string)_dec_update_Drop_out_block__15;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'block_12reluseperablebn_pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__15}};
			_dec_update_Drop_out_block__16=_dec_Drop_out_block__16*.05;
			if _dec_update_Drop_out_block__16<0 then
			_dec_update_Drop_out_block__16=0;
			_Dropout_block__16=(string)_dec_update_Drop_out_block__16;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'seperablebnrelu_exit1__pw' and  _DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_Dropout_block__16}};

			/* add new output layer */
			/* Depth = predictionsPerGrid + (ClassNumber + CoorNumber + 1)  */
			_chk_image_height_=&_image_input_height_+0;
			_chk_image_width_=&_image_input_width_+0;
			_OD_depth=&_CV_OD_preds_per_grid * (&_CV_OD_class_num + 5)+0;
			AddLayer result=suppress / model='Xception' name='_convolast_'
			layer={type='CONVO'
			nFilters=_OD_depth
			width=&_CV_OD_lastConvo_width height=&_CV_OD_lastConvo_height
			stride=1 act='identity' includeBias=FALSE} 
				srcLayers={'seperablebnrelu_exit2__pw'};

			/* change model activation functions */
			_verify_activation_function=&_CV_act_function;
			if _verify_activation_function=11 then _new_activation_value_=(string)6;
			if _verify_activation_function ne 11 then
			_new_activation_value_=(string)_verify_activation_function;
			mytbl.name="Xception";
			mytbl.where="_DLKey1_ = 'bnopts.act' and  _DLChrVal_ = 'Rectifier'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			mytbl.name="Xception";
			mytbl.where="_DLKey1_ = 'reshapeopts.act' and  _DLChrVal_ = 'Rectifier'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value=_new_activation_value_}};
			if _chk_image_height_=224 or _chk_image_width_=224 then
			_update_grid_size=7;
			if _chk_image_height_=416 or _chk_image_width_=416 then
			_update_grid_size=13;
			if _chk_image_height_=640 or _chk_image_width_=640 then
			_update_grid_size=20;
			if _chk_image_height_=1280 or _chk_image_width_=1280 then
			_update_grid_size=40;
			AddLayer result=suppress / model='Xception'
			name='detection1' layer={type='detection'
			detectionModelType="YOLOV2"
			classNumber=&_CV_OD_class_num
			gridNumber=_update_grid_size
			coordNumber=4
			predictionsPerGrid=&_CV_OD_preds_per_grid
			anchors={&anchor_box_coord} softMaxForClassProb=True

			/* Error function scalers: */
			objectScale=&_CV_OD_Obj_scale_
			predictionNotAObjectScale=&_CV_OD_Not_Obj_scale_
			classScale=&_CV_OD_class_scale_
			coordScale=&_CV_OD_coord_scale_
			maxLabelPerImage=&_CV_object_num_

			/* end, error function scalers */
			coordType="YOLO"

			/* Prediction thresholds */
			detectionThreshold=&_CV_OD_detection_thresh_
			iouThreshold=&_CV_OD_iouthreshold_
			trainIouThreshold=&_CV_iouTrainThreshold_} srcLayers={'_convolast_'};
			_verify_crop_="&_CV_crop_RESIZE_THENCROP";
			if _verify_crop_="RESIZETHENCROP" then do;

			/* Apply crop */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;
			if _verify_crop_="none" then do;

			/* Apply no crop */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_mutation_="&_CV_random_mutate";
			if _verify_mutation_="random" then do;

			/* Apply mutations */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			if _verify_mutation_="none" then do;

			/* Apply mutations */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			_verify_fliptype_="&_CV_fliptype_";
			if _verify_fliptype_="none" then do;

			/* Apply flipping */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			end;
			if _verify_fliptype_="horizontal" then do;

			/* Apply flipping */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='2'}};
			end;
			if _verify_fliptype_="vertical" then do;

			/* Apply flipping */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='3'}};
			end;
			if _verify_fliptype_="both" then do;

			/* Apply flipping */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='4'}};
			end;

			/* Change the expected input size - height */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.height'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_height_"}};

			/* Change the expected input size - width */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.width'";
			table.update / table=mytbl set={{var="_DLNumVal_", 
				value="&_image_input_width_"}};

			/* Change the number of channels to match greyscale if condition exist */
			_verify_image_color="&_image_input_color_";

			/* yes no */
			if _verify_image_color="greyscale" then do;
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = '	inputopts.nchannels'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="1"}};
			end;
			_verify_autotune_init="&_CV_Global_autotune_initiate";
			if _verify_autotune_init="yes" then do;
			_new_final_lr=(&_CV_gam_value_**(floor(&_CV_eval_epochs/&_CV_stepSize_value_)))*&_CV_lr_value_;
			lower_clipgrad=0+&_CV_gradclips_value*-1;

			/*begin ShuffleNetV2 for object detection*/
			deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
				model='Xception'
				modelWeights={name='ConVTrainedWeights_d', replace=1} 
				bestweights={name="&_CV_finalweightstable_", replace=1} 
				initWeights='autotune_bestweights_'
				dataSpecs={{data=_ObjectTargets_, layer='detection1', 
				type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
				GPU=&_CV_usegpu_T_F
				nthreads=&n_threads_
				ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
				lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
				learningrate=_new_final_lr, beta1=_set_beta1_value, 
				clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad}, 
				ignoreTrainingError=true, loglevel=1, regL1=&_CV_l1reg_value_, 
				regL2=&_CV_l2reg_value_, maxepochs=&_CV_num_epochs_} seed=12345;
			end;
			if _verify_autotune_init ne "yes" then do;
			lower_clipgrad=0+&_CV_gradclips_value*-1;
			deeplearn.dlTrain / table={name="&_imageDS_", where="&_CV_partition_var_=1"} 
				model='Xception'
				modelWeights={name='ConVTrainedWeights_d', replace=1} 
				bestweights={name="&_CV_finalweightstable_", replace=1} 
				/* 				initWeights='Xceptionweights' */
				dataSpecs={{data=_ObjectTargets_, layer='detection1', 
				type='OBJECTDETECTION'} {data={'_image_'}, layer='data', type='IMAGE'}} 
				GPU=&_CV_usegpu_T_F
				nthreads=&n_threads_
				ValidTable={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				optimizer={minibatchsize=&_CV_miniBSize_value_, algorithm={method='ADAM', 
				lrpolicy='Step', gamma=&_CV_gam_value_, stepsize=&_CV_stepSize_value_, 
				learningrate=&_CV_lr_value_, beta1=_set_beta1_value, 
				clipGradMax=&_CV_gradclips_value, clipGradMin=lower_clipgrad}, 
				ignoreTrainingError=true, loglevel=1, regL1=&_CV_l1reg_value_, 
				regL2=&_CV_l2reg_value_, maxepochs=&_CV_num_epochs_} seed=12345;
			end;

			/* return flipping back to "no flip" for OD model scoring and deployment */
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.flip'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.mutation'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLChrVal_ = 'Random cropping (one in, one out)'";
			table.update / table=mytbl set={{var="_DLNumVal_", value='1'}};

			/*remove dropout*/
			mytbl.name="Xception";
			mytbl.where="_DLKey1_ = 'convopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};
			/*Reset Xception Dropout in input layer back to 0*/
			mytbl.name="Xception";
			mytbl.where="_DLKey0_ = 'data' and  _DLKey1_ = 'inputopts.dropout'";
			table.update / table=mytbl set={{var="_DLNumVal_", value="0"}};

			deeplearn.dlScore / table={name="&_imageDS_", where="&_CV_partition_var_=2"} 
				model='Xception'
				initWeights="&_CV_finalweightstable_"
				GPU=&_CV_usegpu_T_F
				copyVars={/*'idjoin',*/"&_CV_partition_var_", "&_CV_inpVar_name_"} 
				casout={name="tempscoreddata", replace=1, caslib="casuser"};
			table.save / saveAttrs=True
			Caslib="libres"
			table="Xception"
			name="Xception"
			permission="PUBLICWRITE"
			replace=True;
			datastep.runCode / code="
data &insert_outputtable1.;

/*save project path name*/
name='&tempprojpath_lib_';
type='projectpath';
output;

/*save model table name*/
name='Xception';
type='modeltable';
output;

/*save model table weights name*/
name='&_CV_finalweightstable_';
type='modelweights';
output;

/*save image height*/
name='&_image_input_height_';
type='imageheight';
output;

/*save image width*/
name='&_image_input_width_';
type='imagewidth';
output;

/*save modeling task*/
name='&_CV_modeltask_';
type='modeltask';
output;

run;
";
			end;
			end;
			end;

			table.save / saveAttrs=True
			Caslib="libres"
			table={name="&insert_outputtable1_name_base.", caslib="&insert_outputtable1_lib."}
			name="modelinformation"
			permission="PUBLICWRITE"
			replace=True;

			quit;

			/****************************/
			/*  Store minimum training  */
			/*  and validation error in */
			/*  macro variables. 	    */
			/****************************/
			proc sql noprint;
				select min(FitError) into :Train separated by ' '
				from ObjectModeliter;
			quit;

			;

			proc sql noprint;
				select min(ValidError) into :Valid separated by ' '
				from ObjectModeliter;
			quit;

			;

			/* Plot Performance */
			proc sgplot data=ObjectModeliter;
				;
				yaxis label='ERROR Rate';
				series x=Epoch y=FitError / CURVELABEL="&Train" CURVELABELPOS=END
				name="Training";
				series x=Epoch y=Validerror / CURVELABEL="&Valid" CURVELABELPOS=END
				name="Validation";
				keylegend "Training" "Validation";
			run;

			proc cas;
				table.save / saveAttrs=True
				Caslib="libres"
				table="&_CV_finalweightstable_"
				name="&_CV_finalweightstable_"
				permission="PUBLICWRITE"
				replace=True;
			quit;

			/* options mprint MLOGIC ; */
			%Macro viewimagepredictions();
				%if &_CV_modeltask_=classification %then %do;

					proc cas;
						table.shuffle / table={name="tempscoreddata", 
							computedVars={{name="Misclassified_count"}}, computedVarsProgram="if trim(left(&_CV_tarVar_name_)) = trim(left(I_&_CV_tarVar_name_)) then Misclassified_count=0;
else Misclassified_count=1;

", caslib="casuser", where="&_CV_partition_var_=2"} 
							casout={name='scoredimagedata_w_miss', replace=1, caslib='casuser'};
					quit;

					data work.MISC_Counts;
						set casuser.scoredimagedata_w_miss (drop=_image_);

						if trim(left(&_CV_tarVar_name_))=trim(left(I_&_CV_tarVar_name_)) then 
							Misclassified_count=0;
						else Misclassified_count=1;
					run;

					/**************************************************/
					/*Sum misclassification counts at the target level*/
					/**************************************************/
					proc sql;
						create table work.AssessModel as
						select distinct &_CV_tarVar_name_, sum(Misclassified_count) as
						number_MISC
						from work.MISC_Counts
						group by &_CV_tarVar_name_;
					quit;

					/***************************************************/
					/*Plot each target level's misclassification counts */
					/***************************************************/
					proc sgplot data=work.AssessModel;
						vbar _label_ / response=number_MISC;
						yaxis display=(nolabel) grid;
						xaxis display=(nolabel);
					run;

				%end;

				%if &_CV_modeltask_=objectdetection %then %do;

					proc cas;
						action sampling.srs / table={caslib="casuser", name="tempscoreddata", 
							where="&_CV_partition_var_=2"}, sampPct=&_CV_percentimages_to_inspect, 
							display={excludeAll=TRUE}, output={casOut={caslib="casuser", 
							name="tempDisplayTable_", replace=TRUE}, copyVars="ALL"};
					quit;

					title "Number of Holdout Images Selected:";

					proc freq data=casuser.tempDisplayTable_;
						tables _partind_;
					run;

					title;
					title
					"Number of Selected Holdout Images Containing Successful Extractions:";

					proc cas;
						image.extractDetectedObjects / casOut={name='_Objects_highlighted_', 
							replace=true, caslib="libres"} coordType='YOLO'
							maxObjects=&_CV_object_num_
							extractType="HIGHLIGHT"
							Table={name='tempDisplayTable_', caslib="casuser"};
					quit;

					title;

					proc cas;
						saveImages result=suppress / caslib="libres"
						subdirectory='Final_images_to_display'
						images={table={name='_Objects_highlighted_', caslib="libres"} 
							image="&_CV_inpVar_name_"} overwrite=TRUE type="JPG";

						/***********************************************/
						/*Highlight bounding box regions in Images in*/
						/***********************************************/
						action image.loadImages result=suppress / caslib="libres"
						path="Final_images_to_display"
						recurse=TRUE labelLevels=-1 casOut={caslib="casuser", 
							name="_viewyourimages_", replace=TRUE};
					run;

					quit;

					data _null_;
						set casuser._viewyourimages_ end=eof;
					_labelID_=cat(_label_, ' (_id_=', _id_, ')');

					if _n_=1 then do;
						dcl odsout obj();
						obj.layout_gridded(columns: 4);
					end;
					obj.region();
					obj.format_text(text: _labelID_, just: "c", style_attr: 'font_size=9pt');
					obj.image(file: _path_, width: "&_image_input_width_", 
						height: "&_image_input_height_");

					if eof then do;
						obj.layout_end();
					end;
				run;

			%end;
		%mend viewimagepredictions;

		%viewimagepredictions;
		ODS html CLOSE;

		proc printto;
		run;

		proc cas;
			table.dropCaslib result=suppress / caslib="libCVmod" quiet=TRUE;
			table.dropCaslib result=suppress / caslib="libres" quiet=TRUE;
		quit;

		/* Delete macor variables: */
		%SYMDEL

		/*inputCaslib1	inputCASTable1	outputCaslib1	outputCASTable1 */
		_CV_location_for_results_data _CV_onoff_search_obj
		_CV_onoff_search_noobj _CV_onoff_search_coord _CV_onoff_search_class
		_CV_onoff_search_detthresh _CV_onoff_search_iouthresh
		_CV_onoff_search_trainiou _CV_onoff_search_FCneuronnum
		_CV_onoff_search_FCactfunc _CV_onoff_search_lr _CV_onoff_search_betadiff
		_CV_onoff_search_miniBSize _CV_onoff_search_stepsize
		_CV_onoff_search_gamma _CV_onoff_search_l1reg _CV_onoff_search_l2reg
		_CV_dropValue _CV_onoff_search_actfunc _CV_onoff_search_gradclips
		_CV_caslib_ _CV_objectdetectiondata_ _CV_regressiontable_
		_CV_CVmodel_location _imageDS_ _CV_partition_var_
		_CV_valid_partition_per_ _CV_modelBackbone_ _CV_partition_seed
		_image_input_height_ _image_input_width_ n_threads_ _image_input_color_
		_CV_tarVar_name_ _CV_tarVar_commaname_
		_CV_inpVar_name_ _CV_modeltask_ _CV_usegpu_T_F _CV_fliptype_
		_CV_random_mutate _CV_crop_RESIZE_THENCROP
		_CV_num_epochs_ _CV_finalweightstable_ _CV_percentimages_to_inspect
		_CV_saveautotune_results _CV_autotuneresults_name
		_CV_OD_class_num _CV_OD_cluster_criterion _CV_maxnumclusters
		_CV_reg_error _CV_reg_out_act_function
		_CV_reg_out_standardization _CV_Global_autotune_initiate
		_CV_population_s _CV_gsslocal_s _CV_gagenerations_s
		_CV_maxtraintime _CV_autotuneseed _CV_eval_epochs
		_CV_continue_previous_search _CV_howmanytouseforfirstgen
		_CV_name_autotuneresults_save _CV_name_autotuneresults_load
		_CV_onoff_search_lc_width _CV_OD_lastConvo_width
		_CV_lb_OD_lconvo_width_value_ _CV_ub_OD_lconvo_width_value_
		_CV_onoff_search_lc_height _CV_OD_lastConvo_height
		_CV_lb_OD_lconvo_height_value_ _CV_ub_OD_lconvo_height_value_
		_CV_OD_Obj_scale_ _CV_lb_OD_Obj_value_
		_CV_ub_OD_Obj_value_ _CV_OD_Not_Obj_scale_ _CV_lb_Not_Obj_value_
		_CV_ub_Not_Obj_value_ _CV_OD_coord_scale_
		_CV_lb_coord_value_ _CV_ub_coord_value_ _CV_OD_class_scale_
		_CV_lb_class_value_ _CV_ub_class_value_ _CV_OD_detection_thresh_
		_CV_lb_detection_thresh_value_ _CV_ub_detection_thresh_value_
		_CV_OD_iouthreshold_ _CV_lb_iouthreshold_value_
		_CV_ub_iouthreshold_value_ _CV_iouTrainThreshold_
		_CV_lb_iouTrainThreshold_value_ _CV_ub_iouTrainThreshold_value_
		_CV_include_FC_layer _CV_FC_neuron_num _CV_lb_FC_neuron_value_
		_CV_ub_FC_neuron_value_ _CV_FC_act_function
		_CV_onoff_search_firstc_fsize _CV_assigned_firstc_fsize
		_CV_gradclips_value _CV_lb_gradclips_value _CV_ub_gradclips_value
		_CV_gam_value_ _CV_lb_gamma_value_ _CV_ub_gamma_value_
		_CV_stepSize_value_ _CV_stepSize_value_ _CV_ub_stepSize_value_
		_CV_miniBSize_value_
		_CV_lb_miniBSize_value_ _CV_ub_miniBSize_value_ _CV_lr_value_
		_CV_lb_lr_value_ _CV_ub_lr_value_ _CV_betadiff_value_
		_CV_lb_betadiff_value_ _CV_ub_betadiff_value_ _CV_l1reg_value_
		_CV_lb_l1reg_value_ _CV_ub_l1reg_value_ _CV_l2reg_value_
		_CV_lb_l2reg_value_ _CV_ub_l2reg_value_ _CV_act_function
		_CV_multitlayercount _CV_multitoutput_0 _CV_multitoutput_1
		_CV_multitoutput_2 _CV_multitoutput_3 _CV_multitoutput_4
		_CV_multitoutput_5 _CV_multitoutput_6 _CV_multitoutput_7
		_CV_multitoutput_8
		_CV_multitoutput_9 _CV_multitoutput_10 _CV_multitoutput_11
		_CV_multitoutput_12 _CV_multitoutput_13 _CV_multitoutput_14
		_CV_multitoutput_15 _CV_multitoutput_16 _CV_multitoutput_17
		_CV_multitoutput_18 _CV_multitoutput_19 _CV_multitoutput_20
		_CV_multitoutputtype_0
		_CV_multitoutputtype_1 _CV_multitoutputtype_2 _CV_multitoutputtype_3
		_CV_multitoutputtype_4 _CV_multitoutputtype_5 _CV_multitoutputtype_6
		_CV_multitoutputtype_7 _CV_multitoutputtype_8 _CV_multitoutputtype_9
		_CV_multitoutputtype_10 _CV_multitoutputtype_11 _CV_multitoutputtype_12
		_CV_multitoutputtype_13 _CV_multitoutputtype_14 _CV_multitoutputtype_15
		_CV_multitoutputtype_16 _CV_multitoutputtype_17 _CV_multitoutputtype_18
		_CV_multitoutputtype_19 _CV_multitoutputtype_20 multaskevals
		_CV_search_slt0 _CV_search_slt1 _CV_search_slt2 _CV_search_slt3
		_CV_search_slt4 _CV_search_slt5 _CV_search_slt6 _CV_search_slt7
		_CV_search_slt8 _CV_search_slt9 _CV_search_slt_10 _CV_search_slt_11
		_CV_search_slt_12 _CV_search_slt_13 _CV_search_slt_14 _CV_search_slt_15
		_CV_search_slt_16 _CV_search_slt_17 _CV_search_slt_18
		_CV_search_slt_19 _CV_search_slt_20 _CV_dropout_block1
		_CV_dropout_block2 _CV_dropout_block3 _CV_dropout_block4
		_CV_dropout_block5
		_CV_dropout_block6 _CV_dropout_block7 _CV_dropout_block8
		_CV_dropout_block9 _CV_dropout_block10 _CV_dropout_block11
		_CV_dropout_block12
		_CV_dropout_block13 _CV_dropout_block14 _CV_dropout_block15
		_CV_dropout_block16 _CV_object_num_ anchor_box_coord
		_CV_OD_preds_per_grid
		_dcodeclassreg _CVdm_dltraincodemultitaskres
		_CVdm_dltraincodemultitasktin _CVdm_dltraincodemultitaskshuf
		_CVdm_decidenominal
		_CVdm_addlayercodemultitask _retainmultitaskdec_ _labelsmultitaskdec_
		_CVdm_TrgVarList _dcodemultitask _CVsclaremacroupdate
		_tm_wsbackbone _tm_warmstart _tm_projdropoutrate chk_modelpath__
		chk_projectpath__ tempmodelpath_lib_ tempprojpath_lib_ / NOWARN;
		%SYSMACDELETE
		_useprevioussearch_ _FindAnchorBoxes_ sbbcodeclassreg
		NOcreatemultitasklayer A_createmultitasklayer A_createaddlayermultitask
		NOcreateaddlayermultitask retaindecsionvars labelsdecsionvars
		crtTrgVarList4Multitask sbbcodemultitask updatemultiTaskS
		updatetransfervales viewimagepredictions check_for_caslib / NOWARN;
		options SERR;
		options casdatalimit="100M";