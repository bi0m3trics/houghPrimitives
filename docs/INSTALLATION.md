# Installation and Testing Guide for houghPrimitives

## Prerequisites

### System Requirements

  - R (\>= 3.5.0)
  - C++ compiler with C++11 support
      - Windows: Rtools
      - macOS: Xcode Command Line Tools
      - Linux: g++ or clang

### R Package Dependencies

Required: - Rcpp (\>= 1.0.8.3) - RcppEigen

Suggested for full functionality: - lidR (for LAS file support) - sf
(for spatial export) - rgl (for 3D visualization)

## Installation Steps

### 1\. Install Dependencies

``` r
install.packages(c("Rcpp", "RcppEigen"))
install.packages(c("lidR", "sf", "rgl"))  # Optional but recommended
```

### 2\. Compile Rcpp Attributes

Before building the package, you need to generate Rcpp exports:

``` r
library(Rcpp)
setwd("e:/GithubRepos/houghPrimitives")
Rcpp::compileAttributes()
```

This will create/update: - `R/RcppExports.R` - `src/RcppExports.cpp`

### 3\. Build and Install Package

#### Option A: Using RStudio

1.  Open `houghPrimitives.Rproj` in RStudio
2.  Click Build → Clean and Rebuild
3.  Click Build → Install and Restart

#### Option B: Using devtools

``` r
library(devtools)
setwd("e:/GithubRepos/houghPrimitives")
document()  # Generate documentation
build()     # Build package
install()   # Install package
```

#### Option C: Command line

``` powershell
cd e:\GithubRepos\houghPrimitives
R CMD build .
R CMD INSTALL houghPrimitives_2.0.0.tar.gz
```

### 4\. Verify Installation

``` r
library(houghPrimitives)
?houghPrimitives  # View package help
```

## Quick Tests

### Test 1: Basic Functionality

``` r
library(houghPrimitives)

# Create simple test data (a cylinder)
n <- 1000
theta <- runif(n, 0, 2*pi)
h <- runif(n, 0, 5)
r <- 0.3
noise <- rnorm(n, 0, 0.01)

x <- r * cos(theta) + noise
y <- r * sin(theta) + noise
z <- h

xyz <- cbind(x, y, z)

# Test cylinder detection
result <- detect_cylinders(xyz, 
                          min_radius = 0.2,
                          max_radius = 0.4,
                          min_height = 2.0,
                          min_votes = 50)

# Should detect 1 cylinder near r=0.3
print(result)
```

### Test 2: Plane Detection

``` r
# Create a plane (z = 0)
n <- 1000
x <- runif(n, -5, 5)
y <- runif(n, -5, 5)
z <- rnorm(n, 0, 0.01)

xyz <- cbind(x, y, z)

# Detect plane
planes <- detect_planes(xyz, min_votes = 100)

# Should detect 1 horizontal plane
print(planes)
```

### Test 3: Line Detection

``` r
# Create a line along z-axis
n <- 500
t <- runif(n, 0, 10)
noise <- 0.01

x <- rnorm(n, 0, noise)
y <- rnorm(n, 0, noise)
z <- t

xyz <- cbind(x, y, z)

# Detect line
lines <- detect_lines_3d(xyz, min_votes = 50)

# Should detect 1 line along z-axis
print(lines)
```

### Test 4: lidR Integration (if lidR installed)

``` r
if (requireNamespace("lidR", quietly = TRUE)) {
  library(lidR)
  
  # Create simple LAS
  x <- runif(1000, 0, 100)
  y <- runif(1000, 0, 100)
  z <- runif(1000, 0, 10)
  
  las <- LAS(data.frame(X = x, Y = y, Z = z))
  
  # Test classification
  result <- classify_point_shapes(las)
  
  print(result)
  cat("Test passed: lidR integration works!\n")
}
```

## Troubleshooting

### Common Issues

#### Issue 1: Compilation Errors

**Error: “C++11 required”**

``` r
# Add to ~/.R/Makevars (Linux/Mac) or ~/.R/Makevars.win (Windows)
CXX = g++
CXX_STD = CXX11
```

**Error: “Eigen not found”**

``` r
# Reinstall RcppEigen
install.packages("RcppEigen", type = "source")
```

#### Issue 2: Missing Exports

