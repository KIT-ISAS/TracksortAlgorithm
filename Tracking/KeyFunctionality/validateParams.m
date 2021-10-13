function validateParams(allParam, borders, midpointMatrix)
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021
% Check that only valid fields in the struct
assert(isequal(sort(fieldnames(allParam)), ...
    {'association'; 'general'; 'initial'; 'live'; 'meas'; 'plot'; 'prediction'; 'score'}));
if ~strcmp(allParam.prediction.model, 'ConstantVelocityWithAngle') && isfield(allParam.prediction, 'PositionCov')
    error('Only use PositionCov for ConstantVelocityWithAngle')
end

% Test some paramters for orientation
if allParam.association.useOrientation && (~isfield(allParam.initial, 'OrientationNoise') || ...
        ~isfield(allParam.meas, 'OrientationNoise') || ~isfield(allParam.prediction, 'OrientationNoise'))
    error('Orientation should be used for the assoication but no noises were set. This may occur if libDirectional is not installed."');
elseif strcmp(allParam.association.orientationMode, 'logLikelihoodVM') && ~strcmp(allParam.initial.OrientationFilterString, 'VMFilter')
    assert(isfield(allParam.meas, 'OrientationNoiseVM'), 'OrientationNoiseVM is required for orientationMode logLikelihoodVM');
    warning('Use logLikelihoodFourier for Fourier filters for better performance.');
elseif strcmp(allParam.association.orientationMode, 'logLikelihood')
    error('logLikelihood as orientation mode is ambiguious. Use logLikelihoodVM or logLikelihoodFourier.');
end

if ~strcmpi(allParam.association.distanceMetricPos, 'Mahalanobis')
    warning('Make sure to change association parameters when not using Mahalanobis distance.');
end
% Validate correct config for different motion models
if ~isequal(size(allParam.initial.PositionCov), [2, 2]) || ~isequal(size(allParam.meas.PositionCov), [2, 2]) ...
        || (strcmpi(allParam.prediction.model, 'ConstantVelocityWithAngle') && ~isequal(size(allParam.prediction.PositionCov), [2, 2])) ...
        || (strcmpi(allParam.prediction.model, 'WhiteNoiseJerk') && ~isequal(size(allParam.prediction.Q), [6, 6]))
    error('All covariances regarding the position must be matrices.');
elseif ~isdiag(allParam.initial.PositionCov) || ~isdiag(allParam.meas.PositionCov) ...
        || (strcmpi(allParam.prediction.model, 'ConstantVelocityWithAngle') && ~isdiag(allParam.prediction.PositionCov)) ...
        || (strcmpi(allParam.prediction.model, 'WhiteNoiseJerk') && ~isdiag(allParam.prediction.Q([1, 4], [1, 4])))
    warning('Detected a covariance matrix that is not a diagonal matrix. Double check that this is intentional.');
end

if ~allParam.live.enabled
    % Assert that NaN are ONLY used to fill up at the end
    assert(~any(any(any(isnan(midpointMatrix(:, 1:end-1, :)) & ~isnan(midpointMatrix(:, 2:end, :))))));
    % Assert all measurements are within permitted area. (Live mode is checked
    % in loop because measurements are not known beforehand.)
    minMaxMeas = minmax(midpointMatrix(:, :));
    assert(all(borders(:, 1) <= minMaxMeas(:, 1) & borders(:, 2) >= minMaxMeas(:, 2)), 'Particles outside of the given borders were detected. Please set the observable area correctly. For image data, provide the resolution of the camera.');
end
if allParam.live.enabled && ~allParam.general.rotateBy == 0
    error('Rotation in live mode is currently not supported');
end
if (strcmp(allParam.association.orientationMode, 'logLikelihoodVM') || strcmp(allParam.association.orientationMode, 'logLikelihoodFourier')) ...
        && ~isequal(allParam.association.orientationFactor, 2)
    warning('The orientationFactor is not the orientation factor that is optimal in theory for perfect models.')
end
end
