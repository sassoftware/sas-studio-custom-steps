/* Pickle File to Model Manager - code generator
   ==========================================
   This is the exact same logic as the "Pickle File to Model Manager" custom step
   (see the .step file one level up), packaged so it can be run directly in a
   SAS Studio Program tab (or any batch/scheduled SAS session) without the
   step's UI - handy for repeated/scripted runs, or for testing changes to the
   generated code without re-importing the custom step each time.

   Fill in the %let values below for your environment, then submit the whole
   file. Each %let corresponds to one field in the custom step's UI - see the
   step's README.md for what each one does and which tab it lives on.

   Leave a model's pickle_path blank to skip that model slot (only the first
   is required). model_prefix/algorithm are optional for a filled-in slot -
   both are auto-detected from the model file if left blank. */

%let pickle_path=;             /* required: path/URL to model 1's pickle file */
%let model_prefix=;            /* optional: model 1's display name in Model Manager */
%let algorithm=;                /* optional: model 1's algorithm label */
%let pickle_path_2=;           /* optional: model 2 */
%let model_prefix_2=;
%let algorithm_2=;
%let pickle_path_3=;           /* optional: model 3 */
%let model_prefix_3=;
%let algorithm_3=;
%let pickle_path_4=;           /* optional: model 4 */
%let model_prefix_4=;
%let algorithm_4=;
%let training_table=;          /* required: path/URL to the training data CSV */
%let predictor_columns=;       /* optional: comma-separated; blank = auto-detect */
%let target_variable=;         /* required: target column name */
%let eval_table=;              /* optional: held-out data for honest model-card metrics */
%let model_function=classification;  /* classification | prediction */
%let event_value=1;            /* classification only: which class value is the "event" */
%let project_action=existing;  /* existing | create */
%let project_name=;            /* required: Model Manager project name */
%let overwrite_model=0;        /* 1 = add a new version if the model already exists */
%let do_model_card=1;          /* 1 = generate a model card */
%let sensitive_column=;        /* optional: column for a bias/fairness assessment */
%let do_publish=0;             /* 1 = publish the model(s) after import */
%let publish_destination=;     /* required if do_publish=1: an existing publish destination */
%let do_performance=0;         /* 1 = set up (but not run) performance monitoring - requires do_publish=1 */
%let monitor_caslib=Public;    /* CAS library for the performance monitoring input table */
%let viya_host=;               /* optional: only needed if not derivable from the session */


/* --- Stage SAS Content (sascontent:) file inputs into WORK -----------------
   The file pickers can return a logical SAS Content path (sascontent:/...),
   which lives in the Files service, NOT on the compute server filesystem - so
   Python open()/pandas can't read it. For any such input, copy the file into
   WORK with the FILESRVC filename engine and rewrite the macro variable to the
   local WORK path Python then reads. Real filesystem paths pass through as-is. */
%macro _stage_input(var);
    %local v fname folder localpath;
    %let v = %superq(&var);
    /* sasserver:/path is already a real compute-server filesystem path - the file
       picker just prefixes it. Strip the prefix so Python reads the file directly
       (no copy needed). */
    %if %length(&v) >= 10 %then %do;
        %if %qupcase(%qsubstr(&v, 1, 10)) = SASSERVER: %then %do;
            %let &var = %qsubstr(&v, 11);
            %let v = %superq(&var);
            %put NOTE: using server file &v;
        %end;
    %end;
    %if %length(&v) >= 11 %then %do;
        %if %qupcase(%qsubstr(&v, 1, 11)) = SASCONTENT: %then %do;
            %let v = %qsubstr(&v, 12);
            /* %kscan (not %scan) so a folder/file name with multi-byte UTF-8
               characters splits on a whole character, not a raw byte. */
            %let fname = %kscan(&v, -1, /);
            %let folder = %substr(&v, 1, %eval(%length(&v) - %length(&fname) - 1));
            filename _ssrc filesrvc folderpath="&folder" filename="&fname" recfm=n lrecl=1048576;
            %let localpath = %sysfunc(getoption(work))/&fname;
            filename _sdst "&localpath" recfm=n lrecl=1048576;
            %local _stage_rc;
            data work._null_;
                length rc 8 msg $384;
                rc = fcopy('_ssrc', '_sdst');
                msg = sysmsg();
                call symputx('_stage_rc', rc, 'L');
                if rc ^= 0 then
                    put "ERROR: could not stage &fname from SAS Content, rc=" rc " msg=" msg;
                else put "NOTE: staged &fname -> &localpath";
            run;
            filename _ssrc; filename _sdst;
            /* Only repoint at the WORK copy if the copy actually succeeded, so a
               failure surfaces clearly instead of Python reading a truncated file. */
            %if &_stage_rc = 0 %then %let &var = &localpath;
        %end;
    %end;
%mend _stage_input;
%_stage_input(pickle_path);
%_stage_input(pickle_path_2);
%_stage_input(pickle_path_3);
%_stage_input(pickle_path_4);
%_stage_input(training_table);
%_stage_input(eval_table);

/* Derive the Viya host from the flow's base URL so sasctl has a host without the
   user typing one (https://host/AppName -> host). Wrapped in a macro because
   open-code %if is not reliably supported in every compute session. */
%macro _derive_viya_host;
    %global viya_host_auto;
    %let viya_host_auto =;
    %if %symexist(_baseurl) %then %do;
        %let viya_host_auto = %kscan(%superq(_baseurl), 2, %str(/));
    %end;
%mend _derive_viya_host;
%_derive_viya_host;

/* Build banner - if you don't see this exact line in the log, SAS Studio is
   running an OLD copy of the step (re-upload the .step and replace the flow node). */
%put NOTE: ===== Pickle File to Model Manager - step build 1.7 (03SEP2026) =====;

proc python;
submit;
import pickle
import json
import os
from pathlib import Path

