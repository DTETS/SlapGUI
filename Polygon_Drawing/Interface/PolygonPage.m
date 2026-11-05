function PolygonPage(mainFig)
% Open the window used to draw the tongue polygons on the coronal slice.

    mainHandles = guidata(mainFig);
    if ~isfield(mainHandles,'MRI')
        errordlg('Load MRI first in the main GUI.','Polygon GUI');
        return;
    end

    MRI = mainHandles.MRI;

    if isfield(mainHandles, 'crosshair')
        corIdx = round(mainHandles.crosshair(1) / MRI.scaling.scale(1));
    elseif isfield(MRI,'corSlice')
        corIdx = MRI.corSlice;
    else
        corIdx = round(MRI.scaling.C(1)/2);
    end

    polyFig = figure('Name','Coronal polygon measurement', ...
        'NumberTitle','off', ...
        'Position',[300 150 800 600]);

    ax = axes('Parent',polyFig, ...
        'Units','normalized', ...
        'Position',[0.07 0.15 0.6 0.8]);
    hold(ax,'on'); set(ax,'YDir','normal');

    uicontrol('Parent',polyFig,'Style','pushbutton','String','Draw polygon', ...
        'Units','normalized', ...
        'Position',[0.72 0.70 0.22 0.08], ...
        'Callback',@onPolyDraw);

    uicontrol('Parent',polyFig,'Style','pushbutton','String','Save to Excel', ...
        'Units','normalized', ...
        'Position',[0.72 0.58 0.22 0.08], ...
        'Callback',@onPolySave);

    imgData = struct();
    imgData.MRI        = mainHandles.MRI;
    imgData.US         = mainHandles.US;
    imgData.ax         = ax;
    imgData.corIdx     = corIdx;
    imgData.polygon    = [];
    imgData.brightness = mainHandles.mriBright;
    imgData.threshold  = mainHandles.threshold;
    imgData.usCenter   = mainHandles.usCenter;

    % name the Excel file after the US recording if we know it
    if isfield(mainHandles.US, 'name') && ~isempty(mainHandles.US.name)
        [~, usName, ~] = fileparts(mainHandles.US.name);
        imgData.excelFile = fullfile(pwd, sprintf('%s_polygons.xlsx', usName));
    else
        imgData.excelFile = fullfile(pwd, 'coronalPolygons.xlsx');
    end

    if isfield(mainHandles, 'tFrozen')
        imgData.frame = mainHandles.tFrozen;
    elseif isfield(mainHandles, 't')
        imgData.frame = mainHandles.t;
    else
        imgData.frame = 1;
    end

    guidata(polyFig, imgData);
    drawPolyPage(polyFig);
end
