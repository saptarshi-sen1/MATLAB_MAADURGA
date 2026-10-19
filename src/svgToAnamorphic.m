function out = svgToAnamorphic(svgFile, opts)
%SVGTOANAMORPHIC  Any 2-D SVG -> an anamorphic 3-D relief.
%
%   out = svgToAnamorphic(SVGFILE) turns ANY SVG drawing into a 3-D relief with
%   a NON-UNIFORM, height-dependent vertical placement, so the flat 2-D drawing
%   only snaps into place when the plate is viewed at one chosen elevation.
%   From every other angle it reads as sheared ridges, not the picture.
%
%   The drawing is taken from the SVG's own cubic-Bezier equations
%   (svgToEquations -> svgToRelief); the anamorphic mapping lives in
%   heightfieldToAnamorphic.
%
%   out = svgToAnamorphic(SVGFILE, OPTS) with options:
%       angle      reading-view elevation, degrees     (default 40)
%       res        raster longest side, pixels         (default 520)
%       mode       'auto'|'stroke'|'fill'|'both'       (default 'auto')
%       blur       stroke softness                     (default 0.004)
%       widthMM    plate width, mm                      (default 160)
%       depthFrac  relief depth / drawing height        (default 0.05)
%       baseMM     base plate thickness, mm             (default 1.5)
%       iters      fixed-point iterations               (default 15)
%       outdir     output directory                     (default: beside SVG)
%       outBase    base filename for outputs            (default <svg>_anamorphic)
%       render     also write a preview PNG             (default true)
%       writeSTL   also write the STL model             (default true)
%
%   OUT fields: stl, png, seen, X, Y, Z, angle, dim (mm), nTri.
%
%   Example
%       svgToAnamorphic('assets/durgamaa_svg.svg', struct('angle', 45));

if nargin < 2, opts = struct(); end
def = struct('angle', 40, 'res', 520, 'mode', 'auto', 'blur', 0.004, ...
             'widthMM', 160, 'depthFrac', 0.05, 'baseMM', 1.5, 'iters', 15, ...
             'outdir', '', 'outBase', '', 'render', true, 'writeSTL', true);
o = def;
fn = fieldnames(opts);
for k = 1:numel(fn), o.(fn{k}) = opts.(fn{k}); end

if isempty(o.outdir), o.outdir = fileparts(svgFile); end
if isempty(o.outdir), o.outdir = pwd; end
[~, base] = fileparts(svgFile);
if isempty(o.outBase), o.outBase = [base '_anamorphic']; end

A = svgToRelief(svgFile, struct('res', o.res, 'mode', o.mode, 'blur', o.blur));
H = A.Z;                                  % row 1 = bottom (Y up)

out = heightfieldToAnamorphic(H, struct( ...
        'angle', o.angle, 'widthMM', o.widthMM, 'depthFrac', o.depthFrac, ...
        'baseMM', o.baseMM, 'iters', o.iters, 'outdir', o.outdir, ...
        'outBase', o.outBase, 'render', o.render, 'writeSTL', o.writeSTL, ...
        'label', base));
end
