function microgrid_dashboard_pro()
% MICROGRID_DASHBOARD_PRO  (v2.3)
% Professional results viewer for the AI-Assisted Microgrid EMS project.
% Displays stored project results only. It does not run Simulink or show live data.
%
% Features
%   - Light (default) / dark theme, collapsible sidebar, reduced-motion toggle
%   - Interactive Microgrid Architecture: clickable components with full technical
%     specifications, animated directional energy flows, and scenario selector
%   - Forecasting: 3 chart views, per-day vs all-day metrics, explicit test-period
%     notice, and clickable model leaderboard
%   - Energy Management: animated MPC pipeline (Forecast -> MPC -> Dispatch ->
%     System), explicit constraints (+/-100 kW battery, 20-90% SOC, +/-150 kW grid,
%     15-min interval), and direction-aware strategy ranking
%   - Monitoring: peak marker, energy, load factor, net-load profile (generated data)
%   - Experiment analysis: live filter, sortable columns, normalized multi-metric
%     strategy comparison chart, CSV export
%   - Presentation mode (3 minutes): 60-second animated, narrated introduction
%     followed by a 2-minute tour of all six screens
%
% Keyboard: Space play/pause | 1-6 screens | PgUp/PgDn previous/next
%           I replay intro | V voice-over | M motion/animations on/off
%           Left/Right forecast day | T theme | B sidebar
% Requires MATLAB R2021a or newer.

%% ================================================================
%  PATHS
%  ================================================================
dashboardFolder = fileparts(mfilename('fullpath'));
rootFolder      = fileparts(dashboardFolder);

dataFolder   = fullfile(rootFolder,'04_Data','generated');
forecastRoot = fullfile(rootFolder,'05_Forecasting');

pvFile   = fullfile(forecastRoot,'day_ahead','solar','results', ...
    'pv_seasonal_lstm_experiment.mat');
bldFile  = fullfile(forecastRoot,'day_ahead','building','results', ...
    'building_forecasting_experiment.mat');
evFile   = fullfile(forecastRoot,'day_ahead','ev','results', ...
    'ev_forecasting_experiment.mat');
profFile = fullfile(dataFolder,'microgrid_profiles_24h.mat');
mpcFile  = fullfile(rootFolder,'three_strategy_mpc_comparison.csv');

sources = {'PV forecast (LSTM)',pvFile; 'Building forecast',bldFile; ...
    'EV forecast',evFile; 'Generated profiles',profFile; ...
    'MPC comparison',mpcFile};

%% ================================================================
%  CONSTANTS & TECHNICAL SYSTEM SPECIFICATIONS
%  ================================================================
screenNames = {'System Overview','Forecasting','Energy Management', ...
    'System Monitoring','Experiment Analysis','About'};
screenSubtitles = { ...
    'Design specifications, interactive architecture, daily insights and data health', ...
    'Compare actual and predicted power, and rank the prediction models', ...
    'MPC optimization flow, operating constraints and strategy comparison', ...
    'Inspect historical generated 24-hour profiles', ...
    'Search, sort, compare and export the full MPC experiment table', ...
    'Project information, shortcuts and data limitations'};

% Icons are built from char codes so the file stays pure ASCII.
navIcons   = {char(8962),char(8767),char(8623),char(9684),char(9638),char(9432)};
icoMenu    = char(9776);   icoTheme = char(9680);   icoReload = char(8635);
icoPrev    = char(8249);   icoNext  = char(8250);
R2name     = ['R' char(178)];
icoPlay    = char(9654);   icoPause = char(8214);   icoOK = char(10003);
icoArrowR  = char(8594);   icoArrowLR = char(8596); icoPM = char(177);
icoDash    = char(8211);   icoMotion = char(8766);

% Project design parameters (never represented as live measurements)
SYS = struct( ...
    'pv_kWp',   '100 kWp', ...
    'pv_mppt',  'Perturb and Observe (P&O)', ...
    'bat_kWh',  '200 kWh', ...
    'bat_V',    '500 V nominal', ...
    'bat_soc',  ['20' icoDash '90 %'], ...
    'bat_kW',   [icoPM '100 kW'], ...
    'ev_desc',  '5 x 11 kW (55 kW)', ...
    'bld_kW',   '80 kW peak', ...
    'dc_bus',   '750 V (provisional)', ...
    'grid_v',   '415 V L-L, 50 Hz', ...
    'grid_kva', '150 kVA', ...
    'grid_kW',  [icoPM '150 kW'], ...
    'ems_dt',   '15 minutes');

% Presentation mode (set autoPlay = false to start paused,
% voiceOver = false for captions only, reduceMotion = true for static flows)
presIntro    = 60000;                          % ms, animated introduction
presSection  = 20000;                          % ms per dashboard screen
presTotal    = presIntro + 6*presSection;      % 3 minutes
autoPlay     = true;
voiceOver    = true;
reduceMotion = false;

introTimes  = [0 10 22 32 43 53 60]*1000;
introTitles = {'The problem','The microgrid','Electrical architecture', ...
    'AI forecasting','Predictive energy management','Project outcome'};
introCaps = { ...
    'Modern electricity systems face changing solar generation, building demand and electric-vehicle charging. Managing these sources efficiently requires coordinated energy management.', ...
    'This project develops a grid-connected microgrid combining a 100-kilowatt-peak PV system with Perturb-and-Observe MPPT, a 200-kilowatt-hour 500-volt battery rated at 100 kilowatts, five 11-kilowatt EV chargers and an 80-kilowatt peak building load.', ...
    'The system connects these components through power-conversion interfaces and a 750-volt DC bus, with a 415-volt, 50-hertz, 150-kVA utility grid interface providing bidirectional power exchange.', ...
    'Machine-learning and time-series forecasting models estimate photovoltaic generation, building demand and EV charging demand. Their predictions provide information for future energy scheduling.', ...
    'A model predictive control framework compares forecast-based operating strategies at a 15-minute supervisory interval while enforcing battery SOC, 100-kilowatt battery power and 150-kilowatt grid limits.', ...
    'Finally, MATLAB and Simulink results are organized into an interactive dashboard for forecasting, energy management, monitoring and experiment analysis.'};
introNotes = { ...
    'Illustrative daily profiles - not measured data', ...
    'Reference-system design parameters', ...
    'Provisional 750 V DC-bus design value  |  conceptual power flows, not a live schematic', ...
    'Models trained and evaluated on chronological test data  |  illustrative curves', ...
    'Strategies compared against baselines under explicit constraints: Perfect Forecast, Persistence, ML forecast', ...
    'Monitoring uses historical generated profiles - not live measurements'};

forecastCategories = {'PV Forecasting','Building Forecasting','EV Forecasting'};
buildingModels = {'PreviousDayPersistence','ThreeDayMovingAverage', ...
    'RandomForest','LSBoost','SVR','LSTM'};
evModels = {'Persistence','MovingAverage3','RandomForest','LSBoost','SVR','LSTM'};
signalNames = {'PV Power','Building Load','EV Load','Net Load (Bldg+EV-PV)'};
viewNames   = {'Time series','Residual error','Actual vs predicted'};
scenarioNames = {'Generated Profile (Noon)', ...
    'Sunny (Illustrative)', ...
    'Cloudy (Illustrative)', ...
    'High Demand (Illustrative)'};

%% ================================================================
%  STATE (declared here so nested functions share it)
%  ================================================================
S = struct('mode','light','screen',1,'collapsed',false, ...
    'category','PV Forecasting','model','LSTM','day',1, ...
    'view','Time series','signal','PV Power', ...
    'metric','','direction','Lower is better','filter','', ...
    'scenario','Generated Profile (Noon)','selectedComp','PV');

C = makeTheme(S.mode);

fig = [];  root = [];  main = [];  content = [];
pages = gobjects(1,6);  navButtons = gobjects(1,6);
brandTitle = [];  brandSub = [];  menuLabel = [];
healthLabel = [];  versionLabel = [];
titleLabel = [];  subtitleLabel = [];  statusLabel = [];
isRebuilding = false;

% Overview & Interactive Architecture
overviewAxes = [];  healthTable = [];
insPV = [];  insLoad = [];  insCov = [];  insPeak = [];
archAxes = [];  archScenarioDrop = [];  archScenarioNote = [];
archSpecTitle = [];  archSpecBody = [];  archSpecBadge = [];
archNodes = struct();  archFlows = {};  archPhase = 0;

% Forecasting
categoryDrop = [];  modelDrop = [];  dayDrop = [];  viewDrop = [];
forecastAxes = [];  lbTable = [];  fcPeriodNote = [];
fcMAE = [];  fcRMSE = [];  fcR2 = [];  fcMax = [];
lbNames = {};

% Energy Management & MPC Animation
metricDrop = [];  directionDrop = [];  mpcAxes = [];  mpcTableUI = [];
enBest = [];  enValue = [];  enGap = [];  enCount = [];
mpcAnimAxes = [];  mpcAnimDots = {};  mpcPhase = 0;

% Monitoring
signalDrop = [];  monitoringAxes = [];  sourceLabel = [];
moPeak = [];  moMean = [];  moEnergy = [];  moLF = [];

% Experiment Analysis
experimentTableUI = [];  filterField = [];  countLabel = [];
expChartAxes = [];  shownTable = table();

% Data
mpcTable = table();
forecastCache = containers.Map('KeyType','char','ValueType','any');
profileCache = [];

% Timers & Presentation state
presTimer = [];  animTimer = [];
presPlaying = false;  presElapsed = 0;  presBase = 0;  presT0 = [];
presLastSec = -1;
playBtn = [];  motionBtn = [];  timerLabel = [];  progressGrid = [];  sideNote = [];

% Introduction scene state
introPanel = [];  introAxes = [];  introHead = [];  introCaption = [];
voiceBtn = [];  introScene = 0;  sceneObjs = {};  alwaysObjs = {};  IH = struct();
speaker = [];

loadMpc();

%% ================================================================
%  MAIN WINDOW
%  ================================================================
fig = uifigure('Name','AI-Assisted Microgrid EMS Command Center', ...
    'Position',[50 35 1400 880],'Color',C.bg);
fig.CloseRequestFcn   = @closeDashboard;
fig.WindowKeyPressFcn = @onKey;

buildUI();
showIntro();

presTimer = timer('ExecutionMode','fixedRate','Period',0.1, ...
    'BusyMode','drop','TimerFcn',@(~,~) presTick());
animTimer = timer('ExecutionMode','fixedRate','Period',0.08, ...
    'BusyMode','drop','TimerFcn',@(~,~) animTick());
start(animTimer);

presUpdateUI();
if autoPlay, playPresentation(); end

%% ================================================================
%  THEME
%  ================================================================
    function T = makeTheme(mode)
        T.accent = [0.00 0.60 0.56];
        T.blue   = [0.16 0.42 0.82];
        T.amber  = [0.92 0.60 0.12];
        T.green  = [0.16 0.66 0.38];
        T.orange = [0.90 0.44 0.18];
        T.purple = [0.50 0.35 0.80];
        T.danger = [0.82 0.24 0.24];
        if strcmp(mode,'dark')
            T.bg        = [0.065 0.085 0.125];
            T.card      = [0.105 0.135 0.190];
            T.sidebar   = [0.045 0.060 0.090];
            T.navActive = [0.120 0.170 0.250];
            T.navText   = [0.62 0.68 0.77];
            T.text      = [0.92 0.94 0.97];
            T.muted     = [0.58 0.64 0.73];
            T.grid      = [0.35 0.40 0.50];
            T.input     = [0.150 0.185 0.250];
        else
            T.bg        = [0.957 0.965 0.978];
            T.card      = [1 1 1];
            T.sidebar   = [0.075 0.115 0.190];
            T.navActive = [0.145 0.220 0.340];
            T.navText   = [0.74 0.79 0.87];
            T.text      = [0.10 0.14 0.21];
            T.muted     = [0.42 0.47 0.55];
            T.grid      = [0.80 0.83 0.88];
            T.input     = [0.94 0.955 0.975];
        end
        T.palette = [T.blue; T.accent; T.amber; T.orange; T.green; T.purple];
    end

    function c = mixc(a,b,w)
        c = a*(1-w) + b*w;
    end

    function toggleTheme()
        if strcmp(S.mode,'light'), S.mode = 'dark'; else, S.mode = 'light'; end
        C = makeTheme(S.mode);
        rebuildUI();
        setStatus(['Switched to ' S.mode ' theme']);
    end

    function toggleMotion()
        reduceMotion = ~reduceMotion;
        updateMotionButton();
        if reduceMotion
            setStatus('Reduced motion enabled (animations paused)');
        else
            setStatus('Animations enabled');
        end
    end

    function updateMotionButton()
        if ~isempty(motionBtn) && isvalid(motionBtn)
            if reduceMotion
                motionBtn.BackgroundColor = C.input;
                motionBtn.FontColor = C.muted;
                motionBtn.Tooltip = 'Animations paused (M to enable)';
            else
                motionBtn.BackgroundColor = mixc(C.input,C.accent,0.18);
                motionBtn.FontColor = C.accent;
                motionBtn.Tooltip = 'Animations active (M for reduced motion)';
            end
        end
    end

    function reloadAll()
        forecastCache = containers.Map('KeyType','char','ValueType','any');
        profileCache = [];
        loadMpc();
        rebuildUI();
        setStatus('Data reloaded from disk');
    end

    function rebuildUI()
        isRebuilding = true;
        try
            if ~isempty(root) && isvalid(root), delete(root); end
            buildUI();
            introScene = 0;
            if S.screen == 0
                showIntro();
            else
                showScreen(S.screen);
            end
            presUpdateUI();
        catch ME
            isRebuilding = false;
            rethrow(ME);
        end
        isRebuilding = false;
    end

