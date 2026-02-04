# Example 3: Point Cloud Analysis Demo
# ======================================

library(houghPrimitives)

# This example demonstrates the available functionality
# Future versions will include comprehensive shape classification

# Generate a mixed synthetic point cloud
set.seed(789)

# Create different synthetic features
n_ground_points <- 1000
n_tree_points <- 500
n_building_points <- 500

# Ground plane
ground_x <- runif(n_ground_points, 0, 50)
ground_y <- runif(n_ground_points, 0, 50)
ground_z <- rnorm(n_ground_points, 0, 0.1)

# Tree (cylinder)
tree_x <- rnorm(n_tree_points, 25, 0.2)
tree_y <- rnorm(n_tree_points, 25, 0.2)
tree_z <- runif(n_tree_points, 0, 15)

# Building (cuboid)
building_x <- runif(n_building_points, 35, 45)
building_y <- runif(n_building_points, 35, 45)
building_z <- runif(n_building_points, 0, 10)

# Combine all points
xyz_all <- rbind(
  cbind(ground_x, ground_y, ground_z),
  cbind(tree_x, tree_y, tree_z),
  cbind(building_x, building_y, building_z)
)

# Analyze the entire scene
cat("=== Overall Scene Summary ===\n")
summary_all <- summarize_points(xyz_all)
print(summary_all)

# Analyze individual components
cat("\n=== Ground Component ===\n")
summary_ground <- summarize_points(cbind(ground_x, ground_y, ground_z))
print(summary_ground)

cat("\n=== Tree Component ===\n")
summary_tree <- summarize_points(cbind(tree_x, tree_y, tree_z))
print(summary_tree)

# Detect trees using tree detection
cat("\n=== Tree Detection ===\n")
tree_xyz <- cbind(tree_x, tree_y, tree_z)
trees <- detect_tree_boles(
  tree_xyz,
  min_radius = 0.1,
  max_radius = 0.5,
  min_height = 5.0,
  min_votes = 100,
  vertical_only = TRUE,
  label_points = FALSE
)

cat("Trees detected:", trees$n_trees, "\n")
if (trees$n_trees > 0) {
  print(trees$trees)
}

cat("\n=== Building Component ===\n")
summary_building <- summarize_points(cbind(building_x, building_y, building_z))
print(summary_building)

# Visualize if rgl is available
if (requireNamespace("rgl", quietly = TRUE)) {
  library(rgl)
  
  # Create colors for different components
  colors_all <- c(
    rep("brown", n_ground_points),
    rep("green", n_tree_points),
    rep("gray", n_building_points)
  )
  
  plot3d(xyz_all[,1], xyz_all[,2], xyz_all[,3],
         col = colors_all,
         size = 3,
         xlab = "X (m)", ylab = "Y (m)", zlab = "Z (m)",
         main = "Mixed Point Cloud Scene")
  
  # Add legend manually
  cat("\nColors: Brown=Ground, Green=Tree, Gray=Building\n")
}

# Future functionality notes
cat("\n=== Future Capabilities ===\n")
cat("The following functions will be implemented:\n")
cat("- detect_planes() for ground/wall/roof detection\n")
cat("- detect_lines() for edge and power line detection\n")
cat("- detect_spheres() for specific object detection\n")
cat("- classify_point_shapes() for comprehensive classification\n")
cat("\nCurrently available:\n")
cat("- summarize_points() ✓\n")
cat("- detect_tree_boles() ✓\n")

# Visualize with lidR
cat("\n=== Visualization with lidR ===\n")
library(lidR)

# Create classification codes
classification <- c(
  rep(2L, n_ground_points),   # Ground
  rep(5L, n_tree_points),     # Vegetation
  rep(6L, n_building_points)  # Building
)

# Create LAS object
las <- LAS(data.frame(
  X = xyz_all[,1],
  Y = xyz_all[,2],
  Z = xyz_all[,3],
  Classification = classification
))

cat("Plotting scene with classifications...\n")
cat("  2 = Ground, 5 = Vegetation, 6 = Building\n")
plot(las, color = "Classification", size = 3)

