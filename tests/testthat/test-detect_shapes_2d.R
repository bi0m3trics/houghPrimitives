test_that("detect_circles_2d returns correct structure with no detections", {
  # Too few points
  xy <- matrix(c(1, 2, 3, 4), ncol = 2)
  result <- detect_circles_2d(xy, min_votes = 10L)

  expect_type(result, "list")
  expect_equal(result$n_circles, 0)
  expect_s3_class(result$circles, "data.frame")
  expect_named(result$circles, c("circle_id", "x", "y", "radius", "n_points"))
})

test_that("detect_circles_2d detects a single circle", {
  set.seed(42)
  n <- 200
  theta <- seq(0, 2 * pi, length.out = n + 1)[-(n + 1)]
  cx <- 5
  cy <- 3
  r <- 2
  noise <- rnorm(n, 0, 0.02)
  xy <- cbind(cx + (r + noise) * cos(theta), cy + (r + noise) * sin(theta))

  result <- detect_circles_2d(xy, min_radius = 1, max_radius = 5,
                              distance_threshold = 0.15, min_votes = 50L)

  expect_equal(result$n_circles, 1)
  expect_equal(nrow(result$circles), 1)
  expect_true(abs(result$circles$x - cx) < 0.3)
  expect_true(abs(result$circles$y - cy) < 0.3)
  expect_true(abs(result$circles$radius - r) < 0.3)
  expect_true(result$circles$n_points >= 50)
})

test_that("detect_circles_2d label_points works", {
  set.seed(42)
  n <- 100
  theta <- seq(0, 2 * pi, length.out = n + 1)[-(n + 1)]
  xy <- cbind(2 * cos(theta), 2 * sin(theta))

  result <- detect_circles_2d(xy, min_radius = 1, max_radius = 5,
                              distance_threshold = 0.2, min_votes = 20L,
                              label_points = TRUE)

  expect_true("point_labels" %in% names(result))
  expect_length(result$point_labels, n)
  expect_true(all(result$point_labels >= 0))
})

test_that("detect_ellipses_2d returns correct structure with no detections", {
  xy <- matrix(c(1, 2, 3, 4, 5, 6), ncol = 2)
  result <- detect_ellipses_2d(xy, min_votes = 50L)

  expect_type(result, "list")
  expect_equal(result$n_ellipses, 0)
  expect_s3_class(result$ellipses, "data.frame")
  expect_named(result$ellipses,
               c("ellipse_id", "x", "y", "semi_major", "semi_minor", "angle", "n_points"))
})

test_that("detect_ellipses_2d detects a single ellipse", {
  set.seed(123)
  n <- 300
  theta <- seq(0, 2 * pi, length.out = n + 1)[-(n + 1)]
  cx <- 1
  cy <- 2
  a <- 4   # semi-major
  b <- 2   # semi-minor
  noise <- rnorm(n, 0, 0.02)
  xy <- cbind(cx + (a + noise) * cos(theta),
              cy + (b + noise) * sin(theta))

  result <- detect_ellipses_2d(xy, min_radius = 1, max_radius = 10,
                               distance_threshold = 0.2, min_votes = 50L,
                               max_iterations = 3000L)

  expect_equal(result$n_ellipses, 1)
  expect_equal(nrow(result$ellipses), 1)
  expect_true(abs(result$ellipses$x - cx) < 0.5)
  expect_true(abs(result$ellipses$y - cy) < 0.5)
  expect_true(result$ellipses$semi_major > result$ellipses$semi_minor)
  expect_true(result$ellipses$n_points >= 50)
})

test_that("detect_ellipses_2d label_points works", {
  set.seed(99)
  n <- 200
  theta <- seq(0, 2 * pi, length.out = n + 1)[-(n + 1)]
  xy <- cbind(3 * cos(theta), 1.5 * sin(theta))

  result <- detect_ellipses_2d(xy, min_radius = 0.5, max_radius = 10,
                               distance_threshold = 0.2, min_votes = 30L,
                               label_points = TRUE)

  expect_true("point_labels" %in% names(result))
  expect_length(result$point_labels, n)
})

test_that("detect_rectangles_2d returns correct structure with no detections", {
  xy <- matrix(c(1, 2, 3, 4), ncol = 2)
  result <- detect_rectangles_2d(xy, min_votes = 10L)

  expect_type(result, "list")
  expect_equal(result$n_rectangles, 0)
  expect_s3_class(result$rectangles, "data.frame")
  expect_named(result$rectangles,
               c("rectangle_id", "x", "y", "width", "height", "angle", "n_points"))
})

