# Multi-Shape Scene Classification

## Introduction

Real-world point clouds often contain **multiple shape types**
coexisting in the same scene:

  - **Urban environments**: Buildings (planes/cuboids), trees
    (cylinders), street furniture (spheres), power lines (lines)
  - **Industrial facilities**: Tanks (cylinders/spheres), pipes
    (cylinders/lines), structural beams (lines), walls (planes)
  - **Forestry**: Trees (cylinders), terrain (planes), rocks (spheres),
    fallen logs (cylinders/lines)

This vignette demonstrates how to classify all shapes in a complex scene
using the `houghPrimitives` package.

## Key Principle: Detection Order Matters

**Critical insight:** The order in which you detect shapes significantly
impacts results because:

1.  Each detection “consumes” points from the cloud
2.  Dominant features (planes) can mask smaller features (lines)
3.  Some shapes are subsets of others (cube edges vs standalone lines)

### Recommended Detection Order

``` r
# OPTIMAL ORDER for most complex scenes:

# 1. Spheres - Compact, geometrically distinct
spheres <- detect_spheres(xyz, ...)

# 2. Cylinders - Elongated, less common than planes
cylinders <- detect_cylinders(xyz, ...)

# 3. Lines - Thin features (BEFORE planes!)
lines <- detect_lines(xyz, in_scene = TRUE, ...)

# 4. Planes - Large, dominant features
planes <- detect_planes(xyz, ...)

# 5. Cubes/Cuboids - Composite structures (last)
cubes <- detect_cubes(xyz, ...)
cuboids <- detect_cuboids(xyz, ...)
```

**Why this order?** - Detect **distinctive/rare shapes first** (spheres,
cylinders) - Detect **thin features before dominant ones** (lines before
planes) - Detect **composite shapes last** (cubes/cuboids depend on
plane detection)

## Complete Classification Workflow

### Step 1: Load and Summarize Data

``` r
library(houghPrimitives)

# Load point cloud (as N x 3 matrix)
# xyz <- load_your_data()

# Get basic statistics
summary <- summarize_points(xyz)
print(summary)

# Output shows:
# - n_points: total count
# - bbox: x/y/z min/max
# - centroid: center point
# - extent: dimensions
```

### Step 2: Sequential Shape Detection

``` r
# Initialize results list
shapes <- list()

# 1. SPHERES
cat("Detecting spheres...\n")
shapes$spheres <- detect_spheres(
  xyz,
  min_radius = 0.5,
  max_radius = 2.0,
  min_votes = 50,
  label_points = TRUE
)
cat(sprintf("  Found %d spheres\n", shapes$spheres$n_spheres))

# 2. CYLINDERS
cat("Detecting cylinders...\n")
shapes$cylinders <- detect_cylinders(
  xyz,
  min_radius = 0.2,
  max_radius = 0.5,
  min_length = 2.0,
  min_votes = 80,
  label_points = TRUE
)
cat(sprintf("  Found %d cylinders\n", shapes$cylinders$n_cylinders))

# 3. LINES (strict mode for complex scenes)
cat("Detecting lines...\n")
shapes$lines <- detect_lines(
  xyz,
  distance_threshold = 0.05,
  min_votes = 40,
  min_length = 2.0,
  in_scene = TRUE,  # Strict mode
  label_points = TRUE
)
cat(sprintf("  Found %d lines\n", shapes$lines$n_lines))

# 4. PLANES
cat("Detecting planes...\n")
shapes$planes <- detect_planes(
  xyz,
  distance_threshold = 0.10,
  min_votes = 150,
  max_iterations = 800,
  label_points = TRUE
)
cat(sprintf("  Found %d planes\n", shapes$planes$n_planes))

# 5. CUBES (optional, complex)
cat("Detecting cubes...\n")
shapes$cubes <- detect_cubes(
  xyz,
  min_size = 1.0,
  max_size = 5.0,
  min_votes = 200,
  label_points = TRUE
)
cat(sprintf("  Found %d cubes\n", shapes$cubes$n_cubes))
```

### Step 3: Combine Point Labels

