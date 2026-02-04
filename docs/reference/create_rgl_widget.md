# Create rgl Widget for Interactive 3D Display

Generates an interactive rglwidget for HTML output (vignettes, pkgdown
articles). This is a wrapper around rgl::rglwidget() with sensible
defaults.

## Usage

``` r
create_rgl_widget(width = 800, height = 600, elementId = NULL)
```

## Arguments

  - width:
    
    Integer. Widget width in pixels (default: 800)

  - height:
    
    Integer. Widget height in pixels (default: 600)

  - elementId:
    
    Character. Optional DOM element ID for the widget

## Value

An htmlwidget object (rglwidget)

## Details

This function creates an interactive 3D widget that:

  - Works in HTML vignettes and pkgdown articles

  - Allows rotation, zoom, and pan with mouse

  - Only renders in HTML output (not PDF/Word)

## Examples

``` r
if (FALSE) { # \dontrun{
library(rgl)

# Create scene
open3d()
spheres3d(rnorm(100), rnorm(100), rnorm(100), radius = 0.1)

# Generate interactive widget (HTML only)
create_rgl_widget()
} # }
```
