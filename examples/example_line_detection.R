# Example: Line Detection in Different Contexts
# Demonstrates in_scene parameter for detect_lines()
#
# Two modes:
#   in_scene = FALSE: Optimized for detecting all lines (cables, edges, beams)
#   in_scene = TRUE:  Stricter detection for lines in complex scenes with other shapes

library(houghPrimitives)

set.seed(NULL)
run_seed <- sample(1:10000, 1)
set.seed(run_seed)
cat(sprintf("=== LINE DETECTION EXAMPLE (seed=%d) ===\n\n", run_seed))

# Helper function for random lines
generate_random_line <- function(bounds_x = c(0, 20), bounds_y = c(0, 20), 
                                  bounds_z = c(0, 6), min_length = 3, 
                                  max_length = 8, n_points = 100, noise = 0.015) {
  x1 <- runif(1, bounds_x[1] + 1, bounds_x[2] - 1)
  y1 <- runif(1, bounds_y[1] + 1, bounds_y[2] - 1)
  z1 <- runif(1, bounds_z[1] + 0.5, bounds_z[2] - 0.5)
  
  length <- runif(1, min_length, max_length)
  theta <- runif(1, 0, 2*pi)
  phi <- runif(1, 0, pi)
  
  dx <- sin(phi) * cos(theta)
  dy <- sin(phi) * sin(theta)
  dz <- cos(phi)
  
  x2 <- x1 + length * dx
  y2 <- y1 + length * dy
  z2 <- z1 + length * dz
  
  x2 <- max(bounds_x[1], min(bounds_x[2], x2))
  y2 <- max(bounds_y[1], min(bounds_y[2], y2))
  z2 <- max(bounds_z[1], min(bounds_z[2], z2))
  
  t <- runif(n_points, 0, 1)
  x <- x1 + t * (x2 - x1) + rnorm(n_points, sd = noise)
  y <- y1 + t * (y2 - y1) + rnorm(n_points, sd = noise)
  z <- z1 + t * (z2 - z1) + rnorm(n_points, sd = noise)
  
  cbind(x, y, z)
}

# ============================================================================
# SCENARIO 1: Lines Only (cables, infrastructure edges, etc.)
# ============================================================================
cat("=== SCENARIO 1: LINES ONLY ===\n")
cat("Detecting cables/beams in infrastructure scan\n\n")

n_lines_only <- sample(5:8, 1)
lines_only <- NULL
for (i in 1:n_lines_only) {
  lines_only <- rbind(lines_only, generate_random_line(
    min_length = 3,
    max_length = 12,
    n_points = sample(80:140, 1),
    noise = runif(1, 0.01, 0.02)
  ))
}

# Add some measurement noise
noise_points <- cbind(
  runif(100, 0, 20),
  runif(100, 0, 20),
  runif(100, 0, 6)
)
lines_with_noise <- rbind(lines_only, noise_points)

cat(sprintf("Generated %d lines (%d points) + %d noise points\n", 
            n_lines_only, nrow(lines_only), nrow(noise_points)))

# Detect with in_scene=FALSE (aggressive, find all lines)
result_aggressive <- detect_lines(lines_with_noise, 
                                   distance_threshold = 0.05,
                                   min_votes = 30,
                                   min_length = 2.0,
                                   max_iterations = 1000,
                                   in_scene = FALSE)  # Line-only mode
cat(sprintf("\nWith in_scene=FALSE (aggressive): Found %d/%d lines\n", 
            result_aggressive$n_lines, n_lines_only))
if (result_aggressive$n_lines > 0) {
  cat("Detected lines:\n")
  print(result_aggressive$lines)
}

# ============================================================================
# SCENARIO 2: Lines in Complex Scene
# ============================================================================
cat("\n\n=== SCENARIO 2: LINES IN COMPLEX SCENE ===\n")
cat("Scene with planes, cylinders, and standalone lines\n\n")

# Generate a ground plane
ground <- cbind(
  runif(300, 0, 20),
  runif(300, 0, 20),
  rnorm(300, mean = 0.05, sd = 0.02)
)

# Generate a cylinder (pole)
cylinder_pts <- NULL
for (theta in seq(0, 2*pi, length.out=60)) {
  for (h in seq(0, 5, by=0.2)) {
    x <- 10 + 0.3 * cos(theta) + rnorm(1, sd=0.01)
    y <- 10 + 0.3 * sin(theta) + rnorm(1, sd=0.01)
    z <- h + rnorm(1, sd=0.02)
    cylinder_pts <- rbind(cylinder_pts, c(x, y, z))
  }
}

