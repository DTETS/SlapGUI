function stepCrosshairAP(src, stepCm)
% The -2 mm / +2 mm AP buttons
    fig = ancestor(src, 'figure');
    handles = guidata(fig);

    if ~isfield(handles,'crosshair') || numel(handles.crosshair)~=3
        handles.crosshair     = handles.usCenter;
        handles.crosshairDraw = handles.crosshair;
    end

    handles.crosshair(1)     = handles.crosshair(1)     + stepCm;
    handles.crosshairDraw(1) = handles.crosshairDraw(1) + stepCm;

    guidata(fig, handles);
    maybeDrawSlices(fig);
end
