function onPolySave(src, ~)
% Write every finished polygon pair to the Excel file, one row per position.
%
% Area is computed the same way as in the .mlx: polyarea on each polygon,
% summed over the pair. We don't divide by 100 here because the axes are
% already in cm. The /100 in the .mlx is only for the oblique section,
% where obliqueslice gives back an image in voxels.

    polyFig = ancestor(src, 'figure');
    imgData = guidata(polyFig);

    if ~isfield(imgData, 'polygons') || isempty(imgData.polygons)
        errordlg('No polygons to save. Draw a pair first.', 'Save Error');
        return;
    end

    if isfield(imgData, 'excelFile') && ~isempty(imgData.excelFile)
        excelFile = imgData.excelFile;
    else
        excelFile = fullfile(pwd, 'polygonAreas.xlsx');
    end

    mainFig = findobj('Type', 'figure', 'Name', 'Align US over MRI');
    usName  = 'Unknown';
    if ~isempty(mainFig)
        mainHandles = guidata(mainFig(1));
        if isfield(mainHandles, 'US') && isfield(mainHandles.US, 'name') && ...
                ~isempty(mainHandles.US.name)
            [~, usName, ~] = fileparts(mainHandles.US.name);
        end
    end

    vars = {'US_Name', 'Position', 'AP_cm', 'SI_cm', 'ML_cm', ...
            'Coronal_Slice', 'Frame', 'Area_cm2'};

    if isfile(excelFile)
        T = readtable(excelFile);
        for k = 1:numel(vars)
            if ~ismember(vars{k}, T.Properties.VariableNames)
                T.(vars{k}) = missing;
            end
        end
    else
        T = cell2table(cell(0, numel(vars)), 'VariableNames', vars);
    end
    T.US_Name = string(T.US_Name);   % so the comparison and assignment below work

    nSaved = 0;
    for i = 1:numel(imgData.polygons)
        p = imgData.polygons(i);

        % skip half-drawn pairs
        if ~isfield(p, 'withTongue')    || isempty(p.withTongue) || ...
           ~isfield(p, 'withoutTongue') || isempty(p.withoutTongue)
            fprintf('Skipping incomplete pair %d\n', i);
            continue;
        end

        totalArea = p.withTongue.area + p.withoutTongue.area;
        posNum    = p.position;
        crosshair = p.crosshair;

        % overwrite the row if this US + position is already in the file
        idx = [];
        if height(T) > 0
            idx = find(T.US_Name == string(usName) & T.Position == posNum, 1);
        end

        if isempty(idx)
            newRow = {string(usName), posNum, crosshair(1), crosshair(2), crosshair(3), ...
                      p.corIdx, p.frame, totalArea};
            T = [T; cell2table(newRow, 'VariableNames', vars)]; %#ok<AGROW>
        else
            T.US_Name(idx)       = string(usName);
            T.Position(idx)      = posNum;
            T.AP_cm(idx)         = crosshair(1);
            T.SI_cm(idx)         = crosshair(2);
            T.ML_cm(idx)         = crosshair(3);
            T.Coronal_Slice(idx) = p.corIdx;
            T.Frame(idx)         = p.frame;
            T.Area_cm2(idx)      = totalArea;
        end
        nSaved = nSaved + 1;
    end

    if nSaved == 0
        errordlg('No completed pairs to save.', 'Save Error');
        return;
    end

    writetable(T, excelFile);
    fprintf('Saved %d position(s) for %s to %s\n', nSaved, usName, excelFile);

    msgbox(sprintf('Polygon data saved.\n\n%d position(s) from %s\nSaved to:\n%s', ...
        nSaved, usName, excelFile), 'Save Successful');

    polyPanel(polyFig, 'step', 0, 0);
end
