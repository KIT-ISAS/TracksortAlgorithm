function  assignmentSolver =  try2useMexAssSol()
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
warningSetting=[warning('off','MATLAB:dispatcher:pathWarning'),warning('off','MATLAB:mpath:nameNonexistentOrNotADirectory')];
addpath(fullfile('..','AssignmentProblemSolver','LAPJV Mex'));
addpath(fullfile('..','..','AssignmentProblemSolver','LAPJV Mex'));
warning(warningSetting);
if exist('lapjvMex')==3 %#ok<EXIST>
    assignmentSolver='lapjvMex';
else
    assignmentSolver='lapjvMatlab';
    warning('Cannot find mex version of lapjv, falling back to Matlab implementation.');
end