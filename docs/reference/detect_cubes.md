# Detect cubes in point cloud data

Detect cubes in point cloud data

## Usage

``` r
detect_cubes(
  xyz,
  min_size = 0.3,
  max_size = 3,
  min_votes = 100L,
  plane_threshold = 0.05,
  label_points = FALSE
)
```

## Arguments

  - xyz:
    
    A matrix with 3 columns (X, Y, Z coordinates)

  - min\_size:
    
    Minimum cube side length

  - max\_size:
    
    Maximum cube side length

  - min\_votes:
    
    Minimum number of points required per cube

  - plane\_threshold:
    
    Distance threshold for plane detection

  - label\_points:
    
    If TRUE, label all points with cube ID

## Value

A list with detected cubes and optionally labeled points
