function [tracks] = makeTracks(trackPts,track_start,track_cuts)
%% testcases
rng(1)
% track_cuts a cell array of index to be nan
xmax = 2320; % band width
ymax = 1024; % band length
bandSpeed = 28; % pixel per frame

yPts = [0 900];
y = 1:bandSpeed:ymax;

b=10; %right border of the uniform dist. with mean =0
c=10;


for i = 1:length(trackPts)
    y =  (y + 2*c*rand(1,length(y)));
    tracks(i).x = spline(yPts, trackPts{i},y)+2*b*rand(1,length(y))-b; % noise is uniform betwenn -b,b
    tracks(i).y = y;
    
    tracks(i).x = [nan* zeros(1, track_start(i)-1) tracks(i).x];
    tracks(i).y = [nan* zeros(1, track_start(i)-1) tracks(i).y];
    
    tracks(i).x = add_track_cut(tracks(i).x, track_cuts{i});
    tracks(i).y = add_track_cut(tracks(i).y, track_cuts{i});
    
   
end
