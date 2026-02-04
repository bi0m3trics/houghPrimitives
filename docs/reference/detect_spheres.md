# Detect spheres in point cloud data using 3D Hough transform

Detect spheres in point cloud data using 3D Hough transform

## Usage

``` r
detect_spheres(
  xyz,
  min_radius = 0.1,
  max_radius = 2,
  min_votes = 30L,
  label_points = FALSE
)
```

## Arguments

  - xyz:
    
    A matrix with 3 columns (X, Y, Z coordinates)

  - min\_radius:
    
    Minimum sphere radius

  - max\_radius:
    
    Maximum sphere radius

  - min\_votes:
    
    Minimum number of points required to detect a sphere

  - label\_points:
    
    If TRUE, label all points with sphere ID

## Value

A list with detected spheres and optionally labeled points
