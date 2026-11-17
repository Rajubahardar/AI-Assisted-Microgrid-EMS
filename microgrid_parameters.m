%% MICROGRID INITIALIZATION SCRIPT (Nepal / IEC Standard)
% Standard: 415V L-L, 50 Hz Utility Grid | 750V Common DC Bus
clc;
fprintf('Initializing Microgrid Parameters (Nepal/IEC Standard)...\n');

%% 1. Utility Grid Parameters (IEC 3-Phase)
V_grid_LL  = 415;          % Line-to-Line RMS Voltage [V]
f_grid     = 50;           % Nominal Frequency [Hz]
omega_grid = 2 * pi * f_grid;
V_grid_LN  = V_grid_LL / sqrt(3); % Line-to-Neutral [V] (~240V)

%% 2. Common DC Bus
V_dc       = 750;          % Nominal DC-Link Voltage [V]
C_dc       = 2200e-6;      % DC-link capacitance [F]

%% 3. PV Generation Subsystem Baseline
P_pv_rated = 100e3;        % Rated PV Array Power [W] (100 kWp)

%% 4. Battery Energy Storage System (BESS) Baseline
E_batt_nominal = 200e3;    % Nominal Energy Capacity [Wh] (200 kWh)
V_batt_nom     = 500;      % Nominal Battery Voltage [V]
SOC_min        = 0.20;     % Minimum Allowable State of Charge (20%)
SOC_max        = 0.90;     % Maximum Allowable State of Charge (90%)
E_batt_usable  = E_batt_nominal * (SOC_max - SOC_min); % 140 kWh usable

%% 5. Electric Vehicle (EV) Charging Stations
P_ev_station   = 11e3;     % Power per EV charger [W] (11 kW)
Num_ev_stations = 5;       % Total charging bays
P_batt_max = 100e3;        % Maximum Battery Power [W] (100 kW)

%% 6. Building Load Profile
P_load_peak    = 80e3;     % Peak Building Demand [W] (80 kW)

fprintf('Global parameters loaded into workspace.\n');