# Cumulative Shape Detection Example
# 
# This example demonstrates a cumulative detection workflow where:
# 1. Multiple shape detection passes are performed on the same point cloud
# 2. Each pass labels points that belong to detected shapes
# 3. Results are accumulated to count how many shape types each point belongs to
# 4. Provides insight into point classification confidence and overlap
# 5. All 7 shape types are detected: spheres, cones, cylinders, planes, lines, cubes, cuboids

library(houghPrimitives)

# Set seed for reproducibility
set.seed(42)

cat("\n=== CUMULATIVE SHAPE DETECTION WORKFLOW (ALL 7 SHAPE TYPES) ===\n\n")

# ============================================================================
# 1. GENERATE SYNTHETIC SCENE WITH ALL SHAPE TYPES
# ============================================================================

cat("Step 1: Generating synthetic scene...\n")

# Generate spheres (balls, domes)
n_spheres <- 2
sphere_pts_list <- lapply(1:n_spheres, function(i) {
  n <- sample(100:150, 1)
  center_x <- runif(1, -8, 8)
  center_y <- runif(1, -8, 8)
  center_z <- runif(1, 2, 4)
  radius <- runif(1, 0.3, 0.6)
  
  theta <- runif(n, 0, 2*pi)
  phi <- acos(runif(n, -1, 1))
  
  cbind(
    center_x + radius * sin(phi) * cos(theta) + rnorm(n, 0, 0.02),
    center_y + radius * sin(phi) * sin(theta) + rnorm(n, 0, 0.02),
    center_z + radius * cos(phi) + rnorm(n, 0, 0.02)
  )
})
sphere_pts <- do.call(rbind, sphere_pts_list)

# Generate cylinders (pipes, posts)
n_cylinders <- 2
cylinder_pts_list <- lapply(1:n_cylinders, function(i) {
  n <- sample(100:150, 1)
  base_x <- runif(1, -7, 7)
  base_y <- runif(1, -7, 7)
  base_z <- runif(1, 0, 1)
  radius <- runif(1, 0.2, 0.4)
  height <- runif(1, 2, 4)
  
  h <- runif(n, 0, height)
  theta <- runif(n, 0, 2*pi)
  
  cbind(
    base_x + radius * cos(theta) + rnorm(n, 0, 0.02),
    base_y + radius * sin(theta) + rnorm(n, 0, 0.02),
    base_z + h + rnorm(n, 0, 0.02)
  )
})
cylinder_pts <- do.call(rbind, cylinder_pts_list)

# Generate traffic cones
n_cones <- 2
cone_pts_list <- lapply(1:n_cones, function(i) {
  n <- sample(100:150, 1)
  apex_x <- runif(1, -6, 6)
  apex_y <- runif(1, -6, 6)
  apex_z <- runif(1, 2.5, 4)
  height <- runif(1, 2, 3)
  half_angle <- runif(1, 0.25, 0.35)
  
  h <- runif(n, 0.2, height)
  theta <- runif(n, 0, 2*pi)
  r <- h * tan(half_angle)
  
  cbind(
    apex_x + r * cos(theta) + rnorm(n, 0, 0.02),
    apex_y + r * sin(theta) + rnorm(n, 0, 0.02),
    apex_z - h + rnorm(n, 0, 0.02)
  )
})
cone_pts <- do.call(rbind, cone_pts_list)

# Generate a ground plane
n_plane_pts <- 800
plane_pts <- cbind(
  runif(n_plane_pts, -10, 10),
  runif(n_plane_pts, -10, 10),
  rnorm(n_plane_pts, 0, 0.05)
)

# Generate some lines (edges, poles)
n_lines <- 3
line_pts_list <- lapply(1:n_lines, function(i) {
  n <- sample(60:100, 1)
  t <- seq(0, 1, length.out = n)
  
  x0 <- runif(1, -8, 8)
  y0 <- runif(1, -8, 8)
  z0 <- runif(1, 0.5, 2)
  
  x1 <- runif(1, -8, 8)
  y1 <- runif(1, -8, 8)
  z1 <- runif(1, 2, 5)
  
  cbind(
    x0 + t * (x1 - x0) + rnorm(n, 0, 0.03),
    y0 + t * (y1 - y0) + rnorm(n, 0, 0.03),
    z0 + t * (z1 - z0) + rnorm(n, 0, 0.03)
  )
})
line_pts <- do.call(rbind, line_pts_list)

