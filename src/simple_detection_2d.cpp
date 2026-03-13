#include <Rcpp.h>
#include <cmath>
#include <vector>
#include <algorithm>
using namespace Rcpp;

// ===========================================================================
// Helper: Gaussian elimination with partial pivoting for nxn system
// Solves M*x = b in-place (solution returned in b)
// ===========================================================================
static bool gauss_solve(std::vector<std::vector<double>>& M,
                        std::vector<double>& b, int n) {
  for (int col = 0; col < n; col++) {
    // Partial pivoting
    int pivot = col;
    double max_val = fabs(M[col][col]);
    for (int row = col + 1; row < n; row++) {
      if (fabs(M[row][col]) > max_val) {
        max_val = fabs(M[row][col]);
        pivot = row;
      }
    }
    if (max_val < 1e-12) return false;

    if (pivot != col) {
      std::swap(M[pivot], M[col]);
      std::swap(b[pivot], b[col]);
    }

    // Forward elimination
    for (int row = col + 1; row < n; row++) {
      double factor = M[row][col] / M[col][col];
      for (int j = col; j < n; j++) {
        M[row][j] -= factor * M[col][j];
      }
      b[row] -= factor * b[col];
    }
  }

  // Back substitution
  for (int row = n - 1; row >= 0; row--) {
    for (int j = row + 1; j < n; j++) {
      b[row] -= M[row][j] * b[j];
    }
    if (fabs(M[row][row]) < 1e-12) return false;
    b[row] /= M[row][row];
  }

  return true;
}

// ===========================================================================
// Helper: Fit circumscribed circle through 3 points
// Returns false if points are (nearly) collinear
// ===========================================================================
static bool fit_circle_3pts(double x1, double y1,
                            double x2, double y2,
                            double x3, double y3,
                            double &cx, double &cy, double &r) {
  // Solve the 2x2 system from equidistance conditions:
  // 2(x2-x1)*cx + 2(y2-y1)*cy = x2^2+y2^2-x1^2-y1^2
  // 2(x3-x1)*cx + 2(y3-y1)*cy = x3^2+y3^2-x1^2-y1^2
  double a11 = 2 * (x2 - x1), a12 = 2 * (y2 - y1);
  double a21 = 2 * (x3 - x1), a22 = 2 * (y3 - y1);
  double b1 = x2*x2 + y2*y2 - x1*x1 - y1*y1;
  double b2 = x3*x3 + y3*y3 - x1*x1 - y1*y1;

  double det = a11 * a22 - a12 * a21;
  if (fabs(det) < 1e-10) return false;

  cx = (b1 * a22 - b2 * a12) / det;
  cy = (a11 * b2 - a21 * b1) / det;
  r = sqrt((cx - x1) * (cx - x1) + (cy - y1) * (cy - y1));

  return r > 1e-10;
}

// ===========================================================================
// detect_circles_2d
// ===========================================================================

