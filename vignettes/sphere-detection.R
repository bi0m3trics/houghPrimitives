## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5,
  out.width = "80%",
  fig.align = "center"
)

# Load package
library(houghPrimitives)

# Setup rgl for headless rendering (required for CRAN checks and CI)
# This enables 3D visualizations without requiring a display device
if (requireNamespace("rgl", quietly = TRUE)) {
  setup_rgl_knitr()  # Sets rgl.useNULL = TRUE + knitr hooks
}

## ----eval=FALSE---------------------------------------------------------------
# library(houghPrimitives)
# 
# # Detect spheres in point cloud
# result <- detect_spheres(
#   xyz = point_matrix,  # N x 3 matrix (x, y, z)
#   min_radius = 0.5,    # Minimum sphere radius
#   max_radius = 2.0,    # Maximum sphere radius
#   min_votes = 50,      # Minimum points per sphere
#   label_points = FALSE # Return point labels?
# )
# 
# # Check results
# cat("Detected", result$n_spheres, "spheres\n")
# print(result$spheres)

## ----eval=FALSE---------------------------------------------------------------
# # Small objects (cm scale)
# detect_spheres(xyz, min_radius = 0.01, max_radius = 0.1)
# 
# # Medium objects (dm to m scale)
# detect_spheres(xyz, min_radius = 0.5, max_radius = 2.0)
# 
# # Large structures (m scale)
# detect_spheres(xyz, min_radius = 2.0, max_radius = 10.0)

## ----eval=FALSE---------------------------------------------------------------
# # Dense point cloud → higher threshold
# detect_spheres(xyz, min_votes = 100)  # Strict
# 
# # Sparse point cloud → lower threshold
# detect_spheres(xyz, min_votes = 30)   # Permissive
# 
# # Balance quality vs completeness
# detect_spheres(xyz, min_votes = 50)   # Moderate

## ----eval=FALSE---------------------------------------------------------------
# # Get point labels
# result <- detect_spheres(xyz, label_points = TRUE)
# 
# # Labels are 0 (not a sphere) or 1, 2, 3... (sphere ID)
# labels <- result$point_labels
# 
# # Count points per sphere
# table(labels[labels > 0])

## ----eval=FALSE---------------------------------------------------------------
# result <- detect_spheres(xyz, label_points = TRUE)
# 
# # Number of spheres detected
# result$n_spheres  # Integer
# 
# # Sphere parameters (data.frame)
# result$spheres
# #   sphere_id: 1, 2, 3...
# #   x, y, z: center coordinates
# #   radius: sphere radius
# #   n_points: number of points in this sphere
# 
# # Point labels (if requested)
# result$point_labels  # Integer vector, length = nrow(xyz)

## ----eval=FALSE---------------------------------------------------------------
# library(houghPrimitives)
# set.seed(42)
# 
# # Function to generate sphere surface points
# generate_sphere <- function(cx, cy, cz, radius, n_points = 200) {
#   # Uniform distribution on sphere surface
#   theta <- runif(n_points, 0, 2 * pi)
#   phi <- acos(2 * runif(n_points) - 1)
# 
#   x <- cx + radius * sin(phi) * cos(theta)
#   y <- cy + radius * sin(phi) * sin(theta)
#   z <- cz + radius * cos(phi)
# 
#   cbind(x, y, z)
# }
# 
# # Generate 3 spheres
# sphere1 <- generate_sphere(5, 5, 3, radius = 1.2, n_points = 300)
# sphere2 <- generate_sphere(12, 8, 2.5, radius = 0.8, n_points = 250)
# sphere3 <- generate_sphere(8, 15, 4, radius = 1.5, n_points = 400)
# 
# # Add uniform noise
# noise <- cbind(
#   runif(300, 0, 20),
#   runif(300, 0, 20),
#   runif(300, 0, 6)
# )
# 
# # Combine
# all_points <- rbind(sphere1, sphere2, sphere3, noise)
# 
# # Detect spheres
# result <- detect_spheres(
#   all_points,
#   min_radius = 0.5,
#   max_radius = 2.0,
#   min_votes = 50,
#   label_points = TRUE
# )
# 
# cat("Detected", result$n_spheres, "spheres\n")
# print(result$spheres)
# 
# # Calculate accuracy
# n_sphere_points <- nrow(sphere1) + nrow(sphere2) + nrow(sphere3)
# labels <- result$point_labels
# 
# true_positives <- sum(labels[1:n_sphere_points] > 0)
# precision <- true_positives / sum(labels > 0)
# recall <- true_positives / n_sphere_points
# 
# cat(sprintf("Precision: %.2f%%\n", precision * 100))
# cat(sprintf("Recall: %.2f%%\n", recall * 100))

