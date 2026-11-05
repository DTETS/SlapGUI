function ud = findWASLData()
% UserData of the first open WASL window that has tongue data loaded.
% Shows an error and returns [] if there isn't one.
    ud = [];
    figs = findall(0,'Type','figure');
    for i = 1:numel(figs)
        try
            tmp = get(figs(i),'UserData');
        catch
            continue;   % figure was deleted in the meantime
        end
        if isstruct(tmp) && isfield(tmp,'tongue') && ...
           isfield(tmp.tongue,'V') && isfield(tmp.tongue,'scaling')
            ud = tmp;
            return;
        end
    end
    errordlg('No open WASL figure with .UserData.tongue found. Open WASL and load data first.', 'WASL Missing');
end
