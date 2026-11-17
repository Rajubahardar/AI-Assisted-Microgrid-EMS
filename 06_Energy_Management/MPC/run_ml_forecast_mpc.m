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
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));