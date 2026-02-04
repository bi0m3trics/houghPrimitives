# Example: Comprehensive Multi-Shape Detection
# Demonstrates detecting cylinders, cubes, spheres, lines, planes, and cuboids in a complex scene
#
# NOTE: This package provides detection for primitive shapes:
#   - Spheres: Direct 3D sphere detection via spatial clustering
#   - Cylinders: Direct cylinder detection via circular cross-sections  
#   - Planes: RANSAC-based plane fitting
#   - Lines: RANSAC-based 3D line detection
#   - Cubes: Detected as collections of 6 orthogonal planes forming a box
#   - Cuboids: Detected as collections of planes forming rectangular structures
#
# Cube/cuboid detection is inherently more complex as these are composite structures
# made up of multiple planar faces. Detection success depends on point density,
# noise levels, and whether all faces are well-represented in the point cloud.

library(houghPrimitives)
library(lidR)

# Use random seed each time (or set to NULL for truly random)
set.seed(NULL)  # Randomize each run!
run_seed <- sample(1:10000, 1)
set.seed(run_seed)
cat(sprintf("=== GENERATING RANDOM SCENE (seed=%d) ===\n\n", run_seed))

# Helper functions for shape generation
generate_sphere <- function(cx, cy, cz, radius, n_points = 150) {
  theta <- runif(n_points, 0, 2 * pi)
  phi <- acos(2 * runif(n_points) - 1)
  
  x <- cx + radius * sin(phi) * cos(theta)
  y <- cy + radius * sin(phi) * sin(theta)
  z <- cz + radius * cos(phi)
  
  cbind(x, y, z)
}

generate_cylinder <- function(x, y, z1, z2, radius, n_points = 200) {
  theta <- runif(n_points, 0, 2 * pi)
  z <- runif(n_points, z1, z2)
  
  x_pts <- x + radius * cos(theta)
  y_pts <- y + radius * sin(theta)
  
  cbind(x_pts, y_pts, z)
}

generate_plane <- function(center_x, center_y, center_z, width, height, normal = c(0,0,1), n_points = 300) {
  # Generate points on a rectangle
  u <- runif(n_points, -width/2, width/2)
  v <- runif(n_points, -height/2, height/2)
  
  # Default plane in XY, transform to desired orientation
  # Simplified: just create horizontal or vertical planes
  if (normal[3] == 1) {  # Horizontal
    x <- center_x + u
    y <- center_y + v
    z <- rep(center_z, n_points)
  } else if (normal[2] == 1) {  # Wall in Y direction
    x <- center_x + u
    y <- rep(center_y, n_points)
    z <- center_z + v
  } else {  # Wall in X direction
    x <- rep(center_x, n_points)
    y <- center_y + u
    z <- center_z + v
  }
  
  cbind(x, y, z)
}

generate_line <- function(x1, y1, z1, x2, y2, z2, n_points = 80, noise = 0.02) {
  t <- runif(n_points, 0, 1)
  
  x <- x1 + t * (x2 - x1) + rnorm(n_points, sd = noise)
  y <- y1 + t * (y2 - y1) + rnorm(n_points, sd = noise)
  z <- z1 + t * (z2 - z1) + rnorm(n_points, sd = noise)
  
  cbind(x, y, z)
}

