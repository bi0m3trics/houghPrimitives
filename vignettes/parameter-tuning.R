## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

## ----eval=FALSE---------------------------------------------------------------
# # STEP 1: Estimate point density
# bbox <- apply(xyz, 2, range)
# volume <- prod(bbox[2,] - bbox[1,])
# density <- nrow(xyz) / volume
# cat(sprintf("Point density: %.1f points/m³\n", density))
# 
# # STEP 2: Estimate expected points on shape
# # For sphere with radius r: surface_area = 4 * pi * r^2
# expected_sphere_points <- density * 4 * pi * (1.0)^2  # 1m radius
# cat(sprintf("Expected points on 1m sphere: %.0f\n", expected_sphere_points))
# 
# # STEP 3: Set min_votes to 30-50% of expected
# min_votes <- round(expected_sphere_points * 0.4)

## ----eval=FALSE---------------------------------------------------------------
# # Dense scans (>100 pts/m³)
# min_votes_sphere <- 80
# min_votes_cylinder <- 100
# min_votes_plane <- 200
# 
# # Medium density (20-100 pts/m³)
# min_votes_sphere <- 50
# min_votes_cylinder <- 60
# min_votes_plane <- 150
# 
# # Sparse scans (<20 pts/m³)
# min_votes_sphere <- 30
# min_votes_cylinder <- 40
# min_votes_plane <- 100

## ----eval=FALSE---------------------------------------------------------------
# # Based on scanner accuracy and noise
# # Typical values:
# 
# # High-accuracy scanner (mm precision)
# distance_threshold <- 0.02  # 2cm
# 
# # Standard terrestrial scanner (cm precision)
# distance_threshold <- 0.05  # 5cm
# 
# # Airborne/UAV LiDAR
# distance_threshold <- 0.10  # 10cm
# 
# # Mobile mapping / kinematic
# distance_threshold <- 0.15  # 15cm

## ----eval=FALSE---------------------------------------------------------------
# # Calculate noise level from ground plane
# ground_points <- xyz[xyz[,3] < quantile(xyz[,3], 0.1), ]  # Bottom 10%
# ground_fit <- lm(Z ~ X + Y, data = as.data.frame(ground_points))
# residuals <- abs(residuals(ground_fit))
# noise_level <- quantile(residuals, 0.95)  # 95th percentile
# 
# # Set threshold to 2-3x noise level
# distance_threshold <- 3 * noise_level
# cat(sprintf("Estimated noise: %.3fm, threshold: %.3fm\n",
#             noise_level, distance_threshold))

## ----eval=FALSE---------------------------------------------------------------
# # Based on expected inlier ratio
# # More noise → need more iterations
# 
# # Formula: iterations = log(1 - confidence) / log(1 - inlier_ratio^samples)
# 
# calculate_iterations <- function(confidence = 0.99, inlier_ratio = 0.5,
#                                   n_samples = 3) {
#   iter <- log(1 - confidence) / log(1 - inlier_ratio^n_samples)
#   ceiling(iter)
# }
# 
# # High inlier ratio (clean data)
# calculate_iterations(inlier_ratio = 0.7)  # ~20 iterations
# 
# # Medium inlier ratio (typical)
# calculate_iterations(inlier_ratio = 0.5)  # ~35 iterations
# 
# # Low inlier ratio (noisy scene)
# calculate_iterations(inlier_ratio = 0.3)  # ~200 iterations
# 
# # Practical defaults:
# # Clean data: max_iterations = 300
# # Normal data: max_iterations = 500-800
# # Noisy data: max_iterations = 1000-2000

## ----eval=FALSE---------------------------------------------------------------
# detect_spheres(xyz,
#                min_radius = ?,      # Smallest sphere to detect
#                max_radius = ?,      # Largest sphere to detect
#                min_votes = ?)       # Minimum points per sphere

## ----eval=FALSE---------------------------------------------------------------
# # 1. RADIUS RANGE: Based on expected object sizes
# 
# # Small objects (balls, markers)
# min_radius <- 0.05  # 5cm
# max_radius <- 0.20  # 20cm
# 
# # Medium objects (decorative spheres)
# min_radius <- 0.30
# max_radius <- 2.0
# 
# # Large structures (tank ends, domes)
# min_radius <- 2.0
# max_radius <- 10.0
# 
# # 2. MIN_VOTES: Based on point density and radius
# 
# # For dense scans: ~100 points per m² of sphere surface
# points_per_m2 <- 100
# sphere_surface <- 4 * pi * (0.5)^2  # 0.5m radius
# min_votes <- points_per_m2 * sphere_surface  # ~314 points
# 
# # Practical: 30-50% of theoretical
# min_votes <- round(min_votes * 0.4)  # ~125 points

