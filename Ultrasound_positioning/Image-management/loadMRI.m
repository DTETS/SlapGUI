function loadMRI(~, ~)
% Grab the MRI volume from an open WASL window.
    ud = findWASLData();
    if isempty(ud), return; end

    try
        MRI.V       = ud.tongue.V;
        MRI.scaling = ud.tongue.scaling;
        MRI.scaling.scale = MRI.scaling.scale/10;   % mm -> cm

        MRI.corSlice   = round(MRI.scaling.C(1)/2);
        MRI.axialSlice = round(MRI.scaling.C(2)/2);
        MRI.sagSlice   = round(MRI.scaling.C(3)/2);

        fig = findobj('Type','figure','-and','Name','Align US over MRI');
        if isempty(fig) || ~isgraphics(fig), errordlg('Main GUI not found.','GUI Error'); return; end
        handles = guidata(fig);

        handles.MRI = MRI;

        % older sessions used 'frame' instead of 't', keep both in sync
        if ~isfield(handles,'t')
            if isfield(handles,'frame'), handles.t = handles.frame; else, handles.t = 1; end
        end
        handles.frame = handles.t;

        if ~isfield(handles,'threshold'), handles.threshold = 150; end

        % Don't set usCenter here. maybeDrawSlices will put the US at
        % usStartPos. Using the US native center put the US in the MRI's
        % corner whenever the US was loaded first.

        % drop the cached interpolant, otherwise a reloaded MRI isn't used
        handles = rmfield(handles, intersect({'MRIinterp','MRIinterp_t'}, fieldnames(handles)));

        guidata(fig, handles);
        if isfield(handles,'US')
            maybeDrawSlices(fig);
        end
    catch ME
        errordlg(['Could not load MRI from WASL: ' ME.message], 'MRI Error');
    end
end
