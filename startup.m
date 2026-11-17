%% AI-MICROGRID EMS PROJECT STARTUP SCRIPT
clearvars; clc;

% 1. Set project root
projectRoot = pwd;
addpath(genpath(projectRoot));

fprintf('====================================================\n');
fprintf('AI-Assisted Microgrid EMS Initialized Successfully!\n');
fprintf('====================================================\n');

% 2. Run all parameter and design scripts in sequence (without them clearing each other)
microgrid_parameters;
pv_boost_design;
battery_design;
grid_vsi_design;
ev_design;

fprintf('SUCCESS: All workspace variables loaded!\n');

% 3. Display project configuration
fprintf('\nProject Configuration:\n');
fprintf('  PV Rated Power: %.1f kW\n', P_pv_rated/1000);
fprintf('  Battery Usable Energy: %.1f kWh\n', E_batt_usable/1000);
fprintf('  EV Station Power: %.1f kW per charger, %d chargers\n', P_ev_station/1000, Num_ev_stations);
fprintf('  Building Load Peak: %.1f kW\n', P_load_peak/1000);
fprintf('  DC Bus Voltage: %.1f V\n', V_dc);
fprintf('  EMS Scheduling Interval: 900 seconds (15 min)\n');
fprintf('  Total Simulation Duration: 86400 seconds (24 hours)\n');

% 4. Open master model
open_system('Integrated_Microgrid');
guidata(gcbf);