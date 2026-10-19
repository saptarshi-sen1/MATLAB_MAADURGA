function run_anamorphic_any_svg(svgFile, angle)
%RUN_ANAMORPHIC_ANY_SVG  Build an anamorphic relief from ANY 2-D SVG.
%
%   Turns an arbitrary SVG drawing into the 3-D "picture only at one angle"
%   relief (see svgToAnamorphic).  The SVG's own Bezier equations are used, so
%   any vector drawing works - logos, lettering, line art, icons.
%
%   run_anamorphic_any_svg                 % uses assets/durgamaa_svg.svg, 40 deg
%   run_anamorphic_any_svg('logo.svg')     % any SVG, 40 deg
%   run_anamorphic_any_svg('logo.svg', 50) % choose the reading angle
%
%   Outputs <svg>_anamorphic.{stl,png,_seen.png} in ../output.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));

if nargin < 1 || isempty(svgFile)
    svgFile = fullfile(root, 'assets', 'durgamaa_svg.svg');
end
if nargin < 2 || isempty(angle)
    angle = 40;
end
outD = fullfile(root, 'output');
if ~exist(outD, 'dir'), mkdir(outD); end

res = svgToAnamorphic(svgFile, struct('angle', angle, 'outdir', outD));
fprintf('  preview : %s\n  seen    : %s\n  model   : %s\n', ...
        res.png, res.seen, res.stl);
end
