# Example: Using houghPrimitives Color Palettes
# Demonstrates the flexible color palette functions

library(houghPrimitives)

cat("=== HOUGHPRIMITIVES COLOR PALETTES ===\n\n")

# 1. Basic palette usage
cat("1. Basic hough_palette() function:\n")
cat("   - Full palette (20 colors from dark to bright)\n")
cat("   - Contrast palette (19 high-contrast colors)\n\n")

colors_full <- hough_palette(8, type = "full")
cat("8 colors from 'full' palette:\n")
print(colors_full)

colors_contrast <- hough_palette(8, type = "contrast")
cat("\n8 colors from 'contrast' palette:\n")
print(colors_contrast)

# 2. Handling more colors than palette size (cycling)
cat("\n2. Requesting more colors than available (automatic cycling):\n")
colors_many <- hough_palette(25, type = "contrast")  # 19-color palette, but request 25
cat(sprintf("Requested 25 colors from 19-color 'contrast' palette:\n"))
print(colors_many)
cat(sprintf("   (First 19 are unique, then it cycles: colors[1]=%s == colors[20]=%s)\n",
            colors_many[1], colors_many[20]))

# 3. Gradient interpolation for smooth color ramps
cat("\n3. Gradient interpolation with hough_palette_gradient():\n")
gradient_colors <- hough_palette_gradient(15, type = "full", alpha = 1.0)
cat("15 interpolated colors from 'full' palette:\n")
print(gradient_colors)

# With transparency
gradient_transparent <- hough_palette_gradient(10, type = "contrast", alpha = 0.7)
cat("\n10 interpolated colors from 'contrast' palette with 70% opacity:\n")
print(gradient_transparent)

# 4. Contrasting color pairs for foreground/background
cat("\n4. Contrasting color pairs with hough_palette_pairs():\n")
pairs <- hough_palette_pairs(5)
cat("5 pairs (10 colors total) for high contrast visualizations:\n")
for (i in 1:5) {
  cat(sprintf("   Pair %d: Foreground=%s, Background=%s\n", 
              i, pairs[2*i-1], pairs[2*i]))
}

# 5. Visual preview
cat("\n5. Visual preview:\n")
cat("   Opening barplot for 'full' palette with 15 colors...\n")
hough_palette_preview(15, type = "full")

cat("\n   Opening barplot for 'contrast' palette with 12 colors...\n")
hough_palette_preview(12, type = "contrast")

# 6. Practical usage: Coloring detected shapes
cat("\n6. Practical example: Assigning colors to detected shapes\n")

# Simulate detection results
n_spheres <- 3
n_cylinders <- 4
n_cubes <- 2

# Get colors for each shape type
sphere_colors <- hough_palette(n_spheres, "contrast")
cylinder_colors <- hough_palette(n_cylinders, "full")
cube_colors <- hough_palette(n_cubes, "contrast")

cat(sprintf("\nDetected %d spheres - assigned colors:\n", n_spheres))
print(sphere_colors)

cat(sprintf("\nDetected %d cylinders - assigned colors:\n", n_cylinders))
print(cylinder_colors)

cat(sprintf("\nDetected %d cubes - assigned colors:\n", n_cubes))
print(cube_colors)

# 7. Creating a custom palette for a specific number of classes
cat("\n7. Custom palette for N classification classes:\n")
n_classes <- 7
class_colors <- hough_palette(n_classes, "contrast")
cat(sprintf("Colors for %d classification classes:\n", n_classes))
for (i in 1:n_classes) {
  cat(sprintf("   Class %d: %s\n", i, class_colors[i]))
}

# 8. Gradient for continuous color scale
cat("\n8. Smooth gradient for continuous values (e.g., elevation, intensity):\n")
elevation_colors <- hough_palette_gradient(50, "full", alpha = 1.0)
cat("50-color gradient for continuous elevation/intensity mapping:\n")
cat(sprintf("   Low:  %s\n", elevation_colors[1]))
cat(sprintf("   Mid:  %s\n", elevation_colors[25]))
cat(sprintf("   High: %s\n", elevation_colors[50]))

cat("\n=== PALETTE SUMMARY ===\n")
cat("Available functions:\n")
cat("  • hough_palette(n, type='full'|'contrast')  - Get n colors (cycles if n > palette size)\n")
cat("  • hough_palette_gradient(n, type, alpha)    - Interpolate n smooth colors\n")
cat("  • hough_palette_pairs(n)                    - Get n contrasting pairs (2n colors)\n")
cat("  • hough_palette_preview(n, type)            - Display barplot visualization\n")
cat("\nPalette types:\n")
cat("  • 'full'     - 20 colors from dark to bright (good for sequential data)\n")
cat("  • 'contrast' - 19 high-contrast colors (good for categorical data)\n")
cat("\nExample complete!\n")
