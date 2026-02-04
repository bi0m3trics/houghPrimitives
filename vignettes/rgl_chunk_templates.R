# rgl Chunk Templates for Copy-Paste
# =====================================
# 
# These templates provide ready-to-use R Markdown chunks for creating
# reproducible rgl 3D visualizations in pkgdown articles and vignettes.
#
# See RGL_FIGURES_GUIDE.md for complete documentation.

# ==============================================================================
# TEMPLATE 1: Setup Chunk (Required - Add to Every Vignette/Article)
# ==============================================================================

```{r setup, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5,
  out.width = "80%",
  fig.align = "center"
)

# Setup rgl for headless rendering
# CRITICAL: Must be called before any rgl usage
# Enables rendering without X11/display (required for CRAN checks and CI)
if (requireNamespace("rgl", quietly = TRUE)) {
  library(houghPrimitives)
  setup_rgl_knitr()  # Sets rgl.useNULL = TRUE + configures knitr hooks
}
```

# ==============================================================================
# TEMPLATE 2: Simple Static Figure
# ==============================================================================

```{r figure-name, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)
library(houghPrimitives)

# Open rgl device (headless if setup_rgl_knitr() was called)
open3d()

# Create your 3D scene
# Example: Plot some points
points3d(rnorm(100), rnorm(100), rnorm(100), col = "steelblue", size = 5)
axes3d()
title3d("My 3D Plot", "X", "Y", "Z")

# Save as static PNG (automatically saved to man/figures/)
fig_path <- save_rgl_snapshot("figure-name.png")

# Close device (important to prevent accumulation)
close3d()
```

# Display the saved figure
```{r show-figure, echo = FALSE, out.width = "80%", fig.cap = "Description of your figure"}
knitr::include_graphics(fig_path)
```

# ==============================================================================
# TEMPLATE 3: Static Figure with Custom Dimensions
# ==============================================================================

```{r large-figure, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)
library(houghPrimitives)

open3d()

# Create scene
plot3d(iris[, 1:3], col = iris$Species, size = 5)
axes3d()

# Save with custom size and resolution
fig_path <- save_rgl_snapshot(
  "iris-3d-large.png",
  width = 1200,   # Larger width
  height = 900,   # Larger height
  dpi = 150       # Higher DPI for print quality
)

close3d()
```

```{r show-large, echo = FALSE, out.width = "100%"}
knitr::include_graphics(fig_path)
```

# ==============================================================================
# TEMPLATE 4: Interactive Widget (HTML only) with Static Fallback
# ==============================================================================

```{r create-interactive-scene, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)
library(houghPrimitives)

open3d()

# Create your scene
spheres3d(rnorm(50), rnorm(50), rnorm(50), 
          radius = 0.1, col = rainbow(50))
axes3d()
title3d("Interactive Sphere Cloud", "X", "Y", "Z")

# ALWAYS save static version first (fallback for PDF output)
fig_path <- save_rgl_snapshot("interactive-spheres.png")

# Create interactive widget for HTML, static image for PDF
if (knitr::is_html_output()) {
  # HTML output: show interactive widget
  widget <- create_rgl_widget(width = "100%", height = 600)
  close3d()
  widget
} else {
  # PDF/Word output: show static image
  close3d()
  knitr::include_graphics(fig_path)
}
```

# ==============================================================================
# TEMPLATE 5: Reusable Scene Function (Recommended for Complex Scenes)
# ==============================================================================

```{r define-scene-function}
# Define a reusable function that creates your 3D scene
# This can be called multiple times with different parameters

plot_detection_results <- function(xyz, labels, title = "Detection Results") {
  # Separate detected vs undetected points
  detected_mask <- labels > 0
  
  # Plot undetected points in gray
  if (any(!detected_mask)) {
    points3d(xyz[!detected_mask, 1], 
             xyz[!detected_mask, 2], 
             xyz[!detected_mask, 3],
             color = "gray", size = 3)
  }
  
  # Plot detected points colored by label
  if (any(detected_mask)) {
    n_shapes <- max(labels)
    colors <- rainbow(n_shapes)
    
    for (i in 1:n_shapes) {
      shape_mask <- labels == i
      if (any(shape_mask)) {
        points3d(xyz[shape_mask, 1], 
                 xyz[shape_mask, 2], 
                 xyz[shape_mask, 3],
                 color = colors[i], size = 5)
      }
    }
  }
  
  axes3d()
  title3d(title, "X (m)", "Y (m)", "Z (m)")
}
```

