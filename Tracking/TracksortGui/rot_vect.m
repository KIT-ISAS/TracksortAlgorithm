function [ v_rotated ] = rot_vect(v,a)
%ROT_VECT rotate vector v by a radian about the center of resolution (not origin) 
%   Detailed explanation goes here
global tracks;
res = tracks.resolution;
trans = [(res(1,1)+res(1,2))/2;(res(2,1)+res(2,2))/2];
v_centered = v - repmat(trans,1,size(v,2));
v_rotated_centered =  rotmat(a)* v_centered;
v_rotated = v_rotated_centered +repmat(trans,1,size(v_rotated_centered,2));
end


