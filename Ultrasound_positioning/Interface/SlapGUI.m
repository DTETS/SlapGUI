function SlapGUI()
% Main window for aligning the ultrasound volume over the MRI.

    f = figure('Name','Align US over MRI', ...
               'KeyPressFcn', @keyMove, ...
               'Position', [100, 100, 1400, 650]);

    % faster rendering with the alpha overlays
    set(f,'Renderer','opengl');
    set(f,'GraphicsSmoothing','on');

    % Bottom toolbar
    uicontrol('Style','pushbutton','String','Load US', ...
              'Position',[10 10 90 30], 'Callback', @loadUS);
    uicontrol('Style','pushbutton','String','Load MRI', ...
              'Position',[105 10 90 30], 'Callback', @loadMRI);

    uicontrol('Style','text','String','View Angle:', ...
              'Position',[1050 10 70 20], 'HorizontalAlignment','left');
    uicontrol('Style','pushbutton','String','-', ...
              'Position',[1125 10 25 25], 'Callback', @(src,~) changeViewAngle(src, -3.6));
    uicontrol('Style','edit','String','0','Tag','viewAngleInput', ...
              'Position',[1155 10 40 25], 'Callback', @(src,~) changeViewAngle(src));
    uicontrol('Style','pushbutton','String','+', ...
              'Position',[1200 10 25 25], 'Callback', @(src,~) changeViewAngle(src, 3.6));

    uicontrol('Style','pushbutton','String','-2 mm AP', ...
              'Position',[200 10 100 30], 'Callback', @(src,~) stepCrosshairAP(src, -0.2));
    uicontrol('Style','pushbutton','String','+2 mm AP', ...
              'Position',[305 10 100 30], 'Callback', @(src,~) stepCrosshairAP(src, 0.2));

    uicontrol('Style','text','String','US Threshold:', ...
              'Position',[415 40 80 15], 'HorizontalAlignment','left');
    uicontrol('Style','edit','String','150','Tag','thresholdInput', ...
              'Position',[495 35 50 22]);
    uicontrol('Style','pushbutton','String','Apply', ...
              'Position',[550 34 60 24], 'Callback', @applyThreshold);

    uicontrol('Style','text','String','MRI colormap:', ...
              'Position',[620 40 90 15],'HorizontalAlignment','left');
    uicontrol('Style','popupmenu','Tag','mriCmapMenu', ...
              'String',{'parula','turbo','hot','gray'}, ...
              'Position',[710 35 90 22], 'Callback',@onCmapChanged);

    uicontrol('Style','text','String','US colormap:', ...
              'Position',[620 15 90 15],'HorizontalAlignment','left');
    uicontrol('Style','popupmenu','Tag','usCmapMenu', ...
              'String',{'parula','turbo','hot','gray','bone','jet'}, ...
              'Position',[710 10 90 22], 'Callback',@onUsCmapChanged);

    uicontrol('Style','text','String','MRI Bright:', ...
              'Position',[820 40 70 15],'HorizontalAlignment','left');
    uicontrol('Style','edit','String','1.8','Tag','mriBrightInput', ...
              'Position',[890 35 45 22], 'Callback',@onMriBrightChanged);
    uicontrol('Style','text','String','Gamma:', ...
              'Position',[945 40 50 15],'HorizontalAlignment','left');
    uicontrol('Style','edit','String','0.8','Tag','mriGammaInput', ...
              'Position',[995 35 45 22], 'Callback',@onMriGammaChanged);

    uicontrol('Style','pushbutton','String','Save', ...
              'Position',[850 10 80 30], 'Callback', @onSaveButtonPressed);
    uicontrol('Style','pushbutton','String','Load Session', ...
              'Position',[935 10 100 30], 'Callback', @onLoadButtonPressed);

    uicontrol('Style','togglebutton','String','Lock US','Value',0, ...
              'Position',[1040 10 80 30], 'Callback', @toggleLockUS);

    uicontrol('Style','pushbutton','String','Draw polygons', ...
              'Position',[1300 10 80 30], ...
              'Callback', @(src,evt) openPolygonWindow(f));

    uicontrol('Style','text','String','Frame:', ...
              'Position',[1120 40 50 15], 'HorizontalAlignment','left');
    uicontrol('Style','edit','String','1','Tag','frameInput', ...
              'Position',[1170 35 40 22], 'Callback', @(src,~) changeFrame(src));
    uicontrol('Style','pushbutton','String','<', ...
              'Position',[1215 35 25 22], 'Callback', @(src,~) changeFrame(src, -1));
    uicontrol('Style','pushbutton','String','>', ...
              'Position',[1245 35 25 22], 'Callback', @(src,~) changeFrame(src, 1));

    % Image area on the left, readout panel on the right
    main = uipanel('Parent', f, 'Units','normalized', 'Position',[0 0.12 0.78 0.86], ...
                   'BorderType','none', 'Tag','mainPanel');
    p = uipanel('Parent', f, 'Units','normalized', 'Position',[0.78 0.12 0.22 0.86], ...
                'Title','Center & Session', 'Tag','readoutPanel');

    uicontrol('Parent',p,'Style','text','String','AP (cm):',    'HorizontalAlignment','left','Position',[10 230 80 18]);
    uicontrol('Parent',p,'Style','text','String','SI (cm):',    'HorizontalAlignment','left','Position',[10 200 80 18]);
    uicontrol('Parent',p,'Style','text','String','ML (cm):',    'HorizontalAlignment','left','Position',[10 170 80 18]);
    uicontrol('Parent',p,'Style','text','String','Thr (0-255):','HorizontalAlignment','left','Position',[10 140 90 18]);
    uicontrol('Parent',p,'Style','text','String','Frame:',      'HorizontalAlignment','left','Position',[10 110 80 18]);

    uicontrol('Parent',p,'Style','text','Tag','valAP','String','--', 'HorizontalAlignment','left','Position',[105 230 60 18]);
    uicontrol('Parent',p,'Style','text','Tag','valSI','String','--', 'HorizontalAlignment','left','Position',[105 200 60 18]);
    uicontrol('Parent',p,'Style','text','Tag','valML','String','--', 'HorizontalAlignment','left','Position',[105 170 60 18]);
    uicontrol('Parent',p,'Style','text','Tag','valTH','String','--', 'HorizontalAlignment','left','Position',[105 140 60 18]);
    uicontrol('Parent',p,'Style','text','Tag','valFR','String','--', 'HorizontalAlignment','left','Position',[105 110 60 18]);

    uicontrol('Parent', p, 'Style', 'text', 'String', 'Selected View:', ...
              'HorizontalAlignment', 'left', 'Position', [10 70 80 18]);
    uicontrol('Parent', p, 'Style', 'text', 'Tag', 'selectedViewLabel', ...
              'String', 'Axial', 'HorizontalAlignment', 'left', ...
              'Position', [95 70 80 18], 'FontWeight', 'bold', ...
              'ForegroundColor', [0.8 0.6 0]);

    instrPanel = uipanel('Parent', p, 'Title', 'Controls', ...
                         'Units', 'pixels', 'Position', [5 5 195 60], ...
                         'FontWeight', 'bold', 'Tag', 'instrPanel');
    instrText = sprintf(['1/2/3: Coronal/Axial/Sagittal\n', ...
                         'WASD/Arrows: Move  |  Q/E: Rotate\n', ...
                         '0: Reset rotation  |  ,/.: Frames']);
    uicontrol('Parent', instrPanel, 'Style', 'text', 'String', instrText, ...
              'HorizontalAlignment', 'left', 'Position', [3 2 188 42], 'FontSize', 8);

    handles = struct();
    handles.threshold    = 150;      % 0-255
    handles.usLocked     = false;
    handles.t            = 1;        % current frame
    handles.tFrozen      = 1;        % frame shown while the US is unlocked
    handles.viewInit     = false;    % axes get created on the first draw
    handles.main         = main;
    handles.readoutPanel = p;
    handles.mriCmapName  = 'parula';
    handles.usCmapName   = 'parula';
    handles.mriBright    = 1.8;
    handles.mriGamma     = 0.8;
    handles.readoutMode  = 'nav';
    % where the US starts on the MRI, [AP SI ML] in cm (used to be [8.55 8.30 7.75])
    handles.usStartPos   = [7.5 8 9];
    guidata(f, handles);
