# Quantum - Reservoir Computing

## Description

The **Quantum - Reservoir Computing** custom step enables SAS Studio users
to transform tabular data into quantum reservoir features.
It then compares how well classical, quantum, and combined features
predict a target.

The step runs the following pipeline:

1. Optionally downsamples the input table.
2. Standardizes the numeric predictors and projects them onto one angle
   per qubit.
3. Builds an OpenQASM 3 reservoir circuit and simulates it with
   `PROC QRUN`.
4. Measures single-qubit and neighboring two-qubit Z expectation values.
5. Adds pairwise products of those expectation values.
6. Writes three feature sets: Classical, Quantum (QRC), and Combined.
7. Optionally trains a classical model on each feature set and reports
   accuracy.

The step supports two modes:

| Mode | What it does |
| :--- | :--- |
| Manual | Runs one reservoir with the circuit type, qubit count, simulation method, and noise model you choose. |
| Hypertune | Uses `PROC HYPERTUNE` to search the qubit count and the SVM parameters C and gamma, then regenerates the reservoir for the best result. |

## User Interface

> Screenshots of each tab are not yet included.
> Add them to the **img** folder, as in the **_template** folder.

### Data tab

| Control | Description |
| :--- | :--- |
| Input data | Required. Numeric columns are used as predictors. |
| Downsample (percent of rows to use) | Simple random sample of the input, 1 to 100. Default 100. |
| Mode | Manual or Hypertune. |
| Save output data | Writes the Combined feature table to the output port. |
| Output table | Name of the output table. Shown when **Save output data** is selected. |
| Replace existing output table | Shown when **Save output data** is selected. |

The target column must be named `y` or `target` (case-insensitive).
If both exist, `y` is used.
If neither exists, a placeholder `y` of 0 is created,
so the ML comparison is not meaningful.
Missing numeric target values are set to 0.

### QRC Options tab

| Control | Mode | Description |
| :--- | :--- | :--- |
| Circuit type | Both | Linear, Entangled, Nonlinear, Recurrent feedback, Parametric, or Sparse connectivity. |
| Number of qubits | Manual | Default 4. |
| Minimum qubits, Maximum qubits | Hypertune | Qubit search range. Defaults 4 to 4. |
| Machine learning algorithm | Both | None, SVM, Logistic regression, Log select, Gradient boosting, or Random forest. |
| C, Gamma | Manual | SVM regularization and RBF kernel bandwidth. |
| C minimum and maximum, Gamma minimum and maximum | Hypertune | SVM search bounds, searched on a log10 scale. |
| Classification threshold | Manual | Used by Logistic regression and Log select. |

The tab also contains gradient boosting and random forest settings,
a logistic variable selection method, and Hypertune bounds for them.
See **Limitations** for which of these affect the results.

### Advanced Simulation tab

| Control | Description |
| :--- | :--- |
| Number of PROC HYPERTUNE optimization trials | Hypertune only. Default 5. |
| Use cache | Reuses the `PROC HYPERTUNE` cache from the current session. Default off. |
| Number of parallel cores | Threads for `PROC QRUN` and parallel Hypertune evaluations. Default 4. |
| Simulation method | Automatic, Statevector, MPS, or QASM. |
| Noise model | Ideal, Depolarising 1%, Depolarising 5%, or Thermal relaxation. |
| Binary label noise rate | Randomly flips binary 0/1 labels at this rate to stress test. Default 0. |
| Show correlation heatmaps | Classical, QRC, and Combined feature-correlation heatmaps. Default on. |

### About tab

Summary of the modes, outputs, and algorithms.

## Output

* **Results window:** The champion circuit display, a runtime summary,
  and an accuracy comparison table and bar chart for Classical, Quantum,
  and Quantum+Classical features.
  The accuracy comparison appears when a machine learning algorithm is
  selected.
  Heatmaps appear when selected.
* **Output port (optional):** The Combined feature table.
  It has columns `x0`, `x1`, and so on
  (classical projections followed by quantum features), plus `y`.
* **Files in the SAS session working directory:**
  Each run writes files whose names include a unique run identifier.
  * `classical_*.csv`, `qrc_*.csv`, and `combined_*.csv`
  * `accuracy_*.csv`
  * `circuit_*.qasm3`
  * `agent_context_*.json`, which records the run settings and file
    names

## Requirements

* SAS Viya with SAS Studio Flows.
* A release that includes `PROC QRUN` (SAS Quantum Lab) and `PROC HYPERTUNE`.
* An active CAS session.
  The step assigns a `qrun` CAS library, starting a `qrun_session` if
  needed, to hold intermediate tables for `PROC QRUN`.
* Numeric predictor columns and a `y` or `target` column.
* A Python environment configured for `PROC HYPERTUNE`.
  See **Limitations**.

The tested Viya version has not been recorded for this step.

## Usage

Use a table with numeric predictors and a binary `y` column.
The following program creates a small example in `WORK`:

```sas
data work.qrc_demo;
    call streaminit(42);
    do i = 1 to 500;
        x1 = rand('normal');
        x2 = rand('normal');
        x3 = rand('normal');
        x4 = rand('normal');
        y = (x1 * x2 + 0.5 * x3 > 0);
        output;
    end;
    drop i;
run;
```

1. Add the **Quantum - Reservoir Computing** step to a flow,
   or open it on its own.
2. Select `WORK.QRC_DEMO` as the input data.
3. Keep Manual mode.
4. On the **QRC Options** tab, set **Machine learning algorithm** to
   **Support vector machine (SVM)**.
5. Run the step.

The comparison table shows accuracy for Classical, Quantum, and
Quantum+Classical features.
The comparison is on training data, not held-out data.
To pass the Combined features downstream, select **Save output data**
and connect the output port.

## Limitations

* Reported accuracy is training accuracy, not held-out accuracy.
  For a binary target, the SVM result is the better of the SVM and a
  nearest-centroid classifier.
* **Simulation method:** Only **Statevector** changes the `PROC QRUN` call.
  Automatic, MPS, and QASM all run with the default method.
* **Hypertune:** Only SVM is tuned.
  For any other algorithm, the step runs a Manual-style reservoir and
  writes a warning.
  The classification threshold, gradient boosting, and random forest
  bounds are not searched.
* **Gradient boosting, random forest, and logistic selection:**
  These models run with procedure defaults.
  The tree and forest parameters and the variable selection method on the
  **QRC Options** tab are not applied.
  Logistic regression and Log select run the same model;
  only the threshold applies.
* **Hypertune circuits and noise:** Hypertune uses the single selected
  circuit type.
  The multi-select circuit and noise lists shown for Hypertune are not
  used.
* **Hypertune Python path:** The step sets the `HYPERTUNE_PYTHON` option to
  a fixed path under `/bigdisk/lax/SpeedDoctor/`.
  Change this to a Python environment available in your deployment before
  using Hypertune mode elsewhere.
* **Binary label noise:** Applies only when `y` is binary 0/1.
* **Qubit count:** The number of projected predictors is the smaller of
  the qubit count and the number of numeric predictors.
  Extra qubits receive an angle of 0.

## Change Log

* Version 1.0 (09NOV2026)
  * Initial version in this repository.