``` r
# Create unified classification
n_points <- nrow(xyz)
point_shape_type <- rep(0, n_points)  # 0 = unclassified
point_shape_id <- rep(0, n_points)    # 0 = no shape

# Shape type codes
SPHERE <- 1
CYLINDER <- 2
LINE <- 3
PLANE <- 4
CUBE <- 5

# Assign labels (last assignment wins for overlaps)
if (shapes$spheres$n_spheres > 0) {
  mask <- shapes$spheres$point_labels > 0
  point_shape_type[mask] <- SPHERE
  point_shape_id[mask] <- shapes$spheres$point_labels[mask]
}

if (shapes$cylinders$n_cylinders > 0) {
  mask <- shapes$cylinders$point_labels > 0
  point_shape_type[mask] <- CYLINDER
  point_shape_id[mask] <- shapes$cylinders$point_labels[mask]
}

if (shapes$lines$n_lines > 0) {
  mask <- shapes$lines$point_labels > 0
  point_shape_type[mask] <- LINE
  point_shape_id[mask] <- shapes$lines$point_labels[mask]
}

if (shapes$planes$n_planes > 0) {
  mask <- shapes$planes$point_labels > 0
  point_shape_type[mask] <- PLANE
  point_shape_id[mask] <- shapes$planes$point_labels[mask]
}

if (shapes$cubes$n_cubes > 0) {
  mask <- shapes$cubes$point_labels > 0
  point_shape_type[mask] <- CUBE
  point_shape_id[mask] <- shapes$cubes$point_labels[mask]
}

# Summary statistics
cat("\n=== Classification Summary ===\n")
cat(sprintf("Total points: %d\n", n_points))
cat(sprintf("Spheres: %d points (%.1f%%)\n", 
            sum(point_shape_type == SPHERE),
            100 * sum(point_shape_type == SPHERE) / n_points))
cat(sprintf("Cylinders: %d points (%.1f%%)\n", 
            sum(point_shape_type == CYLINDER),
            100 * sum(point_shape_type == CYLINDER) / n_points))
cat(sprintf("Lines: %d points (%.1f%%)\n", 
            sum(point_shape_type == LINE),
            100 * sum(point_shape_type == LINE) / n_points))
cat(sprintf("Planes: %d points (%.1f%%)\n", 
            sum(point_shape_type == PLANE),
            100 * sum(point_shape_type == PLANE) / n_points))
cat(sprintf("Cubes: %d points (%.1f%%)\n", 
            sum(point_shape_type == CUBE),
            100 * sum(point_shape_type == CUBE) / n_points))
cat(sprintf("Unclassified: %d points (%.1f%%)\n", 
            sum(point_shape_type == 0),
            100 * sum(point_shape_type == 0) / n_points))
```

### Step 4: Visualization with lidR

``` r
library(lidR)

# Create LAS object with classifications
las <- LAS(data.frame(
  X = xyz[, 1],
  Y = xyz[, 2],
  Z = xyz[, 3],
  ShapeType = point_shape_type,
  ShapeID = point_shape_id
))

# Visualize by shape type
plot(las, color = "ShapeType", size = 3,
     main = "Point Cloud Classification by Shape Type")

# Visualize individual shapes
plot(las, color = "ShapeID", size = 3,
     main = "Individual Shape Instances")
```

## Complete Example: Synthetic Mixed Scene

