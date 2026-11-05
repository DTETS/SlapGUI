function updateSideReadout(fig, Cnav, thr, tUS)
% Fill in the numbers in the right-hand panel.
% 'nav' mode (the default) shows the live crosshair. 'slap' mode shows the
% values the old SLAP script would print: the MRI center plus any moveby offsets.

    handles = guidata(fig);

    switch handles.readoutMode
        case 'slap'
            AP = handles.MRI.scaling.C(1)*handles.MRI.scaling.scale(1)/2;
            SI = handles.MRI.scaling.C(2)*handles.MRI.scaling.scale(2)/2;
            ML = handles.MRI.scaling.C(3)*handles.MRI.scaling.scale(3)/2;

            if isfield(handles,'APmoveby'), AP = AP + handles.APmoveby; end
            if isfield(handles,'SImoveby'), SI = SI + handles.SImoveby; end
            if isfield(handles,'MLmoveby'), ML = ML + handles.MLmoveby; end

            if isfield(handles,'DCMframe'), frm = handles.DCMframe; else, frm = tUS; end

        otherwise
            AP = Cnav(1); SI = Cnav(2); ML = Cnav(3);
            frm = tUS;
    end

    set(findobj(fig,'Tag','valAP'),'String',sprintf('%.2f', AP));
    set(findobj(fig,'Tag','valSI'),'String',sprintf('%.2f', SI));
    set(findobj(fig,'Tag','valML'),'String',sprintf('%.2f', ML));
    set(findobj(fig,'Tag','valTH'),'String',sprintf('%.0f', thr));
    set(findobj(fig,'Tag','valFR'),'String',sprintf('%d', frm));
end
