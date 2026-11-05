function changeFrame(src, step)
% Frame controls. The < and > buttons pass a step of -1/+1; typing a
% number in the box calls this without a step.
    fig = ancestor(src, 'figure');
    handles = guidata(fig);
    box = findobj(fig, 'Tag', 'frameInput');

    if nargin < 2
        frame = str2double(get(box, 'String'));
        if isnan(frame) || frame < 1
            frame = 1;
        end
        if isfield(handles, 'US')
            frame = min(frame, size(handles.US.V, 4));
        end
    else
        if ~isfield(handles, 'tFrozen')
            handles.tFrozen = 1;
        end
        if step < 0
            frame = max(1, handles.tFrozen + step);
        else
            maxFrame = 1;
            if isfield(handles, 'US')
                maxFrame = size(handles.US.V, 4);
            end
            frame = min(maxFrame, handles.tFrozen + step);
        end
    end

    handles.tFrozen = frame;
    handles.t = frame;
    set(box, 'String', num2str(frame));
    guidata(fig, handles);
    maybeDrawSlices(fig);
end
