function loadUS(~, ~)
% Grab the ultrasound volume from an open WASL window.
    ud = findWASLData();
    if isempty(ud), return; end

    try
        US.V       = ud.tongue.V;
        US.scaling = ud.tongue.scaling;

        % WASL gives mm, we work in cm. Only the first 3 entries are spatial,
        % the 4th is time.
        US.scaling.scale = US.scaling.scale(1:3) / 10;
        US.scaling.C     = US.scaling.C(1:3);

        US.corSlice   = round(US.scaling.C(1)/2);
        US.axialSlice = round(US.scaling.C(2)/2);
        US.sagSlice   = round(US.scaling.C(3)/2);
        US.name = char(ud.FLDfilename);

        fig = findobj('Type','figure','-and','Name','Align US over MRI');
        if isempty(fig) || ~isgraphics(fig), errordlg('Main GUI not found.','GUI Error'); return; end
        handles = guidata(fig);

        handles.US = US;
        if ~isfield(handles,'t'), handles.t = 1; end

        % forget everything computed from the previous US so the next draw
        % starts fresh
        handles.viewInit = false;
        stale = {'crosshair','crosshairDraw','usCenter','usRotCenter', ...
                 'USinterp','USinterp_t','initialUSSlices'};
        handles = rmfield(handles, intersect(stale, fieldnames(handles)));

        guidata(fig, handles);
        maybeDrawSlices(fig);
    catch ME
        errordlg(['Could not load US from WASL: ' ME.message], 'US Error');
    end
end
