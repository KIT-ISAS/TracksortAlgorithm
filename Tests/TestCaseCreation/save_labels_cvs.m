function [] = save_labels_cvs(tracks_mat,csvPath)
frameNr = (1:length(tracks_mat(:,1,1)))';
T = table(frameNr);
for i = 1:size(tracks_mat,2)
    xCol_title = ['MidPointX' num2str(i)];
    yCol_title = ['MidPointY' num2str(i)];
    T_ = table(tracks_mat(:,i,1),tracks_mat(:,i,2),'VariableNames',{xCol_title,yCol_title});    
    T = [T T_];
    
end
writetable(T,csvPath)

end