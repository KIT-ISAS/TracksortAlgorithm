function [allTracks, deleteTrackList] = updateTrackScores(allTracks, disapearedTrackList, scoreParam)
for trackNo = disapearedTrackList
    allTracks(trackNo).TrackScore = allTracks(trackNo).TrackScore - scoreParam.looseStep;
end
for trackNo = setdiff(1:numel(allTracks), disapearedTrackList)
    allTracks(trackNo).TrackScore = min(allTracks(trackNo).TrackScore+scoreParam.winStep, scoreParam.maxScore);
end
deleteTrackList = find([allTracks.TrackScore] < scoreParam.trackRemoveLevel);
end