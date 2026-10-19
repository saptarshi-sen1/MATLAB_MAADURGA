function out = imageToAnamorphic(imgFile, opts)
%IMAGETOANAMORPHIC  Any raster image -> an anamorphic 3-D relief.
%
%   out = imageToAnamorphic(IMGFILE) builds a photographic height field (via
%   imageToRelief: broad volume + low-pass lift) and feeds it to the anamorphic
%   engine (heightfieldToAnamorphic), so the actual picture - real faces, real
%   shading - only snaps into place when the plate is viewed at one chosen
%   elevation.  Use this when a line-art trace is too thin for a face/nose.
%
%   out = imageToAnamorphic(IMGFILE, OPTS) options:
%       angle      reading-view elevation, degrees     (default 40)
%       res        longest side of the height grid      (default 520)
%       invert     raise dark pixels instead of bright  (default false)
%       blur       volume softness (fraction)           (default 0.02)
%       detail     detail radius (fraction)             (default 0.004)
%       sharp      high-pass detail weight              (default 0.50)
%       gain       tanh cap steepness                   (default 3.0)
%       feather    border fade (fraction)               (default 0.02)
%       widthMM    plate width, mm                       (default 160)
%       depthFrac  relief depth / picture height         (default 0.05)
%       baseMM     base plate thickness, mm              (default 1.5)
%       iters      fixed-point iterations                (default 15)
%       outdir     output directory                      (default: beside image)
%       outBase    base filename for outputs             (default <img>_anamorphic)
%       render     also write a preview PNG              (default true)
%       writeSTL   also write the STL model              (default true)
%
%   OUT fields: stl, png, seen, X, Y, Z, angle, dim (mm), nTri.
%
%   Example
%       imageToAnamorphic('assets/main_clean.png', struct('angle', 40));

if nargin < 2, opts = struct(); end
def = struct('angle', 40, 'res', 520, 'invert', false, 'blur', 0.02, ...
             'detail', 0.004, 'sharp', 0.50, 'gain', 3.0, 'feather', 0.02, ...
             'widthMM', 160, 'depthFrac', 0.05, 'baseMM', 1.5, 'iters', 15, ...
             'outdir', '', 'outBase', '', 'render', true, 'writeSTL', true);
o = def;
fn = fieldnames(opts);
for k = 1:numel(fn), o.(fn{k}) = opts.(fn{k}); end

if isempty(o.outdir), o.outdir = fileparts(imgFile); end
if isempty(o.outdir), o.outdir = pwd; end
[~, base] = fileparts(imgFile);
if isempty(o.outBase), o.outBase = [base '_anamorphic']; end

r = imageToRelief(imgFile, struct('res', o.res, 'invert', o.invert, ...
        'blur', o.blur, 'detail', o.detail, 'sharp', o.sharp, ...
        'gain', o.gain, 'feather', o.feather));
H = flipud(r.Z);                          % imageToRelief row 1 = top -> make it bottom

out = heightfieldToAnamorphic(H, struct( ...
        'angle', o.angle, 'widthMM', o.widthMM, 'depthFrac', o.depthFrac, ...
        'baseMM', o.baseMM, 'iters', o.iters, 'outdir', o.outdir, ...
        'outBase', o.outBase, 'render', o.render, 'writeSTL', o.writeSTL, ...
        'label', base));
end