%% ================================================================
%  UI SHELL
%  ================================================================
    function buildUI()
        fig.Color = C.bg;

        root = uigridlayout(fig,[1 2]);
        root.ColumnWidth     = {sidebarWidth(),'1x'};
        root.Padding         = [0 0 0 0];
        root.ColumnSpacing   = 0;
        root.BackgroundColor = C.bg;

        buildSidebar();

        main = uigridlayout(root,[4 1]);
        main.Layout.Column   = 2;
        main.RowHeight       = {5,58,'1x',22};
        main.Padding         = [24 8 24 6];
        main.RowSpacing      = 10;
        main.BackgroundColor = C.bg;

        % Presentation progress bar
        progressGrid = uigridlayout(main,[1 2]);
        progressGrid.ColumnWidth   = {'0.0001x','100x'};
        progressGrid.Padding       = [0 0 0 0];
        progressGrid.ColumnSpacing = 0;
        progressGrid.BackgroundColor = C.bg;
        uipanel(progressGrid,'BackgroundColor',C.accent,'BorderType','none');
        uipanel(progressGrid,'BackgroundColor',mixc(C.bg,C.grid,0.6),'BorderType','none');

        buildHeader();

        content = uigridlayout(main,[1 1]);
        content.Padding = [0 0 0 0];
        content.BackgroundColor = C.bg;
        for k = 1:numel(screenNames)
            pages(k) = uipanel(content,'BorderType','none', ...
                'BackgroundColor',C.bg,'Visible','off');
            pages(k).Layout.Row = 1;  pages(k).Layout.Column = 1;
        end

        statusLabel = uilabel(main,'Text','','FontSize',11,'FontColor',C.muted);

        buildIntro();
        buildOverview();
        buildForecasting();
        buildEnergyManagement();
        buildMonitoring();
        buildExperiment();
        buildAbout();
        applySidebar();
    end

    function w = sidebarWidth()
        if S.collapsed, w = 68; else, w = 232; end
    end

    function buildSidebar()
        sidebar = uipanel(root,'BorderType','none','BackgroundColor',C.sidebar);
        sg = uigridlayout(sidebar,[11 1]);
        sg.RowHeight       = {54,24,44,44,44,44,44,44,'1x',20,20};
        sg.Padding         = [10 20 10 12];
        sg.RowSpacing      = 6;
        sg.BackgroundColor = C.sidebar;

        brand = uigridlayout(sg,[2 1]);
        brand.Padding = [6 0 0 0];  brand.RowSpacing = 0;
        brand.BackgroundColor = C.sidebar;
        brandTitle = uilabel(brand,'Text','Microgrid EMS','FontSize',20, ...
            'FontWeight','bold','FontColor',[1 1 1]);
        brandSub = uilabel(brand,'Text','AI-assisted predictive control', ...
            'FontSize',11,'FontColor',C.navText);

        menuLabel = uilabel(sg,'Text','   MENU','FontSize',10, ...
            'FontWeight','bold','FontColor',C.muted);

        for k = 1:numel(screenNames)
            b = uibutton(sg,'push','Text',screenNames{k}, ...
                'FontSize',14,'BackgroundColor',C.sidebar, ...
                'FontColor',C.navText,'Tooltip', ...
                sprintf('%s  (key %d)',screenNames{k},k));
            b.Layout.Row = k + 2;
            b.ButtonPushedFcn = @(~,~) navigateTo(k);
            navButtons(k) = b;
        end

        sideNote = uilabel(sg,'Text',{'PV - BATTERY - EV - GRID', ...
            '15-minute EMS scheduling','', ...
            'Stored MATLAB/Simulink results only; not live telemetry.'}, ...
            'FontSize',10,'FontColor',C.muted,'WordWrap','on', ...
            'VerticalAlignment','bottom');
        sideNote.Layout.Row = 9;

        ok = cellfun(@isfile,sources(:,2));
        healthLabel = uilabel(sg,'Text',sprintf('Data sources: %d / %d', ...
            sum(ok),numel(ok)),'FontSize',11,'FontWeight','bold');
        healthLabel.Layout.Row = 10;
        if all(ok), healthLabel.FontColor = C.green; else, healthLabel.FontColor = C.amber; end

        versionLabel = uilabel(sg,'Text','v2.3  |  offline viewer', ...
            'FontSize',10,'FontColor',C.muted);
        versionLabel.Layout.Row = 11;
    end

    function applySidebar()
        root.ColumnWidth = {sidebarWidth(),'1x'};
        collapsed = S.collapsed;
        brandSub.Visible     = ~collapsed;
        menuLabel.Visible    = ~collapsed;
        versionLabel.Visible = ~collapsed;
        sideNote.Visible     = ~collapsed;
        if collapsed
            brandTitle.Text = 'EMS';  brandTitle.FontSize = 15;
            healthLabel.Text = sprintf('%d/%d',sum(cellfun(@isfile,sources(:,2))), ...
                size(sources,1));
        else
            brandTitle.Text = 'Microgrid EMS';  brandTitle.FontSize = 20;
            healthLabel.Text = sprintf('Data sources: %d / %d', ...
                sum(cellfun(@isfile,sources(:,2))),size(sources,1));
        end
        for k = 1:numel(navButtons)
            if collapsed
                navButtons(k).Text = navIcons{k};
                navButtons(k).HorizontalAlignment = 'center';
                navButtons(k).FontSize = 18;
            else
                navButtons(k).Text = ['  ' navIcons{k} '   ' screenNames{k}];
                navButtons(k).HorizontalAlignment = 'left';
                navButtons(k).FontSize = 14;
            end
        end
    end

    function toggleSidebar()
        S.collapsed = ~S.collapsed;
        applySidebar();
    end

    function buildHeader()
        header = uigridlayout(main,[2 3]);
        header.RowHeight       = {'fit','fit'};
        header.ColumnWidth     = {44,'1x',414};
        header.Padding         = [0 0 0 0];
        header.RowSpacing      = 2;
        header.ColumnSpacing   = 10;
        header.BackgroundColor = C.bg;

        left = uigridlayout(header,[3 1]);
        left.Layout.Row = [1 2];  left.Layout.Column = 1;
        left.RowHeight = {'1x',34,'1x'};  left.Padding = [0 0 0 0];
        left.BackgroundColor = C.bg;
        mb = makeButton(left,icoMenu,'secondary','Toggle sidebar (B)');
        mb.Layout.Row = 2;
        mb.ButtonPushedFcn = @(~,~) toggleSidebar();

        titleLabel = uilabel(header,'Text','','FontSize',24, ...
            'FontWeight','bold','FontColor',C.text);
        titleLabel.Layout.Row = 1;  titleLabel.Layout.Column = 2;
        subtitleLabel = uilabel(header,'Text','','FontSize',12, ...
            'FontColor',C.muted);
        subtitleLabel.Layout.Row = 2;  subtitleLabel.Layout.Column = 2;

        right = uigridlayout(header,[3 7]);
        right.Layout.Row = [1 2];  right.Layout.Column = 3;
        right.RowHeight = {'1x',34,'1x'};
        right.ColumnWidth = {80,36,90,36,36,36,56};
        right.Padding = [0 0 0 0];  right.ColumnSpacing = 6;
        right.BackgroundColor = C.bg;

        playBtn = makeButton(right,[icoPlay ' Play'],'primary', ...
            'Play / pause the presentation tour (Space)');
        playBtn.Layout.Row = 2;  playBtn.Layout.Column = 1;
        playBtn.ButtonPushedFcn = @(~,~) togglePresentation();

        rsb = makeButton(right,icoReload,'secondary','Restart the presentation tour');
        rsb.Layout.Row = 2;  rsb.Layout.Column = 2;
        rsb.ButtonPushedFcn = @(~,~) restartPresentation();

        timerLabel = uilabel(right,'Text','00:00 / 03:00','FontSize',12, ...
            'FontColor',C.muted,'HorizontalAlignment','center');
        timerLabel.Layout.Row = 2;  timerLabel.Layout.Column = 3;

        motionBtn = makeButton(right,icoMotion,'secondary','Toggle reduced motion (M)');
        motionBtn.Layout.Row = 2;  motionBtn.Layout.Column = 4;
        motionBtn.ButtonPushedFcn = @(~,~) toggleMotion();
        updateMotionButton();

        tb = makeButton(right,icoTheme,'secondary','Toggle light / dark theme (T)');
        tb.Layout.Row = 2;  tb.Layout.Column = 5;
        tb.ButtonPushedFcn = @(~,~) toggleTheme();

        rb = makeButton(right,icoReload,'secondary','Reload data from disk');
        rb.Layout.Row = 2;  rb.Layout.Column = 6;
        rb.ButtonPushedFcn = @(~,~) reloadAll();

        eb = makeButton(right,'Exit','secondary','Close the dashboard');
        eb.Layout.Row = 2;  eb.Layout.Column = 7;
        eb.ButtonPushedFcn = @(~,~) closeDashboard();
    end

    function showScreen(index)
        if ~isempty(introPanel) && isvalid(introPanel)
            introPanel.Visible = 'off';
        end
        stopNarration();
        S.screen = index;
        for k = 1:numel(pages)
            active = (k == index);
            pages(k).Visible = active;
            if active
                navButtons(k).BackgroundColor = C.navActive;
                navButtons(k).FontColor  = [1 1 1];
                navButtons(k).FontWeight = 'bold';
            else
                navButtons(k).BackgroundColor = C.sidebar;
                navButtons(k).FontColor  = C.navText;
                navButtons(k).FontWeight = 'normal';
            end
        end
        titleLabel.Text    = screenNames{index};
        subtitleLabel.Text = screenSubtitles{index};
        setStatus(['Viewing ' screenNames{index}]);
    end

    function setStatus(msg)
        if isempty(statusLabel) || ~isvalid(statusLabel), return; end
        stamp = char(datetime('now','Format','HH:mm:ss'));
        if presPlaying, mode = 'Presentation playing'; else, mode = 'Presentation paused'; end
        statusLabel.Text = sprintf('%s   |   %s   |   %s   |   Stored project results - no live data', ...
            stamp,msg,mode);
    end

    function onKey(~,evt)
        try
            if isa(fig.CurrentObject,'matlab.ui.control.EditField'), return; end
        catch
        end
        if ~isempty(evt.Modifier), return; end
        switch evt.Key
            case {'1','2','3','4','5','6'}
                navigateTo(str2double(evt.Key));
            case 'space'
                togglePresentation();
            case 'pagedown'
                navigateTo(min(S.screen+1,numel(screenNames)));
            case 'pageup'
                if S.screen <= 1
                    navigateToIntro();
                else
                    navigateTo(S.screen-1);
                end
            case 'i'
                navigateToIntro();
            case 'v'
                toggleVoice();
            case 'm'
                toggleMotion();
            case 'leftarrow'
                if S.screen == 2, stepDay(-1); end
            case 'rightarrow'
                if S.screen == 2, stepDay(+1); end
            case 't'
                toggleTheme();
            case 'b'
                toggleSidebar();
        end
    end

%% ================================================================
%  PRESENTATION & ANIMATION ENGINES
%  ================================================================
    function togglePresentation()
        if presPlaying, pausePresentation(); else, playPresentation(); end
    end

    function playPresentation()
        if presPlaying, return; end
        if isempty(presTimer) || ~isvalid(presTimer), return; end
        if presElapsed >= presTotal
            restartPresentation();
            return;
        end
        presBase = presElapsed;
        presT0 = tic;
        presPlaying = true;
        if strcmp(presTimer.Running,'off'), start(presTimer); end
        if S.screen == 0, speakScene(introScene); end
        presUpdateUI();
        setStatus('Presentation started');
    end

    function pausePresentation()
        if ~presPlaying, return; end
        presElapsed = min(presBase + toc(presT0)*1000,presTotal);
        presPlaying = false;
        if ~isempty(presTimer) && isvalid(presTimer) && strcmp(presTimer.Running,'on')
            stop(presTimer);
        end
        stopNarration();
        presUpdateUI();
        setStatus('Presentation paused');
    end

    function restartPresentation()
        presPlaying = false;
        if ~isempty(presTimer) && isvalid(presTimer) && strcmp(presTimer.Running,'on'), stop(presTimer); end
        stopNarration();
        presElapsed = 0;
        introScene = 0;
        showIntro();
        playPresentation();
    end

    function navigateTo(k)
        % Manual navigation pauses the tour and re-syncs the timeline.
        pausePresentation();
        presElapsed = presIntro + (k-1)*presSection;
        showScreen(k);
        presUpdateUI();
    end

    function navigateToIntro()
        pausePresentation();
        presElapsed = 0;
        introScene = 0;
        showIntro();
        presUpdateUI();
    end

    function presTick()
        if isRebuilding || isempty(fig) || ~isvalid(fig) || ~presPlaying, return; end
        try
            presElapsed = min(presBase + toc(presT0)*1000,presTotal);
            if presElapsed >= presTotal
                pausePresentation();
                showScreen(numel(screenNames));
                presUpdateUI();
                return;
            end
            if presElapsed < presIntro
                if S.screen ~= 0, showIntro(); end
                renderIntro(presElapsed);
            else
                sec = min(floor((presElapsed-presIntro)/presSection)+1,numel(screenNames));
                if sec ~= S.screen, showScreen(sec); end
            end
            if floor(presElapsed/1000) ~= presLastSec
                presLastSec = floor(presElapsed/1000);
                presUpdateUI();
            end
        catch ME
            presPlaying = false;
            try stop(presTimer); catch, end
            setStatus(['Presentation error: ' ME.message]);
        end
    end

    function animTick()
        % Lightweight ambient animation for the interactive architecture & MPC pipeline.
        if isRebuilding || reduceMotion || isempty(fig) || ~isvalid(fig), return; end
        try
            if S.screen == 1 && ~isempty(archFlows)
                archPhase = mod(archPhase + 0.032, 1);
                for q = 1:numel(archFlows)
                    f = archFlows{q};
                    if ~isvalid(f.dot), continue; end
                    if f.active
                        ph = archPhase;
                        if f.dir < 0, ph = 1 - ph; end
                        f.dot.XData = f.x0 + ph*(f.x1 - f.x0);
                        f.dot.YData = f.y0 + ph*(f.y1 - f.y0);
                        f.dot.Visible = 'on';
                    else
                        f.dot.Visible = 'off';
                    end
                end
            elseif S.screen == 3 && ~isempty(mpcAnimDots)
                mpcPhase = mod(mpcPhase + 0.035, 1);
                for q = 1:numel(mpcAnimDots)
                    d = mpcAnimDots{q};
                    if ~isvalid(d.h), continue; end
                    ph = mod(mpcPhase + (q-1)*0.22, 1);
                    d.h.XData = d.x0 + ph*(d.x1 - d.x0);
                    d.h.YData = d.y;
                end
            end
        catch
        end
    end

    function presUpdateUI()
        if isempty(timerLabel) || ~isvalid(timerLabel), return; end
        timerLabel.Text = sprintf('%s / %s',fmtTime(presElapsed),fmtTime(presTotal));
        frac = min(max(presElapsed/presTotal,0),1);
        progressGrid.ColumnWidth = {sprintf('%.4fx',max(frac*100,0.0001)), ...
            sprintf('%.4fx',max((1-frac)*100,0.0001))};
        if presPlaying
            playBtn.Text = [icoPause ' Pause'];
        else
            playBtn.Text = [icoPlay ' Play'];
        end
    end

    function s = fmtTime(ms)
        sec = floor(ms/1000);
        s = sprintf('%02d:%02d',floor(sec/60),mod(sec,60));
    end