## ----eval=FALSE---------------------------------------------------------------
# # Start conservative
# result1 <- detect_spheres(xyz, min_radius = 0.5, max_radius = 1.5, min_votes = 100)
# 
# # Too few detected? Relax constraints
# result2 <- detect_spheres(xyz, min_radius = 0.3, max_radius = 2.0, min_votes = 60)
# 
# # Too many false positives? Tighten
# result3 <- detect_spheres(xyz, min_radius = 0.6, max_radius = 1.2, min_votes = 120)

## ----eval=FALSE---------------------------------------------------------------
# detect_cylinders(xyz,
#                  min_radius = ?,     # Minimum cylinder radius
#                  max_radius = ?,     # Maximum cylinder radius
#                  min_length = ?,     # Minimum cylinder length
#                  min_votes = ?)      # Minimum points

## ----eval=FALSE---------------------------------------------------------------
# # RADIUS: Based on expected cylinders
# 
# # Thin poles/trees
# min_radius <- 0.05  # 5cm (small tree)
# max_radius <- 0.30  # 30cm (large tree)
# 
# # Standard poles (street lights)
# min_radius <- 0.10
# max_radius <- 0.40
# 
# # Large cylinders (tanks, silos)
# min_radius <- 1.0
# max_radius <- 5.0
# 
# # LENGTH: Minimum visible extent
# 
# # Forest (partial trunk visible)
# min_length <- 1.0  # At least 1m of trunk
# 
# # Urban poles (full height usually visible)
# min_length <- 2.5  # At least 2.5m tall
# 
# # MIN_VOTES: Larger than spheres (more surface area)
# 
# # Dense scan, medium cylinder (r=0.3m, h=5m)
# surface_area <- 2 * pi * 0.3 * 5  # ~9.4 m²
# min_votes <- 100 * 9.4 * 0.3  # points/m² × area × factor ≈ 280

## ----eval=FALSE---------------------------------------------------------------
# detect_tree_boles(xyz,
#                   min_radius = 0.05,      # Smallest tree DBH
#                   max_radius = 0.5,       # Largest expected
#                   min_height = 1.0,       # Minimum visible trunk
#                   vertical_only = TRUE,   # Only vertical cylinders
#                   min_votes = 50)         # Lower due to gaps/occlusion

## ----eval=FALSE---------------------------------------------------------------
# detect_lines(xyz,
#              distance_threshold = ?,  # Max distance from line
#              min_votes = ?,          # Min points per line
#              min_length = ?,         # Min line length
#              in_scene = ?)           # Context mode

## ----eval=FALSE---------------------------------------------------------------
# # DISTANCE_THRESHOLD: Based on line thickness
# 
# # Thin features (cables)
# distance_threshold <- 0.02  # 2cm
# 
# # Edges (building corners)
# distance_threshold <- 0.05  # 5cm
# 
# # Thick beams
# distance_threshold <- 0.10  # 10cm
# 
# # MIN_LENGTH: Avoid spurious short segments
# 
# # Cables (want long segments)
# min_length <- 3.0  # At least 3m
# 
# # Any linear feature
# min_length <- 1.0
# 
# # MIN_VOTES: Typically fewer than other shapes
# 
# # Thin cables (fewer points)
# min_votes <- 30
# 
# # Standard edges
# min_votes <- 50
# 
# # IN_SCENE: CRITICAL parameter!
# 
# # Line-only data (power lines scan)
# in_scene <- FALSE  # Aggressive mode
# 
# # Complex scenes (with buildings, terrain)
# in_scene <- TRUE   # Strict mode (detect AFTER other shapes)

## ----eval=FALSE---------------------------------------------------------------
# # Scenario 1: Power line corridor (lines only)
# lines <- detect_lines(xyz,
#                       distance_threshold = 0.04,
#                       min_votes = 25,
#                       min_length = 5.0,
#                       in_scene = FALSE,  # Aggressive
#                       max_iterations = 1200)
# 
# # Scenario 2: Urban scene (lines + buildings)
# # First detect other shapes
# planes <- detect_planes(xyz, ...)
# cylinders <- detect_cylinders(xyz, ...)
# 
# # Then detect standalone lines
# lines <- detect_lines(xyz,
#                       distance_threshold = 0.06,
#                       min_votes = 40,
#                       min_length = 2.0,
#                       in_scene = TRUE,   # Strict
#                       max_iterations = 800)

