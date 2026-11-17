%% EV Charging Demand Forecast (Phase 9)
% Function: P_ev_forecast = ev_forecast(t, P_ev_station, Num_ev_stations)
% Purpose: Generate 24-hour EV charging demand forecast using occupancy profile
% Inputs:
%   t           - Time vector [seconds] or hour of day [0-24]
%   P_ev_station - Power per EV charger [W] (default: 11 kW)
%   Num_ev_stations - Total number of charging bays (default: 5)
% Outputs:
%   P_ev_forecast - Forecasted EV charging demand [W]

function P_ev_forecast = ev_forecast(t, P_ev_station, Num_ev_stations)

% Default parameters
if nargin < 2 || isempty(P_ev_station)
    P_ev_station = 11e3;
end
if nargin < 3 || isempty(Num_ev_stations)
    Num_ev_stations = 5;
end

% If scalar input (hour of day), handle appropriately
if isscalar(t) && ~isempty(t)
    % Generate time vector for 24-hour simulation
    t = linspace(0, 86400, 96); % 96 sample points over 24 hours
end

% Time vector in hours
if ~isempty(t) && any(t > 1000) % Looks like seconds
    hours = t / 3600;
else
    hours = t; % Already in hours
end

% EV charging occupancy profile
% Most office/workplace charging: highest occupancy during day (9 AM - 5 PM)
% Some home charging: higher evening/night occupancy
% Mixed: bimodal profile

% Daily occupancy profile for workplace charging
% Peak: 10 AM - 4 PM, with arrival 8-9 AM and departure 5-6 PM
% Use cosine-based occupancy

% Normalize hours to 0-24 range
hour_norm = mod(hours, 24);

% Occupancy: high during daytime (8 AM - 6 PM), low at night
% cosine goes from -1 at 0 to 1 at 12 to -1 at 24
% Shift and scale to get 0 at midnight, 1 at noon, 0 at midnight
occupancy_cosine = -cos(pi/12 * hour_norm); % -cos: 0 at midnight, 1 at noon, 0 at midnight
occupancy = max(0, occupancy_cosine); % Half-day: 0 at midnight, 1 at noon, 0 at midnight

% Actually, let's use a more realistic profile:
% Arrival: 8-9 AM, Departure: 5-6 PM
% Occupancy is high 9 AM - 5 PM

% Better: use two Gaussians for arrival and departure bands
% Arrival window: 8-9 AM
% Departure window: 5-6 PM

% Peak occupancy at 1 PM (normalized to 1.0)
peak_occupancy = 1.0;

% Gaussian occupancy centered at 1 PM
occupancy = peak_occupancy * exp(-(hour_norm - 13).^2 / (2 * 1.5^2));

% Add secondary evening peak for home charging (6-9 PM)
evening_occ = 0.3 * exp(-(hour_norm - 20).^2 / (2 * 2^2));
occupancy = occupancy + evening_occ;

% Clamp to [0, 1]
occupancy = max(0, min(1, occupancy));

% EV power demand = occupancy * max_possible_power
% Not all stations will be occupied at all times
P_max_possible = P_ev_station * Num_ev_stations; % 55 kW total

P_ev_profile = P_max_possible .* occupancy;

% Add stochastic variability (stochastic arrivals/departures)
rng(44); % For reproducibility
stochastic_factor = 1 + 0.15 * randn(size(P_ev_profile)); % 15% std
P_ev_profile = P_ev_profile .* stochastic_factor;

% Ensure non-negative
P_ev_profile(P_ev_profile < 0) = 0;

% Clip at maximum
P_ev_profile = min(P_ev_profile, P_max_possible);
P_ev_forecast = P_ev_profile;
fprintf('EV charging forecast generated for %d time points\n', length(hour_norm));
fprintf('  Peak forecast: %.1f W (%.2f%% of max possible)\n', max(P_ev_profile), max(P_ev_profile)/P_max_possible*100);
fprintf('  Total daily energy: %.2f kWh\n', sum(P_ev_profile)/4000);
fprintf('  Max possible power: %.1f kW\n', P_max_possible/1000);