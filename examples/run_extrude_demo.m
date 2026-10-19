%RUN_EXTRUDE_DEMO  Build a small height map and stream it to a binary STL.
% Run this file from anywhere; it resolves its own paths.

here   = fileparts(mfilename('fullpath'));
root   = fileparts(here);
addpath(fullfile(root, 'src'));

outDir = fullfile(root, 'output');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% A smooth "bump" surface, 200 x 200 grid
[X, Y] = meshgrid(linspace(-1, 1, 200));
Z = exp(-4*(X.^2 + Y.^2)) + 0.15*sin(6*X).*cos(6*Y);

outFile = fullfile(outDir, 'demo.stl');
nTri = writeDurgaSTL(X, Y, Z, outFile);

fprintf('Wrote %s\n  %d triangles (watertight).\n', outFile, nTri);