# New function: Generate line with random angle
generate_random_line <- function(bounds_x = c(0, 20), bounds_y = c(0, 20), 
                                  bounds_z = c(0, 6), min_length = 3, 
                                  max_length = 8, n_points = 100, noise = 0.015) {
  # Random start point
  x1 <- runif(1, bounds_x[1] + 1, bounds_x[2] - 1)
  y1 <- runif(1, bounds_y[1] + 1, bounds_y[2] - 1)
  z1 <- runif(1, bounds_z[1] + 0.5, bounds_z[2] - 0.5)
  
  # Random direction with desired length
  length <- runif(1, min_length, max_length)
  
  # Random unit direction vector
  theta <- runif(1, 0, 2*pi)      # Azimuth angle
  phi <- runif(1, 0, pi)           # Elevation angle
  
  dx <- sin(phi) * cos(theta)
  dy <- sin(phi) * sin(theta)
  dz <- cos(phi)
  
  # End point
  x2 <- x1 + length * dx
  y2 <- y1 + length * dy
  z2 <- z1 + length * dz
  
  # Clip to bounds if needed
  x2 <- max(bounds_x[1], min(bounds_x[2], x2))
  y2 <- max(bounds_y[1], min(bounds_y[2], y2))
  z2 <- max(bounds_z[1], min(bounds_z[2], z2))
  
  generate_line(x1, y1, z1, x2, y2, z2, n_points, noise)
}

generate_cone <- function(apex_x, apex_y, apex_z, axis_x = 0, axis_y = 0, axis_z = -1,
                          height = 3.0, half_angle = 0.3, n_points = 150) {
  # Generate points on cone surface
  # Cone equation: perpendicular_distance = height_along_axis * tan(half_angle)
  
  # Normalize axis direction
  axis_len <- sqrt(axis_x^2 + axis_y^2 + axis_z^2)
  axis_x <- axis_x / axis_len
  axis_y <- axis_y / axis_len
  axis_z <- axis_z / axis_len
  
  # Generate random heights along cone
  h <- runif(n_points, 0, height)
  
  # Generate random angles around axis
  theta <- runif(n_points, 0, 2*pi)
  
  # Radius at each height
  r <- h * tan(half_angle)
  
  # Need perpendicular vectors to axis
  # Find a vector not parallel to axis
  if (abs(axis_z) < 0.9) {
    perp1_x <- 0
    perp1_y <- axis_z
    perp1_z <- -axis_y
  } else {
    perp1_x <- axis_y
    perp1_y <- -axis_x
    perp1_z <- 0
  }
  
  # Normalize
  perp1_len <- sqrt(perp1_x^2 + perp1_y^2 + perp1_z^2)
  perp1_x <- perp1_x / perp1_len
  perp1_y <- perp1_y / perp1_len
  perp1_z <- perp1_z / perp1_len
  
  # Second perpendicular vector (cross product)
  perp2_x <- axis_y * perp1_z - axis_z * perp1_y
  perp2_y <- axis_z * perp1_x - axis_x * perp1_z
  perp2_z <- axis_x * perp1_y - axis_y * perp1_x
  
  # Points on cone surface
  x <- apex_x + h * axis_x + r * (cos(theta) * perp1_x + sin(theta) * perp2_x)
  y <- apex_y + h * axis_y + r * (cos(theta) * perp1_y + sin(theta) * perp2_y)
  z <- apex_z + h * axis_z + r * (cos(theta) * perp1_z + sin(theta) * perp2_z)
  
  cbind(x, y, z)
}

generate_cube <- function(cx, cy, cz, size, n_points = 400) {
  # Generate points on 6 faces
  points_per_face <- n_points / 6
  
  faces <- NULL
  
  # Bottom face (z = cz - size/2)
  x <- cx + runif(points_per_face, -size/2, size/2)
  y <- cy + runif(points_per_face, -size/2, size/2)
  z <- rep(cz - size/2, points_per_face)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Top face (z = cz + size/2)
  x <- cx + runif(points_per_face, -size/2, size/2)
  y <- cy + runif(points_per_face, -size/2, size/2)
  z <- rep(cz + size/2, points_per_face)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Front face (y = cy - size/2)
  x <- cx + runif(points_per_face, -size/2, size/2)
  y <- rep(cy - size/2, points_per_face)
  z <- cz + runif(points_per_face, -size/2, size/2)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Back face (y = cy + size/2)
  x <- cx + runif(points_per_face, -size/2, size/2)
  y <- rep(cy + size/2, points_per_face)
  z <- cz + runif(points_per_face, -size/2, size/2)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Left face (x = cx - size/2)
  x <- rep(cx - size/2, points_per_face)
  y <- cy + runif(points_per_face, -size/2, size/2)
  z <- cz + runif(points_per_face, -size/2, size/2)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Right face (x = cx + size/2)
  x <- rep(cx + size/2, points_per_face)
  y <- cy + runif(points_per_face, -size/2, size/2)
  z <- cz + runif(points_per_face, -size/2, size/2)
  faces <- rbind(faces, cbind(x, y, z))
  
  faces
}

