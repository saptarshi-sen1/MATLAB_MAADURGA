function out = svgToEquations(svgFile, opts)
%SVGTOEQUATIONS  Convert an SVG into graphable parametric equations.
%
%   MATLAB port of the ImageToEquations approach
%   (github.com/vigneshsaravanakumar404/ImageToEquations).  The original
%   reads an SVG, walks its path data and rewrites every segment as a
%   parametric equation that can be graphed on Desmos.
%
%   This port parses the SVG path grammar (M/L/H/V/C/S/Q/T/A/Z, absolute and
%   relative), converts every segment to cubic Beziers, applies the enclosing
%   group transform, and emits the equations as a plain-text list and as a
%   self-contained Desmos HTML page.
%
%   OUT = SVGTOEQUATIONS() parses durgamaa_svg.svg with default options.
%   OUT = SVGTOEQUATIONS(FILE) parses the given SVG file.
%   OUT = SVGTOEQUATIONS(FILE, OPTS) uses a struct of options.
%
%   OPTS fields (all optional):
%       yFlip    flip y so the drawing is upright in Desmos  (default true)
%       color    Desmos line colour name                     (default 'BLACK')
%       outBase  base name for the output files (default '<svg>_equations')
%       arcN     samples used to flatten an elliptical arc   (default 24)
%       render   also write the MATLAB .png preview          (default true)
%       write    write the output files at all               (default true)
%
%   OUT fields: nPath, nSeg, eqs, bbox and the output file paths.
%
%   Outputs written next to the SVG:
%       <base>.txt    - one equation per line (LaTeX)
%       <base>.html   - Desmos graph of every equation
%       <base>.png    - MATLAB preview render of the parsed drawing
%
%   Example
%       svgToEquations('durgamaa_svg.svg');
%
%   See also imageToEquations.

%% ------------------------------ options ---------------------------------
if nargin < 1 || isempty(svgFile)
    svgFile = 'durgamaa_svg.svg';
end
opt = struct('yFlip', true, 'color', 'BLACK', 'outBase', '', 'arcN', 24, 'render', true, 'write', true);
if nargin >= 2 && ~isempty(opts)
    f = fieldnames(opts);
    for k = 1:numel(f), opt.(f{k}) = opts.(f{k}); end
end
if isempty(opt.outBase)
    [~, b] = fileparts(svgFile);
    opt.outBase = [b '_equations'];
end

%% ------------------------------- read ------------------------------------
txt = fileread(svgFile);

%% --------------------------- group transform -----------------------------
% Compose every transform="..." found on the <g>/<svg> elements.  The list is
% applied left-to-right (later entries are the inner transforms).
tr = regexp(txt, 'transform\s*=\s*"([^"]*)"', 'tokens');
A = eye(3);
for i = 1:numel(tr)
    A = A * parseTransform(tr{i}{1});
end

%% ----------------------------- parse paths -------------------------------
tok   = regexp(txt, 'd\s*=\s*"([^"]*)"', 'tokens');
paths = [tok{:}];
nPath = numel(paths);
perPath = cell(nPath, 1);        % segments grouped per <path> element
for i = 1:nPath
    perPath{i} = parseSvgPath(paths{i}, opt.arcN);
end
segs = vertcat(perPath{:});
nSeg = numel(segs);

%% ------------------------- apply transform -------------------------------
R = A(1:2, 1:2);
T = A(1:2, 3).';
for i = 1:nSeg
    segs{i} = segs{i} * R.' + T;
end
for i = 1:nPath
    pi = perPath{i};
    for k = 1:numel(pi)
        pi{k} = pi{k} * R.' + T;
    end
    perPath{i} = pi;
end

%% ------------------------------ bounds -----------------------------------
allPts = vertcat(segs{:});
xmin = min(allPts(:,1)); xmax = max(allPts(:,1));
ymin = min(allPts(:,2)); ymax = max(allPts(:,2));
bbox = [xmin xmax ymin ymax];

%% ------------------------------ equations --------------------------------
eqs = cell(nSeg, 1);
for i = 1:nSeg
    eqs{i} = bezierLatex(segs{i}, ymax, opt.yFlip);
end

%% -------------------------------- write ----------------------------------
txtFile  = [opt.outBase '.txt'];
htmlFile = [opt.outBase '.html'];
pngFile  = [opt.outBase '.png'];
if opt.write
    writeEquationTxt(eqs, txtFile);
    writeDesmosHtml(eqs, xmin, xmax, ymin, ymax, opt.yFlip, opt.color, htmlFile);
    if opt.render
        renderPreview(segs, bbox, pngFile);
    end
end
%% ------------------------------- report ----------------------------------
out = struct('nPath', nPath, 'nSeg', nSeg, 'eqs', {eqs}, 'bbox', bbox, ...
    'segs', {segs}, 'pathSegs', {perPath}, ...
    'txtFile', txtFile, 'htmlFile', htmlFile, 'pngFile', pngFile);
