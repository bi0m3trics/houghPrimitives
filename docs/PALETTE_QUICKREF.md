# houghPrimitives Color Palette Quick Reference

## Quick Start

``` r
library(houghPrimitives)

# Get N colors for categorical data (shapes, classes)
colors <- hough_palette(n = 8, type = "contrast")

# Get N colors for continuous data (elevation, intensity)  
colors <- hough_palette_gradient(n = 50, type = "full")

# Get N contrasting pairs for labels/text
pairs <- hough_palette_pairs(n = 5)  # Returns 10 colors (5 pairs)

# Preview colors
hough_palette_preview(n = 12, type = "contrast")
```

-----

## Function Reference

| Function                                 | Purpose                     | Returns                        |
| ---------------------------------------- | --------------------------- | ------------------------------ |
| `hough_palette(n, type)`                 | Get n colors from palette   | Character vector of hex colors |
| `hough_palette_gradient(n, type, alpha)` | Interpolate n smooth colors | Character vector of hex colors |
| `hough_palette_pairs(n)`                 | Get n contrasting pairs     | Character vector (2n colors)   |
| `hough_palette_preview(n, type)`         | Display color barplot       | Plot (side effect)             |

-----

## Palette Types

| Type         | Colors                    | Best For                              |
| ------------ | ------------------------- | ------------------------------------- |
| `"full"`     | 20 colors (dark → bright) | Continuous data, gradients, elevation |
| `"contrast"` | 19 colors (high contrast) | Categories, shapes, classifications   |

-----

## Common Use Cases

### Detected Shapes (Categorical)

``` r
result <- detect_spheres(points, ...)
colors <- hough_palette(result$n_spheres, "contrast")
```

### Elevation Gradient (Continuous)

``` r
colors <- hough_palette_gradient(100, "full")
elevation_bins <- cut(points[,3], breaks = 100)
point_colors <- colors[elevation_bins]
```

### Classification Colors

``` r
# 7 classes
class_colors <- hough_palette(7, "contrast")
# Apply to LAS classification
las$RGB <- class_colors[las$Classification]
```

### Text Labels with Background

``` r
pairs <- hough_palette_pairs(5)
# pairs[1] = foreground, pairs[2] = background
# pairs[3] = foreground, pairs[4] = background, etc.
```

-----

## Tips

✅ **Contrast palette** - For distinct shapes/categories  
✅ **Full palette** - For smooth transitions  
✅ **Gradient function** - When n \> palette size and need smooth
colors  
✅ **Regular function** - When n \> palette size and cycling is OK  
✅ **Alpha parameter** - For transparent overlays (0.0-1.0)

-----

## Color Counts

  - Full palette: 20 colors
  - Contrast palette: 19 colors  
  - Pairs: 10 pairs (20 colors)
  - Gradient: unlimited (interpolated)

**Note:** If you request more colors than available, `hough_palette()`
automatically cycles. Use `hough_palette_gradient()` for true
interpolation.

-----

## Examples

``` r
# Example 1: Color each detected cylinder differently
result <- detect_cylinders(points, label_points = TRUE)
cyl_colors <- hough_palette(result$n_cylinders, "contrast")

# Example 2: Smooth intensity gradient
intensity_colors <- hough_palette_gradient(50, "full", alpha = 1.0)

# Example 3: High-contrast labels
label_pairs <- hough_palette_pairs(3)
# Use: label_pairs[1] on label_pairs[2], label_pairs[3] on label_pairs[4], etc.

# Example 4: Preview before using
hough_palette_preview(15, "contrast")
```

-----

## Integration with lidR

``` r
library(lidR)

# Detect and color
result <- detect_spheres(points, label_points = TRUE)
colors <- hough_palette(result$n_spheres, "contrast")

# Create LAS
las <- LAS(data.frame(X = points[,1], Y = points[,2], Z = points[,3],
                      SphereID = result$point_labels))

# Plot with automatic coloring
plot(las, color = "SphereID", size = 3)
```

-----

## See Also

  - Full documentation: `?hough_palette`
  - Comprehensive guide: `PALETTE_GUIDE.md`
  - Example usage: `examples/example_palettes.R`
