# houghPrimitives Quick Reference Guide

## Installation

```r
# Install from GitHub
devtools::install_github("yourusername/houghPrimitives")

# Load package
library(houghPrimitives)
library(lidR)  # For LAS support
```

## Basic Workflow

### 1. Load Point Cloud

```r
# From LAS file
las <- readLAS("file.las")

# Or from XYZ matrix
xyz <- matrix(c(x, y, z), ncol = 3)
```

### 2. Detect Shapes

```r
# Trees (cylinders)
trees <- detect_tree_boles(las, min_radius = 0.1, max_radius = 0.5)

# Buildings (cuboids)
buildings <- detect_buildings(las, min_volume = 10.0)

# Planes (ground, walls)
planes <- detect_planes(las, min_votes = 50)

# Lines (edges, wires)
lines <- detect_lines_3d(las, min_votes = 10)

# All shapes at once
shapes <- classify_point_shapes(las)
```

### 3. Use Results

```r
# Add to LAS object
las <- add_shape_labels(las, trees)

# Access shape parameters
print(trees)
tree_positions <- trees$axis_points
tree_radii <- trees$radii

# Filter points
tree_points <- filter_poi(las, ShapeType == 4)

# Visualize
plot(las, color = "ShapeID")
```

## Function Reference

### Detection Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `detect_tree_boles()` | Detect tree trunks | Cylinder parameters + labels |
| `detect_buildings()` | Detect buildings | Cuboid parameters + labels |
| `detect_planes()` | Detect planar surfaces | Plane normals + labels |
| `detect_lines_3d()` | Detect linear features | Line equations + labels |
| `detect_spheres()` | Detect spheres | Centers + radii + labels |
| `detect_cylinders()` | General cylinder detection | Cylinder parameters + labels |
| `detect_cuboids()` | General cuboid detection | Cuboid parameters + labels |
| `classify_point_shapes()` | Classify all points | All shapes + labels |

### Utility Functions

| Function | Purpose |
|----------|---------|
| `add_shape_labels()` | Add results to LAS object |
| `visualize_shapes()` | Quick visualization |
| `export_shapes()` | Export to GIS formats |

## Parameter Guide

### Tree Detection Parameters

```r
detect_tree_boles(
  las,
  min_radius = 0.05,      # Minimum trunk radius (m)
  max_radius = 1.0,       # Maximum trunk radius (m)
  min_height = 0.5,       # Minimum visible trunk height (m)
  min_votes = 30,         # Minimum supporting points
  vertical_only = TRUE,   # Only detect vertical trunks
  label_points = TRUE     # Label all points
)
```

**Typical values:**
- Young forest: `min_radius = 0.05`, `max_radius = 0.3`
- Mature forest: `min_radius = 0.15`, `max_radius = 0.8`
- Dense forest: increase `min_votes` to 50-100
- Sparse forest: decrease `min_votes` to 20-30

### Building Detection Parameters

```r
detect_buildings(
  las,
  min_volume = 1.0,       # Minimum building volume (m³)
  min_votes = 100,        # Minimum supporting points
  axis_aligned = FALSE,   # Allow rotated buildings
  label_points = TRUE
)
```

**Typical values:**
- Urban areas: `min_volume = 50`, `min_votes = 200`
- Rural buildings: `min_volume = 10`, `min_votes = 100`
- Small structures: `min_volume = 1`, `min_votes = 50`

### Plane Detection Parameters

```r
detect_planes(
  las,
  max_planes = 0,             # 0 = detect all
  min_votes = 50,             # Minimum supporting points
  distance_threshold = 0.05,  # Max distance to plane (m)
  label_points = TRUE
)
```

**Typical values:**
- Ground detection: `distance_threshold = 0.1`
- Wall detection: `distance_threshold = 0.05`
- Fine features: `distance_threshold = 0.02`

### Line Detection Parameters

```r
detect_lines_3d(
  las,
  max_lines = 0,        # 0 = detect all
  min_votes = 10,       # Minimum supporting points
  dx = 0.0,             # Spatial resolution (0 = auto)
  granularity = 4,      # Direction discretization (3-5)
  label_points = TRUE
)
```

**Typical values:**
- Power lines: `min_votes = 50`, `dx = 0.1`
- Building edges: `min_votes = 20`, `dx = 0.05`
- Fine wires: `min_votes = 10`, `dx = 0.02`

## Shape Type Codes

When points are labeled, they receive a shape type code:

