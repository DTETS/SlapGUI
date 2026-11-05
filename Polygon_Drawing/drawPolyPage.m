function drawPolyPage(polyFig)
% Copy the coronal MRI + US overlay from the main window into the polygon
% window. This clears the axes, so call polyPanel(polyFig,'repaint')
% afterwards to get the polygons back.

    imgData = guidata(polyFig);

    mainFig = findobj('Type', 'figure', 'Name', 'Align US over MRI');
    if isempty(mainFig)
        error('Main GUI not found');
    end
    mainHandles = guidata(mainFig(1));

    MRI = imgData.MRI;
    ax  = imgData.ax;

    if ~isfield(mainHandles, 'hMRI') || isempty(mainHandles.hMRI)
        error('Main GUI not properly initialized');
    end

    cla(ax);
    hold(ax, 'on');
    set(ax, 'YDir', 'normal');

    hMRI = image(get(mainHandles.hMRI(1), 'CData'), 'Parent', ax);
    set(hMRI, 'XData', get(mainHandles.hMRI(1), 'XData'), ...
              'YData', get(mainHandles.hMRI(1), 'YData'), ...
              'CDataMapping', get(mainHandles.hMRI(1), 'CDataMapping'));
    axis(ax, 'equal', 'tight');

    % use the MRI colormap picked in the main window (the US is RGB already)
    colormap(ax, colormap(mainHandles.axCor));
    set(ax, 'CLim', get(mainHandles.axCor, 'CLim'));
    imgData.hMRI = hMRI;

    imgData.hUS = gobjects(0);
    if isfield(mainHandles, 'hUS') && ~isempty(mainHandles.hUS) && isvalid(mainHandles.hUS(1))
        hUS = image(get(mainHandles.hUS(1), 'CData'), 'Parent', ax);
        set(hUS, 'XData', get(mainHandles.hUS(1), 'XData'), ...
                 'YData', get(mainHandles.hUS(1), 'YData'));
        hUS.AlphaData        = get(mainHandles.hUS(1), 'AlphaData');
        hUS.AlphaDataMapping = 'none';
        imgData.hUS = hUS;
    end

    if isfield(mainHandles, 'crosshair')
        corIdx = round(mainHandles.crosshair(1) / MRI.scaling.scale(1));
    else
        corIdx = imgData.corIdx;
    end
    if isfield(mainHandles, 'tFrozen')
        frame = mainHandles.tFrozen;
    else
        frame = imgData.frame;
    end

    title(ax, sprintf('Coronal slice %d - Frame %d', corIdx, frame));
    guidata(polyFig, imgData);
end
