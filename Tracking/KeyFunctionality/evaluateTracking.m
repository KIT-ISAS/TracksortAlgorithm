function [trackHistory, predictErrorTracksort, predictErrorTracksortTime, predictErrorLine, predictErrorLineTime] = evaluateTracking(trackHistory, predictOnlyStart, band_edge, resolution)
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021

%% evaluate precision
edge = [resolution(1, 2), band_edge];
predictErrorTracksort = [];
predictErrorLine = [];
predictErrorTracksortTime = [];
predictErrorLineTime = [];
%calculate predicted tracks for rmse and for line camera prediction
nTrucks_statistik = 0;
for i = 1:length(trackHistory) %necessary to count for adding track history
    track = trackHistory(i);
    if isnan(track.StartTime), continue; end
    TrackStartTime = track.StartTime; %track.LastSeenTime - length(track.Posterior);
    earlyStart = (length(find(track.Posterior(2, :) < predictOnlyStart)) < 5) && (TrackStartTime < 10); % check if ther is enouph measurments before prediction
    if ~isempty(track.PredictedX) && track.Posterior(2, end) > edge(2) && ~isnan(track.PredictedX) && ~isnan(track.LastSeenTime) && ~earlyStart
        nTrucks_statistik = nTrucks_statistik + 1;
        ind = find(track.Posterior(2, :) > edge(2), 1) - 1; % -1 to index direktly before the edge.
        closeProjectionOfPos = track.Posterior(:, ind+1);
        [approxTrueIntersection(1), approxTrueIntersection(2)] = polyxpoly([track.Posterior(1, ind), closeProjectionOfPos(1)], [track.Posterior(2, ind), closeProjectionOfPos(2)], [-50, edge(1) + 50], [edge(2), edge(2)]);
        partTimeAfterComma = sqrt((approxTrueIntersection(1) - track.Posterior(1, ind))^2+(approxTrueIntersection(2) - track.Posterior(2, ind))^2) / sqrt((track.Posterior(1, ind+1) - track.Posterior(1, ind))^2+(track.Posterior(2, ind+1) - track.Posterior(2, ind))^2);
        approxTrueIntersectionTime = (TrackStartTime + ind) - 1 + partTimeAfterComma; % the time direktly before the edge + remain part
        if ~isempty(approxTrueIntersection(1))
            trackHistory(i).TrueIntersection = approxTrueIntersection(1);
            predictErrorTracksort = [predictErrorTracksort, track.PredictedX - approxTrueIntersection(1)]; %#ok<AGROW>
            predictErrorTracksortTime = [predictErrorTracksortTime, track.PredictedIntersectionTime - approxTrueIntersectionTime];
            predictErrorLine = [predictErrorLine, track.LinePredictedX - approxTrueIntersection(1)]; %#ok<AGROW>
            predictErrorLineTime = [PredictErrorLineTime, track.LinepredictedIntersectionTime - approxTrueIntersectionTime];
        else
            warning('Track not used in accuracy comparison because no intersection found');
        end
    end
end
fprintf('number of tracks: %5G\n', nTrucks_statistik)
rmsetracksortpx = sqrt(mean(predictErrorTracksort.^2)); fprintf('RMSE Tracksort in Pixels: %5Gpx\n', rmsetracksortpx) % They are given names so saving workspace is more complete
rmselinepx = sqrt(mean(predictErrorLine.^2)); fprintf('RMSE Line Prediction in Pixels: %5Gpx\n', rmselinepx)

rmsetracksortTime = sqrt(mean(predictErrorTracksortTime.^2)); fprintf('RMSE Tracksort in time unit: %5G\n', rmsetracksortTime) % They are given names so saving workspace is more complete
rmseLineTime = sqrt(mean(predictErrorLineTime.^2)); fprintf('RMSE Line Prediction in time unit: %5G\n', rmseLineTime) % They are given names so saving workspace is more complete

end