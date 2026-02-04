# Detect 3D lines in point cloud data

Detect 3D lines in point cloud data

## Usage

``` r
detect_lines(
  xyz,
  distance_threshold = 0.05,
  min_votes = 20L,
  min_length = 0.5,
  max_iterations = 500L,
  in_scene = TRUE,
  label_points = FALSE
)
```

## Arguments

  - xyz:
    
    A matrix with 3 columns (X, Y, Z coordinates)

  - distance\_threshold:
    
    Maximum distance from line for inliers

  - min\_votes:
    
    Minimum number of points required to detect a line

  - min\_length:
    
    Minimum line length

  - max\_iterations:
    
    Maximum RANSAC iterations

  - in\_scene:
    
    If TRUE, assumes lines exist in complex scene (stricter). If FALSE,
    optimized for line-only detection (more aggressive)

  - label\_points:
    
    If TRUE, label all points with line ID

## Value

A list with detected lines and optionally labeled points
