
function [P_batt_ref, P_grid_ref, mpc_info] = mpc_dispatch( ...
    P_pv_forecast, P_load_forecast, P_ev_forecast, soc0, params)
% MPC_DISPATCH
% Constrained supervisory MPC with rule-based fallback.
%
% Inputs:
%   P_pv_forecast   - PV forecast [W]
%   P_load_forecast - Building load forecast [W]
%   P_ev_forecast   - EV demand forecast [W]
%   soc0            - Initial SOC [0...1]
%   params          - Optional parameter structure
%
% Outputs:
%   P_batt_ref - First battery reference [W]
%                Positive = discharge, negative = charge
%   P_grid_ref - First grid reference [W]
%                Positive = import, negative = export
%   mpc_info   - Optimization and dispatch diagnostics
%
% Requires:
%   Optimization Toolbox (quadprog)
%   ems_dispatch_rules.m on MATLAB path
%
% New parameters:
%   params.allow_battery_export = false (default)
%   params.terminal_soc_target  = 0.60 (default)
%
% Terminal SOC is a HARD lower-bound constraint at the end
% of the prediction horizon.
%
% Fallback operates on the first interval only.

%% 1. Validate inputs

if nargin < 5 || isempty(params)
    params = struct();
end

validateattributes(P_pv_forecast, {'numeric'}, ...
    {'vector','real','finite','nonnegative'});

validateattributes(P_load_forecast, {'numeric'}, ...
    {'vector','real','finite','nonnegative'});

validateattributes(P_ev_forecast, {'numeric'}, ...
    {'vector','real','finite','nonnegative'});

validateattributes(soc0, {'numeric'}, ...
    {'scalar','real','finite','>=',0,'<=',1});

Ppv = P_pv_forecast(:) / 1000;
Pload = P_load_forecast(:) / 1000;
Pev = P_ev_forecast(:) / 1000;

N = numel(Ppv);

if numel(Pload) ~= N || numel(Pev) ~= N
    error('MPC:ForecastSizeMismatch', ...
        'PV, building-load and EV forecasts must have equal lengths.');
end

if N < 1
    error('MPC:EmptyForecast', ...
        'Forecast horizon cannot be empty.');
end

if exist('quadprog','file') == 0
    error('MPC:MissingOptimizationToolbox', ...
        'quadprog is unavailable. Check Optimization Toolbox.');
end

%% 2. Parameters and defaults

dt = get_param(params,'dt_hours',0.25);

E_batt = get_param(params,'battery_energy_kWh',200);
P_batt_max = get_param(params,'battery_power_max_kW',100);

soc_min = get_param(params,'soc_min',0.20);
soc_max = get_param(params,'soc_max',0.90);

eta_charge = get_param(params,'eta_charge',0.95);
eta_discharge = get_param(params,'eta_discharge',0.95);

P_grid_import_max = get_param(params,'grid_import_max_kW',150);
P_grid_export_max = get_param(params,'grid_export_max_kW',150);

battery_cost = get_param(params,'battery_throughput_cost',0.01);
curtailment_cost = get_param(params,'curtailment_cost',0.50);

tariff_import = expand_profile( ...
    get_param(params,'tariff_import',0.20),N);

tariff_export = expand_profile( ...
    get_param(params,'tariff_export',0.05),N);

regularization = get_param(params,'regularization',1e-6);

% Battery export policy.
allow_battery_export = get_param( ...
    params,'allow_battery_export',false);

% Minimum SOC required at the end of the prediction horizon.
terminal_soc_target = get_param( ...
    params,'terminal_soc_target',0.60);

%% 3. Parameter validation

if ~isscalar(dt) || ~isfinite(dt) || dt <= 0 || ...
   ~isscalar(E_batt) || ~isfinite(E_batt) || E_batt <= 0 || ...
   ~isscalar(P_batt_max) || ~isfinite(P_batt_max) || P_batt_max <= 0

    error('MPC:InvalidParameter', ...
        'Time step, battery energy and battery power must be positive finite scalars.');
end

if ~isscalar(P_grid_import_max) || ...
   ~isfinite(P_grid_import_max) || P_grid_import_max < 0 || ...
   ~isscalar(P_grid_export_max) || ...
   ~isfinite(P_grid_export_max) || P_grid_export_max < 0

    error('MPC:InvalidGridLimit', ...
        'Grid import/export limits must be nonnegative finite scalars.');
end

