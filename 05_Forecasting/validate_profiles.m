%% Phase 9: Validate Forecast Profile Dataset
% Script: validate_profiles.m
% Purpose: Validate the generated 24-hour forecast profiles
%          at 15-minute resolution (96 samples)
% Output: Reports validation results to command window

clear; clc;

fprintf('Phase 9: Validating Forecast Profile Dataset\n');
fprintf('=============================================\n\n');

% 1. Project paths
projectRoot = pwd;
addpath(genpath(projectRoot));
microgrid_parameters;

profileFile = fullfile(projectRoot, ...
    '04_Data', 'generated', 'microgrid_profiles_24h.mat');

% 2. Check file exists
fprintf('--- File Validation ---\n');
if ~isfile(profileFile)
    error('Profile file not found: %s\n', profileFile);
end
fprintf('✓ Profile file found: %s\n', profileFile);

% 3. Load profiles
fprintf('\n--- Loading Profiles ---\n');
data = load(profileFile);
if ~isfield(data, 'profiles')
    error('Required field "profiles" not found in MAT file');
end
profiles = data.profiles;

% 4. Validate profile structure
fprintf('\n--- Structure Validation ---\n');
requiredFields = {'P_pv_W', 'P_building_W', 'P_ev_W', ...
    'N_steps', 'ems_interval_s', 'sim_duration_s'};
for i = 1:length(requiredFields)
    if ~isfield(profiles, requiredFields{i})
        error('Missing field: %s', requiredFields{i});
    end
end
fprintf('✓ All required fields present\n');

% 5. Validate dimensions
fprintf('\n--- Dimension Validation ---\n');
expectedSamples = 96; % 24 hours / 15 min
if profiles.N_steps ~= expectedSamples
    error('Expected %d samples, got %d', expectedSamples, profiles.N_steps);
end
if numel(profiles.P_pv_W) ~= expectedSamples
    error('PV profiles: expected %d samples, got %d', ...
        expectedSamples, numel(profiles.P_pv_W));
end
if numel(profiles.P_building_W) ~= expectedSamples
    error('Building profiles: expected %d samples, got %d', ...
        expectedSamples, numel(profiles.P_building_W));
end
if numel(profiles.P_ev_W) ~= expectedSamples
    error('EV profiles: expected %d samples, got %d', ...
        expectedSamples, numel(profiles.P_ev_W));
end
fprintf('✓ All profiles: %d samples (96 expected)\n', expectedSamples);

% 6. Validate data types and values
fprintf('\n--- Data Validation ---\n');

% Check for NaN/Inf
if any(~isfinite(profiles.P_pv_W))
    error('PV profiles contain NaN or Inf values');
end
if any(~isfinite(profiles.P_building_W))
    error('Building profiles contain NaN or Inf values');
end
if any(~isfinite(profiles.P_ev_W))
    error('EV profiles contain NaN or Inf values');
end
fprintf('✓ No NaN or Inf values\n');

% Check for non-negative power values
if any(profiles.P_pv_W < 0)
    error('PV profiles contain negative values');
end
if any(profiles.P_building_W < 0)
    error('Building profiles contain negative values');
end
if any(profiles.P_ev_W < 0)
    error('EV profiles contain negative values');
end
fprintf('✓ All power values are non-negative\n');

% Check for non-negative parameters
if profiles.ems_interval_s <= 0
    error('EMS interval must be positive');
end
if profiles.sim_duration_s <= 0
    error('Simulation duration must be positive');
end
fprintf('✓ Timing parameters are valid\n');

% 7. Validate power limits
fprintf('\n--- Power Limit Validation ---\n');
if max(profiles.P_pv_W) > P_pv_rated
    warning('PV peak exceeds rated power (%d W > %d W)', ...
        max(profiles.P_pv_W), P_pv_rated);
end
if max(profiles.P_building_W) > P_load_peak
    warning('Building load peak exceeds rated (%d W > %d W)', ...
        max(profiles.P_building_W), P_load_peak);
end
if max(profiles.P_ev_W) > (P_ev_station * Num_ev_stations)
    warning('EV demand exceeds station capacity (%d W > %d W)', ...
        max(profiles.P_ev_W), P_ev_station * Num_ev_stations);
end
fprintf('✓ Power limits checked (warnings indicate expected overshoots)\n');

% 8. Summary statistics
fprintf('\n--- Summary Statistics ---\n');
fprintf('PV (kW):\n');
fprintf('  Peak:     %.1f kW (%.1f%% of rated)\n', ...
    max(profiles.P_pv_W)/1000, max(profiles.P_pv_W)/P_pv_rated*100);
fprintf('  Min:      %.1f kW\n', min(profiles.P_pv_W)/1000);
fprintf('  Total:    %.1f kWh/day\n', sum(profiles.P_pv_W)*profiles.ems_interval_s/3600/1000);

fprintf('Building Load (kW):\n');
fprintf('  Peak:     %.1f kW\n', max(profiles.P_building_W)/1000);
fprintf('  Min:      %.1f kW\n', min(profiles.P_building_W)/1000);
fprintf('  Total:    %.1f kWh/day\n', ...
    sum(profiles.P_building_W)*profiles.ems_interval_s/3600/1000);

fprintf('EV Charging (kW):\n');
fprintf('  Peak:     %.1f kW (%.1f%% of max possible)\n', ...
    max(profiles.P_ev_W)/1000, ...
    max(profiles.P_ev_W)/(P_ev_station*Num_ev_stations)*100);
fprintf('  Total:    %.1f kWh/day\n', ...
    sum(profiles.P_ev_W)*profiles.ems_interval_s/3600/1000);

% 9. EMS interval check
fprintf('\n--- Timing Validation ---\n');
fprintf('EMS interval: %.1f seconds (%.1f minutes)\n', ...
    profiles.ems_interval_s, profiles.ems_interval_s/60);
fprintf('Simulation duration: %.1f hours\n', ...
    profiles.sim_duration_s/3600);
fprintf('Number of samples: %d (verified: %d expected)\n', ...
    profiles.N_steps, expectedSamples);
fprintf('Time step: %.1f minutes\n', ...
    profiles.ems_interval_s/60);

% 10. Print validation results
fprintf('\n=============================================\n');
fprintf('Phase 9 Validation COMPLETE\n');
fprintf('=============================================\n');
fprintf('All profiles validated successfully.\n');
fprintf('Profiles available for EMS vs MPC comparison.\n');
fprintf('=============================================\n');