test_that("detect_rectangles_2d detects an axis-aligned rectangle", {
  set.seed(42)
  # Rectangle with corners at (0,0), (4,0), (4,2), (0,2)
  n_per_edge <- 50
  noise <- 0.02

  # Bottom edge: y ≈ 0, x in [0, 4]
  e1 <- cbind(seq(0, 4, length.out = n_per_edge),
              rnorm(n_per_edge, 0, noise))
  # Top edge: y ≈ 2, x in [0, 4]
  e2 <- cbind(seq(0, 4, length.out = n_per_edge),
              rnorm(n_per_edge, 2, noise))
  # Left edge: x ≈ 0, y in [0, 2]
  e3 <- cbind(rnorm(n_per_edge, 0, noise),
              seq(0, 2, length.out = n_per_edge))
  # Right edge: x ≈ 4, y in [0, 2]
  e4 <- cbind(rnorm(n_per_edge, 4, noise),
              seq(0, 2, length.out = n_per_edge))

  xy <- rbind(e1, e2, e3, e4)

  result <- detect_rectangles_2d(xy, min_width = 1, max_width = 10,
                                 distance_threshold = 0.15, min_votes = 30L)

  expect_equal(result$n_rectangles, 1)
  expect_true(abs(result$rectangles$x - 2) < 0.5)
  expect_true(abs(result$rectangles$y - 1) < 0.5)
  # Width and height should be approximately 2 and 4 (width <= height)
  expect_true(result$rectangles$width < result$rectangles$height ||
              abs(result$rectangles$width - result$rectangles$height) < 0.5)
  expect_true(result$rectangles$n_points >= 30)
})

test_that("detect_rectangles_2d label_points works", {
  set.seed(42)
  n <- 40
  e1 <- cbind(seq(0, 3, length.out = n), rep(0, n))
  e2 <- cbind(seq(0, 3, length.out = n), rep(2, n))
  e3 <- cbind(rep(0, n), seq(0, 2, length.out = n))
  e4 <- cbind(rep(3, n), seq(0, 2, length.out = n))
  xy <- rbind(e1, e2, e3, e4)

  result <- detect_rectangles_2d(xy, min_width = 1, max_width = 10,
                                 distance_threshold = 0.2, min_votes = 20L,
                                 label_points = TRUE)

  expect_true("point_labels" %in% names(result))
  expect_length(result$point_labels, nrow(xy))
})

test_that("detect_squares_2d returns correct structure with no detections", {
  xy <- matrix(c(1, 2, 3, 4), ncol = 2)
  result <- detect_squares_2d(xy, min_votes = 10L)

  expect_type(result, "list")
  expect_equal(result$n_squares, 0)
  expect_s3_class(result$squares, "data.frame")
  expect_named(result$squares,
               c("square_id", "x", "y", "size", "angle", "n_points"))
})

test_that("detect_squares_2d detects a square", {
  set.seed(42)
  n_per_edge <- 50
  noise <- 0.02
  s <- 3  # side length

  e1 <- cbind(seq(0, s, length.out = n_per_edge),
              rnorm(n_per_edge, 0, noise))
  e2 <- cbind(seq(0, s, length.out = n_per_edge),
              rnorm(n_per_edge, s, noise))
  e3 <- cbind(rnorm(n_per_edge, 0, noise),
              seq(0, s, length.out = n_per_edge))
  e4 <- cbind(rnorm(n_per_edge, s, noise),
              seq(0, s, length.out = n_per_edge))

  xy <- rbind(e1, e2, e3, e4)

  result <- detect_squares_2d(xy, min_size = 1, max_size = 10,
                              distance_threshold = 0.15, min_votes = 30L)

  expect_equal(result$n_squares, 1)
  expect_true(abs(result$squares$size - s) < 0.5)
  expect_true(abs(result$squares$x - s / 2) < 0.5)
  expect_true(abs(result$squares$y - s / 2) < 0.5)
  expect_true(result$squares$n_points >= 30)
})

test_that("detect_squares_2d rejects non-square rectangles", {
  set.seed(42)
  n_per_edge <- 30
  noise <- 0.02
  w <- 1
  h <- 8  # very different from w, and short edge too small to form a square subset

  e1 <- cbind(seq(0, w, length.out = n_per_edge),
              rnorm(n_per_edge, 0, noise))
  e2 <- cbind(seq(0, w, length.out = n_per_edge),
              rnorm(n_per_edge, h, noise))
  e3 <- cbind(rnorm(n_per_edge, 0, noise),
              seq(0, h, length.out = n_per_edge))
  e4 <- cbind(rnorm(n_per_edge, w, noise),
              seq(0, h, length.out = n_per_edge))

  xy <- rbind(e1, e2, e3, e4)

  result <- detect_squares_2d(xy, min_size = 0.5, max_size = 10,
                              distance_threshold = 0.15, min_votes = 60L)

  expect_equal(result$n_squares, 0)
})

test_that("detect_squares_2d label_points works", {
  set.seed(42)
  n <- 30
  s <- 3
  e1 <- cbind(seq(0, s, length.out = n), rep(0, n))
  e2 <- cbind(seq(0, s, length.out = n), rep(s, n))
  e3 <- cbind(rep(0, n), seq(0, s, length.out = n))
  e4 <- cbind(rep(s, n), seq(0, s, length.out = n))
  xy <- rbind(e1, e2, e3, e4)

  result <- detect_squares_2d(xy, min_size = 1, max_size = 10,
                              distance_threshold = 0.2, min_votes = 20L,
                              label_points = TRUE)

  expect_true("point_labels" %in% names(result))
  expect_length(result$point_labels, nrow(xy))
})
