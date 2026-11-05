function saveSession(usName, center, threshold, rotation, excelFile)
    vars = {'US_Name','Center_X','Center_Y','Center_Z', 'Rotation_C', 'Rotation_A', 'Rotation_S', 'Threshold'};

    if isfile(excelFile)
        T = readtable(excelFile);
        % create columns if file had none/other
        for k = 1:numel(vars)
            if ~ismember(vars{k}, T.Properties.VariableNames)
                T.(vars{k}) = missing;
            end
        end
    else
        T = cell2table(cell(0,numel(vars)), 'VariableNames', vars);
    end

    % overwrite row if US_Name exists
    idx = find(strcmp(string(T.US_Name), string(usName)), 1);
    newRow = {string(usName), center(1), center(2), center(3), rotation(1), rotation(2), rotation(3), threshold};

    if isempty(idx)
        T = [T; cell2table(newRow,'VariableNames',vars)];
    else
        T{idx, vars} = newRow;
    end

    writetable(T, excelFile);
end
