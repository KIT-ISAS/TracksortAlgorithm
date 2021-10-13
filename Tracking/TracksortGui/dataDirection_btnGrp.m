function bg=dataDirection_btnGrp(handles)
bg = uibuttongroup('Visible','off','Title','data direction',...
    'Position',[0 0 0.15 0.55]);
    %'SelectionChangedFcn',@bselection);
w=60;
h=25;
% Create three radio buttons in the button group.
r1 = uicontrol(bg,'Style','pushbutton','String','90�',...
    'Position',[10 2*h w h],...
    'HandleVisibility','off','Callback',@bAction);

r2 = uicontrol(bg,'Style','pushbutton',...
    'String','180�',...
    'Position',[10 h w h],...
    'HandleVisibility','off','Callback',@bAction);

% r3 = uicontrol(bg,'Style','radiobutton',...
%     'String','0�',...
%     'Position',[2*w h w h],...
%     'HandleVisibility','off','Callback',@bAction);
r3 = uicontrol(bg,'Style','pushbutton',...
    'String','270�',...
    'Position',[10 0 w h],...
    'HandleVisibility','off','Callback',@bAction);

% Make the uibuttongroup visible after creating child objects.
set(bg,'Visible','on');

%     function bselection(source,event)
%         %        display(['Previous: ' event.OldValue.String]);
%         %        display(['Current: ' event.NewValue.String]);
%         %        display('------------------');
%         rotMidpointM(event.NewValue.String);
%     end
    function bAction(source,event)
        global tracks
        switch get(source,'String')
            case '90�'
                angle = pi/2;
            case '180�'
                angle = pi;
            case '0�'
                angle = 0;
            case '270�'
                angle = 3*pi/2;
        end
        rotMidpointMat(angle);
%         rotate axes limits as well
%         res = rot_vect(tracks.resolution,angle);
%         tracks.resolution(1,:) = sort(res(1,:));
%         tracks.resolution(2,:) = sort(res(2,:));
%         setAxesLim(tracks.axes,tracks.resolution)
    end
end