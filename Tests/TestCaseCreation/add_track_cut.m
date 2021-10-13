function track  =  add_track_cut(track,nanIndex)
len = length(track);

nanIndex = sort(nanIndex);
if max(nanIndex)<= len
    track(nanIndex) = nan;
else
    track(nanIndex<= len) = nan;
    track = [track zeros(1,max(nanIndex)-len)];
    
end