end


function onMriBrightChanged(h,~)
    fig = ancestor(h,'figure');
    handles = guidata(fig);
    v = str2double(get(h,'String'));
    if ~isfinite(v), v = handles.mriBright; end
    handles.mriBright = max(0.5, min(3.0, v));
    guidata(fig,handles);
    maybeDrawSlices(fig);
    syncPolyColors(fig);
end

function onMriGammaChanged(h,~)
    fig = ancestor(h,'figure');
    handles = guidata(fig);
    v = str2double(get(h,'String'));
    if ~isfinite(v), v = handles.mriGamma; end
    handles.mriGamma = max(0.5, min(1.5, v));
    guidata(fig,handles);
    maybeDrawSlices(fig);
    syncPolyColors(fig);
end

function onCmapChanged(src, ~)
    fig = ancestor(src,'figure');
    handles = guidata(fig);

    items = get(src,'String');
    name  = items{get(src,'Value')};
    switch lower(name)
        case 'turbo'
            % turbo only exists in newer MATLAB versions
            if exist('turbo','file'), cmap = turbo(256); else, cmap = parula(256); end
        case 'hot',  cmap = hot(256);
        case 'gray', cmap = gray(256);
        otherwise,   cmap = parula(256);
    end

    handles.mriCmapName = name;
    guidata(fig,handles);

    colormap(handles.axCor, cmap); set(handles.axCor,'CLim',[0 255]);
    colormap(handles.axAx , cmap); set(handles.axAx ,'CLim',[0 255]);
    colormap(handles.axSag, cmap); set(handles.axSag,'CLim',[0 255]);
    syncPolyColors(fig);
    drawnow;
end

function onUsCmapChanged(src, ~)
    fig = ancestor(src,'figure');
    handles = guidata(fig);
    items = get(src,'String');
    handles.usCmapName = items{get(src,'Value')};
    guidata(fig,handles);
    maybeDrawSlices(fig);   % the US is drawn as RGB, so it needs a full redraw
    syncPolyColors(fig);
end
