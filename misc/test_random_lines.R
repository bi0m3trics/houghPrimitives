library(houghPrimitives)

# Test line detection with random angles
set.seed(123)

# Generate lines at various angles
generate_random_line <- function(bounds_x = c(0, 20), bounds_y = c(0, 20), 
                                  bounds_z = c(0, 6), min_length = 3, 
                                  max_length = 8, n_points = 100, noise = 0.015) {
  x1 <- runif(1, bounds_x[1] + 1, bounds_x[2] - 1)
  y1 <- runif(1, bounds_y[1] + 1, bounds_y[2] - 1)
  z1 <- runif(1, bounds_z[1] + 0.5, bounds_z[2] - 0.5)
  
  length <- runif(1, min_length, max_length)
  theta <- runif(1, 0, 2*pi)
  phi <- runif(1, 0, pi)
  
  dx <- sin(phi) * cos(theta)
  dy <- sin(phi) * sin(theta)
  dz <- cos(phi)
  
  x2 <- x1 + length * dx
  y2 <- y1 + length * dy
  z2 <- z1 + length * dz
  
  x2 <- max(bounds_x[1], min(bounds_x[2], x2))
  y2 <- max(bounds_y[1], min(bounds_y[2], y2))
  z2 <- max(bounds_z[1], min(bounds_z[2], z2))
  
  # Generate points along line
  t <- runif(n_points, 0, 1)
  x <- x1 + t * (x2 - x1) + rnorm(n_points, sd = noise)
  y <- y1 + t * (y2 - y1) + rnorm(n_points, sd = noise)
  z <- z1 + t * (z2 - z1) + rnorm(n_points, sd = noise)
  
  list(points = cbind(x, y, z),
       start = c(x1, y1, z1),
       end = c(x2, y2, z2))
}

# Generate 5 lines at random angles
n_lines <- 5
all_lines <- NULL
line_info <- list()

for (i in 1:n_lines) {
  line <- generate_random_line(n_points = sample(80:120, 1))
  all_lines <- rbind(all_lines, line$points)
  line_info[[i]] <- list(start = line$start, end = line$end)
  
  len <- sqrt(sum((line$end - line$start)^2))
  cat(sprintf("Line %d: (%.1f,%.1f,%.1f) to (%.1f,%.1f,%.1f), length=%.2f\n",
              i, line$start[1], line$start[2], line$start[3],
              line$end[1], line$end[2], line$end[3], len))
}

cat(sprintf("\nTotal: %d points from %d lines\n", nrow(all_lines), n_lines))

# Test detection
result <- detect_lines(all_lines, distance_threshold=0.05, min_votes=35, 
                       min_length=2.0, max_iterations=800)
cat(sprintf("\nDetected %d lines\n", result$n_lines))
if (result$n_lines > 0) {
  print(result$lines)
}

# Try more relaxed
result2 <- detect_lines(all_lines, distance_threshold=0.06, min_votes=30, 
                        min_length=1.5, max_iterations=1000)
cat(sprintf("\nRelaxed: Detected %d lines\n", result2$n_lines))
if (result2$n_lines > 0) {
  print(result2$lines)
}
