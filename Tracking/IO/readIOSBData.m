function [numberOfMidpoints, midpointMatrix, sizeMatrix] = readIOSBData(filePath)
% @author Florian Pfaff
% @date 2014-2021

% read in midpoint data
fullTable = readtable(filePath);
% convert midpoint for further use
fullTableMatrix = table2array(fullTable);
numberOfMidpoints = fullTableMatrix(:, 2);
isMidpoint = ~cellfun(@isempty, regexp(fullTable.Properties.VariableNames, '\<MidPoint'));
if ~any(isMidpoint)
    error('No midpoints detected. Make sure that you have column names and that the columns are correctly named (first line of the csv file)!');
end
midpointMatrix = fullTableMatrix(:, isMidpoint); %midpoints are contained rows whose name match the regexp
sizeMatrix = fullTableMatrix(:, ~cellfun(@isempty, regexp(fullTable.Properties.VariableNames, '(?i)\<length|(?i)\<width'))); %size are contained rows whose name match the regexp

midpointMatrix = reshape(midpointMatrix', [2, size(midpointMatrix, 2) / 2, size(midpointMatrix, 1)]);
end