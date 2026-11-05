function updateAngleHUD(fig, usRotDeg, viewTiltDeg)
% Small text in the top-left corner showing the current US rotation and
% the oblique coronal (View Angle) tilt.
    h = findobj(fig,'Tag','angleHUD');
    s = sprintf('US rot [AP SI ML] = [%.1f %.1f %.1f]°', usRotDeg);
    if nargin >= 3
        s = sprintf('%s   |   coronal tilt = %.1f°', s, viewTiltDeg);
    end
    if isempty(h)
        uicontrol('Style','text','Parent',fig,'String',s, ...
            'Units','normalized','Position',[0.01 0.95 0.45 0.04], ...
            'BackgroundColor',[0.97 0.97 0.97],'ForegroundColor',[0 0 0], ...
            'FontSize',10,'HorizontalAlignment','left','Tag','angleHUD', ...
            'Enable','inactive','HitTest','off');
    else
        set(h,'String',s);
    end
end
