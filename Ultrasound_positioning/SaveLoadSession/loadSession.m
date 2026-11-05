function st = loadSession(usName, excelFile)
    st.center = []; 
    st.threshold = [];
    st.rotation = [];
    if ~isfile(excelFile), return; end

    T = readtable(excelFile);
    vn = T.Properties.VariableNames;

    % basic validation
    need = {'US_Name','Center_X','Center_Y','Center_Z', 'Rotation_C', 'Rotation_A', 'Rotation_S', 'Threshold'};
    for k=1:numel(need)
        if ~ismember(need{k}, vn), return; end
    end

    idx = find(strcmp(string(T.US_Name), string(usName)), 1);
    if isempty(idx), return; end

    
    st.center    = [T.Center_X(idx), T.Center_Y(idx), T.Center_Z(idx)];
    st.rotation  = [T.Rotation_C(idx), T.Rotation_A(idx), T.Rotation_S(idx)];
    st.threshold = T.Threshold(idx);
end