``` r
library(houghPrimitives)
set.seed(123)

# ============================================================================
# GENERATE SYNTHETIC SCENE
# ============================================================================

# Helper function: Generate sphere
generate_sphere <- function(cx, cy, cz, radius, n_points = 200) {
  theta <- runif(n_points, 0, 2 * pi)
  phi <- acos(2 * runif(n_points) - 1)
  x <- cx + radius * sin(phi) * cos(theta)
  y <- cy + radius * sin(phi) * sin(theta)
  z <- cz + radius * cos(phi)
  cbind(x, y, z)
}

# Helper function: Generate cylinder
generate_cylinder <- function(cx, cy, z1, z2, radius, n_points = 250) {
  theta <- runif(n_points, 0, 2 * pi)
  z <- runif(n_points, z1, z2)
  x <- cx + radius * cos(theta)
  y <- cy + radius * sin(theta)
  cbind(x, y, z)
}

# Helper function: Generate plane
generate_plane <- function(z_level, xrange, yrange, n_points = 400) {
  x <- runif(n_points, xrange[1], xrange[2])
  y <- runif(n_points, yrange[1], yrange[2])
  z <- rep(z_level, n_points) + rnorm(n_points, sd = 0.02)
  cbind(x, y, z)
}

# Helper function: Generate line
generate_line <- function(x1, y1, z1, x2, y2, z2, n_points = 100, noise = 0.02) {
  t <- runif(n_points, 0, 1)
  x <- x1 + t * (x2 - x1) + rnorm(n_points, sd = noise)
  y <- y1 + t * (y2 - y1) + rnorm(n_points, sd = noise)
  z <- z1 + t * (z2 - z1) + rnorm(n_points, sd = noise)
  cbind(x, y, z)
}

# Create scene components
cat("Generating synthetic scene...\n")

# Ground plane
ground <- generate_plane(0, c(0, 20), c(0, 20), n_points = 500)

# 2 spheres
sphere1 <- generate_sphere(5, 5, 2, radius = 0.8, n_points = 200)
sphere2 <- generate_sphere(15, 15, 1.5, radius = 1.0, n_points = 250)

# 3 cylinders (poles)
cyl1 <- generate_cylinder(10, 5, 0, 5, radius = 0.3, n_points = 300)
cyl2 <- generate_cylinder(5, 15, 0, 4.5, radius = 0.35, n_points = 280)
cyl3 <- generate_cylinder(15, 8, 0, 6, radius = 0.28, n_points = 320)

# 2 lines (cables)
line1 <- generate_line(0, 8, 5, 20, 10, 5.5, n_points = 120, noise = 0.015)
line2 <- generate_line(3, 0, 4.5, 17, 20, 4.8, n_points = 140, noise = 0.015)

# Wall (vertical plane)
wall <- cbind(
  rep(18, 300),
  runif(300, 5, 15),
  runif(300, 0, 5)
)

# Uniform noise
noise <- cbind(runif(200, 0, 20), runif(200, 0, 20), runif(200, 0, 6))

# Combine all
scene <- rbind(
  ground, sphere1, sphere2,
  cyl1, cyl2, cyl3,
  line1, line2, wall, noise
)

cat(sprintf("Scene created: %d points\n", nrow(scene)))
cat(sprintf("  Ground: %d\n", nrow(ground)))
cat(sprintf("  Spheres: %d (2 objects)\n", nrow(sphere1) + nrow(sphere2)))
cat(sprintf("  Cylinders: %d (3 objects)\n", nrow(cyl1) + nrow(cyl2) + nrow(cyl3)))
cat(sprintf("  Lines: %d (2 objects)\n", nrow(line1) + nrow(line2)))
cat(sprintf("  Wall: %d\n", nrow(wall)))
cat(sprintf("  Noise: %d\n", nrow(noise)))

# ============================================================================
# CLASSIFY ALL SHAPES
# ============================================================================

cat("\n=== SHAPE DETECTION ===\n")

# 1. Spheres
spheres <- detect_spheres(scene, 
                         min_radius = 0.6, max_radius = 1.2,
                         min_votes = 80, label_points = TRUE)
cat(sprintf("Spheres: %d detected\n", spheres$n_spheres))

# 2. Cylinders
cylinders <- detect_cylinders(scene,
                              min_radius = 0.25, max_radius = 0.4,
                              min_length = 3.0, min_votes = 100,
                              label_points = TRUE)
cat(sprintf("Cylinders: %d detected\n", cylinders$n_cylinders))

# 3. Lines (strict mode)
lines <- detect_lines(scene,
                      distance_threshold = 0.04, min_votes = 50,
                      min_length = 3.0, in_scene = TRUE,
                      label_points = TRUE)
cat(sprintf("Lines: %d detected\n", lines$n_lines))

# 4. Planes
planes <- detect_planes(scene,
                        distance_threshold = 0.08, min_votes = 120,
                        max_iterations = 800, label_points = TRUE)
cat(sprintf("Planes: %d detected\n", planes$n_planes))

# ============================================================================
# COMBINE CLASSIFICATIONS
# ============================================================================

# Create unified labels
classification <- rep("Unclassified", nrow(scene))
classification[spheres$point_labels > 0] <- "Sphere"
classification[cylinders$point_labels > 0] <- "Cylinder"
classification[lines$point_labels > 0] <- "Line"
classification[planes$point_labels > 0] <- "Plane"

# Shape codes for lidR
shape_code <- rep(0, nrow(scene))
shape_code[classification == "Sphere"] <- 1
shape_code[classification == "Cylinder"] <- 2
shape_code[classification == "Line"] <- 3
shape_code[classification == "Plane"] <- 4

# Summary
cat("\n=== CLASSIFICATION RESULTS ===\n")
table(classification)
cat(sprintf("\nClassification rate: %.1f%%\n",
            100 * sum(shape_code > 0) / nrow(scene)))

# ============================================================================
# VISUALIZE
# ============================================================================

library(lidR)

las <- LAS(data.frame(
  X = scene[, 1],
  Y = scene[, 2],
  Z = scene[, 3],
  ShapeType = shape_code,
  Classification = factor(classification)
))

# Plot by shape type
plot(las, color = "Classification", size = 3,
     main = "Multi-Shape Scene Classification")
```

