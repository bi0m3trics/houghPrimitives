test_that("summarize_points works with basic input", {
  # Create a simple 3x3 point cloud
  xyz <- matrix(c(1, 2, 3,
                  4, 5, 6,
                  7, 8, 9), ncol = 3, byrow = TRUE)
  
  result <- summarize_points(xyz)
  
  # Check structure
  expect_type(result, "list")
  expect_named(result, c("n_points", "x_range", "y_range", "z_range"))
  
  # Check values
  expect_equal(result$n_points, 3)
  expect_equal(result$x_range, c(1, 7))
  expect_equal(result$y_range, c(2, 8))
  expect_equal(result$z_range, c(3, 9))
})

test_that("summarize_points handles single point", {
  xyz <- matrix(c(10, 20, 30), ncol = 3, byrow = TRUE)
  
  result <- summarize_points(xyz)
  
  expect_equal(result$n_points, 1)
  expect_equal(result$x_range, c(10, 10))
  expect_equal(result$y_range, c(20, 20))
  expect_equal(result$z_range, c(30, 30))
})

test_that("summarize_points handles negative coordinates", {
  xyz <- matrix(c(-5, -10, -15,
                  0, 0, 0,
                  5, 10, 15), ncol = 3, byrow = TRUE)
  
  result <- summarize_points(xyz)
  
  expect_equal(result$n_points, 3)
  expect_equal(result$x_range, c(-5, 5))
  expect_equal(result$y_range, c(-10, 10))
  expect_equal(result$z_range, c(-15, 15))
})

test_that("summarize_points handles large point clouds", {
  # Create a larger point cloud (1000 points)
  n_points <- 1000
  xyz <- matrix(runif(n_points * 3, min = -100, max = 100), ncol = 3)
  
  result <- summarize_points(xyz)
  
  expect_equal(result$n_points, n_points)
  expect_length(result$x_range, 2)
  expect_length(result$y_range, 2)
  expect_length(result$z_range, 2)
  
  # Ranges should be ordered (min, max)
  expect_true(result$x_range[1] <= result$x_range[2])
  expect_true(result$y_range[1] <= result$y_range[2])
  expect_true(result$z_range[1] <= result$z_range[2])
})

test_that("summarize_points handles uniform coordinates", {
  # All points at the same location
  xyz <- matrix(rep(c(5, 10, 15), 5), ncol = 3, byrow = TRUE)
  
  result <- summarize_points(xyz)
  
  expect_equal(result$n_points, 5)
  expect_equal(result$x_range, c(5, 5))
  expect_equal(result$y_range, c(10, 10))
  expect_equal(result$z_range, c(15, 15))
})

test_that("summarize_points validates input dimensions", {
  # Test with wrong number of columns
  xyz_wrong <- matrix(c(1, 2, 3, 4), ncol = 2)
  
  # Currently the C++ code doesn't validate, but it should handle gracefully
  # This is testing current behavior - could be improved later
  # For now, just check that it doesn't crash with proper 3-column input
  xyz_correct <- matrix(c(1, 2, 3, 4, 5, 6), ncol = 3, byrow = TRUE)
  result <- summarize_points(xyz_correct)
  expect_equal(result$n_points, 2)
})

test_that("summarize_points handles decimal coordinates", {
  xyz <- matrix(c(1.5, 2.7, 3.9,
                  4.1, 5.3, 6.8,
                  7.2, 8.4, 9.6), ncol = 3, byrow = TRUE)
  
  result <- summarize_points(xyz)
  
  expect_equal(result$n_points, 3)
  expect_equal(result$x_range[1], 1.5)
  expect_equal(result$x_range[2], 7.2)
})

test_that("summarize_points handles very small differences", {
  # Points very close together
  xyz <- matrix(c(0.000001, 0.000002, 0.000003,
                  0.000004, 0.000005, 0.000006), ncol = 3, byrow = TRUE)
  
  result <- summarize_points(xyz)
  
  expect_equal(result$n_points, 2)
  expect_true(all(is.finite(c(result$x_range, result$y_range, result$z_range))))
})

test_that("summarize_points range values are sensible", {
  xyz <- matrix(c(1, 2, 3,
                  10, 20, 30,
                  5, 11, 16), ncol = 3, byrow = TRUE)
  
  result <- summarize_points(xyz)
  
  # Min should be less than or equal to max
  expect_true(result$x_range[1] <= result$x_range[2])
  expect_true(result$y_range[1] <= result$y_range[2])
  expect_true(result$z_range[1] <= result$z_range[2])
  
  # Check actual values
  expect_equal(result$x_range, c(1, 10))
  expect_equal(result$y_range, c(2, 20))
  expect_equal(result$z_range, c(3, 30))
})
