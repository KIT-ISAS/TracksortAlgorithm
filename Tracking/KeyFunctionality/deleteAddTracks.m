function [allTracks, trackHistory, nextID] = ...
    deleteAddTracks(t, allTracks, trackHistory, newTrackMeasurements, ...
    deleteTrackList, initialParam, scoreParam, predictParam, nextID, currVelocityGuess, currVelocityVar, currMeasurements)
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021
currMidpoints = currMeasurements.midpoints;
assert(isempty(currMidpoints) || all(~isnan(currMidpoints(:))));
if isfield(currMeasurements, 'orientations')
    currOrientations = currMeasurements.orientations;
    assert(all(~isnan(currOrientations)));
    useOrientation = true;
else
    useOrientation = false;
end
if isfield(currMeasurements, 'visualClassifications')
    currVisualClassifications = currMeasurements.visualClassifications;
else
    currVisualClassifications = [];
end

%% delete lost tracks and add new ones
previousAmountOfTracks = size(allTracks, 2);
if ~isempty(deleteTrackList)
    [trackHistory([allTracks(deleteTrackList).ID]).LastAngle] = allTracks(deleteTrackList).Angle; % save last angle for each track
    [trackHistory([allTracks(deleteTrackList).ID]).LastVelocity] = allTracks(deleteTrackList).Velocity; % save last velocity for each track
    posteriorCell = {trackHistory([allTracks(deleteTrackList).ID]).Posterior};
    endtimesCell = num2cell([trackHistory([allTracks(deleteTrackList).ID]).StartTime] ...
        +cellfun(@(x) size(x, 2), posteriorCell)-1);
    [trackHistory([allTracks(deleteTrackList).ID]).EndTime] = endtimesCell{:};
    % Calculate when last measurement was obtained (measIndex~=-1)
    lastSeenTimesCell = num2cell([trackHistory([allTracks(deleteTrackList).ID]).StartTime] ...
        +arrayfun(@(delIndex)find(trackHistory(allTracks(delIndex).ID).MeasIndex ~= -1, 1, 'last'), deleteTrackList) ...
        -1);
    [trackHistory([allTracks(deleteTrackList).ID]).LastSeenTime] = lastSeenTimesCell{:};
    allTracks(deleteTrackList) = [];
end

for i = newTrackMeasurements
    if useOrientation
        currOrientationFilter = eval(initialParam.OrientationFilterString);
        initOrientation = currOrientations(i);
        currOrientationFilter.setState(initialParam.OrientationNoise.shift(initOrientation));
    else
        currOrientationFilter = [];
        initOrientation = [];
    end
    if ~isempty(currVisualClassifications)
        initVisualClassification = currVisualClassifications(:, i);
    else
        initVisualClassification = [];
    end
    switch predictParam.model
        case 'ConstantVelocityWithAngle'
            fullState = currMidpoints(:, i);
            fullStateCov = initialParam.PositionCov;
        case 'ConstantVelocity'
            fullState = [currMidpoints(1, i); 0; ... %assuming 0
                currMidpoints(2, i); currVelocityGuess(1)]; %currVelocityGuess(2) % assuming 0
            % Assuming matrix is diagonal at initialization
            fullStateCov = blkdiag(initialParam.PositionCov(1, 1), ...
                currVelocityVar, initialParam.PositionCov(2, 2), ...
                currVelocityVar);
        case 'WhiteNoiseJerk'
            fullState = [currMidpoints(1, i); currVelocityGuess(1); 0; ...
                currMidpoints(2, i); 0; 0]; %currVelocityGuess(2)
            fullStateCov = blkdiag(initialParam.PositionCov(1, 1), ...
                currVelocityVar, initialParam.AccelerationCov(1, 1), initialParam.PositionCov(2, 2), ...
                currVelocityVar, initialParam.AccelerationCov(1, 2));
    end


    allTracks(length(allTracks)+1) = struct('ID', nextID, 'Position', currMidpoints(:, i), ...
        'PositionCov', initialParam.PositionCov, 'Angle', initialParam.AngleGuess, ...
        'AngleVar', initialParam.AngleVar, 'Velocity', currVelocityGuess, 'VelocityVar', currVelocityVar, ...
        'FullState', fullState, 'FullStateCov', fullStateCov, ...
        'Length', [], 'Width', [], ...
        'TrackScore', scoreParam.initialScore, 'OrientationFilter', currOrientationFilter);
    trackHistory(nextID) = struct('Posterior', allTracks(length(allTracks)).Position, ...
        'RawMeasurements', [currMidpoints(1+2*(i - 1)); currMidpoints(2+2*(i - 1))], ...
        'RawOrientations', initOrientation, 'MeasIndex', i, ...
        'Prediction', [NaN; NaN], ... % Initialized using NaN because no prediction in first time step
        'PredictedX', NaN, 'LinePredictedX', NaN, ...
        'LastAngle', NaN, 'LastVelocity', NaN, 'StartTime', t, 'EndTime', NaN, 'LastSeenTime', NaN, 'TrueIntersection', NaN, ...
        'Lengths', [], 'Widths', [], 'PredictedIntersectionTime', NaN, 'LinepredictedIntersectionTime', NaN, ...
        'OrientationEstimates', mod(initOrientation, 2*pi), 'VisualClassifications', initVisualClassification);
    nextID = nextID + 1;
end
assert(length(allTracks) == previousAmountOfTracks-length(deleteTrackList)+length(newTrackMeasurements)) %verify that new number of tracks is correct
