# AI-Assisted Predictive Energy Management of a Grid-Connected PV–Battery–EV Microgrid

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=Rajubahardar/AI-Assisted-Microgrid-EMS)
[![Release](https://img.shields.io/badge/Release-v1.0.1%20(Nov%202026)-0b2545)](https://github.com/Rajubahardar/AI-Assisted-Microgrid-EMS/releases/tag/v1.0.1)
[![Microgrid Rating](https://img.shields.io/badge/Microgrid-100%20kWp%20PV%20%7C%20200%20kWh%20BESS%20%7C%2055%20kW%20EV-2E7D32)](#2-master-microgrid-parameters)
[![Optimizer](https://img.shields.io/badge/Supervisory%20MPC-Quadratic%20Programming%20(quadprog)-6A1B9A)](#1-project-overview)
[![Technical Report](https://img.shields.io/badge/Report-Final%20Project%20Report%20(.docx)-1d4e89)](09_Documentation/AI_Assisted_Microgrid_EMS_Final_Project_Report.docx)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#license)

A modular **MATLAB/Simulink** framework implementing, validating, and benchmarking **AI-assisted supervisory Energy Management System (EMS)** strategies for a grid-connected **Photovoltaic (PV)–Battery Energy Storage System (BESS)–Electric Vehicle (EV)** charging microgrid. The architecture couples **day-ahead machine learning forecasting** (`LSTM`, `Random Forest`, `LSBoost`) with **constrained Quadratic Programming Model Predictive Control (`quadprog` MPC)** to coordinate renewable generation, storage dispatch, and commercial EV charging under strict physical and grid-interconnection constraints.

> **Dashboard Demo & Documentation:** Watch the **[MATLAB Dashboard Demonstration Video (Release v1.0.1)](https://github.com/Rajubahardar/AI-Assisted-Microgrid-EMS/releases/tag/v1.0.1)**, read the complete **[Final Project Report](09_Documentation/AI_Assisted_Microgrid_EMS_Final_Project_Report.docx)**, or view the **[LinkedIn Project Announcement](09_Documentation/LinkedIn_Project_Announcement.md)**.

---

## Key Highlights

- **High-Accuracy Multi-Target ML Forecasting:** Trained on a 365-day (35,040-interval) 15-minute reference dataset, achieving **$R^2 = 0.97093$** for PV generation (`LSTM`), **$R^2 = 0.99034$** for building load (`Random Forest`), and **$R^2 = 0.76933$** for stochastic EV charging demand (`LSBoost`).
- **Real-Time Constrained QP-MPC Dispatch (`~6.0 ms/step`):** Enforces battery SOC bounds ($20\%\text{–}90\%$), battery power limits ($\pm 100\text{ kW}$), and 3-phase grid tie-line limits ($\pm 150\text{ kW}$) across **2,400 consecutive 15-minute intervals (25 days)** with **100% solver feasibility (0 fallbacks)** and numerical power-balance residuals $< 2 \times 10^{-8}\text{ W}$.
- **Zero Curtailment & Zero Unmet Demand in 24-Hour Benchmark:** Under equal-terminal-SOC ($60\%$) evaluation, constrained MPC eliminates both PV curtailment ($\approx 4.67 \times 10^{-9}\text{ kWh}$ vs. $1.524\text{ kWh}$) and unmet load ($\approx 7.48 \times 10^{-14}\text{ kWh}$ vs. $11.602\text{ kWh}$) compared to deterministic rule-based dispatch while reducing battery cycling by **20.7%**.
- **Transparent Engineering & Validation Boundaries:** Explicitly documents synthetic dataset provenance, flat-tariff battery throughput economics, EV false-positive forecast sensitivity, and numerical vs. switching-level validation boundaries.

---

## 1. Project Overview

The supervisory EMS coordinates three core layers across a 15-minute ($900\text{ s}$) scheduling step ($96\text{ intervals/day}$):

1. **Day-Ahead Machine Learning Forecasting (`05_Forecasting/day_ahead/`):**
   - **PV Generation:** Long Short-Term Memory (`LSTM`) recurrent neural network.
   - **Building Load:** `Random Forest` ensemble regressor ($100$ regression trees).
   - **EV Charging Demand:** Least-Squares Boosting (`LSBoost`) gradient-boosted regression trees ($150$ learners).
2. **Supervisory Dispatch Controllers (`06_Energy_Management/`):**
   - **Constrained Supervisory MPC (`mpc_dispatch.m`):** Convex Quadratic Programming (`quadprog`) over a 6-hour ($24$-step) lookahead horizon enforcing SOC dynamics, converter power ratings, terminal SOC targets, and grid import/export bounds.
   - **Rule-Based Heuristic EMS (`ems_dispatch_rules.m`):** Deterministic state-machine dispatch serving as an analytical baseline and safety fallback.
3. **Multi-Horizon Evaluation Suite:**
   - **25-Day (2,400-Interval) Three-Strategy Comparison (`compare_three_mpc_strategies.m`):** Continuous closed-loop benchmark comparing *Perfect-Forecast MPC*, *Persistence-Forecast MPC*, and *ML-Forecast MPC*.
   - **Historical 24-Hour (96-Interval) Comparison (`07_Experiments/`):** Equal-terminal-SOC ($\text{SOC}_{\text{final}} = 60\%$) benchmark comparing Rule-Based EMS against Constrained MPC.

---

## 2. Master Microgrid Parameters

All physical ratings, efficiency constants, and tariff parameters are centralized in [`microgrid_parameters.m`](microgrid_parameters.m):

| Parameter | Value | Units | Engineering Specification |
| :--- | :---: | :---: | :--- |
| **PV Rated Power** | `100` | $\text{kWp}$ | $100\text{ kW}$ DC peak solar array capacity |
| **Battery Nominal Energy** | `200` | $\text{kWh}$ | Nameplate BESS energy capacity |
| **Battery Usable Energy** | `140` | $\text{kWh}$ | Active operating window between $20\%$ and $90\%$ SOC |
| **Battery Nominal Voltage** | `500` | $\text{V}$ | Nominal DC battery bank terminal voltage |
| **Battery Max Power** | `±100` | $\text{kW}$ | Symmetric maximum charge and discharge limits |
| **Battery Round-Trip Efficiency** | `95 / 95` | $\%$ | $\eta_{\text{charge}} = 0.95$, $\eta_{\text{discharge}} = 0.95$ ($\eta_{\text{rt}} = 90.25\%$) |
| **Grid Tie-Line Power Limit** | `±150` | $\text{kW}$ | Maximum bidirectional PCC import and export capacity |
| **Grid Interconnection** | `415` | $\text{V}_{\text{L-L}}$ | 3-Phase, $50\text{ Hz}$ (IEC / Nepal NEA distribution standard) |
| **Common DC Link Voltage** | `750` | $\text{V}$ | Regulated internal microgrid DC bus nominal voltage |
| **EV Charging Infrastructure** | `5 × 11` | $\text{kW}$ | $5$ commercial Level-2 charging bays ($55\text{ kW}$ aggregate) |
| **Building Load Peak** | `80` | $\text{kW}$ | Dual-peak commercial/institutional diurnal load profile |
| **EMS Scheduling Step** | `15` | $\text{min}$ | $900\text{ s}$ control interval ($96\text{ steps/day}$) |
| **Grid Import / Export Tariff** | `0.20 / 0.05` | $\text{per kWh}$ | Flat energy tariff structure (unspecified currency units) |

---

## 3. Machine Learning Forecasting Benchmarks

Day-ahead models were trained and evaluated on a **365-day reference dataset** ($15\text{-minute}$ resolution, $35,040\text{ samples}$) representing synthetic Kathmandu 2025 diurnal and seasonal profiles.

> [!NOTE]
> **Dataset Provenance Disclosure:** The 365-day time-series files (`kathmandu_pv_365days.mat`, `building_load_365days.mat`, `ev_365days.mat`) are **analytically generated synthetic datasets** constructed from astronomical solar irradiance models, stochastic cloud-variability functions, and occupancy/arrival probability distributions. They do not represent live physical field measurements or actual Nepal Electricity Authority (NEA) grid telemetry.

### Test-Set Accuracy Across Selected Architectures

| Forecast Target | Selected Model | Test MAE (kW) | Test RMSE (kW) | Test $R^2$ | Benchmark Notes |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **PV Generation** | **LSTM** *(Seed 22)* | **`1.5089`** | **`3.1570`** | **`0.97093`** | 5-seed mean: $\text{MAE} = 1.5225\text{ kW}$, $\text{RMSE} = 3.1812\text{ kW}$, $R^2 = 0.97047$. Best seed integrated into MPC. |
| **Building Load** | **Random Forest** | **`1.4988`** | **`2.0711`** | **`0.99034`** | $100$ regression trees; outperformed `LSBoost` ($\text{MAE} = 1.5980\text{ kW}$), `LSTM` ($1.6917\text{ kW}$), and `Persistence` ($4.0207\text{ kW}$). |
| **EV Charging Demand** | **LSBoost** | **`2.4143`** | **`5.6099`** | **`0.76933`** | $150$ boosted trees; outperformed `Random Forest` ($\text{MAE} = 2.4950\text{ kW}$), `LSTM` ($3.2045\text{ kW}$), and `Persistence` ($2.9785\text{ kW}$). |

---

## 4. Experimental Dispatch Results

### A. 25-Day (2,400-Interval) Three-Strategy MPC Evaluation

Continuous closed-loop simulation (`compare_three_mpc_strategies.m`) over **2,400 consecutive 15-minute intervals** using a 6-hour ($24$-step) prediction horizon:

| Performance Metric | Perfect-Forecast MPC | Persistence-Forecast MPC | ML-Forecast MPC |
| :--- | :---: | :---: | :---: |
| **Evaluation Horizon** | `2,400 steps (25 days)` | `2,400 steps (25 days)` | `2,400 steps (25 days)` |
| **Successful QP Solver Calls** | `2,400 (100%)` | `2,400 (100%)` | `2,400 (100%)` |
| **Heuristic Fallback Activations** | `0` | `0` | `0` |
| **Total Grid Import (kWh)** | `20,143.24` | `20,143.24` | `20,143.24` |
| **Total Grid Export (kWh)** | `0.00` | `0.00` | `0.00` |
| **Cumulative Grid Energy Cost** | `4,028.65` | `4,028.65` | `4,028.65` |
| **Peak Grid Import (kW)** | `93.89` | `93.89` | `93.89` |
| **Battery Throughput (kWh)** | $3.33 \times 10^{-5}$ | $3.82 \times 10^{-5}$ | $3.39 \times 10^{-5}$ |
| **Final Battery SOC (%)** | `60.00%` | `60.00%` | `60.00%` |
| **Mean QP Solve Time / Step (s)** | `0.0062` | `0.0062` | `0.0060` |
| **Max Predicted Balance Residual (W)** | $9.94 \times 10^{-9}$ | $1.73 \times 10^{-8}$ | $3.93 \times 10^{-9}$ |
| **Max Actual vs. Planned Mismatch (kW)** | $1.60 \times 10^{-8}$ | $1.76 \times 10^{-8}$ | **`31.97`** |

#### Key Technical Findings from the 2,400-Interval Experiment
1. **Analytical Explanation of Near-Zero Battery Throughput ($\approx 3.33 \times 10^{-5}\text{ kWh}$):**  
   Near-zero battery cycling in this 25-day test is an **exact mathematical consequence of the convex cost formulation rather than a solver anomaly**. Under a flat import tariff ($0.20/\text{kWh}$) with no Time-of-Use (TOU) price spread, no peak-demand ratchet penalty, a non-zero quadratic battery degradation weight, and round-trip efficiency losses ($\eta_{\text{ch}} \cdot \eta_{\text{dis}} = 90.25\%$), cycling energy through the BESS strictly increases total cost compared to supplying net load directly from the grid within the $\pm 150\text{ kW}$ tie-line limit.
2. **ML Grid Reference Mismatch & EV False-Positive Sensitivity:**  
   Under `ML-Forecast MPC`, the maximum discrepancy between planned and realized grid power reached **$31.97\text{ kW}$**. Post-simulation residual decomposition confirms this spike stemmed primarily from an EV charging false positive ($\approx 28.18\text{ kW}$ overprediction), where `LSBoost` predicted stochastic vehicle arrivals during intervals with zero actual EV load, requiring instantaneous PCC grid balancing.

---

### B. Historical 24-Hour (96-Interval) Equal-Terminal-SOC Comparison

Single-day benchmark (`compare_ems_mpc_equal_soc.m`, $96\text{ intervals}$) comparing Rule-Based EMS against Constrained MPC when both controllers are constrained to finish at $\text{SOC}_{\text{final}} = 60.00\%$:

| Performance Metric | Rule-Based EMS | Constrained MPC | Verification Status |
| :--- | :---: | :---: | :---: |
| **Grid Import (kWh)** | `188.484` | `196.335` | Verified |
| **Grid Export (kWh)** | `96.343` | `97.867` | Verified |
| **Battery Throughput (kWh)** | `353.563` | `280.368` | Verified |
| **PV Curtailment (kWh)** | `1.524` | $\approx 4.67 \times 10^{-9}$ | Verified |
| **Unmet Load Demand (kWh)** | `11.602` | $\approx 7.48 \times 10^{-14}$ | Verified |
| **Net Grid Energy Cost** | `32.880` | `34.374` | Verified |
| **Final Battery SOC (%)** | `60.00%` | `60.00%` | Verified |
| **Max Power Balance Residual (W)** | $3.64 \times 10^{-12}$ | $1.41 \times 10^{-11}$ | Verified |

*Note: The rule-based controller achieves equal terminal SOC via end-of-day redistribution, whereas MPC naturally enforces the terminal SOC constraint across its receding lookahead horizon without sacrificing load service.*

---

## 5. Validation Scope & Scientific Boundaries

To maintain strict engineering transparency, Release 1 validation boundaries are categorized into five explicit tiers:

| Validation Tier | Status | Technical Scope & Audit Reference |
| :--- | :---: | :--- |
| **1. Numerical ML Forecasting** | **COMPLETE** | `LSTM`, `Random Forest`, and `LSBoost` trained, cross-validated, and benchmarked (`MAE`, `RMSE`, $R^2$) against persistence baselines. |
| **2. Numerical Supervisory EMS/MPC** | **COMPLETE** | Power-balance equations, SOC dynamics, and QP constraints verified over 24-hour and 25-day horizons with residuals $< 10^{-8}\text{ W}$. |
| **3. Simulink Subsystem Integration** | **DESIGN-LEVEL ONLY** | `PV_Subsystem.slx`, `Battery_Subsystem.slx`, `Grid_Subsystem.slx`, and `Integrated_Microgrid.slx` exist at topological design level (`INT_01`–`INT_05` unexecuted; `INT_06` reflects numerical supervisory dispatch). |
| **4. Physical & Switching Dynamics** | **OUT OF SCOPE** | High-frequency PWM switching, IGBT conduction/switching losses, DC-bus ripple, LCL filter resonance, and hardware-in-the-loop (HIL) testing are excluded from Release 1. |
| **5. Reinforcement Learning (RL/PPO)** | **DEFERRED (RELEASE 2)** | Proximal Policy Optimization (PPO) adaptive dispatch agent is planned for Release 2. |

---

## 6. Repository Structure

```text
AI-Assisted-Microgrid-EMS/
├── 01_Requirements/                  # Roadmap and system engineering specifications
├── 02_Engineering_Design/            # Analytical sizing calculations (PV, BESS, VSI, EV)
├── 03_Simulink_Models/               # Design-level Simulink subsystem & integrated models (.slx)
├── 04_Data/
│   └── generated/                    # 24-hour analytical reference profile dataset
├── 05_Forecasting/                   # Analytical & day-ahead ML forecasting pipelines
│   ├── day_ahead/                    # 365-day LSTM, Random Forest, LSBoost models & results
│   ├── pv_forecast.m                 # Analytical cosine solar generation model
│   ├── load_forecast.m               # Analytical Gaussian building load model
│   └── ev_forecast.m                 # Analytical EV arrival/occupancy model
├── 06_Energy_Management/             # Supervisory dispatch controllers
│   ├── rule_based/                   # ems_dispatch_rules.m deterministic baseline
│   └── mpc_dispatch.m                # Constrained Quadratic Programming (quadprog) MPC
├── 07_Experiments/                   # 24-hour equal-terminal-SOC comparison scripts & logs
├── 08_Validation/                    # Numerical validation reports and INT_01–INT_06 audit logs
├── 09_Documentation/                 # Final report (.docx), guides & LinkedIn announcement
│   ├── AI_Assisted_Microgrid_EMS_Final_Project_Report.docx
│   ├── LinkedIn_Project_Announcement.md
│   ├── RELEASE_CHECKLIST.md
│   ├── PROJECT_AUDIT.md
│   └── REPRODUCIBILITY_GUIDE.md
├── compare_three_mpc_strategies.m    # 25-day (2,400-step) 3-strategy MPC benchmark script
├── three_strategy_mpc_comparison.csv # 2,400-interval numerical benchmark dataset
├── microgrid_parameters.m            # Single-source-of-truth microgrid configuration
├── startup.m                         # MATLAB path and environment initializer
├── PROJECT_STATUS.md                 # Release milestone and task tracker
├── AUDIT_REPORT.md                   # Historical technical audit report
└── README.md                         # Project documentation, results & reproducibility guide
```

---

## 7. Reproducibility & Quick Start

### Prerequisites
- **MATLAB R2023b or later** *(verified on MATLAB R2024b Update 3)*
- **Optimization Toolbox** (`quadprog`)
- **Statistics and Machine Learning Toolbox** (`TreeBagger` / `fitrensemble`)
- **Deep Learning Toolbox** (`trainNetwork` / `LSTM`)

### Execution Steps

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/Rajubahardar/AI-Assisted-Microgrid-EMS.git](https://github.com/Rajubahardar/AI-Assisted-Microgrid-EMS.git)
   ```

2. **Initialize the MATLAB workspace and run the 24-hour equal-SOC benchmark:**
   ```matlab
   cd('AI-Assisted-Microgrid-EMS');
   startup
   compare_ems_mpc_equal_soc
   ```
   *Outputs are saved to `07_Experiments/EMS_MPC_Comparison_Equal_SOC/`.*

3. **Run the 25-day (2,400-interval) three-strategy MPC benchmark:**
   ```matlab
   startup
   % Load the 365-day synthetic datasets from 05_Forecasting/day_ahead/ into the workspace
   compare_three_mpc_strategies
   ```
   *Outputs are exported to `three_strategy_mpc_comparison.csv` and `.mat`.*

---

## Citation

```bibtex
@misc{bahardar2026microgridems,
  author       = {Bahardar, Raju},
  title        = {AI-Assisted Predictive Energy Management of a Grid-Connected PV--Battery--EV Microgrid Using MATLAB/Simulink},
  year         = {2026},
  howpublished = {\url{[https://github.com/Rajubahardar/AI-Assisted-Microgrid-EMS](https://github.com/Rajubahardar/AI-Assisted-Microgrid-EMS)}},
  note         = {Release v1.0.1 — Day-Ahead ML Forecasting and Constrained QP-MPC Supervisory Dispatch Suite}
}
```

---

## License

Recommended under the **MIT License** (see [`09_Documentation/`](09_Documentation/) for full release documentation).
