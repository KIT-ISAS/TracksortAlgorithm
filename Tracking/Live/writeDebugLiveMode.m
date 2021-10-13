function writeDebugLiveMode(trackHistory, liveParams)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
wasPredicted = ~isnan([trackHistory.PredictedX]);
hasEnded = ~isnan([trackHistory.EndTime]);
tracksToSave = trackHistory(wasPredicted & hasEnded);

mostFreqId = cellfun(@(cell)mode(cell(2, :)), {tracksToSave.VisualClassifications});
lastSeenTimes = liveParams.timeStepMultiplier * [tracksToSave.LastSeenTime];
predictedTimes = liveParams.timeStepMultiplier * [tracksToSave.PredictedIntersectionTime];
predictedPosOrth = [tracksToSave.PredictedX];

lastSeenTimesRelative = [tracksToSave.LastSeenTime] - [tracksToSave.StartTime] + 1;
lastPosAlong = zeros(size(lastSeenTimes));
lastPosOrth = zeros(size(lastSeenTimes));
for i = 1:numel(tracksToSave)
    lastPosAlong(i) = tracksToSave(i).Posterior(2, lastSeenTimesRelative(i));
    lastPosOrth(i) = tracksToSave(i).Posterior(1, lastSeenTimesRelative(i));
end

file = fopen(liveParams.debugPath, 'w');
fprintf(file, 'mostFreqID\tLastSeenTime\tLastPosAlong\tLastPosOrth\tPredictedTime\tPredictedPosOrth\n');
fprintf(file, '%d\t%15.15G\t%15.15G\t%15.15G\t%15.15G\t%15.15G\n', ...
    [mostFreqId; lastSeenTimes; lastPosAlong; lastPosOrth; predictedTimes; predictedPosOrth]);
fclose(file);
end