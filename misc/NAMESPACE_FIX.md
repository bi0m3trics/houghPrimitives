# NAMESPACE Fix for Rcpp Registration

## Problem
Previously, running `roxygen2::roxygenize()` would regenerate the NAMESPACE file but omit critical directives needed for Rcpp C++ function registration:
- `useDynLib(houghPrimitives, .registration = TRUE)`
- `importFrom(Rcpp,sourceCpp)`

This caused all `detect_*` functions to fail with errors like:
```
Error: .Call function '_houghPrimitives_detect_spheres' not available
```

## Solution
Created [R/houghPrimitives-package.R](R/houghPrimitives-package.R) with roxygen2 directives:

```r
#' @keywords internal
#' @aliases houghPrimitives-package
"_PACKAGE"

## usethis namespace: start
#' @useDynLib houghPrimitives, .registration = TRUE
#' @importFrom Rcpp sourceCpp
## usethis namespace: end
NULL
```

## How It Works
- The `@useDynLib` roxygen tag tells roxygen2 to include the `useDynLib()` directive in NAMESPACE
- The `@importFrom` roxygen tag tells roxygen2 to include the `importFrom()` directive
- These directives are now **automatically** maintained by roxygen2 during package builds
- The special `"_PACKAGE"` string creates package-level documentation

## Verification
The fix persists across multiple `roxygen2::roxygenize()` calls. The NAMESPACE now always includes:
```r
importFrom(Rcpp,sourceCpp)
useDynLib(houghPrimitives, .registration = TRUE)
```

## References
- https://www.rcpp.org/
- https://r-pkgs.org/package-within.html#sec-package-within-side-effects
- https://roxygen2.r-lib.org/articles/namespace.html