if ~isscalar(soc_min) || ~isscalar(soc_max) || ...
   ~isfinite(soc_min) || ~isfinite(soc_max) || ...
   soc_min < 0 || soc_max > 1 || soc_min >= soc_max

    error('MPC:InvalidSOCBounds','Invalid SOC limits.');
end

% Numerical tolerance for SOC validation
soc_tol = 1e-9;

% Reject genuine SOC limit violations
if soc0 < soc_min - soc_tol || ...
   soc0 > soc_max + soc_tol

    error('MPC:InitialSOCOutsideLimits', ...
        'Initial SOC is outside configured operating limits.');
end

% Correct insignificant floating-point deviations
soc0 = min(max(soc0, soc_min), soc_max);
if ~isscalar(eta_charge) || ~isscalar(eta_discharge) || ...
   ~isfinite(eta_charge) || ~isfinite(eta_discharge) || ...
   eta_charge <= 0 || eta_charge > 1 || ...
   eta_discharge <= 0 || eta_discharge > 1

    error('MPC:InvalidEfficiency', ...
        'Battery efficiencies must be in the range (0,1].');
end

if ~isscalar(battery_cost) || ~isfinite(battery_cost) || ...
   battery_cost < 0 || ...
   ~isscalar(curtailment_cost) || ~isfinite(curtailment_cost) || ...
   curtailment_cost < 0 || ...
   ~isscalar(regularization) || ~isfinite(regularization) || ...
   regularization <= 0

    error('MPC:InvalidCostParameter', ...
        'Costs must be nonnegative and regularization positive.');
end

if any(tariff_import < tariff_export)
    error('MPC:InvalidTariff', ...
        'Import tariffs must not be lower than export tariffs.');
end

if ~isscalar(allow_battery_export) || ...
   ~(islogical(allow_battery_export) || ...
   (isnumeric(allow_battery_export) && ...
   isfinite(allow_battery_export) && ...
   (allow_battery_export == 0 || allow_battery_export == 1)))

    error('MPC:InvalidExportPolicy', ...
        'allow_battery_export must be logical or numeric 0/1.');
end

allow_battery_export = logical(allow_battery_export);

if ~isscalar(terminal_soc_target) || ...
   ~isfinite(terminal_soc_target) || ...
   terminal_soc_target < soc_min || ...
   terminal_soc_target > soc_max

    error('MPC:InvalidTerminalSOC', ...
        'Terminal SOC target must be between soc_min and soc_max.');
end

%% 4. Decision variables
%
% x = [Pdis; Pch; Pimport; Pexport; Pcurtail]
% All variables are in kW.

nvar = 5*N;

idx_dis = 1:N;
idx_ch = N+(1:N);
idx_imp = 2*N+(1:N);
idx_exp = 3*N+(1:N);
idx_curt = 4*N+(1:N);

%% 5. Objective function

f = zeros(nvar,1);

f(idx_dis) = battery_cost*dt;
f(idx_ch) = battery_cost*dt;

f(idx_imp) = tariff_import*dt;
f(idx_exp) = -tariff_export*dt;

f(idx_curt) = curtailment_cost*dt;

H = 2*regularization*eye(nvar);

%% 6. Power balance constraints

Aeq = zeros(N,nvar);
beq = Pload + Pev - Ppv;

for k = 1:N
    Aeq(k,idx_dis(k)) = 1;
    Aeq(k,idx_ch(k)) = -1;
    Aeq(k,idx_imp(k)) = 1;
    Aeq(k,idx_exp(k)) = -1;
    Aeq(k,idx_curt(k)) = -1;
end

%% 7. Battery SOC constraints

A_soc = zeros(2*N,nvar);
b_soc = zeros(2*N,1);

energy_discharge_factor = dt/(eta_discharge*E_batt);
energy_charge_factor = eta_charge*dt/E_batt;

for k = 1:N

    A_soc(k,idx_dis(1:k)) = energy_discharge_factor;
    A_soc(k,idx_ch(1:k)) = -energy_charge_factor;

    b_soc(k) = soc0-soc_min;

    A_soc(N+k,:) = -A_soc(k,:);
    b_soc(N+k) = soc_max-soc0;

end

%% 8. Terminal SOC constraint
%
% Require SOC at the end of the horizon to be at least
% terminal_soc_target.
%
% SOC_N = soc0 + sum(eta_ch*Pch*dt/E)
%              - sum(Pdis*dt/(eta_dis*E))
%
% Rearranged into A*x <= b:

A_terminal = zeros(1,nvar);

A_terminal(idx_dis) = energy_discharge_factor;
A_terminal(idx_ch) = -energy_charge_factor;

b_terminal = soc0-terminal_soc_target;

