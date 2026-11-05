function [sCor,sAx,sSag] = resliceVolume(F, vol, idx, Rdeg, center, viewDeg, viewCenter)
% Coronal, axial and sagittal slices through voxel idx = [AP SI ML] of a
% volume rotated by Rdeg = [AP SI ML] degrees around center (cm).
% F is a griddedInterpolant over the volume in cm. Used for both the US
% and the MRI. Only the slices that are asked for get computed.
%
% Optional viewDeg / viewCenter tilt the coronal slice only (the oblique
% "View Angle"): the coronal plane is rotated by viewDeg around viewCenter
% (cm, in this volume's coordinates) before the volume rotation is applied.
% Pass the same tilt for the MRI and the US so both show the same plane.

    if nargin < 6 || isempty(viewDeg),    viewDeg    = [0 0 0]; end
    if nargin < 7 || isempty(viewCenter), viewCenter = center;  end

    R  = rotMat(Rdeg);
    Rv = rotMat(viewDeg);

    % voxel positions in cm
    AP = single((1:vol.scaling.C(1)) * vol.scaling.scale(1));
    SI = single((1:vol.scaling.C(2)) * vol.scaling.scale(2));
    ML = single((1:vol.scaling.C(3)) * vol.scaling.scale(3));
    center     = single(center(:));
    viewCenter = single(viewCenter(:));

    [si, ml] = ndgrid(SI, ML);                           % coronal: SI x ML
    ap = AP(idx(1)) * ones(size(si), 'single');
    P  = [ap(:)'; si(:)'; ml(:)'];
    if any(viewDeg ~= 0)
        P = single(Rv.') * (P - viewCenter) + viewCenter;  % tilt the plane
    end
    sCor = sample(F, P, size(si), R, center);

    if nargout >= 2
        [ap, ml] = ndgrid(AP, ML);                       % axial: AP x ML
        si = SI(idx(2)) * ones(size(ap), 'single');
        sAx = sample(F, [ap(:)'; si(:)'; ml(:)'], size(ap), R, center);
    end
    if nargout >= 3
        [ap, si] = ndgrid(AP, SI);                       % sagittal: AP x SI
        ml = ML(idx(3)) * ones(size(ap), 'single');
        sSag = sample(F, [ap(:)'; si(:)'; ml(:)'], size(ap), R, center)';
    end
end

function R = rotMat(d)
% R = Rz(ML) * Ry(SI) * Rx(AP), angles in degrees
    Rx = [1 0 0; 0 cosd(d(1)) -sind(d(1)); 0 sind(d(1)) cosd(d(1))];
    Ry = [cosd(d(2)) 0 sind(d(2)); 0 1 0; -sind(d(2)) 0 cosd(d(2))];
    Rz = [cosd(d(3)) -sind(d(3)) 0; sind(d(3)) cosd(d(3)) 0; 0 0 1];
    R  = Rz * Ry * Rx;
end

function S = sample(F, P, sz, R, center)
% Rotate the plane's points back into the original volume and read it there
    Q = single(R.') * (P - center) + center;
    S = F(reshape(Q(1,:), sz), reshape(Q(2,:), sz), reshape(Q(3,:), sz));
end
