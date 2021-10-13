function [ nonstop ] = delegation_to_draw(t,trackHistory,handles,hObject)

if ~isvalid(hObject)
    error('Cannot access GUI. Maybe GUI has been closed?');
end

nonstop = get(hObject,'value');
if ~nonstop; return; end
global tracks
imagePath = '';
measurements=[];
if get(handles.checkbox_background,'Value')
    imagePath = fullfile(tracks.imagePath,tracks.background_images{t});
end
if get(handles.checkbox_measurements,'Value')
    if isfield(tracks,'midpointMatrix')
        measurements = [tracks.midpointMatrix(t,...
            1:2:2*tracks.numberOfMidpoints(t));...
            tracks.midpointMatrix(t,2:2:2*tracks.numberOfMidpoints(t))];
    elseif isfield(trackHistory,'RawMeasurements')
        for i= 1:length(trackHistory)
            track= trackHistory(i);
            MeasData=track.RawMeasurements;
            ind = t-track.StartTime +1; % index in posterior of the current moment
            if isnan(ind)l, continue; end
            if ind>0 && ind <= size(MeasData,2)
                Xmeas=MeasData(1,ind);
                Ymeas=MeasData(2,ind);
                measurements =[measurements [Xmeas;Ymeas]];
            end
        end
    end
end
if (get(handles.checkbox_tracks,'Value') || get(handles.checkbox_pred_beam,'Value')...
       || get(handles.checkbox_markers,'Value')|| get(handles.checkbox_track_IDs,'Value'))||~isempty(trackHistory)
    drawTracks(handles.axes1,trackHistory,t,imagePath,measurements);
end
tracks.dt = get(handles.slider_pause,'value');
set(handles.slider_frame,'value',tracks.t);
set(handles.text_frameDisp,'string',tracks.t);
title(tracks.axes,['frame ' num2str(t)])
if tracks.dt>0
    pause(tracks.dt) % No need to call drawnow because pause already causes axes to redraw
else
    drawnow 
end


