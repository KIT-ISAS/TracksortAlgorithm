classdef (SharedTestFixtures = { ...
        matlab.unittest.fixtures.PathFixture('../Tracking', 'IncludingSubfolders', true), ...
        matlab.unittest.fixtures.PathFixture('TestCaseCreation', 'IncludingSubfolders', true), ...
        }) ...
        TrackSortAlgorithmTest < matlab.unittest.TestCase
    % @author Florian Pfaff
    % @date 2014-2021
    methods (Test, TestTags = {'Batch'})
        function generateDataset(testCase)
            testCase.verifyWarningFree(@()genStandardTestCases());
        end
        function basicTestCases(testCase)
            % Other test cases cannot be directly used (for test case 4 true solution is
            % not evident, test case 5 the gap without measurements is too
            % large to make sense).
            models = {'ConstantVelocity', 'WhiteNoiseJerk', 'ConstantVelocityWithAngle'};
            repNTimes = 10;
            for modelIndex = 1:numel(models)
                allParam = getDefaultParam([30; 0], models{modelIndex});
                if modelIndex ~= 3
                    allParam.prediction.S = 50;
                end

                allParam.score.looseStep = 30; % Ensure that gap in third test is bridged

                allParam.association.useOrientation = false;
                allParam.initial.PositionCov = 3000 * eye(2);
                allParam.meas.PositionCov = 3000 * eye(2);
                allParam.association.tryToUseMex = false; % To prevent infinite loops

                for testIndex = 1:3
                    fn = sprintf('./test_case%d.csv', testIndex);

                    trackHistory = TrackSortAlgorithm([0, 1500; 0, 1050], predictFrom = 700, predictTo = 900, allParam = allParam, path = fn);

                    testCase.verifyEqual(numel(trackHistory), 3);

                    [~, midpointMatrixGT] = readIOSBData(sprintf('./test_case%d_labels.csv', testIndex));
                    sizeMidpointOrig = size(midpointMatrixGT, 3);
                    tracksEqual = false(numel(trackHistory), size(midpointMatrixGT, 2));
                    for track = 1:numel(trackHistory)
                        for gtTrack = 1:size(midpointMatrixGT, 2)
                            % Test if measurements assigned to one track are
                            % identical to ground truth track.
                            midpointsGTTrack = squeeze(midpointMatrixGT(:, gtTrack, :));
                            midpointsGTTrack = midpointsGTTrack(~isnan(midpointsGTTrack)); % Filter NaN out for GT
                            rawMeasTrack = trackHistory(track).RawMeasurements(~isnan(trackHistory(track).RawMeasurements)); % Filter NaN out for track (caused by track scores)
                            tracksEqual(track, gtTrack) = isequal(rawMeasTrack, midpointsGTTrack);
                        end
                    end
                    % Test if a corresponding groundtruth track was found for every
                    % track.
                    testCase.verifyTrue(all(any(tracksEqual)));
                    testCase.verifyTrue(all(~isnan([trackHistory.PredictedX])));
                    testCase.verifyLength([trackHistory.PredictedX], 3);
                    testCase.verifyTrue(all(~isnan([trackHistory.LinePredictedX])));
                    testCase.verifyLength([trackHistory.LinePredictedX], 3)
                    testCase.verifyTrue(all(~isnan([trackHistory.PredictedIntersectionTime])));
                    testCase.verifyLength([trackHistory.PredictedIntersectionTime], 3)
                    testCase.verifyTrue(all(~isnan([trackHistory.LinepredictedIntersectionTime])));
                    testCase.verifyLength([trackHistory.LinepredictedIntersectionTime], 3)

                    % Test track amount of 10x test case
                    [~, midpointMatrix] = readIOSBData(sprintf('./test_case%d.csv', testIndex));
                    midpointMatrix = repmat(midpointMatrix, [1, 1, repNTimes]); % Repeat 10 times
                    [trackHistory, env] = TrackSortAlgorithm([0, 1500; 0, 1050], predictFrom = 700, predictTo = 900, allParam = allParam, path = '', midpointMatrix = midpointMatrix);
                    testCase.verifyClass(env, 'struct');
                    testCase.verifyLength(trackHistory, 3*size(midpointMatrix, 3)/sizeMidpointOrig);
                end
            end
        end
        function testCorrectNumberOfMeasurements(testCase)
            % In this test case, a lot of measurements are used. As this is
            % a difficult scenario, not all tracks are tracked perfectly.
            % However, the number of measurements should always be correct.
            addpath(genpath('../Tracking')); % Just to make sure that everything has been added to the path

            models = {'WhiteNoiseJerk', 'ConstantVelocity', 'ConstantVelocityWithAngle'};
            for modelIndex = 1:numel(models)
                allParam = getDefaultParam([30; 0], models{modelIndex});
                if modelIndex ~= 3
                    allParam.prediction.S = 50;
                end
                allParam.score.looseStep = 30; % Ensure that gap in third test is bridged

                allParam.association.useOrientation = false;
                allParam.initial.PositionCov = 3000 * eye(2);
                allParam.meas.PositionCov = 3000 * eye(2);
                allParam.association.tryToUseMex = false;
                for testIndex = 1:3
                    [~, midpointMatrix] = readIOSBData(sprintf('./test_case%d.csv', testIndex));
                    midpointMatrix = [midpointMatrix, midpointMatrix + [20; 0], midpointMatrix - [20; 0], midpointMatrix + [40; 0], midpointMatrix - [40; 0], midpointMatrix - [100; 0], midpointMatrix + [100; 0]]; %#ok<AGROW>
                    midpointMatrix = repmat(midpointMatrix, [1, 1, 10]);
                    for t = 1:size(midpointMatrix, 3)
                        % Make sure NaN are at the end
                        [~, order] = sort(midpointMatrix(1, :, t));
                        midpointMatrix(:, :, t) = midpointMatrix(:, order, t);
                    end
                    borders = [0, 1500; 0, 1050] + [-100, 100; 0, 0];

                    [trackHistory, env] = TrackSortAlgorithm(borders, predictFrom = 700, predictTo = 900, allParam = allParam, midpointMatrix = midpointMatrix);
                    testCase.verifyClass(env, 'struct');
                    allMeasInHistory = [trackHistory.RawMeasurements];
                    allValMeasInHistory = allMeasInHistory(1, ~isnan(allMeasInHistory(1, :)));
                    % Only check number of measurements because tracking is
                    % not perfect
                    testCase.verifyEqual(numel(allValMeasInHistory), sum(sum(~isnan(midpointMatrix(1, :, :)))));
                end
            end
        end
        function testEstimationOfOrientation(testCase) % Do not use for association
            currPath = pwd;
            compileAll();
            cd(currPath);
            allParam = getDefaultParam([30; 0]);
            [~, midpointMatrix] = readIOSBData('./test_case1.csv');
            isValid = ~isnan(midpointMatrix(1, :, :));
            orientationMatrix = NaN(size(midpointMatrix, 2), size(midpointMatrix, 3));
            orientationMatrix(isValid) = randn(1, sum(isValid(:)));

            % First, perform estimation but do not use orientation
            allParam.association.useOrientation = false;
            allParam.initial.PositionCov = 2000 * eye(2);
            allParam.meas.PositionCov = 2000 * eye(2);

            trackHistory = TrackSortAlgorithm([0, 1500; 0, 1050], predictFrom = 700, predictTo = 900, allParam = allParam, midpointMatrix = midpointMatrix, orientationMatrix = orientationMatrix);

            testCase.verifyEqual(numel(trackHistory), 3);
            for i = 1:numel(trackHistory) % Validate sizes of histories
                testCase.verifyEqual(size(trackHistory(i).RawMeasurements, 2), size(trackHistory(i).RawOrientations, 2));
                testCase.verifyEqual(size(trackHistory(i).OrientationEstimates, 2), size(trackHistory(i).Posterior, 2));
            end

            % Now use it and use VMFilter and random values
            allParam.initial.OrientationFilterString = 'VMFilter';
            allParam.initial.OrientationNoise = VMDistribution(0, 100);
            allParam.meas.OrientationNoise = VMDistribution(0, 100);
            allParam.prediction.OrientationNoise = VMDistribution(0, 0.000001);
            trackHistory = TrackSortAlgorithm([0, 1500; 0, 1050], predictFrom = 700, predictTo = 900, allParam = allParam, midpointMatrix = midpointMatrix, orientationMatrix = orientationMatrix);

            testCase.verifyEqual(numel(trackHistory), 3);
            for i = 1:numel(trackHistory)
                testCase.verifyEqual(trackHistory(i).OrientationEstimates, mod(trackHistory(i).RawOrientations, 2*pi), 'AbsTol', 1e-8);
            end

            % Now use with FourierFilter and with ones instead of random
            % values
            allParam.initial.OrientationFilterString = 'FourierFilter(21,''sqrt'')';
            allParam.association.orientationMode = 'logLikelihoodFourier';
            allParam.initial.OrientationNoise = VMDistribution(0, 10);
            allParam.meas.OrientationNoise = VMDistribution(0, 10);
            allParam.prediction.OrientationNoise = VMDistribution(0, 10);
            orientationMatrix(isValid) = ones(1, sum(isValid(:)));
            allParam.association.useOrientation = true;
            trackHistory = TrackSortAlgorithm([0, 1500; 0, 1050], predictFrom = 700, predictTo = 900, allParam = allParam, midpointMatrix = midpointMatrix, orientationMatrix = orientationMatrix);
            testCase.verifyEqual(numel(trackHistory), 3);

        end
        function testBadParameterDetection(testCase)
            testCase.verifyError(@()TrackSortAlgorithm([0, 1500; 0, 1050], predictFrom = 700, predictTo = 900, path = './test_case1.csv'), ...
                'TrackSortAlgorithm:VeryBadParameters');
        end
        function testPlotHistory(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            allParam = getDefaultParam([30; 0]);
            allParam.score.looseStep = 30; % Ensure that gap in third test is bridged

            allParam.association.useOrientation = false;
            allParam.initial.PositionCov = 2000 * eye(2);
            allParam.meas.PositionCov = 2000 * eye(2);
            [~, midpointMatrix] = readIOSBData('./test_case1.csv');
            midpointMatrix = repmat(midpointMatrix, [1, 1, 10]); % Repeat 10 times
            [trackHistory, env] = TrackSortAlgorithm([0, 1500; 0, 1050], predictFrom = 700, predictTo = 900, allParam = allParam, midpointMatrix = midpointMatrix);
            testCase.applyFixture(SuppressedWarningsFixture('MATLAB:hg:AutoSoftwareOpenGL'));
            testCase.verifyWarningFree(@()plotHistory(trackHistory = trackHistory, env = env));
            folderFixture = testCase.applyFixture(TemporaryFolderFixture());
            filename = fullfile(folderFixture.Folder, 'history.mat');
            save(filename, 'trackHistory', 'env');
            testCase.verifyWarningFree(@()plotHistory(filename = filename));
        end
        function testBadBorderDetection(testCase)
            allParam = getDefaultParam([30; 0]);
            allParam.score.looseStep = 30; % Ensure that gap in third test is bridged

            allParam.association.useOrientation = false;
            allParam.initial.PositionCov = 2000 * eye(2);
            allParam.meas.PositionCov = 2000 * eye(2);
            [~, midpointMatrix] = readIOSBData('./test_case1.csv');
            midpointMatrix = repmat(midpointMatrix, [1, 1, 10]); % Repeat 10 times
            testCase.verifyWarning(@()TrackSortAlgorithm(2*[0, 1500; 0, 1050], predictFrom = 700, predictTo = 900, allParam = allParam, midpointMatrix = midpointMatrix), ...
                'TrackSortAlgorithm:TracksShortForCurrentBorders');
        end
    end
    methods (Test, TestTags = {'LiveMode'})
        function testLiveModeScenarioWithoutUsingLiveMode(testCase)
            allMidpointsStruct = repmat(struct('midpoints', [], 'visualClassifications', []), 1, 10);
            maxSize = 0;
            for i = 1:10
                allMidpointsStruct(i) = readMidpointsLive(sprintf('LiveSampleFilesNoSizes/Partikelpositionen_%02d.txt', i));
                maxSize = max([maxSize, size(allMidpointsStruct(i).midpoints, 2)]);
            end
            midpointMatrix = NaN(size(allMidpointsStruct(i).midpoints, 1), maxSize, numel(allMidpointsStruct));
            visualClassificationMatrix = NaN(size(allMidpointsStruct(i).visualClassifications, 1), maxSize, numel(allMidpointsStruct));
            for i = 1:numel(allMidpointsStruct)
                midpointMatrix(1:size(allMidpointsStruct(i).midpoints, 1), 1:size(allMidpointsStruct(i).midpoints, 2), i) = allMidpointsStruct(i).midpoints;
                visualClassificationMatrix(1:size(allMidpointsStruct(i).visualClassifications, 1), 1:size(allMidpointsStruct(i).visualClassifications, 2), i) = allMidpointsStruct(i).visualClassifications;
            end

            params = getDefaultParam(0.005);

            [trackHistory, env] = TrackSortAlgorithm([0.0, 0.18; 0.542, 0.642], predictFrom = 0.625, predictTo = 0.63, allParam = params, path = '', midpointMatrix = midpointMatrix, visualClassificationMatrix = visualClassificationMatrix);
            testCase.verifyClass(env, 'struct');
            testCase.verifyLength(trackHistory, 13);
            plotHistory(trackHistory = trackHistory, env = env)
        end
        function testLiveModeWithoutSizes(testCase)
            % Tests that live mode runs and terminates as planned. Further,
            % validates if number of tracks in history is correct.
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            global enableExpensive %#ok<GVMIS>
            if isempty(enableExpensive) || enableExpensive
                params = getDefaultParam([0.005; 0]);
                params.live.enabled = true;
                params.live.nozzleMiddleLeftRightOutput = false;
                params.live.noNozzles = 16;
                copyfile(fullfile('LiveSampleFilesNoSizes', 'Partikelpositionen_01.txt'), 'Partikelpositionen.txt', 'f');
                file = fopen('Partikelpositionen_blockiert.txt', 'w');
                fprintf(file, '0');
                fclose(file);
                batch('liveModeDummy(''LiveSampleFilesNoSizes'')');
                testCase.applyFixture(SuppressedWarningsFixture('LiveMode:NoMeas'));
                [trackHistory, env] = TrackSortAlgorithm([0.0, 0.18; 0.542, 0.642], predictFrom = 0.625, predictTo = 0.63, allParam = params);
                testCase.verifyClass(env, 'struct');
                testCase.verifyLength(trackHistory, 13);
                testCase.verifyEqual(size([trackHistory.VisualClassifications], 1), 2);
                plotHistory(trackHistory = trackHistory, env = env)
            end
        end
        function testLiveModeWithSizes(testCase)
            % Tests that live mode runs and terminates as planned. Further,
            % validates if number of tracks in history is correct.
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            global enableExpensive %#ok<GVMIS>
            if isempty(enableExpensive) || enableExpensive
                params = getDefaultParam([0.005; 0]);
                params.live.enabled = true;
                copyfile(fullfile('LiveSampleFilesWithSizes', 'Partikelpositionen_01.txt'), 'Partikelpositionen.txt', 'f');
                file = fopen('Partikelpositionen_blockiert.txt', 'w');
                fprintf(file, '0');
                fclose(file);
                batch('liveModeDummy(''LiveSampleFilesWithSizes'')');
                testCase.applyFixture(SuppressedWarningsFixture({'LiveMode:NoMeas', 'LiveMode:EmptyLockFile'}));
                trackHistory = TrackSortAlgorithm([0.0, 0.18; 0.542, 0.642], predictFrom = 0.56, predictTo = 0.63, allParam = params);
                testCase.verifyLength(trackHistory, 31);
                testCase.verifyEqual(size([trackHistory.VisualClassifications], 1), 2);
                nozzleControl = readtable('Duesensteuerung.txt');
                testCase.verifyNotEmpty(nozzleControl);
                testCase.verifyTrue(~any(isnan(nozzleControl.Variables), 'all'));
            end
        end
        function testLiveModeWithSizesAndEmptyAtEnd(testCase)
            % Tests that live mode runs and terminates as planned. Further,
            % validates if number of tracks in history is correct.
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            global enableExpensive %#ok<GVMIS>
            if isempty(enableExpensive) || enableExpensive
                params = getDefaultParam([0.005; 0]);
                params.live.enabled = true;
                copyfile(fullfile('LiveSampleFilesWithSizes', 'Partikelpositionen_01.txt'), 'Partikelpositionen.txt', 'f');
                file = fopen('Partikelpositionen_blockiert.txt', 'w');
                fprintf(file, '0');
                fclose(file);
                batch('liveModeDummy(''LiveSampleFilesWithSizes'', 10)');
                testCase.applyFixture(SuppressedWarningsFixture({'LiveMode:NoMeas', 'LiveMode:EmptyLockFile'}));
                trackHistory = TrackSortAlgorithm([0.0, 0.18; 0.542, 0.642], predictFrom = 0.56, predictTo = 0.63, allParam = params);
                testCase.verifyLength(trackHistory, 31);
                testCase.verifyEqual(size([trackHistory.VisualClassifications], 1), 2);
                nozzleControl = readtable('Duesensteuerung.txt');
                testCase.verifyNotEmpty(nozzleControl);
                testCase.verifyTrue(~any(isnan(nozzleControl.Variables), 'all'));
            end
        end
        function testAbortLiveMode(testCase)
            % Tests that live mode runs and terminates as planned. Further,
            % validates if number of tracks in history is correct.
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            params = getDefaultParam([0.005; 0]);
            params.live.enabled = true;
            params.live.maxWaitTime = seconds(5);
            copyfile(fullfile('LiveSampleFilesWithSizes', 'Partikelpositionen_01.txt'), 'Partikelpositionen.txt', 'f');
            file = fopen('Partikelpositionen_blockiert.txt', 'w');
            fprintf(file, '0');
            fclose(file);
            testCase.applyFixture(SuppressedWarningsFixture({'LiveMode:NoMeas', 'LiveMode:EmptyLockFile'}));
            testCase.verifyWarning(@()TrackSortAlgorithm([0.0, 0.18; 0.542, 0.642], predictFrom = 0.56, predictTo = 0.63, allParam = params), 'LiveMode:Timeout');
        end
    end
end