# Generate cubes
n_cubes <- 2
cube_pts_list <- lapply(1:n_cubes, function(i) {
  n <- sample(150:200, 1)
  center_x <- runif(1, -5, 5)
  center_y <- runif(1, -5, 5)
  center_z <- runif(1, 2, 3)
  size <- runif(1, 0.8, 1.2)
  half <- size / 2
  
  face_pts <- lapply(1:6, function(f) {
    n_face <- ceiling(n / 6)
    u <- runif(n_face, -half, half)
    v <- runif(n_face, -half, half)
    
    if (f == 1) cbind(half, u, v)
    else if (f == 2) cbind(-half, u, v)
    else if (f == 3) cbind(u, half, v)
    else if (f == 4) cbind(u, -half, v)
    else if (f == 5) cbind(u, v, half)
    else cbind(u, v, -half)
  })
  
  pts <- do.call(rbind, face_pts)
  cbind(
    center_x + pts[, 1] + rnorm(nrow(pts), 0, 0.02),
    center_y + pts[, 2] + rnorm(nrow(pts), 0, 0.02),
    center_z + pts[, 3] + rnorm(nrow(pts), 0, 0.02)
  )
})
cube_pts <- do.call(rbind, cube_pts_list)

# Generate rectangular cuboids
n_cuboids <- 2
cuboid_pts_list <- lapply(1:n_cuboids, function(i) {
  n <- sample(150:200, 1)
  center_x <- runif(1, -4, 4)
  center_y <- runif(1, -4, 4)
  center_z <- runif(1, 1.5, 2.5)
  width <- runif(1, 1.5, 2.5)
  depth <- runif(1, 0.5, 1.0)
  height <- runif(1, 1.0, 1.5)
  
  hw <- width / 2
  hd <- depth / 2
  hh <- height / 2
  
  face_pts <- lapply(1:6, function(f) {
    n_face <- ceiling(n / 6)
    
    if (f == 1) {
      cbind(hw, runif(n_face, -hd, hd), runif(n_face, -hh, hh))
    } else if (f == 2) {
      cbind(-hw, runif(n_face, -hd, hd), runif(n_face, -hh, hh))
    } else if (f == 3) {
      cbind(runif(n_face, -hw, hw), hd, runif(n_face, -hh, hh))
    } else if (f == 4) {
      cbind(runif(n_face, -hw, hw), -hd, runif(n_face, -hh, hh))
    } else if (f == 5) {
      cbind(runif(n_face, -hw, hw), runif(n_face, -hd, hd), hh)
    } else {
      cbind(runif(n_face, -hw, hw), runif(n_face, -hd, hd), -hh)
    }
  })
  
  pts <- do.call(rbind, face_pts)
  cbind(
    center_x + pts[, 1] + rnorm(nrow(pts), 0, 0.02),
    center_y + pts[, 2] + rnorm(nrow(pts), 0, 0.02),
    center_z + pts[, 3] + rnorm(nrow(pts), 0, 0.02)
  )
})
cuboid_pts <- do.call(rbind, cuboid_pts_list)

# Add noise
n_noise <- 200
noise_pts <- cbind(
  runif(n_noise, -10, 10),
  runif(n_noise, -10, 10),
  runif(n_noise, 0, 6)
)

# Combine all
all_points <- rbind(sphere_pts, cylinder_pts, cone_pts, plane_pts, 
                    line_pts, cube_pts, cuboid_pts, noise_pts)
n_total <- nrow(all_points)

