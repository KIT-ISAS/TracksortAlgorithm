function [handles] = arrangeComponents( handles )
%GUICOMPONENTS Summary of this function goes here
%   Detailed explanation goes here

handles.tgroup = uitabgroup('Parent', handles.figure1,'Position',[0.05 0.03 .8 .32]);%,'BackgroundColor',[80,80,80]/255);
handles.tab_file = uitab('Parent', handles.tgroup, 'Title', 'file');
handles.tab_play = uitab('Parent', handles.tgroup, 'Title', 'play');
handles.tab_plotting = uitab('Parent', handles.tgroup, 'Title', 'plotting');
handles.tab_disturbances = uitab('Parent', handles.tgroup, 'Title', 'disturbances');


%%%%%% tab_file
tab_file_hlist = [handles.pushbutton_open_data_path handles.pushbutton_open_data_file ...
    handles.pushbutton_edit_config_file handles.pushbutton_open_history handles.pushbutton_save_history];
first_pos =  [0.01    0.75    0.1423    0.1683];
first_pos = first_pos + [0 0 first_pos(3)*0.3 first_pos(4)*0.01];
horiz_shft = 0.2;
verti_shft = -0.18;

g = makeAllignmentGrid(first_pos,5,horiz_shft,verti_shft);

set(tab_file_hlist(1),'Parent',handles.tab_file,'Units','normalized','Position',g(:,1,1));
set(tab_file_hlist(2), 'Parent',handles.tab_file,'Units','normalized','Position',g(:,1,2));
set(tab_file_hlist(3), 'Parent',handles.tab_file,'Units','normalized','Position',g(:,1,3));
set(tab_file_hlist(4), 'Parent',handles.tab_file,'Units','normalized','Position',g(:,2,1));
set(tab_file_hlist(5), 'Parent',handles.tab_file,'Units','normalized','Position',g(:,2,2));
dDBtnGr=dataDirection_btnGrp(handles);
set(dDBtnGr, 'Parent',handles.tab_file,'Units','normalized','Position',align2grid(g,3,3,dDBtnGr));

%%%%%% tab_play


set(handles.text_resolution ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,1,1));
set(handles.edit_resolution ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,2,1));
set(handles.text_band_edge ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,1,2));
set(handles.edit_band_edge ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,2,2));
set(handles.text_prediction_only ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,1,3));
set(handles.edit_prediction_only ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,2,3));
set(handles.text_frame ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,3,1));
set(handles.slider_frame ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,4,1));
set(handles.text_frameDisp ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,5,1,handles.text_frameDisp));
set(handles.text_pause ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,3,2));
set(handles.slider_pause ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,4,2));
set(handles.text_pauseDisp ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,5,2,handles.text_pauseDisp));
set(handles.text_Algorithm ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,3,3));
set(handles.popupmenu_algorithms ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,4,3));
set(handles.pushbutton_save_load_parameters,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,1,4));
set(handles.pushbutton_default_parameters,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,2,4));

set(handles.togglebutton_sim_s,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,3,5));
set(handles.togglebutton_sim_p,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,4,5));

set(handles.togglebutton_play_algorithm ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,5,3));
set(handles.togglebutton_play_history ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,5,4));
set(handles.pushbutton_evaluate ,'Parent',handles.tab_play,'Units','normalized','Position',align2grid(g,5,5));

%%%%%% tab_plotting

set(handles.checkbox_measurements ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,1,1));
set(handles.checkbox_background ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,2,1));
set(handles.checkbox_tracks ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,3,1));
set(handles.checkbox_markers ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,4,1));
set(handles.checkbox_track_IDs ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,5,1));
set(handles.checkbox_pred_beam ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,1,2));
set(handles.togglebutton_undock ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,1,3));
set(handles.popupmenu_tracks_color ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,3,2));
set(handles.popupmenu_markers_color ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,4,2));
set(handles.popupmenu_tracks_IDs_color ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,5,2));
set(handles.text_RGB ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,2,3));
set(handles.edit_track_color ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,3,3));
set(handles.edit_marker_color ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,4,3));
set(handles.edit_id_color,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,5,3));
set(handles.text_tracks_width ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,2,4));
set(handles.slider_tracks_width ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,3,4));
set(handles.text_tracks_length ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,2,5));
set(handles.slider_track_length ,'Parent',handles.tab_plotting,'Units','normalized','Position',align2grid(g,3,5));


%%%%%%% tab_disturbances
set(handles.text_clutter_dens ,'Parent',handles.tab_disturbances,'Units','normalized','Position',align2grid(g,1,1));
set(handles.edit_clutter_dens ,'Parent',handles.tab_disturbances,'Units','normalized','Position',align2grid(g,2,1));
set(handles.pushbutton_apply_clutter ,'Parent',handles.tab_disturbances,'Units','normalized','Position',align2grid(g,3,1));
set(handles.text_noise ,'Parent',handles.tab_disturbances,'Units','normalized','Position',align2grid(g,1,2));
set(handles.edit_noise ,'Parent',handles.tab_disturbances,'Units','normalized','Position',align2grid(g,2,2));
set(handles.pushbutton_apply_noise ,'Parent',handles.tab_disturbances,'Units','normalized','Position',align2grid(g,3,2));

end

