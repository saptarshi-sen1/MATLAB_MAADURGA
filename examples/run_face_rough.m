function run_face_rough
%RUN_FACE_ROUGH  A deliberately less-"polished" take on the Maa Durga face relief.
%
%   Same face-from-luminance idea as Durga_Face_3D, but it keeps the fine image
%   detail (only a light blur), adds a subtle carved-grain texture and uses a
%   matte finish, so it reads like a worked relief rather than a glossy render.
%
%   Writes ../output/durga_face_rough.{png,stl}.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
outD = fullfile(root, 'output');
if ~exist(outD, 'dir'), mkdir(outD); end

I = imread(fullfile(root, 'assets', 'main_clean.png'));
if size(I, 3) == 1, I = repmat(I, 1, 1, 3); end
I  = im2double(I);
L0 = 0.2989*I(:,:,1) + 0.5870*I(:,:,2) + 0.1140*I(:,:,3);

n = 380;
L0 = imresize(L0, [n NaN]);
[nR, nC] = size(L0);
u = ((0:nC-1)/(nC-1) - 0.5)*2;
v = ((0:nR-1)/(nR-1) - 0.5)*2;
[U, V] = meshgrid(u, v);
R = min(1, sqrt(U.^2 + V.^2));

% --- rough take: light blur keeps detail, add fine carved grain ------------
dome = 0.7*cos(R*pi/2);
Lr = imgaussfilt(L0, 0.45);
Lr = (Lr - min(Lr(:))) / max(eps, max(Lr(:)) - min(Lr(:)));
rng(11);
g = imgaussfilt(randn(nR, nC), 1.0);
g = g / max(abs(g(:)));
Zface = dome + 6.0*(Lr - 0.5) + 0.8*g;
Zface = Zface - min(Zface(:));
Z = 1.5 + Zface;

widthMM = 160;
sx = widthMM / (nC - 1);
xv = (0:nC-1)*sx;
yv = (nR-1:-1:0)*sx;
[X, Y] = meshgrid(xv, yv);

stl  = fullfile(outD, 'durga_face_rough.stl');
nTri = writeDurgaSTL(X, Y, Z, stl);
d    = dir(stl);
fprintf('STL %s  %d triangles  %.1f MB\n', stl, nTri, d.bytes/1e6);

% --- preview: current (polished) vs rough ----------------------------------
Lp = imgaussfilt(L0, 1.0);
Lp = (Lp - min(Lp(:))) / max(eps, max(Lp(:)) - min(Lp(:)));
Zp = 1.5 + 1.0*cos(R*pi/2) + 4.0*(Lp - 0.5);
Zp = Zp - min(Zp(:));

f = figure('Color', 'w', 'Position', [70 40 1280 760]);
subplot(1, 2, 1);
surf(X, Y, Zp, repmat(Lp, 1, 1, 3), 'EdgeColor','none', 'FaceColor','texturemap');
shading interp; axis equal tight off; view(-28, 20);
camlight headlight; lighting gouraud; material dull;
title('current (too polished)');
subplot(1, 2, 2);
surf(X, Y, Z, repmat(Lr, 1, 1, 3), 'EdgeColor','none', 'FaceColor','texturemap');
shading interp; axis equal tight off; view(-28, 20);
camlight headlight; lighting gouraud; material dull;
title('rough / carved');
png = fullfile(outD, 'durga_face_rough.png');
exportgraphics(f, png, 'BackgroundColor', 'white', 'Resolution', 150);
fprintf('preview %s\n', png);
end
