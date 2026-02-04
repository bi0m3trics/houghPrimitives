# News and Changes for houghPrimitives

## Version 2.0.0 (2026-02-01)

### Major Changes

- **Complete rewrite** of package to support comprehensive 3D shape detection
- **Full lidR integration** - seamless compatibility with LAS objects
- **Multiple shape types** now supported:
  - 3D lines (original functionality)
  - Planes (ground, walls, roofs)
  - Spheres
  - Cylinders (tree boles, poles)
  - Cuboids (buildings)

### New Features

#### Tree Detection
- `detect_tree_boles()`: Specialized function for forestry applications
- Vertical cylinder detection optimized for tree trunk detection
- DBH estimation from detected cylinders
- Compatible with TreeLS workflows

#### Building Detection  
- `detect_buildings()`: Automated building extraction from urban LiDAR
- Oriented bounding box detection
- Volume and footprint calculations
- Export to shapefile support

#### Comprehensive Classification
- `classify_point_shapes()`: Classify all points by geometric primitive
- `detect_all_shapes()`: Run all detection methods in one call
- Point labeling with shape type and ID
- Distance-to-shape metrics for quality assessment

#### Enhanced Workflow
- `add_shape_labels()`: Directly add results to LAS objects
- `visualize_shapes()`: Quick visualization of detection results
- `export_shapes()`: Export to GIS formats
- Print methods for all result types

### API Changes

- **Breaking**: Original `main()` function now wrapped in higher-level functions
- **New**: R interface through Rcpp instead of command-line interface
- **New**: All functions accept LAS objects or XYZ matrices
- **Enhanced**: Results returned as structured lists with metadata

### Implementation Details

- C++11 required (automatically enabled in Makevars)
- Eigen library for matrix operations
- Optimized Hough Transform implementations for each shape type
- Iterative detection with automatic point removal

### Documentation

- Complete README with quick start examples
- Three comprehensive example scripts:
  - Forest tree detection
  - Urban building detection
  - Mixed scene classification
- Function documentation with examples
- Algorithm references and citations

### Performance

- Efficient C++ implementation
- Memory-conscious point cloud handling
- Configurable resolution/accuracy tradeoffs
- Suitable for large-scale LiDAR processing

### Dependencies

- Rcpp (>= 1.0.8.3)
- RcppEigen
- Suggests: lidR, sf, rgl

### References

Based on:
- von Gioi et al. (2017) "On Straight Line Segment Detection" IPOL
- Jeltsch et al. (2016) "Hough Parameter Space Regularisation for Line Detection in 3D"
- TreeLS package methods for cylinder detection
- Building extraction methods from remote sensing literature

---

## Version 1.0 (2022-07-10)

- Initial release
- Basic 3D line detection using Hough Transform
- Command-line interface
- Based on IPOL paper implementation