//' Detect circles in 2D point data using RANSAC
//'
//' Uses a RANSAC approach with 3-point circumscribed circle fitting to detect
//' circular patterns in 2D point sets. Iteratively detects circles, removing
//' inlier points after each detection.
//'
//' @param xy A matrix with 2 columns (X, Y coordinates)
//' @param min_radius Minimum circle radius
//' @param max_radius Maximum circle radius
//' @param distance_threshold Maximum distance from circle boundary for inliers
//' @param min_votes Minimum number of points required to detect a circle
//' @param max_iterations Maximum RANSAC iterations per detection
//' @param label_points If TRUE, label all points with circle ID
//' @return A list with detected circles and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_circles_2d(NumericMatrix xy,
                       double min_radius = 0.1,
                       double max_radius = 10.0,
                       double distance_threshold = 0.1,
                       int min_votes = 20,
                       int max_iterations = 1000,
                       bool label_points = false) {

  int n_points = xy.nrow();

  if (n_points < min_votes || n_points < 3) {
    return List::create(
      Named("n_circles") = 0,
      Named("circles") = DataFrame::create(
        Named("circle_id") = IntegerVector(),
        Named("x") = NumericVector(),
        Named("y") = NumericVector(),
        Named("radius") = NumericVector(),
        Named("n_points") = IntegerVector()
      )
    );
  }

  std::vector<double> circ_x, circ_y, circ_r;
  std::vector<int> circ_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);

  int circle_id = 0;

  while (true) {
    int available = 0;
    for (int i = 0; i < n_points; i++) {
      if (!used[i]) available++;
    }
    if (available < min_votes) break;

    double best_cx = 0, best_cy = 0, best_r = 0;
    int best_inliers = 0;
    std::vector<int> best_inlier_indices;

    for (int iter = 0; iter < max_iterations; iter++) {
      // Sample 3 random unused points
      std::vector<int> samples;
      int attempts = 0;
      while ((int)samples.size() < 3 && attempts < 1000) {
        int idx = rand() % n_points;
        if (!used[idx] && std::find(samples.begin(), samples.end(), idx) == samples.end()) {
          samples.push_back(idx);
        }
        attempts++;
      }
      if ((int)samples.size() < 3) continue;

      double cx, cy, r;
      if (!fit_circle_3pts(
            xy(samples[0], 0), xy(samples[0], 1),
            xy(samples[1], 0), xy(samples[1], 1),
            xy(samples[2], 0), xy(samples[2], 1),
            cx, cy, r)) continue;

      if (r < min_radius || r > max_radius) continue;

      // Count inliers: points within distance_threshold of the circle boundary
      std::vector<int> inliers;
      for (int i = 0; i < n_points; i++) {
        if (used[i]) continue;
        double dx = xy(i, 0) - cx;
        double dy = xy(i, 1) - cy;
        double dist = fabs(sqrt(dx * dx + dy * dy) - r);
        if (dist < distance_threshold) {
          inliers.push_back(i);
        }
      }

      if ((int)inliers.size() > best_inliers) {
        best_inliers = inliers.size();
        best_cx = cx;
        best_cy = cy;
        best_r = r;
        best_inlier_indices = inliers;
      }
    }

    if (best_inliers < min_votes) break;

    // Refine center estimate using inlier points
    double sum_cx = 0, sum_cy = 0, sum_r = 0;
    int refine_count = 0;
    for (int idx : best_inlier_indices) {
      double dx = xy(idx, 0) - best_cx;
      double dy = xy(idx, 1) - best_cy;
      double dist = sqrt(dx * dx + dy * dy);
      if (dist > 1e-10) {
        sum_cx += xy(idx, 0) - best_r * dx / dist;
        sum_cy += xy(idx, 1) - best_r * dy / dist;
        refine_count++;
      }
      sum_r += dist;
    }

    double refined_cx = (refine_count > 0) ? sum_cx / refine_count : best_cx;
    double refined_cy = (refine_count > 0) ? sum_cy / refine_count : best_cy;
    double refined_r = sum_r / best_inlier_indices.size();

    // Recount inliers with refined parameters
    std::vector<int> final_inliers;
    for (int i = 0; i < n_points; i++) {
      if (used[i]) continue;
      double dx = xy(i, 0) - refined_cx;
      double dy = xy(i, 1) - refined_cy;
      double dist = fabs(sqrt(dx * dx + dy * dy) - refined_r);
      if (dist < distance_threshold) {
        final_inliers.push_back(i);
      }
    }

    if ((int)final_inliers.size() < min_votes) break;

    // Mark points as used
    for (int idx : final_inliers) {
      used[idx] = true;
      if (label_points) point_labels[idx] = circle_id + 1;
    }

    circle_id++;
    circ_x.push_back(refined_cx);
    circ_y.push_back(refined_cy);
    circ_r.push_back(refined_r);
    circ_votes.push_back(final_inliers.size());
  }

  // Build results
  DataFrame circles;
  if (circle_id > 0) {
    circles = DataFrame::create(
      Named("circle_id") = seq(1, circle_id),
      Named("x") = circ_x,
      Named("y") = circ_y,
      Named("radius") = circ_r,
      Named("n_points") = circ_votes
    );
  } else {
    circles = DataFrame::create(
      Named("circle_id") = IntegerVector(),
      Named("x") = NumericVector(),
      Named("y") = NumericVector(),
      Named("radius") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }

  List result = List::create(
    Named("n_circles") = circle_id,
    Named("circles") = circles
  );

  if (label_points) {
    result["point_labels"] = point_labels;
  }

  return result;
}

