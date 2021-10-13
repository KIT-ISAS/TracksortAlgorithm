function allTracks = predict(predictionParam, allTracks)
% Determine predictions
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021
rotmat = @(ang)[cos(ang), -sin(ang); sin(ang), cos(ang)];
dimState = size(allTracks(1).FullState, 1);
for trackNo = 1:size([allTracks.Position], 2)
    if ~isempty(allTracks(trackNo).OrientationFilter)
        allTracks(trackNo).OrientationFilter.predictIdentity(predictionParam.OrientationNoise);
    end
    if isequal(predictionParam.model, 'ConstantVelocityWithAngle')
        allTracks(trackNo).AngleVar = allTracks(trackNo).AngleVar + predictionParam.AngleVar;
        allTracks(trackNo).Position = allTracks(trackNo).Position + rotmat(allTracks(trackNo).Angle) * allTracks(trackNo).Velocity;
        allTracks(trackNo).PositionCov = allTracks(trackNo).PositionCov + predictionParam.PositionCov;
        allTracks(trackNo).VelocityVar = allTracks(trackNo).VelocityVar + predictionParam.VelocityVar;
    else % All other models work with F and Q matrices.
        allTracks(trackNo).FullState = predictionParam.F * allTracks(trackNo).FullState;
        allTracks(trackNo).FullStateCov = predictionParam.F * allTracks(trackNo).FullStateCov * predictionParam.F' + predictionParam.Q;
        allTracks(trackNo).Position = allTracks(trackNo).FullState([1, dimState / 2 + 1]);
    end
end
end