cat(sprintf("  Generated %d points:\n", n_total))
cat(sprintf("    * %d sphere points (%d spheres)\n", nrow(sphere_pts), n_spheres))
cat(sprintf("    * %d cylinder points (%d cylinders)\n", nrow(cylinder_pts), n_cylinders))
cat(sprintf("    * %d cone points (%d cones)\n", nrow(cone_pts), n_cones))
cat(sprintf("    * %d plane points\n", nrow(plane_pts)))
cat(sprintf("    * %d line points (%d lines)\n", nrow(line_pts), n_lines))
cat(sprintf("    * %d cube points (%d cubes)\n", nrow(cube_pts), n_cubes))
cat(sprintf("    * %d cuboid points (%d cuboids)\n", nrow(cuboid_pts), n_cuboids))
cat(sprintf("    * %d noise points\n", nrow(noise_pts)))

# ============================================================================
# 2-8. CUMULATIVE DETECTION - ALL 7 SHAPE TYPES
# ============================================================================

cat("\nStep 2: Pass 1 - Detecting spheres...\n")
spheres_result <- detect_spheres(all_points, min_radius=0.2, max_radius=1.0, 
                                  min_votes=50, label_points=TRUE)
sphere_labels <- spheres_result$point_labels
sphere_binary <- ifelse(sphere_labels > 0, 1, 0)
cat(sprintf("  Detected %d spheres, %d points labeled (%.1f%%)\n", 
            spheres_result$n_spheres, sum(sphere_binary), 
            100*sum(sphere_binary)/n_total))

cat("\nStep 3: Pass 2 - Detecting cylinders...\n")
cylinders_result <- detect_cylinders(all_points, min_radius=0.15, max_radius=0.6, 
                                      min_length=1.5, min_votes=60, label_points=TRUE)
cylinder_labels <- cylinders_result$point_labels
cylinder_binary <- ifelse(cylinder_labels > 0, 1, 0)
cat(sprintf("  Detected %d cylinders, %d points labeled (%.1f%%)\n", 
            cylinders_result$n_cylinders, sum(cylinder_binary), 
            100*sum(cylinder_binary)/n_total))

cat("\nStep 4: Pass 3 - Detecting cones...\n")
cones_result <- detect_cones(all_points, min_radius=0.1, max_radius=2.0, 
                              min_height=1.5, max_height=4.0, min_votes=60, 
                              angle_threshold=0.4, label_points=TRUE)
cone_labels <- cones_result$point_labels
cone_binary <- ifelse(cone_labels > 0, 1, 0)
cat(sprintf("  Detected %d cones, %d points labeled (%.1f%%)\n", 
            cones_result$n_cones, sum(cone_binary), 
            100*sum(cone_binary)/n_total))

cat("\nStep 5: Pass 4 - Detecting planes...\n")
planes_result <- detect_planes(all_points, distance_threshold=0.15, min_votes=100, 
                                max_iterations=1000, label_points=TRUE)
plane_labels <- planes_result$point_labels
plane_binary <- ifelse(plane_labels > 0, 1, 0)
cat(sprintf("  Detected %d planes, %d points labeled (%.1f%%)\n", 
            planes_result$n_planes, sum(plane_binary), 
            100*sum(plane_binary)/n_total))

cat("\nStep 6: Pass 5 - Detecting lines...\n")
lines_result <- detect_lines(all_points, distance_threshold=0.08, min_votes=30, 
                              min_length=0.5, max_iterations=500, label_points=TRUE)
line_labels <- lines_result$point_labels
line_binary <- ifelse(line_labels > 0, 1, 0)
cat(sprintf("  Detected %d lines, %d points labeled (%.1f%%)\n", 
            lines_result$n_lines, sum(line_binary), 
            100*sum(line_binary)/n_total))

cat("\nStep 7: Pass 6 - Detecting cubes...\n")
cubes_result <- detect_cubes(all_points, min_size=0.6, max_size=1.5, 
                              min_votes=80, plane_threshold=0.08, label_points=TRUE)
cube_labels <- cubes_result$point_labels
cube_binary <- ifelse(cube_labels > 0, 1, 0)
cat(sprintf("  Detected %d cubes, %d points labeled (%.1f%%)\n", 
            cubes_result$n_cubes, sum(cube_binary), 
            100*sum(cube_binary)/n_total))

