function out = heightfieldToAnamorphic(H, opts)
%HEIGHTFIELDTOANAMORPHIC  Anamorphic relief from a height field.
%
%   out = heightfieldToAnamorphic(H) turns a height field H (ny-by-nx, values
%   in [0,1], ROW 1 = BOTTOM of the picture) into a 3-D plate with a
%   NON-UNIFORM, height-dependent vertical placement, so the flat picture only
%   snaps into place when the plate is viewed at one chosen elevation:
%
%       screen row  V(Y) = Y*sin(el) + Z(Y)*cos(el)
%       height      Z(Y) = amp * H(V)                    (fixed point)
%
%   X, Y and Z share one mm scale so the oblique view reconstructs the picture.
%   This is the shared engine behind svgToAnamorphic and imageToAnamorphic.
%
%   opts:
%       angle      reading-view elevation, degrees     (default 40)
%       widthMM    plate width, mm                      (default 160)
%       depthFrac  relief depth / picture height        (default 0.05)
%       baseMM     base plate thickness, mm             (default 1.5)
%       iters      fixed-point iterations               (default 15)
%       outdir     output directory                     (default pwd)
%       outBase    base filename for outputs            (default 'anamorphic')
%       render     also write a preview PNG             (default true)
%       label      name used in the printout
%
%   OUT fields: stl, png, seen, X, Y, Z, angle, dim (mm), nTri.

if nargin < 2, opts = struct(); end
def = struct('angle', 40, 'widthMM', 160, 'depthFrac', 0.05, 'baseMM', 1.5, ...
             'iters', 15, 'outdir', '', 'outBase', 'anamorphic', ...
             'render', true, 'writeSTL', true, 'label', 'anamorphic');
o = def;
fn = fieldnames(opts);
for k = 1:numel(fn), o.(fn{k}) = opts.(fn{k}); end
if isempty(o.outdir), o.outdir = pwd; end
if ~exist(o.outdir, 'dir'), mkdir(o.outdir); end

[ny, nx] = size(H);
if max(H(:)) > 0, H = H / max(H(:)); end
el = o.angle;  S = sind(el);  C = cosd(el);

% --- anamorphic mapping (fixed point, art-row units) -----------------------
nY = round((ny - 1) / S) + 1;             % vertical stretch 1/sin(el)
[Yg, Cg] = ndgrid(0:nY-1, 0:nx-1);
amp = o.depthFrac * ny;
V = Yg * S;
h = zeros(size(V));
for it = 1:o.iters
    r  = min(max(V, 0), ny-1) + 1;
    Hv = interp2(1:nx, 1:ny, H, Cg+1, r, 'linear');
    Hv(~isfinite(Hv)) = 0;
    h  = amp * Hv;
    V  = Yg * S + C * h;                  % height-dependent (non-uniform) shift
end

% --- to mm (one uniform scale for x, y and z) -----------------------------
mm = o.widthMM / (nx - 1);
X  = Cg * mm;
Y  = Yg * mm;
Z  = o.baseMM + h * mm;
dim = [(nx-1)*mm, (nY-1)*mm, max(Z(:))];

% --- STL -------------------------------------------------------------------
stl  = fullfile(o.outdir, [o.outBase '.stl']);
if o.writeSTL
    nTri = writeDurgaSTL(X, Y, Z, stl);
else
    nTri = 0;
end

% --- numeric "what the camera sees" at the reading angle -------------------
rec = zeros(nx, ny);
for j = 1:nx
    Vcol = Yg(:,1)*S + C*h(:,j);
    Hcol = interp1(1:ny, H(:,j), min(max(Vcol+1, 1), ny), 'linear');
    [Vu, ia] = unique(Vcol);
    Vs = linspace(Vu(1), Vu(end), ny).';
    rec(j,:) = interp1(Vu, Hcol(ia), Vs, 'linear', 0);
end
seen = fullfile(o.outdir, [o.outBase '_seen.png']);
imwrite(uint8(255*(1 - flipud(rec.'))), seen);   % upright: row 1 = bottom

% --- preview: reading angle vs. top ----------------------------------------
png = fullfile(o.outdir, [o.outBase '.png']);
if o.render
    % Colour by HEIGHT with no lighting: lighting the fine relief detail
    % produces speckle that hides the picture, so the unlit height map is
    % what actually shows the reconstruction.
    zr = [min(Z(:)) max(Z(:))];
    f = figure('Color','w', 'Position',[60 30 1300 760], 'Visible','off');
    ax1 = subplot(1,2,1); %#ok<NASGU>
    surf(X, Y, Z, Z, 'EdgeColor','none');
    colormap(ax1, gray); caxis(ax1, zr); shading interp;
    camproj('orthographic'); view(0, el); lighting none; axis equal tight off;
    title(sprintf('viewed at %g deg  ->  the picture appears', el));
    ax2 = subplot(1,2,2); %#ok<NASGU>
    surf(X, Y, Z, Z, 'EdgeColor','none');
    colormap(ax2, gray); caxis(ax2, zr); shading interp;
    camproj('orthographic'); view(0, 90); lighting none; axis equal tight off;
    title('top view  ->  sheared / distorted');
    try
        exportgraphics(f, png, 'BackgroundColor','white', 'Resolution',140);
    catch
    end
    close(f);
end

out = struct('stl', stl, 'png', png, 'seen', seen, ...
             'X', X, 'Y', Y, 'Z', Z, 'angle', el, 'dim', dim, 'nTri', nTri);
fprintf('heightfieldToAnamorphic [%s]: angle %g deg | plate %.0f x %.0f mm | %d tris\n', ...
        o.label, el, dim(1), dim(2), nTri);
end
