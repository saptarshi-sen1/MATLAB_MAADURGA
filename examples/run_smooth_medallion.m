function run_smooth_medallion
%RUN_SMOOTH_MEDALLION  Smooth golden Maa Durga medallion from explicit equations.
%
%   Pure surf()/equation approach - NO distance transforms, NO extrusion.
%   One smooth height field Z(x,y) built from closed-form shapes. Every part is
%   rounded and gently sized, and a soft tanh CAP guarantees no local spike can
%   rise far above the rest of the relief.
%
%   The STL solid is written first (memory-lean), then the lit gold figure is
%   created and exported, so the renderer never competes with the mesh writer.

% ------------------------------------------------------------------ setup
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root,'src'));
outD = fullfile(root,'output');
if ~exist(outD,'dir'), mkdir(outD); end

% 1) 3-D GRID
[U, V] = meshgrid(linspace(-3, 3, 300), linspace(-3, 3, 300));

% smooth normalised Gaussian bump centred at (x0,y0)
g = @(x0, y0, sx, sy) exp(-(((U-x0)/sx).^2 + ((V-y0)/sy).^2));

% 2) FACE BASE - elliptic Gaussian mound
Z_face = 1.1 * exp(-(U.^2/2 + V.^2/3));

% 3) CROWN - ROUNDED mukut dome (no sharp cone apex) with a soft tier ring
[~, Rho] = cart2pol(U, V - 1.75);
Z_crown = 0.80*exp(-(Rho/0.85).^2) ...            % rounded crown dome
        + 0.30*exp(-((Rho-0.55)/0.12).^2);        % soft tier ring
wR = 0.5*(1 - tanh((Rho - 1.25)/0.15));           % smooth footprint clip
wH = 0.5*(1 + tanh((Z_face - 0.40)/0.10));        % only where the head is tall
Z_crown = Z_crown .* wR .* wH;

% crown jewels - small, soft peaks (never taller than the dome)
Z_jewels = 0.10*g( 0.00, 1.75, 0.16, 0.16) ...
         + 0.07*g(-0.50, 1.60, 0.12, 0.12) + 0.07*g(0.50, 1.60, 0.12, 0.12);
Z_crown = Z_crown + Z_jewels .* wH;

% 4) FEATURES - broad, low Gaussian bumps (no needles)
Z_nose   = 0.55*g(0,  -0.10, 0.17, 0.45) + 0.35*g(0,  -0.60, 0.17, 0.17);
Z_eyes   = 0.15*(g(-0.70, 0.15, 0.16, 0.12) + g(0.70, 0.15, 0.16, 0.12)) ...
         - 0.22*(g(-0.70, 0.15, 0.40, 0.20) + g(0.70, 0.15, 0.40, 0.20));
Z_brows  = 0.20*(g(-0.70, 0.45, 0.46, 0.10) + g(0.70, 0.45, 0.46, 0.10));
Z_lips   = 0.22*g(0, -0.95, 0.46, 0.11) + 0.20*g(0, -1.12, 0.42, 0.12);
Z_chin   = 0.22*g(0, -1.55, 0.42, 0.30);
Z_cheeks = 0.20*(g(-1.05, -0.45, 0.55, 0.55) + g(1.05, -0.45, 0.55, 0.55));
Z_bindi  = 0.18*g(0, 0.80, 0.12, 0.15);

% nose ring (nath) - a thin but gentle Gaussian ring near the nose
Rn       = sqrt((U - 0.30).^2 + (V + 0.55).^2);
Z_nath   = 0.14*exp(-((Rn - 0.16)/0.05).^2);

% earrings - modest rounded peaks at the sides
Z_ear    = 0.30*(g(-1.35, -0.35, 0.17, 0.19) + g(1.35, -0.35, 0.17, 0.19));

% 5) COMBINE smoothly
Z_total = Z_face + Z_crown + Z_nose + Z_eyes + Z_brows + ...
          Z_lips + Z_chin + Z_cheeks + Z_bindi + Z_nath + Z_ear;

% 5b) SOFT CAP - squash any leftover high spot so the relief stays even.
%     (tanh is smooth, so it flattens peaks without creating ledges.)
Zcap    = 1.1;
Z_total = Zcap * tanh(Z_total / Zcap);

% ------------------------------------------------------ export thin STL first
Ztotal = Z_total;                             % keep a copy for the figure
clear Z_total Z_face Z_crown Z_nose Z_eyes Z_brows Z_lips Z_chin ...
      Z_cheeks Z_bindi Z_nath Z_ear Z_jewels wR wH Rn
stl = fullfile(outD,'durga_smooth_medallion.stl');
nTri = reliefWriteSTL(U, V, Ztotal, stl, struct('sizeMM', 120));

% ------------------------------------------------------------ render medallion
figure('Color','w', 'Name','Maa Durga - gold medallion');
surf(U, V, Ztotal, 'EdgeColor', 'none', 'FaceColor', 'interp');

% gold tone colormap
goldMap = [linspace(0.30,1.00,256)', linspace(0.12,0.90,256)', linspace(0.02,0.45,256)'];
colormap(goldMap);

shading interp;
lighting gouraud;
camlight('headlight');       % frontal fill
camlight('left');            % key
camlight('right');           % rim
material([0.35 0.65 0.85 30 0.60]);   % ambient/diffuse/specular/shininess/spec-color

axis off;
daspect([1 1 0.3]);          % bas-relief depth
view(-20, 60);               % isometric-ish
zlim([0 6]);
title('Maa Durga - gold medallion');

% export a PNG preview
png = fullfile(outD,'durga_smooth_medallion.png');
try
    exportgraphics(gcf, png, 'Resolution', 150, 'BackgroundColor', 'w');
catch
end

% report height stats so spikes are easy to spot
[zmax, imax] = max(Ztotal(:));
[r, c] = ind2sub(size(Ztotal), imax);
fprintf('gold medallion: grid %dx%d | STL %d triangles\n', ...
    size(Ztotal,1), size(Ztotal,2), nTri);
fprintf('  height range: min %.2f  max %.2f at (x=%.2f, y=%.2f)\n', ...
    min(Ztotal(:)), zmax, U(r,c), V(r,c));
fprintf('  preview: %s\n  model  : %s\n', png, stl);
end
