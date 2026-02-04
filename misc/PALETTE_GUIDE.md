# houghPrimitives Color Palettes

## Overview

The `houghPrimitives` package includes a flexible color palette system designed for visualizing point cloud detection results. The palettes provide both sequential colors (for continuous data) and high-contrast colors (for categorical data like detected shapes).

## Available Functions

### 1. `hough_palette(n, type = c("full", "contrast"))`

**Primary palette function** - Returns `n` colors from the specified palette.

**Parameters:**
- `n` - Number of colors to return
- `type` - Palette type:
  - `"full"` - 20-color palette from dark to bright (sequential)
  - `"contrast"` - 19-color high-contrast palette (categorical)

**Behavior:**
- If `n <= palette_size`: Returns first `n` colors
- If `n > palette_size`: Cycles through palette using `rep_len()`

**Examples:**
```r
# Get 5 colors from full palette
colors <- hough_palette(5, "full")
# Returns: "#0B0E14", "#1F2937", "#2E3440", "#FF9F1C", "#FF7A18"

# Get 8 high-contrast colors
colors <- hough_palette(8, "contrast")
# Returns: "#FF9F1C", "#4CC9F0", "#E4572E", "#2EC4B6", ...

# Request more than available (cycles)
colors <- hough_palette(25, "contrast")  # 19-color palette
# Returns 25 colors, cycling after 19
```

---

### 2. `hough_palette_gradient(n, type = c("full", "contrast"), alpha = 1.0)`

**Interpolated gradient function** - Creates smooth color transitions.

**Parameters:**
- `n` - Number of interpolated colors
- `type` - Base palette type
- `alpha` - Transparency (0.0 = fully transparent, 1.0 = opaque)

**Behavior:**
- Uses `colorRampPalette()` to interpolate between base colors
- Skips very dark anchors to maintain visibility
- Creates smooth gradients for continuous data

**Examples:**
```r
# Smooth 50-color gradient for elevation mapping
elevation_colors <- hough_palette_gradient(50, "full")

# 20-color gradient with transparency for overlays
overlay_colors <- hough_palette_gradient(20, "contrast", alpha = 0.7)
```

---

### 3. `hough_palette_pairs(n)`

**Contrasting pairs function** - Returns high-contrast foreground/background pairs.

**Parameters:**
- `n` - Number of color pairs (returns `2*n` colors)

**Behavior:**
- Returns predefined high-contrast pairs
- Pairs alternate: `(foreground1, background1, foreground2, background2, ...)`
- Maximum 10 pairs available (cycles if `n > 10`)

**Examples:**
```r
# Get 3 contrasting pairs (6 colors)
pairs <- hough_palette_pairs(3)
# Returns: "#FF9F1C", "#0B0E14", "#4CC9F0", "#1F2937", "#E4572E", "#FFFFFF"

# Use for text labels on shapes
for (i in 1:3) {
  fg <- pairs[2*i - 1]  # Foreground color
  bg <- pairs[2*i]      # Background color
  # Draw text with fg color on bg background
}
```

---

### 4. `hough_palette_preview(n, type = c("full", "contrast"))`

**Visualization function** - Displays barplot of palette colors.

**Parameters:**
- `n` - Number of colors to preview
- `type` - Palette type

**Behavior:**
- Creates barplot with each bar colored according to palette
- Useful for exploring color combinations
- Shows color hex codes on bars

**Examples:**
```r
# Preview 12 contrast colors
hough_palette_preview(12, "contrast")

# Preview full palette gradient
hough_palette_preview(20, "full")
```

---

## Palette Compositions

### Full Palette (20 colors)
Sequential dark-to-bright palette for continuous data:

```
 1. #0B0E14  (Very dark blue-black)
 2. #1F2937  (Dark gray-blue)
 3. #2E3440  (Dark gray)
 4. #FF9F1C  (Vibrant orange)
 5. #FF7A18  (Deep orange)
 6. #E4572E  (Red-orange)
 7. #FF3C38  (Bright red)
 8. #FFD166  (Golden yellow)
 9. #FCA311  (Amber)
10. #E9C46A  (Soft yellow)
11. #84BC48  (Yellow-green)
12. #2EC4B6  (Turquoise)
13. #00BBF9  (Sky blue)
14. #4CC9F0  (Bright cyan)
15. #4895EF  (Medium blue)
16. #560BAD  (Deep purple)
17. #9D4EDD  (Purple)
18. #C77DFF  (Light purple)
19. #B5179E  (Magenta)
20. #F72585  (Hot pink)
```