## ----eval=FALSE---------------------------------------------------------------
# detect_planes(xyz,
#               distance_threshold = ?,  # Max point-to-plane distance
#               min_votes = ?,          # Min points per plane
#               max_iterations = ?)     # RANSAC iterations

## ----eval=FALSE---------------------------------------------------------------
# # DISTANCE_THRESHOLD: Related to surface roughness
# 
# # Smooth walls, floors (indoor)
# distance_threshold <- 0.03  # 3cm
# 
# # Building facades (outdoor)
# distance_threshold <- 0.10  # 10cm
# 
# # Terrain (ground plane with vegetation)
# distance_threshold <- 0.20  # 20cm
# 
# # MIN_VOTES: Largest of all shapes (planes are big!)
# 
# # Indoor rooms
# min_votes <- 200
# 
# # Building walls
# min_votes <- 300
# 
# # Terrain/ground
# min_votes <- 500
# 
# # MAX_ITERATIONS: Medium to high
# 
# # Clean building scans
# max_iterations <- 500
# 
# # Complex scenes
# max_iterations <- 800
# 
# # Very noisy data
# max_iterations <- 1500

## ----eval=FALSE---------------------------------------------------------------
# library(houghPrimitives)
# 
# # Get basic statistics
# summary <- summarize_points(xyz)
# print(summary)
# 
# # Calculate density
# volume <- prod(summary$extent)
# density <- summary$n_points / volume
# cat(sprintf("Point density: %.1f pts/m³\n", density))
# 
# # Estimate noise from ground
# ground_subset <- xyz[xyz[,3] < quantile(xyz[,3], 0.05), ]
# if (nrow(ground_subset) > 100) {
#   fit <- lm(V3 ~ V1 + V2, data = as.data.frame(ground_subset))
#   noise <- sd(residuals(fit))
#   cat(sprintf("Estimated noise: %.3fm\n", noise))
# }
# 
# # Visualize distribution
# hist(xyz[,3], main = "Z Distribution", xlab = "Height (m)")

## ----eval=FALSE---------------------------------------------------------------
# # Use conservative defaults first
# defaults <- list(
#   spheres = list(
#     min_radius = 0.5, max_radius = 2.0, min_votes = 50
#   ),
#   cylinders = list(
#     min_radius = 0.2, max_radius = 0.5,
#     min_length = 2.0, min_votes = 80
#   ),
#   lines = list(
#     distance_threshold = 0.05, min_votes = 40,
#     min_length = 2.0, in_scene = TRUE
#   ),
#   planes = list(
#     distance_threshold = 0.10, min_votes = 150,
#     max_iterations = 800
#   )
# )
# 
# # Test each detector
# spheres <- detect_spheres(xyz,
#                          min_radius = defaults$spheres$min_radius,
#                          max_radius = defaults$spheres$max_radius,
#                          min_votes = defaults$spheres$min_votes)
# cat("Spheres:", spheres$n_spheres, "\n")

## ----eval=FALSE---------------------------------------------------------------
# # Create tuning grid
# tune_sphere_detection <- function(xyz, radius_range, vote_range) {
#   results <- data.frame()
# 
#   for (min_r in radius_range) {
#     for (min_v in vote_range) {
#       result <- detect_spheres(xyz,
#                               min_radius = min_r,
#                               max_radius = min_r * 2,
#                               min_votes = min_v)
# 
#       results <- rbind(results, data.frame(
#         min_radius = min_r,
#         min_votes = min_v,
#         n_detected = result$n_spheres
#       ))
#     }
#   }
# 
#   results
# }
# 
# # Run grid search
# grid_results <- tune_sphere_detection(
#   xyz,
#   radius_range = c(0.3, 0.5, 0.7, 1.0),
#   vote_range = c(30, 50, 80, 100)
# )
# 
# print(grid_results)
# 
# # Visualize
# library(ggplot2)
# ggplot(grid_results, aes(x = min_radius, y = min_votes, fill = n_detected)) +
#   geom_tile() +
#   scale_fill_gradient(low = "white", high = "blue") +
#   labs(title = "Sphere Detection Grid Search")

## ----eval=FALSE---------------------------------------------------------------
# # If you have ground truth (e.g., manual labeling)
# true_spheres <- 5  # Known number
# 
# # Test different parameters
# test_params <- function(min_votes) {
#   result <- detect_spheres(xyz, min_votes = min_votes)
# 
#   # Metrics
#   detected <- result$n_spheres
#   precision <- min(detected, true_spheres) / max(detected, 1)
#   recall <- min(detected, true_spheres) / true_spheres
#   f1 <- 2 * precision * recall / (precision + recall)
# 
#   data.frame(min_votes = min_votes, detected = detected,
#              precision = precision, recall = recall, f1 = f1)
# }
# 
# # Test range
# param_tests <- do.call(rbind, lapply(seq(20, 100, by = 10), test_params))
# print(param_tests)
# 
# # Find optimal (max F1 score)
# optimal_idx <- which.max(param_tests$f1)
# cat("Optimal min_votes:", param_tests$min_votes[optimal_idx], "\n")

