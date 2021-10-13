function [currMeasurements, currNumberOfMeasurements] = readMidpointsLive(fn)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
arguments
    fn (1, :) char{mustBeNonempty}
end
data = readtable(fn, "VariableNamingRule", "preserve", 'Delimiter', 'semi');
if ~isempty(data)
    % Swap axis to use tracking from bottom to up
    currMeasurements.midpoints = [data.("Y-Position")'; data.("X-Position")'];
    currNumberOfMeasurements = size(currMeasurements.midpoints, 2);
    currMeasurements.visualClassifications = [data.PColor'; data.PID'];
    if any(strcmp('X-Ausdehnung', data.Properties.VariableNames)) && any(strcmp('Y-Ausdehnung', data.Properties.VariableNames))
        currMeasurements.sizes = [data.("X-Ausdehnung")'; data.("Y-Ausdehnung")'];
    end
else
    currMeasurements.midpoints = [];
    currMeasurements.visualClassifications = [];
    currNumberOfMeasurements = 0;
end
end