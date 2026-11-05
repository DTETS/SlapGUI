function applyThreshold(src, ~)
    fig = ancestor(src,'figure');
    handles = guidata(fig);
    hEdit = findobj(fig,'Tag','thresholdInput');
    val = str2double(get(hEdit,'String'));
    if isnan(val) || val < 0 || val > 255
        errordlg('Threshold must be 0–255.'); return;
    end
    handles.threshold = round(val);
    guidata(fig,handles);
    maybeDrawSlices(fig);
end
