# Detect general cylinders (not just vertical) in point cloud data

Detect general cylinders (not just vertical) in point cloud data

## Usage

``` r
detect_cylinders(
  xyz,
  min_radius = 0.1,
  max_radius = 2,
  min_length = 1,
  min_votes = 50L,
  label_points = FALSE
)
```

## Arguments

  - xyz:
    
    A matrix with 3 columns (X, Y, Z coordinates)

  - min\_radius:
    
    Minimum cylinder radius

  - max\_radius:
    
    Maximum cylinder radius

  - min\_length:
    
    Minimum cylinder length

  - min\_votes:
    
    Minimum number of points required

  - label\_points:
    
    If TRUE, label all points with cylinder ID

## Value

A list with detected cylinders and optionally labeled points
