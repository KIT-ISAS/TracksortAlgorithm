function [midpointMatrix, numberOfMidpoints] = add_cltr_around_meas(radius, midpointMatrix, numberOfMidpoints, densClt)
% add poission distributed clutter to midpointmatrix
if nargin < 3
    densClt = 1e-5;
end

nStep = size(midpointMatrix, 1);

for i = 1:nStep
    cltMeas = [];
    for j = 1:numberOfMidpoints(i)
        xMin = midpointMatrix(i, 2*j-1) - radius(1);
        xMax = midpointMatrix(i, 2*j-1) + radius(1);
        yMin = midpointMatrix(i, 2*j) - radius(2);
        yMax = midpointMatrix(i, 2*j) + radius(2);
        poissClt = densClt * (xMax - xMin) * (yMax - yMin);

        nClt = poissrnd(poissClt);
        while nClt == 0
            nClt = poissrnd(poissClt);
        end
        cltMeas = [cltMeas, [unifrnd(xMin, xMax, 1, nClt); ...
            unifrnd(yMin, yMax, 1, nClt)]];
    end
    nClt = size(cltMeas, 2);
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
