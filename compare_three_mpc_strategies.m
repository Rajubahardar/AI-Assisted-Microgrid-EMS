
%% THREE-STRATEGY MPC COMPARISON
% 1. Perfect-forecast MPC
% 2. Persistence-forecast MPC
% 3. ML-forecast MPC
%
% Uses existing forecasts and actual test data.
% Does not retrain forecasting models.

clearvars -except P mlMPC commonDays pvActual_kW ...
    buildingActual_kW evActual_kW pvForecast_kW ...
    buildingForecast_kW evForecast_kW

clc;

%% 1. CONFIGURATION

dt = 0.25;                  % hours
H = 24;                     % 6-hour prediction horizon

E_batt_kWh = 200;
eta_charge = 0.95;
eta_discharge = 0.95;

SOC_initial = 0.60;
SOC_min = 0.20;
SOC_max = 0.90;

tariff_import = 0.20;       % currency/kWh
tariff_export = 0.05;       % currency/kWh

%% 2. VALIDATE INPUT ARRAYS

assert(isequal(size(pvActual_kW),[25 96]));
assert(isequal(size(buildingActual_kW),[25 96]));
assert(isequal(size(evActual_kW),[25 96]));

assert(isequal(size(mlMPC.pvForecast_kW),[25 96]));
assert(isequal(size(mlMPC.buildingForecast_kW),[25 96]));
assert(isequal(size(mlMPC.evForecast_kW),[25 96]));

% Convert daily matrices into chronological column vectors.
% All values are in kW here.

