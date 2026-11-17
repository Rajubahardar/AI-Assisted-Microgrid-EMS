%% =========================================================================
%  Grid-Tied VSI & Integrated Microgrid Engineering Design Script
%  =========================================================================
clc;

%% 1. AC Side Voltage and Current Bases (Uses V_grid_LL and f_grid from globals)
V_phase_pk = (V_grid_LL / sqrt(3)) * sqrt(2); % Peak Phase Voltage (~338.9 V)
P_rated    = 100e3;                          % Rated Inverter Power (W)
I_base_pk  = (2 * P_rated) / (3 * V_phase_pk);  % Peak Phase Current (~196.2 A)

%% 2. LCL Filter Design Parameters
f_sw       = 10e3;             % 10 kHz switching frequency
L1         = 2.5e-3;           % Inverter-side Inductor (H) -> 2.5 mH
L2         = 1.0e-3;           % Grid-side Inductor (H) -> 1.0 mH
C_filter   = 25e-6;            % Filter Capacitance (F) -> 25 uF

f_res      = (1 / (2 * pi)) * sqrt((L1 + L2) / (L1 * L2 * C_filter));

%% 3. Outer Voltage Loop & Inner Current Loop PI Controller Gains
Kp_v       = 0.5;              % Voltage Proportional Gain
Ki_v       = 25.0;             % Voltage Integral Gain
Kp_i       = 12.5;             % Current Proportional Gain
Ki_i       = 850.0;            % Current Integral Gain

I_ref_max  = 500;              % Current reference upper limit (A)
I_ref_min  = 0;                % Current reference lower limit (A)

% fprintf('--> Grid VSI Parameters Loaded Successfully.\n');
fprintf('\n========================================\n');
fprintf('  GRID-TIED VSI PARAMETERS AUDIT\n');
fprintf('========================================\n');
fprintf('Grid Line-to-Line Voltage : %.1f V RMS\n', V_grid_LL);
fprintf('Grid Frequency            : %.1f Hz\n', f_grid);
fprintf('Peak Phase Voltage        : %.2f V\n', V_phase_pk);
fprintf('Peak Base Current         : %.2f A\n', I_base_pk);
fprintf('Inverter Inductor (L1)    : %.2f mH\n', L1 * 1e3);
fprintf('Grid-side Inductor (L2)   : %.2f mH\n', L2 * 1e3);
fprintf('Filter Capacitance (C)    : %.2f uF\n', C_filter * 1e6);
fprintf('Resonance Frequency       : %.2f Hz\n', f_res);
fprintf('Voltage Loop PI Gains     : Kp = %.2f, Ki = %.2f\n', Kp_v, Ki_v);
fprintf('Current Loop PI Gains     : Kp = %.2f, Ki = %.2f\n', Kp_i, Ki_i);
fprintf('========================================\n');