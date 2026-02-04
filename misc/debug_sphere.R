library(houghPrimitives)

# Simple sphere test with diagnostics
sphere_points <- matrix(0, ncol=3, nrow=0)
for (phi in seq(0, pi, length.out=15)) {
  for (theta in seq(0, 2*pi, length.out=25)) {
    r <- 1.0
    x <- 5 + r * sin(phi) * cos(theta) + rnorm(1, sd=0.01)
    y <- 5 + r * sin(phi) * sin(theta) + rnorm(1, sd=0.01)
    z <- 2 + r * cos(phi) + rnorm(1, sd=0.01)
    sphere_points <- rbind(sphere_points, c(x, y, z))
  }
}

cat(sprintf("Generated %d sphere points\n", nrow(sphere_points)))
cat(sprintf("X range: %.2f to %.2f\n", min(sphere_points[,1]), max(sphere_points[,1])))
cat(sprintf("Y range: %.2f to %.2f\n", min(sphere_points[,2]), max(sphere_points[,2])))
cat(sprintf("Z range: %.2f to %.2f\n", min(sphere_points[,3]), max(sphere_points[,3])))

# Calculate distances from center
cx <- 5; cy <- 5; cz <- 2
dists <- sqrt((sphere_points[,1]-cx)^2 + (sphere_points[,2]-cy)^2 + (sphere_points[,3]-cz)^2)
cat(sprintf("Distance from (5,5,2): mean=%.3f, sd=%.3f, min=%.3f, max=%.3f\n",
            mean(dists), sd(dists), min(dists), max(dists)))

# Check octants
octants <- rep(0, 8)
for (i in 1:nrow(sphere_points)) {
  dx <- sphere_points[i,1] - cx
  dy <- sphere_points[i,2] - cy
  dz <- sphere_points[i,3] - cz
  oct <- ((dx > 0) * 1) + ((dy > 0) * 2) + ((dz > 0) * 4) + 1
  octants[oct] <- octants[oct] + 1
}
cat("Octant distribution:\n")
print(octants)
cat(sprintf("Occupied octants: %d\n", sum(octants > 0)))

# Try detection with relaxed parameters
result <- detect_spheres(sphere_points, min_radius=0.5, max_radius=1.5, min_votes=80)
cat(sprintf("\nDetected %d spheres\n", result$n_spheres))
if (result$n_spheres > 0) print(result$spheres)

# Try even more relaxed
result2 <- detect_spheres(sphere_points, min_radius=0.5, max_radius=1.5, min_votes=50)
cat(sprintf("\nWith min_votes=50: Detected %d spheres\n", result2$n_spheres))
if (result2$n_spheres > 0) print(result2$spheres)
