# Save rgl Scene as Static PNG

Captures the current rgl scene and saves it as a PNG file in a
pkgdown-safe location. This function is designed for use in vignettes
and articles.

## Usage

``` r
save_rgl_snapshot(
  filename,
  width = 800,
  height = 600,
  dpi = 96,
  output_dir = NULL
)
```

## Arguments

  - filename:
    
    Character. Base filename without path (e.g., "sphere-detection.png")

  - width:
    
    Integer. Image width in pixels (default: 800)

  - height:
    
    Integer. Image height in pixels (default: 600)

  - dpi:
    
    Integer. Resolution in dots per inch (default: 96)

  - output\_dir:
    
    Character. Directory to save figure. If NULL (default),
    automatically detects context: "." for vignettes, "man/figures/" for
    pkgdown articles. Can be overridden for specific use cases.

## Value

Character. Full path to the saved PNG file (invisibly)

## Details

This function:

  - Uses rgl::snapshot3d() for high-quality PNG output

  - Auto-detects vignette context and saves to appropriate location

  - In vignettes: saves to current directory (vignette build directory)

  - In pkgdown/manual use: saves to man/figures/ (pkgdown standard)

  - Creates the output directory if it doesn't exist

  - Returns the path for use with knitr::include\_graphics()

## Examples

``` r
if (FALSE) { # \dontrun{
library(rgl)

# Create rgl scene
open3d()
spheres3d(0, 0, 0, radius = 1, color = "blue")

# Save as PNG
fig_path <- save_rgl_snapshot("my-sphere.png")

# Use in knitr chunk
knitr::include_graphics(fig_path)
} # }
```