**Error: “could not find function ‘detect\_tree\_boles’”**

Solution: Recompile attributes

``` r
Rcpp::compileAttributes("e:/GithubRepos/houghPrimitives")
devtools::document("e:/GithubRepos/houghPrimitives")
```

#### Issue 3: Linking Errors on Windows

**Error: “undefined reference to…”**

Solution: Ensure Rtools is properly installed and on PATH

``` powershell
# Check Rtools
Rscript -e "Sys.which('make')"
```

#### Issue 4: Package Loads but Functions Fail

Check that all source files are being compiled:

``` r
# Should list all .cpp files
list.files("e:/GithubRepos/houghPrimitives/src", pattern = "\\.cpp$")

# Should include:
# - hough.cpp
# - hough3dlines.cpp (helper functions, no longer standalone program)
# - pointcloud.cpp
# - sphere.cpp
# - vector3d.cpp
# - shape_detector.cpp
# - lidr_interface.cpp
# - RcppExports.cpp
```

### Performance Issues

If detection is very slow: 1. Start with small test datasets 2. Use
lower resolution (larger `dx`) 3. Decrease `granularity` parameter 4.
Filter point cloud before detection

### Memory Issues

For large point clouds: 1. Process in tiles 2. Use
`lidR::catalog_apply()` 3. Filter to relevant height ranges 4. Subsample
dense areas

## Validation

### Run Example Scripts

``` r
# From R console
setwd("e:/GithubRepos/houghPrimitives/examples")
source("example_tree_detection.R")
source("example_building_detection.R")
source("example_comprehensive_classification.R")
```

Note: You’ll need to modify file paths to point to your own LAS files.

### Unit Tests (Optional)

Create `tests/testthat/test-detection.R`:

``` r
library(testthat)
library(houghPrimitives)

test_that("Cylinder detection works", {
  # Create test cylinder
  n <- 1000
  theta <- runif(n, 0, 2*pi)
  h <- runif(n, 0, 5)
  r <- 0.3
  
  xyz <- cbind(
    r * cos(theta) + rnorm(n, 0, 0.01),
    r * sin(theta) + rnorm(n, 0, 0.01),
    h
  )
  
  result <- detect_cylinders(xyz, 
                            min_radius = 0.2,
                            max_radius = 0.4,
                            min_height = 2.0)
  
  expect_gt(result$n_cylinders, 0)
  expect_true(abs(result$radii[1] - 0.3) < 0.05)
})
```

Run tests:

``` r
devtools::test("e:/GithubRepos/houghPrimitives")
```

## Next Steps

Once installation is verified:

1.  **Read Documentation**
      - README.md - Overview and quick start
      - QUICK\_REFERENCE.md - Function reference
      - examples/ - Example scripts
2.  **Try with Real Data**
      - Start with small LAS files
      - Experiment with parameters
      - Compare results with known ground truth
3.  **Integrate into Workflow**
      - Combine with lidR pipelines
      - Export results for GIS
      - Automate processing

## Getting Help

1.  Check documentation: `?function_name`
2.  Review examples in `examples/` folder
3.  Read QUICK\_REFERENCE.md
4.  Check GitHub issues
5.  Contact package maintainer

## Reporting Issues

When reporting bugs, include: - R version: `R.version.string` - Package
version: `packageVersion("houghPrimitives")` - OS and compiler version -
Minimal reproducible example - Error messages and warnings - Point cloud
characteristics (size, density, etc.)

## Development

To contribute or modify the package:

``` r
# Fork and clone repository
# Make changes
# Test
devtools::check("e:/GithubRepos/houghPrimitives")

# Build documentation
devtools::document("e:/GithubRepos/houghPrimitives")

# Run tests
devtools::test("e:/GithubRepos/houghPrimitives")

# Build package
devtools::build("e:/GithubRepos/houghPrimitives")
```

## License

BSD 2-Clause - see LICENSE file

## Acknowledgments

Based on the IPOL paper and demo: -
<https://www.ipol.im/pub/art/2017/208/> -
<https://ipolcore.ipol.im/demo/clientApp/demo.html?id=208>

Inspired by: - TreeLS package for tree detection - Various building
detection methods from remote sensing literature

-----

Last updated: 2026-02-01
