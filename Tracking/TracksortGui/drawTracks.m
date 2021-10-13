function drawTracks(currentAxes,trackHistory,t,imagePath,measurements,pred_edge)
%DRAWTRACKS Summary of this function goes here
%   Detailed explanation goes here
global tracks;
global MAX_NUM_TRACKS;
cmap = hsv(15);
if  exist('tracks','var') && ~isfield(tracks,'lines')
    tracks.lines.handles = zeros(1,max(length(trackHistory),MAX_NUM_TRACKS));
    tracks.lines.visibility = 1;
    tracks.lines.width = 1;
    tracks.predLines.handles = tracks.lines.handles;
    tracks.predLines.visibility = 1;
    tracks.draw_length = inf;
    color = 'auto';
    tracks.lines.color = color;
    tracks.scatters.handles = zeros(1,max(length(trackHistory),MAX_NUM_TRACKS));
    tracks.scatters.visibility = 1;
    color = 'auto';
    tracks.scatters.color = color;
    tracks.texts.handles = zeros(1,max(length(trackHistory),MAX_NUM_TRACKS));
    tracks.texts.visibility = 1;
    color = 'auto';
    tracks.texts.color = color;
    tracks.background = 0;
    tracks.measurements = 0;
end
if nargin>2 && ~isempty(imagePath) && tracks.backgroundDraw
    img=imread(imagePath);
    if tracks.background ~= 0 && ishandle(tracks.background)
        delete(tracks.background);
%         tracks.background = 0 ;
    end
%     tracks.background = image([tracks.resolution(1),tracks.resolution(3)],[tracks.resolution(4),tracks.resolution(2)],img);
%     uistack(tracks.background,'bottom');
    if abs(tracks.rotImageBy-0)<eps % Do not touch data if no rotation is to be performed.    
        imgRot = img;
    else
        imgRot = imrotate(img, rad2deg(tracks.rotImageBy), 'bicubic'); % This may not work for other angles that are not a multiple of pi/2
    end
    if tracks.mirrorImage(1)
        imgRot = flipud(imgRot);
    end
    if tracks.mirrorImage(2)
        imgRot = fliplr(imgRot);
    end
    tracks.background = image([tracks.resolution(1),tracks.resolution(3)],[tracks.resolution(4),tracks.resolution(2)],imgRot,'Parent',currentAxes);
    uistack(tracks.background,'bottom');
    
end
% elseif  tracks.backgroundDraw
%     set(axes,'Color','k')
% end

%% draw measurements
if nargin>2 && ~isempty(measurements) && tracks.measurementsDraw
    if tracks.measurements ~= 0
        delete(tracks.measurements);
        tracks.measurements = 0 ;
    end
    tracks.measurements = scatter(tracks.axes,measurements(1,:),measurements(2,:),'p','g','LineWidth',1);
    %         'g','MarkerFaceColor','g');
end
%%
for i = 1:length(trackHistory)
    track= trackHistory(i);
    %     if  track.startTime <= t && track.LastSeenTime >= t
    trackData=track.Posterior;
    ind = t-track.StartTime +1; % index in posterior of the current moment
    if isnan(ind), continue; end
    if ind>0 && ind <= size(trackData,2)
        len = min(tracks.draw_length,ind);
        XdataUntil_t=trackData(1,ind-len+1:ind);
        YdataUntil_t=trackData(2,ind-len+1:ind);
        color = cmap(mod(i,15)+1,:);
        if ~tracks.lines.handles(i)  && tracks.lines.visibility
            if ~strcmpi(tracks.lines.color,'auto');color = tracks.lines.color ;end
            tracks.lines.handles(i)=line(XdataUntil_t,YdataUntil_t,'Parent',tracks.axes,'color',color,'linewidth',tracks.lines.width);
        elseif tracks.lines.visibility
            set(tracks.lines.handles(i),'XData',XdataUntil_t,'Ydata',YdataUntil_t);%,'linewidth',tracks.lines.width);
        end
        if ~tracks.scatters.handles(i)  && tracks.scatters.visibility
            if ~strcmpi(tracks.scatters.color,'auto');  color=tracks.scatters.color;end
            tracks.scatters.handles(i) = scatter(XdataUntil_t,YdataUntil_t,'x','MarkerEdgeColor', color,'Parent',tracks.axes);
        elseif tracks.scatters.visibility
            set(tracks.scatters.handles(i),'XData',XdataUntil_t,'Ydata',YdataUntil_t)
        end
        if ~tracks.texts.handles(i)  && tracks.texts.visibility
            if ~strcmpi(tracks.texts.color,'auto'); color= tracks.texts.color ;end
            tracks.texts.handles(i) = text(trackData(1,ind),trackData(2,ind),sprintf('%d',i),'Parent',tracks.axes,'FontSize',14,'Color',color);
        elseif tracks.texts.visibility
            set(tracks.texts.handles(i),'Position',[trackData(1,ind),trackData(2,ind)])
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%% draw prediction beam
        if nargin>5
            tracks.Pred_edge = pred_edge;
        end
        if tracks.predLines.visibility && ~isempty(track.PredictedX)&&~isnan(track.PredictedX) ...
                && abs(YdataUntil_t(end)-tracks.Pred_edge) < abs(tracks.Pred_edge - tracks.predictOnlyStart)...
                && abs(YdataUntil_t(end)- tracks.predictOnlyStart)< abs(tracks.Pred_edge - tracks.predictOnlyStart)
            rotation = wrapToPi(tracks.rotation);
            if rotation == pi/2 || rotation == -pi/2
                Xdata_predLine = [XdataUntil_t(end) tracks.Pred_edge];
                Ydata_predLine = [YdataUntil_t(end) track.PredictedX];
            else
                Xdata_predLine = [XdataUntil_t(end) track.PredictedX];
                Ydata_predLine = [YdataUntil_t(end) tracks.Pred_edge];
            end
            tracks.predLines.color = color;
            if tracks.predLines.handles(i)
                set(tracks.predLines.handles(i),'XData',Xdata_predLine,'Ydata',Ydata_predLine);
            else
                tracks.predLines.handles(i)=line(Xdata_predLine,Ydata_predLine,'Parent',tracks.axes,'color',tracks.predLines.color,'linewidth',tracks.lines.width/3,'Marker','o','LineStyle','--');
            end
        elseif  (YdataUntil_t(end)>tracks.Pred_edge || YdataUntil_t(end) < tracks.predictOnlyStart)&& tracks.predLines.handles(i)
            delete(tracks.predLines.handles(i));tracks.predLines.handles(i) = 0;
        end
        %%%%%%%%%%%%%%%%%%%%%%% draw prediction beam
        
    else
        try
            if tracks.lines.handles(i)
                delete(tracks.lines.handles(i));tracks.lines.handles(i) = 0;
            end
            if tracks.scatters.handles(i)
                delete(tracks.scatters.handles(i));tracks.scatters.handles(i) = 0;
            end
            if tracks.texts.handles(i)
                delete(tracks.texts.handles(i));tracks.texts.handles(i) = 0;
            end
            if tracks.predLines.handles(i)
                delete(tracks.predLines.handles(i));tracks.predLines.handles(i) = 0;
            end
        catch e
            warning(e.message)
        end
    end
    
end
uistack(tracks.scatters.handles(tracks.scatters.handles ~=0),'top'); % move markers to the top of the plot


end

