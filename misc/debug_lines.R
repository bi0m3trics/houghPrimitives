library(houghPrimitives)

# Generate lines exactly like in example
generate_line <- function(x1, y1, z1, x2, y2, z2, n_points, thickness = 0.01) {
  t <- seq(0, 1, length.out = n_points)
  
  x <- x1 + t * (x2 - x1) + rnorm(n_points, sd = thickness)
  y <- y1 + t * (y2 - y1) + rnorm(n_points, sd = thickness)
  z <- z1 + t * (z2 - z1) + rnorm(n_points, sd = thickness)
  
  cbind(x, y, z)
}

lines <- rbind(
  generate_line(0, 0, 5.5, 20, 0, 5.5, 120, 0.02),   # Horizontal line
  generate_line(0, 20, 5, 20, 20, 5, 120, 0.02),     # Horizontal line  
  generate_line(1, 1, 0, 1, 1, 6, 100, 0.015)        # Vertical line
)

cat(sprintf("Generated %d line points (3 lines)\n", nrow(lines)))

# Test detection
result <- detect_lines(lines, distance_threshold=0.04, min_votes=50, min_length=4.5, max_iterations=600)
cat(sprintf("Detected %d lines\n", result$n_lines))
if (result$n_lines > 0) print(result$lines)

# Try relaxed
result2 <- detect_lines(lines, distance_threshold=0.05, min_votes=30, min_length=4.0, max_iterations=800)
cat(sprintf("\nRelaxed: Detected %d lines\n", result2$n_lines))
if (result2$n_lines > 0) print(result2$lines)
