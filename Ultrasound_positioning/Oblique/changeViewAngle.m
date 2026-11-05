function changeViewAngle(src, step)
% View Angle controls. The -/+ buttons pass a step of -3.6/+3.6 deg;
% typing in the box calls this without a step. The angle stays in 0-90.
    fig = ancestor(src, 'figure');
    handles = guidata(fig);
    box = findobj(fig, 'Tag', 'viewAngleInput');
    angle = str2double(get(box, 'String'));

    if nargin < 2
        angle = max(0, min(90, angle));
    elseif step > 0
        angle = min(90, angle + step);
    else
        angle = max(0, angle + step);
    end

    set(box, 'String', num2str(angle));
    handles.viewRotDeg = [0, 0, angle];
    guidata(fig, handles);
    maybeDrawSlices(fig);
end