%% ================================================================
%  VOICE-OVER (optional; Windows System.Speech, otherwise captions only)
%  ================================================================
    function speakScene(k)
        if ~voiceOver || ~presPlaying || k < 1, return; end
        try
            if isempty(speaker)
                NET.addAssembly('System.Speech');
                speaker = System.Speech.Synthesis.SpeechSynthesizer();
                speaker.Rate = 1;
            end
            speaker.SpeakAsyncCancelAll();
            speaker.SpeakAsync(introCaps{k});
        catch
            voiceOver = false;
            updateVoiceButton();
            setStatus('Voice-over unavailable on this system - captions only');
        end
    end

    function stopNarration()
        if ~isempty(speaker)
            try speaker.SpeakAsyncCancelAll(); catch, end
        end
    end

    function toggleVoice()
        voiceOver = ~voiceOver;
        if voiceOver
            if S.screen == 0, speakScene(introScene); end
        else
            stopNarration();
        end
        updateVoiceButton();
        if voiceOver, setStatus('Voice-over on'); else, setStatus('Voice-over off'); end
    end

    function updateVoiceButton()
        if ~isempty(voiceBtn) && isvalid(voiceBtn)
            if voiceOver, voiceBtn.Text = 'Voice: on'; else, voiceBtn.Text = 'Voice: off'; end
        end
    end

%% ================================================================
%  ANIMATED INTRODUCTION (60 s)
%  ================================================================
    function buildIntro()
        introPanel = uipanel(content,'BorderType','none', ...
            'BackgroundColor',C.card,'Visible','off');
        introPanel.Layout.Row = 1;  introPanel.Layout.Column = 1;

        ig = uigridlayout(introPanel,[3 1]);
        ig.RowHeight = {'fit','1x',78};  ig.RowSpacing = 6;
        ig.Padding = [26 18 26 14];  ig.BackgroundColor = C.card;

        introHead = uilabel(ig,'Text','','FontSize',13,'FontWeight','bold', ...
            'FontColor',C.accent);

        introAxes = uiaxes(ig);
        introAxes.Color = C.card;
        introAxes.NextPlot = 'add';
        axis(introAxes,[0 160 0 100]);
        axis(introAxes,'off');
        try introAxes.Toolbar.Visible = 'off'; catch, end
        try disableDefaultInteractivity(introAxes); catch, end

        bottom = uigridlayout(ig,[1 3]);
        bottom.ColumnWidth = {'1x',100,100};  bottom.Padding = [0 0 0 0];
        bottom.ColumnSpacing = 10;  bottom.BackgroundColor = C.card;
        introCaption = uilabel(bottom,'Text','','FontSize',15,'FontColor',C.text, ...
            'WordWrap','on','VerticalAlignment','center');
        voiceBtn = makeButton(bottom,'Voice','secondary','Toggle voice-over (V)');
        voiceBtn.ButtonPushedFcn = @(~,~) toggleVoice();
        updateVoiceButton();
        skipBtn = makeButton(bottom,'Skip intro','secondary','Jump to the dashboard');
        skipBtn.ButtonPushedFcn = @(~,~) navigateTo(1);

        buildIntroScenes();
    end

    function showIntro()
        S.screen = 0;
        for q = 1:numel(pages)
            pages(q).Visible = 'off';
            navButtons(q).BackgroundColor = C.sidebar;
            navButtons(q).FontColor  = C.navText;
            navButtons(q).FontWeight = 'normal';
        end
        introPanel.Visible = 'on';
        titleLabel.Text = 'Project Introduction';
        subtitleLabel.Text = 'Problem, system, forecasting, control and results in 60 seconds';
        renderIntro(min(presElapsed,presIntro-1));
        setStatus('Viewing project introduction');
    end

    function renderIntro(ms)
        if isempty(introAxes) || ~isvalid(introAxes), return; end
        k = find(ms >= introTimes(1:6),1,'last');
        if isempty(k), k = 1; end
        t = (ms - introTimes(k))/1000;
        if k ~= introScene
            for j = 1:6
                if j ~= k
                    vis(sceneObjs{j},false);  vis(alwaysObjs{j},false);
                end
            end
            introScene = k;
            introHead.Text = sprintf('PROJECT INTRODUCTION   |   %d / 6   %s', ...
                k,upper(introTitles{k}));
            introCaption.Text = introCaps{k};
            speakScene(k);
        end
        vis(alwaysObjs{k},true);
        updateIntroScene(k,t);
    end

    function vis(h,on)
        if on, v = 'on'; else, v = 'off'; end
        if iscell(h)
            for q = 1:numel(h), vis(h{q},on); end
        else
            h.Visible = v;
        end
    end

    function reg(k,h)
        sceneObjs{k}{end+1} = h;
    end

    function alw(k,h)
        alwaysObjs{k}{end+1} = h;
    end

    function h = iBox(k,x,y,w,hh,edge,face)
        h = rectangle(introAxes,'Position',[x y w hh],'Curvature',[0.12 0.2], ...
            'EdgeColor',edge,'FaceColor',face,'LineWidth',1.6,'Visible','off');
        reg(k,h);
    end

    function h = iText(k,x,y,str,sz,col,wt)
        h = text(introAxes,x,y,str,'HorizontalAlignment','center', ...
            'VerticalAlignment','middle','FontSize',sz,'Color',col, ...
            'FontWeight',wt,'Interpreter','none','Visible','off');
        reg(k,h);
    end

    function h = iLine(k,x,y,col,w,style)
        h = plot(introAxes,x,y,style,'Color',col,'LineWidth',w,'Visible','off');
        reg(k,h);
    end

    function h = iDot(k,col)
        h = plot(introAxes,NaN,NaN,'o','MarkerSize',8,'MarkerFaceColor',col, ...
            'MarkerEdgeColor','none','Visible','off');
        reg(k,h);
    end

    function buildIntroScenes()
        sceneObjs = repmat({{}},1,6);
        alwaysObjs = repmat({{}},1,6);
        IH = struct();
        introScene = 0;
        cAmber = C.amber;  cBlue = C.blue;  cGreen = C.green;  cAcc = C.accent;

        for q = 1:6
            alw(q,iText(q,80,3,introNotes{q},10,C.muted,'normal'));
        end

        % ---- Scene 1: the problem ----------------------------------
        k = 1;
        u = linspace(0,1,140);
        IH.s1X = 20 + 120*u;
        IH.s1Y = {26 + 46*exp(-((u-.5)/.17).^2).*(0.85+0.15*sin(38*u)), ...
            34 + 9*(tanh((u-.28)*25)-tanh((u-.78)*25)) + 3*sin(18*u), ...
            26 + 20*exp(-((u-.30)/.04).^2) + 26*exp(-((u-.62)/.05).^2) + 14*exp(-((u-.82)/.03).^2)};
        alw(k,iLine(k,[20 140],[24 24],C.grid,1.2,'-'));
        alw(k,iLine(k,[20 20],[24 84],C.grid,1.2,'-'));
        alw(k,iText(k,20,19,'00:00',10,C.muted,'normal'));
        alw(k,iText(k,80,19,'12:00',10,C.muted,'normal'));
        alw(k,iText(k,140,19,'24:00',10,C.muted,'normal'));
        alw(k,iText(k,80,90,'Power over one day',12,C.muted,'bold'));
        cols = {cAmber,cBlue,cGreen};
        IH.s1Curve = cell(1,3);
        for q = 1:3, IH.s1Curve{q} = iLine(k,NaN,NaN,cols{q},3,'-'); end
        IH.s1Chip = {iText(k,36,10,'Variable generation',13,cAmber,'bold'), ...
            iText(k,80,10,'Changing demand',13,cBlue,'bold'), ...
            iText(k,124,10,'EV charging',13,cGreen,'bold')};

        % ---- Scene 2: the microgrid --------------------------------
        k = 2;
        cols = {cAmber,cAcc,cGreen,cBlue};
        vals = {SYS.pv_kWp,SYS.bat_kWh,'55 kW','80 kW'};
        names = {'PV array','Battery','EV chargers','Building'};
        subs = {'MPPT: P&O',['500 V | ' SYS.bat_kW],'5 x 11 kW','peak load'};
        IH.s2 = cell(1,4);
        for q = 1:4
            x0 = 10 + (q-1)*36;
            IH.s2{q} = {iBox(k,x0,32,32,36,cols{q},mixc(C.card,cols{q},0.07)), ...
                iBox(k,x0,64,32,4,cols{q},cols{q}), ...
                iText(k,x0+16,56,vals{q},18,cols{q},'bold'), ...
                iText(k,x0+16,46,names{q},12,C.text,'bold'), ...
                iText(k,x0+16,38,subs{q},10,C.muted,'normal')};
        end

        % ---- Scene 3: electrical architecture ----------------------
        k = 3;
        IH.s3t = [0.5 1.5 3 5 6.5];
        IH.s3node = cell(1,5);
        IH.s3node{1} = {iBox(k,10,64,30,15,cAmber,mixc(C.card,cAmber,0.08)), ...
            iText(k,25,73,'PV array',12,C.text,'bold'), ...
            iText(k,25,68,'100 kWp  |  P&O MPPT',9.5,C.muted,'normal')};
        IH.s3node{2} = {iBox(k,10,21,30,15,cAcc,mixc(C.card,cAcc,0.08)), ...
            iText(k,25,30,'Battery',12,C.text,'bold'), ...
            iText(k,25,25,['200 kWh | 500 V | ' SYS.bat_kW],9.5,C.muted,'normal')};
        IH.s3node{3} = {iBox(k,77,16,6,68,cAcc,cAcc), ...
            iText(k,80,90,'750 V DC bus (provisional)',11,cAcc,'bold')};
        IH.s3node{4} = {iBox(k,120,64,30,15,cBlue,mixc(C.card,cBlue,0.08)), ...
            iText(k,135,73,'Utility grid',12,C.text,'bold'), ...
            iText(k,135,68,'bidirectional',9.5,C.muted,'normal'), ...
            iText(k,135,57,'415 V L-L, 50 Hz',10,C.text,'bold'), ...
            iText(k,135,52,['150 kVA | ' SYS.grid_kW],10,C.text,'bold')};
        IH.s3node{5} = {iBox(k,120,21,30,15,cGreen,mixc(C.card,cGreen,0.08)), ...
            iText(k,135,30,'Building + EV',12,C.text,'bold'), ...
            iText(k,135,25,'80 kW + 55 kW (5x11)',9.5,C.muted,'normal')};
        fdef = {[40 77 71],[40 77 29],[83 120 71],[83 120 29]};
        fcol = {cAmber,cAcc,cBlue,cGreen};
        fdir = {1,[1 -1],[1 -1],1};
        ft   = [3 3 5 6.5];
        IH.s3flow = cell(1,4);
        for q = 1:4
            d = fdef{q};
            f.x0 = d(1);  f.x1 = d(2);  f.y = d(3);  f.t = ft(q);  f.dirs = fdir{q};
            f.objs = {iLine(k,[d(1) d(2)],[d(3) d(3)],C.grid,2.5,'-'), ...
                iBox(k,(d(1)+d(2))/2-3,d(3)-3,6,6,fcol{q},C.card)};
            f.dots = cell(1,numel(fdir{q}));
            for m = 1:numel(f.dots), f.dots{m} = iDot(k,fcol{q}); end
            IH.s3flow{q} = f;
        end

        % ---- Scene 4: AI forecasting -------------------------------
        k = 4;
        u = linspace(0,1,100);
        A = cell(1,3);  P = cell(1,3);
        A{1} = exp(-((u-.5)/.18).^2).*(0.9+0.1*sin(30*u));
        A{2} = 0.45 + 0.35*(tanh((u-.3)*14)-tanh((u-.78)*14))/2 + 0.03*sin(16*u);
        A{3} = 0.1 + 0.8*exp(-((u-.3)/.07).^2) + 0.6*exp(-((u-.65)/.09).^2);
        P{1} = 0.95*exp(-((u-.5)/.18).^2) + 0.03*sin(20*u+1);
        P{2} = A{2} + 0.03*sin(25*u+.5) - 0.02;
        P{3} = 0.1 + 0.7*exp(-((u-.32)/.09).^2) + 0.55*exp(-((u-.63)/.10).^2);
        x0s = [8 57 106];  w = 46;
        names = {'PV forecasting','Building forecasting','EV forecasting'};
        cols = {cAmber,cBlue,cGreen};
        alw(k,iText(k,80,86,'Actual (solid)  |  Predicted (dashed)',11,C.muted,'normal'));
        IH.s4 = cell(1,3);
        for q = 1:3
            g4.X = x0s(q) + 4 + (w-8)*u;
            g4.A = 38 + 32*A{q};
            g4.P = 38 + 32*P{q};
            g4.grp = {iBox(k,x0s(q),32,w,44,C.grid,C.card), ...
                iText(k,x0s(q)+w/2,26,names{q},12,cols{q},'bold')};
            g4.la = iLine(k,NaN,NaN,cols{q},2.6,'-');
            g4.lp = iLine(k,NaN,NaN,mixc(cols{q},C.card,0.35),2.2,'--');
            IH.s4{q} = g4;
        end

        % ---- Scene 5: predictive energy management -----------------
        k = 5;
        inY = [72 50 28];  tgY = [56 50 44];
        inNames = {'PV forecast','Building forecast','EV forecast'};
        inCols = {cAmber,cBlue,cGreen};
        IH.s5in = cell(1,3);
        for q = 1:3
            f5.objs = {iBox(k,8,inY(q)-6,34,12,inCols{q},mixc(C.card,inCols{q},0.08)), ...
                iText(k,25,inY(q),inNames{q},11,C.text,'bold'), ...
                iLine(k,[42 62],[inY(q) tgY(q)],C.grid,2,'-')};
            f5.dot = iDot(k,inCols{q});
            f5.x0 = 42;  f5.x1 = 62;  f5.y0 = inY(q);  f5.y1 = tgY(q);
            IH.s5in{q} = f5;
        end
        IH.s5ctrl = {iBox(k,62,36,36,28,cAcc,mixc(C.card,cAcc,0.12)), ...
            iText(k,80,54,'MPC',22,cAcc,'bold'), ...
            iText(k,80,43,'15-minute scheduling',10,C.muted,'normal')};
        outNames = {'Battery schedule','Grid exchange'};
        outY = [66 34];  srcY = [56 44];  outCols = {cAcc,cBlue};
        IH.s5out = cell(1,2);
        for q = 1:2
            o5.objs = {iBox(k,118,outY(q)-6,34,12,outCols{q},mixc(C.card,outCols{q},0.08)), ...
                iText(k,135,outY(q),outNames{q},11,C.text,'bold'), ...
                iLine(k,[98 118],[srcY(q) outY(q)],C.grid,2,'-')};
            o5.dot = iDot(k,outCols{q});
            o5.x0 = 98;  o5.x1 = 118;  o5.y0 = srcY(q);  o5.y1 = outY(q);
            IH.s5out{q} = o5;
        end
        IH.s5con = {iBox(k,34,6,92,11,C.orange,mixc(C.card,C.orange,0.08)), ...
            iText(k,80,11.5,['Constraints: SOC ' SYS.bat_soc ' | Battery ' SYS.bat_kW ' | Grid ' SYS.grid_kW], ...
            10,C.orange,'bold'), ...
            iLine(k,[80 80],[17 36],C.orange,2,'--')};

        % ---- Scene 6: project outcome ------------------------------
        k = 6;
        chipX = [10 61 112];  chipTxt = {'Simulation','Comparison','Interactive dashboard'};
        chipCol = {cBlue,C.orange,cAcc};
        IH.s6chip = cell(1,3);
        for q = 1:3
            c6 = {iBox(k,chipX(q),64,38,16,chipCol{q},mixc(C.card,chipCol{q},0.08)), ...
                iText(k,chipX(q)+19,72,chipTxt{q},12,chipCol{q},'bold')};
            if q > 1
                c6{end+1} = iText(k,chipX(q)-5.5,72,icoArrowR,20,C.muted,'bold'); %#ok<AGROW>
            end
            IH.s6chip{q} = c6;
        end
        mock = {iBox(k,44,16,72,42,C.grid,C.card), ...
            iBox(k,44,16,9,42,C.sidebar,C.sidebar)};
        mcols = {cAmber,cAcc,cGreen,cBlue};
        for q = 1:4
            mock{end+1} = iBox(k,56+(q-1)*14,44,12,10,mcols{q},mixc(C.card,mcols{q},0.12)); %#ok<AGROW>
        end
        mock{end+1} = iBox(k,56,20,54,20,C.grid,mixc(C.card,cAcc,0.05));
        xs = linspace(58,108,40);
        mock{end+1} = iLine(k,xs,28+7*sin(xs/6)+3*cos(xs/3),cAcc,2.2,'-');
        IH.s6mock = mock;
        IH.s6open = iText(k,80,10,'Opening the dashboard...',13,cAcc,'bold');
    end

    function updateIntroScene(k,t)
        switch k
            case 1
                n = max(2,round(min(1,t/8)*numel(IH.s1X)));
                for q = 1:3
                    c = IH.s1Curve{q};
                    c.XData = IH.s1X(1:n);  c.YData = IH.s1Y{q}(1:n);  c.Visible = 'on';
                end
                vis(IH.s1Chip{1},t>=1.5);
                vis(IH.s1Chip{2},t>=3.5);
                vis(IH.s1Chip{3},t>=5.5);

            case 2
                for q = 1:4, vis(IH.s2{q},t >= 1 + 2.2*(q-1)); end

            case 3
                for q = 1:5, vis(IH.s3node{q},t >= IH.s3t(q)); end
                for q = 1:4
                    f = IH.s3flow{q};  on = t >= f.t;
                    vis(f.objs,on);
                    for m = 1:numel(f.dots)
                        ph = mod(0.3*t + 0.5*(m-1),1);
                        if f.dirs(m) < 0, ph = 1 - ph; end
                        f.dots{m}.XData = f.x0 + ph*(f.x1-f.x0);
                        f.dots{m}.YData = f.y;
                        vis(f.dots{m},on);
                    end
                end

            case 4
                for q = 1:3
                    g4 = IH.s4{q};
                    ti = 0.8 + (q-1)*2.4;  on = t >= ti;
                    vis(g4.grp,on);
                    n = max(2,round(min(1,max(0,(t-ti)/3.5))*numel(g4.X)));
                    g4.la.XData = g4.X(1:n);  g4.la.YData = g4.A(1:n);
                    g4.lp.XData = g4.X(1:n);  g4.lp.YData = g4.P(1:n);
                    vis(g4.la,on);  vis(g4.lp,on);
                end

            case 5
                tin = [0.5 1.7 2.9];
                for q = 1:3
                    f = IH.s5in{q};  on = t >= tin(q);
                    vis(f.objs,on);
                    ph = mod(0.4*t + 0.3*q,1);
                    f.dot.XData = f.x0 + ph*(f.x1-f.x0);
                    f.dot.YData = f.y0 + ph*(f.y1-f.y0);
                    vis(f.dot,on);
                end
                vis(IH.s5ctrl,t >= 4);
                tout = [5.5 6.3];
                for q = 1:2
                    o = IH.s5out{q};  on = t >= tout(q);
                    vis(o.objs,on);
                    ph = mod(0.4*t + 0.3*q,1);
                    o.dot.XData = o.x0 + ph*(o.x1-o.x0);
                    o.dot.YData = o.y0 + ph*(o.y1-o.y0);
                    vis(o.dot,on);
                end
                vis(IH.s5con,t >= 7);

            case 6
                vis(IH.s6chip{1},t >= 0.6);
                vis(IH.s6chip{2},t >= 2.0);
                vis(IH.s6chip{3},t >= 3.4);
                vis(IH.s6mock,t >= 4.5);
                vis(IH.s6open,t >= 6);
        end
    end

