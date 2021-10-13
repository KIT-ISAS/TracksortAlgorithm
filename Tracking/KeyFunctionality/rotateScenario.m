function [midpointMatrix, resolution] = rotateScenario(midpointMatrix, resolution, rotation)
% @author Florian Pfaff pfaff@kit.edu
% @date 2014-2021
if rotation == 0 % Do not touch data if no rotation is to be performed.
    return
elseif rotation >= 2 * pi
    error('Please provide rotation in radian as a value in [0,2*pi)');
elseif mod(rotation, 1) < eps
    warning('An integer was given as rotation angle. Make sure to pass the angle in radian and not in degree.');
elseif abs(rotation-0) < eps % Set manually for most common angles to prevent numerical inaccuracies (these may break assertions regarding the borders!)
    rotMat = eye(2);
elseif abs(rotation-pi/2) < eps
    rotMat = [0, -1; 1, 0];
elseif abs(rotation-pi) < eps
    rotMat = [-1, 0; 0, -1];
elseif abs(rotation-3/2*pi) < eps
    rotMat = [0, 1; -1, 0];
else
    warning('Rotation is not 0, pi/2, pi, or 3/2*pi. Borders may not be suitable.');
    rotMat = [cos(rotation), -sin(rotation); sin(rotation), cos(rotation)];
end

midpointMatrix = reshape(rotMat*midpointMatrix(:, :), size(midpointMatrix));
resolution = rotMat * resolution;
if resolution(1, 1) > resolution(1, 2)
    resolution(1, 1:2) = resolution(1, [2, 1]);
end
if resolution(2, 1) > resolution(2, 2)
    resolution(2, 1:2) = resolution(2, [2, 1]);
end
end