// ===========================================================================
// detect_ellipses_2d
// ===========================================================================

//' Detect ellipses in 2D point data using RANSAC
//'
//' Uses RANSAC with 5-point algebraic conic fitting and Sampson distance
//' for inlier evaluation. Iteratively detects ellipses, removing inlier
//' points after each detection.
//'
//' @param xy A matrix with 2 columns (X, Y coordinates)
//' @param min_radius Minimum semi-minor axis length
//' @param max_radius Maximum semi-major axis length
//' @param distance_threshold Maximum approximate distance from ellipse for inliers
//' @param min_votes Minimum number of points required to detect an ellipse
//' @param max_iterations Maximum RANSAC iterations per detection
//' @param label_points If TRUE, label all points with ellipse ID
//' @return A list with detected ellipses and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_ellipses_2d(NumericMatrix xy,
                        double min_radius = 0.1,
                        double max_radius = 10.0,
                        double distance_threshold = 0.1,
                        int min_votes = 30,
                        int max_iterations = 2000,
                        bool label_points = false) {

  int n_points = xy.nrow();

  if (n_points < min_votes || n_points < 5) {
    return List::create(
      Named("n_ellipses") = 0,
      Named("ellipses") = DataFrame::create(
        Named("ellipse_id") = IntegerVector(),
        Named("x") = NumericVector(),
        Named("y") = NumericVector(),
        Named("semi_major") = NumericVector(),
        Named("semi_minor") = NumericVector(),
        Named("angle") = NumericVector(),
        Named("n_points") = IntegerVector()
      )
    );
  }

  std::vector<double> ell_x, ell_y, ell_a, ell_b, ell_angle;
  std::vector<int> ell_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);

  int ellipse_id = 0;

  while (true) {
    int available = 0;
    for (int i = 0; i < n_points; i++) {
      if (!used[i]) available++;
    }
    if (available < min_votes) break;

    int best_inliers = 0;
    std::vector<int> best_inlier_indices;
    double best_cx = 0, best_cy = 0, best_a = 0, best_b = 0, best_angle = 0;

    for (int iter = 0; iter < max_iterations; iter++) {
      // Sample 5 random unused points
      std::vector<int> samples;
      int attempts = 0;
      while ((int)samples.size() < 5 && attempts < 2000) {
        int idx = rand() % n_points;
        if (!used[idx] && std::find(samples.begin(), samples.end(), idx) == samples.end()) {
          samples.push_back(idx);
        }
        attempts++;
      }
      if ((int)samples.size() < 5) continue;

      // Fit general conic: Ax^2 + Bxy + Cy^2 + Dx + Ey + F = 0
      // Normalize with F = 1: Ax^2 + Bxy + Cy^2 + Dx + Ey = -1
      std::vector<std::vector<double>> M(5, std::vector<double>(5));
      std::vector<double> rhs(5, -1.0);

      for (int i = 0; i < 5; i++) {
        double x = xy(samples[i], 0);
        double y = xy(samples[i], 1);
        M[i][0] = x * x;
        M[i][1] = x * y;
        M[i][2] = y * y;
        M[i][3] = x;
        M[i][4] = y;
      }

      if (!gauss_solve(M, rhs, 5)) continue;

      double A = rhs[0], B = rhs[1], C = rhs[2], D = rhs[3], E = rhs[4];
      double F = 1.0;

      // Ellipse condition: 4AC - B^2 > 0
      double disc = 4 * A * C - B * B;
      if (disc <= 1e-10) continue;

      // Compute center
      double cx = (B * E - 2 * C * D) / disc;
      double cy = (B * D - 2 * A * E) / disc;

      // Evaluate conic at center
      double F_prime = A * cx * cx + B * cx * cy + C * cy * cy +
                       D * cx + E * cy + F;

      // Eigenvalues of quadratic form matrix [[A, B/2], [B/2, C]]
      double trace = A + C;
      double diff = A - C;
      double delta = sqrt(std::max(0.0, diff * diff + B * B));
      double lam1 = (trace + delta) / 2;  // larger eigenvalue
      double lam2 = (trace - delta) / 2;  // smaller eigenvalue

      // For a valid ellipse: -F'/lambda must be positive for both
      if (F_prime * lam1 >= 0 || F_prime * lam2 >= 0) continue;
      if (fabs(lam1) < 1e-12 || fabs(lam2) < 1e-12) continue;

      double semi1 = sqrt(-F_prime / lam1);
      double semi2 = sqrt(-F_prime / lam2);

      double semi_major = std::max(semi1, semi2);
      double semi_minor = std::min(semi1, semi2);

      if (semi_minor < min_radius || semi_major > max_radius) continue;
      if (semi_minor < 1e-6) continue;

      // Rotation angle of the semi-major axis
      double angle;
      if (fabs(B) < 1e-10) {
        angle = (A <= C) ? 0.0 : M_PI / 2;
      } else {
        // Semi-major corresponds to smaller eigenvalue (lam2)
        // Eigenvector for lam2: proportional to (B/2, lam2-A)
        angle = atan2(lam2 - A, B / 2.0);
      }
      // Normalize angle to [0, pi)
      while (angle < 0) angle += M_PI;
      while (angle >= M_PI) angle -= M_PI;

      // Count inliers using Sampson distance approximation
      std::vector<int> inliers;
      for (int i = 0; i < n_points; i++) {
        if (used[i]) continue;
        double x = xy(i, 0), y = xy(i, 1);

        double f_val = A * x * x + B * x * y + C * y * y + D * x + E * y + F;
        double fx = 2 * A * x + B * y + D;
        double fy = B * x + 2 * C * y + E;
        double grad_sq = fx * fx + fy * fy;

        double sampson_dist = (grad_sq > 1e-12) ? fabs(f_val) / sqrt(grad_sq) : 1e10;

        if (sampson_dist < distance_threshold) {
          inliers.push_back(i);
        }
      }

      if ((int)inliers.size() > best_inliers) {
        best_inliers = inliers.size();
        best_inlier_indices = inliers;
        best_cx = cx;
        best_cy = cy;
        best_a = semi_major;
        best_b = semi_minor;
        best_angle = angle;
      }
    }

    if (best_inliers < min_votes) break;

    // Mark points as used
    for (int idx : best_inlier_indices) {
      used[idx] = true;
      if (label_points) point_labels[idx] = ellipse_id + 1;
    }

    ellipse_id++;
    ell_x.push_back(best_cx);
    ell_y.push_back(best_cy);
    ell_a.push_back(best_a);
    ell_b.push_back(best_b);
    ell_angle.push_back(best_angle);
    ell_votes.push_back(best_inliers);
  }

  // Build results
  DataFrame ellipses;
  if (ellipse_id > 0) {
    ellipses = DataFrame::create(
      Named("ellipse_id") = seq(1, ellipse_id),
      Named("x") = ell_x,
      Named("y") = ell_y,
      Named("semi_major") = ell_a,
      Named("semi_minor") = ell_b,
      Named("angle") = ell_angle,
      Named("n_points") = ell_votes
    );
  } else {
    ellipses = DataFrame::create(
      Named("ellipse_id") = IntegerVector(),
      Named("x") = NumericVector(),
      Named("y") = NumericVector(),
      Named("semi_major") = NumericVector(),
      Named("semi_minor") = NumericVector(),
      Named("angle") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }

  List result = List::create(
    Named("n_ellipses") = ellipse_id,
    Named("ellipses") = ellipses
  );

  if (label_points) {
    result["point_labels"] = point_labels;
  }

  return result;
}

