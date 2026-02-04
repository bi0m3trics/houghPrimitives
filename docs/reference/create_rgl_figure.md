# Complete Workflow: Create rgl Figure with Static and Interactive Output

High-level function that creates an rgl scene, saves a static PNG, and
optionally returns an interactive widget. Designed for use in
vignette/article chunks.

## Usage

``` r
create_rgl_figure(
  scene_function,
  filename,
  width = 800,
  height = 600,
  interactive = FALSE,
  ...
)
```

## Arguments

  - scene\_function:
    
    Function. A function that creates the rgl scene. Should call rgl
    functions (spheres3d, plot3d, etc.) but NOT open3d().

  - filename:
    
    Character. Base filename for PNG snapshot (e.g., "my-figure.png")

  - width:
    
    Integer. Image/widget width (default: 800)

  - height:
    
    Integer. Image/widget height (default: 600)

  - interactive:
    
    Logical. If TRUE, return rglwidget for HTML output (default: FALSE)

  - ...:
    
    Additional arguments passed to scene\_function

## Value

If interactive=TRUE, returns rglwidget. Otherwise, returns path to PNG
invisibly.

## Details

This function automates the complete workflow:

1.  Opens new rgl device

2.  Executes scene\_function to create visualization

3.  Saves static PNG snapshot

4.  Optionally creates interactive widget

5.  Closes rgl device

## Examples

``` r
if (FALSE) { # \dontrun{
# Define scene
my_scene <- function(n_points = 100) {
  points3d(rnorm(n_points), rnorm(n_points), rnorm(n_points), col = "blue")
  axes3d()
  title3d("Random Points", "x", "y", "z")
}

# Static PNG only
create_rgl_figure(my_scene, "random-points.png", n_points = 50)

# Interactive widget (HTML output)
create_rgl_figure(my_scene, "random-points.png", interactive = TRUE)
} # }
```
