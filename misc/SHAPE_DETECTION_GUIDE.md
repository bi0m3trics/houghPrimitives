# Shape Detection Guide for houghPrimitives

## Overview

The `houghPrimitives` package provides detection for 6 types of 3D primitive shapes in point cloud data:

| Shape | Function | Method | Complexity |
|-------|----------|--------|------------|
| **Spheres** | `detect_spheres()` | Spatial clustering + circularity validation | ★★☆☆☆ |
| **Cylinders** | `detect_cylinders()` | Cross-section analysis | ★★★☆☆ |
| **Planes** | `detect_planes()` | RANSAC plane fitting | ★★☆☆☆ |
| **Lines** | `detect_lines()` | RANSAC 3D line fitting | ★★☆☆☆ |
| **Cubes** | `detect_cubes()` | Orthogonal plane analysis (6 faces) | ★★★★☆ |
| **Cuboids** | `detect_cuboids()` | Multi-plane rectangular fitting | ★★★★☆ |
| **Tree Boles** | `detect_tree_boles()` | Vertical cylinder with multi-slice validation | ★★★☆☆ |

## Function Parameters

### 1. Sphere Detection
```r
detect_spheres(xyz,
               min_radius = 0.1,
               max_radius = 2.0,
               min_votes = 30,
               label_points = FALSE)
```

**Use Cases:**
- Decorative balls/spheres in urban scenes
- Tank ends, dome structures
- Spherical objects in industrial scans

**Parameters:**
- `min_radius`, `max_radius`: Expected radius range
- `min_votes`: Minimum points required per sphere
- `label_points`: If TRUE, returns point labels with sphere IDs

**Returns:**
- `n_spheres`: Number of detected spheres
- `spheres`: DataFrame with (x, y, z, radius, n_points)
- `point_labels` (if requested): Integer vector with sphere IDs (0 = not a sphere)

---

### 2. Cylinder Detection
```r
detect_cylinders(xyz,
                 min_radius = 0.1,
                 max_radius = 2.0,
                 min_length = 1.0,
                 min_votes = 50,
                 label_points = FALSE)
```

**Use Cases:**
- Poles, pillars
- Pipe detection
- General cylindrical objects (any orientation)

**Parameters:**
- `min_radius`, `max_radius`: Expected radius range
- `min_length`: Minimum cylinder length
- `min_votes`: Minimum points per cylinder
- `label_points`: If TRUE, returns point labels

**Returns:**
- `n_cylinders`: Number detected
- `cylinders`: DataFrame with (cylinder_id, x1, y1, z1, x2, y2, z2, radius, n_points)
  - (x1,y1,z1) and (x2,y2,z2) are the endpoints of the cylinder axis
- `point_labels` (if requested): Integer vector

---

### 3. Tree Bole Detection (Specialized Cylinders)
```r
detect_tree_boles(xyz,
                  min_radius = 0.05,
                  max_radius = 0.5,
                  min_height = 1.0,
                  min_votes = 30,
                  vertical_only = TRUE,
                  label_points = FALSE)
```

**Use Cases:**
- Forest inventory
- Urban tree detection
- Vertical cylinder structures

**Parameters:**
- `min_radius`, `max_radius`: Expected trunk radius
- `min_height`: Minimum visible trunk height
- `min_votes`: Minimum points per tree
- `vertical_only`: If TRUE, only detect vertical cylinders
- `label_points`: If TRUE, returns point labels

**Returns:**
- `n_trees`: Number detected
- `trees`: DataFrame with (tree_id, x, y, radius, height, n_points)
- `point_labels` (if requested): Integer vector with tree IDs

---

### 4. Plane Detection
```r
detect_planes(xyz,
              distance_threshold = 0.1,
              min_votes = 100,
              max_iterations = 1000,
              label_points = FALSE)
```

**Use Cases:**
- Ground extraction
- Wall/facade detection
- Roof planes
- Any flat surface

**Parameters:**
- `distance_threshold`: Max distance from point to plane
- `min_votes`: Minimum points per plane
- `max_iterations`: RANSAC iterations
- `label_points`: If TRUE, returns point labels

**Returns:**
- `n_planes`: Number detected
- `planes`: DataFrame with (plane_id, a, b, c, d, n_points)
  - Plane equation: ax + by + cz + d = 0
- `point_labels` (if requested): Integer vector

**Algorithm:** RANSAC with 3-point plane fitting

---

### 5. Line Detection
```r
detect_lines(xyz,
             distance_threshold = 0.05,
             min_votes = 20,
             min_length = 0.5,
             max_iterations = 500,
             label_points = FALSE)
```

**Use Cases:**
- Power lines, cables
- Beams, edges
- Linear features

**Parameters:**
- `distance_threshold`: Max perpendicular distance from point to line
- `min_votes`: Minimum points per line
- `min_length`: Minimum line length
- `max_iterations`: RANSAC iterations
- `label_points`: If TRUE, returns point labels

**Returns:**
- `n_lines`: Number detected
- `lines`: DataFrame with (line_id, x1, y1, z1, x2, y2, z2, n_points)
  - (x1,y1,z1) and (x2,y2,z2) are the line endpoints
- `point_labels` (if requested): Integer vector

**Algorithm:** RANSAC with 2-point line fitting

