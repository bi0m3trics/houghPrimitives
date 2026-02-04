#!/usr/bin/env Rscript
# Generate example images for README.md

library(rgl)

# Create output directory if it doesn't exist
dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)

# Helper function to save rgl snapshot
save_snapshot <- function(filename, width = 800, height = 600) {
  rgl::snapshot3d(filename = filename, fmt = "png", width = width, height = height)
}

# 1. Sphere Detection Example
cat("Generating sphere detection example...\n")
rgl::open3d()
rgl::par3d(windowRect = c(0, 0, 800, 600))
rgl::bg3d("#1a1a1a")

# Generate a sphere with some noise
set.seed(123)
n_sphere <- 500
theta <- runif(n_sphere, 0, 2*pi)
phi <- runif(n_sphere, 0, pi)
r <- 1.0 + rnorm(n_sphere, 0, 0.02)
x <- r * sin(phi) * cos(theta)
y <- r * sin(phi) * sin(theta)
z <- r * cos(phi)

# Add some noise points
n_noise <- 100
x_noise <- runif(n_noise, -1.5, 1.5)
y_noise <- runif(n_noise, -1.5, 1.5)
z_noise <- runif(n_noise, -1.5, 1.5)

# Plot sphere points in cyan and noise in dim gray
rgl::points3d(x, y, z, col = "#06FFA5", size = 5)
rgl::points3d(x_noise, y_noise, z_noise, col = "#666666", size = 3)

# Add axes with light colors
rgl::axes3d(col = "#e0e0e0")
rgl::title3d("Sphere Detection Example", line = 3, color = "#e0e0e0")

save_snapshot("man/figures/sphere-detection-3d.png")
rgl::close3d()

# 2. Line Detection Example
cat("Generating line detection example...\n")
rgl::open3d()
rgl::par3d(windowRect = c(0, 0, 800, 600))
rgl::bg3d("#1a1a1a")

# Generate 3 lines with noise
set.seed(456)

# Line 1: Diagonal
n1 <- 100
t1 <- seq(0, 2, length.out = n1)
x1 <- t1 + rnorm(n1, 0, 0.02)
y1 <- t1 + rnorm(n1, 0, 0.02)
z1 <- t1 + rnorm(n1, 0, 0.02)

# Line 2: Vertical
n2 <- 80
t2 <- seq(0, 2, length.out = n2)
x2 <- 1.5 + rnorm(n2, 0, 0.02)
y2 <- -0.5 + rnorm(n2, 0, 0.02)
z2 <- t2 + rnorm(n2, 0, 0.02)

# Line 3: Horizontal
n3 <- 90
t3 <- seq(0, 2, length.out = n3)
x3 <- t3 + rnorm(n3, 0, 0.02)
y3 <- -1.0 + rnorm(n3, 0, 0.02)
z3 <- 0.5 + rnorm(n3, 0, 0.02)

# Add noise points
n_noise <- 50
x_noise <- runif(n_noise, -0.5, 2.5)
y_noise <- runif(n_noise, -1.5, 2.5)
z_noise <- runif(n_noise, -0.5, 2.5)

# Plot with different colors
rgl::points3d(x1, y1, z1, col = "#E63946", size = 5)
rgl::points3d(x2, y2, z2, col = "#06FFA5", size = 5)
rgl::points3d(x3, y3, z3, col = "#00B4D8", size = 5)
rgl::points3d(x_noise, y_noise, z_noise, col = "#666666", size = 3)

rgl::axes3d(col = "#e0e0e0")
rgl::title3d("Line Detection Example", line = 3, color = "#e0e0e0")

save_snapshot("man/figures/line-detection-3d.png")
rgl::close3d()

# 3. Multi-Shape Classification Example
cat("Generating multi-shape classification example...\n")
rgl::open3d()
rgl::par3d(windowRect = c(0, 0, 800, 600))
rgl::bg3d("#1a1a1a")

set.seed(789)

# Generate sphere
n_sphere <- 300
theta <- runif(n_sphere, 0, 2*pi)
phi <- runif(n_sphere, 0, pi)
r <- 0.5 + rnorm(n_sphere, 0, 0.01)
x_sp <- r * sin(phi) * cos(theta) + 1.0
y_sp <- r * sin(phi) * sin(theta)
z_sp <- r * cos(phi) + 1.0

# Generate cylinder
n_cyl <- 400
theta_c <- runif(n_cyl, 0, 2*pi)
z_c <- runif(n_cyl, 0, 2)
r_c <- 0.3 + rnorm(n_cyl, 0, 0.01)
x_cy <- r_c * cos(theta_c) - 1.0
y_cy <- r_c * sin(theta_c)
z_cy <- z_c

# Generate plane
n_plane <- 500
x_pl <- runif(n_plane, -2, 2)
y_pl <- runif(n_plane, -2, 2)
z_pl <- rnorm(n_plane, 0, 0.02)

# Plot shapes
rgl::points3d(x_sp, y_sp, z_sp, col = "#E63946", size = 5)  # Red sphere
rgl::points3d(x_cy, y_cy, z_cy, col = "#06FFA5", size = 5)  # Green cylinder
rgl::points3d(x_pl, y_pl, z_pl, col = "#00B4D8", size = 5)  # Cyan plane

rgl::axes3d(col = "#e0e0e0")
rgl::title3d("Multi-Shape Classification", line = 3, color = "#e0e0e0")

save_snapshot("man/figures/multi-shape-3d.png")
rgl::close3d()

# 4. Complex scene with shapes (intro example)
cat("Generating complex scene example...\n")
rgl::open3d()
rgl::par3d(windowRect = c(0, 0, 800, 600))
rgl::bg3d("#1a1a1a")

set.seed(321)

# Combine all shapes from above
rgl::points3d(x_sp, y_sp, z_sp, col = "#E63946", size = 5)
rgl::points3d(x_cy, y_cy, z_cy, col = "#06FFA5", size = 5)
rgl::points3d(x_pl, y_pl, z_pl, col = "#00B4D8", size = 4)

# Add some lines
n_line <- 80
t_l <- seq(-1.5, 1.5, length.out = n_line)
x_li <- t_l + rnorm(n_line, 0, 0.02)
y_li <- -1.5 + rnorm(n_line, 0, 0.02)
z_li <- t_l + 0.5 + rnorm(n_line, 0, 0.02)
rgl::points3d(x_li, y_li, z_li, col = "#F77F00", size = 5)

rgl::axes3d(col = "#e0e0e0")
rgl::title3d("Complex Scene: Multiple Primitive Types", line = 3, color = "#e0e0e0")

save_snapshot("man/figures/intro-shapes-3d.png")
rgl::close3d()

cat("\nAll images generated successfully!\n")
cat("Images saved to man/figures/\n")
