# Example: Sphere Detection with Varying Noise
# Demonstrates detecting spherical objects in point clouds with different noise patterns

library(houghPrimitives)
library(lidR)

set.seed(42)

# Function to generate points on a sphere surface
generate_sphere <- function(center_x, center_y, center_z, radius, n_points = 200) {
  # Use spherical coordinates to generate uniform distribution on sphere
  theta <- runif(n_points, 0, 2 * pi)  # azimuthal angle
  phi <- acos(2 * runif(n_points) - 1)  # polar angle (uniform on sphere)
  
  # Convert to Cartesian coordinates
  x <- center_x + radius * sin(phi) * cos(theta)
  y <- center_y + radius * sin(phi) * sin(theta)
  z <- center_z + radius * cos(phi)
  
  cbind(x, y, z)
}

# Function to add uniform random noise
add_uniform_noise <- function(bounds, n_points) {
  x <- runif(n_points, bounds$xmin, bounds$xmax)
  y <- runif(n_points, bounds$ymin, bounds$ymax)
  z <- runif(n_points, bounds$zmin, bounds$zmax)
  cbind(x, y, z)
}

# Function to add clustered noise
add_clustered_noise <- function(bounds, n_clusters = 5, points_per_cluster = 50) {
  noise <- NULL
  for (i in 1:n_clusters) {
    cx <- runif(1, bounds$xmin, bounds$xmax)
    cy <- runif(1, bounds$ymin, bounds$ymax)
    cz <- runif(1, bounds$zmin, bounds$zmax)
    
    x <- cx + rnorm(points_per_cluster, sd = 0.5)
    y <- cy + rnorm(points_per_cluster, sd = 0.5)
    z <- cz + rnorm(points_per_cluster, sd = 0.5)
    
    noise <- rbind(noise, cbind(x, y, z))
  }
  noise
}

# Function to add ground plane noise
add_ground_plane <- function(bounds, n_points = 500, z_level = 0) {
  x <- runif(n_points, bounds$xmin, bounds$xmax)
  y <- runif(n_points, bounds$ymin, bounds$ymax)
  z <- rep(z_level, n_points) + rnorm(n_points, sd = 0.05)
  cbind(x, y, z)
}

cat("\n=== Generating Synthetic Spheres ===\n")

# Generate 4 spheres with different sizes
spheres <- list(
  list(x = 5, y = 5, z = 3, r = 1.2, n = 300),
  list(x = 12, y = 8, z = 2.5, r = 0.8, n = 250),
  list(x = 8, y = 15, z = 4, r = 1.5, n = 400),
  list(x = 15, y = 15, z = 1.8, r = 0.6, n = 200)
)

sphere_points <- NULL
for (i in seq_along(spheres)) {
  s <- spheres[[i]]
  pts <- generate_sphere(s$x, s$y, s$z, s$r, s$n)
  sphere_points <- rbind(sphere_points, pts)
  cat(sprintf("  Sphere %d: center=(%.1f, %.1f, %.1f), radius=%.2fm, points=%d\n",
              i, s$x, s$y, s$z, s$r, s$n))
}

cat(sprintf("\nTotal sphere points: %d\n", nrow(sphere_points)))

# Define scene bounds
bounds <- list(
  xmin = 0, xmax = 20,
  ymin = 0, ymax = 20,
  zmin = 0, zmax = 6
)

cat("\n=== Adding Noise ===\n")

# Add different types of noise
noise_uniform <- add_uniform_noise(bounds, 300)
cat(sprintf("  Uniform noise: %d points\n", nrow(noise_uniform)))

noise_clusters <- add_clustered_noise(bounds, n_clusters = 8, points_per_cluster = 40)
cat(sprintf("  Clustered noise: %d points\n", nrow(noise_clusters)))

noise_ground <- add_ground_plane(bounds, n_points = 400, z_level = 0)
cat(sprintf("  Ground plane: %d points\n", nrow(noise_ground)))

# Combine all points
all_points <- rbind(
  sphere_points,
  noise_uniform,
  noise_clusters,
  noise_ground
)

cat(sprintf("\nTotal points in scene: %d\n", nrow(all_points)))
cat(sprintf("  Signal (spheres): %d (%.1f%%)\n", 
            nrow(sphere_points), 100 * nrow(sphere_points) / nrow(all_points)))