## 3D Visualization Example

Here’s a complete example with synthetic data and 3D visualization:

``` r
library(rgl)

# Generate synthetic multi-shape scene
set.seed(456)

# Helper functions
generate_sphere <- function(cx, cy, cz, radius, n_points = 150) {
  theta <- runif(n_points, 0, 2 * pi)
  phi <- acos(2 * runif(n_points) - 1)
  x <- cx + radius * sin(phi) * cos(theta)
  y <- cy + radius * sin(phi) * sin(theta)
  z <- cz + radius * cos(phi)
  cbind(x, y, z)
}

generate_cylinder <- function(cx, cy, z1, z2, radius, n_points = 200) {
  theta <- runif(n_points, 0, 2 * pi)
  z <- runif(n_points, z1, z2)
  x <- cx + radius * cos(theta)
  y <- cy + radius * sin(theta)
  cbind(x, y, z)
}

generate_plane <- function(z_level, xrange, yrange, n_points = 300) {
  x <- runif(n_points, xrange[1], xrange[2])
  y <- runif(n_points, yrange[1], yrange[2])
  z <- rep(z_level, n_points) + rnorm(n_points, sd = 0.02)
  cbind(x, y, z)
}

# Create scene components
ground <- generate_plane(0, c(0, 10), c(0, 10), n_points = 400)
sphere1 <- generate_sphere(2, 2, 1, 0.8, n_points = 200)
sphere2 <- generate_sphere(7, 3, 0.6, 0.6, n_points = 150)
pole <- generate_cylinder(5, 7, 0, 4, 0.3, n_points = 250)

# Combine
all_points <- rbind(ground, sphere1, sphere2, pole)

# Detect shapes in optimal order
spheres <- detect_spheres(all_points, min_radius = 0.4, max_radius = 1.0, 
                          min_votes = 50, label_points = TRUE)
cylinders <- detect_cylinders(all_points, min_radius = 0.2, max_radius = 0.4,
                              min_length = 2.0, min_votes = 80, label_points = TRUE)
planes <- detect_planes(all_points, distance_threshold = 0.05, 
                       min_votes = 150, label_points = TRUE)

# Create classification
classification <- rep(0, nrow(all_points))
classification[spheres$point_labels > 0] <- 1
classification[cylinders$point_labels > 0] <- 2
classification[planes$point_labels > 0] <- 3

# Visualize
open3d()
#> null 
#>    8
shape_colors <- c("gray70", "coral", "steelblue", "forestgreen")
shape_sizes <- c(3, 6, 6, 4)

for (i in 0:3) {
  mask <- classification == i
  if (any(mask)) {
    points3d(all_points[mask, 1], all_points[mask, 2], all_points[mask, 3],
             color = shape_colors[i + 1], size = shape_sizes[i + 1])
  }
}

axes3d()
title3d(sprintf("Multi-Shape: %d Spheres, %d Cylinders, %d Planes",
                spheres$n_spheres, cylinders$n_cylinders, planes$n_planes),
        "X", "Y", "Z")
```

``` r

# Save
fig_path <- save_rgl_snapshot("multi-shape-3d.png", width = 800, height = 600)
#> Error in startup(port = port, ...) : 
#>   Chrome debugging port not open after 10 seconds.
#> Warning in rgl::snapshot3d(filepath, width = width, height = height):
#> webshot2::webshot() failed; trying rgl.snapshot()
close3d()
```

![Multi-shape classification showing detected spheres (coral), cylinder
(blue), and plane (green).](multi-shape-3d.png)

Multi-shape classification showing detected spheres (coral), cylinder
(blue), and plane (green).

## Application: Urban Scene Analysis

``` r
# Real-world workflow for urban LiDAR data

library(lidR)
library(houghPrimitives)

# Load LAS file
las <- readLAS("urban_scene.las")
xyz <- cbind(las$X, las$Y, las$Z)

# Classify shapes
planes <- detect_planes(xyz, 
                       distance_threshold = 0.15,  # Building walls
                       min_votes = 200)

cylinders <- detect_cylinders(xyz,
                              min_radius = 0.15,    # Light poles
                              max_radius = 0.5,
                              min_length = 2.5,
                              min_votes = 100,
                              label_points = TRUE)

lines <- detect_lines(xyz,
                     distance_threshold = 0.05,   # Power lines
                     min_votes = 50,
                     in_scene = TRUE,
                     label_points = TRUE)

# Add to LAS
las$IsPole <- as.integer(cylinders$point_labels > 0)
las$IsCable <- as.integer(lines$point_labels > 0)

# Export classified point cloud
writeLAS(las, "urban_classified.las")
```

