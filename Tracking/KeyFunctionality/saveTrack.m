function [trackInHistory] = saveTrack(track, trackInHistory, t, tracks_meas, rawOrientation, visualClassification, measIndex, prediction)
arguments
    track (1, 1) struct
    trackInHistory (1, 1) struct
    t (1, 1) double
    tracks_meas (2, 1) double
    rawOrientation double
    visualClassification
    measIndex (1, 1) double
    prediction (2, 1) double
end
trackInHistory.RawMeasurements = [trackInHistory.RawMeasurements, tracks_meas];
trackInHistory.Prediction = [trackInHistory.Prediction, prediction];
if all(~isnan(tracks_meas))
    trackInHistory.Posterior = [trackInHistory.Posterior, track.Position];
    trackInHistory.MeasIndex = [trackInHistory.MeasIndex, measIndex];
    if ~isempty(trackInHistory.OrientationEstimates)
        trackInHistory.OrientationEstimates = [trackInHistory.OrientationEstimates, track.OrientationFilter.getEstimateMean()];
        trackInHistory.RawOrientations = [trackInHistory.RawOrientations, rawOrientation];
    end
    trackInHistory.VisualClassifications = [trackInHistory.VisualClassifications, visualClassification];
    trackInHistory.Lengths = [trackInHistory.Lengths, track.Length];
    trackInHistory.Widths = [trackInHistory.Widths, track.Width];
else
    trackInHistory.Posterior = [trackInHistory.Posterior, NaN(2, 1)];
    trackInHistory.MeasIndex = [trackInHistory.MeasIndex, -1]; % Use -1 because is int32
    if ~isempty(trackInHistory.OrientationEstimates)
        trackInHistory.OrientationEstimates = [trackInHistory.OrientationEstimates, NaN];
    end
    trackInHistory.VisualClassifications = [trackInHistory.VisualClassifications, NaN(size(trackInHistory.VisualClassifications, 1), 1)];
    trackInHistory.Lengths = [trackInHistory.Lengths, NaN];
    trackInHistory.Widths = [trackInHistory.Widths, NaN];
end
if isnan(trackInHistory.StartTime)
    trackInHistory.StartTime = t;
end

end