cat("\nStep 8: Pass 7 - Detecting cuboids...\n")
cuboids_result <- detect_cuboids(all_points, min_width=0.5, max_width=3.0, 
                                  min_height=0.5, max_height=2.0, min_votes=100, 
                                  plane_threshold=0.1, label_points=TRUE)
cuboid_labels <- cuboids_result$point_labels
cuboid_binary <- ifelse(cuboid_labels > 0, 1, 0)
cat(sprintf("  Detected %d cuboids, %d points labeled (%.1f%%)\n", 
            cuboids_result$n_cuboids, sum(cuboid_binary), 
            100*sum(cuboid_binary)/n_total))

# ============================================================================
# 9. ACCUMULATE VOTES
# ============================================================================

cat("\nStep 9: Accumulating votes across all 7 detection passes...\n")

vote_count <- sphere_binary + cylinder_binary + cone_binary + 
              plane_binary + line_binary + cube_binary + cuboid_binary

vote_table <- table(vote_count)
cat("\nVote Distribution:\n")
for (v in names(vote_table)) {
  cat(sprintf("  %s vote(s): %d points (%.1f%%)\n", 
              v, vote_table[v], 100*vote_table[v]/n_total))
}

multi_votes <- sum(vote_count > 1)
any_shape <- sum(vote_count > 0)
unclassified <- sum(vote_count == 0)

cat(sprintf("\nPoints belonging to MULTIPLE shape types: %d (%.1f%%)\n", 
            multi_votes, 100*multi_votes/n_total))
cat(sprintf("Points belonging to ANY shape: %d (%.1f%%)\n", 
            any_shape, 100*any_shape/n_total))
cat(sprintf("Unclassified points (likely noise): %d (%.1f%%)\n", 
            unclassified, 100*unclassified/n_total))

# ============================================================================
# 10. CREATE DATA FRAME
# ============================================================================

cat("\nStep 10: Creating comprehensive results data frame...\n")

results_df <- data.frame(
  x = all_points[, 1],
  y = all_points[, 2],
  z = all_points[, 3],
  is_sphere = sphere_binary,
  is_cylinder = cylinder_binary,
  is_cone = cone_binary,
  is_plane = plane_binary,
  is_line = line_binary,
  is_cube = cube_binary,
  is_cuboid = cuboid_binary,
  total_votes = vote_count,
  sphere_id = sphere_labels,
  cylinder_id = cylinder_labels,
  cone_id = cone_labels,
  plane_id = plane_labels,
  line_id = line_labels,
  cube_id = cube_labels,
  cuboid_id = cuboid_labels
)

cat(sprintf("  Created data frame with %d rows and %d columns\n", 
            nrow(results_df), ncol(results_df)))

# ============================================================================
# 11. DETAILED ANALYSIS
# ============================================================================

cat("\n=== DETAILED ANALYSIS ===\n\n")
cat("Vote Count Analysis:\n")
for (v in 0:max(vote_count)) {
  mask <- vote_count == v
  n_pts <- sum(mask)
  
  if (n_pts > 0) {
    cat(sprintf("\n%d vote(s) - %d points:\n", v, n_pts))
    
    if (v == 0) {
      cat("  Classification: Unclassified (noise)\n")
    } else {
      in_sphere <- sum(mask & sphere_binary == 1)
      in_cylinder <- sum(mask & cylinder_binary == 1)
      in_cone <- sum(mask & cone_binary == 1)
      in_plane <- sum(mask & plane_binary == 1)
      in_line <- sum(mask & line_binary == 1)
      in_cube <- sum(mask & cube_binary == 1)
      in_cuboid <- sum(mask & cuboid_binary == 1)
      
      shape_types <- c()
      if (in_sphere > 0) shape_types <- c(shape_types, sprintf("sphere (%d)", in_sphere))
      if (in_cylinder > 0) shape_types <- c(shape_types, sprintf("cylinder (%d)", in_cylinder))
      if (in_cone > 0) shape_types <- c(shape_types, sprintf("cone (%d)", in_cone))
      if (in_plane > 0) shape_types <- c(shape_types, sprintf("plane (%d)", in_plane))
      if (in_line > 0) shape_types <- c(shape_types, sprintf("line (%d)", in_line))
      if (in_cube > 0) shape_types <- c(shape_types, sprintf("cube (%d)", in_cube))
      if (in_cuboid > 0) shape_types <- c(shape_types, sprintf("cuboid (%d)", in_cuboid))
      
      cat(sprintf("  Shape types: %s\n", paste(shape_types, collapse = ", ")))
    }
  }
}