import pandas as pd
import sasctl.pzmm as pzmm
from sasctl import Session, current_session, publish_model
from sasctl.services import model_repository as mr
from sasctl.services import model_management as mm
from sasctl.services import model_publish as mp

# SWAT's default CA bundle path is broken in this compute environment (same fix
# PZMM.ipynb applies before opening its CAS connection) - without it, the CAS
# connection performance monitoring needs (current_session().as_swat() below)
# fails on an SSL error. Non-fatal: publish and plain model import don't need
# CAS at all, so a failure here shouldn't block them.
try:
    import swat
    import certifi
    swat.options.cas.ssl_ca_list = certifi.where()
except Exception as _e:
    print(f"NOTE: could not pre-configure SWAT's SSL cert path ({_e}) - performance "
          f"monitoring's CAS upload may fail if this matters on this server.")

# --- Prompt values (each custom-step control id arrives as a macro variable) ---
# Up to 4 model slots, each with its own pickle/name/algorithm - only slots with a
# pickle path filled in are processed. This is what "recreate the PZMM notebook's
# multi-model group" maps onto: several algorithms, one shared target/training
# table/project, each named and labelled individually.
_slot_ids = [
    ("pickle_path", "model_prefix", "algorithm"),
    ("pickle_path_2", "model_prefix_2", "algorithm_2"),
    ("pickle_path_3", "model_prefix_3", "algorithm_3"),
    ("pickle_path_4", "model_prefix_4", "algorithm_4"),
]
model_slots = []
for _pk_id, _nm_id, _alg_id in _slot_ids:
    _p = SAS.symget(_pk_id)
    if _p:
        model_slots.append({"path": _p, "name": SAS.symget(_nm_id), "algorithm": SAS.symget(_alg_id)})

training_csv         = SAS.symget("training_table")
predictor_columns_input = [c.strip() for c in SAS.symget("predictor_columns").split(",") if c.strip()]
target_variable      = SAS.symget("target_variable")
model_function       = SAS.symget("model_function")        # classification | prediction
event_value          = SAS.symget("event_value")
project_action       = SAS.symget("project_action")        # existing | create
project_name         = SAS.symget("project_name")
overwrite_model      = SAS.symget("overwrite_model") == "1"
do_model_card        = SAS.symget("do_model_card") == "1"
viya_host            = SAS.symget("viya_host")
sensitive_column     = SAS.symget("sensitive_column")
eval_csv             = SAS.symget("eval_table")   # optional held-out evaluation data
do_publish           = SAS.symget("do_publish") == "1"
publish_destination  = SAS.symget("publish_destination")
do_performance       = SAS.symget("do_performance") == "1"
monitor_caslib       = SAS.symget("monitor_caslib") or "Public"

# Training data CSV and target column are required.
if not training_csv:
    raise RuntimeError(
        "No training data provided. Choose a training CSV file, or pick a training table."
    )
if not target_variable:
    raise RuntimeError(
        "No target column provided. Type a Target column name, or pick one with the "
        "table column selector."
    )

# --- Run summary + up-front validation --------------------------------------
# Collect a per-phase result so the log ends with a readable summary instead of a
# raw traceback. The model card (optional) - and each individual model in a
# multi-model batch - are caught and logged so one failure never blocks
# the rest of the run.
STEP_LOG = []


def _log(step, status, detail=""):
    STEP_LOG.append((step, status, detail))


if model_function not in ("classification", "prediction"):
    raise RuntimeError(
        f"model_function must be 'classification' or 'prediction', got {model_function!r}."
    )
if do_publish and not publish_destination:
    raise RuntimeError(
        "'Publish the model(s) after import' is checked but no publish destination "
        "was given. Enter the name of an existing Viya publishing destination (page "
        "'Publish'), or uncheck Publish."
    )
if not model_slots:
    raise RuntimeError(
        "No pickle files provided. Choose Model 1's pickle file (and optionally more "
        "on the 'Additional models' page)."
    )
for _p in [m["path"] for m in model_slots] + [training_csv]:
    if not _p or not os.path.exists(_p):
        raise RuntimeError(
            f"File not found on the compute server at: {_p!r}. Check the path (and "
            f"that SAS Content / Server staging succeeded above)."
        )

is_classification = model_function == "classification"
prob_var = f"P_{target_variable}"   # convention: event-probability output name
print(f"Processing {len(model_slots)} model(s) into project '{project_name}'.")

# --- Connect to Viya --------------------------------------------------------
# The step runs inside an authenticated SAS Studio compute session, but sasctl
# still needs its own Session. oauth_bearer=sas_services (PROC HTTP) reuses the
# session token but does NOT expose the raw string to Python, so we best-effort
# locate a reusable token from the compute environment and hand it to sasctl. If
# none is found, we print what IS available so auth can be wired for this site.
import os
import glob


def _find_reusable_token():
    for key, val in os.environ.items():
        if val and any(t in key.upper() for t in (
            "ACCESS_TOKEN", "OAUTH_TOKEN", "SAS_SERVICES_TOKEN", "SAS_CLIENT_TOKEN"
        )):
            return val.strip(), f"env:{key}"
    candidates = [
        os.path.expanduser("~/.sas/access_token"),
        os.path.expanduser("~/.sas/oauth_token"),
        "/opt/sas/viya/config/var/run/compsrv/default/access_token",
    ] + glob.glob(os.path.expanduser("~/.sas/*token*"))
    for path in candidates:
        try:
            with open(path) as fh:
                tok = fh.read().strip()
            if tok:
                return tok, f"file:{path}"
        except OSError:
            pass
    return None, None


viya_host = viya_host or SAS.symget("viya_host_auto")

