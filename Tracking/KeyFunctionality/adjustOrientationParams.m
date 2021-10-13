function allParam = adjustOrientationParams(allParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021
if strcmp(allParam.association.orientationMode, 'logLikelihood')
    if isa(allParam.meas.OrientationNoise, 'VMDistribution')
        allParam.meas.OrientationNoiseVM = allParam.meas.OrientationNoise;
    else
        warning('Using log-likelihood but measurement noise was not given as VM. Casting to VM');
        allParam.meas.OrientationNoiseVM = VMDistribution.fromMoment(allParam.meas.OrientationNoise.trigonometricMoment(1));
    end
end

chosenFilter = eval(allParam.initial.OrientationFilterString);
if isa(chosenFilter, 'FourierFilter')
    % Cast all noises to Fourier
    numberOfCoeffs = 2 * numel(chosenFilter.fd.a) - 1;
    if ~isa(allParam.initial.OrientationNoise, 'FourierDistribution')
        allParam.initial.OrientationNoise = FourierDistribution.fromDistribution( ...
            allParam.initial.OrientationNoise, numberOfCoeffs);
    end
    if ~isa(allParam.prediction.OrientationNoise, 'FourierDistribution')
        allParam.prediction.OrientationNoise = FourierDistribution.fromDistribution( ...
            allParam.prediction.OrientationNoise, numberOfCoeffs);
    end
    if ~isa(allParam.meas.OrientationNoise, 'FourierDistribution')
        allParam.meas.OrientationNoise = FourierDistribution.fromDistribution( ...
            allParam.meas.OrientationNoise, numberOfCoeffs);
    end
end

end