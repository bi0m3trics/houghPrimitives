# Setup rgl for Vignette/Article Use

Configures rgl for headless rendering suitable for vignettes and pkgdown
articles. Call this in your setup chunk.

## Usage

``` r
setup_rgl_knitr(use_null = TRUE)
```

## Arguments

  - use\_null:
    
    Logical. If TRUE (default), use headless NULL device for rendering.
    This is required for CRAN checks and CI environments without
    X11/display.

## Value

NULL (called for side effects)

## Details

This function:

  - Sets options(rgl.useNULL = TRUE) for headless rendering

  - Calls rgl::setupKnitr() to configure knitr hooks

  - Should be called once in the vignette setup chunk

  - Ensures rgl works without a display device

## Examples

``` r
if (FALSE) { # \dontrun{
# In vignette setup chunk:
setup_rgl_knitr()
} # }
```
