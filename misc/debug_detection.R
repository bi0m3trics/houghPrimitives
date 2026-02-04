library(houghPrimitives)

# Test each shape type individually

# 1. Test cylinder detection
cat("=== TESTING CYLINDER DETECTION ===\n")
cyl_points <- matrix(0, ncol=3, nrow=0)
for (t in seq(0, 2*pi, length.out=80)) {
  for (h in seq(0, 5, by=0.3)) {
    r <- 0.35
    x <- 3 + r * cos(t) + rnorm(1, sd=0.015)
    y <- 3 + r * sin(t) + rnorm(1, sd=0.015)
    z <- h + rnorm(1, sd=0.02)
    cyl_points <- rbind(cyl_points, c(x, y, z))
  }
}

cat(sprintf("Generated %d cylinder points\n", nrow(cyl_points)))
result <- detect_cylinders(cyl_points, min_radius=0.25, max_radius=0.50, min_length=3.0, min_votes=50)
cat(sprintf("Detected %d cylinders\n", result$n_cylinders))
if (result$n_cylinders > 0) print(result$cylinders)

# 2. Test line detection  
cat("\n=== TESTING LINE DETECTION ===\n")
line_points <- matrix(0, ncol=3, nrow=0)
for (i in 1:120) {
  t <- i / 120
  x <- t * 20 + rnorm(1, sd=0.015)
  y <- 0 + rnorm(1, sd=0.015)
  z <- 5.5 + rnorm(1, sd=0.015)
  line_points <- rbind(line_points, c(x, y, z))
}

cat(sprintf("Generated %d line points\n", nrow(line_points)))
result <- detect_lines(line_points, distance_threshold=0.05, min_votes=30, min_length=4.0, max_iterations=500)
cat(sprintf("Detected %d lines\n", result$n_lines))
if (result$n_lines > 0) print(result$lines)

# 3. Test sphere detection
cat("\n=== TESTING SPHERE DETECTION ===\n")
sphere_points <- matrix(0, ncol=3, nrow=0)
for (phi in seq(0, pi, length.out=12)) {
  for (theta in seq(0, 2*pi, length.out=20)) {
    r <- 1.0
    x <- 5 + r * sin(phi) * cos(theta) + rnorm(1, sd=0.02)
    y <- 5 + r * sin(phi) * sin(theta) + rnorm(1, sd=0.02)
    z <- 2 + r * cos(phi) + rnorm(1, sd=0.02)
    sphere_points <- rbind(sphere_points, c(x, y, z))
  }
}

cat(sprintf("Generated %d sphere points\n", nrow(sphere_points)))
result <- detect_spheres(sphere_points, min_radius=0.8, max_radius=1.2, min_votes=80)
cat(sprintf("Detected %d spheres\n", result$n_spheres))
if (result$n_spheres > 0) print(result$spheres)
