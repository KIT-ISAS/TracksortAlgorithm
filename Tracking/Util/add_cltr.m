function [midpointMatrix, numberOfMidpoints] = add_cltr(resolution, midpointMatrix, numberOfMidpoints, densClt)
% add poission distributed clutter to midpointmatrix
if nargin < 3
    densClt = 1e-5;
end
xMin = 0;
xMax = resolution(1);
yMin = 0;
yMax = resolution(2);

nStep = size(midpointMatrix, 1);
poissClt = densClt * (xMax - xMin) * (yMax - yMin);
for i = 1:nStep
    nClt = poissrnd(poissClt);
    % make sure nClt > 0 to avoid the case that meas{i} is empty
    while nClt == 0
        nClt = poissrnd(poissClt);
    end
    cltMeas = [unifrnd(xMin, xMax, 1, nClt); ...
        unifrnd(yMin, yMax, 1, nClt)];
    cltMeas_ = reshape(cltMeas, 1, 2*nClt);
    indexNaN_mid = find(isnan(midpointMatrix(i, :)), 1);
    if isempty(indexNaN_mid)
        indexNaN_mid = length(midpointMatrix(i, :)) + 1;
    end
    if length(midpointMatrix(i, indexNaN_mid:end)) < 2 * nClt
        midpointMatrix = [midpointMatrix, nan(size(midpointMatrix, 1), 2*nClt-length(midpointMatrix(i, indexNaN_mid:end)))];
    end
    midpointMatrix(i, indexNaN_mid:indexNaN_mid+length(cltMeas_)-1) = cltMeas_;
    numberOfMidpoints(i) = numberOfMidpoints(i) + nClt;
end