# ============================================================================
# 12. VISUALIZATION COLORS
# ============================================================================

cat("\n=== VISUALIZATION COLOR ASSIGNMENT ===\n\n")

max_votes <- max(vote_count)
vote_colors <- hough_palette(max_votes + 1)[vote_count + 1]

cat(sprintf("Color coding by vote count (0-%d votes):\n", max_votes))
for (v in 0:min(max_votes, 7)) {
  n_pts <- sum(vote_count == v)
  if (n_pts > 0) {
    cat(sprintf("  %d vote(s): Color %d (%d points)\n", v, v + 1, n_pts))
  }
}

cat("\nExample visualization with lidR:\n")
cat("  library(lidR)\n")
cat("  las <- LAS(results_df)\n")
cat("  las$vote_count <- results_df$total_votes\n")
cat("  plot(las, color = 'vote_count')\n")

# ============================================================================
# 13. FINAL SUMMARY
# ============================================================================

cat("\n=== FINAL SUMMARY ===\n\n")

cat(sprintf("Total points processed: %d\n", n_total))
cat(sprintf("Detection passes: 7 (all primitive shapes)\n\n"))
cat("Shape detection results:\n")
cat(sprintf("  Spheres: %d detected, %d points\n", 
            spheres_result$n_spheres, sum(sphere_binary)))
cat(sprintf("  Cylinders: %d detected, %d points\n", 
            cylinders_result$n_cylinders, sum(cylinder_binary)))
cat(sprintf("  Cones: %d detected, %d points\n", 
            cones_result$n_cones, sum(cone_binary)))
cat(sprintf("  Planes: %d detected, %d points\n", 
            planes_result$n_planes, sum(plane_binary)))
cat(sprintf("  Lines: %d detected, %d points\n", 
            lines_result$n_lines, sum(line_binary)))
cat(sprintf("  Cubes: %d detected, %d points\n", 
            cubes_result$n_cubes, sum(cube_binary)))
cat(sprintf("  Cuboids: %d detected, %d points\n", 
            cuboids_result$n_cuboids, sum(cuboid_binary)))

cat("\nCumulative classification:\n")
cat(sprintf("  Classified points: %d (%.1f%%)\n", 
            any_shape, 100*any_shape/n_total))
cat(sprintf("  Unclassified points: %d (%.1f%%)\n", 
            unclassified, 100*unclassified/n_total))
cat(sprintf("  Multi-class points: %d (%.1f%%)\n", 
            multi_votes, 100*multi_votes/n_total))

cat("\n✓ Cumulative detection workflow complete!\n\n")
cat("Output: 'results_df' data frame with columns:\n")
cat("  - x, y, z: Point coordinates\n")
cat("  - is_sphere, is_cylinder, is_cone, is_plane, is_line, is_cube, is_cuboid: Binary flags (0/1)\n")
cat("  - total_votes: Sum of all binary flags (0-7)\n")
cat("  - sphere_id, cylinder_id, cone_id, plane_id, line_id, cube_id, cuboid_id: Specific shape IDs\n\n")

# ============================================================================
# 14. VISUALIZATION WITH lidR
# ============================================================================

cat("\n=== CREATING VISUALIZATION ===\n\n")

library(lidR)

# Create LAS object
las <- LAS(data.frame(
  X = results_df$x,
  Y = results_df$y,
  Z = results_df$z,
  Votes = as.integer(results_df$total_votes)
))

cat("Plotting point cloud colored by vote count...\n")
cat(sprintf("  Vote range: %d to %d\n", min(las$Votes), max(las$Votes)))
cat("  Higher votes = point detected by multiple shape types\n\n")

plot(las, color = "Votes", size = 3)

cat("\n✓ Visualization complete!\n")