generate_cuboid <- function(cx, cy, cz, width, depth, height, n_points = 500) {
  # House-like cuboid
  points_per_face <- n_points / 6
  
  faces <- NULL
  
  # Bottom
  x <- cx + runif(points_per_face, -width/2, width/2)
  y <- cy + runif(points_per_face, -depth/2, depth/2)
  z <- rep(cz, points_per_face)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Top
  x <- cx + runif(points_per_face, -width/2, width/2)
  y <- cy + runif(points_per_face, -depth/2, depth/2)
  z <- rep(cz + height, points_per_face)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Front wall
  x <- cx + runif(points_per_face, -width/2, width/2)
  y <- rep(cy - depth/2, points_per_face)
  z <- cz + runif(points_per_face, 0, height)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Back wall
  x <- cx + runif(points_per_face, -width/2, width/2)
  y <- rep(cy + depth/2, points_per_face)
  z <- cz + runif(points_per_face, 0, height)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Left wall
  x <- rep(cx - width/2, points_per_face)
  y <- cy + runif(points_per_face, -depth/2, depth/2)
  z <- cz + runif(points_per_face, 0, height)
  faces <- rbind(faces, cbind(x, y, z))
  
  # Right wall
  x <- rep(cx + width/2, points_per_face)
  y <- cy + runif(points_per_face, -depth/2, depth/2)
  z <- cz + runif(points_per_face, 0, height)
  faces <- rbind(faces, cbind(x, y, z))
  
  faces
}

# Generate scene objects - RANDOMIZED positions and sizes!
cat("1. SPHERES (decorative objects)\n")
n_spheres <- sample(2:3, 1)
spheres <- NULL
for (i in 1:n_spheres) {
  cx <- runif(1, 3, 17)
  cy <- runif(1, 3, 17)
  cz <- runif(1, 1.5, 3.5)
  radius <- runif(1, 0.7, 1.2)
  n_pts <- sample(150:220, 1)
  spheres <- rbind(spheres, generate_sphere(cx, cy, cz, radius, n_pts))
}
cat(sprintf("   Generated %d spheres, %d points\n", n_spheres, nrow(spheres)))

cat("\n2. CONES (traffic cones, markers)\n")
n_cones <- sample(2:3, 1)
cones <- NULL
for (i in 1:n_cones) {
  apex_x <- runif(1, 3, 17)
  apex_y <- runif(1, 3, 17)
  apex_z <- runif(1, 4.5, 6)  # Cone points up
  height <- runif(1, 2.5, 4.5)
  half_angle <- runif(1, 0.25, 0.4)  # ~14-23 degrees
  n_pts <- sample(120:180, 1)
  # Cone pointing down (apex at top)
  cones <- rbind(cones, generate_cone(apex_x, apex_y, apex_z, 
                                      axis_x=0, axis_y=0, axis_z=-1,
                                      height=height, half_angle=half_angle, 
                                      n_points=n_pts))
}
cat(sprintf("   Generated %d cones, %d points\n", n_cones, nrow(cones)))

cat("\n4. CYLINDERS (columns/poles)\n")
n_cylinders <- sample(2:4, 1)
cylinders <- NULL
for (i in 1:n_cylinders) {
  cx <- runif(1, 2, 18)
  cy <- runif(1, 2, 18)
  z1 <- 0
  z2 <- runif(1, 3.5, 6.5)
  radius <- runif(1, 0.25, 0.45)
  n_pts <- sample(200:300, 1)
  cylinders <- rbind(cylinders, generate_cylinder(cx, cy, z1, z2, radius, n_pts))
}
cat(sprintf("   Generated %d cylinders, %d points\n", n_cylinders, nrow(cylinders)))

