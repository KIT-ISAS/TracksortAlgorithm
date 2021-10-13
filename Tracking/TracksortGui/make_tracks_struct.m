function make_tracks_struct(handles)

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

global tracks;
global MAX_NUM_TRACKS
tracks.backgroundDraw = get(handles.checkbox_background,'value'); 
tracks.measurementsDraw =  get(handles.checkbox_measurements,'value');
tracks.draw_length = get(handles.slider_track_length,'value');
tracks.t = get(handles.slider_frame,'value');
tracks.predictOnlyStart = str2double(get(handles.edit_prediction_only,'String'));
tracks.Pred_edge = str2double(get(handles.edit_band_edge,'String'));
tracks.lines.handles = zeros(1,MAX_NUM_TRACKS);
tracks.lines.visibility = get(handles.checkbox_tracks,'Value');
tracks.lines.width = 1;
tracks.predLines.handles = tracks.lines.handles;
tracks.predLines.visibility = get(handles.checkbox_pred_beam,'Value');;
contents = cellstr(get(handles.popupmenu_tracks_color,'String'));
color = contents{get(handles.popupmenu_tracks_color,'Value')};
tracks.lines.color = color;
tracks.scatters.handles = zeros(1,MAX_NUM_TRACKS);
tracks.scatters.visibility = get(handles.checkbox_markers,'Value');
contents = cellstr(get(handles.popupmenu_markers_color,'String'));
color = contents{get(handles.popupmenu_markers_color,'Value')};
tracks.scatters.color = color;
tracks.texts.handles = zeros(1,MAX_NUM_TRACKS);
tracks.texts.visibility =get(handles.checkbox_track_IDs,'Value');
contents = cellstr(get(handles.popupmenu_tracks_IDs_color,'String'));
color = contents{get(handles.popupmenu_tracks_IDs_color,'Value')};
tracks.texts.color = color;
% h=newHandle;
% h.Type='Image';
tracks.background = 0;
% h.Type='Scatter';
tracks.measurements = 0;

end