sess = current_session()
if sess is None:
    token, source = _find_reusable_token()
    if token and viya_host:
        sess = Session(viya_host, token=token)
        print(f"Established sasctl session for {viya_host} via {source}.")
    else:
        print("=== sasctl auth diagnostic (no session yet) ===")
        print(f"host resolved to: {viya_host!r}; reusable token found: {bool(token)}")
        print("Token-ish environment variables present in this compute session:")
        for key in sorted(os.environ):
            if any(t in key.upper() for t in (
                "TOKEN", "OAUTH", "BEARER", "JWT", "VIYA", "SAS_SERVICES", "SASLOGON"
            )):
                print("   ", key)
        raise RuntimeError(
            "Could not establish a sasctl session. See the token diagnostic above - "
            "paste it back so auth can be wired for this deployment."
        )
print("Viya session:", current_session())

# --- Publish destination check (fail fast, before any model work, so a typo'd
# destination name doesn't waste a whole run) --------------------------------
if do_publish:
    _dest_names = [d.get("name") for d in mp.list_destinations()]
    _dest_match = next(
        (d for d in _dest_names if d and d.lower() == publish_destination.lower()), None
    )
    if _dest_match is None:
        raise RuntimeError(
            f"Publish destination '{publish_destination}' was not found on {viya_host}. "
            f"Available destinations: {_dest_names or '(none configured)'}. Ask your "
            f"Viya admin to create one, or enter an existing name."
        )
    publish_destination = _dest_match   # normalize to the destination's exact stored name
    print(f"Publish destination '{publish_destination}' verified - model(s) will be "
          f"published there after import.")

# --- Performance monitoring pre-flight: mirrors PZMM.ipynb's proven-working setup,
# which uses scoring_required=True (CAS scores each model itself against one shared
# input table) rather than pre-scoring in Python. CAS can only invoke a model once
# it's published, so performance monitoring needs Publish checked too - it's a real
# dependency here, not an artificial restriction. Establishing the CAS connection
# now (not deep inside the performance block) means a failure here is loud and
# immediate, not a silent per-table upload failure discovered only in Model
# Manager's job history. Non-fatal to the overall run either way: this only
# disables performance monitoring, model import/publish continue regardless. -----
conn = None
if do_performance and not do_publish:
    print("Performance monitoring needs the model(s) published first (CAS scores "
          "them itself to compute performance) - check 'Publish the model(s) after "
          "import' too, or uncheck performance monitoring. Skipping performance "
          "monitoring for this run.")
    _log("Performance monitoring setup", "skipped", "Publish not checked")
    do_performance = False
elif do_performance:
    try:
        conn = current_session().as_swat()
        print("CAS connection established for performance monitoring.")
    except Exception as _e:
        print(f"Could not establish a CAS connection for performance monitoring: {_e}")
        _log("Performance monitoring setup", "failed", f"CAS connection: {_e}")
        do_performance = False

# --- Shared training/evaluation data -----------------------------------------
# Loaded ONCE and reused for every model in the batch: all pickles in a run are
# expected to share the same target/training table (like the PZMM notebook's
# classifier group sharing one table) - only the algorithm differs per pickle.
data = pd.read_csv(training_csv)

eval_df = None
if eval_csv:
    if os.path.exists(eval_csv):
        eval_df = pd.read_csv(eval_csv)
        print(f"Loaded held-out evaluation data ({len(eval_df)} rows) from {eval_csv}.")
    else:
        print(f"NOTE: evaluation data not found at {eval_csv!r}; using in-sample metrics.")

# Target series, reused for stats, the model card, and the monitoring table. A
# regression target that arrived as text (e.g. currency "$36,945") is stripped of
# currency/thousands formatting and coerced to numeric - CAS model assessment
# requires a numeric target for prediction models.
target_series = data[target_variable].reset_index(drop=True)
if not is_classification and target_series.dtype == object:
    cleaned_target = target_series.astype(str).str.replace(r"[^\d.\-eE]", "", regex=True)
    target_series = pd.to_numeric(cleaned_target, errors="coerce")
    n_bad = int(target_series.isna().sum())
    print(f"Target '{target_variable}' was non-numeric; cleaned currency/thousands "
          f"formatting and coerced to numeric"
          + (f" ({n_bad} value(s) unparseable -> NaN)." if n_bad else "."))

# --- Project: create-if-missing vs require-existing (ONCE, shared by every
# model in this batch) --------------------------------------------------------
project = mr.get_project(project_name)
if project is None:
    if project_action == "create":
        project = mr.create_project(project_name, mr.default_repository())
        print(f"Created project '{project_name}'")
    else:
        raise RuntimeError(
            f"Project '{project_name}' was not found and 'Use existing project' "
            f"was selected. Choose 'Create the project' or enter an existing name."
        )

# --- Per-model loop: pickle/JSON/card/import for each model slot ------------
imported_models = []          # model_obj for every successfully imported model
monitor_candidates = []       # per-model info for performance monitoring (non-multiclass only)

