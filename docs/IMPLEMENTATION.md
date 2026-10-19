# Implementation Notes

This document records **what was built and how**, including the measurements and
dead-ends that shaped the design.

---

## 1. Pipeline overview

```
                 +------------------------+
 durgamaa_svg.svg | svgToEquations.m       |  .txt  (LaTeX Beziers)
 ---------------> |  parse path grammar    |  .html (Desmos graph)
                 |  -> cubic Beziers       |  .png  (MATLAB preview)
                 +------------------------+

 height map (X,Y,Z) --> writeDurgaSTL.m --> watertight binary STL
```

Both tools are plain MATLAB functions; there is no state or config file.

---

## 2. Coordinate model

The Durga SVG contains a single group:

```xml
<g transform="translate(0,2672) scale(0.1,-0.1)" fill="#000000" stroke="none">
```

with `viewBox="0 0 2500 2672"`.

- Raw path coordinates are multiplied by `0.1` and the y axis is negated
  (`scale(0.1,-0.1)`), then shifted down by `2672`.
- After the transform, coordinates land directly in **image-pixel space**:
  `x in [89, 2405]`, `y in [95, 2567]` - i.e. `image column = X`, `image row = Y`.

`svgToEquations` composes *every* `transform="..."` in the file (left-to-right,
inner transforms last) into one 3x3 affine matrix `A`, supporting `translate`,
`scale`, `matrix` and `rotate`. It applies `A` to the segments.

For human-readable output (`bezierLatex`) the y axis is flipped back with
`yFlip` (default true) so the drawing is upright on Desmos.

---

## 3. `svgToEquations.m`

**Goal:** rewrite every SVG curve as a parametric cubic Bezier
`(x(t), y(t))`, `t in [0,1]`, graphable on Desmos.

1. **Tokenise** each `d="..."` attribute with one regex that alternates command
   letters `[MmLlHhVvCcSsQqTtAaZz]` and numbers.
2. **Build** cubic segments:
   - `M/L` start/line; `H/V` horizontal/vertical lines (as degenerate cubics).
   - `C` cubic; `S` smooth cubic; `Q` quadratic; `T` smooth quadratic.
   - `A` elliptical arc, flattened to cubics via `arcN` samples.
   - `Z` closes the subpath.

For `durgamaa_svg.svg`: **34 paths -> 1921 cubic Beziers**, bbox
`x[89.2 2404.9] y[95.2 2567]`.

---

## 3b. Why the equations also render (`render` option)

The `.png` preview is generated from the same parsed Beziers, so it doubles as a
correctness check: if the equations look right, the segments are right.

---

## 4. `writeDurgaSTL.m`

### 4.1 The problem it solves

The obvious approach - build a `triangulation` for the whole grid and call
`stlwrite` - exhausts memory on large grids. The crash logs were **native JVM
out-of-memory** (`Failed to commit metaspace`, `mmap failed`), not MATLAB array
OOM. Building a giant in-memory `triangulation` object is what blows up.

### 4.2 The streaming fix

Rather than triangulating the whole grid, `writeDurgaSTL` writes the **binary
STL format directly**:

```
[80-byte header][uint32 triangle count][face records...]
```

Each face is 50 bytes: `normal (3xfloat32)` + 3 vertices (`3x3xfloat32`) +
`uint16` attribute. Faces are emitted in a tight loop with `fwrite`, so peak
memory stays tiny even for multi-million-triangle solids.

### 4.3 Watertightness

It builds a closed surface: the `Z`-grid front, a flat back plate at `z=0`, and
four side walls. The winding is consistent, so the result is a watertight,
orientable solid suitable for 3-D printing.

### 4.4 Verification

Because results are verified head-lessly, the checks used were: file size, the
STL header's triangle count, and a signed-volume test. A correct solid for a
known test surface passed all three, and multi-million-triangle grids exported
without a crash.

---

## 5. Known limitations

- `svgToEquations` handles the SVG path grammar and
  `translate/scale/rotate/matrix` transforms; it does not evaluate CSS
  stylesheets or `<use>`/symbol instantiation.
- The tools assume a well-formed single-document SVG. Very large path sets are
  fine (thousands of segments), but the whole file is parsed into memory first.