| Code | Shape | Typical Features |
|------|-------|------------------|
| 0 | Unknown | Unclassified |
| 1 | Line | Power lines, edges, wires |
| 2 | Plane | Ground, walls, roofs, floors |
| 3 | Sphere | Spherical objects |
| 4 | Cylinder | Trees, poles, pillars, pipes |
| 5 | Cuboid | Buildings, boxes, containers |
| 99 | Noise | Outliers, artifacts |

## Common Workflows

### Forestry: Tree Inventory

```r
# 1. Load and prepare data
las <- readLAS("forest.las")
las <- normalize_height(las, tin())

# 2. Filter to stem height
stems <- filter_poi(las, Z >= 1.0 & Z <= 2.0)

# 3. Detect trees
trees <- detect_tree_boles(stems, min_radius = 0.08, max_radius = 0.6)

# 4. Calculate metrics
dbh <- trees$radii * 2 * 100  # Convert to DBH in cm
n_trees <- trees$n_cylinders
basal_area <- sum(pi * trees$radii^2)

# 5. Export
las <- add_shape_labels(las, trees)
writeLAS(las, "trees_detected.las")
```

### Urban: Building Extraction

```r
# 1. Load urban data
las <- readLAS("urban.las")

# 2. Remove ground
las_ng <- filter_poi(las, Classification != 2)

# 3. Detect buildings
buildings <- detect_buildings(las_ng, min_volume = 25)

# 4. Calculate statistics
volumes <- buildings$dimensions[,1] * buildings$dimensions[,2] * buildings$dimensions[,3]
heights <- buildings$dimensions[,3]

# 5. Export footprints
export_shapes(buildings, "buildings", crs = st_crs(las))
```

### Mixed Scene: Complete Classification

```r
# 1. Load data
las <- readLAS("scene.las")

# 2. Classify all features
result <- classify_point_shapes(las)

# 3. Add labels
las <- add_shape_labels(las, result)

# 4. Extract components
trees <- filter_poi(las, ShapeType == 4)
buildings <- filter_poi(las, ShapeType == 5)
ground <- filter_poi(las, ShapeType == 2)

# 5. Save
writeLAS(las, "classified.las")
```

## Tips and Tricks

### Performance Optimization

```r
# Subsample for testing
las_test <- decimate_points(las, random(0.1))

# Process by tiles
ctg <- readLAScatalog("folder/")
opt_chunk_size(ctg) <- 100
result <- catalog_apply(ctg, detect_tree_boles)

# Filter irrelevant points first
las_filtered <- filter_poi(las, Z >= min_z & Z <= max_z)
```

### Quality Control

```r
# Check detection quality
hist(trees$confidence)
summary(trees$votes)

# Check point-to-shape distances
hist(las$ShapeDistance[las$ShapeType == 4])

# Compare with manual measurements
```

### Troubleshooting

**Too few detections:**
- Decrease `min_votes`
- Increase `max_radius` (trees) or `max_planes` (buildings)
- Check point cloud density
- Verify height normalization

**Too many false positives:**
- Increase `min_votes`
- Decrease `max_radius` or increase `min_radius`
- Add pre-filtering steps
- Adjust distance thresholds

**Poor accuracy:**
- Decrease `dx` for finer resolution
- Increase `granularity` for more directions
- Use more points (increase `min_votes`)
- Check for systematic errors in input data

## Advanced Usage

### Custom Filtering

```r
# Combine shape detection with other attributes
las$IsLargeTree <- las$ShapeType == 4 & las$ShapeDistance < 0.05
large_trees <- filter_poi(las, IsLargeTree)

# Use detection confidence
reliable_shapes <- filter_poi(las, ShapeType > 0 & ShapeDistance < 0.1)
```

### Integration with Other Packages

```r
# With TreeLS
library(TreeLS)
normalized <- normalize_height(las, tin())
trees_hough <- detect_tree_boles(normalized)
trees_tls <- stemPoints(normalized, stm.hough())

# Compare methods
# ...

# With ForestTools
library(ForestTools)
chm <- grid_canopy(las, 0.5, pitfree())
trees_hough <- detect_tree_boles(las)
# ...
```

### Export for GIS Analysis

```r
library(sf)

# Create spatial features
tree_points <- st_as_sf(
  data.frame(
    X = trees$axis_points[,1],
    Y = trees$axis_points[,2],
    DBH = trees$radii * 2
  ),
  coords = c("X", "Y"),
  crs = st_crs(las)
)

st_write(tree_points, "trees.gpkg")
```

## See Also

- Package documentation: `?houghPrimitives`
- Examples: See `examples/` folder
- lidR package: https://github.com/r-lidar/lidR
- IPOL paper: https://www.ipol.im/pub/art/2017/208/
