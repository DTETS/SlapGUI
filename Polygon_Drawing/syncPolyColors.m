function syncPolyColors(mainFig)
% Make every open polygon window use the same MRI/US colors as the main
% window (MRI colormap, brightness, gamma and US colormap). Updates the
% images in place, so a polygon being drawn is not lost.

    mainHandles = guidata(mainFig);
    if ~isfield(mainHandles, 'hMRI') || isempty(mainHandles.hMRI) || ~isvalid(mainHandles.hMRI(1))
        return;
    end

    polyFigs = findobj('Type', 'figure', 'Name', 'Coronal polygon measurement');
    for i = 1:numel(polyFigs)
        imgData = guidata(polyFigs(i));
        if ~isstruct(imgData) || ~isfield(imgData, 'ax') || ~isvalid(imgData.ax)
            continue;
        end
        applyColors(imgData, mainHandles);
    end
end


function applyColors(imgData, mainHandles)
    ax = imgData.ax;

    % MRI: indexed image, so it needs the main window's colormap + limits
    colormap(ax, colormap(mainHandles.axCor));
    set(ax, 'CLim', get(mainHandles.axCor, 'CLim'));
    if isfield(imgData, 'hMRI') && ~isempty(imgData.hMRI) && isvalid(imgData.hMRI)
        set(imgData.hMRI, 'CData', get(mainHandles.hMRI(1), 'CData'), ...
                          'CDataMapping', get(mainHandles.hMRI(1), 'CDataMapping'));
    end

    % US: drawn as RGB with the US colormap already applied
    if isfield(imgData, 'hUS') && ~isempty(imgData.hUS) && isvalid(imgData.hUS) ...
            && isfield(mainHandles, 'hUS') && ~isempty(mainHandles.hUS) && isvalid(mainHandles.hUS(1))
        set(imgData.hUS, 'CData',     get(mainHandles.hUS(1), 'CData'), ...
                         'AlphaData', get(mainHandles.hUS(1), 'AlphaData'));
    end
end