## Application: Forestry Inventory

``` r
# Forest scene with trees and terrain

library(houghPrimitives)

# Load forest point cloud
# xyz <- load_forest_data()

# Detect ground
ground <- detect_planes(xyz,
                       distance_threshold = 0.1,
                       min_votes = 300,
                       label_points = TRUE)

# Detect tree boles (specialized cylinder detection)
trees <- detect_tree_boles(xyz,
                          min_radius = 0.05,
                          max_radius = 0.5,
                          min_height = 1.5,
                          vertical_only = TRUE,
                          label_points = TRUE)

# Classification
terrain_mask <- ground$point_labels > 0
vegetation_mask <- trees$point_labels > 0

cat(sprintf("Ground points: %d (%.1f%%)\n",
            sum(terrain_mask), 100 * sum(terrain_mask) / nrow(xyz)))
cat(sprintf("Tree points: %d (%.1f%%)\n",
            sum(vegetation_mask), 100 * sum(vegetation_mask) / nrow(xyz)))
cat(sprintf("Trees detected: %d\n", trees$n_trees))
```

## Performance Tips for Large Scenes

### 1\. Spatial Subdivision

``` r
# For very large point clouds, process in tiles

library(dplyr)

# Divide into 10x10 meter tiles
xyz_df <- data.frame(xyz)
xyz_df$tile_x <- floor(xyz_df[,1] / 10)
xyz_df$tile_y <- floor(xyz_df[,2] / 10)

# Process each tile
results_list <- list()

for (tx in unique(xyz_df$tile_x)) {
  for (ty in unique(xyz_df$tile_y)) {
    tile_data <- xyz_df %>%
      filter(tile_x == tx, tile_y == ty) %>%
      select(1:3) %>%
      as.matrix()
    
    # Detect shapes in tile
    result <- detect_spheres(tile_data, label_points = TRUE)
    results_list[[paste(tx, ty, sep = "_")]] <- result
  }
}

# Merge results
```

### 2\. Adaptive Parameters

``` r
# Adjust parameters based on point density

density <- nrow(xyz) / (diff(range(xyz[,1])) * diff(range(xyz[,2])))

if (density > 100) {  # Dense
  min_votes_spheres <- 80
  min_votes_planes <- 200
} else if (density > 50) {  # Medium
  min_votes_spheres <- 50
  min_votes_planes <- 150
} else {  # Sparse
  min_votes_spheres <- 30
  min_votes_planes <- 100
}

# Use adaptive parameters
spheres <- detect_spheres(xyz, min_votes = min_votes_spheres)
planes <- detect_planes(xyz, min_votes = min_votes_planes)
```

## Troubleshooting Multi-Shape Scenes

### Problem: Shapes missed or over-detected

**Solution:** Tune parameters for each shape type independently

``` r
# Test each detector separately first
spheres_test <- detect_spheres(xyz, min_votes = 30)
cylinders_test <- detect_cylinders(xyz, min_votes = 60)
lines_test <- detect_lines(xyz, min_votes = 40, in_scene = FALSE)
planes_test <- detect_planes(xyz, min_votes = 100)

# Adjust parameters based on individual results
# Then run full sequential classification
```

### Problem: Overlapping classifications

**Solution:** Define priority order for overlaps

``` r
# Apply labels with priority (higher priority overwrites)
priority_order <- c("planes", "lines", "cylinders", "spheres")

for (shape_type in priority_order) {
  # Apply labels for this shape type
  # ...
}
```

## Summary

Multi-shape scene classification requires:

✓ **Correct detection order**: Distinctive shapes first, dominant shapes
later  
✓ **Shape-specific parameters**: Tune each detector independently  
✓ **Context awareness**: Use `in_scene = TRUE` for lines in complex
scenes  
✓ **Unified labeling**: Combine results with clear priority rules  
✓ **Validation**: Check results against expectations

**Recommended workflow:** 1. Spheres → 2. Cylinders → 3. Lines → 4.
Planes → 5. Cubes/Cuboids

**Critical insights:** - Detect **lines BEFORE planes** to avoid false
positives from edges - Use **strict mode** (`in_scene = TRUE`) for lines
in multi-shape scenes - **Validate** each detection step before
proceeding - **Visualize** results with lidR for quality control
