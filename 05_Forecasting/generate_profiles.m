%% Phase 9: Generate 24-Hour Forecast Profiles
% Script: generate_profiles.m
% Purpose: Generate 24-hour PV, building-load, and EV-demand forecast profiles
%          at 15-minute resolution (96 samples) for the microgrid
% Output: Saves profiles to 04_Data/generated/microgrid_profiles_24h.mat

clear; clc;

fprintf('Phase 9: Generating 24-Hour Forecast Profiles\n');
fprintf('================================================\n\n');

% 1. Initialize project
projectRoot = pwd;
addpath(genpath(projectRoot));
microgrid_parameters;
fprintf('Project parameters loaded.\n\n');

% 2. Simulation parameters
sim_duration = 86400;        % 24 hours [seconds]
ems_interval = 900;          % EMS scheduling interval [seconds] = 15 min
N_steps = round(sim_duration / ems_interval); % Total EMS steps = 96

fprintf('Simulation Duration: %.1f hours (24 h)\n', sim_duration/3600);
fprintf('EMS Scheduling Interval: %d seconds (15 min)\n', ems_interval);
fprintf('Number of forecast samples: %d (96 points)\n\n', N_steps);

% 3. Generate forecast profiles using Phase 9 forecasting functions
fprintf('--- Generating PV Forecast ---\n');
% Use the pv_forecast function with the EMS time vector (in hours at 15-min intervals)
t_ems_hours = (0:N_steps-1)' * (ems_interval/3600); % 0, 0.25, 0.5, ..., 23.75

% Generate PV forecast (each point = average for that 15-min window)
P_pv_forecast = zeros(N_steps, 1);
for k = 1:N_steps
    hour = t_ems_hours(k);
    % Generate 100 points around this hour for averaging
    t_local = linspace(hour, hour + ems_interval/3600, 100);
    P_pv_forecast(k) = mean(pv_forecast(t_local, P_pv_rated));
end

fprintf('  PV Forecast Generated\n');
fprintf('  Peak PV: %.1f kW (%.1f%% of rated)\n', max(P_pv_forecast)/1000, max(P_pv_forecast)/P_pv_rated*100);

fprintf('--- Generating Building Load Forecast ---\n');
P_building_forecast = zeros(N_steps, 1);
for k = 1:N_steps
    hour = t_ems_hours(k);
    t_local = linspace(hour, hour + ems_interval/3600, 100);
    P_building_forecast(k) = mean(load_forecast(t_local, P_load_peak));
end
fprintf('  Building Load Forecast Generated\n');
fprintf('  Peak Load: %.1f kW\n', max(P_building_forecast)/1000);

fprintf('--- Generating EV Charging Forecast ---\n');
P_ev_forecast = zeros(N_steps, 1);
for k = 1:N_steps
    hour = t_ems_hours(k);
    t_local = linspace(hour, hour + ems_interval/3600, 100);
    P_ev_forecast(k) = mean(ev_forecast(t_local, P_ev_station, Num_ev_stations));
end
fprintf('  EV Charging Forecast Generated\n');
fprintf('  Peak EV Demand: %.1f kW (%.1f%% of max %.1f kW)\n', ...
    max(P_ev_forecast)/1000, max(P_ev_forecast)/(P_ev_station*Num_ev_stations)*100, ...
    P_ev_station*Num_ev_stations/1000);

% 4. Save profile data
outputDir = fullfile(projectRoot, '04_Data', 'generated');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

profileFile = fullfile(outputDir, 'microgrid_profiles_24h.mat');

% Create profile structure
profiles.P_pv_W = P_pv_forecast;              % 96 samples
profiles.P_building_W = P_building_forecast;  % 96 samples
profiles.P_ev_W = P_ev_forecast;              % 96 samples

% Additional metadata
profiles.N_steps = N_steps;
profiles.ems_interval_s = ems_interval;
profiles.sim_duration_s = sim_duration;
profiles.time_hours = t_ems_hours;
profiles.generated_at = datestr(now);
profiles.version = '1.0';

% Save profiles
save(profileFile, 'profiles');
fprintf('\nProfile data saved to: %s\n', profileFile);
fprintf('  File size: %.1f KB\n', dir(profileFile).bytes/1024);

% 5. Display summary
fprintf('\n--- Forecast Summary ---\n');
fprintf('PV: Peak %.1f kW (%.1f%% of rated), Total daily: %.1f kWh\n', ...
    max(P_pv_forecast)/1000, max(P_pv_forecast)/P_pv_rated*100, ...
    sum(P_pv_forecast)/4000);
fprintf('Building Load: Peak %.1f kW, Total daily: %.1f kWh\n', ...
    max(P_building_forecast)/1000, sum(P_building_forecast)/4000);
fprintf('EV Charging: Peak %.1f kW (%.1f%% of max), Total daily: %.1f kWh\n', ...
    max(P_ev_forecast)/1000, max(P_ev_forecast)/(P_ev_station*Num_ev_stations)*100, ...
    sum(P_ev_forecast)/4000);

fprintf('\nPhase 9 complete. Forecast profiles generated for use in comparison (Phase 12).\n');
fprintf('============================================================\n');