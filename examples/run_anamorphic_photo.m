function run_anamorphic_photo(imgFile, angle)
%RUN_ANAMORPHIC_PHOTO  Durga as an anamorphic relief built from the PHOTO.
%
%   Uses the photographic relief (imageToRelief of main_clean.png) instead of
%   the line-art SVG, so the real face and nose survive the anamorphic
%   re-sampling.  The picture resolves only at the chosen viewing angle.
%
%   run_anamorphic_photo                 % assets/main_clean.png, 40 deg
%   run_anamorphic_photo('img.png', 45)  % any raster, any angle
%
%   Outputs output/durga_anamorphic_photo.{stl,png,_seen.png}

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));

if nargin < 1 || isempty(imgFile)
    imgFile = fullfile(root, 'assets', 'main_clean.png');
end
if nargin < 2 || isempty(angle)
    angle = 40;
end
outD = fullfile(root, 'output');
if ~exist(outD, 'dir'), mkdir(outD); end

res = imageToAnamorphic(imgFile, struct('angle', angle, ...
        'depthFrac', 0.038, 'sharp', 1.8, 'blur', 0.008, 'detail', 0.0025, ...
        'gain', 2.0, 'outdir', outD, 'outBase', 'durga_anamorphic_photo'));
fprintf('  preview : %s\n  seen    : %s\n  model   : %s\n', ...
        res.png, res.seen, res.stl);
end
