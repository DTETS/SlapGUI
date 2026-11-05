function keyMove(src, event)
% Keyboard controls for the main window:
%   1/2/3        pick the coronal / axial / sagittal view
%   arrows, WASD move the US (or just the crosshair when the US is locked)
%   Q/E          rotate the US about the current view's normal
%   0            reset rotation,  P prints the current angles
%   , and .      step through frames (only when locked)

    handles = guidata(src);
    if ~isfield(handles,'US') || ~isfield(handles,'MRI'), return; end
    if ~isfield(handles,'usCenter'), return; end
    if ~isfield(handles,'usLocked'), handles.usLocked = false; end
    if ~isfield(handles,'t'),        handles.t = 1; end
    if ~isfield(handles,'tFrozen'),  handles.tFrozen = handles.t; end
    if ~isfield(handles,'crosshair') || numel(handles.crosshair)~=3
        handles.crosshair = handles.usCenter;
    end
    if ~isfield(handles,'crosshairDraw') || numel(handles.crosshairDraw)~=3
        handles.crosshairDraw = handles.crosshair;
    end
    if ~isfield(handles,'usRotDeg'), handles.usRotDeg = [0 0 0]; end   % [AP SI ML] deg

    step    = 0.1;   % cm per key press
    rotStep = 1;     % deg per key press

    persistent currentView
    if isempty(currentView), currentView = 2; end   % 1=cor, 2=ax, 3=sag

    switch event.Key
        case '1', currentView = 1; updateViewHighlight(src, currentView);
        case '2', currentView = 2; updateViewHighlight(src, currentView);
        case '3', currentView = 3; updateViewHighlight(src, currentView);
    end

    % Q/E rotate about the axis normal to the current view:
    % coronal -> AP, axial -> SI, sagittal -> ML
    if any(strcmp(event.Key, {'q','e'}))
        rotAxis = currentView;
        if strcmp(event.Key,'e')
            delta = rotStep;
        else
            delta = -rotStep;
        end
        % flipped for axial and sagittal so the image turns the way you'd expect
        if currentView == 2 || currentView == 3
            delta = -delta;
        end
        handles.usRotDeg(rotAxis) = handles.usRotDeg(rotAxis) + delta;

        guidata(src,handles);
        maybeDrawSlices(src);
        return;
    end

    switch event.Key
        case '0'
            handles.usRotDeg(:) = 0;
            guidata(src,handles);
            maybeDrawSlices(src);
            return;
        case 'p'
            fprintf('US rotation (AP,SI,ML) = [%.1f %.1f %.1f] deg\n', handles.usRotDeg);
            return;
    end

    dx = 0; dy = 0;
    switch event.Key
        case {'leftarrow','a'},  dx = -step;
        case {'rightarrow','d'}, dx =  step;
        case {'uparrow','w'},    dy =  step;
        case {'downarrow','s'},  dy = -step;
    end

    if dx~=0 || dy~=0
        % Unlocked: move the US itself and keep the crosshair on it.
        % Locked: the US stays put and only the crosshair moves.
        if handles.usLocked
            pos = handles.crosshair;
        else
            pos = handles.usCenter;
        end

        switch currentView
            case 1  % coronal: x=ML, y=SI
                pos(3) = pos(3) + dx;
                pos(2) = pos(2) + dy;
            case 2  % axial: x=ML, y=AP
                pos(3) = pos(3) + dx;
                pos(1) = pos(1) + dy;
            case 3  % sagittal: x=AP, y=SI
                pos(1) = pos(1) + dx;
                pos(2) = pos(2) + dy;
        end

        if ~handles.usLocked
            handles.usCenter = pos;
        end
        handles.crosshair     = pos;
        handles.crosshairDraw = pos;

        guidata(src,handles);
        maybeDrawSlices(src);
        return;
    end

    prevKeys = {'comma','subtract','numpadsubtract','pageup'};
    nextKeys = {'period','add','numpadadd','pagedown'};
    if any(strcmp(event.Key, [prevKeys nextKeys]))
        if handles.usLocked
            if any(strcmp(event.Key, prevKeys))
                timeStep = -1;
            else
                timeStep = 1;
            end
            T = max(size(handles.US.V,4),1);
            handles.t = min(max(1, handles.t + timeStep), T);
            handles.tFrozen = handles.t;
            guidata(src,handles);
            updateSideReadout(src, handles.usCenter, handles.threshold, handles.t);
            maybeDrawSlices(src);
        end
        return;
    end
end


function updateViewHighlight(fig, currentView)
% Gold border around the selected view, and update the label in the side panel
    handles = guidata(fig);
    if ~isfield(handles,'axCor') || ~isfield(handles,'axAx') || ~isfield(handles,'axSag')
        return;
    end

    gold = [1 0.8 0];
    grey = [0.15 0.15 0.15];
    viewNames = {'Coronal', 'Axial', 'Sagittal'};

    allAxes = [handles.axCor, handles.axAx, handles.axSag];
    set(allAxes, 'Box', 'on', 'XColor', grey, 'YColor', grey, 'LineWidth', 0.5);
    set(allAxes(currentView), 'XColor', gold, 'YColor', gold, 'LineWidth', 3);

    hLabel = findobj(fig, 'Tag', 'selectedViewLabel');
    if ~isempty(hLabel)
        set(hLabel, 'String', viewNames{currentView});
    end

    drawnow limitrate;
end
