# Example 1: Tree Bole Detection in Forest LiDAR Data
# =====================================================

library(houghPrimitives)
library(lidR)

# This example demonstrates tree detection in a forest plot
# You can use this with lidR LAS objects or plain matrices

# Example 1: Using a matrix of XYZ coordinates
# Generate synthetic tree data for demonstration
set.seed(123)
n_trees <- 5
xyz_all <- NULL

for (i in 1:n_trees) {
  # Random tree location
  tree_x <- runif(1, 0, 20)
  tree_y <- runif(1, 0, 20)
  tree_radius <- runif(1, 0.15, 0.40)
  tree_height <- runif(1, 1.5, 3.0)
  
  # Generate points around cylinder
  n_points <- 200
  angles <- runif(n_points, 0, 2*pi)
  radii <- abs(rnorm(n_points, tree_radius, 0.03))
  heights <- runif(n_points, 0.5, 0.5 + tree_height)
  
  tree_xyz <- cbind(
    tree_x + radii * cos(angles),
    tree_y + radii * sin(angles),
    heights
  )
  xyz_all <- rbind(xyz_all, tree_xyz)
}

# Detect tree boles
# Adjust parameters based on your forest type:
# - Tropical forest: larger min/max radius
# - Young plantation: smaller min/max radius
trees <- detect_tree_boles(
  xyz_all,
  min_radius = 0.08,      # 8 cm minimum DBH
  max_radius = 0.60,      # 60 cm maximum DBH  
  min_height = 1.0,       # At least 1m of visible trunk
  min_votes = 50,         # Minimum points per tree
  vertical_only = TRUE,   # Only detect vertical trunks
  label_points = TRUE     # Label all points
)

# View results
print(trees)
cat("\n=== Detection Results ===\n")
cat("Trees detected:", trees$n_trees, "\n")

if (trees$n_trees > 0) {
  cat("\nTree Details:\n")
  print(trees$trees)
  
  # Visualize point labels if requested
  if (!is.null(trees$point_labels)) {
    # Simple 3D scatter plot (if rgl is available)
    if (requireNamespace("rgl", quietly = TRUE)) {
      library(rgl)
      
      # Color by tree ID
      colors <- rainbow(trees$n_trees + 1)
      point_colors <- colors[trees$point_labels + 1]
      
      plot3d(xyz_all[,1], xyz_all[,2], xyz_all[,3],
             col = point_colors,
             size = 3,
             xlab = "X", ylab = "Y", zlab = "Z",
             main = "Detected Trees")
      
      # Add tree centers
      with(trees$trees, {
        points3d(x, y, rep(1.5, length(x)), 
                col = "black", size = 10)
      })
    }
  }
  
  # Calculate forest metrics
  cat("\n=== Forest Metrics ===\n")
  cat("Total trees detected:", trees$n_trees, "\n")
  cat("Mean DBH:", round(mean(trees$trees$radius * 2 * 100), 1), "cm\n")
  cat("SD DBH:", round(sd(trees$trees$radius * 2 * 100), 1), "cm\n")
  cat("DBH range:", round(min(trees$trees$radius * 2 * 100), 1), "-",
      round(max(trees$trees$radius * 2 * 100), 1), "cm\n")
  cat("Mean height:", round(mean(trees$trees$height), 2), "m\n")
  
  cat("\n=== VISUALIZING WITH lidR ===\n")
  
  # Create LAS object with tree classifications
  library(lidR)
  
  classification <- as.integer(trees$point_labels)
  classification[classification == 0L] <- 1L  # Unclassified/ground
  classification[classification > 0L] <- 5L   # Vegetation (trees)
  
  las <- LAS(data.frame(
    X = xyz_all[,1],
    Y = xyz_all[,2],
    Z = xyz_all[,3],
    Classification = classification,
    TreeID = as.integer(trees$point_labels)
  ))
  
  cat("Plotting forest with detected tree boles...\\n")
  plot(las, color = "TreeID", size = 3)
  
  cat("\\nVisualization complete!\\n")
  
  # Create DBH distribution histogram
  hist(trees$trees$radius * 2 * 100,
       breaks = 10,
       main = "DBH Distribution",
       xlab = "DBH (cm)",
       ylab = "Frequency",
       col = "forestgreen")
}

# Example 2: Using with lidR LAS objects
# (Uncomment if you have lidR installed and a LAS file)
# 
library(lidR)
las <- readLAS("D:/OneDrive - Northern Arizona University/GitHubRepos/spanner/inst/extdata/TLS_Clip.laz")
# 
# # Extract XYZ coordinates
xyz <- cbind(las@data$X, las@data$Y, las@data$Z)
# 
# # Filter to stem height (0.5m to 3m)
stem_indices <- which(las@data$Z >= 0.5 & las@data$Z <= 3.0)
xyz_stems <- xyz[stem_indices, ]
# 
# # Detect trees
trees <- detect_tree_boles(
  xyz_stems,
  min_radius = 0.08,
  max_radius = 0.60,
  min_height = 1.0,
  min_votes = 50,
  vertical_only = TRUE,
  label_points = TRUE
)
# 
# # Add labels back to LAS
las@data$TreeID <- 0
las@data$TreeID[stem_indices] <- trees$point_labels
# 
# # Visualize
plot(las, color = "TreeID")