// ===========================================================================
// detect_rectangles_2d
// ===========================================================================

//' Detect rectangles in 2D point data using RANSAC
//'
//' Uses a RANSAC approach to detect rectangular patterns in 2D point sets.
//' Samples 3 points to define edge direction and width, then validates by
//' counting inliers along all 4 edges. Iteratively detects rectangles,
//' removing inlier points after each detection.
//'
//' @param xy A matrix with 2 columns (X, Y coordinates)
//' @param min_width Minimum rectangle dimension (applies to both width and height)
//' @param max_width Maximum rectangle dimension (applies to both width and height)
//' @param distance_threshold Maximum distance from rectangle edge for inliers
//' @param min_votes Minimum number of points required to detect a rectangle
//' @param max_iterations Maximum RANSAC iterations per detection
//' @param label_points If TRUE, label all points with rectangle ID
//' @return A list with detected rectangles and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_rectangles_2d(NumericMatrix xy,
                          double min_width = 0.5,
                          double max_width = 10.0,
                          double distance_threshold = 0.1,
                          int min_votes = 20,
                          int max_iterations = 1000,
                          bool label_points = false) {

  int n_points = xy.nrow();

  if (n_points < min_votes || n_points < 3) {
    return List::create(
      Named("n_rectangles") = 0,
      Named("rectangles") = DataFrame::create(
        Named("rectangle_id") = IntegerVector(),
        Named("x") = NumericVector(),
        Named("y") = NumericVector(),
        Named("width") = NumericVector(),
        Named("height") = NumericVector(),
        Named("angle") = NumericVector(),
        Named("n_points") = IntegerVector()
      )
    );
  }

  std::vector<double> rect_x, rect_y, rect_w, rect_h, rect_angle;
  std::vector<int> rect_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);

  int rect_id = 0;

  while (true) {
    int available = 0;
    for (int i = 0; i < n_points; i++) {
      if (!used[i]) available++;
    }
    if (available < min_votes) break;

    int best_inliers = 0;
    std::vector<int> best_inlier_indices;
    double best_cx = 0, best_cy = 0, best_w = 0, best_h = 0, best_angle = 0;

    for (int iter = 0; iter < max_iterations; iter++) {
      // Sample 3 random unused points
      std::vector<int> samples;
      int attempts = 0;
      while ((int)samples.size() < 3 && attempts < 1000) {
        int idx = rand() % n_points;
        if (!used[idx] && std::find(samples.begin(), samples.end(), idx) == samples.end()) {
          samples.push_back(idx);
        }
        attempts++;
      }
      if ((int)samples.size() < 3) continue;

      // p1-p2 define edge direction
      double dx = xy(samples[1], 0) - xy(samples[0], 0);
      double dy = xy(samples[1], 1) - xy(samples[0], 1);
      double edge_len = sqrt(dx * dx + dy * dy);
      if (edge_len < 1e-6) continue;

      // Edge direction and perpendicular
      double ex = dx / edge_len, ey = dy / edge_len;
      double nx = -ey, ny = ex;

      // p3 defines the width (perpendicular distance from line through p1-p2)
      double p3_dx = xy(samples[2], 0) - xy(samples[0], 0);
      double p3_dy = xy(samples[2], 1) - xy(samples[0], 1);
      double w = p3_dx * nx + p3_dy * ny;  // signed perpendicular distance

      if (fabs(w) < min_width || fabs(w) > max_width) continue;

      // Project all unused points into the (edge, normal) coordinate system
      // relative to p1
      double ref_x = xy(samples[0], 0);
      double ref_y = xy(samples[0], 1);

      // First pass: find parallel edge inliers and compute edge extents
      std::vector<double> t_vals, s_vals;
      std::vector<int> avail_indices;

      for (int i = 0; i < n_points; i++) {
        if (used[i]) continue;
        double px = xy(i, 0) - ref_x;
        double py = xy(i, 1) - ref_y;
        double t = px * ex + py * ey;   // along-edge projection
        double s = px * nx + py * ny;   // cross-edge projection
        t_vals.push_back(t);
        s_vals.push_back(s);
        avail_indices.push_back(i);
      }

      // Edge 1: s ≈ 0, Edge 2: s ≈ w
      // Find t_min and t_max from points on edge 1 and edge 2
      double t_min = 1e10, t_max = -1e10;
      int edge12_count = 0;
      for (int k = 0; k < (int)avail_indices.size(); k++) {
        if (fabs(s_vals[k]) < distance_threshold ||
            fabs(s_vals[k] - w) < distance_threshold) {
          if (t_vals[k] < t_min) t_min = t_vals[k];
          if (t_vals[k] > t_max) t_max = t_vals[k];
          edge12_count++;
        }
      }

      if (edge12_count < 4) continue;
      double length = t_max - t_min;
      if (length < min_width || length > max_width) continue;

      // Define perpendicular edge boundaries
      double s_lo = std::min(0.0, w);
      double s_hi = std::max(0.0, w);

      // Count all inliers on 4 edges
      std::vector<int> inliers;
      for (int k = 0; k < (int)avail_indices.size(); k++) {
        double t = t_vals[k], s = s_vals[k];

        bool on_edge1 = (fabs(s) < distance_threshold) &&
                        (t >= t_min - distance_threshold) &&
                        (t <= t_max + distance_threshold);
        bool on_edge2 = (fabs(s - w) < distance_threshold) &&
                        (t >= t_min - distance_threshold) &&
                        (t <= t_max + distance_threshold);
        bool on_edge3 = (fabs(t - t_min) < distance_threshold) &&
                        (s >= s_lo - distance_threshold) &&
                        (s <= s_hi + distance_threshold);
        bool on_edge4 = (fabs(t - t_max) < distance_threshold) &&
                        (s >= s_lo - distance_threshold) &&
                        (s <= s_hi + distance_threshold);

        if (on_edge1 || on_edge2 || on_edge3 || on_edge4) {
          inliers.push_back(avail_indices[k]);
        }
      }

      if ((int)inliers.size() > best_inliers) {
        best_inliers = inliers.size();
        best_inlier_indices = inliers;

        // Compute rectangle center in original coordinates
        double center_t = (t_min + t_max) / 2.0;
        double center_s = w / 2.0;
        best_cx = ref_x + center_t * ex + center_s * nx;
        best_cy = ref_y + center_t * ey + center_s * ny;

        // Ensure width <= height
        double dim1 = fabs(w);
        double dim2 = length;
        if (dim1 <= dim2) {
          best_w = dim1;
          best_h = dim2;
          best_angle = atan2(ey, ex);
        } else {
          best_w = dim2;
          best_h = dim1;
          best_angle = atan2(ny, nx);
        }
        // Normalize angle to [0, pi)
        while (best_angle < 0) best_angle += M_PI;
        while (best_angle >= M_PI) best_angle -= M_PI;
      }
    }

    if (best_inliers < min_votes) break;

    // Mark points as used
    for (int idx : best_inlier_indices) {
      used[idx] = true;
      if (label_points) point_labels[idx] = rect_id + 1;
    }

    rect_id++;
    rect_x.push_back(best_cx);
    rect_y.push_back(best_cy);
    rect_w.push_back(best_w);
    rect_h.push_back(best_h);
    rect_angle.push_back(best_angle);
    rect_votes.push_back(best_inliers);
  }

  // Build results
  DataFrame rectangles;
  if (rect_id > 0) {
    rectangles = DataFrame::create(
      Named("rectangle_id") = seq(1, rect_id),
      Named("x") = rect_x,
      Named("y") = rect_y,
      Named("width") = rect_w,
      Named("height") = rect_h,
      Named("angle") = rect_angle,
      Named("n_points") = rect_votes
    );
  } else {
    rectangles = DataFrame::create(
      Named("rectangle_id") = IntegerVector(),
      Named("x") = NumericVector(),
      Named("y") = NumericVector(),
      Named("width") = NumericVector(),
      Named("height") = NumericVector(),
      Named("angle") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }

  List result = List::create(
    Named("n_rectangles") = rect_id,
    Named("rectangles") = rectangles
  );

  if (label_points) {
    result["point_labels"] = point_labels;
  }

  return result;
}

