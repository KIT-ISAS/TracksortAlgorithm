function rotMidpointMat(angle)
%ROTMIDPOINTM Summary of this function goes here
%   Detailed explanation goes here

global tracks;
mpm = tracks.midpointMatrix;
mpm=reshape(mpm,[size(mpm,1)*size(mpm,2),size(mpm,3)])';
% max_mpm_X = max(max(mpm(:,1:2:end),[],1));
% max_mpm_Y = max(max(mpm(:,2:2:end),[],1));
% min_mpm_X = min(min(mpm(:,1:2:end),[],1));
% min_mpm_Y = min(min(mpm(:,2:2:end),[],1));
% trans = [(min_mpm_X+max_mpm_X)/2;(min_mpm_Y+max_mpm_Y)/2];
res = tracks.resolution;
trans = [(res(1,1)+res(1,2))/2;(res(2,1)+res(2,2))/2];
cn = size(mpm,2)/2;
for i = 1:size(mpm,1)
    RepRow =reshape(mpm(i,:),2,cn);
    RepRow_centered = RepRow - repmat(trans,1,cn);
    rotatedRow_centered =  rotmat(angle)* RepRow_centered;
    rotatedRow = rotatedRow_centered +repmat(trans,1,cn);
    mpm(i,:) = reshape(rotatedRow,1,cn*2);
end
tracks.midpointMatrix = mpm;
tracks.rotation = wrapTo2Pi(tracks.rotation+angle);
end