### Contrast Palette (19 colors)
High-contrast colors for categorical distinctions:

```
 1. #FF9F1C  (Vibrant orange)
 2. #4CC9F0  (Bright cyan)
 3. #E4572E  (Red-orange)
 4. #2EC4B6  (Turquoise)
 5. #FFD166  (Golden yellow)
 6. #7209B7  (Purple)
 7. #FF3C38  (Bright red)
 8. #00B4D8  (Deep cyan)
 9. #E9C46A  (Soft yellow)
10. #B5179E  (Magenta)
11. #4895EF  (Medium blue)
12. #F4D35E  (Bright yellow)
13. #9D4EDD  (Light purple)
14. #A8DADC  (Pale cyan)
15. #1F2937  (Dark gray-blue)
16. #EAEAEA  (Light gray)
17. #2E3440  (Dark gray)
18. #FFFFFF  (White)
19. #0B0E14  (Very dark blue)
```

### Contrasting Pairs (10 pairs)
Predefined foreground/background combinations:

```
Pair 1:  #FF9F1C / #0B0E14  (Orange on dark)
Pair 2:  #4CC9F0 / #1F2937  (Cyan on dark gray)
Pair 3:  #E4572E / #FFFFFF  (Red-orange on white)
Pair 4:  #2EC4B6 / #2E3440  (Turquoise on gray)
Pair 5:  #FFD166 / #7209B7  (Yellow on purple)
Pair 6:  #FF3C38 / #0B0E14  (Red on dark)
Pair 7:  #00B4D8 / #FFFFFF  (Deep cyan on white)
Pair 8:  #E9C46A / #1F2937  (Soft yellow on dark)
Pair 9:  #B5179E / #EAEAEA  (Magenta on light gray)
Pair 10: #4895EF / #2E3440  (Blue on gray)
```

---

## Usage Examples

### Example 1: Coloring Detected Shapes

```r
library(houghPrimitives)
library(lidR)

# Detect shapes
result_spheres <- detect_spheres(points, ...)
result_cylinders <- detect_cylinders(points, ...)

# Assign unique colors to each detected shape
n_total <- result_spheres$n_spheres + result_cylinders$n_cylinders
shape_colors <- hough_palette(n_total, "contrast")

# Color spheres
sphere_colors <- shape_colors[1:result_spheres$n_spheres]

# Color cylinders
cyl_start <- result_spheres$n_spheres + 1
cyl_end <- n_total
cylinder_colors <- shape_colors[cyl_start:cyl_end]
```

### Example 2: LiDAR Classification Coloring

```r
# Create classification color scheme
class_names <- c("Unclassified", "Ground", "Vegetation", 
                 "Building", "Sphere", "Cylinder", "Line")
n_classes <- length(class_names)

# Get distinct colors for each class
class_colors <- hough_palette(n_classes, "contrast")

# Create color mapping
color_map <- setNames(class_colors, class_names)

# Apply to LAS object
las$RGB <- class_colors[las$Classification]
plot(las)
```

### Example 3: Continuous Intensity Mapping

```r
# Map intensity values to gradient
intensity_range <- range(las$Intensity)
n_bins <- 100

# Create smooth gradient
intensity_colors <- hough_palette_gradient(n_bins, "full")

# Map values to colors
intensity_bins <- cut(las$Intensity, breaks = n_bins)
las$RGB <- intensity_colors[intensity_bins]

plot(las, color = "RGB")
```

### Example 4: Multi-Plot Consistency

```r
# Detect multiple shape types
detect_all_shapes <- function(points) {
  list(
    planes = detect_planes(points, ...),
    spheres = detect_spheres(points, ...),
    cylinders = detect_cylinders(points, ...),
    cubes = detect_cubes(points, ...)
  )
}

results <- detect_all_shapes(point_cloud)

# Assign consistent color scheme across all plots
all_colors <- hough_palette(20, "contrast")

# Use same color palette for all visualizations
plot_planes(results$planes, colors = all_colors[1:5])
plot_spheres(results$spheres, colors = all_colors[6:10])
plot_cylinders(results$cylinders, colors = all_colors[11:15])
plot_cubes(results$cubes, colors = all_colors[16:20])
```

