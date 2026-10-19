function out = imageTo3D(imgFile, opts)
%IMAGETO3D  One call turns ANY raster image (PNG/JPEG) into a 3-D relief model.
%
%   out = imageTo3D(IMGFILE) reads a bitmap, builds a smooth height field from
%   its grayscale (broad volume + fine detail), writes a thin, watertight STL
%   and a gold preview image.  This generalises the "image on a relief" look so
%   it works from a plain PNG/JPEG - no vector source, no reference mesh.
%
%   out = imageTo3D(IMG, OPTS) with fields:
%       outdir    where to write files                 (default: next to the image)
%       res       raster resolution, long side px      (default 600)
%       invert    raise dark pixels (line art)         (default false)
%       blur      volume softness (fraction)           (default 0.02)
%       detail    detail radius (fraction)             (default 0.004)
%       sharp     high-pass weight                     (default 0.50)
%       gain      tanh cap steepness                   (default 3.0)
%       sizeMM    longest side of the part, mm         (default 150)
%       plate     base thickness, mm                   (default 1.5)
%       relief    relief height, mm                    (default 3.0)
%       render    also write a gold PNG preview        (default true)
%       viewTop   face-on top view for the preview     (default true)
%
%   OUT fields: stl, png, X, Y, Z, dim ([w h t] mm), nTri.
%
%   Example
%       imageTo3D('assets/main_clean.png', struct('invert', true));

if nargin < 2, opts = struct(); end
def = struct('outdir', '', 'res', 600, 'invert', false, 'blur', 0.02, ...
             'detail', 0.004, 'sharp', 0.50, 'gain', 3.0, 'sizeMM', 150, ...
             'plate', 1.5, 'relief', 3.0, 'render', true, 'viewTop', true);
o = def;
fn = fieldnames(opts);
for k = 1:numel(fn), o.(fn{k}) = opts.(fn{k}); end

if isempty(o.outdir)
    o.outdir = fileparts(which(imgFile));
    if isempty(o.outdir), o.outdir = fileparts(imgFile); end
end
if ~exist(o.outdir, 'dir'), mkdir(o.outdir); end
[~, base] = fileparts(imgFile);

% ----------------------------------------------- 1) image -> height field
r  = imageToRelief(imgFile, struct('res', o.res, 'invert', o.invert, ...
                 'blur', o.blur, 'detail', o.detail, 'sharp', o.sharp, ...
                 'gain', o.gain));
Xg = r.X;  Yg = r.Y;  Z = r.Z;
clear r

% --------------------------------------------------- 2) write the thin STL
stl  = fullfile(o.outdir, [base '_3d.stl']);
[nTri, dim] = reliefWriteSTL(Xg, Yg, Z, stl, struct('sizeMM', o.sizeMM, ...
                  'plate', o.plate, 'relief', o.relief));

% ------------------------------------------------------- 3) gold preview
png = fullfile(o.outdir, [base '_3d.png']);
if o.render
    figure('Color','w', 'Name',['Image to 3D - ' base]);
    surf(Xg, Yg, Z, 'EdgeColor','none', 'FaceColor','interp');
    goldMap = [linspace(0.30,1.00,256)', linspace(0.12,0.90,256)', linspace(0.02,0.45,256)'];
    colormap(goldMap);
    shading interp;  lighting gouraud;
    camlight('headlight');  camlight('left');  camlight('right');
    material([0.35 0.65 0.85 30 0.60]);
    axis equal off;
    if o.viewTop, view(0, 90); else, view(-25, 60); end
    title(['Image to 3D relief: ' base]);
    try
        exportgraphics(gcf, png, 'Resolution', 150, 'BackgroundColor', 'w');
    catch
    end
end

out = struct('stl', stl, 'png', png, 'X', Xg, 'Y', Yg, 'Z', Z, ...
             'dim', dim, 'nTri', nTri);
fprintf('imageTo3D: %s -> %d triangles, %.1f x %.1f x %.1f mm\n', ...
    base, nTri, dim(1), dim(2), dim(3));
end
