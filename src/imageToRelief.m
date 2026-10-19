function out = imageToRelief(imgFile, opts)
%IMAGETORELIEF  Turn any raster image (PNG/JPEG) into a smooth 3-D relief.
%
%   OUT = IMAGETORELIEF(IMGFILE) reads a bitmap (PNG, JPEG, TIFF, BMP, ...),
%   converts it to grayscale and treats that luminance as a height map: a
%   blurred copy supplies the broad volume and a high-pass copy supplies the
%   fine detail.  The combined field is softly capped (tanh) and feathered at
%   the border, so it can be written to STL as a shallow embossed plaque - no
%   vector source required.
%
%   OUT = IMAGETORELIEF(IMG, OPTS) with fields:
%       res       longest side of the height grid, px       (default 600)
%       invert    raise dark pixels instead of bright ones  (default false)
%       blur      volume softness, fraction of long side     (default 0.02)
%       detail    detail radius, fraction of long side       (default 0.004)
%       volume    weight of the blurred volume               (default 1.00)
%       sharp     weight of the high-pass detail             (default 0.50)
%       gain      steepness of the tanh cap                  (default 3.0)
%       feather   border fade, fraction of long side         (default 0.06)
%
%   OUT fields: X, Y, Z (ny-by-nx grids), mask, res = [ny nx], imgGray.

if nargin < 2, opts = struct(); end
def = struct('res', 600, 'invert', false, 'blur', 0.02, 'detail', 0.004, ...
             'volume', 1.00, 'sharp', 0.50, 'gain', 3.0, 'feather', 0.06);
o = def;
fn = fieldnames(opts);
for k = 1:numel(fn), o.(fn{k}) = opts.(fn{k}); end

% --------------------------------------------------------------- read image
g = imread(imgFile);
if size(g, 3) > 1, g = rgb2gray(g); end
if ~isa(g, 'double'), g = im2double(g); end
if o.invert, g = 1 - g; end

% --------------------------------------------------------------- grid setup
[ny0, nx0] = size(g);
if nx0 >= ny0, nx = o.res; ny = max(8, round(o.res*ny0/nx0));
else,          ny = o.res; nx = max(8, round(o.res*nx0/ny0)); end
g = imresize(g, [ny nx]);

% --------------------------------------------------------- height synthesis
sigV   = max(0.5, o.blur   * max(nx, ny));
sigD   = max(0.5, o.detail * max(nx, ny));
volume = imgaussfilt(g, sigV);                 % broad 3-D form
detail = g - imgaussfilt(g, sigD);             % crisp feature lines
h = o.volume*volume + o.sharp*detail;
h = h - mean(h(:));
h = tanh(o.gain * h / max(std(h(:)), eps));    % soft cap: no spikes
h = (h + 1) / 2;

% ----------------------------------------------------- feather the border
fpx  = max(1, round(o.feather * max(nx, ny)));
ramp = (0:fpx).' / fpx;                        % 0 -> 1 across the fade
fx   = ones(nx, 1);
fy   = ones(ny, 1);
fx(1:fpx)        = ramp(1:end-1);
fx(nx-fpx+1:end) = flipud(ramp(1:end-1));
fy(1:fpx)        = ramp(1:end-1);
fy(ny-fpx+1:end) = flipud(ramp(1:end-1));
h = h .* (fy * fx.');

h = h - min(h(:));
mx = max(h(:));
if mx > 0, h = h / mx; end
Z = h;

% X, Y in pixel units keep the image aspect; Y is flipped so row 1 sits on top
xv = 0:nx-1;
yv = ny-1:-1:0;
[Xg, Yg] = meshgrid(xv, yv);

out = struct('X', Xg, 'Y', Yg, 'Z', Z, 'mask', Z > 1e-3, ...
             'res', [ny nx], 'imgGray', g);
fprintf('imageToRelief: %dx%d image -> %dx%d grid\n', ny0, nx0, ny, nx);
end
