function [nTri, dim] = reliefWriteSTL(X, Y, Z, fname, opts)
%RELIEFWRITESTL  Write a thin, 3-D-print-friendly relief solid from a height grid.
%
%   [nTri, dim] = reliefWriteSTL(X, Y, Z, fname) turns a height map into a
%   watertight binary STL that is easy to 3-D print:
%       * X, Y are scaled so the LONGEST side is OPTS.sizeMM millimetres,
%       * the normalised height Z is lifted into a shallow
%         [plate, plate+relief] band, giving a flat back and a gentle relief,
%     so the part stays thin (no tall slabs, no steep overhangs) regardless of
%     the units X, Y, Z happen to be in.
%
%   OPTS fields:
%       sizeMM   longest side of the part, mm         (default 150)
%       plate    flat base thickness, mm              (default 1.5)
%       relief   relief height above the plate, mm    (default 3.0)
%
%   dim = [widthY heightY thickness] of the written part, in mm.

if nargin < 5 || isempty(opts), opts = struct(); end
def = struct('sizeMM', 150, 'plate', 1.5, 'relief', 3.0);
o = def;
fn = fieldnames(opts);
for k = 1:numel(fn), o.(fn{k}) = opts.(fn{k}); end

X = single(X);  Y = single(Y);
xr = double(max(X(:)) - min(X(:)));
yr = max(Y(:)) - min(Y(:));
mmPerUnit = o.sizeMM / max([xr yr]);

g   = (Z - min(Z(:))) ./ max(range(Z(:)), eps);   % 0..1
Zmm = single(o.plate) + single(o.relief) * single(g);

nTri = writeDurgaSTL(X*mmPerUnit, Y*mmPerUnit, Zmm, fname);

dim = [xr*mmPerUnit, yr*mmPerUnit, o.plate + o.relief];
fprintf('relief STL: %s\n  size %.1f x %.1f mm | thickness %.1f mm (plate %.1f + relief %.1f)\n', ...
    fname, dim(1), dim(2), dim(3), o.plate, o.relief);
end
