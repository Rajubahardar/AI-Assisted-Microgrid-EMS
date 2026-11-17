% Inspection script for Integrated Microgrid 24H model
% Derive project root relative to script location for portability
projectRoot = fileparts(mfilename('fullpath'));
if ~ismember(projectRoot, path)
    addpath(projectRoot);
end

% Open the 24H model using absolute project-relative path
model = open_system(fullfile(projectRoot, '03_Simulink_Models', 'Integrated_Microgrid', 'Integrated_Microgrid_24H.slx'));

% Get model information
fprintf('=== Model Name: %s\n', model.Name);

% Get subsystem hierarchy
model_name = 'Integrated_Microgrid_24H';
sys = slLinearizer(model_name); % or just use get_param

% Get sample times
sample_times = get_param(model, 'SampleTime');
fprintf('Sample time: %s\n', mat2str(sample_times));

% Get solver info
solvertype = get_param(model, 'SolverType');
fprintf('Solver: %s\n', solvertype);

% Get stop time
stop_time = get_param(model, 'StopTime');
fprintf('Stop time: %s\n', stop_time);

% List all blocks and their connections
blocks = find_system(model, 'Type', 'Block');
fprintf('Number of blocks: %d\n', length(blocks));

% Print block paths
for i = 1:length(blocks)
    block_path = get_param(blocks{i}, 'Path');
    block_type = get_param(blocks{i}, 'BlockType');
    fprintf('Block %d: %s (%s)\n', i, block_path, block_type);
end

% Check for EMS subsystem
ems_subsys = find_system(model, 'Path', '*EMS*');
fprintf('EMS subsystems found: %d\n', length(ems_subsys));

% Check for rule-based EMS
rule_blocks = find_system(model, 'Path', '*rule_based*');
fprintf('Rule-based blocks: %d\n', length(rule_blocks));

% Get parameter settings
fprintf('\n=== Parameter Settings ===\n');
fprintf('P_batt_max: %g\n', get_param([model '/Battery'], 'P_batt_max'));

% Close the model
close_system(model);
fprintf('\nInspection complete.\n');