cat("\n5. CUBES (storage boxes) - note: detected via planes\n")
n_cubes <- sample(1:3, 1)
cubes <- NULL
for (i in 1:n_cubes) {
  cx <- runif(1, 3, 17)
  cy <- runif(1, 3, 17)
  cz <- runif(1, 1.0, 2.0)
  size <- runif(1, 1.5, 2.5)
  n_pts <- sample(350:500, 1)
  cubes <- rbind(cubes, generate_cube(cx, cy, cz, size, n_pts))
}
cat(sprintf("   Generated %d cubes, %d points\n", n_cubes, nrow(cubes)))

cat("\n6. CUBOIDS (building structures) - note: detected via planes\n")
n_cuboids <- sample(1:2, 1)
cuboids <- NULL
for (i in 1:n_cuboids) {
  cx <- runif(1, 3, 17)
  cy <- runif(1, 10, 18)
  cz <- 0
  width <- runif(1, 3, 5)
  depth <- runif(1, 3, 4.5)
  height <- runif(1, 3.5, 5)
  n_pts <- sample(500:700, 1)
  cuboids <- rbind(cuboids, generate_cuboid(cx, cy, cz, width, depth, height, n_pts))
}
cat(sprintf("   Generated %d cuboids, %d points\n", n_cuboids, nrow(cuboids)))

cat("\n7. PLANES (separate walls and ground)\n")
n_planes <- sample(2:4, 1)
planes <- NULL
for (i in 1:n_planes) {
  if (i == 1) {
    # Always include a ground plane
    planes <- rbind(planes, generate_plane(10, 10, 0.05, 20, 20, c(0,0,1), 400))
  } else {
    # Random walls
    wall_type <- sample(c("x", "y"), 1)
    if (wall_type == "x") {
      cx <- runif(1, 5, 15)
      cy <- sample(c(2, 18), 1)
      cz <- runif(1, 2, 3)
      planes <- rbind(planes, generate_plane(cx, cy, cz, runif(1, 15, 20), runif(1, 3, 5), c(0,1,0), 300))
    } else {
      cx <- sample(c(2, 18), 1)
      cy <- runif(1, 5, 15)
      cz <- runif(1, 2, 3)
      planes <- rbind(planes, generate_plane(cx, cy, cz, runif(1, 15, 20), runif(1, 3, 5), c(1,0,0), 300))
    }
  }
}
cat(sprintf("   Generated %d planes, %d points\n", n_planes, nrow(planes)))

cat("\n8. LINES (cables/beams at RANDOM ANGLES)\n")
n_lines <- sample(3:5, 1)
lines <- NULL
for (i in 1:n_lines) {
  lines <- rbind(lines, generate_random_line(
    bounds_x = c(0, 20), 
    bounds_y = c(0, 20), 
    bounds_z = c(0.5, 6),
    min_length = 4,      # Longer lines
    max_length = 10,
    n_points = sample(100:150, 1),  # More points per line
    noise = runif(1, 0.008, 0.018)  # Less noise
  ))
}
cat(sprintf("   Generated %d lines, %d points\n", n_lines, nrow(lines)))

# Combine all shape points
all_shapes <- rbind(spheres, cones, cylinders, cubes, cuboids, planes, lines)

cat("\n9. ADDING NOISE\n")
# Add moderate noise - not too much to interfere
noise_uniform <- cbind(
  runif(300, 0, 20),
  runif(300, 0, 20),
  runif(300, 0, 6.5)
)

