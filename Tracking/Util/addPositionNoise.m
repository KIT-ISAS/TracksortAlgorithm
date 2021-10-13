function midpointMatrix = addPositionNoise(midpointMatrix, noiseSigma, fieldOfViewX, fieldOfViewY)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
arguments
    midpointMatrix (2, :, :) double
    noiseSigma (1, 1) double % Variance of TRUNCATED (!) Gaussian. Measurements are truncated to field of view.
    fieldOfViewX (1, 2) double = [0.388, 0.788]
    fieldOfViewY (1, 2) double = [0, 0.18]
end

% Add noise
midpointMatrix = normrnd(midpointMatrix, noiseSigma);
% Truncate to field of view
midpointMatrix(1, midpointMatrix(1, :) < fieldOfViewX(1)) = fieldOfViewX(1);
midpointMatrix(1, midpointMatrix(1, :) > fieldOfViewX(2)) = fieldOfViewX(2);
midpointMatrix(2, midpointMatrix(2, :) < fieldOfViewY(1)) = fieldOfViewY(1);
midpointMatrix(2, midpointMatrix(2, :) > fieldOfViewY(2)) = fieldOfViewY(2);

end