fprintf('svgToEquations: %d paths -> %d cubic-Bezier equations\n', nPath, nSeg);
fprintf('  bbox x[%g %g] y[%g %g]\n', xmin, xmax, ymin, ymax);
if opt.write
    fprintf('  %s\n  %s\n  %s\n', txtFile, htmlFile, pngFile);
end
end

% ============================ local functions ============================

function A = parseTransform(str)
%PARSETRANSFORM  Compose an SVG transform list into a 3x3 affine matrix.
A  = eye(3);
tk = regexp(str, '(\w+)\s*\(([^)]*)\)', 'tokens');
for i = 1:numel(tk)
    name = lower(tk{i}{1});
    v    = str2double(regexp(tk{i}{2}, '[-+0-9.eE]+', 'match'));
    M    = eye(3);
    switch name
        case 'translate'
            M(1,3) = v(1);
            if numel(v) >= 2, M(2,3) = v(2); end
        case 'scale'
            M(1,1) = v(1);
            if isscalar(v), M(2,2) = v(1); else, M(2,2) = v(2); end
        case 'matrix'
            M = [v(1) v(3) v(5); v(2) v(4) v(6); 0 0 1];
        case 'rotate'
            a  = v(1)*pi/180; c = cos(a); s = sin(a);
            Rr = [c -s 0; s c 0; 0 0 1];
            if numel(v) >= 3
                T1 = [1 0 -v(2); 0 1 -v(3); 0 0 1];
                T2 = [1 0  v(2); 0 1  v(3); 0 0 1];
                M  = T2 * Rr * T1;
            else
                M = Rr;
            end
    end
    A = A * M;
end
end

% ------------------------------------------------------------------------
function S = parseSvgPath(d, arcN)
%PARSESVGPATH  Parse SVG path data into a cell array of 4x2 cubic Beziers.
cmdSet = {'M','m','L','l','H','h','V','v','C','c','S','s','Q','q','T','t','A','a','Z','z'};
pat = '[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?';
tk  = regexp(d, pat, 'match');
isLet = ismember(tk, cmdSet);
S  = cell(0, 1);
cp = [0 0]; sp = [0 0]; prevC2 = []; prevQ = []; prevCmd = '';
i = 1;
while i <= numel(tk)
    if ~isLet(i)
        error('svgToEquations:patStart', 'Path data must begin with a command.');
    end
    cmd = tk{i}; i = i + 1;
    j = i;
    while j <= numel(tk) && ~isLet(j), j = j + 1; end
    args = str2double(tk(i:j-1));
    i = j;
    [cp, sp, prevC2, prevQ, prevCmd, newSegs] = runCmd( ...
        cmd, args, cp, sp, prevC2, prevQ, prevCmd, arcN);
    S = [S; newSegs]; %#ok<AGROW>
end
end

% ------------------------------------------------------------------------
function [cp, sp, prevC2, prevQ, prevCmd, segs] = runCmd( ...
        cmd, args, cp, sp, prevC2, prevQ, prevCmd, arcN)
%RUNCMD  Execute one SVG command (possibly repeated) into cubic segments.
segs = cell(0, 1);
if upper(cmd) == 'Z'
    segs{end+1,1} = lineCubic(cp, sp); cp = sp;
    prevC2 = []; prevQ = []; prevCmd = cmd;
    return
