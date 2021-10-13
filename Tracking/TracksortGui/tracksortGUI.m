function varargout = tracksortGUI(varargin)
% TRACKSORTGUI MATLAB code for tracksortGUI.fig
%      TRACKSORTGUI, by itself, creates a new TRACKSORTGUI or raises the existing
%      singleton*.
%
%      H = TRACKSORTGUI returns the handle to a new TRACKSORTGUI or the handle to
%      the existing singleton*.
%
%      TRACKSORTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACKSORTGUI.M with the given input arguments.
%
%      TRACKSORTGUI('Property','Value',...) creates a new TRACKSORTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before tracksortGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to tracksortGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help tracksortGUI

% Last Modified by GUIDE v2.5 11-Jan-2017 09:44:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @tracksortGUI_OpeningFcn, ...
    'gui_OutputFcn',  @tracksortGUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before tracksortGUI is made visible.
function tracksortGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to tracksortGUI (see VARARGIN)

% Choose default command line output for tracksortGUI
clearvars -global tracks
cla(handles.axes1);
global newStart
global tracks;
global MAX_NUM_TRACKS;
MAX_NUM_TRACKS = 10000;
make_tracks_struct(handles)
tracks.resolution= str2num(get(handles.edit_resolution,'String'));
newStart = true;
handles = arrangeComponents(handles);
addpath(genpath('../../GUI/'));
addpath(genpath('../GUI/'));
handles.output = hObject;
% set(hObject,'toolbar','figure');
handles.trackHistory = [];
handles.path = [];
tracks.axes = handles.axes1;
tracks.rotation = 0;
make_tracks_struct(handles);
tracks.resolution= str2num(get(handles.edit_resolution,'String'));
tracks.predictionLine = line([tracks.resolution(1,1),tracks.resolution(1,2)],[tracks.predictOnlyStart tracks.predictOnlyStart],'color','g');
tracks.pred_line = line([tracks.resolution(1,1),tracks.resolution(1,2)],[tracks.Pred_edge tracks.Pred_edge],'color','w','LineWidth',2);
set(handles.text_frameDisp,'string',num2str(get(handles.slider_frame,'value')));
set(handles.text_pauseDisp,'string',num2str(get(handles.slider_pause,'value')));
start_state(handles)
hold(handles.axes1,'on')

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes tracksortGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = tracksortGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_open_history.
function pushbutton_open_history_Callback(hObject, eventdata, handles, pathname, filename)
% hObject    handle to pushbutton_open_history (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if nargin<5
    [filename, pathname] = uigetfile();
end
if filename == 0
    return
end
load(fullfile(pathname, filename));
handles.trackHistory = trackHistory;
if isempty(trackHistory)
    error('History is empty, plotting does not make sense');
end
delete_elements()
global tracks;
make_tracks_struct(handles);
if exist('env','var')
    tracks.predictOnlyStart = env.predictionOnlyStart;
    tracks.Pred_edge = env.Pred_edge;
    tracks.resolution = env.resolution;
    tracks.imagePath = env.imagePath;
    tracks.rotImageBy = env.rotateBy;
else % env parameters were not saved. Falling back to some other parameters that can make sense for the scenario.
    tracks.resolution=[min([trackHistory.RawMeasurements],[],2),max([trackHistory.RawMeasurements],[],2)];
    tracks.Pred_edge=-1;
    tracks.predictOnlyStart=-1;
    tracks.imagePath='';
end
if ~isempty(tracks.imagePath)
    [background_images,~] = read_background_images(tracks.imagePath);
    tracks.background_images = background_images;
else
    tracks.backgroundDraw = 0;
end

axis(handles.axes1,[tracks.resolution(1,:),tracks.resolution(2,:)]);

if exist('env','var')&&isfield(env,'rotation')
    tracks.rotation = env.rotation;
end
rotation = wrapToPi(tracks.rotation);
if rotation == pi || rotation == 0
    setPredLines(1)
elseif rotation == pi/2 || rotation == -pi/2
    setPredLines(2)
end
tracks.t = 1;
guidata(hObject, handles);


% --- Executes on button press in togglebutton_play_algorithm.
function togglebutton_play_algorithm_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_play_algorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks;
algorithm_id = get(handles.popupmenu_algorithms,'Value');
if isempty(handles.path) && get(hObject,'Value')
    errordlg('please select a data path!')
    set(hObject,'Value',0);
    return
end
if get(hObject,'Value') && ~isempty(handles.path)
    %     cla;
    %     tracks.line = [];
    switch algorithm_id
        case 1
            algorithm = @tracksortAlgorithm;
        case 2
            algorithm = @tracksortAlgorithm_JPDA_cheap;
        case 3
            algorithm = @tracksortAlgorithm_JPDA;
        otherwise
            errordlg('no algorthims has been choosed');
    end
    
    delete_elements();
    
    %     tracks.dt = get(handles.slider_pause,'value');
    make_tracks_struct(handles);
    set(handles.slider_frame,'Enable','off');
    set(handles.togglebutton_play_history,'Enable','off');
    %     set(handles.togglebutton_undock,'Enable','off');
    allParam=getDefaultParam;
    allParam.plot.delegation_to_draw=@delegation_to_draw;
    allParam.plot.handles=handles;
    allParam.plot.hObject=hObject;
    if isfield(tracks,'midpointMatrix') && isfield(tracks,'numberOfMidpoints')&&isfield(tracks,'orientationMatrix')
        handles.trackHistory = algorithm(tracks.resolution, tracks.predictOnlyStart,tracks.Pred_edge,allParam,handles.path,...
            tracks.midpointMatrix,tracks.orientationMatrix);
    elseif isfield(tracks,'midpointMatrix') && isfield(tracks,'numberOfMidpoints')
        handles.trackHistory = algorithm(tracks.resolution, tracks.predictOnlyStart,tracks.Pred_edge,allParam,handles.path,...
            tracks.midpointMatrix);
    else
        handles.trackHistory = algorithm(tracks.resolution, tracks.predictOnlyStart,tracks.Pred_edge,allParam,handles.path);
    end

    set(hObject,'Value',0)
    set(handles.slider_frame,'Enable','on');
    set(handles.togglebutton_play_history,'Enable','on');
    %     set(handles.togglebutton_undock,'Enable','on');
    
    tracks.t = 1;
    %    set(handles.slider_frame,'Value',1);
    %    set(handles.text_frameDisp,'String','1');
    %    set(handles.slider7,'Enable','off');
    %    delete(get(handles.slider7,'UserData'));
    guidata(hObject, handles);
end


% --- Executes on button press in togglebutton_play_history.
function togglebutton_play_history_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_play_history (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_play_history
trackHistory = handles.trackHistory;
if isempty(trackHistory)
    errordlg('there is no history, please select one!')
    set(hObject,'Value',0);
    return;
end
global tracks;
if get(hObject,'Value')
    delete_elements()
end
tracks.dt = get(handles.slider_pause,'value');
maxlength = 0;
firstFrameWithContent=trackHistory(1).StartTime;
% extract the max end time of tracks in trackHistory
for i = 1:length(trackHistory)
    newVal = trackHistory(i).StartTime + size(trackHistory(i).Posterior,2)-1;
    if newVal > maxlength
        maxlength = newVal;
    end
    if trackHistory(i).StartTime<firstFrameWithContent
        firstFrameWithContent=trackHistory(i).StartTime;
    end
end
if tracks.t>maxlength
    set(handles.slider_frame,'value',1);
    tracks.t = 1;
elseif tracks.t<firstFrameWithContent
    tracks.t=firstFrameWithContent;
end
set(handles.slider_frame,'Max',maxlength,'SliderStep',[1 ,10]/maxlength);
while get(hObject,'Value') && ishandle(handles.figure1)
    if tracks.t>maxlength
        set(hObject,'Value',0);
        break;
    end
    delegation_to_draw(tracks.t,trackHistory,handles,hObject);
    tracks.t  = tracks.t +1;
end


% --- Executes on slider movement.
function slider_frame_Callback(hObject, eventdata, handles)
% hObject    handle to slider_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% cla(handles.axes1);
global tracks;
newVal = round(get(hObject,'Value'));
set(hObject,'Value',newVal);
set(handles.text_frameDisp,'string',num2str(newVal));
tracks.t = newVal;
try
    delegation_to_draw(tracks.t,handles.trackHistory,handles,hObject);
catch ex
    warning(ex.message)
end

% --- Executes during object creation, after setting all properties.
function slider_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider_pause_Callback(hObject, eventdata, handles)
% hObject    handle to slider_pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global tracks;
tracks.dt = get(hObject,'Value') ;
set(handles.text_pauseDisp,'string',num2str(tracks.dt));


% --- Executes during object creation, after setting all properties.
function slider_pause_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_pause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes on button press in checkbox_tracks.
function checkbox_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_tracks
setVisibleCheckbox(hObject,'lines')




% --- Executes on button press in checkbox_markers.
function checkbox_markers_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_markers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_markers

setVisibleCheckbox(hObject,'scatters')


% --- Executes on button press in checkbox_track_IDs.
function checkbox_track_IDs_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_track_IDs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_track_IDs
setVisibleCheckbox(hObject,'texts')


% --- Executes on button press in checkbox_pred_beam.
function checkbox_pred_beam_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_pred_beam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_pred_beam

setVisibleCheckbox(hObject,'predLines')

function setVisibleCheckbox(hObject,komponent)
global tracks;
try
    linesH = tracks.(komponent).handles;
    linesH = linesH(linesH ~=0);
    if  get(hObject,'Value')
        set(linesH,'Visible','on');
        tracks.(komponent).('visibility')=1;
    else
        set(linesH,'Visible','off');
        tracks.(komponent).('visibility')=0;
    end
catch ex
    if strcmp(ex.identifier,'MATLAB:nonExistentField')
        warning(ex.message);
    end
end


% --- Executes on slider movement.
function slider_tracks_width_Callback(hObject, eventdata, handles)
% hObject    handle to slider_tracks_width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global tracks;
if ~isfield(tracks,'lines') return; end
val = get(hObject,'Value');
tracks.lines.width = val;
linesH = tracks.lines.handles;
linesH = linesH(linesH~=0);
set(linesH,'linewidth',val)



% --- Executes during object creation, after setting all properties.
function slider_tracks_width_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_tracks_width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in popupmenu_tracks_color.
function popupmenu_tracks_color_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_tracks_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_tracks_color contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_tracks_color
global tracks;
tracks.lines.color = popupmenu_setcolor(hObject,tracks.lines.handles,'Color');

% --- Executes during object creation, after setting all properties.
function popupmenu_tracks_color_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_tracks_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_markers_color.
function popupmenu_markers_color_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_markers_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_markers_color contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_markers_color

global tracks;
tracks.scatters.color = popupmenu_setcolor(hObject,tracks.scatters.handles,'MarkerEdgeColor');


% --- Executes during object creation, after setting all properties.
function popupmenu_markers_color_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_markers_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_tracks_IDs_color.
function popupmenu_tracks_IDs_color_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_tracks_IDs_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_tracks_IDs_color contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_tracks_IDs_color
global tracks;
tracks.texts.color = popupmenu_setcolor(hObject,tracks.texts.handles,'Color');

function color = popupmenu_setcolor(popupmenu_val,graphic_handles,prop)
contents = cellstr(get(popupmenu_val,'String')) ;
color = contents{get(popupmenu_val,'Value')};
graphic_handles = graphic_handles(graphic_handles~=0);
if ~strcmpi(color,'auto')
    set(graphic_handles,prop,color)
else
    cmap = hsv(15);
    for i =1:length(graphic_handles)
        auto_color = cmap(mod(i,15)+1,:);
        set(graphic_handles(i),prop,auto_color)
    end
end


% --- Executes during object creation, after setting all properties.
function popupmenu_tracks_IDs_color_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_tracks_IDs_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_open_data_path.
function pushbutton_open_data_path_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_open_data_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks;
filepath = uigetdir();
if filepath == 0
    return
end
dataPath = dir([filepath filesep '*.csv']);
if isempty(dataPath)
    dataPath = dir([filepath filesep '*.dat']);
    readDataFunction = @readIOSBData_dat;
else
    readDataFunction = @readIOSBData;
end
datafileName = fullfile(filepath, dataPath(1).name);
imagePath = filepath;
handles.path = filepath;
handles.trackHistory = [];
[numberOfMidpoints,midpointMatrix,~]=readDataFunction(datafileName);

%%
% when sequential data format is used
if isempty(midpointMatrix)
    [numberOfMidpoints,midpointMatrix,~]=readIOSBData_seq(datafileName);
end
tracks.midpointMatrix = midpointMatrix;
tracks.numberOfMidpoints = numberOfMidpoints;
[background_images,imageInfos] = read_background_images(imagePath);
tracks.background_images = background_images;
tracks.resolution = [0,imageInfos.Width;0,imageInfos.Height];
tracks.imagePath = imagePath;
axis(handles.axes1,[tracks.resolution(1,:),tracks.resolution(2,:)]);
set([handles.checkbox_background,handles.checkbox_measurements],'Enable','on');
setPredLines(1)
start_state(handles);

guidata(hObject, handles);

% --- Executes on button press in checkbox_background.
function checkbox_background_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_background
global tracks;
is_img_and_exists = strcmpi(get(tracks.background,'Type'),'Image') && ...
    strcmpi(get(tracks.background,'BeingDeleted'),'off');
if ~get(hObject,'Value')
    tracks.backgroundDraw = 0 ;
    if is_img_and_exists
        set(tracks.background,'Visible','off');
    end
else
    tracks.backgroundDraw = 1;
    if is_img_and_exists
        set(tracks.background,'Visible','on')
    end
    
end

% --- Executes on button press in checkbox_measurements.
function checkbox_measurements_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_measurements (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_measurements
global tracks;
is_scatter_and_exists = strcmpi(get(tracks.measurements,'Type'),'Scatter') && ...
    strcmpi(get(tracks.measurements,'BeingDeleted'),'off');
if ~get(hObject,'Value')
    tracks.measurementsDraw = 0;
    if is_scatter_and_exists
        set(tracks.measurements,'Visible','off');
    end
else
    tracks.measurementsDraw = 1;
    if is_scatter_and_exists
        set(tracks.measurements,'Visible','on')
    end
end

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% fpos = get(handles.figure1,'position');
% apos = get(handles.axes1,'position');
% apos = fpos *[0 0 0.8 0.8] + apos * [1 1 0 0];
% set(handles.axes1,'position',apos);


% --- Executes on slider movement.
function slider7_Callback(hObject, eventdata, handles)
% hObject    handle to slider7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% global tracks
% predictionLine = get(hObject,'UserData');
% value = floor(get(hObject,'value'));
% set(hObject,'Value',value);
% set(handles.text_prediction,'string',num2str(value));
% tracks.predictOnlyStart = value;
% --- Executes during object creation, after setting all properties.
function slider7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton_save_history.
function pushbutton_save_history_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_save_history (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks
[FileName,PathName] = uiputfile('*.mat', 'Save history as');
if FileName == 0
    return
end
trackHistory = handles.trackHistory;
filePath = fullfile(PathName,FileName);
if ~isfield(tracks,'imagePath')
    tracks.imagePath='';
end
if numel(filePath)>1&&~isempty(trackHistory)
    env = struct('predictionOnlyStart',tracks.predictOnlyStart,...
        'Pred_edge',tracks.Pred_edge,'resolution',tracks.resolution,...
        'imagePath',tracks.imagePath);
    if isfield(tracks,'rotation')
        if tracks.rotation ~= 0
            env = rotEnv(env,-tracks.rotation);
            trackHistory = rotTrackHis(trackHistory,-tracks.rotation,env);
        end
    end
    save(filePath,'trackHistory','env');
end


% --- Executes on slider movement.
function slider_track_length_Callback(hObject, eventdata, handles)
% hObject    handle to slider_track_length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global tracks;
newVal = round(get(hObject,'Value'));
set(hObject,'Value',newVal);
% set(handles.text_frameDisp,'string',num2str(newVal));
tracks.draw_length = newVal;

% --- Executes during object creation, after setting all properties.
function slider_track_length_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_track_length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in popupmenu_algorithms.
function popupmenu_algorithms_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_algorithms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_algorithms contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_algorithms


% --- Executes during object creation, after setting all properties.
function popupmenu_algorithms_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_algorithms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_track_color_Callback(hObject, eventdata, handles)
% hObject    handle to edit_track_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_track_color as text
%        str2double(get(hObject,'String')) returns contents of edit_track_color as a double
global tracks
color = getcolor(hObject);
if isempty(color)
    return
end
setcolor(tracks.lines.handles,color);
setcolor(tracks.predLines.handles,color);

tracks.lines.color = color;

function color = getcolor(hObject)
s = get(hObject,'String');
ind = regexpi(s,'\d+,\d+,\d+');
if isempty(ind)
    color = [];
    return
end
rgb_string = strsplit(s,',');
r = str2double(rgb_string(1));
g = str2double(rgb_string(2));
b = str2double(rgb_string(3));
color = [r,g,b]/255;


% --- Executes during object creation, after setting all properties.
function edit_track_color_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_track_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_marker_color_Callback(hObject, eventdata, handles)
% hObject    handle to edit_marker_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_marker_color as text
%        str2double(get(hObject,'String')) returns contents of edit_marker_color as a double
global tracks
color = getcolor(hObject);
if isempty(color)
    return
end
scattersH = tracks.scatters.handles;
scattersH = scattersH(scattersH~=0);
set(scattersH,'MarkerEdgeColor',color);
tracks.scatters.color = color;

% --- Executes during object creation, after setting all properties.
function edit_marker_color_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_marker_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_id_color_Callback(hObject, eventdata, handles)
% hObject    handle to edit_id_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_id_color as text
%        str2double(get(hObject,'String')) returns contents of edit_id_color as a double
global tracks
color = getcolor(hObject);
if isempty(color)
    return
end
setcolor(tracks.texts.handles,color);
tracks.texts.color = color;

% --- Executes during object creation, after setting all properties.
function edit_id_color_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_id_color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider_clutter_density_Callback(hObject, eventdata, handles)
% hObject    handle to slider_clutter_density (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
dens = get(hObject,'Value');
set(handles.text_clutter_dens_value,'string',num2str(dens))




% --- Executes during object creation, after setting all properties.
function slider_clutter_density_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_clutter_density (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton_apply_clutter.
function pushbutton_apply_clutter_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_apply_clutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks;
dens = str2double(get(handles.edit_clutter_dens,'String'));
if isfield(tracks,'resolution')&& isfield(tracks,'midpointMatrix') && isfield(tracks,'numberOfMidpoints')
    %     [m,n] = add_cltr(tracks.resolution,tracks.midpointMatrix,tracks.numberOfMidpoints,dens);
    [m,n] = add_cltr_around_mes([20,20],tracks.midpointMatrix,tracks.numberOfMidpoints,dens);
    tracks.midpointMatrix = m;
    tracks.numberOfMidpoints = n;
end


% --- Executes on slider movement.
function slider_noise_Callback(hObject, eventdata, handles)
% hObject    handle to slider_noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider_noise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton_apply_noise.
function pushbutton_apply_noise_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_apply_noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks;
sigma = str2num(get(handles.edit_noise,'String'));
if isfield(tracks,'resolution')&& isfield(tracks,'midpointMatrix') && isfield(tracks,'numberOfMidpoints')
    %     mu = [1 2];
    s = tracks.midpointMatrix;
    for i = 1:size(s,1)
        for j = 1:2:size(s,2)
            if isnan(s(i,j))
                break;
            end
            R = chol(sigma);
            tracks.midpointMatrix(i,j:j+1) = s(i,j:j+1) + randn(1,2)*R; % + repmat(mu,10,1)
        end
    end
end



function edit_clutter_dens_Callback(hObject, eventdata, handles)
% hObject    handle to edit_clutter_dens (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_clutter_dens as text
%        str2double(get(hObject,'String')) returns contents of edit_clutter_dens as a double


% --- Executes during object creation, after setting all properties.
function edit_clutter_dens_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_clutter_dens (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_noise_Callback(hObject, eventdata, handles)
% hObject    handle to edit_noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_noise as text
%        str2double(get(hObject,'String')) returns contents of edit_noise as a double


% --- Executes during object creation, after setting all properties.
function edit_noise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_evaluate.
function pushbutton_evaluate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_evaluate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks;
trackHistory = handles.trackHistory;
[trackHistory,predictErrorTracksort,predictErrorTracksortTime,...
    predictErrorLine, predictErrorLineTime] = evaluateTracking(trackHistory,...
    tracks.predictOnlyStart,tracks.Pred_edge, tracks.resolution);
handles.trackHistory = trackHistory;

assignin('base', 'predictErrorTracksort', predictErrorTracksort);
assignin('base', 'predictErrorTracksortTime', predictErrorTracksortTime);
assignin('base', 'predictErrorLine', predictErrorLine);
assignin('base', 'predictErrorLineTime', predictErrorLineTime);
guidata(hObject, handles);


function edit_band_edge_Callback(hObject, eventdata, handles)
% hObject    handle to edit_band_edge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_band_edge as text
%        str2double(get(hObject,'String')) returns contents of edit_band_edge as a double
global tracks;
tracks.Pred_edge = str2double(get(hObject,'String'));
set(tracks.pred_line,'YData',[tracks.Pred_edge,tracks.Pred_edge]);

% --- Executes during object creation, after setting all properties.
function edit_band_edge_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_band_edge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_prediction_only_Callback(hObject, eventdata, handles)
% hObject    handle to edit_prediction_only (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_prediction_only as text
%        str2double(get(hObject,'String')) returns contents of edit_prediction_only as a double
global tracks;
tracks.predictOnlyStart = str2double(get(hObject,'String'));
predictionLine = tracks.predictionLine;
set(predictionLine,'YData',[tracks.predictOnlyStart,tracks.predictOnlyStart]);

% --- Executes during object creation, after setting all properties.
function edit_prediction_only_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_prediction_only (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_open_data_file.
function pushbutton_open_data_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_open_data_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks;
readDataFunction = '';
[fileName,filepath] = uigetfile('*.csv;*.dat;*.mat','File Selector');
if fileName == 0
    return
end
[~,~,fileExt] = fileparts(fileName);
datafileName = fullfile(filepath,fileName);

if strcmpi(fileExt,'.dat')
    readDataFunction = @readIOSBData_dat;
elseif strcmpi(fileExt,'.csv')
    readDataFunction = @readIOSBData;
else
    load(datafileName);
end
handles.path = filepath;
handles.trackHistory = [];

if ~isempty(readDataFunction)
    [numberOfMidpoints,midpointMatrix,~]=readDataFunction(datafileName);
    if isempty(midpointMatrix)
        [numberOfMidpoints,midpointMatrix,~]=readIOSBData_seq(datafileName);
    end
end
% %%
% % flip data
% midpointMatrix=repmat(max(midpointMatrix,[],1),size(midpointMatrix,1),1)-midpointMatrix;
% %%

if exist('orientationMatrix','var')
    tracks.orientationMatrix=orientationMatrix;
end
% Format of midpoint matrix: 1st dim: coordinate, 2nd dim: particle, 3rd dim: time step
if ismatrix(midpointMatrix) % Convert if other format
    midpointMatrix=reshape(midpointMatrix',[2,size(midpointMatrix,2)/2,size(midpointMatrix,1)]);
end
resolution=NaN(2,2);
resolution(1,1)=min(min(midpointMatrix(1,:,:)));
resolution(1,2)=max(max(midpointMatrix(1,:,:)));
resolution(2,1)=min(min(midpointMatrix(2,:,:)));
resolution(2,2)=max(max(midpointMatrix(2,:,:)));
tracks.midpointMatrix = midpointMatrix;
tracks.numberOfMidpoints = numberOfMidpoints;
tracks.resolution= resolution;
set_edit_resolution(handles.edit_resolution,resolution);
% tracks.resolution= str2num(get(handles.edit_resolution,'String'));
axis(handles.axes1,[tracks.resolution(1,:),tracks.resolution(2,:)]);
set(handles.checkbox_measurements,'Enable','on');
set(handles.checkbox_background,'Enable','off');
set(handles.checkbox_background,'Value',0);
tracks.predictOnlyStart = 0.7 * (resolution(2,2)-resolution(2,1)) + resolution(2,1);
tracks.Pred_edge = 0.9 * (resolution(2,2)-resolution(2,1)) + resolution(2,1);
set(handles.edit_band_edge,'String',num2str(tracks.Pred_edge))
set(handles.edit_prediction_only,'String',num2str(tracks.predictOnlyStart))
set(tracks.predictionLine,'xdata',[0,tracks.resolution(1,2)],'ydata',[tracks.predictOnlyStart tracks.predictOnlyStart])
set(tracks.pred_line,'xdata',[0,tracks.resolution(1,2)],'ydata',[tracks.Pred_edge tracks.Pred_edge])
tracks.backgroundDraw = 0;
start_state(handles);

guidata(hObject, handles);


function edit_resolution_Callback(hObject, eventdata, handles)
% hObject    handle to edit_resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_resolution as text
%        str2double(get(hObject,'String')) returns contents of
%        edit_resolution as a double
global tracks;
tracks.resolution= str2num(get(handles.edit_resolution,'String'));
axis(handles.axes1,[tracks.resolution(1,:),tracks.resolution(2,:)]);


% --- Executes during object creation, after setting all properties.
function edit_resolution_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_resolution (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_edit_config_file.
function pushbutton_edit_config_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_edit_config_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
edit config_parameters.m
% [filename,pathname] = uigetfile();
% if filename == 0
%     return
% end
% global tracks;
% tracks.config_file = fullfile(pathname,filename);

% --- Executes on button press in togglebutton_sim_s.
function togglebutton_sim_s_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_sim_s (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_sim_s
global tracks
global newStart
if newStart
    newStart = false;
    set(hObject,'String','live modus stop');
    handles.trackHistory = [];
    tracks.predictOnlyStart = str2double(get(handles.edit_prediction_only,'String'));
    tracks.Pred_edge = str2double(get(handles.edit_band_edge,'String'));
    tracks.resolution= str2num(get(handles.edit_resolution,'String'));
    axis(handles.axes1,[tracks.resolution(1,:),tracks.resolution(2,:)]);

    
    delete_elements();
    tracks.dt = get(handles.slider_pause,'value');
    set(handles.slider_frame,'Enable','off');
    set(handles.togglebutton_play_history,'Enable','off');
    allParam=getDefaultParam;
    trckalg(tracks.resolution,tracks.predictOnlyStart,tracks.Pred_edge,@delegation_to_draw_sim,handles,hObject,allParam);
end
set(hObject,'Value',0);
set(handles.slider_frame,'Enable','on');
set(handles.togglebutton_play_history,'Enable','on');
tracks.t = 1;
newStart = true;
set(hObject,'String','live modus play');


% --- Executes on button press in togglebutton_sim_p.
function togglebutton_sim_p_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_sim_p (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_sim_p


% --- Executes on button press in pushbutton_undock.
function pushbutton_undock_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_undock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in togglebutton_undock.
function togglebutton_undock_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_undock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_undock
global tracks
if get(hObject,'Value')
    delete_elements()
    handles.undockes_figure = figure();
    tracks.axes = copyobj(handles.axes1,handles.undockes_figure);
    %     handles.axes2 = handles.axes1;
    %     handles.axes1 = axes2;
    set(tracks.axes,'Position',[0.07,0.07,0.9,0.85])
    set(handles.undockes_figure,'CloseRequestFcn',{@my_closereq,handles})
    guidata(hObject, handles);
    
elseif isfield(handles,'undockes_figure')
    try
        delete(handles.undockes_figure)
    end
    correct_axes(handles)
    
end

function my_closereq(src,callbackdata,handles)
delete(gcf)
correct_axes(handles)

function correct_axes(handles)
% handles.axes1 = handles.axes2;
% handles=rmfield(handles,'axes2');
global tracks
delete_elements()
tracks.axes = handles.axes1;
handles=rmfield(handles,'undockes_figure');
set(handles.togglebutton_undock,'Value',0);
guidata(handles.figure1, handles);

function setPredLines(direction)
global tracks
if direction == 1 % parallel to X-axes
    XData = tracks.resolution(1,:);
    YData = [tracks.predictOnlyStart tracks.predictOnlyStart];
    XData2 = tracks.resolution(1,:);
    YData2 = [tracks.Pred_edge tracks.Pred_edge];
elseif direction == 2
    XData = [tracks.predictOnlyStart tracks.predictOnlyStart];
    YData = tracks.resolution(2,:);
    XData2 = [tracks.Pred_edge tracks.Pred_edge];
    YData2 = tracks.resolution(2,:);
else error('direction not known')
end
set(tracks.predictionLine,'xdata',XData,'ydata',YData)
set(tracks.pred_line,'xdata',XData2,'ydata',YData2)

function delete_elements()
global tracks
if  ~isfield(tracks,'lines')
    return
end
ind_trk = find(tracks.lines.handles ~=0);
ind_sctr = find(tracks.scatters.handles ~=0);
ind_text = find(tracks.texts.handles ~=0);
ind_prdln = find(tracks.predLines.handles ~=0);

handlesToDelete=[tracks.lines.handles(ind_trk),...
    tracks.predLines.handles(ind_prdln),tracks.scatters.handles(ind_sctr),...
    tracks.texts.handles(ind_text),tracks.background,tracks.measurements];
handlesToDelete = handlesToDelete(handlesToDelete~=0);
handlesToDelete = handlesToDelete(ishandle(handlesToDelete));
handlesToDelete = handlesToDelete(strcmpi(get(handlesToDelete,'BeingDeleted'),'off'));
delete(handlesToDelete);

tracks.lines.handles(ind_trk) = 0;
tracks.predLines.handles(ind_prdln) = 0;
tracks.scatters.handles(ind_sctr) = 0;
tracks.texts.handles(ind_text) = 0;
tracks.background = 0;
tracks.measurements = 0;



function set_edit_resolution(hEdit,resolution)
    format loose
    set(hEdit,'String',mat2str(resolution));

function start_state(handles)
% construct the start state
global tracks 
tracks.rotation = 0;

% set(handles.checkbox_tracks,'value',true);
% set(handles.checkbox_markers,'value',true);
% set(handles.checkbox_track_IDs,'value',true);
% set(handles.checkbox_pred_beam,'value',true);
% set(handles.edit_track_color,'String','255,255,255');
% set(handles.edit_marker_color,'String','255,255,255');
% set(handles.edit_id_color,'String','255,255,255');
% set(handles.popupmenu_tracks_color,'value',2);
% set(handles.popupmenu_markers_color,'value',3);
% set(handles.popupmenu_tracks_IDs_color,'value',5);
return


% --- Executes on button press in pushbutton_save_load_parameters.
function pushbutton_save_load_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_save_load_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks
loadedParameterList = save_load_playParameter();
if isempty(loadedParameterList)
    return
end
if isfield(loadedParameterList,'resolution')
    tracks.resolution = loadedParameterList.resolution;
    axis(handles.axes1,[tracks.resolution(1,:),tracks.resolution(2,:)]);
    set_edit_resolution(handles.edit_resolution,tracks.resolution)
end
if isfield(loadedParameterList,'predictOnlyStart')
    tracks.predictOnlyStart = loadedParameterList.predictOnlyStart;
    set(tracks.predictionLine,'xdata',[0,tracks.resolution(1,2)],'ydata',...
    [tracks.predictOnlyStart tracks.predictOnlyStart])
    set(handles.edit_prediction_only,'String',num2str(tracks.predictOnlyStart))
end
if isfield(loadedParameterList,'pred_edge')
    tracks.Pred_edge = loadedParameterList.pred_edge;
    set(tracks.pred_line,'xdata',[0,tracks.resolution(1,2)],'ydata',...
    [tracks.Pred_edge tracks.Pred_edge])
    set(handles.edit_band_edge,'String',num2str(tracks.Pred_edge))
end
    
% --- Executes on button press in pushbutton_default_parameters.
function pushbutton_default_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_default_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tracks
resolution = [0,2200;0,1500];
predictOnlyStart = 800;
pred_edge = 900;
tracks.Pred_edge = pred_edge;
tracks.predictOnlyStart = predictOnlyStart;
tracks.resolution = resolution;
axis(tracks.axes,[resolution(1,:),resolution(2,:)]);

set_edit_resolution(handles.edit_resolution,tracks.resolution)
setPredLines(1);
set(handles.edit_prediction_only,'String',num2str(tracks.predictOnlyStart))
set(handles.edit_band_edge,'String',num2str(tracks.Pred_edge))