%% ================================================================
%  INTERACTIVE MICROGRID ARCHITECTURE (System Overview)
%  ================================================================
    function buildInteractiveArchitecture(parent)
        [ag,~] = cardGrid(parent,[3 1],[14 10 14 10]);
        ag.RowHeight = {34,'1x','fit'};  ag.RowSpacing = 6;

        % Top bar: title + scenario selector
        top = uigridlayout(ag,[1 4]);
        top.ColumnWidth = {'1x','fit',200,'fit'};
        top.Padding = [0 0 0 0];  top.ColumnSpacing = 10;
        top.BackgroundColor = C.card;
        uilabel(top,'Text','INTERACTIVE MICROGRID ARCHITECTURE  (click any component for specifications)', ...
            'FontSize',11,'FontWeight','bold','FontColor',C.muted);
        controlLabel(top,'Scenario');
        archScenarioDrop = makeDropdown(top,scenarioNames,S.scenario, ...
            'Switch between generated profile noon snapshot and illustrative scenarios');
        archScenarioDrop.ValueChangedFcn = @(~,~) onScenarioChanged();
        uilabel(top,'Text','750 V DC Bus  |  415 V AC Grid', ...
            'FontSize',11,'FontWeight','bold','FontColor',C.accent);

        % Middle split: interactive diagram canvas + specification inspector
        mid = uigridlayout(ag,[1 2]);
        mid.ColumnWidth = {'2.2x','1x'};
        mid.Padding = [0 0 0 0];  mid.ColumnSpacing = 12;
        mid.BackgroundColor = C.card;

        archAxes = uiaxes(mid);
        archAxes.Color = mixc(C.card,C.bg,0.35);
        archAxes.NextPlot = 'add';
        axis(archAxes,[0 160 0 100]);
        axis(archAxes,'off');
        try archAxes.Toolbar.Visible = 'off'; catch, end
        try disableDefaultInteractivity(archAxes); catch, end

        % Inspector panel
        [~,specPanel] = cardGrid(mid,[1 1],[0 0 0 0]);
        delete(specPanel.Children);
        specPanel.BackgroundColor = mixc(C.card,C.accent,0.06);
        sg = uigridlayout(specPanel,[3 1]);
        sg.RowHeight = {'fit','fit','1x'};
        sg.Padding = [14 12 14 12];  sg.RowSpacing = 6;
        sg.BackgroundColor = mixc(C.card,C.accent,0.06);

        archSpecBadge = uilabel(sg,'Text','COMPONENT SPECIFICATIONS', ...
            'FontSize',10,'FontWeight','bold','FontColor',C.accent);
        archSpecTitle = uilabel(sg,'Text','PV Array (100 kWp)', ...
            'FontSize',16,'FontWeight','bold','FontColor',C.text);
        archSpecBody = uilabel(sg,'Text','','FontSize',12,'FontColor',C.text, ...
            'WordWrap','on','VerticalAlignment','top');

        archScenarioNote = uilabel(ag,'Text','','FontSize',11,'FontColor',C.muted);

        drawArchitectureDiagram();
        selectComponent(S.selectedComp);
        updateArchitectureScenario();
    end

    function drawArchitectureDiagram()
        cla(archAxes);
        archNodes = struct();
        archFlows = {};

        % Central DC Bus
        makeCompNode('DCBUS',68,20,24,60,C.accent,'DC Bus','750 V (prov.)');
        % Central EMS Controller (top center)
        makeCompNode('EMS',62,84,36,13,C.purple,'EMS / MPC','15-min control');
        % Left: PV & Battery
        makeCompNode('PV',8,60,34,26,C.amber,'PV Array','100 kWp | P&O');
        makeCompNode('BAT',8,16,34,26,C.accent,'Battery BESS','200 kWh | 500 V');
        % Right: Grid, Building, EV
        makeCompNode('GRID',118,62,34,24,C.blue,'Utility Grid','415 V | 150 kVA');
        makeCompNode('BLD',118,34,34,22,C.orange,'Building Load','80 kW peak');
        makeCompNode('EV',118,8,34,22,C.green,'EV Chargers','5 x 11 kW (55 kW)');

        % Supervisory control dashed lines from EMS
        plot(archAxes,[80 80],[84 80],'--','Color',C.purple,'LineWidth',1.3,'PickableParts','none');
        plot(archAxes,[42 62],[78 90],':','Color',C.purple,'LineWidth',1.2,'PickableParts','none');
        plot(archAxes,[98 118],[90 78],':','Color',C.purple,'LineWidth',1.2,'PickableParts','none');

        % Power links + animated dots
        archFlows{end+1} = makeFlowLink('pv',  42,68, 73,68, C.amber,  1);
        archFlows{end+1} = makeFlowLink('bat', 42,29, 68,29, C.accent, 1);
        archFlows{end+1} = makeFlowLink('grid',92,72, 118,72,C.blue,   1);
        archFlows{end+1} = makeFlowLink('bld', 92,45, 118,45,C.orange, 1);
        archFlows{end+1} = makeFlowLink('ev',  92,22, 118,22,C.green,  1);
    end

    function makeCompNode(id,x,y,w,hh,col,titleTxt,subTxt)
        boxH = rectangle(archAxes,'Position',[x y w hh],'Curvature',[0.14 0.18], ...
            'EdgeColor',col,'FaceColor',mixc(C.card,col,0.09), ...
            'LineWidth',1.8,'PickableParts','all', ...
            'ButtonDownFcn',@(~,~) selectComponent(id));
        t1 = text(archAxes,x+w/2,y+hh*0.64,titleTxt,'HorizontalAlignment','center', ...
            'VerticalAlignment','middle','FontSize',11,'FontWeight','bold', ...
            'Color',C.text,'Interpreter','none','PickableParts','all', ...
            'ButtonDownFcn',@(~,~) selectComponent(id));
        t2 = text(archAxes,x+w/2,y+hh*0.30,subTxt,'HorizontalAlignment','center', ...
            'VerticalAlignment','middle','FontSize',9.5,'Color',C.muted, ...
            'Interpreter','none','PickableParts','all', ...
            'ButtonDownFcn',@(~,~) selectComponent(id));
        archNodes.(id) = struct('box',boxH,'col',col,'t1',t1,'t2',t2);
    end

    function f = makeFlowLink(id,x0,y0,x1,y1,col,dir)
        ln = plot(archAxes,[x0 x1],[y0 y1],'-','Color',col,'LineWidth',2.4, ...
            'PickableParts','none');
        lbl = text(archAxes,(x0+x1)/2,y0+4.5,'','HorizontalAlignment','center', ...
            'VerticalAlignment','bottom','FontSize',9.5,'FontWeight','bold', ...
            'Color',col,'Interpreter','none','PickableParts','none');
        dot = plot(archAxes,x0,y0,'o','MarkerSize',8,'MarkerFaceColor',col, ...
            'MarkerEdgeColor',C.card,'LineWidth',1,'PickableParts','none');
        f = struct('id',id,'x0',x0,'y0',y0,'x1',x1,'y1',y1,'dir',dir, ...
            'active',true,'line',ln,'lbl',lbl,'dot',dot);
    end

    function selectComponent(id)
        S.selectedComp = id;
        ids = fieldnames(archNodes);
        for q = 1:numel(ids)
            nd = archNodes.(ids{q});
            if strcmp(ids{q},id)
                nd.box.LineWidth = 3.2;
                nd.box.FaceColor = mixc(C.card,nd.col,0.22);
            else
                nd.box.LineWidth = 1.6;
                nd.box.FaceColor = mixc(C.card,nd.col,0.08);
            end
        end

        switch id
            case 'PV'
                archSpecBadge.Text = 'GENERATION COMPONENT  (DESIGN SPEC)';
                archSpecTitle.Text = ['PV Array (' SYS.pv_kWp ')'];
                archSpecBody.Text  = sprintf(['Rated peak capacity: %s\n' ...
                    'MPPT algorithm: %s\nDC interface: %s DC bus\n\n' ...
                    'Supplies solar power to building/EV loads, battery charging, or grid export under EMS coordination.'], ...
                    SYS.pv_kWp,SYS.pv_mppt,SYS.dc_bus);
            case 'BAT'
                archSpecBadge.Text = 'ENERGY STORAGE  (DESIGN SPEC)';
                archSpecTitle.Text = ['Battery BESS (' SYS.bat_kWh ')'];
                archSpecBody.Text  = sprintf(['Energy capacity: %s\nNominal voltage: %s\n' ...
                    'Charge/discharge limit: %s\nOperating SOC window: %s\n\n' ...
                    'Buffers renewable variability and shifts peak demand within explicit SOC and power constraints.'], ...
                    SYS.bat_kWh,SYS.bat_V,SYS.bat_kW,SYS.bat_soc);
            case 'EV'
                archSpecBadge.Text = 'CONTROLLABLE / FORECASTED LOAD';
                archSpecTitle.Text = ['EV Charging Stations (' SYS.ev_desc ')'];
                archSpecBody.Text  = sprintf(['Configuration: 5 chargers x 11 kW each\n' ...
                    'Total peak capacity: 55 kW\n\n' ...
                    'Day-ahead EV charging demand is forecasted using Persistence, Moving Average, Random Forest, LSBoost, SVR, and LSTM.'], ...
                    '');
            case 'BLD'
                archSpecBadge.Text = 'PRIMARY DEMAND  (DESIGN SPEC)';
                archSpecTitle.Text = ['Building Load (' SYS.bld_kW ')'];
                archSpecBody.Text  = sprintf(['Peak building demand: %s\n\n' ...
                    'Day-ahead building demand is predicted at 15-minute resolution to inform the supervisory MPC optimizer.'], ...
                    SYS.bld_kW);
            case 'GRID'
                archSpecBadge.Text = 'GRID INTERFACE  (DESIGN SPEC)';
                archSpecTitle.Text = ['Utility Grid (' SYS.grid_kva ')'];
                archSpecBody.Text  = sprintf(['Grid connection: %s\nInterface rating: %s\n' ...
                    'Import / export limit: %s\n\n' ...
                    'Provides bidirectional power balancing when net microgrid load exceeds or falls below local supply.'], ...
                    SYS.grid_v,SYS.grid_kva,SYS.grid_kW);
            case 'DCBUS'
                archSpecBadge.Text = 'COMMON COUPLING  (DESIGN SPEC)';
                archSpecTitle.Text = ['DC Bus (' SYS.dc_bus ')'];
                archSpecBody.Text  = sprintf(['Provisional nominal voltage: %s\n\n' ...
                    'Links PV, battery storage, and bidirectional inverter/load interfaces. Conceptual representation, not a live schematic.'], ...
                    SYS.dc_bus);
            case 'EMS'
                archSpecBadge.Text = 'SUPERVISORY CONTROLLER';
                archSpecTitle.Text = 'Central EMS / MPC Controller';
                archSpecBody.Text  = sprintf(['Scheduling interval: %s\n' ...
                    'Compared strategies: Perfect Forecast, Persistence, ML Forecast\n\n' ...
                    'Enforces SOC (%s), battery power (%s), and grid limits (%s). Does not execute Simulink from this viewer.'], ...
                    SYS.ems_dt,SYS.bat_soc,SYS.bat_kW,SYS.grid_kW);
        end
    end

    function onScenarioChanged()
        S.scenario = archScenarioDrop.Value;
        updateArchitectureScenario();
    end

    function updateArchitectureScenario()
        if isempty(archFlows), return; end
        switch S.scenario
            case 'Generated Profile (Noon)'
                try
                    p = loadProfiles();
                    [~,idx] = min(abs(p.time_hours - 12.0));
                    pv  = p.P_pv_W(idx)/1000;
                    bld = p.P_building_W(idx)/1000;
                    ev  = p.P_ev_W(idx)/1000;
                    net = bld + ev - pv; % positive => net demand
                    note = sprintf('Source: microgrid_profiles_24h.mat at %.2f h (historical generated profile; conceptual net balance, no live battery SOC/grid telemetry).', ...
                        p.time_hours(idx));
                    batFlow = 0;  batDir = 1;
                    gridFlow = abs(net);
                    if net >= 0, gridDir = -1; gridTxt = sprintf('%.1f kW imp.',gridFlow);
                    else,        gridDir = 1;  gridTxt = sprintf('%.1f kW exp.',gridFlow); end
                catch
                    pv = 68; bld = 52; ev = 18; batFlow = 0; batDir = 1;
                    gridDir = -1; gridTxt = '2.0 kW imp.';
                    note = 'Profile file unavailable - showing fallback illustrative noon values.';
                end
                archFlows{1}.lbl.String = sprintf('%.1f kW',pv);
                archFlows{1}.dir = 1; archFlows{1}.active = pv > 0.1;
                archFlows{2}.lbl.String = 'standby (no live SOC)';
                archFlows{2}.dir = batDir; archFlows{2}.active = batFlow > 0.1;
                archFlows{3}.lbl.String = gridTxt;
                archFlows{3}.dir = gridDir; archFlows{3}.active = true;
                archFlows{4}.lbl.String = sprintf('%.1f kW',bld);
                archFlows{4}.dir = 1; archFlows{4}.active = true;
                archFlows{5}.lbl.String = sprintf('%.1f kW',ev);
                archFlows{5}.dir = 1; archFlows{5}.active = ev > 0.1;

            case 'Sunny (Illustrative)'
                note = 'Illustrative sunny scenario: high PV generation charges battery and exports surplus (not measured data).';
                setFlow(1,'92 kW',1,true);
                setFlow(2,'28 kW chg',-1,true);
                setFlow(3,'16 kW exp.',1,true);
                setFlow(4,'38 kW',1,true);
                setFlow(5,'10 kW',1,true);

            case 'Cloudy (Illustrative)'
                note = 'Illustrative cloudy scenario: reduced PV supplemented by battery discharge and grid import (not measured data).';
                setFlow(1,'24 kW',1,true);
                setFlow(2,'22 kW dis.',1,true);
                setFlow(3,'24 kW imp.',-1,true);
                setFlow(4,'52 kW',1,true);
                setFlow(5,'18 kW',1,true);

            otherwise % High Demand (Illustrative)
                note = 'Illustrative high-demand scenario: peak building + EV charging supported by max battery and grid import (not measured data).';
                setFlow(1,'40 kW',1,true);
                setFlow(2,'55 kW dis.',1,true);
                setFlow(3,'40 kW imp.',-1,true);
                setFlow(4,'80 kW',1,true);
                setFlow(5,'55 kW',1,true);
        end
        archScenarioNote.Text = note;
        for q = 1:numel(archFlows)
            if ~archFlows{q}.active
                archFlows{q}.dot.Visible = 'off';
            elseif reduceMotion
                archFlows{q}.dot.XData = (archFlows{q}.x0 + archFlows{q}.x1)/2;
                archFlows{q}.dot.YData = (archFlows{q}.y0 + archFlows{q}.y1)/2;
                archFlows{q}.dot.Visible = 'on';
            end
        end
    end

    function setFlow(idx,txt,dir,active)
        archFlows{idx}.lbl.String = txt;
        archFlows{idx}.dir = dir;
        archFlows{idx}.active = active;
    end