end
ar  = struct('M',2,'L',2,'H',1,'V',1,'C',6,'S',4,'Q',4,'T',2,'A',7);
arity = ar.(upper(cmd));
n = numel(args) / arity;
rel = strcmp(cmd, lower(cmd));
for s = 1:n
    sa = args((s-1)*arity + (1:arity));   % this repetition's arguments
    ec = cmd;
    if upper(cmd) == 'M' && s > 1        % extra pairs after a moveto are linetos
        if rel, ec = 'l'; else, ec = 'L'; end
    end
    switch upper(ec)
        case 'M'
            cp = absPt(sa(1:2), cp, rel); sp = cp;
        case 'L'
            p  = absPt(sa(1:2), cp, rel);
            segs{end+1,1} = lineCubic(cp, p); cp = p; %#ok<AGROW>
        case 'H'
            if rel, x = cp(1) + sa(1); else, x = sa(1); end
            p  = [x cp(2)];
            segs{end+1,1} = lineCubic(cp, p); cp = p; %#ok<AGROW>
        case 'V'
            if rel, y = cp(2) + sa(1); else, y = sa(1); end
            p  = [cp(1) y];
            segs{end+1,1} = lineCubic(cp, p); cp = p; %#ok<AGROW>
        case 'C'
            a  = absPt(sa(1:2), cp, rel);
            b  = absPt(sa(3:4), cp, rel);
            p  = absPt(sa(5:6), cp, rel);
            segs{end+1,1} = [cp; a; b; p]; prevC2 = b; cp = p; %#ok<AGROW>
        case 'S'
            if any(strcmp(prevCmd, {'C','c','S','s'})), a = 2*cp - prevC2; else, a = cp; end
            b  = absPt(sa(1:2), cp, rel);
            p  = absPt(sa(3:4), cp, rel);
            segs{end+1,1} = [cp; a; b; p]; prevC2 = b; cp = p; %#ok<AGROW>
        case 'Q'
            q  = absPt(sa(1:2), cp, rel);
            p  = absPt(sa(3:4), cp, rel);
            segs{end+1,1} = quadCubic(cp, q, p); prevQ = q; cp = p; %#ok<AGROW>
        case 'T'
            if any(strcmp(prevCmd, {'Q','q','T','t'})), q = 2*cp - prevQ; else, q = cp; end
            p  = absPt(sa(1:2), cp, rel);
            segs{end+1,1} = quadCubic(cp, q, p); prevQ = q; cp = p; %#ok<AGROW>
        case 'A'
            p  = absPt(sa(6:7), cp, rel);
            cc = arcCubics(cp, sa(1), sa(2), sa(3), sa(4), sa(5), p, arcN);
            segs = [segs; cc]; cp = p; %#ok<AGROW>
    end
    if ~any(strcmpi(ec, {'C','S'})), prevC2 = []; end
    if ~any(strcmpi(ec, {'Q','T'})), prevQ  = []; end
    prevCmd = ec;
end
end

% ------------------------------------------------------------------------
function p = absPt(pair, cp, rel)
if rel, p = cp + pair; else, p = pair; end
end

% ------------------------------------------------------------------------
function seg = lineCubic(p0, p1)
d   = (p1 - p0) / 3;
seg = [p0; p0 + d; p0 + 2*d; p1];
end

% ------------------------------------------------------------------------
function seg = quadCubic(p0, q, p)
c1  = p0 + 2/3*(q - p0);
c2  = p  + 2/3*(q - p);
seg = [p0; c1; c2; p];
end

% ------------------------------------------------------------------------
function c = arcCubics(p0, rx, ry, xrot, largeArc, sweep, p, arcN)
%ARCCUBICS  Approximate an elliptical arc with cubic Beziers (W3C SVG F.6).
rx = abs(rx); ry = abs(ry);
if rx == 0 || ry == 0 || isequal(p0, p)
    c = {lineCubic(p0, p)};
    return
end
phi = xrot*pi/180;
dx  = (p0(1) - p(1))/2;
dy  = (p0(2) - p(2))/2;
x1p =  cos(phi)*dx + sin(phi)*dy;
y1p = -sin(phi)*dx + cos(phi)*dy;
lam = x1p^2/rx^2 + y1p^2/ry^2;
if lam > 1
    sc = sqrt(lam);
    rx = rx*sc;
    ry = ry*sc;
end
num = rx^2*ry^2 - rx^2*y1p^2 - ry^2*x1p^2;
den = rx^2*y1p^2 + ry^2*x1p^2;
co  = sqrt(max(0, num/den));
if largeArc == sweep
    co = -co;
end
cxp =  co*rx*y1p/ry;
cyp = -co*ry*x1p/rx;
cx  = cos(phi)*cxp - sin(phi)*cyp + (p0(1) + p(1))/2;
cy  = sin(phi)*cxp + cos(phi)*cyp + (p0(2) + p(2))/2;
u   = [ (x1p - cxp)/rx, (y1p - cyp)/ry ];
v   = [ (-x1p - cxp)/rx, (-y1p - cyp)/ry ];
dth = atan2(u(1)*v(2) - u(2)*v(1), u(1)*v(1) + u(2)*v(2));
if ~sweep && dth > 0, dth = dth - 2*pi; end
if  sweep && dth < 0, dth = dth + 2*pi; end
tt  = linspace(0, dth, max(2, arcN));
pts = zeros(numel(tt), 2);
for k = 1:numel(tt)
    xr = rx*cos(tt(k)); yr = ry*sin(tt(k));
    pts(k,:) = [cx + cos(phi)*xr - sin(phi)*yr, ...
                cy + sin(phi)*xr + cos(phi)*yr];
end
pts(1,:)   = p0;
pts(end,:) = p;
c = catmullToCubics(pts);
end

% ------------------------------------------------------------------------
function segs = catmullToCubics(P)
%CATMULLTOCUBICS  Fit a Catmull-Rom spline through points as cubic Beziers.
n    = size(P, 1);
segs = cell(n-1, 1);
for i = 1:n-1
    pm = P(max(i-1, 1), :);
    pp = P(min(i+2, n), :);
    p0 = P(i,     :);
    p1 = P(i+1,   :);
    c1 = p0 + (p1 - pm)/6;
    c2 = p1 - (pp - p0)/6;
    segs{i} = [p0; c1; c2; p1];