## ----sphere-detection-3d, eval = requireNamespace("rgl", quietly = TRUE)------
library(rgl)
library(houghPrimitives)

# Generate synthetic spheres with noise (same as above example)
set.seed(42)

generate_sphere <- function(cx, cy, cz, radius, n_points = 200) {
  theta <- runif(n_points, 0, 2 * pi)
  phi <- acos(2 * runif(n_points) - 1)
  x <- cx + radius * sin(phi) * cos(theta)
  y <- cy + radius * sin(phi) * sin(theta)
  z <- cz + radius * cos(phi)
  cbind(x, y, z)
}

sphere1 <- generate_sphere(5, 5, 3, radius = 1.2, n_points = 300)
sphere2 <- generate_sphere(12, 8, 2.5, radius = 0.8, n_points = 250)
sphere3 <- generate_sphere(8, 15, 4, radius = 1.5, n_points = 400)

noise <- cbind(runif(300, 0, 20), runif(300, 0, 20), runif(300, 0, 6))
all_points <- rbind(sphere1, sphere2, sphere3, noise)

# Detect spheres
result <- detect_spheres(all_points, min_radius = 0.5, max_radius = 2.0,
                        min_votes = 50, label_points = TRUE)

# Create 3D visualization
open3d()

# Plot undetected points (gray noise)
noise_mask <- result$point_labels == 0
if (any(noise_mask)) {
  points3d(all_points[noise_mask, 1], 
           all_points[noise_mask, 2], 
           all_points[noise_mask, 3],
           color = "gray", size = 3)
}

# Plot detected sphere points (colored by sphere ID)
if (result$n_spheres > 0) {
  colors <- c("steelblue", "coral", "forestgreen", "gold", "purple")
  
  for (i in 1:result$n_spheres) {
    sphere_mask <- result$point_labels == i
    
    # Points on sphere surface
    points3d(all_points[sphere_mask, 1], 
             all_points[sphere_mask, 2], 
             all_points[sphere_mask, 3],
             color = colors[i], size = 5)
    
    # Overlay detected sphere (semi-transparent)
    sphere_params <- result$spheres[i, ]
    spheres3d(sphere_params$x, 
              sphere_params$y, 
              sphere_params$z,
              radius = sphere_params$radius,
              color = colors[i], alpha = 0.2)
  }
}

axes3d()
title3d(sprintf("Detected %d Spheres", result$n_spheres), 
        "X (m)", "Y (m)", "Z (m)")

# Save static PNG snapshot (goes to man/figures/ for pkgdown)
fig_path <- save_rgl_snapshot("sphere-detection-3d.png", 
                              width = 900, height = 700)
close3d()

## ----show-sphere-3d, echo = FALSE, out.width = "100%", fig.cap = "3D visualization of sphere detection results. Detected spheres shown with semi-transparent overlays."----
knitr::include_graphics(fig_path)

## ----sphere-widget, eval = knitr::is_html_output() && requireNamespace("rgl", quietly = TRUE), echo = FALSE----
# Recreate scene for interactive widget
open3d()

noise_mask <- result$point_labels == 0
if (any(noise_mask)) {
  points3d(all_points[noise_mask, 1], 
           all_points[noise_mask, 2], 
           all_points[noise_mask, 3],
           color = "gray", size = 3)
}

if (result$n_spheres > 0) {
  colors <- c("steelblue", "coral", "forestgreen", "gold", "purple")
  for (i in 1:result$n_spheres) {
    sphere_mask <- result$point_labels == i
    points3d(all_points[sphere_mask, 1], 
             all_points[sphere_mask, 2], 
             all_points[sphere_mask, 3],
             color = colors[i], size = 5)
    sphere_params <- result$spheres[i, ]
    spheres3d(sphere_params$x, sphere_params$y, sphere_params$z,
              radius = sphere_params$radius,
              color = colors[i], alpha = 0.2)
  }
}

axes3d()
title3d(sprintf("Detected %d Spheres (Interactive)", result$n_spheres), 
        "X", "Y", "Z")

widget <- create_rgl_widget(width = 800, height = 600)
close3d()

widget