A = [A_soc; A_terminal];
b = [b_soc; b_terminal];

%% 9. Decision-variable bounds

lb = zeros(nvar,1);
ub = zeros(nvar,1);

ub(idx_dis) = P_batt_max;
ub(idx_ch) = P_batt_max;

ub(idx_imp) = P_grid_import_max;
ub(idx_exp) = P_grid_export_max;

ub(idx_curt) = Ppv;

% Restrict battery discharge to local net demand
% when battery-to-grid export is disabled.

if ~allow_battery_export

    local_net_demand = Pload + Pev - Ppv;

    max_local_discharge = max(local_net_demand,0);

    ub(idx_dis) = min(P_batt_max,max_local_discharge);

end

%% 10. Solve optimization problem

options = optimoptions('quadprog', ...
    'Display','off', ...
    'Algorithm','interior-point-convex');

[x,objective_value,exitflag,output] = quadprog( ...
    H,f,A,b,Aeq,beq,lb,ub,[],options);

%% 11. MPC or fallback selection

if ~isempty(x) && exitflag > 0

    % -----------------------------------------------------
    % MPC SUCCESS
    % -----------------------------------------------------

    Pdis = x(idx_dis);
    Pch = x(idx_ch);
    Pimport = x(idx_imp);
    Pexport = x(idx_exp);
    Pcurtail = x(idx_curt);

    P_batt_schedule = Pdis-Pch;
    P_grid_schedule = Pimport-Pexport;

    % Predicted SOC trajectory.

    soc_schedule = zeros(N,1);
    soc_previous = soc0;

    for k = 1:N

        battery_energy_change = ...
            (eta_charge*Pch(k) ...
            - Pdis(k)/eta_discharge)*dt;

        soc_previous = soc_previous + ...
            battery_energy_change/E_batt;

        soc_schedule(k) = soc_previous;

    end

    P_batt_ref = P_batt_schedule(1)*1000;
    P_grid_ref = P_grid_schedule(1)*1000;

    P_unmet = zeros(N,1);

    power_balance_residual = ...
        Ppv + P_batt_schedule + P_grid_schedule ...
        - Pload - Pev - Pcurtail;

    % Diagnostics.

    mpc_info.control_mode = 'MPC';
    mpc_info.fallback_active = false;
    mpc_info.fallback_reason = '';

    mpc_info.exitflag = exitflag;
    mpc_info.solver_output = output;
    mpc_info.objective_value = objective_value;

    mpc_info.P_batt_schedule_W = P_batt_schedule*1000;
    mpc_info.P_grid_schedule_W = P_grid_schedule*1000;

    mpc_info.P_curtailment_schedule_W = Pcurtail*1000;
    mpc_info.P_unmet_demand_schedule_W = P_unmet*1000;

    mpc_info.P_import_schedule_W = Pimport*1000;
    mpc_info.P_export_schedule_W = Pexport*1000;

    mpc_info.soc_schedule = soc_schedule;
    mpc_info.initial_soc = soc0;

    mpc_info.power_balance_residual_W = ...
        power_balance_residual*1000;

    mpc_info.max_abs_balance_residual_W = ...
        max(abs(power_balance_residual))*1000;

    mpc_info.ems_state = 'MPC OPTIMIZATION SUCCESSFUL';

    mpc_info.horizon_steps = N;
    mpc_info.schedule_steps = N;
    mpc_info.interval_hours = dt;

    mpc_info.terminal_soc_predicted = soc_schedule(end);
    mpc_info.terminal_soc_margin = ...
        soc_schedule(end)-terminal_soc_target;

