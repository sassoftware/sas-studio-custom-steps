# Pickle File to Model Manager

## Description

The **Pickle File to Model Manager** custom step enables SAS Studio users to register scikit-learn models — trained entirely outside SAS, in plain Python — into SAS Model Manager, without writing any Python or sasctl code themselves.

Point the step at up to four pickled scikit-learn models (classification or regression) and a training data CSV, and it will:

* Auto-detect predictor columns from each model's own trained feature list (or let you specify them explicitly)
* Handle binary **and** multiclass classification, as well as regression/prediction models, in the same batch
* Generate the input/output variable metadata, model properties, and governance/lineage metadata (who registered it, when, the framework, the model's hyperparameters) that SAS Model Manager expects
* Optionally generate a full model card, including honest held-out metrics if an evaluation dataset is supplied, and an optional bias/fairness assessment against a sensitive column
* Create the target Model Manager project if it doesn't already exist, or register into an existing one
* Optionally publish the imported model(s) to an existing Viya publishing destination, verifying the destination exists before doing any work, and confirming the publish job actually completed rather than just submitting it
* Optionally set up performance monitoring for the imported model(s), once published

Up to four models share one training table, one target column, and one project — so a single run of the step can recreate a typical "compare several algorithms on the same problem" workflow (e.g. a decision tree, a random forest, and a gradient boosting model, all predicting the same target) entirely from the UI.

Models are picked up either from a SAS Content location or directly from the compute server's filesystem — the step stages SAS Content files into WORK automatically before reading them.

## User Interface

* ### Model & Data ###

   The core inputs: the first model's pickle file, an optional name and algorithm label (auto-detected from the model's class if left blank), the training data CSV, optional explicit predictor columns (auto-detected from the model if left blank), the target column, an optional held-out evaluation dataset for honest model-card metrics, and the model function (classification or regression/prediction — for classification, also which class value is the target "event").

   ![](img/PickleFileToModelManager-tabModelData.png)

* ### Additional Models ###

   Optionally, up to three more models (pickle file, name, algorithm label each), sharing the same training table, target, and project as the first model.

   ![](img/PickleFileToModelManager-tabAdditionalModels.png)

* ### Project ###

   Whether to require an existing project or create one if it's missing, the project name, and whether re-running should overwrite an existing model version.

   ![](img/PickleFileToModelManager-tabProject.png)

* ### Optional Steps ###

   Whether to generate a model card, and an optional sensitive column for a bias/fairness assessment (classification only).

   Whether to publish the imported model(s), and the name of the (already-existing) Viya publishing destination to publish to. The destination is verified up front — the step fails immediately with a clear message (and the list of destinations that *do* exist) if it can't find the one you named, rather than partway through the run.

   Also whether to set up performance monitoring for the imported model(s) — binary classification and regression/prediction models only, multiclass models are skipped — and which CAS library to upload the monitoring input table to (default `Public`). This requires **Publish** to be checked too: SAS Model Manager scores each model itself to compute performance, so the model has to already be published for that to work. This option configures the project's Model Evaluation properties, uploads a monitoring input table, and creates the performance definition — it deliberately does **not** run the performance job itself (see Requirements below for why). Once the step finishes, open the project's **Performance** tab in Model Manager and click **Run** on the definition it created.

   ![](img/PickleFileToModelManager-tabOptional.png)

* ### Connection ###

   An optional explicit Viya host, only needed if the step can't derive one automatically from the SAS Studio session it's running in.

   ![](img/PickleFileToModelManager-tabConnection.png)

* ### About ###

   General description of the step, plus collapsible **Pre-requisites** and **Documentation** sections and an expanded **Changelog** section showing the current version — kept in sync with the Requirements and Change Log sections of this README.

   ![](img/PickleFileToModelManager-tabAbout.png)

## Requirements

Tested on Viya version Stable 2026.06.

This step's Python code runs inside the SAS Studio compute session's `proc python` block and depends on the following packages already being available in that session's Python environment — the step does not install them itself:

* `sasctl` (including the `pzmm` submodule)
* `pandas`
* `scikit-learn`
* `swat` and `certifi` (needed if you use the SAS Content file picker, and/or performance monitoring — both upload data directly to CAS and this pre-configures SWAT's SSL certificate path so that doesn't fail on servers with the same known broken default; not needed otherwise for `sasserver:`-style paths)

If you plan to use the **Publish** option, the named destination must already exist in your Viya environment — creating a publishing destination is an admin-only operation and out of scope for this step.

If you plan to use **performance monitoring**, the step only creates the performance definition — it does not execute it. Running a performance job promotes result tables into Model Manager's own results library, which is shared across projects rather than scoped to the one you're working in; if that library is carrying any stale state (from an interrupted earlier job, anywhere on the server), the run fails with a "target table ... already exists" error that has nothing to do with your model or this step, and isn't something the step can detect or clean up on your behalf. Running it yourself from the Performance tab keeps that failure mode a normal, retryable Model Manager job instead of a failure buried in this step's log.

## Usage

The step expects a plain CSV training table and one or more pickled scikit-learn models trained on it. A quick way to produce both from data already available in your Viya environment:

