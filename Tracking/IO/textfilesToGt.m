function textfilesToGt(inputPath, outputFilename, convZAxis, convAngles)
% @author Florian Pfaff pfaff@kit.edu
% Function to convert the DEM data to mat files. Can be converted into
% a midpoint matrix or further converted into a CSV file via MatToCSV.
% @date 2016-2021
% V2.1
arguments
    inputPath char
    outputFilename char = 'gt.mat'
    convZAxis (1, 1) logical = false
    convAngles (1, 1) logical = false
end


if ~strcmp(outputFilename(end-3:end), '.mat')
    error('Invalid output filename');
end
if ~convZAxis
    formatSpec = '%f %f %*f %f %f %*f %*f %*f %*f %*f %*f %*f %*f %*f %f %*f\n'; % For x y vx vy
    scanPerLine = 5;
else
    formatSpec = '%f %f %f %f %f %f %*f %*f %*f %*f %*f %*f %*f %*f %f %*f\n'; % For x y vx vy
    scanPerLine = 7;
end

allFiles = dir(fullfile(inputPath, 't0*.txt'));
filesRotMat = dir(fullfile(inputPath, 't0*.Daten.TransMatrix.txt'));
[~, indicesRemaining] = setdiff({allFiles.name}, {filesRotMat.name});
filesPosVelID = allFiles(indicesRemaining);

if isempty(filesPosVelID) || convAngles && isempty(filesRotMat)
    error('Folder does not contain text files of the desired format.')
end

% Get number of particles by parsing first file
filename = filesPosVelID(1).name;
fileID = fopen(fullfile(inputPath, filename), 'r');
tmp = fscanf(fileID, formatSpec, [scanPerLine, inf]);
fclose(fileID);
if size(tmp, 2) < 10
    error('Less than 10 particles in data set. This is definitely wrong');
end
% Initialize as 3d matrix. 1st dim: coordinate, 2nd dim: time step,
% 3rd dim: particle
if ~convZAxis
    pos = NaN(2, numel(filesPosVelID), size(tmp, 2));
    vel = NaN(2, numel(filesPosVelID), size(tmp, 2));
else
    pos = NaN(3, numel(filesPosVelID), size(tmp, 2));
    vel = NaN(3, numel(filesPosVelID), size(tmp, 2));
end
if convAngles
    % Initialize as 4d matrix. 1st & 2nd dim: matrix, 3rd dim: time step
    % 4th dim: particle
    rotMat = NaN(3, 3, numel(filesPosVelID), size(tmp, 2));
end

for j = 1:length(filesPosVelID)
    if mod(j, 50) == 0
        fprintf('Reading file %d of %d\n', j, length(filesPosVelID));
    end
    filename = filesPosVelID(j).name;
    fileID = fopen(fullfile(inputPath, filename), 'r');
    tmp = fscanf(fileID, formatSpec, [scanPerLine, inf]);

    fclose(fileID);
    if isempty(tmp)
        continue;
    end
    if ~convZAxis
        pos(:, j, tmp(5, :)) = tmp(1:2, :);
        vel(:, j, tmp(5, :)) = tmp(3:4, :);
    else
        pos(:, j, tmp(7, :)) = tmp(1:3, :);
        vel(:, j, tmp(7, :)) = tmp(4:6, :);
    end
    if convAngles
        filename = filesRotMat(j).name;
        fileID = fopen(fullfile(inputPath, filename), 'r');
        tmp = fscanf(fileID, [repmat('%f ', 1, 9), '%f\n'], [10, inf]);
        fclose(fileID);
        rotMat(:, :, j, tmp(1, :)) = reshape(tmp(2:10, :), [3, 3, 1, size(tmp, 2)]); % Rotmat currently row wise. Change to line-wise later
    end

end

%%
if ~convAngles
    save(outputFilename, '-v7.3', 'pos', 'vel');
else
    rotMat = permute(rotMat, [2, 1, 3, 4]); % Change to line-wise later
    save(outputFilename, '-v7.3', 'pos', 'vel', 'rotMat');
end
end