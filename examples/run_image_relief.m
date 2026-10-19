function run_image_relief(imgFile, invert)
%RUN_IMAGE_RELIEF  Generate a 3D relief model from ANY raster image (PNG/JPEG).
%
%   run_image_relief()                    uses assets/main_clean.png (dark lines raised)
%   run_image_relief('photo.jpg')         uses the given image
%   run_image_relief('photo.jpg', false)  raises bright pixels instead of dark
%
%   One call to imageTo3D(): the bitmap's grayscale is turned into a height
%   field (broad volume + fine detail), then written as a thin, watertight STL
%   plus a gold preview - no vector source or reference mesh needed.  With the
%   default invert = true the dark strokes of a line drawing become the raised
%   relief, matching the equation-built Durga plaque.
%
%   Outputs (into ../output): <name>_3d.{png,stl}

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
outD = fullfile(root, 'output');
if ~exist(outD, 'dir'), mkdir(outD); end

if nargin < 1 || isempty(imgFile)
    imgFile = fullfile(root, 'assets', 'main_clean.png');
end
if nargin < 2 || isempty(invert)
    invert = true;                       % dark line art -> raised relief
end

res = imageTo3D(imgFile, struct('outdir', outD, 'invert', invert, 'res', 600, ...
                                'sharp', 0.60, 'sizeMM', 150, ...
                                'render', true, 'viewTop', true));

fprintf('  preview: %s\n  model  : %s\n', res.png, res.stl);
end
