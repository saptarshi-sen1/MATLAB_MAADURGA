function run_svg_relief(svgFile)
%RUN_SVG_RELIEF  Generate a 3D relief model from ANY SVG image.
%
%   run_svg_relief()            uses assets/durgamaa_svg.svg
%   run_svg_relief('file.svg')  uses the given SVG
%
%   One call to svgTo3D(): the SVG is parsed into its Bezier curves, those are
%   rasterised into fills and crisp strokes, smoothed into a height field and
%   written out as a thin, watertight STL plus a gold preview - no reference
%   mesh or photo needed.  Drop in any SVG (logo, line drawing, icon) to get a
%   printable 3-D relief.
%
%   Outputs (into ../output): <name>_3d.{png,stl}

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
outD = fullfile(root, 'output');
if ~exist(outD, 'dir'), mkdir(outD); end

if nargin < 1 || isempty(svgFile)
    svgFile = fullfile(root, 'assets', 'durgamaa_svg.svg');
end

res = svgTo3D(svgFile, struct('outdir', outD, 'res', 460, 'mode', 'auto', ...
                              'sizeMM', 150, 'render', true, 'viewTop', true));

fprintf('  preview: %s\n  model  : %s\n', res.png, res.stl);
end
