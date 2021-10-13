function [] = makeTest(trackPts, tracks_start ,track_cuts,testPath,labelPath)
%MAKETEST Summary of this function goes here
%   Detailed explanation goes here

tracks = makeTracks(trackPts,tracks_start,track_cuts);

% arrange in matrix to shuffel
l = [];
for i = 1:length(tracks)
    l = [l length(tracks(i).x)];
end
m = max(l);
tracks_mat = nan * zeros(m,length(tracks),2);
for i = 1:length(tracks);
    tracks_mat(1:length(tracks(i).x),i,1) = tracks(i).x;
    tracks_mat(1:length(tracks(i).y),i,2) = tracks(i).y;
end
save_test_cvs(tracks_mat,labelPath);

% shuffle
nRows = size(tracks_mat,1);
nTracks = size(tracks_mat,2);

for i= 1:nRows
   xRow = tracks_mat(i,:,1);
   yRow = tracks_mat(i,:,2);
   NaNIdx = find(isnan(xRow));
   numIdx = setdiff(1:length(xRow),NaNIdx);
   xRow_filterd = xRow(numIdx);
   yRow_filterd = yRow(numIdx);
   
   permArr = randperm(length(numIdx));
   perm_X = xRow_filterd(permArr);
   perm_Y = yRow_filterd(permArr);
   xRow = [perm_X nan* zeros(1,length(NaNIdx))];
   yRow = [perm_Y nan* zeros(1,length(NaNIdx))];
   tracks_mat(i,:,1) = xRow;
   tracks_mat(i,:,2) = yRow;
end
save_test_cvs(tracks_mat,testPath);


end

