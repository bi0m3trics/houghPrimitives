## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

# Load package
library(houghPrimitives)

# Setup rgl for headless rendering (required for CRAN checks and CI)
if (requireNamespace("rgl", quietly = TRUE)) {
  setup_rgl_knitr()
}

## ----eval=FALSE---------------------------------------------------------------
# library(houghPrimitives)
# 
# # Detect lines
# result <- detect_lines(
#   xyz = point_matrix,       # N x 3 matrix
#   distance_threshold = 0.05, # Max distance from line
#   min_votes = 30,           # Min points per line
#   min_length = 1.0,         # Min line length (meters)
#   max_iterations = 500,     # RANSAC iterations
#   in_scene = TRUE,          # Context mode
#   label_points = FALSE      # Return labels?
# )
# 
# cat("Detected", result$n_lines, "lines\n")
# print(result$lines)

## ----eval=FALSE---------------------------------------------------------------
# # Thin features (cables)
# detect_lines(xyz, distance_threshold = 0.02)  # 2cm
# 
# # Thicker features (beams)
# detect_lines(xyz, distance_threshold = 0.10)  # 10cm
# 
# # Noisy data
# detect_lines(xyz, distance_threshold = 0.15)  # 15cm

## ----eval=FALSE---------------------------------------------------------------
# # Dense point clouds
# detect_lines(xyz, min_votes = 50)
# 
# # Sparse or thin features
# detect_lines(xyz, min_votes = 20)

## ----eval=FALSE---------------------------------------------------------------
# # Short segments acceptable
# detect_lines(xyz, min_length = 0.5)  # 50cm
# 
# # Only long features
# detect_lines(xyz, min_length = 5.0)  # 5 meters

## ----eval=FALSE---------------------------------------------------------------
# # Quick scan
# detect_lines(xyz, max_iterations = 300)
# 
# # Thorough search
# detect_lines(xyz, max_iterations = 1000)

## ----eval=FALSE---------------------------------------------------------------
# # Line-only scene (cables, wires)
# detect_lines(cables, in_scene = FALSE)  # Aggressive
# 
# # Complex scene (buildings + cables)
# detect_lines(urban_scan, in_scene = TRUE)  # Strict

## ----eval=FALSE---------------------------------------------------------------
# library(houghPrimitives)
# 
# # Example: Cable/power line scan
# # Point cloud contains primarily cables with some measurement noise
# 
# # Use aggressive mode
# result <- detect_lines(
#   cable_points,
#   distance_threshold = 0.05,
#   min_votes = 30,
#   min_length = 2.0,
#   max_iterations = 1000,
#   in_scene = FALSE  # ← Line-only mode
# )
# 
# cat("Detected", result$n_lines, "cables\n")
# 
# # Internally, parameters are relaxed:
# # - distance_threshold → 0.065 (30% increase)
# # - min_votes → 21 (70% of 30)
# # - min_length → 1.6 (80% of 2.0)
# # - max_iterations → 1500 (50% increase)

## ----eval=FALSE---------------------------------------------------------------
# # Example: Urban scene with buildings and standalone cables
# 
# # STEP 1: Detect dominant features first
# planes <- detect_planes(
#   urban_points,
#   distance_threshold = 0.10,
#   min_votes = 150,
#   label_points = TRUE
# )
# cat("Found", planes$n_planes, "planes\n")
# 
# # STEP 2: Detect cylinders (poles)
# cylinders <- detect_cylinders(
#   urban_points,
#   min_radius = 0.2,
#   max_radius = 0.4,
#   min_length = 3.0,
#   min_votes = 80,
#   label_points = TRUE
# )
# cat("Found", cylinders$n_cylinders, "poles\n")
# 
# # STEP 3: Detect standalone lines from remaining points
# lines <- detect_lines(
#   urban_points,
#   distance_threshold = 0.06,
#   min_votes = 40,
#   min_length = 2.5,
#   max_iterations = 1000,
#   in_scene = TRUE,  # ← Strict mode for complex scenes
#   label_points = TRUE
# )
# cat("Found", lines$n_lines, "standalone lines\n")

