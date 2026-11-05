function maybeDrawSlices(fig)
% Redraw the three MRI views with the US overlay on top.
% Fills in any missing state with defaults first, so it's safe to call any time.

    handles = guidata(fig);

    % brightness defaults, keep in sync with SlapGUI.m
    if ~isfield(handles,'mriBright'), handles.mriBright = 1.8; end
    if ~isfield(handles,'mriGamma'),  handles.mriGamma  = 0.8; end

    if ~isfield(handles,'MRI') || ~isfield(handles,'US'), return; end
    MRI = handles.MRI;
    US  = handles.US;

    if ~isfield(handles,'usRotDeg'), handles.usRotDeg = [0 0 0]; end  % [AP SI ML] deg

    % US native center, in the US's own cm space. Slicing and rotation use it
    % as a fixed reference.
    usNative = (US.scaling.C .* US.scaling.scale) / 2;

    % By default the US starts at the center of the MRI volume
    mriCenter = (MRI.scaling.C(1:3) + 1) .* MRI.scaling.scale(1:3) / 2;
    if ~isfield(handles,'usStartPos') || numel(handles.usStartPos)~=3
        handles.usStartPos = mriCenter;
    end
    if ~isfield(handles,'usCenter') || numel(handles.usCenter)~=3
        handles.usCenter = handles.usStartPos;
    end
    if ~isfield(handles,'crosshair') || numel(handles.crosshair)~=3
        handles.crosshair = handles.usCenter;
    end
    if ~isfield(handles,'crosshairDraw') || numel(handles.crosshairDraw)~=3
        handles.crosshairDraw = handles.crosshair;
    end

    % Pivot stays put so the US doesn't drift when the crosshair moves
    if ~isfield(handles,'usRotCenter')
        handles.usRotCenter = usNative;
    end
    if ~isfield(handles,'initialUSSlices')
        handles.initialUSSlices = toIndex(usNative, US);
    end

    if ~isfield(handles,'t'),          handles.t          = 1; end
    if ~isfield(handles,'tFrozen'),    handles.tFrozen    = handles.t; end
    if ~isfield(handles,'usLocked'),   handles.usLocked   = false; end
    if ~isfield(handles,'threshold'),  handles.threshold  = 150; end
    if ~isfield(handles,'viewRotDeg'), handles.viewRotDeg = [0 0 0]; end

    % Which frame to show
    if handles.usLocked
        tEff = handles.t;
        handles.tFrozen = tEff;
    else
        tEff = handles.tFrozen;
    end
    tUS  = min(max(1,tEff), max(size(US.V ,4),1));
    tMRI = min(max(1,tEff), max(size(MRI.V,4),1));
    thr  = handles.threshold;

    Cdraw = handles.crosshairDraw;
    Cnav  = handles.crosshair;

    % 3D interpolants for rotating, rebuilt only when the frame changes
    if ~isfield(handles,'USinterp') || ~isfield(handles,'USinterp_t') || handles.USinterp_t ~= tUS
        handles.USinterp   = volumeInterpolant(US, tUS);
        handles.USinterp_t = tUS;
    end
    if ~isfield(handles,'MRIinterp') || ~isfield(handles,'MRIinterp_t') || handles.MRIinterp_t ~= tMRI
        handles.MRIinterp   = volumeInterpolant(MRI, tMRI);
        handles.MRIinterp_t = tMRI;
    end

    % MRI slices follow the crosshair
    mriIdx = toIndex(Cnav, MRI);

    % Where the US sits on the MRI. Frozen while locked.
    % US local cm + usOffset = MRI (world) cm.
    if handles.usLocked
        if ~isfield(handles,'usAlignFrozen'), handles.usAlignFrozen = handles.usCenter; end
        Calign = handles.usAlignFrozen;
    else
        Calign = handles.usCenter;
        handles.usAlignFrozen = Calign;
    end
    usOffset = Calign - (US.scaling.C/2) .* US.scaling.scale;

    % US slices go through the same point as the MRI slices (locked or not),
    % so e.g. the +/-2 mm AP buttons move the US coronal along with the MRI.
    % A view whose slice falls outside the US volume shows no US.
    mriSlicePos = mriIdx .* MRI.scaling.scale(1:3);
    usIdxRaw = round((mriSlicePos - usOffset) ./ US.scaling.scale);
    usInside = usIdxRaw >= 1 & usIdxRaw <= US.scaling.C;   % [cor ax sag] normals = [AP SI ML]
    usIdx    = min(max(usIdxRaw, 1), US.scaling.C);

    % Oblique coronal (View Angle): the plane tilts around the crosshair, so
    % it goes through the tilted line drawn in the sagittal view. The MRI and
    % the US get the same tilt so they show the same plane.
    mriPivot = [mriIdx(1)*MRI.scaling.scale(1), Cnav(2), Cnav(3)];
    usPivot  = mriPivot - usOffset;                       % same point, US cm
    usPivot(1) = usIdx(1) * US.scaling.scale(1);          % on the US coronal slice

    [uCor,uAx,uSag] = resliceVolume(handles.USinterp, US, usIdx, handles.usRotDeg, ...
                                    handles.usRotCenter, handles.viewRotDeg, usPivot);
    if ~usInside(1), uCor(:) = NaN; end
    if ~usInside(2), uAx(:)  = NaN; end
    if ~usInside(3), uSag(:) = NaN; end

    % Only the coronal MRI view uses the rotated (oblique) slice.
    % Axial and sagittal are taken straight from the volume.
    mCor = resliceVolume(handles.MRIinterp, MRI, mriIdx, [0 0 0], mriPivot, ...
                         handles.viewRotDeg, mriPivot);
    mAx  = double(squeeze(MRI.V(:,mriIdx(2),:,tMRI)));
    mSag = double(squeeze(MRI.V(:,:,mriIdx(3),tMRI)))';

    % Each view shows two of the three directions [AP SI ML]:
    % coronal x=ML y=SI, axial x=ML y=AP, sagittal x=AP y=SI
    xDim = [3 3 1];
    yDim = [2 1 2];

    % First call only: create the axes, images and crosshair lines
    if ~isfield(handles,'viewInit') || ~handles.viewInit
        main = findobj(fig,'Type','uipanel','Tag','mainPanel');
        if isempty(main), main = fig; end

        titles = {'Coronal (SI vs ML)', 'Axial (AP vs ML)', 'Sagittal (AP vs SI)'};
        axs = gobjects(1,3);
        for k = 1:3
            axs(k) = subplot(1,3,k,'Parent',main);
            title(axs(k), titles{k});
            set(axs(k),'YDir','normal');
        end
        handles.axCor = axs(1);
        handles.axAx  = axs(2);
        handles.axSag = axs(3);

        % MRI colormap, picked in the GUI (parula, turbo and hot work well)
        if ~isfield(handles,'mriCmapName'), handles.mriCmapName = 'parula'; end
        cmap = feval(handles.mriCmapName, 256);

        for k = 1:3
            axes(axs(k));
            handles.hMRI(k) = image('XData', voxelCoords(MRI, xDim(k)), ...
                                    'YData', voxelCoords(MRI, yDim(k)), ...
                                    'CData', zeros(2,'uint8'), 'CDataMapping','scaled');
            axis(axs(k),'image'); hold(axs(k),'on');
            colormap(axs(k), cmap); set(axs(k),'CLim',[0 255]);

            handles.hUS(k) = image('CData',zeros(2,'uint8'),'AlphaData',0);
            uistack(handles.hUS(k),'top');

            handles.hXhairV(k) = line(axs(k),[0 0],[0 1],'Color','k','LineWidth',1,'HitTest','off');
            handles.hXhairH(k) = line(axs(k),[0 1],[0 0],'Color','k','LineWidth',1,'HitTest','off');
        end

        handles.viewInit = true;
    end
    axs = [handles.axCor handles.axAx handles.axSag];

    % The US is drawn as RGB so its colormap doesn't depend on the MRI's
    if ~isfield(handles,'usCmapName'), handles.usCmapName = 'parula'; end
    usCmap = feval(handles.usCmapName, 256);

    mriSlices = {mCor, mAx, mSag};
    usSlices  = {uCor, uAx, uSag};
    for k = 1:3
        set(handles.hMRI(k), 'CData', adjSlice(mriSlices{k}, handles.mriBright, handles.mriGamma), ...
                             'XData', voxelCoords(MRI, xDim(k)), ...
                             'YData', voxelCoords(MRI, yDim(k)));

        u = usSlices{k};
        [h,w] = size(u);
        set(handles.hUS(k), 'CData', usToRGB(u, usCmap), ...
            'AlphaData', 0.8*double(u >= thr), 'AlphaDataMapping','none', ...
            'XData', (1:w)*US.scaling.scale(xDim(k)) + usOffset(xDim(k)), ...
            'YData', (1:h)*US.scaling.scale(yDim(k)) + usOffset(yDim(k)));

        fitAxes(axs(k), handles.hMRI(k), handles.hUS(k));

        % Crosshair. With a view rotation, the vertical line in the sagittal
        % view tilts to show where the rotated coronal plane cuts.
        % The vertical line has to be set before the horizontal one: the axis
        % limits follow the data, so a tilted line can widen them.
        cx = Cdraw(xDim(k));
        cy = Cdraw(yDim(k));
        if k == 3 && norm(handles.viewRotDeg) > 0.1
            theta   = deg2rad(handles.viewRotDeg(3));
            halfLen = diff(xlim(axs(k))) / 2;
            dx = halfLen * sin(theta);
            dy = halfLen * cos(theta);
            set(handles.hXhairV(k), 'XData', [cx - dx, cx + dx], 'YData', [cy - dy, cy + dy]);
        else
            set(handles.hXhairV(k), 'XData', [cx cx], 'YData', ylim(axs(k)));
        end
        set(handles.hXhairH(k), 'XData', xlim(axs(k)), 'YData', [cy cy]);
    end
    title(handles.axCor,'Coronal (SI vs ML)');

    if ~isempty(findobj(fig,'Tag','valAP'))
        updateSideReadout(fig, Cnav, thr, tUS);
    end
    handles.usLastSlices = usIdx;

    updateAngleHUD(fig, handles.usRotDeg, handles.viewRotDeg(3));

    guidata(fig, handles);
    drawnow limitrate;
