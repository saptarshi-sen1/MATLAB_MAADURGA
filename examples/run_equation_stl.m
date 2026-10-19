function run_equation_stl
%RUN_EQUATION_STL  A 3-D relief of the Durga line art, built from its equations.
%
% The SVG is parsed into parametric cubic-Bezier "equations", those curves are
% rasterised into a line mask, the lines are raised on a thin base plate, and
% the whole thing is streamed to a watertight binary STL (plus previews).
%
% Nothing here touches the network or the reference photo - it is derived purely
% from the SVG equations.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));

svg  = fullfile(root, 'assets', 'durgamaa_svg.svg');
outD = fullfile(root, 'output');
if ~exist(outD, 'dir'), mkdir(outD); end

% 1) the equations ---------------------------------------------------------
sv   = svgToEquations(svg, struct('write', false));
segs = sv.segs;
x0 = sv.bbox(1); x1 = sv.bbox(2);
y0 = sv.bbox(3); y1 = sv.bbox(4);

% 2) raster resolution (isotropic) ----------------------------------------
R  = 700;                                  % longest side, pixels
sx = (R-1) / max(x1-x0, y1-y0);            % pixels per SVG unit
W  = round((x1-x0)*sx) + 1;
H  = round((y1-y0)*sx) + 1;

% 3) sample every cubic Bezier, burn into a mask ---------------------------
mask = false(H, W);
for i = 1:numel(segs)
    S = segs{i};
    L = norm(S(2,:)-S(1,:)) + norm(S(3,:)-S(2,:)) + norm(S(4,:)-S(3,:));
    n = max(4, ceil(L*sx)) + 1;
    t = linspace(0, 1, n).';
    P = (1-t).^3 .* S(1,:) + 3*(1-t).^2.*t .* S(2,:) + ...
        3*(1-t).*t.^2 .* S(3,:) + t.^3 .* S(4,:);
    cc = min(max(round((P(:,1)-x0)*sx)+1, 1), W);
    rr = min(max(round((P(:,2)-y0)*sx)+1, 1), H);
    mask(sub2ind([H W], rr, cc)) = true;
end

% 4) thicken the lines (base MATLAB, no Toolbox) ---------------------------
rad  = max(1, round(W*0.016));             % thicker lines (~1.6% of width)
[kx,ky] = meshgrid(-rad:rad);
disk = (kx.^2 + ky.^2) <= rad^2;
mask = conv2(double(mask), double(disk), 'same') > 0;

% 5) height map: crisp lines on a gently curved (domed) solid plate ---------
mmPerPx = 150 / W;                         % ~150 mm wide plaque
baseH   = 1.5;                             % plate thickness (mm)
lineH   = 3.0;                             % relief depth (mm) - shallow, printable
domeH   = 1.0;                             % curvature of the plate (mm)

% Crisp chamfer: the lines stay flat-topped and sharp, with a short stepped
% bevel down their shoulders so there is a defined relief edge but no blur -
% the line art keeps its crisp identity instead of melting into soft mounds.
bevelPx = max(1, round(W*0.006));           % ~4 px chamfer width
h = double(mask);                           % 1.0 on the raised line
covered = mask;
for k = 1:bevelPx
    dk = conv2(double(mask), disk2d(k), 'same') > 0;    % radius-k dilation
    ring = dk & ~covered;
    h(ring) = 1 - k/(bevelPx+1);            % linear ramp down the bevel
    covered = dk;
end

% Curved plate: a smooth dome so the whole carving is genuinely three-dimensional.
[uu, vv] = meshgrid(linspace(-1,1,W), linspace(-1,1,H));
rr   = min(1, sqrt(uu.^2 + vv.^2)/sqrt(2));
dome = domeH * cos(rr*pi/2);                % 1 at centre -> 0 at the corners
Z = baseH + dome + lineH*h;

xv = (0:W-1)*mmPerPx;
yv = (H-1:-1:0)*mmPerPx;                   % flip Y so it stands upright
[X, Y] = meshgrid(xv, yv);

% 6) write the watertight STL ---------------------------------------------
stlFile = fullfile(outD, 'durga_equations.stl');
nTri = writeDurgaSTL(X, Y, Z, stlFile);
d = dir(stlFile);
fprintf('STL: %s\n  grid %dx%d | %d triangles | %.1f MB\n', ...
    stlFile, H, W, nTri, d.bytes/1e6);

% 7) previews --------------------------------------------------------------
maskFile = fullfile(outD,'durga_equations_relief_mask.png');
try
    imwrite(uint8(255*(~mask)), maskFile);
catch
    maskFile = fullfile(outD, sprintf('durga_equations_relief_mask_%s.png', ...
        datestr(now,'HHMMSS')));
    imwrite(uint8(255*(~mask)), maskFile);
end
fprintf('Mask: %s\n', maskFile);

ds = max(1, round(max(H,W)/320));
f  = figure(1); clf(f);
set(f, 'Color','w', 'Position',[120 60 900 840]);
Zs = Z(1:ds:end,1:ds:end);
surf(X(1:ds:end,1:ds:end), Y(1:ds:end,1:ds:end), Zs, Zs, ...
     'EdgeColor','none', 'FaceColor','interp');
shading interp;
axis equal; axis tight; view(-30, 34);
camlight headlight; camlight left; lighting gouraud;
material([0.55 0.50 0.40 24 0.60]);
colormap(gca, [0.18 0.10 0.05; 0.45 0.26 0.12; 0.72 0.50 0.25; 0.95 0.80 0.55]);
set(gca, 'XColor','none','YColor','none','ZColor','none');
title('Maa Durga - deep 3-D relief from its equations');
pngFile = fullfile(outD,'durga_equations_relief.png');
try
    exportgraphics(gcf, pngFile, 'BackgroundColor','white','Resolution',150);
catch
    pngFile = fullfile(outD, sprintf('durga_equations_relief_%s.png', ...
        datestr(now,'HHMMSS')));
    exportgraphics(gcf, pngFile, 'BackgroundColor','white','Resolution',150);
    fprintf('(previous preview was open/locked - wrote a fresh copy)\n');
end
fprintf('Preview: %s\n', pngFile);
end

% ------------------------------------------------------------------------
function D = disk2d(r)
%DISK2D  Binary disk structuring element of radius r (pixels).
[gx, gy] = meshgrid(-r:r);
D = double(gx.^2 + gy.^2 <= r^2);
end
