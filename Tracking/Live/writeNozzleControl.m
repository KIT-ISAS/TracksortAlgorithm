function nozzleControlWithID = writeNozzleControl(trackHistory, liveParams)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% Supports middle-left-right mode considering the sizes or legacy mode
% that outputs the best two with identical sizes for all particles.
arguments
    trackHistory (1, :) struct
    liveParams (1, 1) struct
end

predictionValid = ~isnan([trackHistory.PredictedX]) & ~isnan([trackHistory.PredictedIntersectionTime]);
mostFreqLabel = cellfun(@(cell)mode(cell(1, :)), {trackHistory.VisualClassifications});
shouldBeTargeted = ismember(mostFreqLabel, liveParams.visualIDsToTarget);

trackHistoryToTargetValidPred = trackHistory(predictionValid & shouldBeTargeted);
if isempty(trackHistoryToTargetValidPred)
    [predictedTime, nozzleMiddle, nozzleLeft, nozzleRight, activationDuration, nozzle1, nozzle2] = deal([]);
else
    nozzleBorders = linspace(liveParams.nozzleLimits(1), liveParams.nozzleLimits(2), liveParams.noNozzles+1);
    nozzleMidToBorderDist = 0.5 * (nozzleBorders(2) - nozzleBorders(1));
    nozzleCenters = nozzleBorders(1:end-1) + nozzleMidToBorderDist;

    predictedPositions = [trackHistoryToTargetValidPred.PredictedX]';
    predictedTime = [trackHistoryToTargetValidPred.PredictedIntersectionTime]' * liveParams.timeStepMultiplier;

    if liveParams.nozzleMiddleLeftRightOutput
        sizesAlongTransportDirection = cellfun(@(lenghts)lenghts(find(~isnan(lenghts), 1, 'last')), {trackHistoryToTargetValidPred.Lengths})';
        sizesOrthogonalToTransportDirection = cellfun(@(widths)widths(find(~isnan(widths), 1, 'last')), {trackHistoryToTargetValidPred.Widths})';
        % This formula comes from the settings in the experimental setup.
        activationDuration = (ceil(sizesAlongTransportDirection*1000/4.8) * 4.8 + 3.3) / 1000;
    else
        sizesOrthogonalToTransportDirection = 2 * liveParams.radiusTargetedParticles * ones(numel(trackHistoryToTargetValidPred), 1);
    end

    distPredNozzleCenter = abs(predictedPositions-nozzleCenters);
    [distsSorted, ranking] = sort(distPredNozzleCenter, 2);

    % Always use best nozzle as the one in the middle
    if liveParams.nozzleMiddleLeftRightOutput
        nozzleMiddle = ranking(:, 1);
        nozzleLeft = (ranking(:, 2) == (nozzleMiddle - 1) & (distsSorted(:, 2) < sizesOrthogonalToTransportDirection / 2 + nozzleMidToBorderDist) | ...
            ranking(:, 3) == (nozzleMiddle - 1) & (distsSorted(:, 3) < sizesOrthogonalToTransportDirection / 2 + nozzleMidToBorderDist)) .* (nozzleMiddle - 1);
        nozzleRight = (ranking(:, 2) == (nozzleMiddle + 1) & (distsSorted(:, 2) < sizesOrthogonalToTransportDirection / 2 + nozzleMidToBorderDist) | ...
            ranking(:, 3) == (nozzleMiddle + 1) & (distsSorted(:, 3) < sizesOrthogonalToTransportDirection / 2 + nozzleMidToBorderDist)) .* (nozzleMiddle + 1);
    else
        nozzle1 = ranking(:, 1);
        nozzle2 = ranking(:, 2) .* (distsSorted(:, 2) < sizesOrthogonalToTransportDirection / 2 + nozzleMidToBorderDist);
    end
end
if liveParams.nozzleMiddleLeftRightOutput
    nozzleControlTable = table(predictedTime, nozzleMiddle, nozzleLeft, nozzleRight, activationDuration);
else
    nozzleControlTable = table(predictedTime, nozzle1, nozzle2);
end
writetable(nozzleControlTable, liveParams.duesenOutputPath);

nozzleControlWithID = nozzleControlTable; % For output
nozzleControlWithID.ID = cellfun(@(cell)mode(cell(2, :)), {trackHistoryToTargetValidPred.VisualClassifications})';
end