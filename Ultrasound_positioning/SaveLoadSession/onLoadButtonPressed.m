function onLoadButtonPressed(~, ~)
% Restore the US position, rotation and threshold saved for this recording.
    fig = findobj('Type','figure','-and','Name','Align US over MRI');
    handles = guidata(fig);
    if ~isfield(handles,'US')
        errordlg('Load an ultrasound first.'); return;
    end

    [file, path] = uigetfile('*.xlsx','Select session settings file');
    if isequal(file,0), return; end
    excelFile = fullfile(path,file);

    st = loadSession(handles.US.name, excelFile);
    if ~isempty(st.center)
        handles.usCenter      = st.center;
        handles.crosshair     = st.center;   % same as after moving with the keys
        handles.crosshairDraw = st.center;
    end
    if ~isempty(st.rotation),  handles.usRotDeg  = st.rotation;  end
    if ~isempty(st.threshold), handles.threshold = st.threshold; end

    hThr = findobj(fig,'Tag','thresholdInput');
    if ~isempty(hThr), set(hThr,'String',num2str(handles.threshold)); end

    guidata(fig,handles);
    maybeDrawSlices(fig);
end