# Small clustered noise (debris)
noise_clusters <- NULL
for (i in 1:8) {  # Fewer clusters
  cx <- runif(1, 0, 20)
  cy <- runif(1, 0, 20)
  cz <- runif(1, 0, 6.5)
  
  n <- sample(15:35, 1)  # Smaller clusters
  x <- cx + rnorm(n, sd = 0.25)
  y <- cy + rnorm(n, sd = 0.25)
  z <- cz + rnorm(n, sd = 0.15)
  
  noise_clusters <- rbind(noise_clusters, cbind(x, y, z))
}

all_noise <- rbind(noise_uniform, noise_clusters)
cat(sprintf("   Generated %d noise points\n", nrow(all_noise)))

# Final point cloud
all_points <- rbind(all_shapes, all_noise)

cat(sprintf("\n=== SCENE SUMMARY ===\n"))
cat(sprintf("Total points: %d\n", nrow(all_points)))
cat(sprintf("  Shapes: %d (%.1f%%)\n", nrow(all_shapes), 100*nrow(all_shapes)/nrow(all_points)))
cat(sprintf("  Noise: %d (%.1f%%)\n", nrow(all_noise), 100*nrow(all_noise)/nrow(all_points)))

cat("\n=== DETECTING SHAPES ===\n\n")

# IMPORTANT: Lines are standalone features, NOT part of other structures.
# Detect all major shapes first, then lines from remaining points.

cat("Detecting planes first...\n")
result_planes <- detect_planes(all_points, distance_threshold = 0.12, min_votes = 130, max_iterations = 1200, label_points = TRUE)
cat(sprintf("  Found %d planes (includes cube/cuboid faces + walls/ground, expected ~%d)\n", 
            result_planes$n_planes, n_planes + n_cubes*6 + n_cuboids*6))
if (result_planes$n_planes > 0) {
  print(head(result_planes$planes, 15))
  if (result_planes$n_planes > 15) cat(sprintf("  (showing first 15 of %d planes)\n", result_planes$n_planes))
}

cat("\nDetecting spheres...\n")
result_spheres <- detect_spheres(all_points, min_radius = 0.6, max_radius = 1.3, min_votes = 110, label_points = TRUE)
cat(sprintf("  Found %d spheres (expected %d)\n", result_spheres$n_spheres, n_spheres))
if (result_spheres$n_spheres > 0) print(result_spheres$spheres)

cat("\nDetecting cones...\n")
result_cones <- detect_cones(all_points, min_radius = 0.5, max_radius = 2.5, 
                             min_height = 2.0, max_height = 5.0, 
                             min_votes = 70, angle_threshold = 0.45, 
                             label_points = TRUE)
cat(sprintf("  Found %d cones (expected %d)\n", result_cones$n_cones, n_cones))
if (result_cones$n_cones > 0) print(result_cones$cones)

cat("\nDetecting cylinders...\n")
result_cylinders <- detect_cylinders(all_points, min_radius = 0.20, max_radius = 0.50, min_length = 3.0, min_votes = 85, label_points = TRUE)
cat(sprintf("  Found %d cylinders (expected %d)\n", result_cylinders$n_cylinders, n_cylinders))
if (result_cylinders$n_cylinders > 0) print(result_cylinders$cylinders)

cat("\nDetecting cubes... (complex - via plane analysis)\n")
result_cubes <- detect_cubes(all_points, min_size = 1.3, max_size = 2.8, min_votes = 110, plane_threshold = 0.13, label_points = TRUE)
cat(sprintf("  Found %d cubes (expected %d) - May vary\n", result_cubes$n_cubes, n_cubes))
if (result_cubes$n_cubes > 0) print(result_cubes$cubes)

cat("\nDetecting cuboids... (complex - via plane analysis)\n")
result_cuboids <- detect_cuboids(all_points, min_width = 2.5, max_width = 5.5, min_height = 3.0, max_height = 5.5, min_votes = 190, plane_threshold = 0.16, label_points = TRUE)
cat(sprintf("  Found %d cuboids (expected %d buildings) - May vary\n", result_cuboids$n_cuboids, n_cuboids))
if (result_cuboids$n_cuboids > 0) print(result_cuboids$cuboids)

