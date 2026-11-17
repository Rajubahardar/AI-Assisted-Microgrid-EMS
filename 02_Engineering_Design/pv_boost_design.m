%% PHASE 3: VERIFIED PV & BOOST CONVERTER SIZING SCRIPT
clc;

%% 1. Datasheet Parameters: SunPower SPR-305-WHT (STC)
P_mod_mp   = 305.226;    % Maximum power per module [W]
V_mod_mp   = 54.70;      % Voltage at MPP [V]
I_mod_mp   = 5.58;       % Current at MPP [A]
V_mod_oc   = 64.20;      % Open-circuit voltage [V]
I_mod_sc   = 5.96;       % Short-circuit current [A]
beta_Voc   = -0.27269;   % Voc temperature coefficient [%/degC]

%% 2. Array Configuration (Uses V_dc from microgrid_parameters.m)
Ns         = 9;          % Modules in series per string
Np         = 36;         % Parallel strings

V_pv_mp    = Ns * V_mod_mp;                 % 492.30 V
I_pv_mp    = Np * I_mod_mp;                 % 200.88 A
P_pv_stc   = V_pv_mp * I_pv_mp;             % 98,893.2 W (98.89 kWp)
V_pv_oc    = Ns * V_mod_oc;                 % 577.80 V
V_pv_oc_0C = V_pv_oc * (1 + (beta_Voc/100)*(0 - 25)); % Cold check at 0 degC

assert(V_pv_oc_0C < V_dc, 'ERROR: Cold-weather Voc exceeds DC bus voltage!');

%% 3. Boost Converter Power-Stage Sizing (CCM)
f_sw         = 10e3;     % Switching frequency [Hz]
ripple_I_pct = 0.10;     % 10% inductor current ripple target
ripple_V_pct = 0.005;    % 0.5% DC-link voltage ripple target

D_nom      = 1 - (V_pv_mp / V_dc);          % Nominal duty ratio
dI_L       = ripple_I_pct * I_pv_mp;        % Peak-to-peak ripple current
L_boost    = (V_pv_mp * D_nom) / (f_sw * dI_L); % Boost Inductor [H]

I_out_nom  = P_pv_stc / V_dc;               % Output current
dV_out     = ripple_V_pct * V_dc;           % Output voltage ripple
C_out_min  = (I_out_nom * D_nom) / (f_sw * dV_out); % Output Cap [F]
C_in_min   = dI_L / (8 * f_sw * (0.002 * V_pv_mp));  % Input Cap [F]

fprintf('--> PV Boost Design Parameters Loaded Successfully.\n');

