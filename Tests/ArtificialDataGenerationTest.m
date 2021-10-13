classdef (SharedTestFixtures = { ...
        matlab.unittest.fixtures.PathFixture('../Tracking', 'IncludingSubfolders', true), ...
        matlab.unittest.fixtures.PathFixture('TestCaseCreation', 'IncludingSubfolders', true), ...
        }) ...
        ArtificialDataGenerationTest < matlab.unittest.TestCase
    % @author Florian Pfaff
    % @date 2014-2021
    methods (Test)
        function generateDataset(testCase)
            testCase.verifyWarningFree(@()genStandardTestCases());
        end
        function basicTestCases(testCase)
            [~, midpointMatrix] = readIOSBData('test_case3.csv');
            midpointMatrixSigma1 = addPositionNoise(midpointMatrix, 1, [0, 1500], [0, 1050]);
            testCase.verifyGreaterThan(sum(abs(midpointMatrixSigma1(:)-midpointMatrix(:)), 'omitnan'), 10);
            midpointMatrixSigma0 = addPositionNoise(midpointMatrix, 0, [0, 1500], [0, 1050]);
            testCase.verifyEqual(midpointMatrixSigma0, midpointMatrix);
        end
    end
end
