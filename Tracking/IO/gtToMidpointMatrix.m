function [midpointMatrix, midpointToGtMapping, orientationMatrix] = ...
    gtToMidpointMatrix(filenameInput, filenameOutput, restrictToX, restrictToY)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
arguments
    filenameInput char
    filenameOutput char = 'midpointMatrix.mat'
    restrictToX (1, 2) double = [0.388, 0.788] % Either belt borders of field of view
    restrictToY (1, 2) double = [0, 0.18]
end

listOfVariables = who('-file', filenameInput);
if ~ismember(listOfVariables, 'pos')
    error('Format not compatible.')
elseif ~ismember(listOfVariables, 'rotz')
    convertRotz = false;
    load(filenameInput, 'pos');
    if nargin == 3
        warning('Requested orientationmatrix but there is no data for it');
    end
else
    convertRotz = true;
    load(filenameInput, 'pos', 'rotz');
end


currentlyOnBelt = squeeze( ...
    pos(1, :, :) > restrictToX(1) ...
    & pos(1, :, :) < restrictToX(2) ...
    & pos(2, :, :) > restrictToY(1) ...
    & pos(2, :, :) < restrictToY(2));


numberOfMidpoints = sum(currentlyOnBelt, 2);
midpointMatrix = NaN(2, max(numberOfMidpoints), numel(numberOfMidpoints));
if convertRotz
    orientationMatrix = NaN(max(numberOfMidpoints), numel(numberOfMidpoints));
else
    orientationMatrix = [];
end
for t = 1:numel(numberOfMidpoints)
    midpointMatrix(:, 1:numberOfMidpoints(t), t) = pos(1:2, t, currentlyOnBelt(t, :));
    if convertRotz
        orientationMatrix(1:numberOfMidpoints(t), t) = rotz(t, currentlyOnBelt(t, :));
    end
    % Assert that everything we have saved is valid
    assert(~any(any(any(isnan(midpointMatrix(:, 1:numberOfMidpoints(t), t))))));
    if convertRotz
        assert(~any(any(isnan(orientationMatrix(1:numberOfMidpoints(t), t)))));
    end
end
midpointToGtMapping = NaN(max(numberOfMidpoints), numel(numberOfMidpoints));
for t = 1:numel(numberOfMidpoints)
    midpointIDs = find(currentlyOnBelt(t, :));
    midpointToGtMapping(1:numel(midpointIDs), t) = midpointIDs;
end

assert(isequal(isnan(midpointToGtMapping), isnan(squeeze(midpointMatrix(1, :, :)))));
save(filenameOutput, 'numberOfMidpoints', 'midpointMatrix', 'midpointToGtMapping', 'orientationMatrix');

end