---

### 6. Cube Detection
```r
detect_cubes(xyz,
             min_size = 0.3,
             max_size = 3.0,
             min_votes = 100,
             plane_threshold = 0.05,
             label_points = FALSE)
```

**Use Cases:**
- Storage boxes
- Cubic containers
- Regular box-shaped objects

**Parameters:**
- `min_size`, `max_size`: Expected cube side length range
- `min_votes`: Minimum total points per cube
- `plane_threshold`: Distance threshold for plane detection
- `label_points`: If TRUE, returns point labels

**Returns:**
- `n_cubes`: Number detected
- `cubes`: DataFrame with (cube_id, x, y, z, size, n_points)
  - (x,y,z) is the center, size is the edge length
- `point_labels` (if requested): Integer vector

**Algorithm:** 
1. First detects planes using RANSAC
2. Searches for 6 orthogonal planes forming a regular cube
3. Validates cube dimensions

**Note:** Requires all 6 faces to be well-represented in point cloud. Success varies with:
- Point density on each face
- Noise levels
- Occlusion (missing faces)

---

### 7. Cuboid Detection
```r
detect_cuboids(xyz,
               min_width = 0.5,
               max_width = 10.0,
               min_height = 0.5,
               max_height = 10.0,
               min_votes = 150,
               plane_threshold = 0.1,
               label_points = FALSE)
```

**Use Cases:**
- Building detection
- Rectangular containers
- Box-like structures (non-cubic)

**Parameters:**
- `min_width`, `max_width`: Expected width/depth range
- `min_height`, `max_height`: Expected height range  
- `min_votes`: Minimum total points per cuboid
- `plane_threshold`: Distance threshold for plane detection
- `label_points`: If TRUE, returns point labels

**Returns:**
- `n_cuboids`: Number detected
- `cuboids`: DataFrame with (cuboid_id, x, y, z, width, depth, height, n_points)
  - (x,y,z) is the center
- `point_labels` (if requested): Integer vector

**Algorithm:**
1. Detects planes using RANSAC
2. Searches for 4+ orthogonal/parallel planes forming rectangular boxes
3. Computes bounding box dimensions

**Note:** Similar challenges to cube detection. May produce variable results depending on scene complexity.

---

## Examples

### Quick Example: Sphere Detection
```r
library(houghPrimitives)

# Generate synthetic sphere
theta <- runif(200, 0, 2*pi)
phi <- acos(2*runif(200) - 1)
x <- 5 + 1.0 * sin(phi) * cos(theta)
y <- 5 + 1.0 * sin(phi) * sin(theta)
z <- 2 + 1.0 * cos(phi)
points <- cbind(x, y, z)

# Detect
result <- detect_spheres(points, min_radius = 0.8, max_radius = 1.2, min_votes = 50)
print(result$spheres)
#   sphere_id   x   y   z radius n_points
# 1         1 5.0 5.0 2.0    1.0      200
```

### See Full Examples
- `examples/example_sphere_detection.R` - Sphere detection with noise
- `examples/example_tree_detection.R` - Tree bole detection in forest
- `examples/example_all_shapes.R` - Comprehensive multi-shape detection

---

## Tips for Best Results

### General Guidelines
1. **Point Density**: Higher density improves detection accuracy
2. **Noise**: Lower noise levels improve all detection methods
3. **Parameter Tuning**: Adjust `min_votes` and thresholds based on your data

### Shape-Specific Tips

**Spheres:**
- Works best with uniform point distribution on sphere surface
- Increase `min_votes` to avoid detecting small sphere fragments

**Cylinders:**
- Ensure cylinder axis is well-sampled
- For tree detection, use `detect_tree_boles()` for vertical cylinders

**Planes:**
- Larger `distance_threshold` for noisy data
- Increase `max_iterations` for complex scenes

**Lines:**
- Tight `distance_threshold` for clean line detection
- Ensure lines have consistent point density

**Cubes/Cuboids:**
- Require good sampling of multiple faces
- May fail if faces are occluded or poorly sampled
- Consider using `detect_planes()` directly and analyzing plane relationships
- Best for clean, well-structured synthetic data or high-quality scans

---

## Visualization with lidR

All detection functions can label points, making visualization easy:

```r
library(lidR)
library(houghPrimitives)

# Detect shapes with labeling
spheres <- detect_spheres(points, label_points = TRUE)
planes <- detect_planes(points, label_points = TRUE)

# Create LAS object with classifications
las <- LAS(data.frame(
  X = points[,1],
  Y = points[,2],
  Z = points[,3],
  Classification = ifelse(spheres$point_labels > 0, 7L,
                   ifelse(planes$point_labels > 0, 2L, 1L))
))

# Interactive 3D plot
plot(las, color = "Classification", size = 3)
```

---

## Algorithm References

**RANSAC (Planes & Lines):**
- Fischler, M. A., & Bolles, R. C. (1981). Random sample consensus: a paradigm for model fitting.

**Sphere Detection:**
- Spatial clustering with circularity validation

**Cylinder Detection:**
- Cross-sectional analysis with circular fitting

**Tree Detection:**
- Multi-slice vertical consistency validation inspired by TreeLS methods

**Cube/Cuboid Detection:**
- Novel plane-based geometric analysis for composite structures
