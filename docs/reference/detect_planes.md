# Detect planes in point cloud data using RANSAC

Detect planes in point cloud data using RANSAC

## Usage

``` r
detect_planes(
  xyz,
  distance_threshold = 0.1,
  min_votes = 100L,
  max_iterations = 1000L,
  label_points = FALSE
)
```

## Arguments

  - xyz:
    
    A matrix with 3 columns (X, Y, Z coordinates)

  - distance\_threshold:
    
    Maximum distance from plane for inliers

  - min\_votes:
    
    Minimum number of points required to detect a plane

  - max\_iterations:
    
    Maximum RANSAC iterations

  - label\_points:
    
    If TRUE, label all points with plane ID

## Value

A list with detected planes and optionally labeled points
