function [numberOfMidpoints, midpointMatrix, sizeMatrix] = readIOSBData_dat(filePath)
% @author Juan Hussain
% @date 2015
linesCell = importdata(filePath);
for i = 1:length(linesCell)
    line = linesCell{i};
    startInd = strfind(line, '{');
    line = strsplit(strtrim(regexprep(line(startInd:end), '[{,}]', ' ')));
    linesCell{i} = str2double(line);
end
numberOfMidpoints = cellfun(@length, linesCell) / 2;
maxsize = max(numberOfMidpoints) * 2;
fcn = @(x) [x, nan(1, maxsize-numel(x))];
linesCell = cellfun(fcn, linesCell, 'UniformOutput', false);
midpointMatrix = cell2mat(linesCell);
sizeMatrix = [];
end