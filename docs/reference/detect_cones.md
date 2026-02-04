# Detect cones in 3D point cloud

Detect cones in 3D point cloud

## Usage

``` r
detect_cones(
  xyz,
  min_radius = 0.1,
  max_radius = 2,
  min_height = 0.5,
  max_height = 10,
  min_votes = 50L,
  angle_threshold = 0.3,
  label_points = FALSE
)
```

## Arguments

  - xyz:
    
    A matrix with 3 columns (X, Y, Z coordinates)

  - min\_radius:
    
    Minimum base radius in meters

  - max\_radius:
    
    Maximum base radius in meters

  - min\_height:
    
    Minimum cone height in meters

  - max\_height:
    
    Maximum cone height in meters

  - min\_votes:
    
    Minimum number of points to form a cone

  - angle\_threshold:
    
    Opening half-angle threshold in radians (default: 0.3 ~ 17 degrees)

  - label\_points:
    
    If TRUE, return point labels

## Value

A list with detected cones
