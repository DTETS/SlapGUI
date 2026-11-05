function onPolyDraw(src, ~)
% Draw one pair of polygons at the current position:
%   first a red one with the tongue (US overlay shown, VwT),
%   then a blue one without it (MRI only, VwoT).
% Pressing Esc at either step throws the pair away.

    polyFig = ancestor(src, 'figure');
    imgData = guidata(polyFig);
    ax      = imgData.ax;

    % disable the buttons while drawing, re-enabled however we leave
    ui = polyPanel(polyFig);
    lockBtns = [ui.btnDraw ui.btnSave ui.btnUndo];
    set(lockBtns, 'Enable', 'off'); drawnow;
    restoreBtns = onCleanup(@() set(lockBtns(isvalid(lockBtns)), 'Enable', 'on')); %#ok<NASGU>

    if ~isfield(imgData, 'polygons') || isempty(imgData.polygons)
        imgData.polygons = struct('withTongue', {}, 'withoutTongue', {}, ...
                                  'corIdx', {}, 'frame', {}, 'crosshair', {}, 'position', {});
    end
    pairNum = numel(imgData.polygons) + 1;

    % Red polygon, with tongue
    polyPanel(polyFig, 'step', 1, pairNum);
    title(ax, sprintf('Pair %d - draw RED: WITH TONGUE (US visible) - double-click the last vertex', pairNum));

    v1 = drawOnce(ax, 'r');
    if isempty(v1)
        polyPanel(polyFig, 'step', -1, pairNum);
        title(ax, 'Cancelled - nothing saved.');
        return;
    end
    area1 = polyarea(v1(:,1), v1(:,2));
    fprintf('Pair %d - with tongue    (VwT):  %.4f cm^2\n', pairNum, area1);

    % hide the US overlay (not delete, we need it back afterwards)
    if isfield(imgData, 'hUS') && ~isempty(imgData.hUS) && isvalid(imgData.hUS)
        set(imgData.hUS, 'Visible', 'off');
    end

    % Blue polygon, without tongue
    polyPanel(polyFig, 'step', 2, pairNum);
    title(ax, sprintf('Pair %d - draw BLUE: WITHOUT TONGUE (MRI only) - double-click the last vertex', pairNum));

    v2 = drawOnce(ax, 'b');
    if isempty(v2)
        if isfield(imgData, 'hUS') && ~isempty(imgData.hUS) && isvalid(imgData.hUS)
            set(imgData.hUS, 'Visible', 'on');
        end
        drawPolyPage(polyFig);   % gets rid of the leftover red outline
        polyPanel(polyFig, 'repaint');
        polyPanel(polyFig, 'step', -1, pairNum);
        title(ax, 'Cancelled - pair discarded.');
        return;
    end
    area2 = polyarea(v2(:,1), v2(:,2));
    fprintf('Pair %d - without tongue (VwoT): %.4f cm^2\n', pairNum, area2);

    % Position info comes from the main window. The first pair drawn becomes
    % position 0 and every 2 mm step in AP after that is +1.
    mainFig = findobj('Type', 'figure', 'Name', 'Align US over MRI');
    if ~isempty(mainFig)
        mainHandles = guidata(mainFig(1));
        ch = mainHandles.crosshair;

        if ~isfield(mainHandles, 'polygonReferenceAP') || isempty(mainHandles.polygonReferenceAP)
            mainHandles.polygonReferenceAP = ch(1);
            guidata(mainFig(1), mainHandles);
            posNum = 0;
        else
            posNum = round((ch(1) - mainHandles.polygonReferenceAP) / 0.2);
        end
        refAP  = mainHandles.polygonReferenceAP;
        corIdx = round(ch(1) / imgData.MRI.scaling.scale(1));

        if isfield(mainHandles, 'tFrozen')
            frame = mainHandles.tFrozen;
        else
            frame = imgData.frame;
        end
    else
        ch = [NaN NaN NaN]; posNum = 0; refAP = NaN;
        corIdx = imgData.corIdx;
        frame  = imgData.frame;
    end

    % save the pair before redrawing anything
    imgData.polygons(pairNum).withTongue.vertices    = v1;
    imgData.polygons(pairNum).withTongue.area        = area1;
    imgData.polygons(pairNum).withoutTongue.vertices = v2;
    imgData.polygons(pairNum).withoutTongue.area     = area2;
    imgData.polygons(pairNum).corIdx    = corIdx;
    imgData.polygons(pairNum).frame     = frame;
    imgData.polygons(pairNum).crosshair = ch;
    imgData.polygons(pairNum).position  = posNum;
    imgData.polygonCount = pairNum;
    guidata(polyFig, imgData);

    fprintf('Stored position %d at AP=%.2f cm (reference AP=%.2f cm)\n', posNum, ch(1), refAP);

    drawPolyPage(polyFig);
    polyPanel(polyFig, 'repaint');

    imgData  = guidata(polyFig);   % drawPolyPage replaced hUS, so read it again
    totalWT  = sum(arrayfun(@(p) p.withTongue.area,    imgData.polygons));
    totalWoT = sum(arrayfun(@(p) p.withoutTongue.area, imgData.polygons));
    title(ax, sprintf('%d pair(s) | with tongue: %.2f cm^2 | without tongue: %.2f cm^2 | position %d', ...
        pairNum, totalWT, totalWoT, posNum));

    % has to come after drawPolyPage or the frame color gets lost
    polyPanel(polyFig, 'step', 3, pairNum);

    fprintf('Pair %d: slice %d, frame %d, position %d\n', pairNum, corIdx, frame, posNum);
    fprintf('  with tongue %.4f, without %.4f, total %.4f cm^2\n', ...
        area1, area2, area1 + area2);
end


function v = drawOnce(ax, colr)
% Let the user draw one polygon and return its vertices, or [] if they
% pressed Esc or placed fewer than 3 points. drawpolygon blocks on its own
% until the double-click, so no wait() is needed.
%
% The interactive ROI gets replaced by a plain outline right away. That way
% it stays visible while the next polygon is drawn, but its vertices
% can't catch the clicks.
    v = [];
    h = drawpolygon(ax, 'LineWidth', 2, 'Color', colr);
    if isempty(h) || ~isvalid(h), return; end
    v = h.Position;
    delete(h);
    if size(v, 1) < 3, v = []; return; end

    hold(ax, 'on');
    plot(ax, [v(:,1); v(1,1)], [v(:,2); v(1,2)], '-', 'Color', colr, ...
        'LineWidth', 1.5, 'HitTest', 'off', 'PickableParts', 'none');
end
