# rgl Figure Utilities for pkgdown Articles and Vignettes
# 
# This file provides helper functions for generating rgl 3D visualizations
# that work correctly in both pkgdown articles and package vignettes.
# It handles headless rendering, static PNG snapshots, and optional interactive widgets.

#' Save rgl Scene as Static PNG
#'
#' Captures the current rgl scene and saves it as a PNG file in a pkgdown-safe location.
#' This function is designed for use in vignettes and articles.
#'
#' @param filename Character. Base filename without path (e.g., "sphere-detection.png")
#' @param width Integer. Image width in pixels (default: 800)
#' @param height Integer. Image height in pixels (default: 600)
#' @param dpi Integer. Resolution in dots per inch (default: 96)
#' @param output_dir Character. Directory to save figure. If NULL (default),
#'   automatically detects context: "." for vignettes, "man/figures/" for pkgdown articles.
#'   Can be overridden for specific use cases.
#'
#' @return Character. Full path to the saved PNG file (invisibly)
#'
#' @details
#' This function:
#' \itemize{
#'   \item Uses rgl::snapshot3d() for high-quality PNG output
#'   \item Auto-detects vignette context and saves to appropriate location
#'   \item In vignettes: saves to current directory (vignette build directory)
#'   \item In pkgdown/manual use: saves to man/figures/ (pkgdown standard)
#'   \item Creates the output directory if it doesn't exist
#'   \item Returns the path for use with knitr::include_graphics()
#' }
#'
#' @examples
#' \dontrun{
#' library(rgl)
#' 
#' # Create rgl scene
#' open3d()
#' spheres3d(0, 0, 0, radius = 1, color = "blue")
#' 
#' # Save as PNG
#' fig_path <- save_rgl_snapshot("my-sphere.png")
#' 
#' # Use in knitr chunk
#' knitr::include_graphics(fig_path)
#' }
#'
#' @export
save_rgl_snapshot <- function(filename, 
                               width = 800, 
                               height = 600, 
                               dpi = 96,
                               output_dir = NULL) {
  
  # Ensure rgl is available
  if (!requireNamespace("rgl", quietly = TRUE)) {
    stop("Package 'rgl' is required but not installed.")
  }
  
  # Auto-detect output directory if not specified
  if (is.null(output_dir)) {
    # Check if we're in a knitr/vignette context
    in_knitr <- isTRUE(getOption("knitr.in.progress"))
    
    if (in_knitr) {
      # Try to get the base directory from knitr options
      base_dir <- try(knitr::opts_knit$get("base.dir"), silent = TRUE)
      
      # For vignettes: save relative to current directory
      # Images will be embedded in the HTML via pandoc's --self-contained
      output_dir <- "."
    } else {
      # For pkgdown articles and manual use: save to man/figures/
      output_dir <- "man/figures/"
    }
  }
  
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Construct full path
  filepath <- file.path(output_dir, filename)
  
  # Capture current rgl scene as PNG
  # snapshot3d() is preferred over rgl.snapshot() for quality
  rgl::snapshot3d(filepath, width = width, height = height)
  
  # Return path invisibly for use with knitr::include_graphics()
  invisible(filepath)
}


#' Create rgl Widget for Interactive 3D Display
#'
#' Generates an interactive rglwidget for HTML output (vignettes, pkgdown articles).
#' This is a wrapper around rgl::rglwidget() with sensible defaults.
#'
#' @param width Integer. Widget width in pixels (default: 800)
#' @param height Integer. Widget height in pixels (default: 600)
#' @param elementId Character. Optional DOM element ID for the widget
#'
#' @return An htmlwidget object (rglwidget)
#'
#' @details
#' This function creates an interactive 3D widget that:
#' \itemize{
#'   \item Works in HTML vignettes and pkgdown articles
#'   \item Allows rotation, zoom, and pan with mouse
#'   \item Only renders in HTML output (not PDF/Word)
#' }
#'
#' @examples
#' \dontrun{
#' library(rgl)
#' 
#' # Create scene
#' open3d()
#' spheres3d(rnorm(100), rnorm(100), rnorm(100), radius = 0.1)
#' 
#' # Generate interactive widget (HTML only)
#' create_rgl_widget()
#' }
#'
#' @export
create_rgl_widget <- function(width = 800, height = 600, elementId = NULL) {
  
  # Ensure rgl is available
  if (!requireNamespace("rgl", quietly = TRUE)) {
    stop("Package 'rgl' is required but not installed.")
  }
  
  # Generate widget from current scene
  rgl::rglwidget(width = width, height = height, elementId = elementId)
}


