function onSaveButtonPressed(~, ~)
    fig = findobj('Type','figure','-and','Name','Align US over MRI');
    H = guidata(fig);
    if ~isfield(H,'US') || ~isfield(H,'usCenter') || ~isfield(H,'threshold')
        errordlg('Cannot save: missing data.'); return;
    end

    [file, path] = uiputfile('*.xlsx','Save session settings as');
    if isequal(file,0), return; end
    excelFile = fullfile(path,file);

    saveSession(H.US.name, H.usCenter, H.threshold, H.usRotDeg, excelFile);
end
