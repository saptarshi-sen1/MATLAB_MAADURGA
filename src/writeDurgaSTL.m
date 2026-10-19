function nTri = writeDurgaSTL(X, Y, Z, fname)
%WRITEDURGASTL  Stream a height-map grid to a watertight binary STL solid.
%
%   nTri = writeDurgaSTL(X, Y, Z, fname)
%
% X, Y, Z are same-size matrices (the front surface).  The solid is built from
%   * the front surface  Z,
%   * a flat back plate at 0,
%   * four vertical side walls joining the two,
% so the mesh is 100% closed (watertight) and safe to 3-D print.
%
% Unlike triangulation + stlwrite, this writes the binary STL row-by-row with a
% small fixed-size buffer, so peak memory stays tiny and does not exhaust the
% MATLAB/Java address space on large grids.
%
% Basic idea (t = triangles of one grid cell):
%   front triangles : (a,b,d) and (a,d,c)
%   back  triangles : (a',d',b') and (a',c',d')

nR = size(Z,1);  nC = size(Z,2);
nCell = (nR-1)*(nC-1);
nSide = 2 * (2*(nR-1) + 2*(nC-1));           % 2 triangles per border-edge
nTri  = 4*nCell + nSide;                     % 2 front + 2 back per cell

fid = fopen(fname, 'wb');
if fid < 0
    error('writeDurgaSTL:cannotOpen', 'Cannot open %s for writing.', fname);
end
cleanup = onCleanup(@() fclose(fid));        % close the file on any exit

fwrite(fid, zeros(1,80,'uint8'), 'uint8');   % 80-byte header (unused)
fwrite(fid, uint32(nTri), 'uint32');         % triangle count

for r = 1:nR-1
    j  = 1:nC-1;
    Pa = [X(r,j);   Y(r,j);   Z(r,j)  ];
    Pb = [X(r,j+1); Y(r,j+1); Z(r,j+1)];
    Pc = [X(r+1,j); Y(r+1,j); Z(r+1,j)];
    Pd = [X(r+1,j+1); Y(r+1,j+1); Z(r+1,j+1)];

    writeTris(fid, Pa, Pb, Pd);              % front  (a,b,d)
    writeTris(fid, Pa, Pd, Pc);              % front  (a,d,c)

    Pa(3,:) = 0;  Pb(3,:) = 0;  Pc(3,:) = 0;  Pd(3,:) = 0;
    writeTris(fid, Pa, Pd, Pb);              % back   (a',d',b')
    writeTris(fid, Pa, Pc, Pd);              % back   (a',c',d')
end

loop = [sub2ind([nR nC], ones(1,nC), 1:nC), ...
        sub2ind([nR nC], 2:nR, nC*ones(1,nR-1)), ...
        sub2ind([nR nC], nR*ones(1,nC-1), (nC-1):-1:1), ...
        sub2ind([nR nC], (nR-1):-1:2, ones(1,nR-2))];
Vf = [X(:) Y(:) Z(:)];
for i = 1:numel(loop)
    p = loop(i);  q = loop(mod(i, numel(loop)) + 1);
    P  = Vf(p,:).';   Q  = Vf(q,:).';
    Pb = [P(1); P(2); 0];   Qb = [Q(1); Q(2); 0];
    writeTris(fid, P,  Qb, Q);               % side wall (p, q', q)
    writeTris(fid, P,  Pb, Qb);              % side wall (p, p', q')
end
end

% ------------------------------------------------------------------------
function writeTris(fid, p1, p2, p3)
%WRITETRIS  Append k triangles (each p is 3-by-k) as 50-byte STL records.
n  = cross(p2 - p1, p3 - p1);                % 3-by-k face normals
nn = sqrt(sum(n.^2, 1));  nn(nn < eps) = 1;
n  = n ./ nn;
M  = [n; p1; p2; p3];                        % 12-by-k, columns are contiguous
body = reshape(typecast(single(M(:)), 'uint8'), 48, []);
buf  = zeros(50, size(M,2), 'uint8');        % 48 payload + 2 attribute bytes
buf(1:48, :) = body;
fwrite(fid, buf(:), 'uint8');
end