end
end

% ------------------------------------------------------------------------
function s = bezierLatex(seg, ymax, yFlip)
%BEZIERLATEX  LaTeX parametric form of one cubic Bezier.
P = seg;
if yFlip
    P(:,2) = ymax - P(:,2);
end
xs = sprintf('(1-t)^3*%s+3(1-t)^2*t*%s+3(1-t)*t^2*%s+t^3*%s', ...
    numStr(P(1,1)), numStr(P(2,1)), numStr(P(3,1)), numStr(P(4,1)));
ys = sprintf('(1-t)^3*%s+3(1-t)^2*t*%s+3(1-t)*t^2*%s+t^3*%s', ...
    numStr(P(1,2)), numStr(P(2,2)), numStr(P(3,2)), numStr(P(4,2)));
s = ['\left(' xs ',' ys '\right)'];
end

% ------------------------------------------------------------------------
function s = numStr(v)
if abs(v - round(v)) < 1e-9
    s = sprintf('%d', round(v));
else
    s = sprintf('%.4g', v);
end
end

% ------------------------------------------------------------------------
function writeEquationTxt(eqs, file)
fid = fopen(file, 'w');
fprintf(fid, '%s\n', eqs{:});
fclose(fid);
end

% ------------------------------------------------------------------------
function writeDesmosHtml(eqs, xmin, xmax, ymin, ymax, yFlip, color, file)
if yFlip
    b0 = 0; b1 = ymax - ymin;
else
    b0 = ymin; b1 = ymax;
end
esc = strrep(eqs, '\', '\\');
fid = fopen(file, 'w');
fprintf(fid, '<!DOCTYPE html>\n<html>\n<head>\n<meta charset="utf-8">\n');
fprintf(fid, '<title>Desmos equations</title>\n');
fprintf(fid, ['<script src="https://www.desmos.com/api/v1.9/calculator.js' ...
    '?apiKey=dcb31709b452b1cf9dc26972add0fda6"></script>\n']);
fprintf(fid, '<style>html,body{margin:0;height:100%%}#calculator{width:100%%;height:100%%}</style>\n');
fprintf(fid, '</head>\n<body>\n<div id="calculator"></div>\n<script>\n');
fprintf(fid, 'var elt = document.getElementById("calculator");\n');
fprintf(fid, 'var calc = Desmos.GraphingCalculator(elt);\n');
fprintf(fid, 'var eqs = [\n');
for i = 1:numel(esc)
    if i < numel(esc), sep = ','; else, sep = ''; end
    fprintf(fid, '  "%s"%s\n', esc{i}, sep);
end
fprintf(fid, '];\n');
fprintf(fid, 'for (var i = 0; i < eqs.length; i++) {\n');
fprintf(fid, ['  calc.setExpression({id: "eq" + i, latex: eqs[i], ' ...
    'color: Desmos.Colors.%s, lineWidth: 1});\n'], color);
fprintf(fid, '}\n');
fprintf(fid, 'calc.setMathBounds({left: %g, right: %g, bottom: %g, top: %g});\n', ...
    xmin, xmax, b0, b1);
fprintf(fid, '</script>\n</body>\n</html>\n');
fclose(fid);
end

% ------------------------------------------------------------------------
function renderPreview(segs, bbox, file)
f  = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 720 780]);
ax = axes(f, 'Color', 'w'); hold(ax, 'on');
for i = 1:numel(segs)
    P = evalCubic(segs{i}, 16);
    plot(ax, P(:,1), P(:,2), 'k-', 'LineWidth', 1);
end
dx = 0.02 * (bbox(2) - bbox(1));
dy = 0.02 * (bbox(4) - bbox(3));
xlim(ax, [bbox(1)-dx bbox(2)+dx]);
ylim(ax, [bbox(3)-dy bbox(4)+dy]);
set(ax, 'YDir', 'reverse', 'Box', 'off', 'XColor', 'none', 'YColor', 'none');
axis(ax, 'equal');
try
    exportgraphics(ax, file, 'BackgroundColor', 'white', 'Resolution', 150);
catch
    set(f, 'Color', 'white');
    print(f, file, '-dpng', '-r150');
end
close(f);
end

% ------------------------------------------------------------------------
function P = evalCubic(seg, n)
t = linspace(0, 1, n).';
P = (1-t).^3 .* seg(1,:) + 3*(1-t).^2 .* t .* seg(2,:) + ...
    3*(1-t) .* t.^2 .* seg(3,:) + t.^3 .* seg(4,:);
end
