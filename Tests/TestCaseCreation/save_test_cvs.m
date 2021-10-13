function [] = save_test_cvs(tracks_mat,csvPath)
nRows = length(tracks_mat(:,1,1));
FrameNr = (1:nRows)';

NumberMidPoints = cellfun(@(x) length(x(~isnan(x))),num2cell(tracks_mat(:,:,1),2));
T = table(FrameNr,NumberMidPoints);
for i = 1:size(tracks_mat,2)
    xCol_title = ['MidPoint_' num2str(i) '_x'];
    yCol_title = ['MidPoint_' num2str(i) '_y'];
    T_ = table(tracks_mat(:,i,1),tracks_mat(:,i,2),'VariableNames',{xCol_title,yCol_title});    
    T = [T T_];
end
writetable(T,csvPath)

end