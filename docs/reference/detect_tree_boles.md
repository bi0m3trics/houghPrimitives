# Detect tree boles (cylindrical trunks) in point cloud data

Detect tree boles (cylindrical trunks) in point cloud data

## Usage

``` r
detect_tree_boles(
  xyz,
  min_radius = 0.05,
  max_radius = 0.5,
  min_height = 1,
  min_votes = 30L,
  vertical_only = TRUE,
  label_points = FALSE
)
```

## Arguments

  - xyz:
    
    A matrix with 3 columns (X, Y, Z coordinates)

  - min\_radius:
    
    Minimum trunk radius in meters

  - max\_radius:
    
    Maximum trunk radius in meters

  - min\_height:
    
    Minimum visible trunk height in meters

  - min\_votes:
    
    Minimum number of points required to detect a tree

  - vertical\_only:
    
    If TRUE, only detect vertical cylinders

  - label\_points:
    
    If TRUE, label all points with tree ID

## Value

A list with detected trees and optionally labeled points
