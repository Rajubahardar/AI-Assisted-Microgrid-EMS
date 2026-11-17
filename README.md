# AI-Assisted Predictive Energy Management of a Grid-Connected PV–Battery–EV Microgrid Using MATLAB/Simulink

**Author:** Raju Bahardar  
**Version:** Release 1 (November 2026)  
**License:** MIT License recommended (see `09_Documentation/` for details)  
**MATLAB Version:** 2023b or later with Optimization Toolbox, Deep Learning Toolbox, and Statistics & Machine Learning Toolbox  

---
## MATLAB Dashboard Demonstration

Watch the recorded demonstration of the MATLAB-based AI-Assisted Microgrid Energy Management System.

[▶ Watch the Dashboard Demonstration](https://github.com/Rajubahardar/AI-Assisted-Microgrid-EMS/releases/tag/v1.0.1)

## 1. Project Overview

This project implements, validates, and compares supervisory Energy Management System (EMS) strategies for a grid-connected Photovoltaic (PV)–Battery Energy Storage System (BESS)–Electric Vehicle (EV) charging microgrid.

The system combines **data-driven machine learning forecasting** with **constrained supervisory Model Predictive Control (MPC)** to coordinate renewable energy generation, energy storage dispatch, and EV load management:

1. **Day-Ahead Machine Learning Forecasting:**
   - **PV Generation:** Long Short-Term Memory (LSTM) network.
   - **Building Load:** Random Forest ensemble regressor.
   - **EV Demand:** Least-Squares Boosting (LSBoost) regression trees.
2. **Supervisory Dispatch Controllers:**
   - **Constrained Supervisory MPC:** Quadratic programming (QP) via MATLAB `quadprog` enforcing battery SOC limits (20%–90%), battery power limits ($\pm 100\text{ kW}$), and grid interconnection constraints ($\pm 150\text{ kW}$).
   - **Rule-Based Heuristic EMS:** Deterministic state logic for baseline comparisons and MPC fallback.
3. **Multi-Horizon Evaluations:**
   - **25-Day (2,400-interval) Three-Strategy Comparison:** Perfect-Forecast MPC, Persistence-Forecast MPC, and ML-Forecast MPC over continuous operations.
   - **Historical 24-Hour (96-interval) Comparison:** Equal-terminal-SOC baseline benchmark.

A comprehensive engineering portfolio report detailing the methodology, architecture, forecasting benchmarks, and multi-day MPC results is available in [`09_Documentation/AI_Assisted_Microgrid_EMS_Final_Project_Report.docx`](09_Documentation/AI_Assisted_Microgrid_EMS_Final_Project_Report.docx). A LinkedIn summary is available in [`09_Documentation/LinkedIn_Project_Announcement.md`](09_Documentation/LinkedIn_Project_Announcement.md).

---

## 2. Key Engineering Parameters (Single Source of Truth)

All microgrid parameters are standardized in `microgrid_parameters.m`:

| Parameter | Value | Units | Description |
|---|---:|---|---|
| PV Rated Power | 100 | kWp | $100\text{ kW}$ DC peak capacity |
| Battery Nominal Energy | 200 | kWh | Nameplate storage capacity |
| Battery Usable Energy | 140 | kWh | Usable energy between 20% and 90% SOC |
| Battery Nominal Voltage | 500 | V | Nominal DC connection voltage |
| Battery Max Power | $\pm 100$ | kW | Maximum charge and discharge rates |
| Battery Efficiency | 95 / 95 | % | $\eta_{\text{charge}} = 0.95$, $\eta_{\text{discharge}} = 0.95$ |
| Grid Power Limit | $\pm 150$ | kW | Maximum grid import and export capacity |
| Grid Interconnection | 415 | V L-L | 3-Phase, 50 Hz (IEC / Nepal NEA standard) |
| DC Bus Voltage | 750 | V | Common DC link nominal voltage |
| EV Charging Stations | 5 × 11 | kW | 5 commercial bays, 11 kW each ($55\text{ kW}$ aggregate) |
| Building Load Peak | 80 | kW | Dual-peak diurnal profile |
| EMS Scheduling Step | 15 | min | 900 seconds per interval (96 intervals/day) |
| Import Tariff | 0.20 | /kWh | Unspecified currency per kWh |
| Export Tariff | 0.05 | /kWh | Unspecified currency per kWh |

---

## 3. Machine Learning Forecasting Models

Day-ahead forecasting models were trained and benchmarked using a 365-day synthetic reference dataset (15-minute resolution, 35,040 samples) representing synthetic Kathmandu 2025 profiles. These profiles are analytically generated synthetic data and do not correspond to live field measurements or actual Nepal grid operations.

**MATLAB Version:** Tested development environment is MATLAB R2024b Update 3. Compatibility with earlier releases is not verified unless otherwise stated.

> [!NOTE]
> **Dataset Disclosure:** The 365-day time series data (`kathmandu_pv_365days.mat`, `building_load_365days.mat`, `ev_365days.mat`) are **synthetic datasets** generated using astronomical solar models, cloud variability functions, and stochastic occupancy distributions. They are not measured physical microgrid sensor recordings.

### Selected Model Architectures and Test Set Performance

| Target | Selected Model | Test MAE (kW) | Test RMSE (kW) | Test R² | Evaluation Summary |
|---|---|---:|---:|---:|---|
| **PV Generation** | **LSTM** (Seed 22) | **1.5089** | **3.1570** | **0.97093** | 5-run mean: $\text{MAE} = 1.5225\text{ kW}$, $\text{RMSE} = 3.1812\text{ kW}$, $R^2 = 0.97047$. Best individual run (Seed 22) selected for MPC integration. |
| **Building Load** | **Random Forest** | **1.4988** | **2.0711** | **0.99034** | 100 regression trees. Outperformed LSBoost ($\text{MAE} = 1.5980\text{ kW}$), LSTM ($\text{MAE} = 1.6917\text{ kW}$), and Persistence ($\text{MAE} = 4.0207\text{ kW}$). |
| **EV Demand** | **LSBoost** | **2.4143** | **5.6099** | **0.76933** | 150 boosted regression trees. Outperformed Random Forest ($\text{MAE} = 2.4950\text{ kW}$), LSTM ($\text{MAE} = 3.2045\text{ kW}$), and Persistence ($\text{MAE} = 2.9785\text{ kW}$). |

---

## 4. Experimental Results

### A. 25-Day (2,400-Interval) Three-Strategy MPC Evaluation

The 25-day simulation (`compare_three_mpc_strategies.m`) evaluates continuous MPC closed-loop dispatch over 2,400 consecutive 15-minute intervals (6-hour / 24-step lookahead horizon).

| Performance Metric | Perfect-Forecast MPC | Persistence-Forecast MPC | ML-Forecast MPC |
|---|---:|---:|---:|
| **Evaluation Horizon** | 2,400 steps (25 days) | 2,400 steps (25 days) | 2,400 steps (25 days) |
| **Successful Solver Calls** | 2,400 (100%) | 2,400 (100%) | 2,400 (100%) |
| **Fallback Activations** | 0 | 0 | 0 |
| **Grid Import (kWh)** | 20,143.24 | 20,143.24 | 20,143.24 |
| **Grid Export (kWh)** | 0.00 | 0.00 | 0.00 |
| **Grid Energy Cost** | 4,028.65 | 4,028.65 | 4,028.65 |
| **Peak Grid Import (kW)** | 93.89 | 93.89 | 93.89 |
| **Battery Throughput (kWh)** | $3.33 \times 10^{-5}$ | $3.82 \times 10^{-5}$ | $3.39 \times 10^{-5}$ |
| **Final Battery SOC (%)** | 60.00 | 60.00 | 60.00 |
| **Mean Solve Time per Step (s)** | 0.0062 | 0.0062 | 0.0060 |
| **Max Predicted Balance Residual (W)** | $9.94 \times 10^{-9}$ | $1.73 \times 10^{-8}$ | $3.93 \times 10^{-9}$ |
| **Max Actual vs. Planned Mismatch (kW)** | $1.60 \times 10^{-8}$ | $1.76 \times 10^{-8}$ | **31.97** |

#### Key Technical Findings from 2,400-Interval Experiment:
1. **Explanation of Near-Zero Battery Throughput:**  
   Battery throughput in this test is negligible ($\approx 3.3 \times 10^{-5}\text{ kWh}$). **This is an expected mathematical consequence of the existing optimization formulation, not a solver failure.** Under the active quadratic cost objective, battery degradation penalty, round-trip efficiency loss ($\eta_{\text{ch}} \cdot \eta_{\text{dis}} \approx 90.25\%$), and flat tariff structure without time-of-use (TOU) arbitrage, cycling energy through the battery increases losses and cost relative to utilizing grid import within the available $\pm 150\text{ kW}$ limits.
2. **ML Grid Reference Mismatch & EV False Positive:**  
   Under ML forecasting, the maximum actual-versus-planned grid power mismatch reached $31.97\text{ kW}$. Analysis confirms this was primarily caused by an EV demand false positive ($\approx 28.18\text{ kW}$ overprediction), where the ML model predicted charging demand during hours when actual EV arrivals were zero, requiring real-time grid compensation.

---

### B. Historical 24-Hour Equal-Terminal-SOC Comparison

The single-day 24-hour baseline (`compare_ems_mpc_equal_soc.m`, 96 intervals) evaluates rule-based dispatch against constrained MPC when both controllers are constrained to finish at $\text{SOC} = 60\%$:

| Metric | Rule-Based EMS | Constrained MPC | Match Status |
|---|---:|---:|:---:|
| Grid import (kWh) | 188.484 | 196.335 | Verified |
| Grid export (kWh) | 96.343 | 97.867 | Verified |
| Battery throughput (kWh) | 353.563 | 280.368 | Verified |
| PV curtailment (kWh) | 1.524 | $\approx 4.67 \times 10^{-9}$ | Verified |
| Unmet demand (kWh) | 11.602 | $\approx 7.48 \times 10^{-14}$ | Verified |
| Grid energy cost | 32.880 | 34.374 | Verified |
| Final battery SOC (%) | 60.00 | 60.00 | Verified |
| Max power balance residual (W) | $3.64 \times 10^{-12}$ | $1.41 \times 10^{-11}$ | Verified |

*Note: The rule-based controller achieves equal terminal SOC via end-of-day redistribution, whereas MPC naturally respects the terminal constraint across its lookahead horizon.*

---

## 5. Scope Disclosure & Validation Boundaries

To maintain scientific integrity, the validation levels are explicitly defined:

1. **Numerical Forecasting Validation:** **COMPLETE.** All three ML models were trained, cross-validated, and tested against baselines with quantitative metrics (MAE, RMSE, R²).
2. **Numerical EMS/MPC Validation:** **COMPLETE.** Supervisory power balance equations, SOC constraints, and dispatch optimizations were numerically verified across both 24-hour and 25-day simulations with residuals $< 10^{-8}\text{ W}$.
3. **Simulink Subsystem / Integration Validation:** **DESIGN-LEVEL ONLY.** Subsystem models (`PV_Subsystem.slx`, `Battery_Subsystem.slx`, `Grid_Subsystem.slx`, `Integrated_Microgrid.slx`) exist at the design/topological level.
   - Validation reports `INT_01` through `INT_05` in `08_Validation/` record that standalone component integration tests were **not executed**.
   - `INT_06` represents **user-reported numerical supervisory dispatch**, not physical electrical circuit simulation.
4. **Physical & Switching-Level Electrical Validation:** **OUT OF SCOPE.** No switching-level converter dynamics (PWM, IGBT losses), DC-bus transient ripples, LCL resonance attenuation, or physical hardware testing were performed in Release 1.
5. **Release 2 Scope:** Reinforcement Learning (RL / PPO) remains unstarted and deferred to Release 2.

---

## 6. Repository Structure

```text
AI_Microgrid_EMS/
├── 01_Requirements/              # Roadmap and project specifications
├── 02_Engineering_Design/        # Analytical design calculations (PV, BESS, VSI, EV)
├── 03_Simulink_Models/           # Simulink subsystem and integrated models
├── 04_Data/
│   └── generated/                # 24-hour analytical profile dataset
├── 05_Forecasting/               # Analytical & day-ahead ML forecasting
│   ├── day_ahead/                # 365-day LSTM, RF, LSBoost models, experiments, results
│   ├── pv_forecast.m             # Analytical cosine model
│   ├── load_forecast.m           # Analytical Gaussian model
│   └── ev_forecast.m             # Analytical occupancy model
├── 06_Energy_Management/         # Dispatch controllers
│   ├── rule_based/               # ems_dispatch_rules.m
│   └── mpc_dispatch.m            # Constrained QP MPC dispatch
├── 07_Experiments/               # 24-hour comparison scripts and outputs
├── 08_Validation/                # Numerical validation reports and INT audit logs
├── 09_Documentation/             # Comprehensive report (.docx), checklist, guides, LinkedIn announcement
│   ├── AI_Assisted_Microgrid_EMS_Final_Project_Report.docx # Comprehensive Release 1 portfolio report
│   ├── LinkedIn_Project_Announcement.md # Professional LinkedIn announcement draft
│   ├── RELEASE_CHECKLIST.md      # Release 1 milestone verification checklist
│   ├── PROJECT_AUDIT.md          # Technical audit and parameter verification
│   └── REPRODUCIBILITY_GUIDE.md  # Step-by-step reproduction instructions
├── compare_three_mpc_strategies.m # 25-day 2,400-interval 3-strategy MPC evaluation
├── three_strategy_mpc_comparison.csv # 2,400-step numerical benchmark results
├── microgrid_parameters.m        # Master system parameter file
├── startup.m                     # Environment initializer
├── PROJECT_STATUS.md             # Project status tracker
├── AUDIT_REPORT.md               # Historical audit report (preserved)
└── README.md                     # This file
```

---

## 7. Execution and Reproducibility

### Prerequisites
- MATLAB R2023b or later
- Optimization Toolbox (for `quadprog`)
- Statistics and Machine Learning Toolbox
- Deep Learning Toolbox

### Running 24-Hour Comparison
```matlab
cd C:\Users\Raju\AI_Microgrid_EMS
startup
compare_ems_mpc_equal_soc
```
Results will be saved to `07_Experiments/EMS_MPC_Comparison_Equal_SOC/`.

### Running 25-Day Three-Strategy MPC Evaluation
```matlab
cd C:\Users\Raju\AI_Microgrid_EMS
startup
% Ensure workspace contains 365-day synthetic datasets
compare_three_mpc_strategies
```
Results are saved to `three_strategy_mpc_comparison.csv` and `.mat`.