%% ================================================================
%  REUSABLE WIDGETS
%  ================================================================
    function [g,panel] = cardGrid(parent,dims,pad)
        panel = uipanel(parent,'BackgroundColor',C.card,'BorderType','none');
        g = uigridlayout(panel,dims);
        g.Padding = pad;  g.BackgroundColor = C.card;
    end

    function h = kpiCard(parent,heading,value,accent,caption)
        [~,panel] = cardGrid(parent,[1 1],[0 0 0 0]);
        delete(panel.Children);
        cg = uigridlayout(panel,[1 2]);
        cg.ColumnWidth = {6,'1x'};  cg.Padding = [0 0 0 0];
        cg.ColumnSpacing = 0;       cg.BackgroundColor = C.card;
        uipanel(cg,'BackgroundColor',accent,'BorderType','none');
        tg = uigridlayout(cg,[3 1]);
        tg.RowHeight = {'fit','1x','fit'};  tg.Padding = [14 10 10 8];
        tg.RowSpacing = 0;  tg.BackgroundColor = C.card;
        uilabel(tg,'Text',upper(heading),'FontSize',10.5, ...
            'FontWeight','bold','FontColor',C.muted);
        h.value = uilabel(tg,'Text',value,'FontSize',21,'FontWeight','bold', ...
            'FontColor',C.text,'VerticalAlignment','center');
        h.caption = uilabel(tg,'Text',caption,'FontSize',10.5,'FontColor',C.muted);
    end

    function ax = chartCard(parent)
        cg = cardGrid(parent,[1 1],[12 12 12 8]);
        ax = uiaxes(cg);
        styleAxes(ax);
    end

    function styleAxes(ax)
        ax.Color = C.card;  ax.XColor = C.muted;  ax.YColor = C.muted;
        ax.GridColor = C.grid;  ax.GridAlpha = 0.45;
        ax.Box = 'off';  ax.FontSize = 11;
        ax.XGrid = 'on';  ax.YGrid = 'on';
        ax.Title.FontSize = 13.5;  ax.Title.FontWeight = 'bold';
        ax.Title.Color = C.text;
        ax.XLabel.Color = C.muted;  ax.YLabel.Color = C.muted;
    end

    function resetAxes(ax)
        legend(ax,'off');
        ax.XTickMode = 'auto';  ax.YTickMode = 'auto';
        ax.XTickLabelMode = 'auto';  ax.YTickLabelMode = 'auto';
        ax.XLimMode = 'auto';  ax.YLimMode = 'auto';
    end

    function styleLegend(ax,loc)
        lg = legend(ax,'Location',loc,'Box','off');
        lg.TextColor = C.text;
    end

    function showMessage(ax,msg,isError)
        cla(ax);
        legend(ax,'off');
        if isError, col = C.danger; else, col = C.muted; end
        text(ax,0.5,0.5,msg,'Units','normalized', ...
            'HorizontalAlignment','center','Color',col, ...
            'FontSize',13,'Interpreter','none');
        ax.XTick = [];  ax.YTick = [];
    end

    function bar = controlBar(parent,widths)
        panel = uipanel(parent,'BackgroundColor',C.card,'BorderType','none');
        bar = uigridlayout(panel,[1 numel(widths)]);
        bar.ColumnWidth = widths;  bar.Padding = [14 8 14 8];
        bar.ColumnSpacing = 10;    bar.BackgroundColor = C.card;
    end

    function l = controlLabel(parent,txt)
        l = uilabel(parent,'Text',txt,'FontWeight','bold', ...
            'FontColor',C.muted,'FontSize',12);
    end

    function d = makeDropdown(parent,items,value,tip)
        if ~ismember(value,items), value = items{1}; end
        d = uidropdown(parent,'Items',items,'Value',value, ...
            'BackgroundColor',C.input,'FontColor',C.text,'Tooltip',tip);
    end

    function b = makeButton(parent,txt,kind,tip)
        b = uibutton(parent,'push','Text',txt,'Tooltip',tip,'FontSize',13);
        if strcmp(kind,'primary')
            b.BackgroundColor = C.accent;  b.FontColor = [1 1 1];
            b.FontWeight = 'bold';
        else
            b.BackgroundColor = C.input;  b.FontColor = C.text;
        end
    end

    function t = makeTable(parent,sortable)
        t = uitable(parent,'ColumnEditable',false,'RowStriping','on', ...
            'FontSize',12,'BackgroundColor',[C.card; mixc(C.card,C.text,0.05)], ...
            'ForegroundColor',C.text);
        try t.ColumnSortable = sortable; catch, end
    end

    function exportAxes(ax,baseName)
        [f,p] = uiputfile('*.png','Export chart as PNG', ...
            fullfile(dashboardFolder,[baseName '.png']));
        figure(fig);
        if isequal(f,0), return; end
        try
            exportgraphics(ax,fullfile(p,f),'Resolution',200);
            setStatus(['Chart exported: ' f]);
        catch ME
            uialert(fig,ME.message,'Export error');
        end
    end

%% ================================================================
%  1. SYSTEM OVERVIEW
%  ================================================================
    function buildOverview()
        g = uigridlayout(pages(1),[4 1]);
        g.RowHeight = {96,96,248,'1x'};
        g.Padding = [0 0 0 0];  g.RowSpacing = 12;
        g.BackgroundColor = C.bg;

        % Row 1: Complete project design specifications
        r1 = uigridlayout(g,[1 5]);
        r1.Padding = [0 0 0 0];  r1.ColumnSpacing = 12;  r1.BackgroundColor = C.bg;
        kpiCard(r1,'PV capacity',SYS.pv_kWp,C.amber,['MPPT: ' SYS.pv_mppt]);
        kpiCard(r1,'Battery BESS',SYS.bat_kWh,C.accent,[SYS.bat_V ' | ' SYS.bat_kW]);
        kpiCard(r1,'EV chargers',SYS.ev_desc,C.green,'design parameter');
        kpiCard(r1,'Building load',SYS.bld_kW,C.blue,'design peak demand');
        kpiCard(r1,'Grid & DC bus',SYS.grid_kva,C.purple,[SYS.grid_v ' | ' SYS.dc_bus]);

        % Row 2: Insights derived from generated 24h profile
        r2 = uigridlayout(g,[1 4]);
        r2.Padding = [0 0 0 0];  r2.ColumnSpacing = 12;  r2.BackgroundColor = C.bg;
        insPV   = kpiCard(r2,'PV energy / day','-',C.amber,'generated profile');
        insLoad = kpiCard(r2,'Demand / day','-',C.blue,'building + EV (generated)');
        insCov  = kpiCard(r2,'Direct solar coverage','-',C.green,'PV used instantly, no battery');
        insPeak = kpiCard(r2,'Peak net import','-',C.orange,'generated profile, no battery');

        % Row 3: Interactive Microgrid Architecture
        buildInteractiveArchitecture(g);

        % Row 4: 24-hour profile chart + Data Health table
        bottom = uigridlayout(g,[1 2]);
        bottom.ColumnWidth = {'2.2x','1x'};  bottom.Padding = [0 0 0 0];
        bottom.ColumnSpacing = 12;  bottom.BackgroundColor = C.bg;

        overviewAxes = chartCard(bottom);

        [hg,~] = cardGrid(bottom,[3 1],[14 10 14 10]);
        hg.RowHeight = {'fit','1x','fit'};  hg.RowSpacing = 6;
        uilabel(hg,'Text','DATA HEALTH','FontSize',11,'FontWeight','bold', ...
            'FontColor',C.muted);
        healthTable = makeTable(hg,false);
        healthTable.ColumnName = {'Source','Status'};
        healthTable.ColumnWidth = {'auto',90};
        uilabel(hg,'Text','Design values and generated profiles are not live measurements.', ...
            'FontSize',11,'FontColor',C.muted,'WordWrap','on');

        fillHealth();
        plotOverview();
    end

    function fillHealth()
        ok = cellfun(@isfile,sources(:,2));
        data = cell(numel(ok),2);
        for i = 1:numel(ok)
            data{i,1} = sources{i,1};
            if ok(i), data{i,2} = 'Available'; else, data{i,2} = 'Missing'; end
        end
        healthTable.Data = data;
        removeStyle(healthTable);
        for i = 1:numel(ok)
            if ok(i), col = C.green; else, col = C.danger; end
            addStyle(healthTable,uistyle('FontColor',col,'FontWeight','bold'), ...
                'cell',[i 2]);
        end
    end

    function plotOverview()
        try
            p = loadProfiles();
            t = p.time_hours;
            pv = p.P_pv_W/1000;  bl = p.P_building_W/1000;  ev = p.P_ev_W/1000;
            net = bl + ev - pv;

            cla(overviewAxes);  resetAxes(overviewAxes);
            hold(overviewAxes,'on');
            plot(overviewAxes,t,pv,'LineWidth',2,'Color',C.amber,'DisplayName','PV');
            plot(overviewAxes,t,bl,'LineWidth',2,'Color',C.blue,'DisplayName','Building');
            plot(overviewAxes,t,ev,'LineWidth',2,'Color',C.green,'DisplayName','EV');
            plot(overviewAxes,t,net,'--','LineWidth',1.6,'Color',C.purple, ...
                'DisplayName','Net load');
            hold(overviewAxes,'off');
            xlim(overviewAxes,[min(t) max(t)]);
            title(overviewAxes,'24-hour power profiles (historical generated data)');
            xlabel(overviewAxes,'Time (hours)');  ylabel(overviewAxes,'Power (kW)');
            styleLegend(overviewAxes,'northwest');

            Epv = trapz(t,pv);  Eld = trapz(t,bl+ev);
            cov = trapz(t,min(pv,bl+ev))/max(Eld,eps)*100;
            insPV.value.Text   = sprintf('%.0f kWh',Epv);
            insLoad.value.Text = sprintf('%.0f kWh',Eld);
            insCov.value.Text  = sprintf('%.1f %%',cov);
            insPeak.value.Text = sprintf('%.1f kW',max(max(net),0));
        catch ME
            showMessage(overviewAxes,['Profile data unavailable: ' ME.message],true);
        end
    end

