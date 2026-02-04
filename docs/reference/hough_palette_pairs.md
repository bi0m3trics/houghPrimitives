# Get Contrasting Color Pairs

Returns pairs of high-contrast colors suitable for foreground/background
or distinguishing adjacent shapes.

## Usage

``` r
hough_palette_pairs(n)
```

## Arguments

  - n:
    
    Number of color pairs to return (returns 2\*n colors)

## Value

Character vector of hex color codes (alternating pairs)

## Examples

``` r
# Get 3 contrasting pairs (6 colors total)
pairs <- hough_palette_pairs(3)
```
