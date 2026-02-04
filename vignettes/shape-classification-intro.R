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
# # Load your point cloud data (xyz matrix with 3 columns)
# # xyz <- read.csv("your_data.csv")
# 
# # Detect spheres
# spheres_result <- detect_spheres(
#   xyz,
#   min_radius = 0.5,
#   max_radius = 2.0,
#   min_votes = 50
# )
# 
# print(spheres_result$n_spheres)
# print(spheres_result$spheres)

## ----eval=FALSE---------------------------------------------------------------
# # Detect with point labels
# result <- detect_spheres(
#   xyz,
#   min_radius = 0.5,
#   max_radius = 2.0,
#   min_votes = 50,
#   label_points = TRUE
# )
# 
# # Points are labeled with shape IDs
# # 0 = not part of a sphere
# # 1, 2, 3... = sphere ID
# point_labels <- result$point_labels

## ----eval=FALSE---------------------------------------------------------------
# # Recommended detection order:
# # 1. Spheres (compact, distinct features)
# spheres <- detect_spheres(xyz, min_votes = 50, label_points = TRUE)
# 
# # 2. Cylinders (elongated structures)
# cylinders <- detect_cylinders(xyz, min_votes = 80, label_points = TRUE)
# 
# # 3. Lines (thin features - detect BEFORE planes!)
# lines <- detect_lines(xyz, min_votes = 40, in_scene = TRUE, label_points = TRUE)
# 
# # 4. Planes (large, dominant features)
# planes <- detect_planes(xyz, min_votes = 150, label_points = TRUE)
# 
# # 5. Cubes/Cuboids (composite structures)
# cubes <- detect_cubes(xyz, min_votes = 200, label_points = TRUE)

## ----eval=FALSE---------------------------------------------------------------
# result <- detect_spheres(xyz, label_points = TRUE)
# 
# # result$n_spheres: integer (e.g., 3)
# # result$spheres: data.frame with columns:
# #   - sphere_id: 1, 2, 3...
# #   - x, y, z: center coordinates
# #   - radius: sphere radius
# #   - n_points: number of points in this sphere
# # result$point_labels: integer vector (length = nrow(xyz))

## ----eval=FALSE---------------------------------------------------------------
# result <- detect_cylinders(xyz, label_points = TRUE)
# 
# # result$n_cylinders: integer
# # result$cylinders: data.frame with columns:
# #   - cylinder_id: 1, 2, 3...
# #   - x1, y1, z1: start point of axis
# #   - x2, y2, z2: end point of axis
# #   - radius: cylinder radius
# #   - n_points: number of points
# # result$point_labels: integer vector

## ----eval=FALSE---------------------------------------------------------------
# # For urban/building data (meters)
# detect_planes(xyz, distance_threshold = 0.1, min_votes = 100)
# 
# # For forestry data (tree detection)
# detect_tree_boles(xyz, min_radius = 0.1, max_radius = 0.5, min_height = 1.0)
# 
# # For small objects
# detect_spheres(xyz, min_radius = 0.01, max_radius = 0.1, min_votes = 30)

## ----eval=FALSE---------------------------------------------------------------
# library(lidR)
# 
# # Detect shapes
# result <- detect_spheres(xyz, label_points = TRUE)
# 
# # Create LAS object with labels
# las <- LAS(data.frame(
#   X = xyz[, 1],
#   Y = xyz[, 2],
#   Z = xyz[, 3],
#   ShapeID = result$point_labels
# ))
# 
# # Visualize
# plot(las, color = "ShapeID")

## ----eval=FALSE---------------------------------------------------------------
# # Too many false positives?
# # → Increase min_votes, decrease distance_threshold
# 
# # Missing shapes?
# # → Decrease min_votes, increase max_iterations, increase distance_threshold
# 
# # Example progression:
# result1 <- detect_spheres(xyz, min_votes = 50)  # Start
# result2 <- detect_spheres(xyz, min_votes = 30)  # Detect more
# result3 <- detect_spheres(xyz, min_votes = 30, max_iterations = 1500)  # More thorough

## ----eval=FALSE---------------------------------------------------------------
# # Detect vertical cylinders (tree boles)
# trees <- detect_tree_boles(
#   forest_points,
#   min_radius = 0.05,
#   max_radius = 0.5,
#   min_height = 1.0,
#   vertical_only = TRUE
# )
# 
# cat("Detected", trees$n_trees, "trees\n")
# print(trees$trees)

## ----eval=FALSE---------------------------------------------------------------
# # Detect walls and roofs
# planes <- detect_planes(
#   building_points,
#   distance_threshold = 0.1,
#   min_votes = 150
# )
# 
# # Detect rectangular structures
# cuboids <- detect_cuboids(
#   building_points,
#   min_size = 2.0,
#   max_size = 20.0,
#   min_votes = 200
# )

## ----eval=FALSE---------------------------------------------------------------
# # Detect cables/wires
# lines <- detect_lines(
#   cable_points,
#   distance_threshold = 0.05,
#   min_votes = 30,
#   min_length = 2.0,
#   in_scene = FALSE  # Aggressive mode for line-only scenes
# )

## ----intro-3d-viz, echo = TRUE------------------------------------------------
library(rgl)

# Create simple synthetic scene
set.seed(42)

# Generate a cylinder (vertical post)
theta <- seq(0, 2*pi, length.out = 100)
z_vals <- runif(100, 0, 3)
cyl_points <- cbind(
  1 + 0.3 * cos(theta),
  1 + 0.3 * sin(theta),
  z_vals
)

# Generate a plane (ground)
plane_points <- cbind(
  runif(200, 0, 5),
  runif(200, 0, 5),
  rnorm(200, 0, 0.02)
)

# Generate a sphere
phi <- runif(150, 0, 2*pi)
theta2 <- acos(2*runif(150) - 1)
sphere_points <- cbind(
  3.5 + 0.5 * sin(theta2) * cos(phi),
  3.5 + 0.5 * sin(theta2) * sin(phi),
  1.5 + 0.5 * cos(theta2)
)

# Combine all points
all_pts <- rbind(cyl_points, plane_points, sphere_points)

# Visualize
open3d()
points3d(plane_points, color = "gray70", size = 3)
points3d(cyl_points, color = "steelblue", size = 5)
points3d(sphere_points, color = "coral", size = 5)
axes3d()
title3d("Multi-Shape Scene", "X", "Y", "Z")

# Save as static image
fig_path <- save_rgl_snapshot("intro-shapes-3d.png", width = 800, height = 600)
close3d()

## ----show-intro-3d, echo = FALSE, out.width = "100%", fig.cap = "Example multi-shape scene with cylinder, plane, and sphere."----
knitr::include_graphics(fig_path)

