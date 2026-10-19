%RUN_EQUATIONS  SVG -> parametric equations (.txt), Desmos page (.html), preview (.png).
% This is the black-and-white line-art pipeline. Run from anywhere.

here   = fileparts(mfilename('fullpath'));
root   = fileparts(here);
addpath(fullfile(root, 'src'));

svg    = fullfile(root, 'assets', 'durgamaa_svg.svg');
outDir = fullfile(root, 'output');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Parse the SVG and emit:
%   durgamaa_svg_equations.txt   one LaTeX parametric equation per line
%   durgamaa_svg_equations.html  self-contained Desmos graph
%   durgamaa_svg_equations.png   MATLAB monochrome line-art render
svgToEquations(svg, struct('outBase', fullfile(outDir, 'durgamaa_svg_equations')));

fprintf('Done. See %s\n', outDir);