else

    % -----------------------------------------------------
    % MPC FAILURE: RULE-BASED FALLBACK
    % -----------------------------------------------------

    fallback_reason = sprintf( ...
        'MPC optimization failed. Exit flag: %d.',exitflag);

    if exist('ems_dispatch_rules','file') == 0
        error('MPC:FallbackUnavailable', ...
            'ems_dispatch_rules.m is not on the MATLAB path.');
    end

    [P_batt_requested,~,ems_state] = ems_dispatch_rules( ...
        Ppv(1)*1000, ...
        Pload(1)*1000, ...
        Pev(1)*1000, ...
        soc0*100, ...
        P_batt_max*1000);

    P_net = Pload(1)+Pev(1)-Ppv(1);

    Pdis_fallback = 0;
    Pch_fallback = 0;
    Pimport_fallback = 0;
    Pexport_fallback = 0;
    Pcurtail_fallback = 0;
    P_unmet = 0;

    if P_net > 0

        % DEFICIT: battery discharge before grid import.

        max_discharge_from_soc = ...
            max(0,(soc0-soc_min)*E_batt ...
            *eta_discharge/dt);

        Pdis_fallback = min([ ...
            max(P_batt_requested/1000,0), ...
            P_batt_max, ...
            max_discharge_from_soc, ...
            P_net]);

        remaining_deficit = P_net-Pdis_fallback;

        Pimport_fallback = min( ...
            remaining_deficit,P_grid_import_max);

        P_unmet = max(0, ...
            remaining_deficit-Pimport_fallback);

    elseif P_net < 0

        % SURPLUS: battery charging before grid export.

        P_surplus = -P_net;

        max_charge_from_soc = ...
            max(0,(soc_max-soc0)*E_batt ...
            /(eta_charge*dt));

        Pch_fallback = min([ ...
            max(-P_batt_requested/1000,0), ...
            P_batt_max, ...
            max_charge_from_soc, ...
            P_surplus]);

        remaining_surplus = P_surplus-Pch_fallback;

        Pexport_fallback = min( ...
            remaining_surplus,P_grid_export_max);

        Pcurtail_fallback = max(0, ...
            remaining_surplus-Pexport_fallback);

    end

    P_batt_fallback = Pdis_fallback-Pch_fallback;
    P_grid_fallback = Pimport_fallback-Pexport_fallback;

    P_batt_ref = P_batt_fallback*1000;
    P_grid_ref = P_grid_fallback*1000;

    soc_next = soc0 + ...
        (eta_charge*Pch_fallback ...
        - Pdis_fallback/eta_discharge)*dt/E_batt;

    P_served = Pload(1)+Pev(1)-P_unmet;

    power_balance_residual = ...
        Ppv(1)+P_batt_fallback+P_grid_fallback ...
        -P_served-Pcurtail_fallback;

    % Fallback diagnostics.

    mpc_info.control_mode = 'RULE_BASED_FALLBACK';
    mpc_info.fallback_active = true;
    mpc_info.fallback_reason = fallback_reason;

    mpc_info.exitflag = exitflag;
    mpc_info.solver_output = output;
    mpc_info.objective_value = NaN;

    mpc_info.P_batt_schedule_W = P_batt_ref;
    mpc_info.P_grid_schedule_W = P_grid_ref;

    mpc_info.P_curtailment_schedule_W = ...
        Pcurtail_fallback*1000;

    mpc_info.P_unmet_demand_schedule_W = P_unmet*1000;

    mpc_info.P_import_schedule_W = Pimport_fallback*1000;
    mpc_info.P_export_schedule_W = Pexport_fallback*1000;

    mpc_info.soc_schedule = soc_next;
    mpc_info.initial_soc = soc0;

    mpc_info.power_balance_residual_W = ...
        power_balance_residual*1000;

    mpc_info.max_abs_balance_residual_W = ...
        abs(power_balance_residual)*1000;

    mpc_info.ems_state = ems_state;

    mpc_info.horizon_steps = N;
    mpc_info.schedule_steps = 1;
    mpc_info.interval_hours = dt;

    % Fallback only calculates the first interval.
    % It does not optimize the full horizon against the
    % terminal SOC target.

    mpc_info.terminal_soc_predicted = NaN;
    mpc_info.terminal_soc_margin = NaN;

end

%% 12. Common diagnostics

mpc_info.P_batt_ref_W = P_batt_ref;
mpc_info.P_grid_ref_W = P_grid_ref;

mpc_info.soc_min = soc_min;
mpc_info.soc_max = soc_max;

mpc_info.battery_power_limit_kW = P_batt_max;
mpc_info.grid_import_limit_kW = P_grid_import_max;
mpc_info.grid_export_limit_kW = P_grid_export_max;

mpc_info.allow_battery_export = allow_battery_export;
mpc_info.terminal_soc_target = terminal_soc_target;

end

%% Local helper: parameter reader

function value = get_param(params,field,default_value)

if isfield(params,field) && ~isempty(params.(field))
    value = params.(field);
else
    value = default_value;
end

end

%% Local helper: tariff profile expansion

function profile = expand_profile(value,N)

if isscalar(value)

    profile = repmat(value,N,1);

elseif isvector(value) && numel(value) == N

    profile = value(:);

else

    error('MPC:InvalidTariffSize', ...
        'Each tariff must be scalar or contain N forecast samples.');

end

if ~isreal(profile) || any(~isfinite(profile))
    error('MPC:InvalidTariff', ...
        'Tariffs must be finite real values.');
end

end
