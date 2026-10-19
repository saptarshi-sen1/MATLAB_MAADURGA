# Setup & First Run

Everything here runs in a local MATLAB install; nothing is uploaded anywhere.

## 1. Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| MATLAB    | R2020a+ | `exportgraphics` is used for the SVG preview. |

Base MATLAB covers the SVG/equation path. The raster and anamorphic paths also
need the **Image Processing Toolbox** (`imread`, `imgaussfilt`, `imfilter`).

Check what you have:

```matlab
ver('MATLAB')
```

## 2. Get the code

```bash
git clone <your-repo-url> MATLAB_Durga_Demo
cd MATLAB_Durga_Demo
```

If you are working from a copy on disk, just `cd` into the folder.

## 3. Make MATLAB see the sources

In MATLAB, from the repository root:

```matlab
addpath('src')          % for this session
savepath                % optional: remember it for future sessions
```

`examples/run_equations.m` and `examples/run_extrude_demo.m` add `src/` for you.

## 4. First run

```matlab
run('examples/run_equations.m')
```

This creates an `output/` folder containing:

```
output/durgamaa_svg_equations.txt     LaTeX parametric equations (one per line)
output/durgamaa_svg_equations.html    self-contained Desmos graph
output/durgamaa_svg_equations.png     MATLAB black-and-white preview
```

Open `output/durgamaa_svg_equations.html` in any browser to see the drawing
render live on Desmos.

## 5. Extrude a height map to STL

```matlab
run('examples/run_extrude_demo.m')
% -> output/demo.stl  (watertight, safe for 3-D printing)
```

`writeDurgaSTL(X,Y,Z,'file.stl')` accepts same-size matrices where `Z` is the
front surface; it builds the flat back plate and side walls automatically.

---

## Troubleshooting

**`Not enough input arguments` when running `writeDurgaSTL.m` directly.**
It is a function that needs its inputs - call it from the workspace or via the
demo script, not with the *Run* button:

```matlab
[X,Y] = meshgrid(linspace(-1,1,200));
Z = exp(-4*(X.^2+Y.^2));
writeDurgaSTL(X,Y,Z,'output/demo.stl');
```

**`Out of memory` from `triangulation`/`stlwrite` on large grids.**
That is exactly what `writeDurgaSTL` avoids - it streams the binary STL with a
tiny buffer instead of building a giant in-memory `triangulation`. Use it for
big grids.

**Desmos page is blank.**
The `.html` loads the Desmos API from the internet; open it with a connection.