## ----eval=FALSE---------------------------------------------------------------
# result <- detect_lines(xyz, label_points = TRUE)
# 
# # Number of lines detected
# result$n_lines  # Integer
# 
# # Line parameters (data.frame)
# result$lines
# #   line_id: 1, 2, 3...
# #   x1, y1, z1: start point
# #   x2, y2, z2: end point
# #   length: 3D Euclidean length
# #   n_points: number of points on this line
# 
# # Point labels (if requested)
# result$point_labels  # Integer vector: 0 = not a line, 1,2,3... = line ID

## ----eval=FALSE---------------------------------------------------------------
# set.seed(42)
# 
# # Generate random 3D line
# generate_line <- function(x1, y1, z1, x2, y2, z2, n_points = 100, noise = 0.02) {
#   t <- runif(n_points, 0, 1)
#   x <- x1 + t * (x2 - x1) + rnorm(n_points, sd = noise)
#   y <- y1 + t * (y2 - y1) + rnorm(n_points, sd = noise)
#   z <- z1 + t * (z2 - z1) + rnorm(n_points, sd = noise)
#   cbind(x, y, z)
# }
# 
# # Create 3 lines
# line1 <- generate_line(0, 0, 0, 10, 5, 3, n_points = 120)
# line2 <- generate_line(5, 10, 1, 15, 15, 5, n_points = 100)
# line3 <- generate_line(2, 2, 4, 8, 12, 6, n_points = 150)
# 
# # Add noise
# noise <- cbind(runif(100, 0, 20), runif(100, 0, 20), runif(100, 0, 6))
# 
# # Combine
# all_points <- rbind(line1, line2, line3, noise)
# 
# # Detect with aggressive mode (line-only)
# result <- detect_lines(
#   all_points,
#   distance_threshold = 0.05,
#   min_votes = 30,
#   min_length = 2.0,
#   in_scene = FALSE,  # Line-only mode
#   label_points = TRUE
# )
# 
# cat("Detected", result$n_lines, "/ 3 lines\n")
# print(result$lines)

## ----eval=FALSE---------------------------------------------------------------
# # Infrastructure, cables, wire scans
# lines <- detect_lines(
#   xyz,
#   distance_threshold = 0.05,  # Adjust to feature thickness
#   min_votes = 30,             # Based on point density
#   min_length = 2.0,           # Minimum interesting length
#   max_iterations = 1000,      # Thorough search
#   in_scene = FALSE            # ← Aggressive mode
# )

## ----eval=FALSE---------------------------------------------------------------
# # Order matters! Detect in this sequence:
# 
# # 1. Planes (walls, ground, roofs)
# planes <- detect_planes(xyz, min_votes = 150, label_points = TRUE)
# 
# # 2. Spheres (if present)
# spheres <- detect_spheres(xyz, min_votes = 50, label_points = TRUE)
# 
# # 3. Cylinders (poles, tree boles)
# cylinders <- detect_cylinders(xyz, min_votes = 80, label_points = TRUE)
# 
# # 4. Lines (standalone cables, edges)
# lines <- detect_lines(
#   xyz,
#   distance_threshold = 0.06,
#   min_votes = 40,
#   in_scene = TRUE,  # ← Strict mode
#   label_points = TRUE
# )
# 
# # 5. Cubes/cuboids (if needed)
# cubes <- detect_cubes(xyz, min_votes = 200, label_points = TRUE)

## ----eval=FALSE---------------------------------------------------------------
# library(lidR)
# 
# # Detect lines
# result <- detect_lines(xyz, in_scene = FALSE, label_points = TRUE)
# 
# # Create LAS with line labels
# las <- LAS(data.frame(
#   X = xyz[, 1],
#   Y = xyz[, 2],
#   Z = xyz[, 3],
#   LineID = result$point_labels,
#   IsLine = as.integer(result$point_labels > 0)
# ))
# 
# # Visualize by line ID
# plot(las, color = "LineID", size = 4)
# 
# # Or just lines vs non-lines
# plot(las, color = "IsLine", size = 4)

## ----line-3d-viz, echo = TRUE-------------------------------------------------
library(rgl)

# Generate synthetic lines
set.seed(123)

generate_line <- function(x1, y1, z1, x2, y2, z2, n_points = 100, noise = 0.02) {
  t <- runif(n_points, 0, 1)
  x <- x1 + t * (x2 - x1) + rnorm(n_points, sd = noise)
  y <- y1 + t * (y2 - y1) + rnorm(n_points, sd = noise)
  z <- z1 + t * (z2 - z1) + rnorm(n_points, sd = noise)
  cbind(x, y, z)
}

