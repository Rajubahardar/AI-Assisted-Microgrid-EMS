%% PV Power Forecast (Phase 9)
% Function: P_pv_forecast = pv_forecast(t, P_pv_rated)
% Purpose: Generate 24-hour PV power forecast using clear-sky model
% Inputs:
%   t           - Time vector [seconds] or hour of day [0-24]
%   P_pv_rated  - Rated PV power [W] (default: 100 kW)
% Outputs:
%   P_pv_forecast - Forecasted PV power [W]

function P_pv_forecast = pv_forecast(t, P_pv_rated)

% Default parameters
if nargin < 2
    P_pv_rated = 100e3; % 100 kWp default
end

% If scalar input (hour of day), convert to time vector
if isscalar(t) && ~isempty(t)
    % Generate 96 time points per hour for 24-hour simulation
    % t is in seconds within the day
    n_points = 96; % 4 points per minute * 60 min * 24 h = 5760, but we use simpler
    t = linspace(0, 86400, 96); % 96 points over 24 hours
end

% Clear-sky PV power model
% The PV output follows a cosine-shaped daily profile
% Peak at solar noon (12 PM = 43200 seconds)
% Full day: 86400 seconds

% Solar elevation angle approximation
% Use daylight hours 6 AM to 6 PM (21600 to 64800 seconds)
% Normalize input to seconds: accept hours (0-24) or seconds (0-86400).
if ~isempty(t) && ~isscalar(t) && any(t > 1000)
    t_day = t;           % already in seconds
else
    t_day = t * 3600;    % input interpreted as hours -> seconds
end

% Calculate hour of day
hour_of_day = mod(t_day / 3600, 24);

% PV power generation using approximated clear-sky model
% Power is proportional to sin(pi * (hour - 6) / 12) for 6 AM - 6 PM, zero otherwise
P_clear = zeros(size(t_day));

% Daytime: 6 AM to 6 PM (hours 6 to 18)
daytime_idx = hour_of_day >= 6 & hour_of_day < 18;

% Cosine-shaped generation within daylight hours
% Peak at hour 12 (solar noon)
hour_normalized = (hour_of_day(daytime_idx) - 12) * pi / 12; % shift to centered at 0
P_clear(daytime_idx) = P_pv_rated * max(0, sin(hour_normalized + pi/2)); % sin goes from 0 at 6AM to 1 at 12PM to 0 at 6PM

% Actually, let's use a cleaner formulation:
% P = P_rated * cos(pi * (t - t_noon) / t_daylength) for |t - t_noon| < t_daylength/2
t_noon = 43200; % 12 PM in seconds
daylength = 21600; % 12 hours of daylight (6 AM to 6 PM)

% Vectorized calculation
hours_from_noon = (t_day - t_noon) / 3600; % hours from solar noon
within_day = abs(hours_from_noon) <= 6; % within 6 AM to 6 PM

% Cosine profile: 0 at 6 AM, 1 at 12 PM, 0 at 6 PM
P_clear = P_pv_rated .* cos(pi/12 .* hours_from_noon);
P_clear(P_clear < 0) = 0; % Clamp negative values
P_clear(~within_day) = 0;

% Add slight stochastic variability (cloud cover simulation)
rng(42); % For reproducibility
cloud_factor = 0.9 + 0.1 * randn(size(P_clear)); % Mean 0.9, std 0.1
P_pv_forecast = P_clear .* max(0, cloud_factor);

% Ensure non-negative
P_pv_forecast(P_pv_forecast < 0) = 0;

% Clip at rated power
P_pv_forecast = min(P_pv_forecast, P_pv_rated);

fprintf('PV forecast generated for %d time points\n', length(t_day));
fprintf('  Peak forecast: %.1f W (%.2f%% of rated)\n', max(P_pv_forecast), max(P_pv_forecast)/P_pv_rated*100);
fprintf('  Total daily energy: %.2f kWh\n', sum(P_pv_forecast)/4000);