function out = svgToRelief(svgFile, opts)
%SVGTORELIEF  Turn an SVG drawing into a smooth 3-D relief height field.
%
%   OUT = SVGTORELIEF(SVGFILE) parses any SVG (via svgToEquations), rasterises
%   its strokes (and, when present, its filled paths), and builds a smooth
%   height field Z(x,y) by Gaussian-blurring those rasters.  The result can be
%   drawn with surf() or written to STL, so ANY line drawing becomes a 3-D
%   embossed plaque - no distance transforms, no blocky extrusion.
%
%   OUT = SVGTORELIEF(SVG, OPTS) uses a struct of options:
%       res           longest side of the grid in pixels       (default 600)
%       mode          'auto'|'stroke'|'fill'|'both'            (default 'auto')
%       strokeWidth   stroke thickness, fraction of long side   (default 0.004)
%       blur          Gaussian softness, fraction of long side  (default 0.006)
%       fillHeight    peak height of filled shapes              (default 0.60)
%       strokeHeight  peak height of strokes                    (default 1.00)
%
%   OUT fields: X, Y, Z (ny-by-nx grids), mask, bbox, res = [ny nx],
%   fillCount, seg (the parsed svgToEquations result).

if nargin < 2, opts = struct(); end
def = struct('res', 600, 'mode', 'auto', 'strokeWidth', 0.004, ...
             'blur', 0.006, 'fillHeight', 0.60, 'strokeHeight', 1.00);
o = def;
fn = fieldnames(opts);
for k = 1:numel(fn), o.(fn{k}) = opts.(fn{k}); end

% --------------------------------------------------------------- parse SVG
sv    = svgToEquations(svgFile, struct('write', false));
segs  = sv.segs;
pSegs = sv.pathSegs;
xmin = sv.bbox(1);  xmax = sv.bbox(2);
ymin = sv.bbox(3);  ymax = sv.bbox(4);
W = xmax - xmin;    H = ymax - ymin;

% ------------------------------------------------------------- grid setup
res = o.res;
if W >= H, nx = res; ny = round(res*H/W); else, ny = res; nx = round(res*W/H); end
nx = max(nx, 8);  ny = max(ny, 8);

% map drawing points -> pixel (row 1 = bottom, so the drawing stays upright)
colOf = @(px) min(nx, max(1, round((px - xmin)/W*(nx-1)) + 1));
rowOf = @(py) min(ny, max(1, round((ymax - py)/H*(ny-1)) + 1));

% ---------------------------------------------------------------- strokes
strokeMask = false(ny, nx);
for i = 1:numel(segs)
    P = evalCubic(segs{i}, 24);
    idx = sub2ind([ny nx], rowOf(P(:,2)), colOf(P(:,1)));
    strokeMask(idx) = true;
end
wpx = round(o.strokeWidth * max(nx, ny));
if wpx > 0, strokeMask = imdilate(strokeMask, strel('disk', wpx)); end

% -------------------------------------------------------- filled (closed) shapes
fillMask = false(ny, nx);
fillCount = 0;
tol = 1e-6 * max(W, H);
for i = 1:numel(pSegs)
    pi = pSegs{i};
    if isempty(pi), continue; end
    P = [];
    for k = 1:numel(pi), P = [P; evalCubic(pi{k}, 24)]; end %#ok<AGROW>
    if norm(P(1,:) - P(end,:)) < tol
        fillCount = fillCount + 1;
        fillMask = fillMask | poly2mask(colOf(P(:,1)), rowOf(P(:,2)), ny, nx);
    end
end

switch lower(o.mode)
    case 'stroke', useFill = false; useStroke = true;
    case 'fill',   useFill = true;  useStroke = false;
    case 'both',   useFill = true;  useStroke = true;
    otherwise,     useFill = (fillCount > 0); useStroke = true;   % auto
end

% ------------------------------------------------------- height synthesis
sig = max(0.5, o.blur * max(nx, ny));
Z = zeros(ny, nx);
if useFill,   Z = Z + o.fillHeight   * imgaussfilt(double(fillMask),   sig); end
if useStroke, Z = Z + o.strokeHeight * imgaussfilt(double(strokeMask), sig); end
mx = max(Z(:));
if mx > 0, Z = Z / mx; end

xv = linspace(xmin, xmax, nx);
yv = linspace(ymin, ymax, ny);
[Xg, Yg] = meshgrid(xv, yv);

out = struct('X', Xg, 'Y', Yg, 'Z', Z, 'mask', Z > 1e-3, ...
             'bbox', sv.bbox, 'res', [ny nx], 'fillCount', fillCount, 'seg', sv);
fprintf('svgToRelief: %d strokes, %d filled shapes -> grid %dx%d\n', ...
    numel(segs), fillCount, ny, nx);
end

% ============================ local functions ============================
function P = evalCubic(seg, n)
t = linspace(0, 1, n).';
P = (1-t).^3 .* seg(1,:) + 3*(1-t).^2 .* t .* seg(2,:) + ...
    3*(1-t) .* t.^2 .* seg(3,:) + t.^3 .* seg(4,:);
end
