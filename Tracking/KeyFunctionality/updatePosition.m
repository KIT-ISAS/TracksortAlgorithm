function track = updatePosition(track, measPositionCov, measurement)
positionInnovationCovariance = inv(track.PositionCov) + inv(measPositionCov);
track.Position = positionInnovationCovariance \ (track.PositionCov \ track.Position + measPositionCov \ measurement);
track.PositionCov = inv(positionInnovationCovariance);
end
