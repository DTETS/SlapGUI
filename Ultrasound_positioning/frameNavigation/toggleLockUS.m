function toggleLockUS(src, ~)
% Lock US button. While locked, the US stays where it is on the MRI and the
% arrow keys only move the crosshair. The US slices follow the crosshair
% relative to where it was at the moment of locking.

    handles = guidata(src);
    if ~isfield(handles,'usLocked'), handles.usLocked = false; end
    handles.usLocked = ~handles.usLocked;

    if handles.usLocked
        handles.crosshair     = handles.usCenter;
        handles.crosshairDraw = handles.usCenter;
        handles.usAlignFrozen = handles.usCenter;

        % reference point for working out how far the crosshair moved
        handles.usLockRefSlices = handles.usLastSlices;
        handles.usLockRefCenter = handles.crosshair;

        if ~isfield(handles,'t'), handles.t = 1; end
        handles.tFrozen = handles.t;
    else
        handles = rmfield(handles, intersect({'usLockRefCenter','usLockRefSlices'}, fieldnames(handles)));
    end

    guidata(src, handles);
end