# Use the scene function
```{r use-scene-function, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)
library(houghPrimitives)

# Example data (replace with your actual data)
set.seed(42)
my_xyz <- matrix(rnorm(300), ncol = 3)
my_labels <- sample(0:3, 100, replace = TRUE)

# Create figure using the scene function
open3d()
plot_detection_results(my_xyz, my_labels, "My Detection Results")
fig_path <- save_rgl_snapshot("detection-results.png")
close3d()
```

```{r show-detection, echo = FALSE, out.width = "100%"}
knitr::include_graphics(fig_path)
```

# ==============================================================================
# TEMPLATE 6: Automated Workflow (Simplest Approach)
# ==============================================================================

```{r automated-workflow, eval = requireNamespace("rgl", quietly = TRUE)}
library(houghPrimitives)

# Define scene creation function
my_scene <- function(n_points = 100, point_color = "blue") {
  # Note: Do NOT call open3d() here - handled by create_rgl_figure()
  points3d(rnorm(n_points), rnorm(n_points), rnorm(n_points), 
           col = point_color, size = 5)
  axes3d()
  title3d("Automated Scene", "X", "Y", "Z")
}

# Create figure with automatic open/save/close
# This function handles all the rgl device management
fig_path <- create_rgl_figure(
  scene_function = my_scene,
  filename = "automated-scene.png",
  width = 800,
  height = 600,
  n_points = 150,        # Passed to my_scene()
  point_color = "coral"  # Passed to my_scene()
)
```

```{r show-automated, echo = FALSE, out.width = "80%"}
knitr::include_graphics(fig_path)
```

# ==============================================================================
# TEMPLATE 7: Shape Detection Visualization (Spheres Example)
# ==============================================================================

```{r sphere-detection-viz, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)
library(houghPrimitives)

# Generate synthetic data
set.seed(123)
sphere1 <- matrix(rnorm(300), ncol = 3) * 0.2 + c(5, 5, 3)
sphere2 <- matrix(rnorm(250), ncol = 3) * 0.15 + c(8, 7, 2)
noise <- matrix(runif(150, 0, 10), ncol = 3)
xyz <- rbind(sphere1, sphere2, noise)

# Detect spheres
result <- detect_spheres(xyz, min_radius = 0.1, max_radius = 0.3,
                        min_votes = 50, label_points = TRUE)

# Visualize
open3d()

# Undetected points (noise)
noise_mask <- result$point_labels == 0
if (any(noise_mask)) {
  points3d(xyz[noise_mask, 1], xyz[noise_mask, 2], xyz[noise_mask, 3],
           color = "gray", size = 3)
}

# Detected spheres
if (result$n_spheres > 0) {
  colors <- c("steelblue", "coral", "forestgreen", "gold")
  
  for (i in 1:result$n_spheres) {
    sphere_mask <- result$point_labels == i
    
    # Points
    points3d(xyz[sphere_mask, 1], xyz[sphere_mask, 2], xyz[sphere_mask, 3],
             color = colors[i], size = 5)
    
    # Detected sphere overlay (semi-transparent)
    s <- result$spheres[i, ]
    spheres3d(s$x, s$y, s$z, radius = s$radius, 
              color = colors[i], alpha = 0.3)
  }
}

axes3d()
title3d(sprintf("Detected %d Spheres", result$n_spheres), "X", "Y", "Z")

# Save figure
fig_path <- save_rgl_snapshot("sphere-detection-example.png", 
                              width = 900, height = 700)
close3d()
```

