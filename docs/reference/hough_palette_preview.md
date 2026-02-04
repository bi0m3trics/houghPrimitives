# Preview Hough Color Palettes

Displays the color palettes as a simple bar chart for visualization

## Usage

``` r
hough_palette_preview(n = 20, type = c("full", "contrast", "gradient"))
```

## Arguments

  - n:
    
    Number of colors to display (default 20)

  - type:
    
    Palette type: "full", "contrast", or "gradient"

## Value

Invisibly returns the color vector

## Examples

``` r
if (FALSE) { # \dontrun{
# Preview full palette
hough_palette_preview(20, "full")

# Preview contrast palette
hough_palette_preview(15, "contrast")

# Preview gradient
hough_palette_preview(30, "gradient")
} # }
```