cat("\nDetecting standalone lines (from remaining points)...\n")
result_lines <- detect_lines(all_points, distance_threshold = 0.06, min_votes = 40, 
                              min_length = 2.0, max_iterations = 1000, 
                              in_scene = TRUE,  # Stricter - only standalone lines
                              label_points = TRUE)
cat(sprintf("  Found %d lines (expected %d)\n", result_lines$n_lines, n_lines))
if (result_lines$n_lines > 0) print(result_lines$lines)
if (result_lines$n_lines > 0) print(result_lines$lines)

cat("\n=== DETECTION SUMMARY ===\n")
cat(sprintf("Random seed used: %d\n", run_seed))
cat("NOTE: Cubes/cuboids are complex 3D structures detected via planar analysis.\n")
cat("      Lines are STANDALONE features - not part of other structures.\n")
cat("      Lines detected only from points NOT belonging to planes/cylinders/spheres.\n")
cat("      Lines now generated at random angles for robustness testing.\n\n")

cat("EXPECTED:\n")
cat(sprintf("  Spheres: %d\n", n_spheres))
cat(sprintf("  Cones: %d\n", n_cones))
cat(sprintf("  Cylinders: %d\n", n_cylinders))
cat(sprintf("  Lines: %d (random angles)\n", n_lines))
cat(sprintf("  Planes: %d (standalone)\n", n_planes))
cat(sprintf("  Cubes: %d\n", n_cubes))
cat(sprintf("  Cuboids: %d\n", n_cuboids))

cat("\nDETECTED:\n")
cat(sprintf("  Spheres: %d (%.0f%%)\n", result_spheres$n_spheres, 
            100*result_spheres$n_spheres/max(1,n_spheres)))
cat(sprintf("  Cones: %d (%.0f%%)\n", result_cones$n_cones,
            100*result_cones$n_cones/max(1,n_cones)))
cat(sprintf("  Cylinders: %d (%.0f%%)\n", result_cylinders$n_cylinders,
            100*result_cylinders$n_cylinders/max(1,n_cylinders)))
cat(sprintf("  Lines: %d (%.0f%%)\n", result_lines$n_lines,
            100*result_lines$n_lines/max(1,n_lines)))
cat(sprintf("  Planes: %d total (includes all planar surfaces)\n", result_planes$n_planes))
cat(sprintf("  Cubes: %d (%.0f%%)\n", result_cubes$n_cubes,
            100*result_cubes$n_cubes/max(1,n_cubes)))
cat(sprintf("  Cuboids: %d (%.0f%%)\n", result_cuboids$n_cuboids,
            100*result_cuboids$n_cuboids/max(1,n_cuboids)))

cat("\n=== VISUALIZING WITH lidR ===\n")

library(lidR)

# Combine all detected shapes into classification
classification <- rep(1L, nrow(all_points))  # Default: unclassified

# Assign classifications based on detections (priority order matters)
if (result_cubes$n_cubes > 0 && !is.null(result_cubes$point_labels)) {
  cube_mask <- result_cubes$point_labels > 0
  classification[cube_mask] <- 8L  # Model key (cubes)
}

if (result_cuboids$n_cuboids > 0 && !is.null(result_cuboids$point_labels)) {
  cuboid_mask <- result_cuboids$point_labels > 0
  classification[cuboid_mask] <- 6L  # Building (cuboids/houses)
}

if (result_spheres$n_spheres > 0 && !is.null(result_spheres$point_labels)) {
  sphere_mask <- result_spheres$point_labels > 0
  classification[sphere_mask] <- 7L  # Low point (spheres)
}

if (result_cylinders$n_cylinders > 0 && !is.null(result_cylinders$point_labels)) {
  cyl_mask <- result_cylinders$point_labels > 0
  classification[cyl_mask] <- 5L  # Vegetation (cylinders/columns)
}

if (result_planes$n_planes > 0 && !is.null(result_planes$point_labels)) {
  plane_mask <- result_planes$point_labels > 0 & classification == 1L
  classification[plane_mask] <- 2L  # Ground/walls
}

