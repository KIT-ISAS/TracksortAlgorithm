function [numberOfMidpoints, midpointMatrix, sizeMatrix] = readIOSBData_seq(filePath)

% read in midpoint data
fullTable = readtable(filePath); %read in data as table
% convert midpoint for further use
fullTableMatrix = table2array(fullTable);
% numberOfMidpoints
frameNr = 0;
n = 0;
for i = 1:size(fullTableMatrix, 1)
    if frameNr == fullTableMatrix(i, 1)
        n = n + 1;
    else
        numberOfMidpoints(frameNr+1) = n; %#ok<AGROW> 
        n = 1;
        frameNr = frameNr + 1;
    end
end
numberOfMidpoints(frameNr+1) = n;
numberOfMidpoints = numberOfMidpoints';
% midpointMatrix
midpointMatrix = NaN(length(numberOfMidpoints), max(numberOfMidpoints)*2);
sizeMatrix = NaN(length(numberOfMidpoints), max(numberOfMidpoints)*2);
ParticleID = 1;
for row = 1:length(numberOfMidpoints)
    for particle = 1:numberOfMidpoints(row)
        midpointMatrix(row, particle*2-1:particle*2) = fullTableMatrix(ParticleID, ~cellfun(@isempty, regexp(fullTable.Properties.VariableNames, '\<Midpoint'))); %midpoints are contained rows whose name match the regexp
        particle_size = fullTableMatrix(ParticleID, ~cellfun(@isempty, regexp(fullTable.Properties.VariableNames, '(?i)\<length|(?i)\<width'))); %size are contained rows whose name match the regexp
        ParticleID = ParticleID + 1;
    end
end
if ~any(find(~isnan(sizeMatrix)))
    sizeMatrix = [];
end
end