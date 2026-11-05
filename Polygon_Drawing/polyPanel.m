function ui = polyPanel(polyFig, cmd, varargin)
% Side panel for the polygon window, plus a couple of helpers that go with it.
%
%   ui = polyPanel(fig)                     build the panel (or return the existing one)
%        polyPanel(fig, 'step', s, pairNum) update the status banner and frame color
%        polyPanel(fig, 'repaint')          redraw the saved polygons
%
%   step:  0 idle, 1 red (with tongue), 2 blue (without tongue),
%          3 pair done, -1 cancelled

    if nargin < 2, cmd = 'build'; end

    switch lower(cmd)
        case 'build'
            ui = buildPanel(polyFig);
        case 'step'
            ui = setStep(polyFig, varargin{:});
        case 'repaint'
            repaint(polyFig);
            ui = getappdata(polyFig, 'polyUI');
        otherwise
            error('polyPanel:badCmd', 'Unknown command "%s".', cmd);
    end
end


function ui = buildPanel(polyFig)
    ui = getappdata(polyFig, 'polyUI');
    if ~isempty(ui) && isfield(ui, 'panel') && isvalid(ui.panel)
        return;
    end

    imgData = guidata(polyFig);
    ax      = imgData.ax;

    % Make room for the panel by narrowing the axes. Only touch the width,
    % changing the height makes the axes overlap the buttons.
    oldUnits = get(ax, 'Units');
    set(ax, 'Units', 'normalized');
    p0 = get(ax, 'Position');
    set(ax, 'Position', [p0(1) p0(2) min(p0(3), 0.60) p0(4)]);
    set(ax, 'Units', oldUnits);

    bg = [0.96 0.96 0.96];

    ui.panel = uipanel(polyFig, 'Tag', 'polyInstrPanel', 'Units', 'normalized', ...
        'Position', [0.68 0.06 0.30 0.88], 'Title', 'Drawing guide', ...
        'FontWeight', 'bold', 'BackgroundColor', bg);

    label = @(y, h, str, fs, fw) uicontrol('Parent', ui.panel, 'Style', 'text', ...
        'Units', 'normalized', 'Position', [0.06 y 0.88 h], 'String', str, ...
        'HorizontalAlignment', 'left', 'FontSize', fs, 'FontWeight', fw, ...
        'BackgroundColor', bg);

    ui.status = uicontrol('Parent', ui.panel, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.06 0.87 0.88 0.09], 'String', 'Ready', ...
        'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', 'w', ...
        'BackgroundColor', [0.45 0.45 0.45], 'HorizontalAlignment', 'center');

    ui.step1 = label(0.79, 0.06, '1.  RED  - with tongue (VwT)',     10, 'normal');
    ui.step2 = label(0.73, 0.06, '2.  BLUE - without tongue (VwoT)', 10, 'normal');
    ui.step3 = label(0.67, 0.06, '3.  Save to Excel',                10, 'normal');

    label(0.60, 0.05, 'How to draw', 10, 'bold');
    label(0.38, 0.21, ['- Click to place each vertex.'            newline ...
                       '- Double-click the last vertex to close.' newline ...
                       '- Backspace removes the last vertex.'     newline ...
                       '- Esc cancels the pair.'], 9, 'normal');

    label(0.31, 0.05, 'RED = tongue present, BLUE = tongue removed', 8, 'normal');

    % buttons go inside the panel so the axes can't end up on top of them
    ui.btnDraw = uicontrol('Parent', ui.panel, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.08 0.21 0.84 0.075], ...
        'String', 'Draw tongue pair', 'FontWeight', 'bold', 'Callback', @onPolyDraw);

    ui.btnSave = uicontrol('Parent', ui.panel, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.08 0.12 0.84 0.075], ...
        'String', 'Save to Excel', 'Callback', @onPolySave);

    ui.btnUndo = uicontrol('Parent', ui.panel, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.08 0.03 0.84 0.075], ...
        'String', 'Undo last pair', 'Callback', @undoLastPair);

    setappdata(polyFig, 'polyUI', ui);
    setStep(polyFig, 0, 0);
