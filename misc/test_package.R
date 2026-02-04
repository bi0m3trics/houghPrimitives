# Quick test script to verify all detection functions work
library(houghPrimitives)

cat("=== Testing houghPrimitives Package ===\n\n")

# Generate test data
set.seed(123)
test_points <- matrix(rnorm(900, sd = 2), ncol = 3)

# Test each function
cat("1. Testing detect_spheres... ")
result1 <- detect_spheres(test_points)
cat(sprintf("✓ Found %d spheres\n", result1$n_spheres))

cat("2. Testing detect_cylinders... ")
result2 <- detect_cylinders(test_points)
cat(sprintf("✓ Found %d cylinders\n", result2$n_cylinders))

cat("3. Testing detect_tree_boles... ")
result3 <- detect_tree_boles(test_points)
cat(sprintf("✓ Found %d trees\n", result3$n_trees))

cat("4. Testing detect_planes... ")
result4 <- detect_planes(test_points)
cat(sprintf("✓ Found %d planes\n", result4$n_planes))

cat("5. Testing detect_lines... ")
result5 <- detect_lines(test_points)
cat(sprintf("✓ Found %d lines\n", result5$n_lines))

cat("6. Testing detect_cubes... ")
result6 <- detect_cubes(test_points)
cat(sprintf("✓ Found %d cubes\n", result6$n_cubes))

cat("7. Testing detect_cuboids... ")
result7 <- detect_cuboids(test_points)
cat(sprintf("✓ Found %d cuboids\n", result7$n_cuboids))

cat("8. Testing summarize_points... ")
result8 <- summarize_points(test_points)
cat(sprintf("✓ %d points analyzed\n", result8$n_points))

cat("\n=== ALL FUNCTIONS WORKING! ===\n")
cat("\nPackage exported functions:\n")
cat(paste0("  - ", ls("package:houghPrimitives"), collapse = "\n"))
cat("\n\nYou can now run the examples:\n")
cat("  source('examples/example_sphere_detection.R')\n")
cat("  source('examples/example_tree_detection.R')\n")
cat("  source('examples/example_all_shapes.R')\n")
