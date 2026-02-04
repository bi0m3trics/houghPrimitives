# Package index

## Package Documentation

Package overview and information

<!-- end list -->

  - `houghPrimitives-package` `houghPrimitives` : houghPrimitives: 3D
    Shape Detection in Point Clouds Using Hough Transforms

## Shape Detection Functions

Core functions for detecting primitive shapes in point clouds

<!-- end list -->

  - `detect_spheres()` : Detect spheres in point cloud data using 3D
    Hough transform
  - `detect_cylinders()` : Detect general cylinders (not just vertical)
    in point cloud data
  - `detect_planes()` : Detect planes in point cloud data using RANSAC
  - `detect_lines()` : Detect 3D lines in point cloud data
  - `detect_cubes()` : Detect cubes in point cloud data
  - `detect_cuboids()` : Detect cuboids (rectangular boxes) in point
    cloud data
  - `detect_cones()` : Detect cones in 3D point cloud
  - `detect_tree_boles()` : Detect tree boles (cylindrical trunks) in
    point cloud data

## Utility Functions

Helper functions for point cloud analysis

<!-- end list -->

  - `summarize_points()` : Simple point cloud summary

## Visualization

Color palette functions for visualization

<!-- end list -->

  - `hough_palette()` : Get Hough Color Palette
  - `hough_palette_gradient()` : Generate Interpolated Colors from Hough
    Palette
  - `hough_palette_pairs()` : Get Contrasting Color Pairs
  - `hough_palette_preview()` : Preview Hough Color Palettes

## 3D Visualization Utilities

Functions for creating rgl figures in vignettes

<!-- end list -->

  - `setup_rgl_knitr()` : Setup rgl for Vignette/Article Use
  - `save_rgl_snapshot()` : Save rgl Scene as Static PNG
  - `create_rgl_widget()` : Create rgl Widget for Interactive 3D Display
  - `create_rgl_figure()` : Complete Workflow: Create rgl Figure with
    Static and Interactive Output