## ----eval=FALSE---------------------------------------------------------------
# # Load point cloud with multiple shape types
# # xyz <- load_your_data()
# 
# # STEP 1: Detect spheres first (they're distinct)
# spheres <- detect_spheres(
#   xyz,
#   min_radius = 0.5,
#   max_radius = 2.0,
#   min_votes = 80,
#   label_points = TRUE
# )
# 
# cat("Found", spheres$n_spheres, "spheres\n")
# 
# # STEP 2: Detect other shapes
# cylinders <- detect_cylinders(xyz, min_votes = 100, label_points = TRUE)
# planes <- detect_planes(xyz, min_votes = 150, label_points = TRUE)
# 
# # Combine labels
# combined_labels <- rep(0, nrow(xyz))
# combined_labels[spheres$point_labels > 0] <- 1  # Sphere
# combined_labels[cylinders$point_labels > 0] <- 2  # Cylinder
# combined_labels[planes$point_labels > 0] <- 3  # Plane

## ----eval=FALSE---------------------------------------------------------------
# library(lidR)
# 
# # Detect spheres
# result <- detect_spheres(xyz, min_votes = 50, label_points = TRUE)
# 
# # Create LAS object
# las <- LAS(data.frame(
#   X = xyz[, 1],
#   Y = xyz[, 2],
#   Z = xyz[, 3],
#   SphereID = result$point_labels,
#   IsSphere = as.integer(result$point_labels > 0)
# ))
# 
# # Visualize by sphere ID
# plot(las, color = "SphereID", size = 3)
# 
# # Visualize sphere vs non-sphere
# plot(las, color = "IsSphere", size = 3)

## ----eval=FALSE---------------------------------------------------------------
# # Assume first N points are sphere points, rest is noise
# n_true_spheres <- 950
# labels <- result$point_labels
# 
# # True positives: sphere points correctly classified
# tp <- sum(labels[1:n_true_spheres] > 0)
# 
# # False positives: noise classified as spheres
# fp <- sum(labels[(n_true_spheres + 1):length(labels)] > 0)
# 
# # False negatives: sphere points missed
# fn <- sum(labels[1:n_true_spheres] == 0)
# 
# precision <- tp / (tp + fp)
# recall <- tp / (tp + fn)
# f1_score <- 2 * (precision * recall) / (precision + recall)
# 
# cat(sprintf("Precision: %.2f%%\n", precision * 100))
# cat(sprintf("Recall: %.2f%%\n", recall * 100))
# cat(sprintf("F1 Score: %.3f\n", f1_score))

## ----eval=FALSE---------------------------------------------------------------
# # Ground truth
# true_center <- c(5, 5, 3)
# true_radius <- 1.2
# 
# # Detected
# detected <- result$spheres[1, ]
# 
# # Center error (Euclidean distance)
# center_error <- sqrt(
#   (detected$x - true_center[1])^2 +
#   (detected$y - true_center[2])^2 +
#   (detected$z - true_center[3])^2
# )
# 
# # Radius error
# radius_error <- abs(detected$radius - true_radius)
# 
# cat(sprintf("Center error: %.3f meters\n", center_error))
# cat(sprintf("Radius error: %.3f meters (%.1f%%)\n",
#             radius_error, 100 * radius_error / true_radius))

## ----eval=FALSE---------------------------------------------------------------
# # Try more permissive parameters
# result <- detect_spheres(
#   xyz,
#   min_radius = 0.1,      # Wider range
#   max_radius = 5.0,
#   min_votes = 20         # Lower threshold
# )
# 
# # Check point cloud summary
# summary_stats <- summarize_points(xyz)
# print(summary_stats)

## ----eval=FALSE---------------------------------------------------------------
# # Increase strictness
# result <- detect_spheres(
#   xyz,
#   min_votes = 100,        # Higher threshold
#   min_radius = 0.8,       # Tighter range
#   max_radius = 1.5
# )

## ----eval=FALSE---------------------------------------------------------------
# # Generate hemisphere (only upper half)
# generate_hemisphere <- function(cx, cy, cz, radius, n_points = 150) {
#   theta <- runif(n_points, 0, 2 * pi)
#   phi <- runif(n_points, 0, pi/2)  # Only upper hemisphere
# 
#   x <- cx + radius * sin(phi) * cos(theta)
#   y <- cy + radius * sin(phi) * sin(theta)
#   z <- cz + radius * cos(phi)
# 
#   cbind(x, y, z)
# }
# 
# hemisphere <- generate_hemisphere(10, 10, 2, radius = 1.0)
# 
# # Detection works but requires fewer octants
# result <- detect_spheres(hemisphere, min_votes = 40)
# # Algorithm uses relaxed octant coverage (3 of 8 octants)

