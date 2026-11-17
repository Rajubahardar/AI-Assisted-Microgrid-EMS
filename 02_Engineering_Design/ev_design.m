%% =========================================================================
%  PHASE 5: ELECTRIC VEHICLE (EV) CHARGING SUBSYSTEM DESIGN & PARAMETERS
%  =========================================================================
%  Description: Calculates electrical and operational parameters for 5 aggregate
%  Level 2 / Fast EV charging bays connected to the 750V common DC bus.
%  Total Aggregate Power: 55 kW (5 bays x 11 kW per bay).
%  =========================================================================

clc;
if ~exist('V_dc', 'var'), microgrid_parameters; end

%% 1. EV Charging Infrastructure Specifications
num_bays      = 5;          % Total charging bays
power_per_bay = 11e3;       % Power rating per bay [W] (11 kW Level 2 / Fast AC-DC)
P_ev_total    = num_bays * power_per_bay; % Aggregate EV demand [W] (55 kW)

%% 2. DC-Bus Side Equivalent Parameters
% Operating off the common 750V DC bus
V_bus         = V_dc;       % 750 V DC bus
I_ev_max      = P_ev_total / V_bus; % Maximum aggregate EV current draw [A] (~73.33 A)

%% 3. Converter & Filtering Parameters (Bidirectional/Controlled Rectifier Stage)
f_sw          = 10e3;       % Switching frequency [Hz] (10 kHz)
ripple_I_pct  = 0.10;       % 10% current ripple target
dI_L_ev       = ripple_I_pct * I_ev_max;
L_ev          = (V_bus * 0.25) / (f_sw * dI_L_ev); % Interface Inductance [H] (~2.55 mH)
C_ev_filter   = 500e-6;     % DC-side decoupling capacitance [F] (500 uF)

%% 4. Display Audit Summary
fprintf('========================================\n');
fprintf('  EV CHARGING SUBSYSTEM DESIGN AUDIT    \n');
fprintf('========================================\n');
fprintf('Number of Charging Bays   : %d bays\n', num_bays);
fprintf('Power Rating per Bay      : %.1f kW\n', power_per_bay/1e3);
fprintf('Total Aggregate EV Demand : %.2f kW\n', P_ev_total/1e3);
fprintf('Nominal DC Bus Voltage    : %.1f V\n', V_bus);
fprintf('Maximum Aggregate Current : %.2f A\n', I_ev_max);
fprintf('EV Subsystem Inductor (L) : %.3f mH\n', L_ev * 1e3);
fprintf('DC Decoupling Filter (C)  : %.1f uF\n', C_ev_filter * 1e6);
fprintf('========================================\n');