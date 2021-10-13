augmentParticles = true;
testCaseIndex = 1;

addpath(genpath('Tracking')); % Just to make sure that everything has been added to the path

allParam = getDefaultParam([30; 0], 'ConstantVelocity');

allParam.score.looseStep = 30;

allParam.association.useOrientation = false;
allParam.initial.PositionCov = 3000 * eye(2);
allParam.meas.PositionCov = 3000 * eye(2);
allParam.prediction.S = 50;

fn = sprintf('./Tests/test_case%d.csv', testCaseIndex);
if ~exist(fn, 'file')
    % Generate them at first run
    assert(exist('Tests', 'dir'), 'Must run demo in root folder.');
    addpath(genpath('Tests'));
    cd('Tests')
    genStandardTestCases();
    cd('..');
end

borders = [0, 1500; 0, 1050];
if ~augmentParticles
    [trackHistory, env] = TrackSortAlgorithm(borders, predictFrom = 700, predictTo = 900, allParam = allParam, path = fn);
else
    [~, midpointMatrix] = readIOSBData(fn);
    midpointMatrix = [midpointMatrix, midpointMatrix + [20; 0], midpointMatrix - [20; 0], midpointMatrix + [40; 0], midpointMatrix - [40; 0], midpointMatrix - [100; 0], midpointMatrix + [100; 0]];
    midpointMatrix = repmat(midpointMatrix, [1, 1, 3]);

    for t = 1:size(midpointMatrix, 3)
        % Make sure NaN are at the end
        [~, order] = sort(midpointMatrix(1, :, t));
        midpointMatrix(:, :, t) = midpointMatrix(:, order, t);
    end
    borders = borders + [-100, 100; 0, 0]; % Otherwise not all augmented particles fit in
    [trackHistory, env] = TrackSortAlgorithm(borders, predictFrom = 700, predictTo = 900, allParam = allParam, midpointMatrix = midpointMatrix);

end
plotHistory(trackHistory=trackHistory,env=env) % Call with second argument imagePath to show background images!