cat(sprintf("  Noise: %d (%.1f%%)\n", 
            nrow(all_points) - nrow(sphere_points), 
            100 * (nrow(all_points) - nrow(sphere_points)) / nrow(all_points)))

cat("\n=== Detecting Spheres ===\n")

# Detect spheres in the noisy point cloud
result <- detect_spheres(
  xyz = all_points,
  min_radius = 0.5,
  max_radius = 2.0,
  min_votes = 50,
  label_points = TRUE
)

cat(sprintf("Spheres detected: %d\n", result$n_spheres))

if (result$n_spheres > 0) {
  cat("\n=== Detection Results ===\n")
  print(result$spheres)
  
  cat("\n=== Ground Truth Comparison ===\n")
  for (i in seq_along(spheres)) {
    s <- spheres[[i]]
    cat(sprintf("True Sphere %d: center=(%.1f, %.1f, %.1f), radius=%.2fm\n",
                i, s$x, s$y, s$z, s$r))
  }
  
  cat("\n=== Detection Accuracy ===\n")
  if (result$n_spheres > 0) {
    detected <- result$spheres
    
    # Match detected spheres to ground truth
    for (i in 1:nrow(detected)) {
      d <- detected[i,]
      
      # Find closest ground truth sphere
      min_dist <- Inf
      closest_idx <- NA
      for (j in seq_along(spheres)) {
        s <- spheres[[j]]
        dist <- sqrt((d$x - s$x)^2 + (d$y - s$y)^2 + (d$z - s$z)^2)
        if (dist < min_dist) {
          min_dist <- dist
          closest_idx <- j
        }
      }
      
      if (!is.na(closest_idx)) {
        s <- spheres[[closest_idx]]
        center_error <- min_dist
        radius_error <- abs(d$radius - s$r)
        
        cat(sprintf("\nDetected sphere %d matches True sphere %d:\n", i, closest_idx))
        cat(sprintf("  Center error: %.3fm\n", center_error))
        cat(sprintf("  Radius error: %.3fm (%.1f%%)\n", 
                    radius_error, 100 * radius_error / s$r))
        cat(sprintf("  Points captured: %d (expected ~%d)\n", d$n_points, s$n))
      }
    }
  }
  
  # Point classification summary
  cat("\n=== Point Classification ===\n")
  labels <- result$point_labels
  n_classified <- sum(labels > 0)
  n_unclassified <- sum(labels == 0)
  
  cat(sprintf("Points assigned to spheres: %d (%.1f%%)\n", 
              n_classified, 100 * n_classified / length(labels)))
  cat(sprintf("Points unclassified (noise): %d (%.1f%%)\n", 
              n_unclassified, 100 * n_unclassified / length(labels)))
  
  # Calculate precision and recall
  n_sphere_points <- nrow(sphere_points)
  n_noise_points <- nrow(all_points) - n_sphere_points
  
  # True positives: sphere points correctly classified
  true_positives <- sum(labels[1:n_sphere_points] > 0)
  # False positives: noise points incorrectly classified as spheres
  false_positives <- sum(labels[(n_sphere_points + 1):length(labels)] > 0)
  # False negatives: sphere points missed
  false_negatives <- sum(labels[1:n_sphere_points] == 0)
  
  precision <- true_positives / (true_positives + false_positives)
  recall <- true_positives / (true_positives + false_negatives)
  f1_score <- 2 * (precision * recall) / (precision + recall)
  
  cat("\n=== Classification Metrics ===\n")
  cat(sprintf("Precision: %.2f (%.1f%% of detected points are true sphere points)\n", 
              precision, 100 * precision))
  cat(sprintf("Recall: %.2f (%.1f%% of sphere points were detected)\n", 
              recall, 100 * recall))
  cat(sprintf("F1 Score: %.2f\n", f1_score))
  
} else {
  cat("No spheres detected!\n")
}

cat("\n=== VISUALIZING WITH lidR ===\n")

# Create LAS object from point cloud
library(lidR)

# Add Classification field based on detection results
classification <- as.integer(result$point_labels)
classification[classification == 0L] <- 1L  # Unclassified
classification[classification > 0L] <- 6L   # Building (spheres)

# Create LAS object
las <- LAS(data.frame(
  X = all_points[,1],
  Y = all_points[,2],
  Z = all_points[,3],
  Classification = classification
))

cat("Plotting point cloud with detected spheres highlighted...\n")
plot(las, color = "Classification", size = 3)

cat("\nVisualization complete! Close the plot window to continue.\n")