## ----eval=FALSE---------------------------------------------------------------
# # Check data scale
# summary(xyz)
# 
# # Check point count
# nrow(xyz)
# 
# # Check for NaN/Inf
# sum(!is.finite(xyz))

## ----eval=FALSE---------------------------------------------------------------
# # 1. Relax ALL parameters
# detect_spheres(xyz, min_votes = 10, min_radius = 0.1, max_radius = 10)
# 
# # 2. Check if scale matches expectations
# # If data is in mm, convert to m:
# xyz_meters <- xyz / 1000
# 
# # 3. Verify data is 3D
# dim(xyz)  # Should be N x 3

## ----eval=FALSE---------------------------------------------------------------
# # Detect with low threshold
# result <- detect_spheres(xyz, min_votes = 20, label_points = TRUE)
# 
# # Check detected sphere sizes
# hist(result$spheres$radius, main = "Detected Radii")
# hist(result$spheres$n_points, main = "Points per Sphere")

## ----eval=FALSE---------------------------------------------------------------
# # 1. Increase min_votes
# detect_spheres(xyz, min_votes = 80)
# 
# # 2. Tighten radius range
# detect_spheres(xyz, min_radius = 0.8, max_radius = 1.2)  # Narrower
# 
# # 3. For lines: use strict mode
# detect_lines(xyz, in_scene = TRUE)

## ----eval=FALSE---------------------------------------------------------------
# result <- detect_cylinders(xyz, label_points = TRUE)
# 
# # Check for nearby similar cylinders
# cyls <- result$cylinders
# distances <- dist(cyls[, c("x1", "y1")])  # Distance between cylinder bases
# print(min(distances))  # Very small = likely splits

## ----eval=FALSE---------------------------------------------------------------
# # 1. Decrease min_votes
# detect_cylinders(xyz, min_votes = 50)  # Was 100
# 
# # 2. Increase distance_threshold
# detect_lines(xyz, distance_threshold = 0.08)  # Was 0.05
# 
# # 3. Post-process to merge nearby similar shapes

## ----eval=FALSE---------------------------------------------------------------
# # 1. Lower min_votes progressively
# for (mv in c(80, 60, 40, 30)) {
#   result <- detect_spheres(xyz, min_votes = mv)
#   cat(sprintf("min_votes=%d: %d spheres\n", mv, result$n_spheres))
# }
# 
# # 2. Widen parameter ranges
# detect_spheres(xyz, min_radius = 0.1, max_radius = 5.0)  # Very wide
# 
# # 3. Increase iterations
# detect_lines(xyz, max_iterations = 2000)
# 
# # 4. For lines: use aggressive mode
# detect_lines(xyz, in_scene = FALSE)

## ----eval=FALSE---------------------------------------------------------------
# # Automatically adapt parameters to data characteristics
# 
# adaptive_sphere_params <- function(xyz) {
#   # Estimate density
#   volume <- prod(apply(xyz, 2, function(x) diff(range(x))))
#   density <- nrow(xyz) / volume
# 
#   # Adapt min_votes
#   if (density > 100) {
#     min_votes <- 80
#   } else if (density > 50) {
#     min_votes <- 50
#   } else {
#     min_votes <- 30
#   }
# 
#   # Estimate scale from point cloud extent
#   extent <- apply(xyz, 2, function(x) diff(range(x)))
#   avg_extent <- mean(extent)
# 
#   # Adapt radius range
#   if (avg_extent < 10) {  # Small scene
#     min_radius <- 0.05
#     max_radius <- 1.0
#   } else if (avg_extent < 100) {  # Medium scene
#     min_radius <- 0.3
#     max_radius <- 3.0
#   } else {  # Large scene
#     min_radius <- 1.0
#     max_radius <- 10.0
#   }
# 
#   list(min_votes = min_votes, min_radius = min_radius, max_radius = max_radius)
# }
# 
# # Use adaptive parameters
# params <- adaptive_sphere_params(xyz)
# result <- detect_spheres(xyz,
#                         min_votes = params$min_votes,
#                         min_radius = params$min_radius,
#                         max_radius = params$max_radius)

