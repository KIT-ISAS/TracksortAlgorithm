function [bestPerm, unobservedTrackList, newTrackMeasurements] = ...
    calcLikelihoodsAndAssociate(allTracks, borders, currMeasurements, ...
    currNumberOfMeasurements, currVelocityGuess, associationParam, measParam, predictionParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021
assert(isequal(size(allTracks(1).Position), [2, 1]), 'Expect 2-D position estimates.');
assert(size(currMeasurements.midpoints, 1) == 2 || isempty(currMeasurements.midpoints), 'Expect 2-D measurements.');

currMatrixDimension = length(allTracks) + associationParam.maxNewMeas;
trackPositions = [allTracks.Position];
if isfield(currMeasurements, 'orientations') && associationParam.useOrientation
    trackOrientations = arrayfun(@(track)track.OrientationFilter.getEstimateMean, allTracks);
end
measurements = reshape(currMeasurements.midpoints, 2, []);
if isempty(measurements)
    distances = [];
    likelihoods = [];
else
    % Varying from left to right in distance matrix: measurements
    % Varying from top to buttom in distance matrix: track
    switch associationParam.distanceMetricPos
        case 'Euclidean'
            distances = pdist2(trackPositions', measurements');
        case 'Mahalanobis'
            distances = NaN(size(trackPositions, 2), size(measurements, 2));
            for i = 1:numel(allTracks)
                % P+R should be used (see Mahler, "Statistical
                % Multisource-Multitarget Information Fusion" Eq. (10.29)).
                if strcmp(predictionParam.model, 'ConstantVelocityWithAngle')
                    currCovMahalanobis = allTracks(i).PositionCov + measParam.PositionCov;
                else
                    currCovMahalanobis = measParam.H * allTracks(i).FullStateCov * measParam.H' + measParam.PositionCov;
                end
                distances(i, :) = pdist2(trackPositions(:, i)', measurements', 'mahalanobis', currCovMahalanobis);
            end
    end
    if associationParam.squareDist
        distances = distances.^2;
    end

    if (associationParam.orientationFactor ~= 0) && isfield(currMeasurements, 'orientations') && associationParam.useOrientation
        % The line below could also be written as
        switch associationParam.orientationMode
            case 'logLikelihoodFourier'
                assert(isa(allTracks(1).OrientationFilter, 'FourierFilter'));
                assert(isa(measParam.OrientationNoise, 'FourierDistribution'));
                z = reshape(currMeasurements.orientations, 1, []); % 1 x n
                % Loop version. Can be used for debugging
                %{
                likeOrientation=NaN(numel(trackOrientations),numel(z));
                for j=1:numel(z)
                    likelihoodCurr=measParam.OrientationNoise.shift(z(j));
                    for i=1:numel(trackOrientations)
                        % see also: More fourier testing file!
                        %' complex conjugate, thus, also flips coefficient
                        % vector as desired
                        likeOrientation(i,j)=2*pi*real(allTracks(i).OrientationFilter.fd.c*likelihoodCurr.c');
                    end 
                    likeOrientation(:,j)=2*pi*real(cat(1,allFilters{:})*likelihoodCurr.c');
                end
                %}
                allFilters = cellfun(@(filter){filter.fd.c}, {allTracks.OrientationFilter});
                measNoiseCoeff = cell2mat(arrayfun(@(j){measParam.OrientationNoise.shift(z(j)).c'}, 1:numel(z)));
                likeOrientation = 2 * pi * real(cat(1, allFilters{:})*measNoiseCoeff);
                distOrientation = -log(likeOrientation);
            case 'logLikelihoodIntegral'
                z = reshape(currMeasurements.orientations, 1, []); % 1 x n
                distOrientation = NaN(size(distances));
                for i = 1:numel(allTracks)
                    for j = 1:numel(z)

                        trackCurr = allTracks(i);
                        zCurr = z(j);

                        fvmTrack = @(x)trackCurr.OrientationFilter.vm.pdf(x);
                        fLikelihood = @(x)exp(measParam.OrientationNoise.kappa.*cos(zCurr-x)) ./ ...
                            (2 * pi * besseli(0, measParam.OrientationNoise.kappa));
                        distOrientation(i, j) = integral(@(x)fvmTrack(x).*fLikelihood(x), 0, 2*pi);
                    end
                end
                distOrientation = -log(distOrientation);
            case 'logLikelihoodVM'
                z = reshape(currMeasurements.orientations, 1, []); % 1 x n
                kappaMeasNoise = measParam.OrientationNoiseVM.kappa; % Is scalar


                mu = reshape(trackOrientations, [], 1); % n x 1
                if isa(allTracks(i).OrientationFilter, 'VMFilter')
                    kappasPred = arrayfun(@(i)allTracks(i).OrientationFilter.vm.kappa, 1:numel(allTracks))';
                else
                    % Cast to VM and then get kappa
                    vms = arrayfun(@(i){VMDistribution.fromMoment( ...
                        allTracks(i).OrientationFilter.getEstimate.trigonometricMoment(1))}, 1:numel(allTracks));
                    kappasPred = cellfun(@(vm)vm.kappa, vms)';
                end
                assert(isequal(size(mu), size(kappasPred))); % kappa also n x 1

                muMult = atan2(kappaMeasNoise.*sin(z)+kappasPred.*sin(mu), kappaMeasNoise.*cos(z)+kappasPred.*cos(mu));
                kappaMult = sqrt((kappaMeasNoise .* cos(z) + kappasPred .* cos(mu)).^2+(kappaMeasNoise .* sin(z) + kappasPred .* sin(mu)).^2);
                % In this formula, we use the assumption that the
                % meaurement noise is identical for all orientation
                % measurements.
                distOrientation = kappaMult .* cos(muMult) - log(besseli(0, kappaMult));
            case 'cos'
                distOrientation = 1 - cos(trackOrientations'-currMeasurements.orientations');
            case 'kappaCos'
                % distOrientation=1-cos(pdist2(trackOrientations',currMeasurements.orientations));
                % Using implicit expansion instead.
                distOrientation = 1 - cos(trackOrientations'-currMeasurements.orientations');
                if associationParam.weightCosineDist
                    % This only works for VM
                    kappas = arrayfun(@(i)allTracks(i).OrientationFilter.vm.kappa, 1:numel(allTracks));
                    % Weight all according to kappa*(1-cos(track-meas)). % This
                    % does not perfectly correspond to the distance as the
                    % measurement uncertainty is not respected.
                    distOrientation = kappas' .* distOrientation;
                end
            otherwise
                error('Unknown orientationMode.');
        end
        assert(isequal(size(distances), size(distOrientation)));
        distances = distances + associationParam.orientationFactor * distOrientation;
    end
end

%% adjust probabilities depending on location
% if measurement is at the beginning, more likelihood that it belongs to
% new track, if track was predicted to be out of sight, it is more
% likely that it will have disappeared. Both get 0.1, otherwise 0.05
noChangeDist = associationParam.noChangeDist;
newTrackAtBeginningDist = associationParam.newTrackAtBeginningDist;
newTrackMiddleDist = associationParam.newTrackMiddleDist;
trackDisappearatEndDist = associationParam.trackDisappearatEndDist;
trackDisappearatMiddleDist = associationParam.trackDisappearatMiddleDist;


startingPhase = borders(2, 1) + 1.3 * currVelocityGuess(1); % If within 1.3 times the velocity guess, it is more likely to be new
endPhase = borders(2, 2) - 0.3 * currVelocityGuess(1); % It should be predicted outside of observable area. However, we add some tolerance to that.

trackData = [allTracks.Position];
measDataY = measurements(2, :);

if ~isempty(distances)
    if ~associationParam.useDistance
        error('Directly using likelihoods is currently unsupported.')
        %{
        noChangeL=0.2;
        newTrackAtBeginningL=0.1;
        newTrackMiddleL=0.1;
        trackDisappearatEndL=0.1;
        trackDisappearatMiddleL=0.05;
        likelihoods=[[likelihoods,repmat(newTrackMiddleL+(trackDisappearatEndL-trackDisappearatMiddleL)*(trackData(2,:)'>resolution(2,2)),1,currMatrixDimension-currNumberOfMeasurements)];...
            [repmat(newTrackMiddleL+(newTrackAtBeginningL-newTrackMiddleL)*(measDataY<startingPhase),currMatrixDimension-length(allTracks),1),...
            2*noChangeL*ones(currMatrixDimension-length(allTracks),currMatrixDimension-currNumberOfMeasurements)]];
        %}
    else
        distances = [[distances, ... % Upper left: Distances between the predictions and the measurements
            ... % Upper right: Penalty for disappearing in middle if in middle,
            ... % if at end penalty for disappearance at end
            repmat(trackDisappearatMiddleDist+(trackDisappearatEndDist - trackDisappearatMiddleDist)*(trackData(2, :)' > endPhase), 1, currMatrixDimension-currNumberOfMeasurements)]; ...
            ... % Lower left: Penality for appearing in middle or at beginning
            [repmat(newTrackMiddleDist+(newTrackAtBeginningDist - newTrackMiddleDist)*(measDataY < startingPhase), currMatrixDimension-length(allTracks), 1), ...
            ... & Lower right: Penalty for no change
            2 * noChangeDist * ones(currMatrixDimension-length(allTracks), currMatrixDimension-currNumberOfMeasurements)]];
    end
else % Return useable likelihoods if no tracks or meas
    likelihoods = ones(currMatrixDimension);
    distances = ones(currMatrixDimension);
end

%% Do association
switch associationParam.associationScheme
    case 'greedyNearestNeighbor'
        error('Currently unsupported')
        % nearestNeighbor(likelihoods);
    case 'GNN'
        if associationParam.useDistance
            assignmentProblem = distances;
        else % Using likelihoods is currently unsupported.
            assignmentProblem = -log(likelihoods);
        end
        [~, bestPerm] = matlab.internal.graph.perfectMatching(assignmentProblem);
        bestPerm = bestPerm';
    case 'JA'
        bestPerm = jointAssociation(likelihoods);
    otherwise
        error('Association scheme unknown or unsupported.');
end

% Assert permutation has correct length and all entries are unique and within range
assert(isequal(sort(bestPerm), 1:currMatrixDimension), 'Error in permutation length. Maybe two measurements were assigned to a single track?');

% Create list of tracks that are not observed and measurements of not yet observed tracks
unobservedTrackList = find(bestPerm(1:length(allTracks)) > currNumberOfMeasurements); % %tracks that are assigned to meas > #meas have disappeared
newTrackMeasurements = setdiff(bestPerm((length(allTracks) + 1):end), (currNumberOfMeasurements + 1):currMatrixDimension); % %meas not assigned to tracks are used for new tracks (are already sorted due to setdiff)
assert(isequal(newTrackMeasurements, setdiff(1:currNumberOfMeasurements, bestPerm(1:size(allTracks, 2))))) %assert that two ways of calculating it return same result
assert(length(newTrackMeasurements) <= associationParam.maxNewMeas) %assert there are not too many new measurements
