function allParam = getDefaultParam(velocityGuess, model)
% Can give velocity guess because many parameters depend on it. Additionally, all other parameters can be
% overwritten. The struct returned then is a struct that simply fills
% up all other parameters not given in paramsToOverite
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021

defaultModel = 'ConstantVelocity';
if nargin == 0
    velocityGuess = [0.0007; 0]; % for simulation
    %     velocityGuess=[30;0]; % For some recordings of large sorters
    model = defaultModel;
elseif nargin == 1
    model = defaultModel;
end
if numel(velocityGuess) == 1 % Allow only giving first component
    velocityGuess = [velocityGuess; 0];
end

initialParam.AngleGuess = pi / 2;
% As Filters are handle classes, we cannot simply copy it and always have to reinitialize it using this string
initialParam.OrientationFilterString = 'FourierFilter(11,''sqrt'')';
% Only set if libDirectional installed
libDirectionalInstalled = exist('VMDistribution', 'class');
if libDirectionalInstalled
    initialParam.OrientationNoise = FourierDistribution.fromDistribution( ...
        VMDistribution(0, 1), 11, 'sqrt');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
generalParam.startFrameNo = 1;
generalParam.endFrameNo = 999999;
generalParam.plotEveryNthStep = 50;
generalParam.rotateBy = 0; % Rotate scenario by (in radian).

initialParam.VelocityGuess = velocityGuess;
scale = initialParam.VelocityGuess(1) / 30;
initialParam.PositionCov = 2 * eye(2) * scale;
initialParam.AngleVar = 2;
initialParam.VelocityVar = 5 * scale; %variance at the very beginning
initialParam.refinedVelocityVar = 1;

% Parameters for measurement
measParam.model = model;
measParam.PositionCov = 2 * eye(2) * scale;
if libDirectionalInstalled
    measParam.OrientationNoise = FourierDistribution.fromDistribution( ...
        VMDistribution(0, 1), 11, 'sqrt');
end
switch model
    case 'ConstantVelocityWithAngle'
        measParam.AngleVar = 1;
        measParam.VelocityVar = 1 * scale;
    case 'ConstantVelocity'
        measParam.H = [1, 0, 0, 0; 0, 0, 1, 0];
    case 'WhiteNoiseJerk'
        measParam.H = [1, 0, 0, 0, 0, 0; 0, 0, 0, 1, 0, 0];
    otherwise
        error('Model unsupported.');
end

% Parameters for prediction
predictionParam.model = model;
if libDirectionalInstalled
    predictionParam.OrientationNoise = FourierDistribution.fromDistribution(VMDistribution(0, 1), 11, 'sqrt');
end

switch model
    case 'ConstantVelocityWithAngle'
        predictionParam.PositionCov = 5 * eye(2) * scale;
        predictionParam.AngleVar = 0.5;
        predictionParam.VelocityVar = 0.5 * scale;
    case 'ConstantVelocity'
        T = 1; % Time
        predictionParam.F = blkdiag([1, T; 0, 1], [1, T; 0, 1]);
        predictionParam.S = 1; % Power spectral density of noise
        % See survey of Maneuvering Target Tracking. Part I: Dynamic Models
        % Q2
        Q2x = [T^4 / 3, T^3 / 2; T^3 / 2, T^2];
        predictionParam.QtoScale = blkdiag(Q2x, Q2x);
    case 'WhiteNoiseJerk'
        T = 1; % Time
        Fx = eye(3) + diag([T, T], 1) + diag(T^2/2, 2);
        predictionParam.F = blkdiag(Fx, Fx);
        % See survey of Maneuvering Target Tracking. Part I: Dynamic Models
        % Q3
        Q3x = [T^5 / 20, T^4 / 8, T^3 / 6; T^4 / 8, T^3 / 3, T^2 / 2; T^3 / 6, T^2 / 2, T];
        predictionParam.S = 1; % Power spectral density of noise
        predictionParam.QtoScale = blkdiag(Q3x, Q3x);
        initialParam.AccelerationCov = 100 * eye(2); % Assume matrix is diagonal.
    otherwise
        error('Model unsupported.');
end

associationParam.associationScheme = 'GNN';
associationParam.useDistance = true;
% distanceMetric can be Euclidean or Mahalanobis
associationParam.distanceMetricPos = 'Mahalanobis';
associationParam.squareDist = true;
associationParam.useOrientation = false;

scoreParam.initialScore = 10;
scoreParam.looseStep = 35;
scoreParam.winStep = 45;
scoreParam.maxScore = 100;
scoreParam.trackRemoveLevel = 0;


associationParam.tryToUseMex = false; % Mex version is much faster but sometimes gets stuck in endless loop
% Can be 'logLikelihood' (recommended, to use it based on likelihood)...
% 'cos' for cosine distance (fast) and 'kappaCos' (only cosine distance weighted using uncertainty
% of prediction, not recommended)
% associationParam.orientationMode='logLikelihood';
associationParam.orientationMode = 'cos';
if strcmpi(associationParam.distanceMetricPos, 'Mahalanobis')
    % OrientationFactor be 2 because we use 1.0 times the squaredMahalanobis distance
    % although it should be 0.5 Mahalanobis distance in the precise
    % derivation
    associationParam.orientationFactor = 2;
    associationParam.trackDisappearatMiddleDist = 1.5;
    associationParam.noChangeDist = 0.1;
    associationParam.newTrackAtBeginningDist = 0.1;
    associationParam.newTrackMiddleDist = 1.5;
    associationParam.trackDisappearatEndDist = 0.1;
else
    associationParam.orientationFactor = 1000 * scale;
    associationParam.trackDisappearatMiddleDist = 100 * scale;
    associationParam.noChangeDist = 0.2 * scale;
    associationParam.newTrackAtBeginningDist = 5 * scale;
    associationParam.newTrackMiddleDist = 100 * scale;
    associationParam.trackDisappearatEndDist = 5 * scale;
end
associationParam.maxNewMeas = 100; % Important!!! low: good speed, high: allows for more new tracks

liveParam.enabled = false; % Overwrite to enable
path = '.';
liveParam.trackingLockFile = fullfile(path, 'Partikelpositionen_blockiert.txt');
liveParam.DEMOutput = fullfile(path, 'Partikelpositionen.txt');
liveParam.duesenOutputPath = fullfile(path, 'Duesensteuerung.txt');
liveParam.debugPath = fullfile(path, 'DebugLiveMode.txt');
liveParam.noNozzles = 32;
liveParam.nozzleLimits = [0, 0.16];
liveParam.radiusTargetedParticles = 0.003; % Only relevant if nozzleMiddleLeftRightOutput is false because it uses static radius then (legacy mode)
liveParam.timeStepMultiplier = 5 * 0.001; % In seconds
liveParam.visualIDsToTarget = 1;
liveParam.nozzleMiddleLeftRightOutput = true;
liveParam.maxWaitTime = minutes(1);

plotParam.delegation_to_draw = [];
plotParam.handles = [];
plotParam.hObject = [];

allParam = struct('general', generalParam, 'initial', initialParam, 'prediction', predictionParam, ...
    'meas', measParam, 'association', associationParam, 'score', scoreParam, 'live', liveParam, 'plot', plotParam);
end