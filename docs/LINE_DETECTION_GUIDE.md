# Line Detection in Different Scenarios

## Summary

Added `in_scene` parameter to `detect_lines()` function to optimize
detection based on context:

### Parameters

``` r
detect_lines(xyz, 
             distance_threshold = 0.05,
             min_votes = 20,
             min_length = 0.5,
             max_iterations = 500,
             in_scene = TRUE,          # NEW PARAMETER
             label_points = FALSE)
```

### Modes

#### `in_scene = FALSE` (Line-Only Mode)

**Use when**: Detecting only lines (cables, edges, infrastructure scans)

**Behavior**: - More aggressive detection - Distance threshold increased
by 30% - Min votes reduced to 70% of specified value - Min length
reduced to 80% of specified value - Max iterations increased by 50%

**Example**:

``` r
# Detecting cables in infrastructure scan
result <- detect_lines(cable_points, 
                       distance_threshold = 0.05,
                       min_votes = 30,
                       min_length = 2.0,
                       in_scene = FALSE)  # Find ALL lines
```

#### `in_scene = TRUE` (Scene Mode) - DEFAULT

**Use when**: Lines exist WITH other shapes (buildings, terrain,
cylinders)

**Behavior**: - Stricter detection - Uses specified parameters as-is -
Only finds standalone lines not part of other structures - Detects lines
AFTER planes/cylinders have been identified

**Example**:

``` r
# Complex scene - detect other shapes first
planes <- detect_planes(scene, label_points = TRUE)
cylinders <- detect_cylinders(scene, label_points = TRUE)

# Then detect standalone lines from remaining points
lines <- detect_lines(scene,
                      distance_threshold = 0.06,
                      min_votes = 40,
                      in_scene = TRUE)  # Strict, standalone only
```

### Recommended Workflow

**For scenes with multiple shape types**:

``` r
# 1. Detect planes first (they're usually dominant)
planes_result <- detect_planes(points, label_points = TRUE)

# 2. Detect spheres/cylinders
spheres_result <- detect_spheres(points, label_points = TRUE)
cylinders_result <- detect_cylinders(points, label_points = TRUE)

# 3. Detect standalone lines (from remaining points)
lines_result <- detect_lines(points, 
                              in_scene = TRUE,  # Strict mode
                              label_points = TRUE)

# 4. Detect cubes/cuboids last
cubes_result <- detect_cubes(points, label_points = TRUE)
```

**For line-only scenarios**:

``` r
# Just detect all lines aggressively
lines_result <- detect_lines(cable_scan,
                              distance_threshold = 0.05,
                              min_votes = 30,
                              in_scene = FALSE,  # Aggressive mode
                              label_points = TRUE)
```

## Implementation Details

The `in_scene` parameter adjusts detection parameters internally in C++
code:

``` cpp
// When in_scene = FALSE (line-only mode)
if (!in_scene) {
  distance_threshold *= 1.3;  // More tolerance
  min_votes = max(10, (int)(min_votes * 0.7));  // Lower requirement
  min_length *= 0.8;  // Accept shorter
  max_iterations = (int)(max_iterations * 1.5);  // Search harder
}
```

This ensures optimal detection for each use case without requiring users
to manually tune many parameters.