```{r show-sphere-detection, echo = FALSE, out.width = "100%", fig.cap = "Sphere detection results with semi-transparent overlays"}
knitr::include_graphics(fig_path)
```

# ==============================================================================
# TEMPLATE 8: Conditional Widget (Auto-detects HTML vs PDF output)
# ==============================================================================

```{r conditional-scene, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)
library(houghPrimitives)

# Create scene
open3d()
plot3d(mtcars$wt, mtcars$mpg, mtcars$qsec, 
       col = mtcars$cyl, size = 5,
       xlab = "Weight", ylab = "MPG", zlab = "Quarter Mile Time")

# Save static version (always needed)
fig_path <- save_rgl_snapshot("mtcars-3d.png")

# Output appropriate format based on output type
if (knitr::is_html_output()) {
  # HTML: interactive widget
  widget <- create_rgl_widget(width = "100%", height = 500)
  close3d()
  widget
} else {
  # PDF/Word: static image
  close3d()
  knitr::include_graphics(fig_path)
}
```

# ==============================================================================
# TEMPLATE 9: Multiple Scenes in Sequence
# ==============================================================================

```{r multiple-scenes, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)
library(houghPrimitives)

# Scene 1: Before detection
open3d()
set.seed(42)
all_data <- matrix(rnorm(300), ncol = 3)
points3d(all_data, col = "gray", size = 4)
axes3d()
title3d("Before Detection", "X", "Y", "Z")
fig_path_before <- save_rgl_snapshot("before-detection.png")
close3d()

# Scene 2: After detection (simulated)
open3d()
detected <- all_data[1:70, ]  # Simulate detection
undetected <- all_data[71:100, ]
points3d(detected, col = "steelblue", size = 6)
points3d(undetected, col = "lightgray", size = 3)
axes3d()
title3d("After Detection", "X", "Y", "Z")
fig_path_after <- save_rgl_snapshot("after-detection.png")
close3d()
```

Before detection:

```{r show-before, echo = FALSE, out.width = "48%"}
knitr::include_graphics(fig_path_before)
```

After detection:

```{r show-after, echo = FALSE, out.width = "48%"}
knitr::include_graphics(fig_path_after)
```

# ==============================================================================
# TEMPLATE 10: Error Handling
# ==============================================================================

```{r safe-rgl-usage, eval = requireNamespace("rgl", quietly = TRUE)}
library(rgl)
library(houghPrimitives)

# Wrap in tryCatch for robustness
fig_path <- tryCatch({
  open3d()
  
  # Your scene code
  spheres3d(0, 0, 0, radius = 1, col = "blue")
  axes3d()
  
  # Save and close
  path <- save_rgl_snapshot("safe-figure.png")
  close3d()
  path
  
}, error = function(e) {
  # Ensure device is closed even on error
  try(close3d(), silent = TRUE)
  warning("Failed to create rgl figure: ", e$message)
  NULL
})

# Only display if figure was created successfully
if (!is.null(fig_path)) {
  knitr::include_graphics(fig_path)
} else {
  cat("Figure could not be generated\n")
}
```

# ==============================================================================
# NOTES
# ==============================================================================
#
# 1. ALWAYS call setup_rgl_knitr() in setup chunk before using rgl
#
# 2. ALWAYS close rgl devices with close3d() to prevent accumulation
#
# 3. ALWAYS save static PNG before creating interactive widgets
#
# 4. Figures are saved to man/figures/ by default (pkgdown-compatible)
#
# 5. Use eval = requireNamespace("rgl", quietly = TRUE) in chunks
#    to gracefully handle missing rgl package
#
# 6. For HTML output: knitr::is_html_output() returns TRUE
#    Use this to conditionally create interactive widgets
#
# 7. File locations:
#    - Figures: man/figures/ (picked up by pkgdown)
#    - Vignettes: vignettes/*.Rmd
#    - Utility functions: R/rgl_utils.R
#
# 8. See RGL_FIGURES_GUIDE.md for complete documentation
#
# ==============================================================================
