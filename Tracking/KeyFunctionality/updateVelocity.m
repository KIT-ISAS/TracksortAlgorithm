function [track, lastHundretVelocities] = updateVelocity(track, lastHundretVelocities, measVelocityVar, posChange)
% Update velocity
currVelocity = norm(posChange);
velocityInnovationCovariance = track.VelocityVar^-1 + measVelocityVar^-1;
track.Velocity(1) = velocityInnovationCovariance \ (track.VelocityVar \ track.Velocity(1) + measVelocityVar \ currVelocity);
track.VelocityVar = inv(velocityInnovationCovariance);
lastHundretVelocities = [lastHundretVelocities(2:end), track.Velocity(1)];
end