# Create 3 lines in different orientations
line1 <- generate_line(0, 0, 0, 5, 1, 2, n_points = 120)  # Diagonal
line2 <- generate_line(1, 4, 0, 1, 4, 5, n_points = 100)  # Vertical
line3 <- generate_line(3, 1, 1, 8, 3, 1.5, n_points = 150)  # Horizontal

# Add random noise
noise_pts <- cbind(runif(80, 0, 8), runif(80, 0, 5), runif(80, 0, 5))

# Combine
all_points <- rbind(line1, line2, line3, noise_pts)

# Detect lines
result <- detect_lines(
  all_points,
  distance_threshold = 0.05,
  min_votes = 30,
  min_length = 1.5,
  in_scene = FALSE,
  label_points = TRUE
)

# Visualize results
open3d()
colors <- c("gray80", "steelblue", "coral", "forestgreen", "gold")

for (i in 0:result$n_lines) {
  mask <- result$point_labels == i
  points3d(all_points[mask, 1], all_points[mask, 2], all_points[mask, 3],
           color = colors[i + 1], size = ifelse(i == 0, 3, 6))
}

axes3d()
title3d(sprintf("Detected %d Lines", result$n_lines), "X", "Y", "Z")

# Save snapshot
fig_path <- save_rgl_snapshot("line-detection-3d.png", width = 800, height = 600)
close3d()

## ----show-line-3d, echo = FALSE, out.width = "100%", fig.cap = "Line detection results showing three detected lines in different orientations."----
knitr::include_graphics(fig_path)

## ----eval=FALSE---------------------------------------------------------------
# # 1. Relax parameters
# result <- detect_lines(xyz, min_votes = 20, distance_threshold = 0.08)
# 
# # 2. Use aggressive mode
# result <- detect_lines(xyz, in_scene = FALSE)
# 
# # 3. Increase iterations
# result <- detect_lines(xyz, max_iterations = 1500)

## ----eval=FALSE---------------------------------------------------------------
# # Lower min_votes
# result <- detect_lines(xyz, min_votes = 20)
# 
# # Increase distance_threshold slightly
# result <- detect_lines(xyz, distance_threshold = 0.08)
# 
# # Post-process to merge collinear segments
# # (custom function to merge nearby collinear lines)

## ----eval=FALSE---------------------------------------------------------------
# # Detect planes FIRST
# planes <- detect_planes(xyz, label_points = TRUE)
# 
# # Then detect lines in strict mode
# lines <- detect_lines(xyz, in_scene = TRUE, label_points = TRUE)

## ----eval=FALSE---------------------------------------------------------------
# # Reduce distance threshold
# result <- detect_lines(xyz, distance_threshold = 0.03)

## ----eval=FALSE---------------------------------------------------------------
# result <- detect_lines(xyz, label_points = TRUE)
# 
# # Calculate line directions
# lines <- result$lines
# dx <- lines$x2 - lines$x1
# dy <- lines$y2 - lines$y1
# dz <- lines$z2 - lines$z1
# len <- sqrt(dx^2 + dy^2 + dz^2)
# 
# # Unit direction vectors
# ux <- dx / len
# uy <- dy / len
# uz <- dz / len
# 
# # Filter nearly horizontal lines (|uz| < 0.2)
# horizontal_mask <- abs(uz) < 0.2
# horizontal_lines <- lines[horizontal_mask, ]
# 
# cat("Found", nrow(horizontal_lines), "horizontal lines\n")
# 
# # Filter nearly vertical lines (|uz| > 0.9)
# vertical_mask <- abs(uz) > 0.9
# vertical_lines <- lines[vertical_mask, ]
# 
# cat("Found", nrow(vertical_lines), "vertical lines\n")

## ----eval=FALSE---------------------------------------------------------------
# # Fast (but may miss some lines)
# detect_lines(xyz, max_iterations = 300, min_votes = 50)
# 
# # Thorough (slower but more complete)
# detect_lines(xyz, max_iterations = 2000, min_votes = 20)
# 
# # For large point clouds, consider spatial subdivision
# # Detect lines in tiles, then merge results

