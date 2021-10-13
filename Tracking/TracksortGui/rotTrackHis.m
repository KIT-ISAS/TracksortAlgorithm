function [ trackHistory ] = rotTrackHis( trackHistory,rotation,env)
%ROTTRACKHIS Summary of this function goes here
%   Detailed explanation goes here
global tracks

for i = 1:length(trackHistory)
    trackHistory(i).Posterior = rot_vect(trackHistory(i).Posterior,rotation);
    trackHistory(i).RawMeasurements = rot_vect(trackHistory(i).RawMeasurements,rotation);
    trackHistory(i).Prediction = rot_vect(trackHistory(i).RawMeasurements,rotation);
    trackHistory(i).LastAngle = wrapTo2Pi(trackHistory(i).LastAngle+ rotation);
    
    v = rot_vect([trackHistory(i).LinePredictedX;tracks.Pred_edge],rotation);
    if ~all(isnan(v))
        ind_pred_edge = find(abs((v-env.Pred_edge))<1e-5,1);
        if ~isempty(ind_pred_edge)
            ind = 3-ind_pred_edge; %ind_pred_edge is 1 or 2, ind is the other value as ind_pred_edge
            trackHistory(i).LinepredictedX = v(ind);
            v = rot_vect([trackHistory(i).PredictedX;tracks.Pred_edge],rotation);
            trackHistory(i).PredictedX = v(ind);
            v = rot_vect([trackHistory(i).TrueIntersection;tracks.Pred_edge],rotation);
            trackHistory(i).TrueIntersection = v(ind);
        else
            error('invalid rotation')
        end
    end
end


end