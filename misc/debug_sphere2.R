library(houghPrimitives)

# Reproduce the exact spheres from the example
generate_sphere <- function(cx, cy, cz, radius, n_points) {
  phi <- runif(n_points, 0, pi)
  theta <- runif(n_points, 0, 2*pi)
  
  x <- cx + radius * sin(phi) * cos(theta)
  y <- cy + radius * sin(phi) * sin(theta)
  z <- cz + radius * cos(phi)
  
  # Add slight noise
  noise <- rnorm(n_points * 3, sd = radius * 0.015)
  
  cbind(x + noise[1:n_points],
        y + noise[(n_points+1):(2*n_points)],
        z + noise[(2*n_points+1):(3*n_points)])
}

spheres <- rbind(
  generate_sphere(5, 5, 2.0, 0.9, 180),
  generate_sphere(15, 15, 2.5, 1.0, 200)
)

cat(sprintf("Generated %d sphere points\n", nrow(spheres)))

# Test detection
result <- detect_spheres(spheres, min_radius = 0.7, max_radius = 1.3, min_votes = 100, label_points = FALSE)
cat(sprintf("Detected %d spheres\n", result$n_spheres))
if (result$n_spheres > 0) print(result$spheres)

# Try with more relaxed min_votes
result2 <- detect_spheres(spheres, min_radius = 0.7, max_radius = 1.3, min_votes = 80, label_points = FALSE)
cat(sprintf("\nWith min_votes=80: Detected %d spheres\n", result2$n_spheres))
if (result2$n_spheres > 0) print(result2$spheres)
