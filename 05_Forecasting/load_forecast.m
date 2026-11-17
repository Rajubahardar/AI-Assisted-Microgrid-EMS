%% Building Load Forecast (Phase 9)
% Function: P_load_forecast = load_forecast(t, P_load_peak)
% Purpose: Generate 24-hour building load demand forecast using daily profile
% Inputs:
%   t           - Time vector [seconds] or hour of day [0-24]
%   P_load_peak - Peak building load [W] (default: 80 kW)
% Outputs:
%   P_load_forecast - Forecasted building load [W]

function P_load_forecast = load_forecast(t, P_load_peak)

% Default parameters
if nargin < 2
    P_load_peak = 80e3; % 80 kW default from project parameters
end

% If scalar input (hour of day), handle appropriately
if isscalar(t) && ~isempty(t)
    % Generate time vector for 24-hour simulation
    t = linspace(0, 86400, 96); % 96 sample points over 24 hours
end

% Building load profile model
% Typical commercial building load with:
% - Morning peak (8-9 AM)
% - Midday baseline
% - Evening peak (5-6 PM)
% - Night baseline (low but non-zero)

% Time vector in seconds, convert to hours
if ~isempty(t) && any(t > 1000) % Looks like seconds
    hours = t / 3600;
else
    hours = t; % Already in hours
end

% Gaussian-shaped peaks for building load
% Morning peak: 8 AM (hour 8)
% Evening peak: 6 PM (hour 18)

% Baseline load (20% of peak)
P_baseline = 0.2 * P_load_peak;

% Morning peak (Gaussian centered at 8 AM, sigma = 1 hour)
morning_peak = P_load_peak * exp(-(hours - 8).^2 / (2 * 1^2));

% Evening peak (Gaussian centered at 6 PM, sigma = 1 hour)  
evening_peak = P_load_peak * exp(-(hours - 18).^2 / (2 * 1^2));

% Combined profile: baseline + both peaks
P_load_profile = P_baseline + morning_peak/4 + evening_peak/4; % Divide by 4 to make peaks ~25% of peak

% Ensure non-negative
P_load_profile(P_load_profile < 0) = 0;

% Add stochastic variability (occupancy variations)
rng(43); % For reproducibility
variability = 1 + 0.1 * randn(size(P_load_profile)); % 10% std deviation
P_load_forecast = P_load_profile .* variability;

% Ensure non-negative
P_load_forecast(P_load_forecast < 0) = 0;

% Clip at reasonable maximum (150% of peak)
P_load_forecast = min(P_load_forecast, 1.5 * P_load_peak);

fprintf('Building load forecast generated for %d time points\n', length(hours));
fprintf('  Peak forecast: %.1f W (%.2f%% of rated peak)\n', max(P_load_forecast), max(P_load_forecast)/P_load_peak*100);
fprintf('  Daily energy demand: %.2f kWh\n', sum(P_load_forecast)/4000);
fprintf('  Baseline portion: %.1f%%\n', P_baseline/max(P_load_profile)*100);