1. Export `SASHELP.CARS` to CSV (or use any tabular dataset with a mix of numeric predictors and a target column).
2. In a local Python environment (not SAS Studio), train a simple scikit-learn model against it and pickle the result, e.g.:

   ```python
   import pickle
   from sklearn.ensemble import RandomForestClassifier
   from sklearn.model_selection import train_test_split

   # X, y loaded from your exported CSV, target is a binary column
   X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)
   model = RandomForestClassifier(random_state=42).fit(X_train, y_train)

   with open("model.pickle", "wb") as f:
       pickle.dump(model, f)
   ```

3. Upload `model.pickle` and the training CSV somewhere SAS Studio's file picker can reach them (a SAS Content folder, or a path on the compute server).
4. Add the **Pickle File to Model Manager** step to a flow, point **Model & Data** at the pickle and the CSV, name your target column, and run it.
5. Check SAS Model Manager — the project (created if it didn't exist) should now contain the registered model, with a model card if you left that option checked.

The log ends with a run summary listing every phase (model card, import, publish) as OK or ERR per model, so a problem with one model in a multi-model batch is easy to spot without blocking the rest.

### Running it without the step's UI

`extras/Pickle File to Model Manager.sas` contains the exact same logic as the custom step, with the UI fields exposed as `%let` statements at the top instead. Fill those in and submit the file directly in a SAS Studio Program tab (or any batch/scheduled SAS session) to run it without importing the custom step — useful for repeated or scripted runs.

## Change Log

* Version 1.7 (03SEP2026)
    * Renamed the step to **Pickle File to Model Manager**.
    * Reworked the tab layout to follow the SAS Studio custom step UI guidelines: tab labels now use title case; **Model Type** was merged into **Model & Data**; **Publish & performance monitoring** was merged into **Optional Steps**; field labels now end with a colon (checkboxes excepted); two long, paragraph-length control labels (the publish destination and performance monitoring checkboxes) were split into a short label plus separate explanatory text.
    * Added an **About** tab (general description, collapsible Pre-requisites and Documentation sections, and an expanded Changelog section) — none of this existed before.
* Version 1.6 (26AUG2026)
    * Performance monitoring now refuses to upload a monitoring table that's missing usable values in the actual outcome column (or, for classification, the score/probability column), instead of silently uploading it. Model Manager doesn't error on this itself — it just quietly skips the accuracy or stability measures — so this stops the step from producing a performance definition that looks fine but isn't.
* Version 1.5 (25AUG2026)
    * Restored performance monitoring, redesigned around `scoring_required=True` (SAS Model Manager scores each model itself against one shared uploaded input table) rather than pre-computed scores — the earlier removed version's numbers didn't reliably match each model's independently-verified accuracy; this one mirrors a proven-working, hand-verified pattern instead.
    * The step creates the performance definition but deliberately does not execute it — run it yourself from the project's Performance tab in Model Manager. See Requirements above for why.
    * Fixed a stale-training-data-table bug: re-running the step with the same model prefix (normal during repeated testing) now drops any previously-uploaded `<prefix>_train_data` CAS table before regenerating the model card, instead of leaving the project's Training table property pointing at whatever was uploaded last time.
* Version 1.4 (20AUG2026)
    * Removed in-step performance monitoring. It relied on CAS scoring the model directly and produced results that didn't reliably match a model's independently-verified accuracy; set up performance monitoring yourself in Model Manager once your model(s) are published and look right, rather than relying on this step for it.
    * Publish now uses a monitored publish call that waits for the job to finish and raises a clear error on failure, instead of a fire-and-forget submission that could leave a model looking published when it wasn't.
* Version 1.3 (20AUG2026)
    * Missing-value imputation is now baked into the generated score code (computed from the training data at import time), so a live scoring request with real gaps in it doesn't crash models that can't handle `NaN` natively (e.g. `GradientBoostingClassifier`).
    * Predictor auto-detection now explicitly excludes the target and event-probability columns, so a training table that's previously been used as a monitoring/reference table (and so already contains a scored probability column) doesn't get that column mistaken for a real predictor.
    * A duplicated predictor column name (typed twice, or produced by a particular model/data combination) now fails fast with a clear message instead of a cryptic internal error several steps later.
    * **Training data CSV** and **Target column name** are now marked as required fields in the UI, matching what the step already enforced in code.
* Version 1.2 (19AUG2026)
    * Added multiclass classification support (verified against sasctl's own score-code dispatch logic), alongside the existing binary classification and regression support.
    * Added optional model publishing, with the publish destination verified before any model work begins.
* Version 1.1 (11AUG2026)
    * Reworked to support up to four models sharing one training table, target, and project, each picked via its own file picker, instead of a single model per run.
    * Added governance/lineage metadata (registered by, registered when, ML framework, scikit-learn version, hyperparameters) written into each model's properties.
    * Added optional model card generation with honest held-out metrics (via an optional evaluation dataset) and an optional bias/fairness assessment.
* Version 1.0 (04AUG2026)
    * Initial version — single scikit-learn classification model, pickle + training CSV in, registered into a SAS Model Manager project.
