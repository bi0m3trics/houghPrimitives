# Quick Start: rgl Figures in Vignettes

## 30-Second Setup

Add this to your vignette setup chunk:

```r
```{r setup, include = FALSE}
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

# Enable headless rgl rendering
if (requireNamespace("rgl", quietly = TRUE)) {
  library(houghPrimitives)
  setup_rgl_knitr()
}
```
```

## 60-Second Example

Create a static 3D figure:

```r
```{r my-3d-figure, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)

# Create scene
open3d()
spheres3d(0, 0, 0, radius = 1, color = "steelblue")
axes3d()

# Save PNG
fig_path <- save_rgl_snapshot("my-sphere.png")
close3d()
```

# Show the figure
```{r show-fig, echo = FALSE}
knitr::include_graphics(fig_path)
```
```

## That's It!

Your figure:
- ✅ Works in HTML vignettes
- ✅ Works in PDF vignettes
- ✅ Works in pkgdown articles
- ✅ Works in CRAN checks (headless)
- ✅ Fully reproducible

## Add Interactivity (Optional)

For HTML output, add interactive rotation:

```r
```{r interactive, eval = knitr::is_html_output() && requireNamespace("rgl", quietly = TRUE)}
open3d()
plot3d(rnorm(100), rnorm(100), rnorm(100), col = "coral")

widget <- create_rgl_widget()
close3d()

widget
```
```

## More Examples

See:
- `vignettes/RGL_FIGURES_GUIDE.md` - Complete documentation
- `vignettes/rgl_chunk_templates.R` - 10 copy-paste templates
- `vignettes/sphere-detection.Rmd` - Live example

## Functions Available

```r
setup_rgl_knitr()           # Call in setup chunk (required)
save_rgl_snapshot(filename) # Save PNG to man/figures/
create_rgl_widget()         # Interactive 3D (HTML only)
create_rgl_figure(fn, file) # Automated workflow
```

## Common Pattern

```r
# 1. Setup (once per vignette)
setup_rgl_knitr()

# 2. Create and save
open3d()
# ... your rgl code ...
fig_path <- save_rgl_snapshot("name.png")
close3d()

# 3. Display
knitr::include_graphics(fig_path)
```

Ready to visualize! 🎨
