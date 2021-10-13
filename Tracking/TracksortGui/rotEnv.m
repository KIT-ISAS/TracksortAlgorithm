function [ env ] = rotEnv( env,rotation )
%ROTENV Summary of this function goes here
%   Detailed explanation goes here

global tracks
res = tracks.resolution;
env.rotation=rotation;
env.Pred_edge = find_rot_line_Y_compnent(env.Pred_edge);
env.predictionOnlyStart = find_rot_line_Y_compnent(env.predictionOnlyStart);

    function v_= find_rot_line_Y_compnent(v)
        v_rotated =  rot_vect([-5000:1000:5000;ones(1,11)* v],rotation);
        % intersection of Predline_rotated and Y axis
        v_rotated_Y = polyxpoly(v_rotated(1,:),v_rotated(2,:),...
            [res(1,1),res(1,1)],[res(2,1),res(2,2)]);
        % intersection of Predline_rotated and X axis
        x_rotated_X = polyxpoly(v_rotated(1,:),v_rotated(2,:),...
            [res(1,1),res(1,2)],[res(2,1),res(2,1)]);
        if isempty(x_rotated_X)&&isempty(v_rotated_Y)...
                ||  ~isempty(x_rotated_X)&&~isempty(v_rotated_Y)
            error('invalid rotation');
        elseif ~isempty(x_rotated_X)
            v_ = v_rotated(1,1);
        elseif ~isempty(v_rotated_Y)
            v_ = v_rotated(2,1);
        end
        if ~((v_>res(1,1) && v_<res(1,2)) || (v_>res(2,1) && v_<res(2,2)))
            errordlg(['try to save rotated prediction lines but not reasonable'...
                ' value comes out. maybe because one line is too near to a border']);
            return
        end
    end
end
% find the intersection of the rotated prediction line and the resolution
% rectangle
%    [x,y] = polyxpoly(v(1,:),v(2,:),[res(1,1),res(1,1),res(1,2), res(1,2),...
%        res(1,1)],[res(2,1),res(2,2),res(2,2),res(2,1),res(2,1)]);