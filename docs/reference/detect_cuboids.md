# Detect cuboids (rectangular boxes) in point cloud data

Detect cuboids (rectangular boxes) in point cloud data

## Usage

``` r
detect_cuboids(
  xyz,
  min_width = 0.5,
  max_width = 10,
  min_height = 0.5,
  max_height = 10,
  min_votes = 150L,
  plane_threshold = 0.1,
  label_points = FALSE
)
```

## Arguments

  - xyz:
    
    A matrix with 3 columns (X, Y, Z coordinates)

  - min\_width:
    
    Minimum cuboid width

  - max\_width:
    
    Maximum cuboid width

  - min\_height:
    
    Minimum cuboid height

  - max\_height:
    
    Maximum cuboid height

  - min\_votes:
    
    Minimum number of points required per cuboid

  - plane\_threshold:
    
    Distance threshold for plane detection

  - label\_points:
    
    If TRUE, label all points with cuboid ID

## Value

A list with detected cuboids and optionally labeled points
