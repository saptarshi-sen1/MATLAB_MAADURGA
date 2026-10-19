# Architecture - how the functions fit together

Three **core primitives**, a set of **height-field builders**, and a few
**one-call pipelines** that chain them.

---

## 1. The three core primitives

| Function | Input | Output | Role |
|----------|-------|--------|------|
| `writeDurgaSTL.m` | `X,Y,Z` grid, filename | triangle count | Streams a watertight **binary STL** (front + back plate + walls) with a tiny buffer. |
| `heightfieldToAnamorphic.m` | height field `H` `[0,1]` | `X,Y,Z` + STL | The **anamorphic engine**: `screen V = Y*sin(el) + Z*cos(el)`, `Z = amp*H(V)`. |
| `svgToEquations.m` | SVG | cubic Beziers + `.txt`/`.html`/`.png` | The **SVG parser** (also used head-less with `write=false`). |

---

## 2. Builders, writers and pipelines

| Layer | Function | Uses |
|-------|----------|------|
| Builder | `svgToRelief.m` | `svgToEquations` |
| Builder | `imageToRelief.m` | - |
| Writer | `reliefWriteSTL.m` | `writeDurgaSTL` |
| Writer | `figureToSTL.m` | `writeDurgaSTL` |
| Pipeline | `svgTo3D.m` | `svgToRelief` + `reliefWriteSTL` |
| Pipeline | `imageTo3D.m` | `imageToRelief` + `reliefWriteSTL` |
| Pipeline | `svgToAnamorphic.m` | `svgToRelief` + `heightfieldToAnamorphic` |
| Pipeline | `imageToAnamorphic.m` | `imageToRelief` + `heightfieldToAnamorphic` |

---

## 3. Dependency graph

```mermaid
flowchart TD
    SVG([SVG file]) --> EQ[svgToEquations]
    EQ -.-> EQOUT[".txt / .html / .png"]
    EQ --> SREL[svgToRelief]
    IMG([raster image PNG/JPEG]) --> IREL[imageToRelief]
    FIG([plotted figure surface]) --> FSTL[figureToSTL]

    SREL --> S3D[svgTo3D]
    SREL --> SAN[svgToAnamorphic]
    IREL --> I3D[imageTo3D]
    IREL --> IAN[imageToAnamorphic]

    S3D --> RSTL[reliefWriteSTL]
    I3D --> RSTL
    SAN --> HFA[heightfieldToAnamorphic]
    IAN --> HFA

    RSTL --> WSTL[writeDurgaSTL]
    HFA --> WSTL
    FSTL --> WSTL
    WSTL --> STL([.stl model])
```

Solid arrows are calls; the dotted arrow is optional file output.

---

## 4. Data flow

**Raster -> anamorphic (the demo)**

```mermaid
flowchart LR
    A[assets/main_clean.png] --> B[imageToRelief]
    B --> C[flipud] --> D[heightfieldToAnamorphic]
    D --> E[writeDurgaSTL] --> F[durga_anamorphic_photo.stl]
```

**SVG -> anamorphic**

```mermaid
flowchart LR
    A[assets/durgamaa_svg.svg] --> B[svgToEquations] --> C[svgToRelief]
    C --> D[heightfieldToAnamorphic] --> E[writeDurgaSTL] --> F[.stl]
```

**Any source -> thin relief**

```mermaid
flowchart LR
    A[SVG or raster] --> B[svgToRelief / imageToRelief]
    B --> C[reliefWriteSTL] --> D[writeDurgaSTL] --> E[.stl]
```

---

## 5. Conventions across files

- **Height fields are `[0,1]`**, `ny-by-nx`. The engine renormalises defensively.
- **Row order differs by design**: `imageToRelief` puts row 1 at the **top** (so
  callers `flipud` before the anamorphic engine); `svgToRelief` has row 1 at the
  **bottom**.
- **One uniform mm scale** on X, Y and Z is what makes the oblique view
  reconstruct the picture - do not scale Z independently.
- `output/` and `*.stl` are git-ignored; published models are force-added.

---

## 6. Files by layer

```
src/
  writeDurgaSTL.m            core: watertight binary STL writer
  heightfieldToAnamorphic.m  core: anamorphic engine
  svgToEquations.m           core: SVG -> Beziers / txt / html / png
  svgToRelief.m      builder svgToEquations -> height field
  imageToRelief.m    builder raster -> height field
  reliefWriteSTL.m   writer  thin plaque -> writeDurgaSTL
  figureToSTL.m      writer  figure surface -> writeDurgaSTL
  svgTo3D.m          pipeline svgToRelief -> reliefWriteSTL
  imageTo3D.m        pipeline imageToRelief -> reliefWriteSTL
  svgToAnamorphic.m  pipeline svgToRelief -> heightfieldToAnamorphic
  imageToAnamorphic.m pipeline imageToRelief -> heightfieldToAnamorphic
examples/            one runnable script per scenario
assets/              durgamaa_svg.svg (vector), main_clean.png (photo)
```

See also: [../README.md](../README.md), [IMPLEMENTATION.md](IMPLEMENTATION.md).
