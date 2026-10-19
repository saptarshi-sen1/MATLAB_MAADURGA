function run_anamorphic
%RUN_ANAMORPHIC  Maa Durga as an anamorphic relief (picture only at one angle).
%
%   The Durga drawing (its SVG Bezier equations) is placed on the plate with a
%   NON-UNIFORM, height-dependent vertical shift, so it only resolves into the
%   flat 2-D drawing when viewed at the chosen elevation.  From any other angle
%   the surface reads as sheared ridges.
%
%   General entry point: see svgToAnamorphic (works for ANY SVG).
%   A kept copy of the first working version (30 deg) lives in
%   output/kept/durga_anamorphic_el30.{stl,png}.
%
%   Writes ../output/durga_anamorphic.{png,stl,_seen.png}.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
outD = fullfile(root, 'output');
if ~exist(outD, 'dir'), mkdir(outD); end

svg = fullfile(root, 'assets', 'durgamaa_svg.svg');
res = svgToAnamorphic(svg, struct('angle', 40, 'outdir', outD, ...
                                  'outBase', 'durga_anamorphic'));
fprintf('  preview : %s\n  seen    : %s\n  model   : %s\n', ...
        res.png, res.seen, res.stl);
end