#' Setup rgl for Vignette/Article Use
#'
#' Configures rgl for headless rendering suitable for vignettes and pkgdown articles.
#' Call this in your setup chunk.
#'
#' @param use_null Logical. If TRUE (default), use headless NULL device for rendering.
#'   This is required for CRAN checks and CI environments without X11/display.
#'
#' @return NULL (called for side effects)
#'
#' @details
#' This function:
#' \itemize{
#'   \item Sets options(rgl.useNULL = TRUE) for headless rendering
#'   \item Calls rgl::setupKnitr() to configure knitr hooks
#'   \item Should be called once in the vignette setup chunk
#'   \item Ensures rgl works without a display device
#' }
#'
#' @examples
#' \dontrun{
#' # In vignette setup chunk:
#' setup_rgl_knitr()
#' }
#'
#' @export
setup_rgl_knitr <- function(use_null = TRUE) {
  
  # Ensure rgl is available
  if (!requireNamespace("rgl", quietly = TRUE)) {
    warning("Package 'rgl' is not installed. rgl features will not be available.")
    return(invisible(NULL))
  }
  
  # Configure rgl for headless rendering
  # This is CRITICAL for:
  # - CRAN checks (no X11 server)
  # - GitHub Actions / CI (headless environments)
  # - Reproducible builds without display
  if (use_null) {
    options(rgl.useNULL = TRUE)
  }
  
  # Setup knitr hooks for rgl
  # This enables automatic handling of rgl scenes in knitr chunks
  rgl::setupKnitr(autoprint = TRUE)
  
  invisible(NULL)
}


#' Complete Workflow: Create rgl Figure with Static and Interactive Output
#'
#' High-level function that creates an rgl scene, saves a static PNG, and optionally
#' returns an interactive widget. Designed for use in vignette/article chunks.
#'
#' @param scene_function Function. A function that creates the rgl scene.
#'   Should call rgl functions (spheres3d, plot3d, etc.) but NOT open3d().
#' @param filename Character. Base filename for PNG snapshot (e.g., "my-figure.png")
#' @param width Integer. Image/widget width (default: 800)
#' @param height Integer. Image/widget height (default: 600)
#' @param interactive Logical. If TRUE, return rglwidget for HTML output (default: FALSE)
#' @param ... Additional arguments passed to scene_function
#'
#' @return If interactive=TRUE, returns rglwidget. Otherwise, returns path to PNG invisibly.
#'
#' @details
#' This function automates the complete workflow:
#' \enumerate{
#'   \item Opens new rgl device
#'   \item Executes scene_function to create visualization
#'   \item Saves static PNG snapshot
#'   \item Optionally creates interactive widget
#'   \item Closes rgl device
#' }
#'
#' @examples
#' \dontrun{
#' # Define scene
#' my_scene <- function(n_points = 100) {
#'   points3d(rnorm(n_points), rnorm(n_points), rnorm(n_points), col = "blue")
#'   axes3d()
#'   title3d("Random Points", "x", "y", "z")
#' }
#' 
#' # Static PNG only
#' create_rgl_figure(my_scene, "random-points.png", n_points = 50)
#' 
#' # Interactive widget (HTML output)
#' create_rgl_figure(my_scene, "random-points.png", interactive = TRUE)
#' }
#'
#' @export
create_rgl_figure <- function(scene_function, 
                               filename, 
                               width = 800, 
                               height = 600,
                               interactive = FALSE,
                               ...) {
  
  # Ensure rgl is available
  if (!requireNamespace("rgl", quietly = TRUE)) {
    stop("Package 'rgl' is required but not installed.")
  }
  
  # Open new rgl device (headless if rgl.useNULL is set)
  rgl::open3d()
  
  # Execute scene creation function
  # Wrap in tryCatch to ensure cleanup
  tryCatch({
    scene_function(...)
    
    # Save static PNG snapshot
    png_path <- save_rgl_snapshot(filename, width = width, height = height)
    
    # Create interactive widget if requested
    if (interactive) {
      widget <- create_rgl_widget(width = width, height = height)
      rgl::close3d()
      return(widget)
    } else {
      rgl::close3d()
      return(invisible(png_path))
    }
    
  }, error = function(e) {
    # Ensure rgl device is closed even on error
    try(rgl::close3d(), silent = TRUE)
    stop("Error creating rgl figure: ", e$message)
  })
}
