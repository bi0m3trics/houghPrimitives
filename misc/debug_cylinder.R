library(houghPrimitives)

# Simple cylinder test with diagnostics
cyl_points <- matrix(0, ncol=3, nrow=0)

# Generate a clean vertical cylinder
n_circles <- 20
points_per_circle <- 40
radius <- 0.35
cx <- 3
cy <- 3

for (i in 1:n_circles) {
  h <- (i-1) * 5 / (n_circles-1)  # Heights from 0 to 5
  for (j in 1:points_per_circle) {
    theta <- 2 * pi * j / points_per_circle
    x <- cx + radius * cos(theta) + rnorm(1, sd=0.01)
    y <- cy + radius * sin(theta) + rnorm(1, sd=0.01)
    z <- h + rnorm(1, sd=0.02)
    cyl_points <- rbind(cyl_points, c(x, y, z))
  }
}

cat(sprintf("Generated %d cylinder points\n", nrow(cyl_points)))
cat(sprintf("X range: %.2f to %.2f (center ~%.2f)\n", min(cyl_points[,1]), max(cyl_points[,1]), cx))
cat(sprintf("Y range: %.2f to %.2f (center ~%.2f)\n", min(cyl_points[,2]), max(cyl_points[,2]), cy))
cat(sprintf("Z range: %.2f to %.2f\n", min(cyl_points[,3]), max(cyl_points[,3])))

# Check radial distances
dists_xy <- sqrt((cyl_points[,1]-cx)^2 + (cyl_points[,2]-cy)^2)
cat(sprintf("Radial distance from (%.1f,%.1f): mean=%.3f, sd=%.3f\n",
            cx, cy, mean(dists_xy), sd(dists_xy)))

# Check height distribution
cat(sprintf("Height distribution: min=%.2f, max=%.2f, range=%.2f\n",
            min(cyl_points[,3]), max(cyl_points[,3]), 
            max(cyl_points[,3]) - min(cyl_points[,3])))

# Try detection
result <- detect_cylinders(cyl_points, min_radius=0.25, max_radius=0.50, min_length=3.0, min_votes=100)
cat(sprintf("\nDetected %d cylinders\n", result$n_cylinders))
if (result$n_cylinders > 0) print(result$cylinders)

# Try relaxed parameters
result2 <- detect_cylinders(cyl_points, min_radius=0.20, max_radius=0.60, min_length=2.0, min_votes=50)
cat(sprintf("\nWith relaxed params: Detected %d cylinders\n", result2$n_cylinders))
if (result2$n_cylinders > 0) print(result2$cylinders)
