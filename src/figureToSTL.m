function nTri = figureToSTL(fig, fname, opts)
%FIGURETOSTL  Export the surface shown in a MATLAB figure directly to an STL.
%
%   nTri = figureToSTL()                    % active figure -> 'figure.stl'
%   nTri = figureToSTL(fig, fname, opts)
%
% Reads the X/Y/Z data straight off the first Surface (or Patch) in the figure
% and streams it to a binary STL.  No re-modelling: whatever is plotted is what
% gets written.
%
%   opts.solid  true  -> watertight solid (front + back plate + walls) [default]
%               false -> the open surface sheet, exactly as displayed
%   opts.backZ  backing plane for the solid (default 0)
%
%   Example
%       surf(X, Y, Z);                      % any height-map surface
%       figureToSTL(gcf, 'output/durga.stl');
%
%   See also writeDurgaSTL.

if nargin < 1 || isempty(fig),   fig   = gcf;          end
if nargin < 2 || isempty(fname), fname = 'figure.stl'; end
if nargin < 3, opts = struct(); end
if ~isfield(opts,'solid') || isempty(opts.solid), opts.solid = true;  end
if ~isfield(opts,'backZ') || isempty(opts.backZ), opts.backZ = 0;     end

%% locate the axes and the plotted object -------------------------------
if isa(fig, 'matlab.graphics.axis.Axes')
    ax = fig;
else
    ax = findall(fig, 'Type', 'axes');
    if isempty(ax)
        error('figureToSTL:noAxes', 'No axes found in the figure.');
    end
    ax = ax(1);
end

s = findall(ax, 'Type', 'surface');
if isempty(s), s = findall(ax, 'Type', 'patch'); end
if isempty(s)
    error('figureToSTL:noSurface', 'No Surface or Patch found in the axes.');
end
s = s(1);

%% pull the geometry, normalising vector / empty forms to matrices -------
X = s.XData;  Y = s.YData;  Z = s.ZData;
if ~isempty(Z) && ~ismatrix(Z), Z = squeeze(Z); end
[nR, nC] = size(Z);

if isempty(X), X = 1:nC; end
if isempty(Y), Y = 1:nR; end
if isvector(X) && numel(X) == nC, X = repmat(X(:).', nR, 1); end
if isvector(Y) && numel(Y) == nR, Y = repmat(Y(:), 1, nC); end
if ~isequal(size(X), [nR nC]), X = repmat(1:nC, nR, 1); end
if ~isequal(size(Y), [nR nC]), Y = repmat((1:nR).', 1, nC); end

%% write ----------------------------------------------------------------
if opts.solid
    Z = Z - opts.backZ;                        % back plate lands on 0
    nTri = writeDurgaSTL(X, Y, Z, fname);
else
    nTri = writeOpenSurface(X, Y, Z, fname);
end

d = dir(fname);
fprintf('figureToSTL: %s  (%d tris, %.2f MB)\n', fname, nTri, d.bytes/1e6);
end

% ------------------------------------------------------------------------
function nTri = writeOpenSurface(X, Y, Z, fname)
%WRITEOPENSURFACE  Single-sided triangle sheet (front faces only).
nTri = 2 * (size(Z,1)-1) * (size(Z,2)-1);
fid = fopen(fname, 'wb');
if fid < 0, error('figureToSTL:cannotOpen', 'Cannot open %s.', fname); end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, zeros(1,80,'uint8'), 'uint8');
fwrite(fid, uint32(nTri), 'uint32');

nR = size(Z,1);  nC = size(Z,2);
for r = 1:nR-1
    j = 1:nC-1;
    Pa = [X(r,j);   Y(r,j);   Z(r,j)  ];
    Pb = [X(r,j+1); Y(r,j+1); Z(r,j+1)];
    Pc = [X(r+1,j); Y(r+1,j); Z(r+1,j)];
    Pd = [X(r+1,j+1); Y(r+1,j+1); Z(r+1,j+1)];
    writeTris(fid, Pa, Pb, Pd);
    writeTris(fid, Pa, Pd, Pc);
end
end

% ------------------------------------------------------------------------
function writeTris(fid, p1, p2, p3)
n  = cross(p2 - p1, p3 - p1);
nn = sqrt(sum(n.^2, 1));  nn(nn < eps) = 1;
n  = n ./ nn;
M  = [n; p1; p2; p3];
body = reshape(typecast(single(M(:)), 'uint8'), 48, []);
buf  = zeros(50, size(M,2), 'uint8');
buf(1:48, :) = body;
fwrite(fid, buf(:), 'uint8');
end
