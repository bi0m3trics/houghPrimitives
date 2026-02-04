# Generate Interpolated Colors from Hough Palette

Creates a smooth color gradient by interpolating between colors in the
Hough palette. Useful when you need many distinct colors.

## Usage

``` r
hough_palette_gradient(n, type = c("full", "contrast"), alpha = 1)
```

## Arguments

  - n:
    
    Number of colors to return

  - type:
    
    Palette type: "full" or "contrast"

  - alpha:
    
    Transparency level (0-1), default 1 (opaque)

## Value

Character vector of hex color codes

## Examples

``` r
# Generate 50 interpolated colors
colors <- hough_palette_gradient(50)

# With transparency
colors_alpha <- hough_palette_gradient(20, alpha = 0.7)
```
