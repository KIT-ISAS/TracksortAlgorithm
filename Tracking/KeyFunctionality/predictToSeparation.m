function trackHistory = predictToSeparation(t, allTracks, trackHistory, deleteTrackList, edge, predictOnlyStart, currVelocityGuess, predictionParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021
assert(predictOnlyStart < edge(2), 'Under the current assumption about the transport direction, the prediction start and position of the array of nozzles are incompatible');
rotmat = @(ang)[cos(ang), -sin(ang); sin(ang), cos(ang)];

for i = setdiff(1:length(allTracks), deleteTrackList)
    if (allTracks(i).Position(2) > predictOnlyStart) && ... % Has passed edge to prediction phase
            (trackHistory(allTracks(i).ID).Posterior(2, 1) < predictOnlyStart) && ... % Has started before beginning of prediction phase
            (isempty(trackHistory(allTracks(i).ID).PredictedX) || isnan(trackHistory(allTracks(i).ID).PredictedX)) && ... % Does not have a prediction using predictive tracking
            (isempty(trackHistory(allTracks(i).ID).LinePredictedX) || isnan(trackHistory(allTracks(i).ID).LinePredictedX)) % Does not have a prediction using linear prediction

        distToEdgeAlongBelt = edge(2) - allTracks(i).Position(2);
        switch predictionParam.model
            case 'ConstantVelocityWithAngle'
                % Find intersection (temporally).
                vel = rotmat(allTracks(i).Angle) * allTracks(i).Velocity;
                timeToSep = roots([vel(2), -distToEdgeAlongBelt]);
                if numel(timeToSep) ~= 1
                    warning('Could not calculate time to separation.');
                else
                    % If found, save time and calculate predicted position.
                    trackHistory(allTracks(i).ID).PredictedIntersectionTime = t + timeToSep;
                    trackHistory(allTracks(i).ID).PredictedX = allTracks(i).Position(1) + vel(1) * timeToSep;
                end
            case 'ConstantVelocity'
                timeToSep = roots([allTracks(i).FullState(4), -distToEdgeAlongBelt]);
                if numel(timeToSep) ~= 1
                    warning('Could not calculate time to separation.');
                else
                    % If found, save time and calculate predicted position.
                    trackHistory(allTracks(i).ID).PredictedIntersectionTime = t + timeToSep;
                    trackHistory(allTracks(i).ID).PredictedX = allTracks(i).Position(1) + allTracks(i).FullState(2) * timeToSep;
                end
            case 'WhiteNoiseJerk'
                % For velocity v and accleration a, solve
                % int_0^tstep v + t*a dt == distToEdgeAlongBelt
                % For this, find roots of equation
                % 1/2*a*t^2+v*t == distToEdgeAlongBelt
                allPossibleTimes = roots([0.5 * allTracks(i).FullState(6), allTracks(i).FullState(4), -distToEdgeAlongBelt]);
                % Take first time to separation that is >=
                timeToSep = min(allPossibleTimes(allPossibleTimes >= 0));
                if isempty(timeToSep)
                    warning('Could not calculate time to separation.');
                else
                    % If found, save time and calculate predicted position.
                    trackHistory(allTracks(i).ID).PredictedIntersectionTime = t + timeToSep;
                    trackHistory(allTracks(i).ID).PredictedX = 0.5 * allTracks(i).FullState(5) * timeToSep^2 + allTracks(i).FullState(3) * timeToSep + allTracks(i).FullState(1);
                end
        end
        % Line camera intersection. Use current velocity guess
        timeToSepLine = roots([currVelocityGuess(1), -distToEdgeAlongBelt]);
        if ~isempty(timeToSepLine)
            trackHistory(allTracks(i).ID).LinePredictedX = allTracks(i).Position(1);
            trackHistory(allTracks(i).ID).LinepredictedIntersectionTime = t + timeToSepLine;
        end
    end
end
end
