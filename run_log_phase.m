
%% PRE-RUN CHECK AND EXECUTION SCRIPT
% Project: AI-Assisted Microgrid EMS
% MATLAB release: R2024b

clc;

fprintf('\n========================================\n');
fprintf('  LOG_PHASE PRE-RUN CHECK\n');
fprintf('========================================\n\n');

%% CHECK 1: MATLAB VERSION

fprintf('1. Checking MATLAB version...\n');

matlabRelease = version('-release');
fprintf('   Detected MATLAB release: %s\n', matlabRelease);
if ~any(strcmpi(matlabRelease,{'2024b','R2024b'}))
    warning('Unexpected MATLAB release: %s',matlabRelease);
end
%% CHECK 2: PROJECT ROOT

fprintf('\n2. Checking project directory...\n');

% Derive project root relative to script location for portability
projectRoot = fileparts(mfilename('fullpath'));

if ~isfolder(projectRoot)
    error('Project folder not found: %s',projectRoot);
end

fprintf('   Project folder exists.\n');

%% CHECK 3: DOCUMENTATION GENERATOR FILE

fprintf('\n3. Checking log_phase.m...\n');

generatorFile = fullfile(projectRoot,'log_phase.m');

if ~isfile(generatorFile)
    error('log_phase.m was not found in the project folder.');
end

fprintf('   log_phase.m found.\n');

%% CHECK 4: MATLAB FUNCTION RECOGNITION

fprintf('\n4. Checking MATLAB function recognition...\n');

addpath(projectRoot);
rehash;

functionLocation = which('log_phase');

if isempty(functionLocation)
    error('MATLAB cannot recognize log_phase.m.');
end

fprintf('   MATLAB recognizes: %s\n',functionLocation);

%% CHECK 5: STATIC CODE ANALYSIS

fprintf('\n5. Checking MATLAB code...\n');

checkcode(generatorFile);

fprintf(['   Static code analysis completed.\n' ...
    '   Review any warnings displayed above.\n']);

%% CHECK 6: CONFIGURATION AVAILABILITY

fprintf('\n6. Checking configuration variable...\n');

if ~exist('cfg','var')
    error(['Configuration variable cfg is missing.\n' ...
        'Run your configuration code before this script.']);
end

if ~isstruct(cfg)
    error('cfg must be a MATLAB structure.');
end

fprintf('   Configuration structure found.\n');

%% CHECK 7: PROJECT ROOT IN CONFIGURATION

fprintf('\n7. Checking configuration project_root...\n');

if ~isfield(cfg,'project_root') || isempty(cfg.project_root)
    error('cfg.project_root is missing or empty.');
end

cfg.project_root = char(string(cfg.project_root));

if ~isfolder(cfg.project_root)
    error('Configured project_root does not exist.');
end

fprintf('   Configured project root exists.\n');

%% CHECK 8: OPTIONAL TEXT FIELDS

fprintf('\n8. Checking optional text fields...\n');

textFields = {'results','limitations'};

for k = 1:numel(textFields)

    fieldName = textFields{k};

    if ~isfield(cfg,fieldName) || isempty(cfg.(fieldName))
        cfg.(fieldName) = {};
    elseif ischar(cfg.(fieldName))
        cfg.(fieldName) = {cfg.(fieldName)};
    elseif isstring(cfg.(fieldName))
        cfg.(fieldName) = cellstr(cfg.(fieldName));
    elseif ~iscell(cfg.(fieldName))
        error('cfg.%s must be text or a cell array of text.',fieldName);
    end

end

fprintf('   Optional text fields checked.\n');

%% CHECK 9: OPTIONAL FIGURE DATA

fprintf('\n9. Checking figure configuration...\n');

if isfield(cfg,'figures') && ~isempty(cfg.figures)

    if ~isstruct(cfg.figures)
        error('cfg.figures must be a structure array.');
    end

    for k = 1:numel(cfg.figures)

        f = cfg.figures(k);

        if ~all(isfield(f,{'x','y','name'}))
            warning('Figure %d is missing x, y, or name.',k);
            continue;
        end

        if ~isnumeric(f.x) || ~isnumeric(f.y)
            warning('Figure %d has nonnumeric x or y data.',k);
            continue;
        end

        if numel(f.x) ~= numel(f.y)
            warning('Figure %d has different x and y lengths.',k);
            continue;
        end

        if isempty(f.x) || isempty(f.y) || ...
                any(~isfinite(f.x(:))) || any(~isfinite(f.y(:)))
            warning('Figure %d contains empty or nonfinite data.',k);
            continue;
        end

        fprintf('   Figure %d data passed basic checks.\n',k);

    end

else
    fprintf('   No figures supplied. Skipping figure data checks.\n');
end

%% CHECK 10: OPTIONAL SIMULINK MODEL

fprintf('\n10. Checking Simulink model...\n');

if isfield(cfg,'model') && ~isempty(cfg.model)

    modelPath = char(string(cfg.model));

    if ~isfile(modelPath)
        modelPath = fullfile(cfg.project_root,modelPath);
    end

    if ~isfile(modelPath)
        error('Configured Simulink model file was not found: %s', ...
            char(string(cfg.model)));
    end

    fprintf('   Model file exists: %s\n',modelPath);

else
    fprintf('   No model specified. Skipping model check.\n');
end

%% FINAL CHECK AND EXECUTION

fprintf('\n========================================\n');
fprintf('  PRE-RUN CHECKS COMPLETED\n');
fprintf('========================================\n');

answer = input('Do you want to run log_phase(cfg)? (Y/N): ','s');

if strcmpi(strtrim(answer),'Y')

    fprintf('\nStarting documentation generation...\n\n');

    result = log_phase(cfg);

    fprintf('\n========================================\n');
    fprintf('  DOCUMENTATION GENERATION FINISHED\n');
    fprintf('========================================\n');

    disp(result);

else

    fprintf('\nExecution cancelled. No documentation run requested.\n');

end