pvActual = reshape(pvActual_kW.',[],1);
buildingActual = reshape(buildingActual_kW.',[],1);
evActual = reshape(evActual_kW.',[],1);

pvML = reshape(mlMPC.pvForecast_kW.',[],1);
buildingML = reshape(mlMPC.buildingForecast_kW.',[],1);
evML = reshape(mlMPC.evForecast_kW.',[],1);

N = numel(pvActual);

assert(N == 2400);

%% 3. IDENTIFY CONTIGUOUS TEST BLOCKS

% Do not allow the MPC horizon to cross the missing days
% between day 334 and day 351.

breaks = find(diff(commonDays) > 1);

blockStarts = [1; breaks + 1];
blockEnds = [breaks; numel(commonDays)];

fprintf('\n========== TEST CONFIGURATION ==========\n');
fprintf('Test days: %d\n',numel(commonDays));
fprintf('Total intervals: %d\n',N);
fprintf('Horizon: %d intervals\n',H);
fprintf('Initial SOC: %.2f\n',SOC_initial);

%% 4. RUN ALL THREE STRATEGIES

fprintf('\nRunning perfect-forecast MPC...\n');

perfect = run_comparison_case( ...
    'Perfect',pvActual,buildingActual,evActual, ...
    pvActual,buildingActual,evActual, ...
    blockStarts,blockEnds,H,dt,E_batt_kWh, ...
    eta_charge,eta_discharge,SOC_initial,SOC_min,SOC_max);

fprintf('\nRunning persistence-forecast MPC...\n');

persistence = run_comparison_case( ...
    'Persistence',pvActual,buildingActual,evActual, ...
    pvActual,buildingActual,evActual, ...
    blockStarts,blockEnds,H,dt,E_batt_kWh, ...
    eta_charge,eta_discharge,SOC_initial,SOC_min,SOC_max, ...
    'persistence');

fprintf('\nRunning ML-forecast MPC...\n');

ml = run_comparison_case( ...
    'ML',pvActual,buildingActual,evActual, ...
    pvML,buildingML,evML, ...
    blockStarts,blockEnds,H,dt,E_batt_kWh, ...
    eta_charge,eta_discharge,SOC_initial,SOC_min,SOC_max);

%% 5. CALCULATE COMPARISON METRICS

caseResults = {perfect,persistence,ml};
caseNames = {'Perfect';'Persistence';'ML'};

GridImport_kWh = zeros(3,1);
GridExport_kWh = zeros(3,1);
GridCost = zeros(3,1);
PeakGridImport_kW = zeros(3,1);
BatteryThroughput_kWh = zeros(3,1);
SOC_Minimum = zeros(3,1);
SOC_Maximum = zeros(3,1);
MeanSolveTime_s = zeros(3,1);
MaximumSolveTime_s = zeros(3,1);
FallbackCalls = zeros(3,1);
MaximumPredictedBalanceResidual_W = zeros(3,1);
MaximumActualBalanceMismatch_kW = zeros(3,1);

for c = 1:3

    R = caseResults{c};

    GridImport_kWh(c) = ...
        sum(max(R.gridActual_kW,0))*dt;

    GridExport_kWh(c) = ...
        sum(max(-R.gridActual_kW,0))*dt;

    GridCost(c) = ...
        GridImport_kWh(c)*tariff_import ...
        - GridExport_kWh(c)*tariff_export;

    PeakGridImport_kW(c) = max(R.gridActual_kW);

    BatteryThroughput_kWh(c) = ...
        sum(abs(R.battery_kW))*dt;

    SOC_Minimum(c) = min(R.SOC);
    SOC_Maximum(c) = max(R.SOC);

    MeanSolveTime_s(c) = mean(R.solveTime_s);
    MaximumSolveTime_s(c) = max(R.solveTime_s);

    FallbackCalls(c) = sum(R.fallback);

    MaximumPredictedBalanceResidual_W(c) = ...
        max(R.predictedBalanceResidual_W);

    MaximumActualBalanceMismatch_kW(c) = ...
        max(abs(R.actualBalanceMismatch_kW));

end

Comparison = table( ...
    caseNames, ...
    GridImport_kWh, ...
    GridExport_kWh, ...
    GridCost, ...
    PeakGridImport_kW, ...
    BatteryThroughput_kWh, ...
    SOC_Minimum, ...
    SOC_Maximum, ...
    MeanSolveTime_s, ...
    MaximumSolveTime_s, ...
    FallbackCalls, ...
    MaximumPredictedBalanceResidual_W, ...
    MaximumActualBalanceMismatch_kW, ...
    'VariableNames',{ ...
    'Strategy', ...
    'GridImport_kWh', ...
    'GridExport_kWh', ...
    'GridCost', ...
    'PeakGridImport_kW', ...
    'BatteryThroughput_kWh', ...
    'SOC_Minimum', ...
    'SOC_Maximum', ...
    'MeanSolveTime_s', ...
    'MaximumSolveTime_s', ...
    'FallbackCalls', ...
    'MaxPredictedBalanceResidual_W', ...
    'MaxActualBalanceMismatch_kW'});

%% 6. DISPLAY RESULTS

fprintf('\n========== THREE-STRATEGY MPC COMPARISON ==========\n');
disp(Comparison);

%% 7. SAVE RESULTS

MPC_Comparison = struct();

MPC_Comparison.Perfect = perfect;
MPC_Comparison.Persistence = persistence;
MPC_Comparison.ML = ml;

MPC_Comparison.ComparisonTable = Comparison;
MPC_Comparison.commonDays = commonDays;
MPC_Comparison.horizonSteps = H;
MPC_Comparison.dt_hours = dt;
MPC_Comparison.initialSOC = SOC_initial;
MPC_Comparison.tariff_import = tariff_import;
MPC_Comparison.tariff_export = tariff_export;

save('three_strategy_mpc_comparison.mat','MPC_Comparison');

writetable(Comparison,'three_strategy_mpc_comparison.csv');

fprintf('\nComparison results saved.\n');
fprintf('MAT: three_strategy_mpc_comparison.mat\n');
fprintf('CSV: three_strategy_mpc_comparison.csv\n');

%% =========================================================
% LOCAL FUNCTION
%% =========================================================

function R = run_comparison_case( ...
    caseName,pvActual,buildingActual,evActual, ...
    pvForecast,buildingForecast,evForecast, ...
    blockStarts,blockEnds,H,dt,Ebatt, ...
    etaCh,etaDis,SOC0,SOCmin,SOCmax,varargin)

N = numel(pvActual);

R.battery_kW = zeros(N,1);
R.gridPlanned_kW = zeros(N,1);
R.gridActual_kW = zeros(N,1);

R.SOC = zeros(N+1,1);
R.SOC(1) = SOC0;

R.solveTime_s = zeros(N,1);
R.fallback = false(N,1);
R.predictedBalanceResidual_W = zeros(N,1);
R.actualBalanceMismatch_kW = zeros(N,1);

persistenceMode = ~isempty(varargin) && ...
    strcmpi(varargin{1},'persistence');

intervalCounter = 0;

for b = 1:numel(blockStarts)

    first = (blockStarts(b)-1)*96 + 1;
    last = blockEnds(b)*96;

    fprintf('%s MPC: block %d, intervals %d to %d\n', ...
        caseName,b,first,last);

    for k = first:last

        hEnd = min(k+H-1,last);
        idx = k:hEnd;

        if persistenceMode

            pvH = repmat(pvActual(k),numel(idx),1);
            buildingH = repmat(buildingActual(k),numel(idx),1);
            evH = repmat(evActual(k),numel(idx),1);

        else

            pvH = pvForecast(idx);
            buildingH = buildingForecast(idx);
            evH = evForecast(idx);

        end

        % Convert kW to W for mpc_dispatch.
        tic;

        [Pbatt_W,Pgrid_W,info] = mpc_dispatch( ...
            pvH(:)*1000, ...
            buildingH(:)*1000, ...
            evH(:)*1000, ...
            R.SOC(intervalCounter+1));

        elapsed = toc;

        intervalCounter = intervalCounter+1;

        Pbatt_kW = Pbatt_W/1000;
        Pgrid_kW = Pgrid_W/1000;

        R.battery_kW(intervalCounter) = Pbatt_kW;
        R.gridPlanned_kW(intervalCounter) = Pgrid_kW;
        R.solveTime_s(intervalCounter) = elapsed;

        % Update battery SOC using the applied first action.
        if Pbatt_kW >= 0
            % Positive power means battery discharge.
            nextSOC = R.SOC(intervalCounter) ...
                - (Pbatt_kW*dt)/(Ebatt*etaDis);
        else
            % Negative power means battery charging.
            nextSOC = R.SOC(intervalCounter) ...
                + ((-Pbatt_kW)*dt*etaCh)/Ebatt;
        end

        tolerance = 1e-7;

        if nextSOC < SOCmin-tolerance || nextSOC > SOCmax+tolerance
            error('%s MPC violated SOC limits at interval %d.', ...
                caseName,intervalCounter);
        end

        nextSOC = min(max(nextSOC,SOCmin),SOCmax);
        R.SOC(intervalCounter+1) = nextSOC;

        % Record solver diagnostics.
        R.fallback(intervalCounter) = info.fallback_active;

        R.predictedBalanceResidual_W(intervalCounter) = ...
            info.max_abs_balance_residual_W;

        % Actual grid power required to balance realized demand,
        % assuming no PV curtailment.
        R.gridActual_kW(intervalCounter) = ...
            buildingActual(k) + evActual(k) ...
            - pvActual(k) - Pbatt_kW;

        % Difference between planned grid reference and actual
        % grid power required after forecast errors.
        R.actualBalanceMismatch_kW(intervalCounter) = ...
            R.gridActual_kW(intervalCounter)-Pgrid_kW;

    end
end

R.SOC = R.SOC(1:N+1);
R.caseName = caseName;

fprintf('%s MPC completed. Fallback calls: %d\n', ...
    caseName,sum(R.fallback));

end
