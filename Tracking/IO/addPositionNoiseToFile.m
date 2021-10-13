function filenameOutput = addPositionNoiseToFile(filenameInput, noiseSigma, filenameOutput, ...
    fieldOfViewX, fieldOfViewY)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2021
% Use this function to generate a file to make noise reproducible. If this
% is not required, it is possible to use addPositionNoise on
% midpointMatrix.
arguments
    filenameInput char
    noiseSigma (1, 1) double % Variance of TRUNCATED (!) Gaussian. Measurements are truncated to field of view.
    filenameOutput char = [filenameInput, 'Sigma', num2str(noiseSigma), '.mat']
    fieldOfViewX (1, 2) double = [0.388, 0.788]
    fieldOfViewY (1, 2) double = [0, 0.18]
end

matPositions = strfind(filenameOutput, '.mat');
if numel(matPositions) > 1 % Contains .mat twice, remove once.
    filenameOutput(matPositions:matPositions+3) = [];
end

load(filenameInput, 'midpointMatrix');
noisyMidpointMatrix = addPositionNoise(midpointMatrix, noiseSigma, fieldOfViewX, fieldOfViewY);

% Copy file and change midpointMatrix to noisy midpointMatrix
copyfile(filenameInput, filenameOutput)
outputFile = matfile(filenameOutput, 'Writable', true);
outputFile.midpointMatrix = noisyMidpointMatrix;
end