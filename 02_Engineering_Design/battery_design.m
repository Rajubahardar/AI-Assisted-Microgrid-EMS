%% PHASE 4: VERIFIED BATTERY & BIDIRECTIONAL CONVERTER SIZING SCRIPT
clc;

%% 1. Battery Specifications & Energy Limits
E_total_kWh    = E_batt_nominal / 1e3;    % 200 kWh nominal capacity
V_batt         = V_batt_nom;              % 500 V nominal voltage
Q_batt_total   = E_batt_nominal / V_batt; % Total Amp-hour capacity [Ah] (400 Ah)

E_usable_kWh   = E_batt_usable / 1e3;     % 140 kWh usable energy
Q_batt_usable  = E_usable_kWh * 1e3 / V_batt; % Usable Amp-hours [Ah] (280 Ah)

%% 2. Bidirectional DC-DC Converter Power-Stage Sizing (CCM)
f_sw           = 10e3;                    % Switching frequency [Hz]
P_batt_rated   = 100e3;                   % Rated BESS power [W]
I_batt_max     = P_batt_rated / V_batt;   % Max nominal battery current [A]

% Duty cycles (Uses V_dc from microgrid_parameters.m)
D_dis          = 1 - (V_batt / V_dc);     % Boost mode (Discharging)
D_ch           = V_batt / V_dc;           % Buck mode (Charging)

% Inductor & Filter Sizing
ripple_I_pct   = 0.15;                    % 15% current ripple target
dI_L           = ripple_I_pct * I_batt_max; 
L_bidir        = (V_batt * D_dis) / (f_sw * dI_L); % Inductance [H]

ripple_V_batt  = 0.005 * V_batt;          
C_batt_min     = (I_batt_max * D_dis) / (f_sw * ripple_V_batt); % Filter Cap [F]

fprintf('--> Battery & Bidirectional Converter Parameters Loaded Successfully.\n');