if (result_lines$n_lines > 0 && !is.null(result_lines$point_labels)) {
  line_mask <- result_lines$point_labels > 0 & classification == 1L
  classification[line_mask] <- 14L  # Wire/cable
}

# Mark any points with NA coordinates as dark grey (class 0)
na_mask <- is.na(all_points[,1]) | is.nan(all_points[,1]) |
           is.na(all_points[,2]) | is.nan(all_points[,2]) |
           is.na(all_points[,3]) | is.nan(all_points[,3])
if (sum(na_mask) > 0) {
  cat(sprintf("\nWARNING: %d points with NA/NaN values, marking as class 0 (dark grey)\n", sum(na_mask)))
  classification[na_mask] <- 0L
  # Replace NA coordinates with 0 to allow LAS creation
  all_points[na_mask, 1] <- 0
  all_points[na_mask, 2] <- 0
  all_points[na_mask, 3] <- 0
}

# Create LAS object
las <- LAS(data.frame(
  X = all_points[,1],
  Y = all_points[,2],
  Z = all_points[,3],
  Classification = as.integer(classification)
))

cat("\nPlot 1: All points colored by classification...\n")
plot(las, color = "Classification", size = 3)

# Create separate view with detected spheres highlighted
if (result_spheres$n_spheres > 0 && !is.null(result_spheres$point_labels)) {
  sphere_ids <- as.integer(result_spheres$point_labels)
  sphere_ids[sphere_ids == 0L] <- NA_integer_
  
  las_spheres <- LAS(data.frame(
    X = all_points[,1],
    Y = all_points[,2],
    Z = all_points[,3],
    SphereID = sphere_ids
  ))
  
  cat("\nPlot 2: Detected spheres (each sphere in different color)...\n")
  plot(las_spheres, color = "SphereID", size = 3)
}

# Create view with cubes and cuboids
if ((result_cubes$n_cubes > 0 && !is.null(result_cubes$point_labels)) || 
    (result_cuboids$n_cuboids > 0 && !is.null(result_cuboids$point_labels))) {
  
  shape_type <- rep("Noise", nrow(all_points))
  
  if (result_cubes$n_cubes > 0 && !is.null(result_cubes$point_labels)) {
    cube_mask <- result_cubes$point_labels > 0
    shape_type[cube_mask] <- paste0("Cube_", result_cubes$point_labels[cube_mask])
  }
  
  if (result_cuboids$n_cuboids > 0 && !is.null(result_cuboids$point_labels)) {
    cuboid_mask <- result_cuboids$point_labels > 0
    shape_type[cuboid_mask] <- paste0("Cuboid_", result_cuboids$point_labels[cuboid_mask])
  }
  
  if (result_cylinders$n_cylinders > 0 && !is.null(result_cylinders$point_labels)) {
    cyl_mask <- result_cylinders$point_labels > 0 & shape_type == "Noise"
    shape_type[cyl_mask] <- paste0("Cylinder_", result_cylinders$point_labels[cyl_mask])
  }
  
  las_shapes <- LAS(data.frame(
    X = all_points[,1],
    Y = all_points[,2],
    Z = all_points[,3],
    ShapeType = as.factor(shape_type)
  ))
  
  cat("\nPlot 3: Cubes, cuboids, and cylinders (each shape in different color)...\n")
  plot(las_shapes, color = "ShapeType", size = 3)
}

cat("\nVisualization complete!\n")
cat("\n=== LEGEND ===\n")
cat("Classification codes:\n")
cat("  1 = Unclassified (noise)\n")
cat("  2 = Ground/Planes\n")
cat("  5 = Vegetation (cylinders)\n")
cat("  6 = Building (cuboids)\n")
cat("  7 = Low point (spheres)\n")
cat("  8 = Model key (cubes)\n")
cat(" 14 = Wire/cable (lines)\n")
