function plotHistory(opt)
% @author Florian Pfaff
% @date 2014-2021
% Pass either filename or trackHistory
arguments
    opt.filename char = ''
    opt.trackHistory struct = struct.empty()
    opt.env struct = struct.empty()
    opt.imagePath char = ''
    opt.mirrorImage (2, 1) logical = [false, false]; % First: mirror ud, second: mirror lr
end
global tracks
if ~isempty(opt.filename) && isempty(opt.trackHistory)
    listOfVariables = who('-file', opt.filename);
    assert(ismember('trackHistory', listOfVariables));
    filename = opt.filename;
elseif isempty(opt.filename) && ~isempty(opt.trackHistory) && ~isempty(opt.env)
    trackHistory = opt.trackHistory;
    env = opt.env;
    filename = [tempname, '.mat'];
    save(filename, 'trackHistory', 'env');
elseif isempty(opt.filename) && ~isempty(opt.trackHistory) && isempty(opt.env)
    trackHistory = opt.trackHistory;
    filename = [tempname, '.mat'];
    save(filename, 'trackHistory');
else
    error('You should not pass both trackHistory and a filename at the same time.')
end

fileInfos = dir(filename);

handleGUI = tracksortGUI;
hObjectOpenHistory = findobj(handleGUI, 'tag', 'pushbutton_open_history');
tracksortGUI('pushbutton_open_history_Callback', hObjectOpenHistory, [], guidata(hObjectOpenHistory), fileInfos.folder, fileInfos.name)
hObjectPlayHistory = findobj(handleGUI, 'tag', 'togglebutton_play_history');
hObjectPlayHistory.Value = 1;
if ~isempty(opt.imagePath)
    tracks.imagePath = opt.imagePath;
    tracks.background_images = read_background_images(opt.imagePath);
    checkbox_background = findobj(handleGUI, 'tag', 'checkbox_background');
    checkbox_background.Value = 1;
    tracks.backgroundDraw = true;
    tracks.mirrorImage = mirrorImage;
end
tracksortGUI('togglebutton_play_history_Callback', hObjectPlayHistory, [], guidata(hObjectPlayHistory));
end
