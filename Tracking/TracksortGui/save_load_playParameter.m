function selectedParameterToLoad=save_load_playParameter()
%LOADEDPARAMETERLIST Summary of this function goes here
%   Detailed explanation goes here
global tracks
loadedParameterList=[];
resolution = tracks.resolution;
predictOnlyStart = tracks.predictOnlyStart;
pred_edge = tracks.Pred_edge;

parameterList = {'predictOnlyStart','pred_edge'};
allParameterList = {'resolution','predictOnlyStart','pred_edge'};
loaded = false;
selectedParameterToLoad=[];
d = dialog('Position',[300 300 350 250],'Name','save & load parameters','WindowStyle','normal','Units','normalized');
first_pos =  [0.1   0.75   0.5    0.08];
% first_pos = first_pos + [0 0 first_pos(3) first_pos(4)*0.2];
horiz_shft = 0.3;
verti_shft = -0.17;

g = makeAllignmentGrid(first_pos,5,horiz_shft,verti_shft);
txt = uicontrol('Parent',d,'Style','text','Units','normalized','Position',...
    align2grid(g,1,1),'String','Select parameteres to save:');

checkbox_resolution = uicontrol('Parent',d,'Style','checkbox','Units','normalized',...
    'Position',align2grid(g,1,2),'String','resolution','Callback',{@chechbox_callback 'resolution'} );

checkbox_predictOnlyStart = uicontrol('Parent',d,'Style','checkbox','Units','normalized',...
    'Position',align2grid(g,1,3),'String','prediction only start','value',1,'Callback',{@chechbox_callback,'predictOnlyStart'});

checkbox_pred_edge = uicontrol('Parent',d,'Style','checkbox','Units','normalized',...
    'Position',align2grid(g,1,4),'String','pred edge','value',1,'Callback',{@chechbox_callback,'pred_edge'});

btn_save = uicontrol('Parent',d,'String','save','Callback',@save_callback,...
    'Units','normalized','Position',align2grid(g,1,5)'*diag([1,1,0.5,1.3]));

btn_open = uicontrol('Parent',d, 'String','open', 'Callback',@load_callback,...
    'Units','normalized','Position',align2grid(g,2,5)'*diag([1,1,0.5,1.3]));
btn_close = uicontrol('Parent',d, 'String','Close','Callback',@close_callback,...
    'Units','normalized','Position',align2grid(g,3,5)'*diag([1,1,0.5,1.3]));

uiwait

    function chechbox_callback(hObject,event,parameter)
        ind = find(ismember(parameterList,parameter));
        if get(hObject,'value')  == 1
            if isempty(ind)
                parameterList = [parameterList parameter];
            end
        elseif ~isempty(ind)
            parameterList(ind)= [];
        end
    end

    function save_callback(hobject,event)
        [filename,PathName] = uiputfile('*.mat', 'Save parameters');
        if filename == 0
            return
        end
        fullPath = fullfile(PathName,filename);
        if ~isempty(parameterList)
            save(fullPath,parameterList{1});
            for i = 2:length(parameterList)
                save(fullPath,parameterList{i},'-append');
            end
        end
    end

    function load_callback(hobject,event)
        [filename,filepath] = uigetfile('*.mat','File Selector');
        if filename == 0
            return
        end
        loadedParameterList = load(fullfile(filepath,filename));
        if ~isempty(loadedParameterList)
            loaded = true;
            set(txt,'String','Select parameteres to load');
            names = fieldnames(loadedParameterList);
            for i = 1:length(allParameterList)
                ind = find(ismember(parameterList,allParameterList{i}));
                if ismember(allParameterList{i},names)
                    set(eval(['checkbox_' allParameterList{i}]),'Value',1)
                    if isempty(ind)
                        parameterList = [parameterList allParameterList(i)];
                    end
                else
                    set(eval(['checkbox_' allParameterList{i}]),'Enable','off')
                    if ~isempty(ind)
                        parameterList(ind) = [];
                    end
                end
            end
            set(btn_close,'String','load&close')
        end
    end

    function close_callback(hobject,event)
        if loaded
            names = fieldnames(loadedParameterList);
            for i = 1:length(names)
                if ismember(names{i},parameterList);    
                    selectedParameterToLoad.(names{i})= loadedParameterList.(names{i});
                end
            end
        end
        delete(gcf)
    end
end

