# Color Palettes for Hough Primitives Visualization
#
# Two palette schemes optimized for point cloud visualizations:
#   - hough_palette: Full spectrum with dark anchors and bright highlights
#   - hough_palette_contrast: High-contrast colors for distinguishing shapes

#' Get Hough Color Palette
#'
#' Returns colors from the Hough color palette, cycling through if more colors
#' are requested than available. The palette includes dark anchors, warm tones,
#' cool blues/cyans, purples, and highlights.
#'
#' @param n Number of colors to return
#' @param type Palette type: "full" (default, all 20 colors) or "contrast" (high-contrast subset)
#' @return Character vector of hex color codes
#' @export
#' @examples
#' # Get 5 colors
#' hough_palette(5)
#' 
#' # Get high-contrast colors
#' hough_palette(10, type = "contrast")
#' 
#' # Visualize palette
#' if (require(graphics)) {
#'   colors <- hough_palette(12)
#'   barplot(rep(1, 12), col = colors, border = NA, axes = FALSE)
#' }
hough_palette <- function(n, type = c("full", "contrast")) {
  type <- match.arg(type)
  
  if (type == "full") {
    pal <- c(
      "#0B0E14",  # near-black (background anchor)
      "#1F2937",  # dark slate
      "#2E3440",  # cool charcoal
      "#FF9F1C",  # amber orange
      "#FF7A18",  # hot orange
      "#E4572E",  # ember red
      "#FF3C38",  # signal red
      "#FFD166",  # warm gold
      "#F4D35E",  # soft yellow
      "#E9C46A",  # muted gold
      "#2EC4B6",  # teal
      "#00B4D8",  # cyan
      "#4CC9F0",  # electric blue
      "#4895EF",  # saturated blue
      "#7209B7",  # deep purple
      "#9D4EDD",  # neon violet
      "#B5179E",  # magenta
      "#A8DADC",  # pale cyan (highlight)
      "#EAEAEA",  # soft white
      "#FFFFFF"   # pure white
    )
  } else {
    # High-contrast palette - optimized for distinguishing different shapes
    pal <- c(
      "#FF9F1C",  # orange
      "#4CC9F0",  # bright blue
      "#E4572E",  # red-orange
      "#2EC4B6",  # teal
      "#FFD166",  # yellow
      "#7209B7",  # deep purple
      "#FF3C38",  # red
      "#00B4D8",  # cyan
      "#E9C46A",  # gold
      "#B5179E",  # magenta
      "#4895EF",  # blue
      "#F4D35E",  # yellow-light
      "#9D4EDD",  # violet
      "#A8DADC",  # pale cyan
      "#1F2937",  # dark slate
      "#EAEAEA",  # soft white
      "#2E3440",  # charcoal
      "#FFFFFF",  # white
      "#0B0E14"   # near-black
    )
  }
  
  if (n <= 0) {
    return(character(0))
  }
  
  # Cycle through palette if more colors requested than available
  if (n <= length(pal)) {
    return(pal[1:n])
  } else {
    return(rep_len(pal, n))
  }
}

#' Generate Interpolated Colors from Hough Palette
#'
#' Creates a smooth color gradient by interpolating between colors in the
#' Hough palette. Useful when you need many distinct colors.
#'
#' @param n Number of colors to return
#' @param type Palette type: "full" or "contrast"
#' @param alpha Transparency level (0-1), default 1 (opaque)
#' @return Character vector of hex color codes
#' @export
#' @examples
#' # Generate 50 interpolated colors
#' colors <- hough_palette_gradient(50)
#' 
#' # With transparency
#' colors_alpha <- hough_palette_gradient(20, alpha = 0.7)
hough_palette_gradient <- function(n, type = c("full", "contrast"), alpha = 1) {
  type <- match.arg(type)
  
  if (n <= 0) {
    return(character(0))
  }
  
  # Get base palette (skip dark anchors for gradients)
  if (type == "full") {
    base_colors <- hough_palette(20, "full")[4:17]  # Colorful middle section
  } else {
    base_colors <- hough_palette(14, "contrast")[1:14]  # High-contrast colors
  }
  
  # Use colorRampPalette to interpolate
  ramp <- grDevices::colorRampPalette(base_colors)
  colors <- ramp(n)
  
  # Apply alpha if requested
  if (alpha < 1) {
    colors <- grDevices::adjustcolor(colors, alpha.f = alpha)
  }
  
  return(colors)
}

#' Get Contrasting Color Pairs
#'
#' Returns pairs of high-contrast colors suitable for foreground/background
#' or distinguishing adjacent shapes.
#'
#' @param n Number of color pairs to return (returns 2*n colors)
#' @return Character vector of hex color codes (alternating pairs)
#' @export
#' @examples
#' # Get 3 contrasting pairs (6 colors total)
#' pairs <- hough_palette_pairs(3)
hough_palette_pairs <- function(n) {
  if (n <= 0) {
    return(character(0))
  }
  
  # Define high-contrast pairs
  pairs <- list(
    c("#FF9F1C", "#0B0E14"),  # orange vs black
    c("#4CC9F0", "#1F2937"),  # bright blue vs dark slate
    c("#E4572E", "#FFFFFF"),  # red-orange vs white
    c("#2EC4B6", "#2E3440"),  # teal vs charcoal
    c("#FFD166", "#7209B7"),  # yellow vs deep purple
    c("#FF3C38", "#00B4D8"),  # red vs cyan
    c("#E9C46A", "#4895EF"),  # gold vs blue
    c("#B5179E", "#A8DADC"),  # magenta vs pale cyan
    c("#9D4EDD", "#F4D35E"),  # violet vs yellow-light
    c("#EAEAEA", "#2E3440")   # soft white vs charcoal
  )
  
  # Cycle through pairs if needed
  n_pairs <- min(n, length(pairs))
  if (n > length(pairs)) {
    pairs <- rep_len(pairs, n)
  }
  
  # Flatten pairs into vector
  result <- character(n * 2)
  for (i in 1:n) {
    result[(i-1)*2 + 1] <- pairs[[i]][1]
    result[(i-1)*2 + 2] <- pairs[[i]][2]
  }
  
  return(result)
}

#' Preview Hough Color Palettes
#'
#' Displays the color palettes as a simple bar chart for visualization
#'
#' @param n Number of colors to display (default 20)
#' @param type Palette type: "full", "contrast", or "gradient"
#' @return Invisibly returns the color vector
#' @export
#' @examples
#' \dontrun{
#' # Preview full palette
#' hough_palette_preview(20, "full")
#' 
#' # Preview contrast palette
#' hough_palette_preview(15, "contrast")
#' 
#' # Preview gradient
#' hough_palette_preview(30, "gradient")
#' }
hough_palette_preview <- function(n = 20, type = c("full", "contrast", "gradient")) {
  type <- match.arg(type)
  
  if (type == "gradient") {
    colors <- hough_palette_gradient(n)
  } else {
    colors <- hough_palette(n, type = type)
  }
  
  # Create simple bar chart
  graphics::par(mar = c(1, 1, 2, 1))
  graphics::barplot(
    rep(1, length(colors)),
    col = colors,
    border = NA,
    axes = FALSE,
    main = sprintf("Hough %s Palette (%d colors)", 
                   tools::toTitleCase(type), length(colors))
  )
  
  invisible(colors)
}
