# Building pkgdown Articles for houghPrimitives

## Articles Created

Five comprehensive vignettes have been created for shape classification:

### 1. Introduction to Shape Classification (`shape-classification-intro.Rmd`)
- Overview of all supported shape types
- Basic workflow and usage patterns
- Understanding return values
- Key parameters explained
- Common use cases (forestry, urban, infrastructure)

### 2. Sphere Detection (`sphere-detection.Rmd`)
- How sphere detection works (iterative center refinement)
- Parameter selection guide
- Synthetic examples with noise
- Detection quality metrics
- Troubleshooting tips
- Best practices

### 3. Line Detection Strategies (`line-detection.Rmd`)
- Two detection modes: `in_scene = TRUE/FALSE`
- When to use each mode
- Parameter tuning for different scenarios
- Comparison of aggressive vs strict detection
- Workflow recommendations
- Common issues and solutions

### 4. Multi-Shape Scene Classification (`multi-shape-classification.Rmd`)
- Complete workflow for complex scenes
- Detection order and why it matters
- Combining point labels from multiple detectors
- Real-world examples (urban, forestry)
- Performance tips for large scenes
- Troubleshooting multi-shape scenarios

### 5. Parameter Tuning Guide (`parameter-tuning.Rmd`)
- Precision-recall tradeoff
- Universal parameters (min_votes, distance_threshold, max_iterations)
- Shape-specific parameter selection
- Systematic tuning workflow
- Common issues and solutions
- Adaptive parameter strategies

## Building the pkgdown Site

### Prerequisites

Install required packages:

```r
install.packages(c("pkgdown", "knitr", "rmarkdown"))
```

### Build the Site

From the package root directory:

```r
# Load pkgdown
library(pkgdown)

# Build the complete site
pkgdown::build_site()

# Or build just the articles
pkgdown::build_articles()

# Preview locally
pkgdown::preview_site()
```

### Command Line

Alternatively, from the package root:

```bash
# Using R
R -e "pkgdown::build_site()"

# Preview in browser
R -e "pkgdown::preview_site()"
```

### Build Individual Articles

To rebuild specific articles during development:

```r
# Build one article
pkgdown::build_article("shape-classification-intro")

# Build all articles
pkgdown::build_articles()
```

## Site Structure

The pkgdown site will be organized as:

- **Getting Started**
  - Introduction to Shape Classification
  
- **Detection Methods**
  - Sphere Detection
  - Line Detection Strategies
  - Multi-Shape Scene Classification
  
- **Advanced Topics**
  - Parameter Tuning Guide

## Configuration

The site is configured via `_pkgdown.yml`:

- Bootstrap 5 theme with Cosmo bootswatch
- Organized navigation menu
- Reference documentation grouped by function type
- Articles grouped by topic

## Publishing to GitHub Pages

1. Build the site:
   ```r
   pkgdown::build_site()
   ```

2. The site will be in `docs/` folder

3. Commit and push:
   ```bash
   git add docs/
   git commit -m "Update pkgdown site"
   git push
   ```

4. Enable GitHub Pages:
   - Go to repository Settings > Pages
   - Source: Deploy from branch
   - Branch: main, folder: /docs
   - Save

5. Site will be available at: `https://yourusername.github.io/houghPrimitives`

## Updating Articles

When you update vignettes:

1. Edit the `.Rmd` file in `vignettes/`
2. Rebuild the site:
   ```r
   pkgdown::build_site()
   ```
3. Commit and push the updated `docs/` folder

## Article Content Summary

### Coverage by Topic

**Shape Detection Functions:**
- ✓ Spheres (dedicated article)
- ✓ Lines (dedicated article)
- ✓ Cylinders (covered in multi-shape)
- ✓ Planes (covered in multi-shape)
- ✓ Cubes/Cuboids (covered in multi-shape)
- ✓ Tree boles (covered in intro and multi-shape)

**Key Concepts:**
- ✓ Detection order importance
- ✓ Parameter selection strategies
- ✓ Point labeling and classification
- ✓ Precision-recall tradeoff
- ✓ Context-aware detection (`in_scene` parameter)
- ✓ Multi-shape workflow
- ✓ Visualization with lidR
- ✓ Troubleshooting common issues

**Code Examples:**
- ✓ Synthetic data generation
- ✓ Complete classification workflows
- ✓ Parameter tuning examples
- ✓ Real-world scenarios (urban, forestry, infrastructure)
- ✓ Quality metrics and validation

## Files Created

```
houghPrimitives/
├── _pkgdown.yml                                    # pkgdown configuration
├── DESCRIPTION                                     # Updated with vignette dependencies
└── vignettes/
    ├── shape-classification-intro.Rmd              # Introduction
    ├── sphere-detection.Rmd                        # Sphere detection guide
    ├── line-detection.Rmd                          # Line detection strategies
    ├── multi-shape-classification.Rmd              # Multi-shape workflows
    └── parameter-tuning.Rmd                        # Parameter tuning guide
```

## Next Steps

1. **Review the vignettes** - Check that code examples match your actual function signatures
2. **Build the site** - Run `pkgdown::build_site()` to generate HTML
3. **Preview locally** - Check formatting and navigation
4. **Update URLs** - Replace `yourusername` in `_pkgdown.yml` with actual GitHub username
5. **Publish** - Push to GitHub and enable Pages

## Notes

- All vignettes use `eval=FALSE` in code chunks to avoid requiring actual data during build
- Examples are comprehensive and self-contained
- Mathematical formulas use KaTeX notation where appropriate
- Cross-references between articles are included
- Each article builds on concepts from previous ones

Enjoy your new pkgdown documentation site! 📚