# Generate standalone lines (cables)
n_lines_scene <- 3
lines_scene <- NULL
for (i in 1:n_lines_scene) {
  lines_scene <- rbind(lines_scene, generate_random_line(
    min_length = 4,
    max_length = 10,
    n_points = sample(100:130, 1),
    noise = 0.015
  ))
}

# Combine everything
complex_scene <- rbind(ground, cylinder_pts, lines_scene, noise_points)

cat(sprintf("Scene: %d points total\n", nrow(complex_scene)))
cat(sprintf("  - Ground plane: %d points\n", nrow(ground)))
cat(sprintf("  - Cylinder: %d points\n", nrow(cylinder_pts)))
cat(sprintf("  - Lines: %d standalone lines, %d points\n", n_lines_scene, nrow(lines_scene)))
cat(sprintf("  - Noise: %d points\n", nrow(noise_points)))

# Detect planes first (consume their points)
cat("\n1. Detecting planes first...\n")
planes_result <- detect_planes(complex_scene, 
                                distance_threshold = 0.10,
                                min_votes = 100,
                                max_iterations = 800,
                                label_points = TRUE)
cat(sprintf("   Found %d planes\n", planes_result$n_planes))

# Detect cylinders
cat("2. Detecting cylinders...\n")
cyl_result <- detect_cylinders(complex_scene,
                                min_radius = 0.25,
                                max_radius = 0.35,
                                min_length = 3.0,
                                min_votes = 80,
                                label_points = TRUE)
cat(sprintf("   Found %d cylinders\n", cyl_result$n_cylinders))

# Now detect standalone lines with in_scene=TRUE (stricter)
cat("3. Detecting standalone lines (remaining points)...\n")
result_scene <- detect_lines(complex_scene,
                              distance_threshold = 0.06,
                              min_votes = 40,
                              min_length = 2.5,
                              max_iterations = 1000,
                              in_scene = TRUE,  # Stricter - only standalone
                              label_points = TRUE)
cat(sprintf("   With in_scene=TRUE (strict): Found %d/%d standalone lines\n",
            result_scene$n_lines, n_lines_scene))
if (result_scene$n_lines > 0) {
  cat("   Detected standalone lines:\n")
  print(result_scene$lines)
}

# ============================================================================
# SUMMARY
# ============================================================================
cat("\n=== SUMMARY ===\n")
cat(sprintf("Random seed: %d\n\n", run_seed))
cat("SCENARIO 1 (Lines Only):\n")
cat(sprintf("  Expected: %d lines\n", n_lines_only))
cat(sprintf("  Detected: %d lines (%.0f%%) with in_scene=FALSE\n",
            result_aggressive$n_lines,
            100 * result_aggressive$n_lines / max(1, n_lines_only)))

cat("\nSCENARIO 2 (Complex Scene):\n")
cat(sprintf("  Expected standalone lines: %d\n", n_lines_scene))
cat(sprintf("  Detected: %d lines (%.0f%%) with in_scene=TRUE\n",
            result_scene$n_lines,
            100 * result_scene$n_lines / max(1, n_lines_scene)))
cat(sprintf("  Other shapes: %d planes, %d cylinders\n",
            planes_result$n_planes, cyl_result$n_cylinders))

cat("\n=== RECOMMENDATION ===\n")
cat("• Use in_scene=FALSE when detecting ONLY lines (cables, edges, infrastructure)\n")
cat("  → More aggressive, finds all linear features\n")
cat("  → Lower thresholds, more iterations\n\n")
cat("• Use in_scene=TRUE when lines exist WITH other shapes (buildings, terrain)\n")
cat("  → Stricter, avoids false positives\n")
cat("  → Only finds standalone lines not part of planes/cylinders\n")

# Visualize with lidR
cat("\n=== Visualization with lidR ===\n")
library(lidR)

# Create classification for complex scene
classification <- rep(1L, nrow(complex_scene))
if (planes_result$n_planes > 0 && !is.null(planes_result$point_labels)) {
  classification[planes_result$point_labels > 0] <- 2L  # Ground
}
if (cyl_result$n_cylinders > 0 && !is.null(cyl_result$point_labels)) {
  classification[cyl_result$point_labels > 0] <- 5L  # Cylinders
}
if (result_scene$n_lines > 0 && !is.null(result_scene$point_labels)) {
  classification[result_scene$point_labels > 0] <- 14L  # Lines/cables
}

# Create LAS object
las <- LAS(data.frame(
  X = complex_scene[,1],
  Y = complex_scene[,2],
  Z = complex_scene[,3],
  Classification = classification
))

cat("Plotting complex scene...\n")
cat("  1 = Unclassified, 2 = Ground, 5 = Cylinders, 14 = Lines\n")
plot(las, color = "Classification", size = 3)
