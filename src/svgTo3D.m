function out = svgTo3D(svgFile, opts)
%SVGTO3D  One call turns ANY SVG image into a 3-D printable relief model.
%
%   out = svgTo3D(SVGFILE) parses the SVG, builds a smooth height field from its
%   strokes (and filled shapes when present), writes a thin, watertight STL and
%   a gold preview image - a smooth "line-art on a relief" look built straight
%   from a plain SVG, with no reference mesh needed.
%
%   out = svgTo3D(SVG, OPTS) with fields:
%       outdir      where to write files                (default: next to the SVG)
%       mode        'auto'|'stroke'|'fill'|'both'       (default 'auto')
%       res         raster resolution, long side px     (default 600)
%       strokeWidth stroke thickness (fraction)          (default 0.004)
%       blur        Gaussian softness                    (default 0.005)
%       sizeMM      longest side of the part, mm         (default 150)
%       plate       base thickness, mm                   (default 1.5)
%       relief      relief height, mm                    (default 3.0)
%       render      also write a gold PNG preview        (default true)
%       viewTop     face-on top view for the preview     (default true)
%
%   OUT fields: stl, png, X, Y, Z, dim ([w h t] mm), nTri.
%
%   Example
%       svgTo3D('assets/durgamaa_svg.svg');

if nargin < 2, opts = struct(); end
def = struct('outdir', '', 'res', 600, 'mode', 'auto', 'strokeWidth', 0.004, ...
             'blur', 0.005, 'sizeMM', 150, 'plate', 1.5, 'relief', 3.0, ...
             'render', true, 'viewTop', true);
o = def;
fn = fieldnames(opts);
for k = 1:numel(fn), o.(fn{k}) = opts.(fn{k}); end

if isempty(o.outdir)
    o.outdir = fileparts(which(svgFile));
    if isempty(o.outdir), o.outdir = fileparts(svgFile); end
end
if ~exist(o.outdir, 'dir'), mkdir(o.outdir); end
[~, base] = fileparts(svgFile);

% ------------------------------------------------- 1) SVG -> height field
r = svgToRelief(svgFile, struct('res', o.res, 'mode', o.mode, ...
                 'strokeWidth', o.strokeWidth, 'blur', o.blur));
[Xg, Yg, Zrelief] = deal(r.X, r.Y, r.Z);

% ------------------------------------------------------ 2) thin STL
stl = fullfile(o.outdir, [base '_3d.stl']);
[nTri, dim] = reliefWriteSTL(Xg, Yg, Zrelief, stl, ...
    struct('sizeMM', o.sizeMM, 'plate', o.plate, 'relief', o.relief));

% ------------------------------------------------------------- 3) render
png = fullfile(o.outdir, [base '_3d.png']);
if o.render
    f = figure('Color', 'w', 'Name', ['SVG to 3D: ' base]);
    surf(Xg, Yg, Zrelief, 'EdgeColor', 'none', 'FaceColor', 'interp');
    goldMap = [linspace(0.30,1.00,256)', linspace(0.12,0.90,256)', linspace(0.02,0.45,256)'];
    colormap(goldMap);
    shading interp;  lighting gouraud;
    camlight('headlight');  camlight('left');  camlight('right');
    material([0.35 0.65 0.85 30 0.60]);
    axis equal off;
    if o.viewTop, view(0, 90); else, view(-25, 60); end
    title(['SVG to 3D relief: ' base]);
    try
        exportgraphics(f, png, 'Resolution', 150, 'BackgroundColor', 'w');
    catch
    end
end

out = struct('stl', stl, 'png', png, 'X', Xg, 'Y', Yg, 'Z', Zrelief, ...
             'dim', dim, 'nTri', nTri);
fprintf('svgTo3D: %s -> %d triangles, %.1f x %.1f x %.1f mm\n', ...
    base, nTri, dim(1), dim(2), dim(3));
end