%% ================================================================
%  2. FORECASTING
%  ================================================================
    function buildForecasting()
        g = uigridlayout(pages(2),[4 1]);
        g.RowHeight = {52,26,102,'1x'};
        g.Padding = [0 0 0 0];  g.RowSpacing = 10;
        g.BackgroundColor = C.bg;

        bar = controlBar(g,{'fit',150,'fit',170,'fit',84,32,32,'fit',135,'1x',104});
        controlLabel(bar,'Category');
        categoryDrop = makeDropdown(bar,forecastCategories,S.category,'Forecast category');
        controlLabel(bar,'Model');
        modelDrop = makeDropdown(bar,{'LSTM'},'LSTM','Prediction model');
        controlLabel(bar,'Day');
        dayDrop = uidropdown(bar,'Items',{'1'},'ItemsData',1,'Value',1, ...
            'BackgroundColor',C.input,'FontColor',C.text,'Tooltip','Test day');
        pb = makeButton(bar,icoPrev,'secondary','Previous day (Left arrow)');
        nb = makeButton(bar,icoNext,'secondary','Next day (Right arrow)');
        controlLabel(bar,'View');
        viewDrop = makeDropdown(bar,viewNames,S.view,'Chart view');
        uilabel(bar,'Text','');
        eb = makeButton(bar,'Export PNG','primary','Save the chart as an image');

        fcPeriodNote = uilabel(g,'Text','', ...
            'FontSize',11.5,'FontWeight','bold','FontColor',C.orange);

        metrics = uigridlayout(g,[1 4]);
        metrics.Padding = [0 0 0 0];  metrics.ColumnSpacing = 12;
        metrics.BackgroundColor = C.bg;
        fcMAE  = kpiCard(metrics,'MAE (selected day)','-',C.blue,' ');
        fcRMSE = kpiCard(metrics,'RMSE (selected day)','-',C.accent,' ');
        fcR2   = kpiCard(metrics,[R2name ' (selected day)'],'-',C.green,' ');
        fcMax  = kpiCard(metrics,'Max abs. error','-',C.orange,' ');

        bottom = uigridlayout(g,[1 2]);
        bottom.ColumnWidth = {'2x','1.2x'};  bottom.Padding = [0 0 0 0];
        bottom.ColumnSpacing = 12;  bottom.BackgroundColor = C.bg;

        forecastAxes = chartCard(bottom);

        [lg,~] = cardGrid(bottom,[2 1],[14 12 10 10]);
        lg.RowHeight = {'fit','1x'};  lg.RowSpacing = 8;
        uilabel(lg,'Text','MODEL LEADERBOARD  (all test days in category, ranked by RMSE)', ...
            'FontSize',11,'FontWeight','bold','FontColor',C.muted);
        lbTable = makeTable(lg,false);
        lbTable.ColumnName = {'#','Model','MAE','RMSE',R2name};
        lbTable.ColumnWidth = {28,'auto',58,58,58};
        lbTable.CellSelectionCallback = @onLeaderboardClick;

        categoryDrop.ValueChangedFcn = @(~,~) onCategoryChanged();
        modelDrop.ValueChangedFcn    = @(~,~) onModelChanged();
        dayDrop.ValueChangedFcn      = @(~,~) onDayChanged();
        viewDrop.ValueChangedFcn     = @(~,~) onViewChanged();
        pb.ButtonPushedFcn = @(~,~) stepDay(-1);
        nb.ButtonPushedFcn = @(~,~) stepDay(+1);
        eb.ButtonPushedFcn = @(~,~) exportAxes(forecastAxes,'forecast_chart');

        refreshForecast();
    end

    function onCategoryChanged()
        S.category = categoryDrop.Value;  S.model = '';  S.day = 1;
        refreshForecast();
    end

    function onModelChanged()
        S.model = modelDrop.Value;
        refreshForecast();
    end

    function onDayChanged()
        S.day = dayDrop.Value;
        renderForecast();
    end

    function onViewChanged()
        S.view = viewDrop.Value;
        renderForecast();
    end

    function onLeaderboardClick(~,evt)
        if isempty(evt.Indices), return; end
        row = evt.Indices(1);
        if row >= 1 && row <= numel(lbNames)
            S.model = lbNames{row};
            refreshForecast();
        end
    end

    function stepDay(delta)
        if isempty(dayDrop) || ~isvalid(dayDrop), return; end
        n = numel(dayDrop.Items);
        S.day = min(max(S.day + delta,1),n);
        dayDrop.Value = S.day;
        renderForecast();
    end

    function refreshForecast()
        updateForecastPeriodNotice();
        try
            fs = loadForecastSet(S.category);
            modelDrop.Items = fs.names;
            if ~ismember(S.model,fs.names), S.model = fs.names{1}; end
            modelDrop.Value = S.model;

            n = size(fs.actual,1);
            dayDrop.Items = fs.labels;
            dayDrop.ItemsData = 1:n;
            if S.day > n || S.day < 1, S.day = 1; end
            dayDrop.Value = S.day;

            updateLeaderboard(fs);
            renderForecast();
        catch ME
            clearForecastMetrics();
            lbTable.Data = {};
            showMessage(forecastAxes,['Forecast data error: ' ME.message],true);
            setStatus(['Forecast data error: ' ME.message]);
        end
    end

    function updateForecastPeriodNotice()
        if isempty(fcPeriodNote) || ~isvalid(fcPeriodNote), return; end
        if strcmp(S.category,'PV Forecasting')
            fcPeriodNote.Text = ['Test period notice: PV Forecasting spans Days 137' icoDash ...
                '365 (LSTM saved model), whereas Building and EV Forecasting span Days 307' icoDash '365.'];
        else
            fcPeriodNote.Text = ['Test period notice: ' S.category ' spans Days 307' icoDash ...
                '365 (separate test window from PV Forecasting Days 137' icoDash '365).'];
        end
    end

    function updateLeaderboard(fs)
        names = fs.names;  n = numel(names);
        M = zeros(n,3);
        for i = 1:n
            [M(i,1),M(i,2),M(i,3)] = computeMetrics(fs.actual(:),fs.models.(names{i})(:));
        end
        [~,ord] = sort(M(:,2),'ascend','MissingPlacement','last');
        lbNames = names(ord);
        lbTable.Data = [num2cell((1:n)'), lbNames(:), num2cell(round(M(ord,:),3))];
        removeStyle(lbTable);
        row = find(strcmp(lbNames,S.model),1);
        if ~isempty(row)
            addStyle(lbTable,uistyle('BackgroundColor',mixc(C.card,C.accent,0.25), ...
                'FontWeight','bold'),'row',row);
        end
    end

    function clearForecastMetrics()
        for h = {fcMAE,fcRMSE,fcR2,fcMax}
            h{1}.value.Text = '-';  h{1}.caption.Text = ' ';
        end
    end

    function renderForecast()
        try
            fs = loadForecastSet(S.category);
            ad = fs.actual(S.day,:);
            pd = fs.models.(S.model)(S.day,:);
            t  = (0:numel(ad)-1)*0.25;
            ax = forecastAxes;

            cla(ax);  resetAxes(ax);
            hold(ax,'on');
            switch S.view
                case 'Time series'
                    fill(ax,[t fliplr(t)],[ad fliplr(pd)],C.orange, ...
                        'FaceAlpha',0.15,'EdgeColor','none','DisplayName','Error');
                    plot(ax,t,ad,'-','LineWidth',2.2,'Color',C.blue,'DisplayName','Actual');
                    plot(ax,t,pd,'--','LineWidth',2.2,'Color',C.orange, ...
                        'DisplayName',S.model);
                    xlim(ax,[0 max(t)]);
                    xlabel(ax,'Time (hours)');  ylabel(ax,'Power (kW)');
                    loc = 'northeast';
                case 'Residual error'
                    e = ad - pd;
                    area(ax,t,e,'FaceColor',C.orange,'FaceAlpha',0.25, ...
                        'EdgeColor',C.orange,'LineWidth',1.8,'DisplayName','Actual - predicted');
                    plot(ax,[0 max(t)],[0 0],'-','Color',C.muted,'HandleVisibility','off');
                    xlim(ax,[0 max(t)]);
                    xlabel(ax,'Time (hours)');  ylabel(ax,'Error (kW)');
                    loc = 'northeast';
                case 'Actual vs predicted'
                    lo = min([ad pd]);  hi = max([ad pd]);
                    plot(ax,[lo hi],[lo hi],'--','Color',C.muted,'DisplayName','Ideal (y = x)');
                    scatter(ax,ad,pd,30,C.blue,'filled','MarkerFaceAlpha',0.7, ...
                        'DisplayName','15-min samples');
                    xlabel(ax,'Actual (kW)');  ylabel(ax,'Predicted (kW)');
                    loc = 'northwest';
            end
            hold(ax,'off');
            title(ax,sprintf('%s  |  %s  |  %s', ...
                strrep(S.category,' Forecasting',''),S.model,fs.labels{S.day}));
            styleLegend(ax,loc);

            [mae,rmse,r2,mx]     = computeMetrics(ad,pd);
            [amae,armse,ar2,amx] = computeMetrics(fs.actual(:),fs.models.(S.model)(:));
            fcMAE.value.Text  = sprintf('%.3f kW',mae);
            fcMAE.caption.Text  = sprintf('all days: %.3f kW',amae);
            fcRMSE.value.Text = sprintf('%.3f kW',rmse);
            fcRMSE.caption.Text = sprintf('all days: %.3f kW',armse);
            fcR2.value.Text   = sprintf('%.3f',r2);
            fcR2.caption.Text   = sprintf('all days: %.3f',ar2);
            fcMax.value.Text  = sprintf('%.3f kW',mx);
            fcMax.caption.Text  = sprintf('all days: %.3f kW',amx);

            updateLeaderboard(fs);
            setStatus(sprintf('Forecast: %s | %s | %s',S.category,S.model,fs.labels{S.day}));
        catch ME
            clearForecastMetrics();
            showMessage(forecastAxes,['Forecast data error: ' ME.message],true);
        end
    end

    function [mae,rmse,r2,mx] = computeMetrics(a,p)
        e = a(:) - p(:);
        mae  = mean(abs(e),'omitnan');
        rmse = sqrt(mean(e.^2,'omitnan'));
        den  = sum((a(:)-mean(a(:),'omitnan')).^2,'omitnan');
        if den > 0, r2 = 1 - sum(e.^2,'omitnan')/den; else, r2 = NaN; end
        mx = max(abs(e));
    end

    function fs = loadForecastSet(category)
        if isKey(forecastCache,category)
            fs = forecastCache(category);
            return;
        end
        models = struct();  names = {};

        switch category
            case 'PV Forecasting'
                requireFile(pvFile,'PV forecasting MAT file');
                s = load(pvFile,'lstmExperiment');
                requireField(s,'lstmExperiment');
                e = s.lstmExperiment;
                A = double(e.test_actual_kW);
                models.LSTM = double(e.test_lstm_prediction_kW);
                names = {'LSTM'};
                try
                    labels = cellstr("Test day " + string(e.test_days(:))).';
                catch
                    labels = {};
                end

            case 'Building Forecasting'
                requireFile(bldFile,'Building forecasting MAT file');
                s = load(bldFile,'experiment');
                requireField(s,'experiment');
                e = s.experiment;
                if ~isfield(e,'predictions')
                    error('Building predictions structure is missing.');
                end
                A = reshape(double(e.actual_test_kW(:)),96,[]).';
                for i = 1:numel(buildingModels)
                    m = buildingModels{i};
                    if isfield(e.predictions,m)
                        models.(m) = reshape(double(e.predictions.(m)(:)),96,[]).';
                        names{end+1} = m; %#ok<AGROW>
                    end
                end
                labels = {};

            case 'EV Forecasting'
                requireFile(evFile,'EV forecasting MAT file');
                s = load(evFile,'evExperiment');
                requireField(s,'evExperiment');
                e = s.evExperiment;
                if ~istable(e.predictions)
                    error('EV predictions are not stored as a table.');
                end
                vars = e.predictions.Properties.VariableNames;
                if ~ismember('Actual_kW',vars)
                    error('EV Actual_kW column is missing.');
                end
                A = reshape(double(e.predictions.Actual_kW(:)),96,[]).';
                for i = 1:numel(evModels)
                    m = evModels{i};  col = [m '_kW'];
                    if ismember(col,vars)
                        models.(m) = reshape(double(e.predictions.(col)(:)),96,[]).';
                        names{end+1} = m; %#ok<AGROW>
                    end
                end
                labels = {};

            otherwise
                error('Unknown forecast category.');
        end

        if isempty(names), error('No prediction models found for %s.',category); end
        if isempty(A), error('Actual data are empty.'); end
        for i = 1:numel(names)
            if ~isequal(size(models.(names{i})),size(A))
                error('Size mismatch between actual and %s predictions.',names{i});
            end
        end
        if numel(labels) ~= size(A,1)
            labels = arrayfun(@(x) sprintf('Test day %d',x),1:size(A,1), ...
                'UniformOutput',false);
        end

        fs = struct('actual',A,'models',models,'names',{names},'labels',{labels});
        forecastCache(category) = fs;
    end

    function requireFile(f,what)
        if ~isfile(f), error('%s not found.',what); end
    end

    function requireField(s,name)
        if ~isfield(s,name), error('%s structure is missing.',name); end
    end

%% ================================================================
%  3. ENERGY MANAGEMENT (MPC PIPELINE, CONSTRAINTS & STRATEGY COMPARISON)
%  ================================================================
    function buildEnergyManagement()
        g = uigridlayout(pages(3),[6 1]);
        g.RowHeight = {50,118,90,94,'1.25x','0.95x'};
        g.Padding = [0 0 0 0];  g.RowSpacing = 10;
        g.BackgroundColor = C.bg;

        numericNames = {};
        if ~isempty(mpcTable)
            isNum = varfun(@isnumeric,mpcTable,'OutputFormat','uniform');
            numericNames = mpcTable.Properties.VariableNames(isNum);
        end
        if isempty(numericNames), items = {'(no data)'}; else, items = numericNames; end
        if isempty(S.metric) || ~ismember(S.metric,items), S.metric = items{1}; end

        bar = controlBar(g,{'fit',250,'fit',160,'1x'});
        controlLabel(bar,'Metric');
        metricDrop = makeDropdown(bar,items,S.metric,'Metric to compare');
        controlLabel(bar,'Ranking');
        directionDrop = makeDropdown(bar,{'Lower is better','Higher is better'}, ...
            S.direction,'Which direction counts as better');
        uilabel(bar,'Text','Offline results only (saved CSV) - does not execute Simulink optimization.', ...
            'FontColor',C.muted,'HorizontalAlignment','right');

        % Animated MPC pipeline card
        buildMpcPipeline(g);

        % Operating Constraints row (explicit project parameters)
        cons = uigridlayout(g,[1 4]);
        cons.Padding = [0 0 0 0];  cons.ColumnSpacing = 12;
        cons.BackgroundColor = C.bg;
        kpiCard(cons,'Battery SOC range',SYS.bat_soc,C.accent,'operating constraint');
        kpiCard(cons,'Battery power limit',SYS.bat_kW,C.blue,['charge/discharge (' SYS.bat_V ')']);
        kpiCard(cons,'Grid power limit',SYS.grid_kW,C.orange,['interface ' SYS.grid_kva]);
        kpiCard(cons,'EMS interval',SYS.ems_dt,C.purple,'supervisory scheduling');

        % Strategy Comparison KPI cards
        cards = uigridlayout(g,[1 4]);
        cards.Padding = [0 0 0 0];  cards.ColumnSpacing = 12;
        cards.BackgroundColor = C.bg;
        enBest  = kpiCard(cards,'Best strategy','-',C.accent,' ');
        enValue = kpiCard(cards,'Best value','-',C.blue,' ');
        enGap   = kpiCard(cards,'Best vs worst','-',C.green,'relative difference');
        enCount = kpiCard(cards,'Strategies compared','-',C.purple,' ');
        enBest.value.FontSize = 17;

        mpcAxes = chartCard(g);

        [tg,~] = cardGrid(g,[1 1],[8 8 8 8]);
        mpcTableUI = makeTable(tg,false);
        if ~isempty(mpcTable)
            mpcTableUI.Data = mpcTable;
            mpcTableUI.ColumnName = mpcTable.Properties.VariableNames;
        end

        metricDrop.ValueChangedFcn    = @(~,~) onMetricChanged();
        directionDrop.ValueChangedFcn = @(~,~) onDirectionChanged();
        renderEnergy();
    end

    function buildMpcPipeline(parent)
        [pg,~] = cardGrid(parent,[2 1],[12 8 12 6]);
        pg.RowHeight = {'fit','1x'};  pg.RowSpacing = 2;
        uilabel(pg,'Text','CONCEPTUAL MPC OPTIMIZATION FLOW  (illustrative control pipeline; saved CSV metrics below)', ...
            'FontSize',10.5,'FontWeight','bold','FontColor',C.muted);

        mpcAnimAxes = uiaxes(pg);
        mpcAnimAxes.Color = C.card;
        mpcAnimAxes.NextPlot = 'add';
        axis(mpcAnimAxes,[0 160 0 40]);
        axis(mpcAnimAxes,'off');
        try mpcAnimAxes.Toolbar.Visible = 'off'; catch, end
        try disableDefaultInteractivity(mpcAnimAxes); catch, end

        mpcAnimDots = {};
        steps = { ...
            struct('x',4,  'w',32,'col',C.amber, 't1','1. Forecast Inputs','t2','PV, Building & EV'), ...
            struct('x',44, 'w',32,'col',C.accent,'t1','2. MPC Optimization','t2','15-min horizon & limits'), ...
            struct('x',84, 'w',32,'col',C.blue,  't1','3. Dispatch Decisions','t2','Battery & Grid refs'), ...
            struct('x',124,'w',32,'col',C.green, 't1','4. System Response','t2','SOC & Power Balance')};

        for q = 1:numel(steps)
            st = steps{q};
            rectangle(mpcAnimAxes,'Position',[st.x 7 st.w 26],'Curvature',[0.14 0.25], ...
                'EdgeColor',st.col,'FaceColor',mixc(C.card,st.col,0.09),'LineWidth',1.8);
            text(mpcAnimAxes,st.x+st.w/2,24,st.t1,'HorizontalAlignment','center', ...
                'FontSize',10.5,'FontWeight','bold','Color',C.text,'Interpreter','none');
            text(mpcAnimAxes,st.x+st.w/2,14,st.t2,'HorizontalAlignment','center', ...
                'FontSize',9.5,'Color',C.muted,'Interpreter','none');
            if q < numel(steps)
                x0 = st.x + st.w;  x1 = steps{q+1}.x;
                plot(mpcAnimAxes,[x0 x1],[20 20],'-','Color',C.grid,'LineWidth',2.2);
                d = plot(mpcAnimAxes,(x0+x1)/2,20,'o','MarkerSize',7.5, ...
                    'MarkerFaceColor',st.col,'MarkerEdgeColor',C.card,'LineWidth',1);
                mpcAnimDots{end+1} = struct('h',d,'x0',x0,'x1',x1,'y',20); %#ok<AGROW>
            end
        end
    end

    function onMetricChanged()
        S.metric = metricDrop.Value;
        S.direction = defaultDirection(S.metric);
        directionDrop.Value = S.direction;
        renderEnergy();
    end

    function onDirectionChanged()
        S.direction = directionDrop.Value;
        renderEnergy();
    end

    function d = defaultDirection(name)
        key = lower(name);
        higher = {'saving','efficien','self','renewable','coverage','utiliz','revenue','profit'};
        d = 'Lower is better';
        for i = 1:numel(higher)
            if contains(key,higher{i}), d = 'Higher is better'; return; end
        end
    end

    function renderEnergy()
        if isempty(mpcTable)
            showMessage(mpcAxes,'three_strategy_mpc_comparison.csv not found.',true);
            return;
        end
        if ~ismember(S.metric,mpcTable.Properties.VariableNames)
            showMessage(mpcAxes,'No numeric metrics available to plot.',false);
            return;
        end
        try
            vals = double(mpcTable.(S.metric)(:));
            n = numel(vals);
            first = mpcTable{:,1};
            if isnumeric(first)
                labels = arrayfun(@(i) sprintf('Strategy %d',i),1:n,'UniformOutput',false);
            else
                labels = cellstr(string(first));
            end

            lowerBetter = strcmp(S.direction,'Lower is better');
            if lowerBetter
                [best,bi] = min(vals);  worst = max(vals);
            else
                [best,bi] = max(vals);  worst = min(vals);
            end

            cla(mpcAxes);  resetAxes(mpcAxes);
            b = bar(mpcAxes,1:n,vals,0.48,'FaceColor','flat','EdgeColor','none');
            colors = repmat(mixc(C.blue,C.card,0.15),n,1);
            colors(bi,:) = C.accent;
            b.CData = colors;
            mpcAxes.XTick = 1:n;
            mpcAxes.XTickLabel = labels;
            mpcAxes.TickLabelInterpreter = 'none';
            title(mpcAxes,[strrep(S.metric,'_',' ') '  (' lower(S.direction) ')']);
            ylabel(mpcAxes,strrep(S.metric,'_',' '));
            span = max(vals) - min(0,min(vals));
            ylim(mpcAxes,[min(0,min(vals)) max(vals)+0.20*max(span,eps)]);

            for i = 1:n
                if i == bi || best == 0
                    if i == bi, txt = sprintf('%.4g\nbest',vals(i));
                    else,      txt = sprintf('%.4g',vals(i)); end
                else
                    txt = sprintf('%.4g\n%+.1f%%',vals(i),(vals(i)-best)/abs(best)*100);
                end
                text(mpcAxes,i,vals(i),txt,'HorizontalAlignment','center', ...
                    'VerticalAlignment','bottom','FontWeight','bold','Color',C.text);
            end

            enBest.value.Text    = labels{bi};
            enBest.caption.Text  = ['on ' strrep(S.metric,'_',' ')];
            enValue.value.Text   = sprintf('%.4g',best);
            enValue.caption.Text = lower(S.direction);
            if abs(worst) > 0
                enGap.value.Text = sprintf('%.1f %%',abs(worst-best)/abs(worst)*100);
            else
                enGap.value.Text = '-';
            end
            enCount.value.Text   = sprintf('%d',n);
            enCount.caption.Text = sprintf('%d numeric metrics', ...
                sum(varfun(@isnumeric,mpcTable,'OutputFormat','uniform')));

            removeStyle(mpcTableUI);
            addStyle(mpcTableUI,uistyle('BackgroundColor',mixc(C.card,C.accent,0.25), ...
                'FontWeight','bold'),'row',bi);
            setStatus(sprintf('Energy management: %s - best is %s',S.metric,labels{bi}));
        catch ME
            showMessage(mpcAxes,['Chart error: ' ME.message],true);
        end
    end

%% ================================================================
%  4. SYSTEM MONITORING (HISTORICAL GENERATED PROFILES)
%  ================================================================
    function buildMonitoring()
        g = uigridlayout(pages(4),[4 1]);
        g.RowHeight = {52,102,'1x','fit'};
        g.Padding = [0 0 0 0];  g.RowSpacing = 12;
        g.BackgroundColor = C.bg;

        bar = controlBar(g,{'fit',250,'1x',104});
        controlLabel(bar,'Profile');
        signalDrop = makeDropdown(bar,signalNames,S.signal,'Generated 24-hour signal');
        uilabel(bar,'Text','Historical generated 24h profile - NOT live telemetry (no synthetic battery SOC/grid series)', ...
            'FontColor',C.orange,'FontWeight','bold','HorizontalAlignment','right');
        eb = makeButton(bar,'Export PNG','primary','Save the chart as an image');

        stats = uigridlayout(g,[1 4]);
        stats.Padding = [0 0 0 0];  stats.ColumnSpacing = 12;
        stats.BackgroundColor = C.bg;
        moPeak   = kpiCard(stats,'Peak power','-',C.orange,' ');
        moMean   = kpiCard(stats,'Average power','-',C.blue,' ');
        moEnergy = kpiCard(stats,'Daily energy','-',C.green,' ');
        moLF     = kpiCard(stats,'Load factor','-',C.accent,'average / peak');

        monitoringAxes = chartCard(g);
        sourceLabel = uilabel(g,'Text','Source: microgrid_profiles_24h.mat (historical generated profiles)', ...
            'FontSize',11,'FontColor',C.muted);

        signalDrop.ValueChangedFcn = @(~,~) onSignalChanged();
        eb.ButtonPushedFcn = @(~,~) exportAxes(monitoringAxes,'monitoring_chart');
        renderMonitoring();
    end

    function onSignalChanged()
        S.signal = signalDrop.Value;
        renderMonitoring();
    end

    function renderMonitoring()
        try
            p = loadProfiles();
            t = p.time_hours;
            switch S.signal
                case 'PV Power',      kW = p.P_pv_W/1000;       col = C.amber;
                case 'Building Load', kW = p.P_building_W/1000; col = C.blue;
                case 'EV Load',       kW = p.P_ev_W/1000;       col = C.green;
                otherwise
                    kW = (p.P_building_W + p.P_ev_W - p.P_pv_W)/1000;  col = C.purple;
            end
            if any(~isfinite(t)) || any(~isfinite(kW))
                error('The selected profile contains invalid values.');
            end

            cla(monitoringAxes);  resetAxes(monitoringAxes);
            hold(monitoringAxes,'on');
            area(monitoringAxes,t,kW,'FaceColor',col,'FaceAlpha',0.22, ...
                'EdgeColor',col,'LineWidth',2,'HandleVisibility','off');
            [pk,pi] = max(kW);
            plot(monitoringAxes,t(pi),pk,'o','MarkerSize',9,'LineWidth',2, ...
                'MarkerFaceColor',C.card,'MarkerEdgeColor',col,'HandleVisibility','off');
            text(monitoringAxes,t(pi),pk,sprintf('  peak %.1f kW',pk), ...
                'Color',C.text,'FontWeight','bold','VerticalAlignment','bottom');
            hold(monitoringAxes,'off');
            xlim(monitoringAxes,[min(t) max(t)]);
            title(monitoringAxes,['Historical Generated Profile: ' S.signal]);
            xlabel(monitoringAxes,'Time (hours)');  ylabel(monitoringAxes,'Power (kW)');

            mins = round(mod(t(pi),24)*60);
            moPeak.value.Text   = sprintf('%.2f kW',pk);
            moPeak.caption.Text = sprintf('at %02d:%02d',floor(mins/60),mod(mins,60));
            moMean.value.Text   = sprintf('%.2f kW',mean(kW));
            moMean.caption.Text = sprintf('minimum %.2f kW',min(kW));
            E = trapz(t,kW);
            moEnergy.value.Text = sprintf('%.1f kWh',E);
            if strncmp(S.signal,'Net',3)
                if E < 0, moEnergy.caption.Text = 'net export over the day';
                else,     moEnergy.caption.Text = 'net import over the day'; end
            else
                moEnergy.caption.Text = sprintf('%d samples',numel(t));
            end
            if pk > 0
                moLF.value.Text = sprintf('%.0f %%',mean(kW)/pk*100);
            else
                moLF.value.Text = '-';
            end
            sourceLabel.Text = 'Source: microgrid_profiles_24h.mat (historical generated profiles)';
            setStatus(['Monitoring: ' S.signal]);
        catch ME
            showMessage(monitoringAxes,['Monitoring data error: ' ME.message],true);
            for h = {moPeak,moMean,moEnergy,moLF}
                h{1}.value.Text = '-';
            end
            sourceLabel.Text = ['Monitoring data error: ' ME.message];
        end
    end

    function p = loadProfiles()
        if ~isempty(profileCache), p = profileCache; return; end
        requireFile(profFile,'microgrid_profiles_24h.mat');
        s = load(profFile,'profiles');
        requireField(s,'profiles');
        p = s.profiles;
        fields = {'time_hours','P_pv_W','P_building_W','P_ev_W'};
        for i = 1:numel(fields)
            if ~isfield(p,fields{i})
                error('Profile field is missing: %s',fields{i});
            end
            p.(fields{i}) = double(p.(fields{i})(:));
        end
        n = numel(p.time_hours);
        for i = 2:numel(fields)
            if numel(p.(fields{i})) ~= n
                error('Time and %s lengths do not match.',fields{i});
            end
        end
        profileCache = p;
    end

%% ================================================================
%  5. EXPERIMENT ANALYSIS
%  ================================================================
    function integrityRow(parent,txt,ok)
        r = uigridlayout(parent,[1 2]);
        r.ColumnWidth = {24,'1x'};  r.Padding = [0 0 0 0];
        r.BackgroundColor = C.card;
        if ok, glyph = icoOK; col = C.green; else, glyph = 'x'; col = C.danger; end
        uilabel(r,'Text',glyph,'FontSize',15,'FontWeight','bold','FontColor',col);
        uilabel(r,'Text',txt,'FontSize',12.5,'FontColor',C.text);
    end

    function buildExperiment()
        g = uigridlayout(pages(5),[3 1]);
        g.RowHeight = {52,'1x',132};
        g.Padding = [0 0 0 0];  g.RowSpacing = 12;
        g.BackgroundColor = C.bg;

        bar = controlBar(g,{'fit',260,'fit','1x',130});
        controlLabel(bar,'Filter');
        filterField = uieditfield(bar,'text','Value',S.filter, ...
            'BackgroundColor',C.input,'FontColor',C.text, ...
            'Tooltip','Type to filter rows (matches any column)');
        countLabel = uilabel(bar,'Text','','FontColor',C.muted);
        uilabel(bar,'Text','Click a column header to sort', ...
            'FontColor',C.muted,'HorizontalAlignment','right');
        eb = makeButton(bar,'Export CSV','primary','Export the rows currently shown');

        mid = uigridlayout(g,[1 2]);
        mid.ColumnWidth = {'1.2x','1x'};
        mid.Padding = [0 0 0 0];  mid.ColumnSpacing = 12;
        mid.BackgroundColor = C.bg;

        [tg,~] = cardGrid(mid,[1 1],[8 8 8 8]);
        experimentTableUI = makeTable(tg,true);

        expChartAxes = chartCard(mid);

        [ig,~] = cardGrid(g,[4 1],[18 10 18 8]);
        ig.RowHeight = {'fit','fit','fit','fit'};  ig.RowSpacing = 4;
        uilabel(ig,'Text','DATA INTEGRITY','FontSize',11,'FontWeight','bold', ...
            'FontColor',C.muted);
        integrityRow(ig,'All project source files found', ...
            all(cellfun(@isfile,sources(:,2))));
        integrityRow(ig,'Forecast test periods kept separate per category (PV 137-365 vs Bldg/EV 307-365)',true);
        integrityRow(ig,'MPC data show only metrics present in three_strategy_mpc_comparison.csv',true);

        filterField.ValueChangingFcn = @(~,evt) onFilterChanging(evt);
        filterField.ValueChangedFcn  = @(src,~) onFilterChanging(struct('Value',src.Value));
        eb.ButtonPushedFcn = @(~,~) exportExperimentTable();
        applyExperimentFilter();
    end

    function onFilterChanging(evt)
        S.filter = evt.Value;
        applyExperimentFilter();
    end

    function applyExperimentFilter()
        if isempty(mpcTable)
            shownTable = table();
            countLabel.Text = 'No data loaded';
            showMessage(expChartAxes,'three_strategy_mpc_comparison.csv not found.',true);
            return;
        end
        T = mpcTable;
        q = lower(strtrim(S.filter));
        if ~isempty(q)
            rs = strings(height(T),1);
            names = T.Properties.VariableNames;
            for v = 1:numel(names)
                try rs = rs + " " + string(T.(names{v})); catch, end
            end
            T = T(contains(lower(rs),q),:);
        end
        shownTable = T;
        experimentTableUI.Data = T;
        experimentTableUI.ColumnName = T.Properties.VariableNames;
        countLabel.Text = sprintf('%d of %d rows',height(T),height(mpcTable));
        plotExperimentComparison();
    end

    function plotExperimentComparison()
        if isempty(expChartAxes) || ~isvalid(expChartAxes), return; end
        if isempty(shownTable) || height(shownTable) == 0
            showMessage(expChartAxes,'No matching rows to compare.',false);
            return;
        end
        isNum = varfun(@isnumeric,shownTable,'OutputFormat','uniform');
        numCols = shownTable.Properties.VariableNames(isNum);
        if isempty(numCols)
            showMessage(expChartAxes,'No numeric metrics in CSV table.',false);
            return;
        end
        try
            M = zeros(numel(numCols),height(shownTable));
            for c = 1:numel(numCols)
                colData = double(shownTable.(numCols{c})(:)).';
                denom = max(abs(colData));
                if denom > 0
                    M(c,:) = colData / denom;
                else
                    M(c,:) = colData;
                end
            end

            first = shownTable{:,1};
            if isnumeric(first)
                stratNames = arrayfun(@(i) sprintf('Strategy %d',i),1:height(shownTable),'UniformOutput',false);
            else
                stratNames = cellstr(string(first));
            end

            cla(expChartAxes);  resetAxes(expChartAxes);
            b = bar(expChartAxes,M,'grouped','EdgeColor','none');
            for sIdx = 1:numel(b)
                b(sIdx).FaceColor = C.palette(mod(sIdx-1,size(C.palette,1))+1,:);
                b(sIdx).DisplayName = stratNames{sIdx};
            end
            expChartAxes.XTick = 1:numel(numCols);
            expChartAxes.XTickLabel = strrep(numCols,'_',' ');
            expChartAxes.XTickLabelRotation = 18;
            expChartAxes.TickLabelInterpreter = 'none';
            ylabel(expChartAxes,'Normalized ratio (value / max |col|)');
            title(expChartAxes,'Multi-metric strategy comparison (normalized CSV values)');
            styleLegend(expChartAxes,'northeast');
        catch ME
            showMessage(expChartAxes,['Comparison chart error: ' ME.message],true);
        end
    end

    function exportExperimentTable()
        if isempty(shownTable) || height(shownTable) == 0
            uialert(fig,'There is no table data to export.','Export');
            return;
        end
        [f,p] = uiputfile('*.csv','Export Experiment Results', ...
            fullfile(dashboardFolder,'experiment_summary_export.csv'));
        figure(fig);
        if isequal(f,0), return; end
        try
            writetable(shownTable,fullfile(p,f));
            uialert(fig,sprintf('Exported %d rows to %s.',height(shownTable),f), ...
                'Export complete','Icon','success');
            setStatus(['Table exported: ' f]);
        catch ME
            uialert(fig,ME.message,'Export error');
        end
    end

%% ================================================================
%  6. ABOUT
%  ================================================================
    function buildAbout()
        g = uigridlayout(pages(6),[1 2]);
        g.Padding = [0 0 0 0];  g.ColumnSpacing = 14;  g.BackgroundColor = C.bg;

        tx = rgbHex(C.text);  mu = rgbHex(C.muted);  og = rgbHex(C.orange);
        head = ['<div style="font-family:Segoe UI,Helvetica,Arial;color:' tx ';">'];
        row = @(a,b) ['<tr><td style="padding:4px 20px 4px 0;color:' mu ';">' a ...
            '</td><td><b>' b '</b></td></tr>'];

        left = [head ...
            '<h2 style="margin:0 0 4px 0;">AI-Assisted Predictive Energy Management</h2>' ...
            '<div style="color:' mu ';margin-bottom:14px;">Grid-connected PV-Battery-EV ' ...
            'microgrid &nbsp;|&nbsp; MATLAB / Simulink &nbsp;|&nbsp; Dashboard v2.3</div>' ...
            '<p style="margin:0 0 14px 0;line-height:1.45;">This project investigates how ' ...
            'artificial intelligence-based forecasting can support predictive energy ' ...
            'management in a grid-connected PV-battery-EV microgrid. By combining electrical ' ...
            'system modelling, demand and generation forecasting, and constrained model ' ...
            'predictive control, the project explores coordinated energy scheduling under ' ...
            'realistic operating limits. The results are evaluated through comparative ' ...
            'experiments and presented in an interactive MATLAB dashboard.</p>' ...
            '<h3 style="margin:0 0 6px 0;">Project information</h3>' ...
            '<table style="margin-bottom:14px;">' ...
            row('PV forecast test days','137 - 365') ...
            row('Building / EV test days','307 - 365') ...
            row('Monitoring source','Generated 24-hour profiles') ...
            row('EMS scheduling interval',SYS.ems_dt) ...
            row('Live Simulink connection',['<span style="color:' og ';">Not implemented</span>']) ...
            '</table>' ...
            '<h3 style="margin:0 0 6px 0;">Technical system specifications (design)</h3>' ...
            '<ul style="margin:0;">' ...
            '<li>PV plant: ' SYS.pv_kWp ' &nbsp;|&nbsp; MPPT: ' SYS.pv_mppt '</li>' ...
            '<li>Battery: ' SYS.bat_kWh ', ' SYS.bat_V ', SOC ' SYS.bat_soc ', max power ' SYS.bat_kW '</li>' ...
            '<li>EV chargers: ' SYS.ev_desc '</li>' ...
            '<li>Building peak demand: ' SYS.bld_kW '</li>' ...
            '<li>DC bus: ' SYS.dc_bus '</li>' ...
            '<li>Utility grid: ' SYS.grid_v ', rating ' SYS.grid_kva ', limit ' SYS.grid_kW '</li></ul></div>'];

        right = [head ...
            '<h3 style="margin:0 0 6px 0;">Presentation mode</h3>' ...
            '<p style="margin:0 0 12px 0;line-height:1.45;">A 3-minute tour: a 60-second ' ...
            'animated, narrated introduction (problem, system, forecasting, control, results) ' ...
            'followed by the six screens at 20 seconds each. Choosing a screen manually ' ...
            'pauses the tour. Set <b>autoPlay = false</b>, <b>voiceOver = false</b>, or ' ...
            '<b>reduceMotion = true</b> at the top of the file to customize startup behavior.</p>' ...
            '<h3 style="margin:0 0 6px 0;">Keyboard shortcuts</h3>' ...
            '<ul style="margin:0 0 14px 0;"><li><b>Space</b> play / pause the tour</li>' ...
            '<li><b>1 - 6</b> jump to a screen</li>' ...
            '<li><b>PgUp / PgDn</b> previous / next screen</li>' ...
            '<li><b>Left / Right</b> previous / next forecast day</li>' ...
            '<li><b>M</b> toggle reduced motion / flow animations</li>' ...
            '<li><b>T</b> toggle light / dark theme</li>' ...
            '<li><b>I</b> replay the introduction</li>' ...
            '<li><b>V</b> voice-over on / off</li>' ...
            '<li><b>B</b> collapse / expand the sidebar</li></ul>' ...
            '<h3 style="margin:0 0 6px 0;">Data limitations</h3>' ...
            '<ul style="margin:0;">' ...
            '<li>Historical profiles are generated (synthetic) data, not live measurements.</li>' ...
            '<li>Forecasting datasets have different test periods (PV 137-365 vs Bldg/EV 307-365).</li>' ...
            '<li>MPC comparison data contain summary metrics only.</li>' ...
            '<li>Illustrative architecture scenarios and MPC animations are conceptual, not live telemetry.</li>' ...
            '<li>This dashboard does not execute Simulink models or solve optimization in real time.</li>' ...
            '<li>Battery power, grid power, and battery SOC time-series are not invented where absent.</li>' ...
            '<li>The 750 V DC bus is a provisional design value; reinforcement learning is not implemented.</li></ul></div>'];

        [cl,~] = cardGrid(g,[1 1],[24 20 24 18]);
        uilabel(cl,'Text',left,'Interpreter','html','VerticalAlignment','top','FontSize',13.5);
        [cr,~] = cardGrid(g,[1 1],[24 20 24 18]);
        uilabel(cr,'Text',right,'Interpreter','html','VerticalAlignment','top','FontSize',13.5);
    end

    function h = rgbHex(c)
        h = sprintf('#%02X%02X%02X',round(c*255));
    end

%% ================================================================
%  DATA + CLOSE
%  ================================================================
    function loadMpc()
        mpcTable = table();
        if isfile(mpcFile)
            try
                mpcTable = readtable(mpcFile);
            catch
                mpcTable = table();
            end
        end
    end

    function closeDashboard(varargin)
        stopNarration();
        if ~isempty(speaker)
            try speaker.Dispose(); catch, end
        end
        for tmr = {presTimer, animTimer}
            if ~isempty(tmr{1}) && isvalid(tmr{1})
                try stop(tmr{1}); catch, end
                delete(tmr{1});
            end
        end
        if ~isempty(fig) && isvalid(fig)
            delete(fig);
        end
    end

end