end


function idx = toIndex(posCm, vol)
% Position in cm to voxel index, clamped to the volume
    idx = min(max(round(posCm ./ vol.scaling.scale(1:3)), 1), vol.scaling.C(1:3));
end

function c = voxelCoords(vol, dim)
% Position in cm of every voxel along one dimension
    c = (1:vol.scaling.C(dim)) * vol.scaling.scale(dim);
end

function F = volumeInterpolant(vol, t)
    F = griddedInterpolant({voxelCoords(vol,1), voxelCoords(vol,2), voxelCoords(vol,3)}, ...
                           single(vol.V(:,:,:,t)), 'linear','none');
end

function rgb = usToRGB(U, cmap)
% US intensities 0-255 to truecolor. NaN (outside the volume) becomes 0.
    U(isnan(U)) = 0;
    idx = round(min(max(double(U),0),255)) + 1;
    rgb = reshape(cmap(idx,:), [size(U) 3]);
end

function A8 = adjSlice(A, bright, gamma)
    A = double(A);
    A = A - min(A(:));
    mx = max(1, max(A(:)));
    A = (A/mx) .^ max(0.01, gamma);
    A8 = uint8(min(255, 255*bright*A));
end

function fitAxes(ax, hMRI, hUS)
% Widen the axis limits so both the MRI and the US fit
    xAll = [get(hMRI,'XData'), get(hUS,'XData')];
    yAll = [get(hMRI,'YData'), get(hUS,'YData')];
    xlim(ax, [min(xAll) max(xAll)]);
    ylim(ax, [min(yAll) max(yAll)]);
    axis(ax,'image');
end
