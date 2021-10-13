function [ pos ] = align2grid( g,h,v,hObject )
%ALIGN2GRID Summary of this function goes here
%   Detailed explanation goes here
if nargin < 4
    pos = g(:,h,v);
else
    objectPos = get(hObject,'Position');
    pos = g(1:2,h,v);
    pos(3:4) = objectPos(3:4);

end