end


function ui = setStep(polyFig, step, pairNum)
    if nargin < 3, pairNum = 0; end
    ui      = buildPanel(polyFig);
    imgData = guidata(polyFig);

    grey  = [0.45 0.45 0.45];
    red   = [0.80 0.16 0.16];
    blue  = [0.15 0.35 0.85];
    green = [0.10 0.58 0.25];

    switch step
        case  1, c = red;   msg = sprintf('Pair %d - RED: with tongue',      pairNum);
        case  2, c = blue;  msg = sprintf('Pair %d - BLUE: without tongue',  pairNum);
        case  3, c = green; msg = sprintf('Pair %d complete - ready to save', pairNum);
        case -1, c = grey;  msg = 'Cancelled - nothing saved';
        otherwise
                 c = grey;  msg = 'Ready - press Draw tongue pair';
    end
    set(ui.status, 'String', msg, 'BackgroundColor', c);

    % bold the current step, grey out the rest
    steps = [ui.step1 ui.step2 ui.step3];
    cols  = {red, blue, green};
    for k = 1:3
        active = (k == step);
        set(steps(k), 'FontWeight',      pick(active, 'bold', 'normal'), ...
                      'ForegroundColor', pick(active, cols{k}, grey));
    end

    % The colored frame is a figure annotation rather than the axes' own
    % XColor/YColor, because drawPolyPage calls cla/axis which would reset those.
    fr = getappdata(polyFig, 'polyFrame');
    if isempty(fr) || ~isvalid(fr)
        u = get(imgData.ax, 'Units');
        set(imgData.ax, 'Units', 'normalized');
        pos = get(imgData.ax, 'Position');
        set(imgData.ax, 'Units', u);
        fr = annotation(polyFig, 'rectangle', pos + [-0.012 -0.012 0.024 0.024], ...
                        'Color', c, 'LineWidth', 4);
        setappdata(polyFig, 'polyFrame', fr);
    end
    set(fr, 'Color', c, 'LineWidth', pick(any(step == [1 2]), 4, 1.5));

    drawnow limitrate;
end


function repaint(polyFig)
% Plain line plots instead of drawpolygon ROIs, so old polygons don't grab
% the clicks meant for the one being drawn.
    imgData = guidata(polyFig);
    if ~isfield(imgData, 'polygons') || isempty(imgData.polygons), return; end

    hold(imgData.ax, 'on');
    for i = 1:numel(imgData.polygons)
        outline(imgData.ax, imgData.polygons(i).withTongue.vertices,    'r');
        outline(imgData.ax, imgData.polygons(i).withoutTongue.vertices, 'b');
    end
end

function outline(ax, v, colr)
    if isempty(v), return; end
    plot(ax, [v(:,1); v(1,1)], [v(:,2); v(1,2)], '-', 'Color', colr, ...
        'LineWidth', 1.5, 'HitTest', 'off', 'PickableParts', 'none');
end


function undoLastPair(src, ~)
    polyFig = ancestor(src, 'figure');
    imgData = guidata(polyFig);

    if ~isfield(imgData, 'polygons') || isempty(imgData.polygons)
        setStep(polyFig, 0, 0);
        return;
    end

    imgData.polygons(end) = [];
    imgData.polygonCount  = numel(imgData.polygons);
    guidata(polyFig, imgData);

    drawPolyPage(polyFig);
    repaint(polyFig);

    imgData = guidata(polyFig);
    title(imgData.ax, sprintf('%d pair(s) remaining', numel(imgData.polygons)));
    setStep(polyFig, 0, 0);
    fprintf('Removed last pair, %d left.\n', numel(imgData.polygons));
end


function out = pick(cond, a, b)
    if cond, out = a; else, out = b; end
end