---

## Design Principles

### Full Palette
- **Sequential ordering**: Dark → Medium → Bright → Saturated
- **Use cases**: 
  - Elevation gradients
  - Intensity mapping
  - Continuous scalar fields
  - Time series visualization

### Contrast Palette
- **Perceptual distinctness**: Colors chosen for maximum visual separation
- **Use cases**:
  - Shape classification
  - Instance segmentation
  - Categorical labels
  - Multi-object detection

### Gradient Interpolation
- **Smooth transitions**: Uses `colorRampPalette()` for seamless gradients
- **Visibility**: Skips very dark colors to maintain contrast
- **Flexibility**: Alpha channel for overlay transparency

### Contrasting Pairs
- **Readability**: Optimized for text/labels on backgrounds
- **Accessibility**: High luminance contrast ratios
- **Use cases**:
  - Text annotations
  - Legend labels
  - UI elements

---

## Tips and Best Practices

### 1. Choosing the Right Palette

```r
# For CATEGORICAL data (shapes, classes, objects):
colors <- hough_palette(n_categories, "contrast")

# For CONTINUOUS data (elevation, intensity, distance):
colors <- hough_palette_gradient(n_bins, "full")

# For LABELS with backgrounds:
pairs <- hough_palette_pairs(n_labels)
```

### 2. Handling Many Colors

```r
# If you need more colors than available:

# Option 1: Use gradient interpolation
many_colors <- hough_palette_gradient(100, "contrast")

# Option 2: Let cycling happen naturally
many_colors <- hough_palette(50, "contrast")  # Cycles after 19

# Option 3: Mix both palettes
full_colors <- hough_palette(20, "full")
contrast_colors <- hough_palette(19, "contrast")
combined <- c(full_colors, contrast_colors)  # 39 unique colors
```

### 3. Transparency for Overlays

```r
# Semi-transparent gradient for overlay visualization
overlay_gradient <- hough_palette_gradient(50, "full", alpha = 0.6)

# Fully opaque for primary visualization
primary_colors <- hough_palette(10, "contrast")  # Default alpha = 1.0
```

### 4. Consistent Color Assignment

```r
# Assign colors based on shape ID (not detection order)
# This ensures same shape gets same color across runs

assign_colors_by_id <- function(shape_ids, palette_type = "contrast") {
  unique_ids <- sort(unique(shape_ids))
  n_shapes <- length(unique_ids)
  
  # Get colors for all unique IDs
  palette <- hough_palette(n_shapes, palette_type)
  
  # Create mapping: ID -> Color
  color_map <- setNames(palette, unique_ids)
  
  # Apply to all points
  colors <- color_map[as.character(shape_ids)]
  return(colors)
}
```

---

## Integration with lidR

The palette functions integrate seamlessly with `lidR` point cloud visualization:

```r
library(houghPrimitives)
library(lidR)

# Detect shapes
result <- detect_spheres(points, label_points = TRUE)

# Assign colors using palette
if (result$n_spheres > 0) {
  sphere_colors <- hough_palette(result$n_spheres, "contrast")
  
  # Create LAS with colored spheres
  las <- LAS(data.frame(
    X = points[,1],
    Y = points[,2],
    Z = points[,3],
    SphereID = result$point_labels
  ))
  
  # Plot with automatic color mapping
  plot(las, color = "SphereID", size = 3)
  
  # Or manually apply colors
  las$RGB <- sphere_colors[result$point_labels]
  plot(las, color = "RGB", size = 3)
}
```

---

## Summary

The `houghPrimitives` color palette system provides:

✅ **Flexible color generation** - Variable number of colors  
✅ **Two distinct palettes** - Sequential and categorical  
✅ **Smooth gradients** - Interpolated color ramps  
✅ **High-contrast pairs** - Optimized for labels  
✅ **Automatic cycling** - Handles any requested size  
✅ **Transparency support** - Alpha channel for overlays  
✅ **lidR integration** - Seamless point cloud coloring  

Use these functions to create consistent, visually appealing visualizations of your point cloud detection results!