// ===========================================================================
// detect_squares_2d
// ===========================================================================

//' Detect squares in 2D point data using RANSAC
//'
//' Uses the same approach as rectangle detection but with an additional
//' constraint that width and height must be approximately equal (within
//' 15\% tolerance). Iteratively detects squares, removing inlier points
//' after each detection.
//'
//' @param xy A matrix with 2 columns (X, Y coordinates)
//' @param min_size Minimum square side length
//' @param max_size Maximum square side length
//' @param distance_threshold Maximum distance from square edge for inliers
//' @param min_votes Minimum number of points required to detect a square
//' @param max_iterations Maximum RANSAC iterations per detection
//' @param label_points If TRUE, label all points with square ID
//' @return A list with detected squares and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_squares_2d(NumericMatrix xy,
                       double min_size = 0.5,
                       double max_size = 10.0,
                       double distance_threshold = 0.1,
                       int min_votes = 20,
                       int max_iterations = 1000,
                       bool label_points = false) {

  int n_points = xy.nrow();

  if (n_points < min_votes || n_points < 3) {
    return List::create(
      Named("n_squares") = 0,
      Named("squares") = DataFrame::create(
        Named("square_id") = IntegerVector(),
        Named("x") = NumericVector(),
        Named("y") = NumericVector(),
        Named("size") = NumericVector(),
        Named("angle") = NumericVector(),
        Named("n_points") = IntegerVector()
      )
    );
  }

  std::vector<double> sq_x, sq_y, sq_size, sq_angle;
  std::vector<int> sq_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);

  int square_id = 0;

  while (true) {
    int available = 0;
    for (int i = 0; i < n_points; i++) {
      if (!used[i]) available++;
    }
    if (available < min_votes) break;

    int best_inliers = 0;
    std::vector<int> best_inlier_indices;
    double best_cx = 0, best_cy = 0, best_size = 0, best_angle = 0;

    for (int iter = 0; iter < max_iterations; iter++) {
      // Sample 3 random unused points
      std::vector<int> samples;
      int attempts = 0;
      while ((int)samples.size() < 3 && attempts < 1000) {
        int idx = rand() % n_points;
        if (!used[idx] && std::find(samples.begin(), samples.end(), idx) == samples.end()) {
          samples.push_back(idx);
        }
        attempts++;
      }
      if ((int)samples.size() < 3) continue;

      // p1-p2 define edge direction
      double dx = xy(samples[1], 0) - xy(samples[0], 0);
      double dy = xy(samples[1], 1) - xy(samples[0], 1);
      double edge_len = sqrt(dx * dx + dy * dy);
      if (edge_len < 1e-6) continue;

      double ex = dx / edge_len, ey = dy / edge_len;
      double nx_dir = -ey, ny_dir = ex;

      // p3 defines the width
      double p3_dx = xy(samples[2], 0) - xy(samples[0], 0);
      double p3_dy = xy(samples[2], 1) - xy(samples[0], 1);
      double w = p3_dx * nx_dir + p3_dy * ny_dir;

      if (fabs(w) < min_size || fabs(w) > max_size) continue;

      // Project all unused points
      double ref_x = xy(samples[0], 0);
      double ref_y = xy(samples[0], 1);

      std::vector<double> t_vals, s_vals;
      std::vector<int> avail_indices;

      for (int i = 0; i < n_points; i++) {
        if (used[i]) continue;
        double px = xy(i, 0) - ref_x;
        double py = xy(i, 1) - ref_y;
        t_vals.push_back(px * ex + py * ey);
        s_vals.push_back(px * nx_dir + py * ny_dir);
        avail_indices.push_back(i);
      }

      // Find t extent from parallel edge inliers
      double t_min = 1e10, t_max = -1e10;
      int edge12_count = 0;
      for (int k = 0; k < (int)avail_indices.size(); k++) {
        if (fabs(s_vals[k]) < distance_threshold ||
            fabs(s_vals[k] - w) < distance_threshold) {
          if (t_vals[k] < t_min) t_min = t_vals[k];
          if (t_vals[k] > t_max) t_max = t_vals[k];
          edge12_count++;
        }
      }

      if (edge12_count < 4) continue;
      double length = t_max - t_min;
      if (length < min_size || length > max_size) continue;

      // Square constraint: width ≈ height (15% tolerance)
      double dim1 = fabs(w), dim2 = length;
      double max_dim = std::max(dim1, dim2);
      if (max_dim < 1e-6) continue;
      if (fabs(dim1 - dim2) > 0.15 * max_dim) continue;

      double s_lo = std::min(0.0, w);
      double s_hi = std::max(0.0, w);

      // Count inliers on 4 edges
      std::vector<int> inliers;
      for (int k = 0; k < (int)avail_indices.size(); k++) {
        double t = t_vals[k], s = s_vals[k];

        bool on_edge1 = (fabs(s) < distance_threshold) &&
                        (t >= t_min - distance_threshold) &&
                        (t <= t_max + distance_threshold);
        bool on_edge2 = (fabs(s - w) < distance_threshold) &&
                        (t >= t_min - distance_threshold) &&
                        (t <= t_max + distance_threshold);
        bool on_edge3 = (fabs(t - t_min) < distance_threshold) &&
                        (s >= s_lo - distance_threshold) &&
                        (s <= s_hi + distance_threshold);
        bool on_edge4 = (fabs(t - t_max) < distance_threshold) &&
                        (s >= s_lo - distance_threshold) &&
                        (s <= s_hi + distance_threshold);

        if (on_edge1 || on_edge2 || on_edge3 || on_edge4) {
          inliers.push_back(avail_indices[k]);
        }
      }

      if ((int)inliers.size() > best_inliers) {
        best_inliers = inliers.size();
        best_inlier_indices = inliers;

        double center_t = (t_min + t_max) / 2.0;
        double center_s = w / 2.0;
        best_cx = ref_x + center_t * ex + center_s * nx_dir;
        best_cy = ref_y + center_t * ey + center_s * ny_dir;
        best_size = (dim1 + dim2) / 2.0;  // average of both dimensions
        best_angle = atan2(ey, ex);
        while (best_angle < 0) best_angle += M_PI;
        while (best_angle >= M_PI) best_angle -= M_PI;
      }
    }

    if (best_inliers < min_votes) break;

    // Mark points as used
    for (int idx : best_inlier_indices) {
      used[idx] = true;
      if (label_points) point_labels[idx] = square_id + 1;
    }

    square_id++;
    sq_x.push_back(best_cx);
    sq_y.push_back(best_cy);
    sq_size.push_back(best_size);
    sq_angle.push_back(best_angle);
    sq_votes.push_back(best_inliers);
  }

  // Build results
  DataFrame squares;
  if (square_id > 0) {
    squares = DataFrame::create(
      Named("square_id") = seq(1, square_id),
      Named("x") = sq_x,
      Named("y") = sq_y,
      Named("size") = sq_size,
      Named("angle") = sq_angle,
      Named("n_points") = sq_votes
    );
  } else {
    squares = DataFrame::create(
      Named("square_id") = IntegerVector(),
      Named("x") = NumericVector(),
      Named("y") = NumericVector(),
      Named("size") = NumericVector(),
      Named("angle") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }

  List result = List::create(
    Named("n_squares") = square_id,
    Named("squares") = squares
  );

  if (label_points) {
    result["point_labels"] = point_labels;
  }

  return result;
}