for _idx, _slot in enumerate(model_slots, start=1):
    pickle_path = _slot["path"]
    _stem = "".join(ch if ch.isalnum() else "_" for ch in Path(pickle_path).stem) or f"Model{_idx}"
    if _stem[0].isdigit():
        _stem = "_" + _stem
    this_prefix = _slot["name"] or _stem
    print(f"[{_idx}/{len(model_slots)}] {this_prefix}: {pickle_path}")
    try:
        with open(pickle_path, "rb") as f:
            model = pickle.load(f)

        # Lineage: compare the scikit-learn version this pickle was made with
        # against the Viya runtime (per-model - each pickle may differ). Warned
        # and stamped into the model description; re-pickling below normalizes
        # the stored artifact to the runtime version regardless.
        import sklearn
        pickled_sklearn = getattr(model, "_sklearn_version", "unknown")
        runtime_sklearn = sklearn.__version__
        sklearn_note = ""
        if pickled_sklearn not in ("unknown", runtime_sklearn):
            sklearn_note = (f" [pickled with scikit-learn {pickled_sklearn}; "
                            f"Viya runtime {runtime_sklearn}]")
            print(f"WARNING: '{this_prefix}' pickled with scikit-learn {pickled_sklearn}, "
                  f"Viya runtime is {runtime_sklearn}. Re-pickled in the runtime version "
                  f"below; verify predictions match the original.")

        model_algorithm = _slot["algorithm"] or type(model).__name__

        # --- Framework / capability detection (groundwork for broader model
        # support) - fail clearly for models without predict()/predict_proba().
        _module = (type(model).__module__ or "").split(".")[0]
        model_framework = {
            "sklearn": "scikit-learn",
            "xgboost": "xgboost",
            "lightgbm": "lightgbm",
            "catboost": "catboost",
            "sasviya": "SAS Viya ML (sasviya.ml)",
        }.get(_module, _module or "unknown")
        if not hasattr(model, "predict"):
            raise RuntimeError(f"Model ({model_framework}) has no predict() method - unsupported.")
        if is_classification and not hasattr(model, "predict_proba"):
            raise RuntimeError(
                f"Classification needs predict_proba(); this {model_framework} model "
                f"does not expose it. (Extension point: add a decision_function/predict "
                f"fallback.)"
            )

        # Predictors: fresh copy of the shared prompt value each iteration, so an
        # auto-detected list for one model never leaks into the next.
        predictor_columns = list(predictor_columns_input)
        if not predictor_columns:
            trained_features = getattr(model, "feature_names_in_", None)
            if trained_features is not None:
                predictor_columns = list(trained_features)
            else:
                # Exclude the target AND the event-probability output var - a
                # training CSV that's been through this step's own monitoring
                # pipeline before (e.g. CARSCLS_1.csv) carries a pre-scored
                # P_<target> reference column, which is numeric and would
                # otherwise get swept up here as if it were a real predictor.
                numeric_cols = data.select_dtypes(include="number").columns.tolist()
                predictor_columns = [
                    c for c in numeric_cols if c not in (target_variable, prob_var)
                ]

        missing_predictors = [c for c in predictor_columns if c not in data.columns]
        if missing_predictors:
            raise RuntimeError(
                f"These predictor columns are not in the training data: {missing_predictors}"
            )

        # A duplicated predictor name (typed twice in the prompt field, or a
        # model/CSV combination that produces one) crashes several rows down
        # inside pyarrow's DataFrame conversion with a cryptic internals
        # traceback - catch it here with a clear message instead.
        _dupe_predictors = {c for c in predictor_columns if predictor_columns.count(c) > 1}
        if _dupe_predictors:
            raise RuntimeError(
                f"Predictor columns list contains duplicates: {sorted(_dupe_predictors)}. "
                f"Remove the repeat(s) from the 'Predictor columns' field."
            )

        X = data[predictor_columns].copy()
        numeric_predictors = X.select_dtypes(include="number").columns
        X[numeric_predictors] = X[numeric_predictors].fillna(X[numeric_predictors].mean())

        # --- Classification label metadata (per-model - each pickle's own classes_).
        # Derives the actual class labels instead of assuming 0/1, so any label
        # scheme works. Binary vs multiclass dispatch mirrors sasctl's own
        # write_score_code.py: len(target_values) == 2 -> binary (uses an event
        # index); len(target_values) > 2 -> multiclass (no single "event", every
        # class gets its own probability column instead).
        class_labels = None
        ordered_values = None
        event_label = None
        event_index = 1
        event_value_typed = None
        is_multiclass = False
        if is_classification:
            raw_classes = getattr(model, "classes_", None)
            if raw_classes is not None:
                raw_classes = list(raw_classes)
            else:
                raw_classes = sorted(pd.Series(data[target_variable]).dropna().unique().tolist())
            if len(raw_classes) < 2:
                raise RuntimeError(
                    f"'{this_prefix}' has fewer than 2 classes - not a valid classifier."
                )
            class_labels = [str(c) for c in raw_classes]
            is_multiclass = len(raw_classes) > 2
            if is_multiclass:
                print(f"'{this_prefix}': multiclass, {len(class_labels)} classes {class_labels}.")
            else:
                if str(event_value) in class_labels:
                    event_index = class_labels.index(str(event_value))
                else:
                    event_index = 1
                    print(f"'{this_prefix}': event value '{event_value}' not in classes "
                          f"{class_labels}; using '{class_labels[1]}'.")
                event_label = class_labels[event_index]
                non_event_label = class_labels[1 - event_index]
                ordered_values = [event_label, non_event_label]
                event_value_typed = raw_classes[event_index]

        output_dir = Path(pickle_path).resolve().parent / this_prefix
        output_dir.mkdir(parents=True, exist_ok=True)

        # --- PZMM artifacts: pickle + input/output variables + model properties -
        pzmm.PickleModel.pickle_trained_model(
            model_prefix=this_prefix, trained_model=model, pickle_path=output_dir
        )
        pzmm.JSONFiles.write_var_json(input_data=X, is_input=True, json_path=output_dir)

        J = pzmm.JSONFiles()
        if is_classification and is_multiclass:
            class_prob_vars = [f"P_{c}" for c in class_labels]
            output_var = pd.DataFrame({target_variable: class_labels})
            for _cv in class_prob_vars:
                output_var[_cv] = [1.0 / len(class_labels)] * len(class_labels)
            J.write_var_json(output_var, False, output_dir)
            J.write_model_properties_json(
                model_name=this_prefix,
                target_variable=target_variable,
                target_values=class_labels,
                json_path=output_dir,
                model_desc="Open-source Python multiclass classification model" + sklearn_note,
                model_algorithm=model_algorithm,
                modeler=current_session().username if current_session() else "",
            )
        elif is_classification:
            output_var = pd.DataFrame({target_variable: class_labels, prob_var: [0.5, 0.5]})
            J.write_var_json(output_var, False, output_dir)
            J.write_model_properties_json(
                model_name=this_prefix,
                target_variable=target_variable,
                target_values=ordered_values,
                json_path=output_dir,
                model_desc="Open-source Python classification model" + sklearn_note,
                model_algorithm=model_algorithm,
                # model_function omitted on purpose -> defaults to lowercase
                # "classification", which is what the Model Card gate checks for.
                modeler=current_session().username if current_session() else "",
            )
            props_path = output_dir / "ModelProperties.json"
            with open(props_path) as f:
                props = json.load(f)
            props["eventProbVar"] = prob_var
            with open(props_path, "w") as f:
                json.dump(props, f, indent=4)
        else:
            # Predicted-value output var is named P_<target>, NOT the target's own
            # name - avoids the predicted value silently overwriting/colliding
            # with the actual target if the two are ever combined in one table.
            output_var = pd.DataFrame({prob_var: [0.0]})
            J.write_var_json(output_var, False, output_dir)
            J.write_model_properties_json(
                model_name=this_prefix,
                target_variable=target_variable,
                json_path=output_dir,
                model_desc="Open-source Python prediction model" + sklearn_note,
                model_algorithm=model_algorithm,
                modeler=current_session().username if current_session() else "",
            )

        # --- Governance / lineage metadata --------------------------------------
        # Provenance (who/what/when/how) + hyperparameters into ModelProperties'
        # custom "properties" list, so audit/governance can see origin in MM.
        # Non-fatal; only prints/logs if it fails, to keep the run quiet.
        try:
            from datetime import datetime, timezone
            _gov = [
                ("registeredBy", (current_session().username or "") if current_session() else ""),
                ("registeredUTC", datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")),
                ("toolBuild", "PickleFileToModelManager 1.7 (03SEP2026)"),
                ("mlFramework", model_framework),
                ("frameworkRuntime", f"scikit-learn {runtime_sklearn}"),
                ("pickledWith", f"scikit-learn {pickled_sklearn}"),
                ("modelClass", type(model).__name__),
                ("modelFunction", model_function),
                ("targetVariable", target_variable),
                ("nFeatures", str(len(predictor_columns))),
                ("nTrainingRows", str(len(data))),
            ]
            try:
                _params = json.dumps({k: str(v) for k, v in model.get_params().items()}, sort_keys=True)
            except Exception:
                _params = ""
            if _params:
                _gov.append(("hyperparameters", _params))
            gov_props = [{"name": n, "value": str(v)[:512], "type": "string"} for n, v in _gov]
            _gp_path = output_dir / "ModelProperties.json"
            with open(_gp_path) as f:
                _mp = json.load(f)
            _existing = _mp.get("properties") or []
            _have = {p.get("name") for p in _existing if isinstance(p, dict)}
            for gp in gov_props:
                if gp["name"] not in _have:
                    _existing.append(gp)
            _mp["properties"] = _existing
            with open(_gp_path, "w") as f:
                json.dump(_mp, f, indent=4)
        except Exception as _e:
            print(f"Governance metadata skipped for '{this_prefix}': {_e}")
            _log("Governance metadata", "failed", f"{this_prefix}: {_e}")

        J.write_file_metadata_json(this_prefix, output_dir)

        # --- Model card: statistics + card files, written BEFORE import so
        # they're part of the model. Non-fatal - a card failure never blocks
        # importing/publishing this (or any other) model. Skipped for multiclass
        # models: calculate_model_statistics()'s N-class behavior isn't verified
        # for this step yet, so it's deliberately left out rather than guessed
        # at - the model still imports fine without a card. -----------
        # _card_generated tracks whether generate_model_card() actually ran (it
        # uploads a <prefix>_train_data CAS table as a side effect) - performance
        # monitoring below needs that table's path for the project's Training
        # table property.
        _card_generated = False
        if do_model_card and is_multiclass:
            print(f"Model card skipped for '{this_prefix}': multiclass model-card "
                  f"statistics aren't supported by this step yet.")
            _log("Model card", "skipped", f"{this_prefix} (multiclass)")
        elif do_model_card:
            try:
                def _prep_features(df_source):
                    Xe = df_source[predictor_columns].copy()
                    _num = Xe.select_dtypes(include="number").columns
                    Xe[_num] = Xe[_num].fillna(Xe[_num].mean())
                    return Xe

                def _prep_target(df_source):
                    ye = df_source[target_variable].reset_index(drop=True)
                    if not is_classification and ye.dtype == object:
                        ye = pd.to_numeric(
                            ye.astype(str).str.replace(r"[^\d.\-eE]", "", regex=True),
                            errors="coerce",
                        )
                    return ye

                if eval_df is None and _idx == 1:
                    print("NOTE: no evaluation dataset supplied - model-card metrics are "
                          "in-sample and will look optimistic. Supply 'Evaluation data' "
                          "for honest metrics.")
                eval_source = eval_df if eval_df is not None else data

                if is_classification:
                    def _clf_frame(df_source):
                        Xe = _prep_features(df_source)
                        return pd.concat(
                            [
                                _prep_target(df_source),
                                pd.Series(model.predict(Xe), name=f"I_{target_variable}"),
                                pd.Series(model.predict_proba(Xe)[:, event_index], name=prob_var),
                            ],
                            axis=1,
                        )

                    pzmm.JSONFiles.calculate_model_statistics(
                        target_value=event_value_typed,
                        train_data=_clf_frame(data),
                        test_data=_clf_frame(eval_source),
                        validate_data=_clf_frame(eval_source),
                        json_path=output_dir,
                        target_type="classification",
                    )

                    if sensitive_column and sensitive_column in data.columns:
                        try:
                            _proba = model.predict_proba(_prep_features(data))[:, event_index]
                            bias_tbl = pd.DataFrame({
                                target_variable: _prep_target(data),
                                f"{prob_var}_1": _proba,
                                f"{prob_var}_0": 1 - _proba,
                                sensitive_column: data[sensitive_column].reset_index(drop=True),
                            })
                            pzmm.JSONFiles.assess_model_bias(
                                score_table=bias_tbl,
                                sensitive_values=sensitive_column,
                                actual_values=target_variable,
                                prob_values=[f"{prob_var}_1", f"{prob_var}_0"],
                                levels=ordered_values,
                                json_path=output_dir,
                            )
                        except Exception as _e:
                            print(f"Bias assessment skipped for '{this_prefix}': {_e}")
                else:
                    def _reg_frame(df_source):
                        _pe = model.predict(_prep_features(df_source))
                        return pd.DataFrame({
                            "actual": _prep_target(df_source),
                            "predict": _pe,
                            "predict_proba": _pe,
                        })

                    pzmm.JSONFiles.calculate_model_statistics(
                        target_value=0,
                        train_data=_reg_frame(data),
                        test_data=_reg_frame(eval_source),
                        validate_data=_reg_frame(eval_source),
                        json_path=output_dir,
                        target_type="prediction",
                    )

                pzmm.JSONFiles.create_requirements_json(model_path=output_dir, output_path=output_dir)

                # Drop any stale '<prefix>_train_data' CAS table before generate_model_card()
                # (below) tries to upload a fresh one. PZMM's upload_training_data() raises
                # 'table already exists' on a name collision rather than overwriting - and
                # the table name is derived ONLY from the model prefix, not the project, so
                # re-running this step with the same prefix (normal during repeated testing)
                # collides with whatever it uploaded last time, silently leaving the card
                # (and the project's Training table property) stale. Mirrors PZMM.ipynb's
                # own model_info loop, which does this same cleanup. Only runs if a CAS
                # connection is already open (established above for performance monitoring) -
                # skips quietly otherwise rather than opening a new connection just for this.
                if conn is not None:
                    try:
                        _stale_train_tbl = conn.CASTable(f"{this_prefix}_train_data", caslib="Public")
                        if _stale_train_tbl.exists():
                            conn.table.droptable(name=f"{this_prefix}_train_data", caslib="Public")
                            print(f"Dropped stale '{this_prefix}_train_data' CAS table before regenerating.")
                    except Exception as _e:
                        print(f"NOTE: could not check/drop stale '{this_prefix}_train_data' table: {_e}")

                card_train = _prep_features(data)
                card_train[target_variable] = _prep_target(data)

                pzmm.JSONFiles.generate_model_card(
                    model_prefix=this_prefix,
                    model_files=output_dir,
                    algorithm=model_algorithm,
                    train_data=card_train,
                    train_predictions=model.predict(_prep_features(data)),
                    target_type="classification" if is_classification else "prediction",
                    target_value=event_value_typed if is_classification else None,
                    interval_vars=predictor_columns,
                    selection_statistic="_KS_" if is_classification else "_ASE_",
                    caslib="Public",
                )

                # Regression Model Health fix: add the missing parameterMap entries
                # and override selectionStatistic to _RSquare_.
                if not is_classification:
                    fitstat_path = output_dir / "dmcas_fitstat.json"
                    reg_props_path = output_dir / "ModelProperties.json"
                    with open(fitstat_path) as f:
                        fitstat = json.load(f)
                    missing_entries = {
                        "_RSquare_": {"parameter": "_RSquare_", "type": "num", "label": "R-Square", "length": 8, "order": 17, "values": ["_RSquare_"], "preformatted": False},
                        "_MAE_": {"parameter": "_MAE_", "type": "num", "label": "Mean Absolute Error", "length": 8, "order": 18, "values": ["_MAE_"], "preformatted": False},
                        "_RMAE_": {"parameter": "_RMAE_", "type": "num", "label": "Root Mean Absolute Error", "length": 8, "order": 19, "values": ["_RMAE_"], "preformatted": False},
                        "_MSLE_": {"parameter": "_MSLE_", "type": "num", "label": "Mean Squared Logarithmic Error", "length": 8, "order": 20, "values": ["_MSLE_"], "preformatted": False},
                        "_RMSLE_": {"parameter": "_RMSLE_", "type": "num", "label": "Root Mean Squared Logarithmic Error", "length": 8, "order": 21, "values": ["_RMSLE_"], "preformatted": False},
                    }
                    for key, entry in missing_entries.items():
                        fitstat["parameterMap"].setdefault(key, entry)
                    with open(fitstat_path, "w") as f:
                        json.dump(fitstat, f, indent=4)
                    r2 = next((row["dataMap"]["_RSquare_"] for row in fitstat["data"]
                               if row["dataMap"].get("_DataRole_") == "TRAIN"), None)
                    if r2 is not None:
                        with open(reg_props_path) as f:
                            reg_props = json.load(f)
                        reg_props["selectionStatistic"] = "_RSquare_"
                        reg_props["selectionStatisticValue"] = str(round(float(r2), 14))
                        with open(reg_props_path, "w") as f:
                            json.dump(reg_props, f, indent=4)

                _basis = "held-out data" if eval_df is not None else "in-sample"
                _log("Model card", "success", f"{this_prefix} ({_basis})")
                _card_generated = True   # <prefix>_train_data now exists in CAS
            except Exception as _e:
                print(f"Model card generation failed for '{this_prefix}' (continuing "
                      f"without it): {_e}")
                _log("Model card", "failed", f"{this_prefix}: {_e}")

        # --- Import into Model Manager -------------------------------------------
        # Multiclass branch verified against sasctl's own write_score_code.py
        # dispatch: len(target_values) > 2 routes to its multiclass code path,
        # which expects score_metrics = [target] + one probability column per
        # class, predict_method returning one float per class (no target_index -
        # that parameter is binary-only), and target_values = every class.
        if is_classification and is_multiclass:
            predict_method = [model.predict_proba, [float] * len(class_labels)]
            score_metrics = [target_variable] + [f"P_{c}" for c in class_labels]
            import_kwargs = dict(target_values=class_labels)
        elif is_classification:
            predict_method = [model.predict_proba, [int, int]]
            score_metrics = [target_variable, prob_var]
            import_kwargs = dict(target_values=class_labels, target_index=event_index)
        else:
            predict_method = [model.predict, [1.0]]
            score_metrics = [prob_var]
            import_kwargs = {}

        result = pzmm.ImportModel.import_model(
            model_files=output_dir,
            model_prefix=this_prefix,
            project=project_name,
            input_data=X,
            predict_method=predict_method,
            score_metrics=score_metrics,
            model_file_name=this_prefix + ".pickle",
            # True bakes a mean-imputation step into the generated score code itself
            # (computed from input_data=X at import time), so a live scoring table
            # with real gaps doesn't crash models that can't handle NaN natively
            # (e.g. GradientBoostingClassifier, unlike DecisionTreeClassifier in this
            # sklearn version) - matches the same fillna(mean) already applied to X
            # before training/import, just re-applied at scoring time too.
            missing_values=True,
            overwrite_model=overwrite_model,
            **import_kwargs,
        )
        pzmm.ScoreCode.score_code = ""   # required between models when importing several
        model_obj = result[0] if isinstance(result, tuple) else result
        imported_models.append(model_obj)
        _log("Model imported", "success", f"{this_prefix} -> {project_name}")

        # --- Publish (optional, per-model so one failure doesn't block the rest
        # of the batch). Uses sasctl's monitored publish_model(), which waits for
        # the publish job to finish and raises clearly on failure - unlike calling
        # the publish service directly, which only confirms the job was submitted,
        # not that it succeeded. Runs BEFORE the performance-monitoring candidate
        # check below, since that check needs to know whether publish actually
        # succeeded. --------------------------------------------
        _published_ok = False
        if do_publish:
            try:
                publish_model(model_obj, publish_destination, replace=overwrite_model)
                print(f"Published '{this_prefix}' to destination "
                      f"'{publish_destination}'.")
                _log("Publish", "success", f"{this_prefix} -> {publish_destination}")
                _published_ok = True
            except Exception as _e:
                print(f"Publish FAILED for '{this_prefix}' to '{publish_destination}': {_e}")
                _log("Publish", "failed", f"{this_prefix}: {_e}")

        # Performance monitoring needs CAS to invoke the model itself
        # (scoring_required=True), so only genuinely-published models are
        # eligible - a model whose publish failed above must NOT end up in the
        # shared performance definition, or it poisons the whole batch's job.
        # SAS Model Manager's monitoring also only supports binary
        # classification / regression - multiclass is skipped, same as the
        # model card.
        if do_performance and not is_multiclass:
            if _published_ok:
                monitor_candidates.append({
                    "model_obj": model_obj,
                    "prefix": this_prefix,
                    "model": model,
                    "predictor_columns": predictor_columns,
                    "is_classification": is_classification,
                    "event_index": event_index,
                    "output_dir": output_dir,
                    "card_generated": _card_generated,
                })
            else:
                print(f"'{this_prefix}' not added to performance monitoring - it "
                      f"wasn't successfully published.")
                _log("Performance monitoring", "skipped", f"{this_prefix} (publish failed)")
        elif do_performance and is_multiclass:
            print(f"Performance monitoring skipped for '{this_prefix}': multiclass "
                  f"models aren't supported by SAS Model Manager performance monitoring.")
            _log("Performance monitoring", "skipped", f"{this_prefix} (multiclass)")
    except Exception as _e:
        print(f"FAILED processing '{this_prefix}': {_e}")
        _log("Model imported", "failed", f"{this_prefix}: {_e}")
        continue

if not imported_models:
    raise RuntimeError("No models were successfully imported.")

# --- Performance monitoring: configure the project once (shared by every
# eligible model in the batch, since they share one target_variable/prob_var),
# upload ONE shared monitoring table directly via CAS, then run the definition.
# Mirrors PZMM.ipynb's proven-working mechanism exactly (scoring_required=True -
# CAS scores each model itself), which is why Publish is required (checked above).
if do_performance and monitor_candidates:
    try:
        _first = monitor_candidates[0]
        with open(_first["output_dir"] / "inputVar.json") as f:
            _in_vars = json.load(f)
        with open(_first["output_dir"] / "outputVar.json") as f:
            _out_vars = json.load(f)
        for _v in _in_vars:
            _v["role"] = "input"
        for _v in _out_vars:
            _v["role"] = "output"
        _var_keys = ("name", "role", "type", "level", "length")
        _proj_variables = [{k: v.get(k) for k in _var_keys} for v in _in_vars + _out_vars]

        _proj = mr.get_project(project_name)
        _proj["function"] = "classification" if is_classification else "prediction"
        _proj["targetVariable"] = target_variable
        _proj["targetLevel"] = "binary" if is_classification else "interval"
        if is_classification:
            _proj["eventProbabilityVariable"] = prob_var
        else:
            _proj["predictionVariable"] = prob_var

        # Project-level Training table: generate_model_card() (above, per-model)
        # already uploaded <prefix>_train_data to CAS and stamped the MODEL's own
        # trainTable property - but the PROJECT's trainTable property is separate
        # and performance monitoring reads that one for its training-data baseline.
        # Nothing else in this step sets it, so without this it's silently blank.
        _card_candidate = next(
            (c for c in monitor_candidates if c.get("card_generated")), None
        )
        if _card_candidate is not None:
            _proj["trainTable"] = (
                f"cas-shared-default/Public/{_card_candidate['prefix']}_train_data".upper()
            )
        else:
            print("NOTE: no model card was generated for any monitored model, so "
                  "the project's Training table property could not be set - the "
                  "performance job may fail without a training-data baseline. "
                  "Enable 'Generate a model card' for at least one model to fix this.")
        _proj = mr.update_project(_proj)

        _existing_vars = []
        try:
            for _v in _proj.variables:
                _existing_vars.append({k: _v.get(k) for k in _var_keys})
        except AttributeError:
            pass
        _new_vars = [v for v in _proj_variables if v not in _existing_vars]
        if _new_vars:
            mr.post(
                f"projects/{_proj.id}/variables",
                json=_new_vars,
                headers={"Content-Type": "application/vnd.sas.collection+json"},
            )
        print(f"Project '{project_name}' configured for performance monitoring "
              f"(target={target_variable}, level="
              f"{'binary' if is_classification else 'interval'}).")

        # --- Upload ONE shared monitoring table directly via CAS - the same
        # mechanism PZMM.ipynb uses (conn.upload(..., promote=True)), instead of
        # sasctl's per-model update_model_performance() helper, which earlier left
        # the table invisible to the performance job ("data source ... could not
        # be found" - the job ran, scoring_required=False, but no table existed
        # under the expected prefix). Uploading before creating the definition so
        # a failure here is caught without ever submitting a doomed job. --------
        table_prefix = "".join(ch for ch in project_name if ch.isalnum())[:20] or "PYMM"
        _run_table_name = f"{table_prefix}_1"
        _uploaded = False
        try:
            _union_predictors = []
            for _c in monitor_candidates:
                for _col in _c["predictor_columns"]:
                    if _col not in _union_predictors:
                        _union_predictors.append(_col)
            _mon_table = data[_union_predictors].copy()
            _num_mon = _mon_table.select_dtypes(include="number").columns
            _mon_table[_num_mon] = _mon_table[_num_mon].fillna(_mon_table[_num_mon].mean())
            _mon_table[target_variable] = target_series
            if is_classification:
                # Reference probability column (first model only) - CAS re-scores
                # every monitored model itself (scoring_required=True below), so
                # this column is for manual inspection only, matching PZMM's
                # own convention (its CARSCLS_1 table does the same).
                _mon_table[prob_var] = _first["model"].predict_proba(
                    data[_first["predictor_columns"]]
                )[:, _first["event_index"]]

            # Hard-stop rather than silently upload a table that would make Model
            # Manager quietly degrade to characteristic-analysis-only (no ROC/Lift/
            # Gini/KS/ASE) with no error of its own - if the actual outcome column
            # (or, for classification, the score output column) we just built is
            # entirely missing, that degraded run would still "complete" and look
            # fine, exactly the misleading failure mode this step exists to avoid.
            if _mon_table[target_variable].isna().all():
                raise RuntimeError(
                    f"Monitoring table has no usable '{target_variable}' values "
                    f"(all missing) - Model Manager would silently skip the "
                    f"accuracy measures (Gini/ROC/Lift/KS/ASE) rather than error, "
                    f"so refusing to upload it instead of producing a performance "
                    f"definition that looks fine but isn't."
                )
            if is_classification and _mon_table[prob_var].isna().all():
                raise RuntimeError(
                    f"Monitoring table has no usable '{prob_var}' (score output) "
                    f"values - Model Manager would silently skip the stability "
                    f"analysis rather than error, so refusing to upload it instead "
                    f"of producing a performance definition that looks fine but isn't."
                )

            _existing_tbl = conn.CASTable(_run_table_name, caslib=monitor_caslib)
            if _existing_tbl.exists():
                conn.table.droptable(name=_run_table_name, caslib=monitor_caslib)
            conn.upload(
                _mon_table,
                casout={"name": _run_table_name, "caslib": monitor_caslib, "promote": True},
            )
            print(f"Uploaded performance monitoring table '{_run_table_name}' to "
                  f"caslib '{monitor_caslib}'.")
            _log("Performance data upload", "success", _run_table_name)
            _uploaded = True
        except Exception as _e:
            print(f"Performance data upload FAILED: {_e}")
            _log("Performance data upload", "failed", str(_e))

        if not _uploaded:
            print("Skipping performance definition - no monitoring data was "
                  "successfully uploaded to CAS (see the failure above).")
            _log("Performance definition executed", "skipped", "no data uploaded")
        else:
            perf_def = mm.create_performance_definition(
                table_prefix=table_prefix,
                project=project_name,
                models=[c["model_obj"] for c in monitor_candidates],
                library_name=monitor_caslib,
                name=f"{project_name} Performance",
                scoring_required=True,
            )
            print(f"Created performance definition for {len(monitor_candidates)} "
                  f"model(s) in caslib '{monitor_caslib}'.")
            _log("Performance definition", "success", f"{len(monitor_candidates)} model(s)")

            # Deliberately NOT calling mm.execute_performance_definition() here.
            # Running the job is a shared, account-level CAS operation (it promotes
            # result tables into Model Manager's own results caslib, which is not
            # scoped per-project) - if anything about that CAS-side state is stale
            # or contended, the failure used to surface buried in this step's run
            # log instead of where you can actually see and retry it. The
            # definition above is real, saved metadata either way - running it by
            # hand costs one click and gives you a normal Model Manager job to
            # inspect/retry on its own terms if it fails.
            print(f"Performance definition created but NOT executed automatically. "
                  f"In Model Manager, open project '{project_name}' -> Performance "
                  f"tab -> select the '{project_name} Performance' definition -> "
                  f"Run, to actually score and populate the performance results.")
            _log("Performance definition executed", "skipped",
                 "run manually in Model Manager")
    except Exception as _e:
        print(f"Performance monitoring setup failed: {_e}")
        _log("Performance monitoring setup", "failed", str(_e))
elif do_performance:
    print("Performance monitoring requested but no eligible (non-multiclass) "
          "models were imported - skipped.")
    _log("Performance monitoring setup", "skipped", "no eligible models")

# --- Run summary ------------------------------------------------------------
print("=" * 64)
print("RUN SUMMARY")
for _step, _status, _detail in STEP_LOG:
    _mark = "OK " if _status == "success" else "ERR"
    print(f"  [{_mark}] {_step}" + (f" - {_detail}" if _detail else ""))
print("=" * 64)

endsubmit;
run;

/* Cleanup - remove the macros/macro variables this step defined for its own
   use, so they don't linger in the compute session after the step finishes.
   Does not touch the prompt-value macro variables (pickle_path, etc.) - those
   belong to the step's UI contract, not to us. */
%sysmacdelete _stage_input / nowarn;
%sysmacdelete _derive_viya_host / nowarn;
%symdel viya_host_auto / nowarn;
