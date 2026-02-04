# Example 2: Basic Point Cloud Analysis
# =======================================

library(houghPrimitives)

# This example demonstrates basic point cloud summarization
# Currently showing the functionality that's implemented

# Generate synthetic building-like data
set.seed(456)

# Create a simple rectangular building footprint
building_length <- 20  # meters
building_width <- 15   # meters
building_height <- 10  # meters

# Generate points on building surfaces
n_points_per_face <- 500

# Floor points
floor_x <- runif(n_points_per_face, 0, building_length)
floor_y <- runif(n_points_per_face, 0, building_width)
floor_z <- rnorm(n_points_per_face, 0, 0.1)

# Roof points
roof_x <- runif(n_points_per_face, 0, building_length)
roof_y <- runif(n_points_per_face, 0, building_width)
roof_z <- rnorm(n_points_per_face, building_height, 0.1)

# Wall 1 (length side)
wall1_x <- runif(n_points_per_face, 0, building_length)
wall1_y <- rnorm(n_points_per_face, 0, 0.1)
wall1_z <- runif(n_points_per_face, 0, building_height)

# Wall 2 (width side)  
wall2_x <- rnorm(n_points_per_face, 0, 0.1)
wall2_y <- runif(n_points_per_face, 0, building_width)
wall2_z <- runif(n_points_per_face, 0, building_height)

# Combine all points
xyz_building <- rbind(
  cbind(floor_x, floor_y, floor_z),
  cbind(roof_x, roof_y, roof_z),
  cbind(wall1_x, wall1_y, wall1_z),
  cbind(wall2_x, wall2_y, wall2_z)
)

# Analyze the point cloud
summary <- summarize_points(xyz_building)

cat("=== Building Point Cloud Summary ===\n")
cat("Total points:", summary$n_points, "\n")
cat("X range:", round(summary$x_range, 2), "m\n")
cat("Y range:", round(summary$y_range, 2), "m\n") 
cat("Z range (height):", round(summary$z_range, 2), "m\n")

# Calculate derived metrics
footprint_area <- diff(summary$x_range) * diff(summary$y_range)
height <- diff(summary$z_range)
volume <- footprint_area * height

cat("\nDerived Metrics:\n")
cat("Footprint area:", round(footprint_area, 1), "m²\n")
cat("Building height:", round(height, 1), "m\n")
cat("Approximate volume:", round(volume, 1), "m³\n")

# Visualize if rgl is available
if (requireNamespace("rgl", quietly = TRUE)) {
  library(rgl)
  
  # Color by height
  colors <- colorRampPalette(c("blue", "green", "yellow", "red"))(100)
  z_normalized <- (xyz_building[,3] - min(xyz_building[,3])) / 
                  (max(xyz_building[,3]) - min(xyz_building[,3]))
  point_colors <- colors[pmin(100, ceiling(z_normalized * 100))]
  
  plot3d(xyz_building[,1], xyz_building[,2], xyz_building[,3],
         col = point_colors,
         size = 3,
         xlab = "X (m)", ylab = "Y (m)", zlab = "Z (m)",
         main = "Building Point Cloud")
}

# NOTE: Full building detection with detect_buildings() will be 
# implemented in future versions. This example shows the current
# basic functionality available in the package.

# Visualize with lidR
cat("\n=== Visualization with lidR ===\n")
library(lidR)

# Create LAS object
las <- LAS(data.frame(
  X = xyz_building[,1],
  Y = xyz_building[,2],
  Z = xyz_building[,3]
))

cat("Plotting building point cloud...\n")
plot(las, color = "Z", size = 3)
