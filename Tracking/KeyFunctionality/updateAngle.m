function track = updateAngle(track, measAngleVar, posChange)
% This is just a heuristic for small angles without cosidering the
% periodicity. One could use a directional filter instead.
currAngle = atan2(posChange(2), posChange(1)) + pi;

% wrap angle
currAngle = wrapTo2Pi(currAngle);
track.Angle = wrapTo2Pi(track.Angle);
angleInnovationCovariance = track.AngleVar^-1 + measAngleVar^-1;
est_angle = angleInnovationCovariance \ (track.AngleVar \ track.Angle + measAngleVar \ currAngle);
% correct angle %%

x = wrapTo2Pi(currAngle);
y = wrapTo2Pi(track.Angle);
if norm(x-y) > pi && est_angle > min(x, y) && est_angle < max(x, y)
    est_angle = min(y, x) - (abs(est_angle-y) / abs(x-y)) * abs(wrapToPi(x-y));
end
track.Angle = est_angle;
track.AngleVar = inv(angleInnovationCovariance);
end
