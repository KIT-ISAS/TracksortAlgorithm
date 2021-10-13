function [allTracks, trackHistory, lastHundredVelocities] = ...
    updateGAL(t, measParam, allTracks, trackHistory, bestPerm, ...
    allTracksBeforePredict, lastHundredVelocities, deleteTrackList, disapearedTracks, currMeasurements)
% Update based on the global association likelihood
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021
arguments
    t (1, 1) double
    measParam (1, 1) struct
    allTracks (1, :) struct
    trackHistory (1, :) struct
    bestPerm (1, :) double{mustBeInteger, mustBePositive}
    allTracksBeforePredict( 1, :) struct
    lastHundredVelocities (1, 100) double
    deleteTrackList (1, :) double
    disapearedTracks (1, :) double
    currMeasurements (1, 1) struct
end
currentMidpoints = currMeasurements.midpoints;
stateDim = size(allTracks(1).FullState, 1);

%% update persisting tracks, produce mean (heuristic)
for trackNo = setdiff(1:length(allTracks), union(deleteTrackList, disapearedTracks))
    associatedTo = bestPerm(trackNo);
    measurement = [currentMidpoints(1+2*(associatedTo - 1)); currentMidpoints(2+2*(associatedTo - 1))];

    if isequal(measParam.model, 'ConstantVelocityWithAngle')
        allTracks(trackNo) = updatePosition(allTracks(trackNo), measParam.PositionCov, measurement);
        posChange = allTracksBeforePredict(trackNo).Position - allTracks(trackNo).Position;

        allTracks(trackNo) = updateAngle(allTracks(trackNo), measParam.AngleVar, posChange);
        [allTracks(trackNo), lastHundredVelocities] = updateVelocity(allTracks(trackNo), lastHundredVelocities, measParam.VelocityVar, posChange);
    else % All other models provide H
        H = measParam.H;
        K = allTracks(trackNo).FullStateCov * H' / (measParam.PositionCov * eye(2) + H * allTracks(trackNo).FullStateCov * H');
        allTracks(trackNo).FullState = (eye(stateDim) - K * H) * allTracks(trackNo).FullState + K * measurement;
        allTracks(trackNo).FullStateCov = allTracks(trackNo).FullStateCov - K * H * allTracks(trackNo).FullStateCov;

        allTracks(trackNo).Position = allTracks(trackNo).FullState([1, stateDim / 2 + 1]);
    end

    rawMeas = [currentMidpoints(1+2*(associatedTo - 1)); currentMidpoints(2+2*(associatedTo - 1))];

    if isfield(currMeasurements, 'visualClassifications')
        currVisualClassification = currMeasurements.visualClassifications(:, associatedTo);
    else
        currVisualClassification = [];
    end
    % Store size
    if isfield(currMeasurements, 'sizes')
        allTracks(trackNo).Length = currMeasurements.sizes(1, associatedTo);
        allTracks(trackNo).Width = currMeasurements.sizes(2, associatedTo);
    end
    % Save prediction
    prediction = allTracks(trackNo).Position;
    % Update orientation
    if isfield(currMeasurements, 'orientations')
        allTracks(trackNo).OrientationFilter.updateIdentity(measParam.OrientationNoise, currMeasurements.orientations(associatedTo));
        trackHistory(allTracks(trackNo).ID) = saveTrack(allTracks(trackNo), trackHistory(allTracks(trackNo).ID), t, rawMeas, ...
            currMeasurements.orientations(associatedTo), currVisualClassification, associatedTo, prediction);
    else
        trackHistory(allTracks(trackNo).ID) = saveTrack(allTracks(trackNo), trackHistory(allTracks(trackNo).ID), t, rawMeas, ...
            [], currVisualClassification, associatedTo, prediction);
    end

end
for trackNo = disapearedTracks
    rawMeas = NaN(2, 1);
    trackIndex = NaN;
    trackOrientation = NaN;
    prediction = allTracks(trackNo).Position;
    visualClassification = NaN;
    trackHistory(allTracks(trackNo).ID) = saveTrack(allTracks(trackNo), trackHistory(allTracks(trackNo).ID), t, rawMeas, trackOrientation, visualClassification, trackIndex, prediction);
end
end
