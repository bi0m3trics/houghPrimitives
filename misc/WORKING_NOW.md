# Quick Start Guide

## The Issue Was Fixed!

The problem was that the NAMESPACE file was missing the `importFrom(Rcpp,sourceCpp)` and `useDynLib()` directives, which are required for Rcpp packages to properly register C++ functions.

## Installation & Usage

```r
# Install the package
devtools::install()

# OR if that doesn't work, install from source:
install.packages(".", repos = NULL, type = "source")

# Load the package
library(houghPrimitives)

# Quick test
test_points <- matrix(rnorm(900, sd = 2), ncol = 3)
result <- detect_spheres(test_points)
print(result)
```

## Test It's Working

Run the included test script:
```r
source("test_package.R")
```

You should see:
```
=== Testing houghPrimitives Package ===

1. Testing detect_spheres... ✓ Found X spheres
2. Testing detect_cylinders... ✓ Found X cylinders
...
=== ALL FUNCTIONS WORKING! ===
```

## Run the Examples

All three examples should now work:

```r
library(houghPrimitives)

# Example 1: Sphere detection with noise
source("examples/example_sphere_detection.R")

# Example 2: Tree bole detection
source("examples/example_tree_detection.R")

# Example 3: ALL shapes (comprehensive demo)
source("examples/example_all_shapes.R")
```

## All Available Functions

The package now exports **8 functions** for detecting **6 primitive shape types**:

1. **detect_spheres()** - Detect spherical objects
2. **detect_cylinders()** - Detect cylinders (any orientation)
3. **detect_tree_boles()** - Detect vertical cylinders (trees/poles)
4. **detect_planes()** - Detect planar surfaces
5. **detect_lines()** - Detect 3D lines
6. **detect_cubes()** - Detect cubic boxes (via plane analysis)
7. **detect_cuboids()** - Detect rectangular structures (via plane analysis)
8. **summarize_points()** - Get basic point cloud statistics

## Notes on Cube/Cuboid Detection

- Cubes and cuboids are **composite shapes** made of multiple planes
- Detection works by:
  1. First detecting all planes in the scene
  2. Analyzing plane relationships (orthogonal/parallel)
  3. Finding sets of planes forming boxes
- Success depends on:
  - Point density on each face
  - Noise levels
  - All faces being visible (not occluded)
- Works best on clean, synthetic data or high-quality scans

## Documentation

- **SHAPE_DETECTION_GUIDE.md** - Complete guide with all parameters and examples
- **README.md** - Package overview
- **examples/** - Three working examples with lidR visualizations

## What Was Implemented

All the primitive shape detectors you requested:
- ✅ Cylinders
- ✅ Cubes  
- ✅ Spheres
- ✅ Lines
- ✅ Planes
- ✅ Cuboids (rectangular boxes/buildings)

The comprehensive example (`example_all_shapes.R`) demonstrates detecting all 6 shape types in a single complex scene with visualization using lidR.
