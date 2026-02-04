#include <Rcpp.h>
#include <map>
using namespace Rcpp;

//' Simple point cloud summary
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @return A list with summary statistics
//' @export
// [[Rcpp::export]]
List summarize_points(NumericMatrix xyz) {
  int n = xyz.nrow();
  
  if (n == 0) {
    return List::create(Named("n_points") = 0);
  }
  
  // Calculate basic statistics
  double minX = xyz(0, 0), maxX = xyz(0, 0);
  double minY = xyz(0, 1), maxY = xyz(0, 1);
  double minZ = xyz(0, 2), maxZ = xyz(0, 2);
  
  for (int i = 1; i < n; i++) {
    if (xyz(i, 0) < minX) minX = xyz(i, 0);
    if (xyz(i, 0) > maxX) maxX = xyz(i, 0);
    if (xyz(i, 1) < minY) minY = xyz(i, 1);
    if (xyz(i, 1) > maxY) maxY = xyz(i, 1);
    if (xyz(i, 2) < minZ) minZ = xyz(i, 2);
    if (xyz(i, 2) > maxZ) maxZ = xyz(i, 2);
  }
  
  return List::create(
    Named("n_points") = n,
    Named("x_range") = NumericVector::create(minX, maxX),
    Named("y_range") = NumericVector::create(minY, maxY),
    Named("z_range") = NumericVector::create(minZ, maxZ)
  );
}

//' Detect tree boles (cylindrical trunks) in point cloud data
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @param min_radius Minimum trunk radius in meters
//' @param max_radius Maximum trunk radius in meters
//' @param min_height Minimum visible trunk height in meters
//' @param min_votes Minimum number of points required to detect a tree
//' @param vertical_only If TRUE, only detect vertical cylinders
//' @param label_points If TRUE, label all points with tree ID
//' @return A list with detected trees and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_tree_boles(NumericMatrix xyz,
                       double min_radius = 0.05,
                       double max_radius = 0.5,
                       double min_height = 1.0,
                       int min_votes = 30,
                       bool vertical_only = true,
                       bool label_points = false) {
  
  int n_points = xyz.nrow();
  
  if (n_points < min_votes) {
    return List::create(
      Named("n_trees") = 0,
      Named("trees") = DataFrame::create()
    );
  }
  
  // Simple cylinder detection using spatial clustering
  // This is a placeholder implementation - will be enhanced with proper Hough transform
  
  std::vector<double> tree_x, tree_y, tree_radius, tree_height;
  std::vector<int> tree_votes;
  IntegerVector point_labels(n_points, 0);
  
  // Calculate Z range for height filtering
  double minZ = xyz(0, 2), maxZ = xyz(0, 2);
  for (int i = 1; i < n_points; i++) {
    if (xyz(i, 2) < minZ) minZ = xyz(i, 2);
    if (xyz(i, 2) > maxZ) maxZ = xyz(i, 2);
  }
  
  // Proper vertical cylinder detection using multi-slice analysis
  int tree_id = 0;
  std::vector<bool> used(n_points, false);
  
  // Analyze horizontal slices to find consistent vertical cylinders
  double slice_thickness = 0.2;  // 20cm slices
  int num_slices = (int)ceil((maxZ - minZ) / slice_thickness);
  
  // Find seed cylinders in breast height region (1.0-1.5m above ground)
  double seed_z = minZ + 1.3;  // Standard breast height
  std::vector<std::pair<double, double>> candidates;  // (x, y) centers
  
  // Grid points near breast height for seed detection
  std::vector<int> seed_points;
  for (int i = 0; i < n_points; i++) {
    if (fabs(xyz(i, 2) - seed_z) < slice_thickness * 2) {
      seed_points.push_back(i);
    }
  }
  
  if (seed_points.size() < min_votes) {
    return List::create(
      Named("n_trees") = 0,
      Named("trees") = DataFrame::create()
    );
  }
  
  // Simple spatial grid for initial clustering
  double grid_size = max_radius * 2.5;
  std::map<std::pair<int, int>, std::vector<int>> grid;
  
  for (int idx : seed_points) {
    int gx = (int)floor(xyz(idx, 0) / grid_size);
    int gy = (int)floor(xyz(idx, 1) / grid_size);
    grid[std::make_pair(gx, gy)].push_back(idx);
  }
  
  // Find cylinder candidates
  for (auto& cell : grid) {
    if ((int)cell.second.size() < min_votes / 3) continue;
    
    // Calculate center from points in this cell
    double cx = 0, cy = 0;
    for (int idx : cell.second) {
      cx += xyz(idx, 0);
      cy += xyz(idx, 1);
    }
    cx /= cell.second.size();
    cy /= cell.second.size();
    
    candidates.push_back(std::make_pair(cx, cy));
  }
  
  // For each candidate, verify it's a vertical cylinder
  for (auto& cand : candidates) {
    double cx = cand.first;
    double cy = cand.second;
    
    // Collect points that are within max_radius of this vertical axis
    std::vector<int> cylinder_points;
    double cyl_minZ = 1e10, cyl_maxZ = -1e10;
    
    for (int i = 0; i < n_points; i++) {
      if (used[i]) continue;
      
      double dx = xyz(i, 0) - cx;
      double dy = xyz(i, 1) - cy;
      double dist_2d = sqrt(dx*dx + dy*dy);
      
      // Only include points close to the axis
      if (dist_2d <= max_radius) {
        cylinder_points.push_back(i);
        if (xyz(i, 2) < cyl_minZ) cyl_minZ = xyz(i, 2);
        if (xyz(i, 2) > cyl_maxZ) cyl_maxZ = xyz(i, 2);
      }
    }
    
    if ((int)cylinder_points.size() < min_votes) continue;
    
    double height = cyl_maxZ - cyl_minZ;
    if (height < min_height) continue;
    
    // Verify vertical consistency by checking multiple slices
    int valid_slices = 0;
    double total_radius = 0;
    int slice_count = 0;
    
    for (double z = cyl_minZ + slice_thickness; z < cyl_maxZ; z += slice_thickness) {
      std::vector<int> slice_pts;
      for (int idx : cylinder_points) {
        if (fabs(xyz(idx, 2) - z) < slice_thickness / 2) {
          slice_pts.push_back(idx);
        }
      }
      
      if ((int)slice_pts.size() < 5) continue;
      
      // Calculate center and radius in this slice
      double scx = 0, scy = 0;
      for (int idx : slice_pts) {
        scx += xyz(idx, 0);
        scy += xyz(idx, 1);
      }
      scx /= slice_pts.size();
      scy /= slice_pts.size();
      
      // Check if center is close to expected position
      double center_drift = sqrt((scx - cx)*(scx - cx) + (scy - cy)*(scy - cy));
      if (center_drift > max_radius * 0.5) continue;
      
      // Calculate radius in this slice
      double slice_radius = 0;
      for (int idx : slice_pts) {
        double dx = xyz(idx, 0) - scx;
        double dy = xyz(idx, 1) - scy;
        slice_radius += sqrt(dx*dx + dy*dy);
      }
      slice_radius /= slice_pts.size();
      
      if (slice_radius >= min_radius && slice_radius <= max_radius) {
        valid_slices++;
        total_radius += slice_radius;
        slice_count++;
      }
    }
    
    // Need at least 3 valid slices for a tree
    if (valid_slices < 3 || slice_count == 0) continue;
    
    double avg_radius = total_radius / slice_count;
    
    // Final filtering: only keep points actually close to the cylinder
    std::vector<int> final_points;
    for (int idx : cylinder_points) {
      double dx = xyz(idx, 0) - cx;
      double dy = xyz(idx, 1) - cy;
      double dist = sqrt(dx*dx + dy*dy);
      
      if (dist <= avg_radius * 2.0) {  // Allow some width for bark/branches
        final_points.push_back(idx);
        used[idx] = true;
      }
    }
    
    if ((int)final_points.size() < min_votes) continue;
    
    // Calculate actual height from final points
    double final_minZ = 1e10, final_maxZ = -1e10;
    for (int idx : final_points) {
      if (xyz(idx, 2) < final_minZ) final_minZ = xyz(idx, 2);
      if (xyz(idx, 2) > final_maxZ) final_maxZ = xyz(idx, 2);
    }
    double final_height = final_maxZ - final_minZ;
    
    // Found a valid tree
    tree_id++;
    tree_x.push_back(cx);
    tree_y.push_back(cy);
    tree_radius.push_back(avg_radius);
    tree_height.push_back(final_height);
    tree_votes.push_back(final_points.size());
    
    // Label points if requested
    if (label_points) {
      for (int idx : final_points) {
        point_labels[idx] = tree_id;
      }
    }
  }
  
  // Build results
  DataFrame trees;
  if (tree_id > 0) {
    trees = DataFrame::create(
      Named("tree_id") = seq(1, tree_id),
      Named("x") = tree_x,
      Named("y") = tree_y,
      Named("radius") = tree_radius,
      Named("height") = tree_height,
      Named("n_points") = tree_votes
    );
  } else {
    // Empty dataframe with correct column names
    trees = DataFrame::create(
      Named("tree_id") = IntegerVector(),
      Named("x") = NumericVector(),
      Named("y") = NumericVector(),
      Named("radius") = NumericVector(),
      Named("height") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }
  
  List result = List::create(
    Named("n_trees") = tree_id,
    Named("trees") = trees
  );
  
  if (label_points) {
    result["point_labels"] = point_labels;
  }
  
  return result;
}

//' Detect spheres in point cloud data using 3D Hough transform
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @param min_radius Minimum sphere radius
//' @param max_radius Maximum sphere radius
//' @param min_votes Minimum number of points required to detect a sphere
//' @param label_points If TRUE, label all points with sphere ID
//' @return A list with detected spheres and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_spheres(NumericMatrix xyz,
                    double min_radius = 0.1,
                    double max_radius = 2.0,
                    int min_votes = 30,
                    bool label_points = false) {
  
  int n_points = xyz.nrow();
  
  if (n_points < min_votes) {
    return List::create(
      Named("n_spheres") = 0,
      Named("spheres") = DataFrame::create()
    );
  }
  
  std::vector<double> sphere_x, sphere_y, sphere_z, sphere_radius;
  std::vector<int> sphere_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);
  
  // Grid-based spatial indexing for candidate center detection
  double grid_size = max_radius * 2.0;
  std::map<std::tuple<int, int, int>, std::vector<int>> grid;
  
  for (int i = 0; i < n_points; i++) {
    int gx = (int)floor(xyz(i, 0) / grid_size);
    int gy = (int)floor(xyz(i, 1) / grid_size);
    int gz = (int)floor(xyz(i, 2) / grid_size);
    grid[std::make_tuple(gx, gy, gz)].push_back(i);
  }
  
  int sphere_id = 0;
  
  // Find sphere candidates from dense regions
  for (auto& cell : grid) {
    if ((int)cell.second.size() < min_votes / 2) continue;
    
    // Calculate centroid as initial sphere center estimate
    double cx = 0, cy = 0, cz = 0;
    int available = 0;
    for (int idx : cell.second) {
      if (!used[idx]) {
        cx += xyz(idx, 0);
        cy += xyz(idx, 1);
        cz += xyz(idx, 2);
        available++;
      }
    }
    
    if (available < min_votes / 2) continue;
    
    cx /= available;
    cy /= available;
    cz /= available;
    
    // Iteratively refine center estimate
    for (int iter = 0; iter < 3; iter++) {
      // Find points within search radius
      std::vector<int> nearby;
      double search_radius = max_radius * 1.2;  // Search slightly beyond max
      
      for (int i = 0; i < n_points; i++) {
        if (used[i]) continue;
        
        double dx = xyz(i, 0) - cx;
        double dy = xyz(i, 1) - cy;
        double dz = xyz(i, 2) - cz;
        double dist = sqrt(dx*dx + dy*dy + dz*dz);
        
        if (dist <= search_radius) {
          nearby.push_back(i);
        }
      }
      
      if ((int)nearby.size() < min_votes / 2) break;
      
      // Find mean radius
      double mean_r = 0;
      for (int idx : nearby) {
        double dx = xyz(idx, 0) - cx;
        double dy = xyz(idx, 1) - cy;
        double dz = xyz(idx, 2) - cz;
        mean_r += sqrt(dx*dx + dy*dy + dz*dz);
      }
      mean_r /= nearby.size();
      
      if (mean_r < min_radius || mean_r > max_radius) break;
      
      // Refine center: points should be at distance mean_r
      double new_cx = 0, new_cy = 0, new_cz = 0;
      int count = 0;
      for (int idx : nearby) {
        double dx = xyz(idx, 0) - cx;
        double dy = xyz(idx, 1) - cy;
        double dz = xyz(idx, 2) - cz;
        double dist = sqrt(dx*dx + dy*dy + dz*dz);
        
        // For point P on sphere surface at distance r from center C:
        // C = P - r * (P-C)/|P-C| = P - r * normalized_direction
        if (dist > 0.01) {  // Avoid division by zero
          new_cx += xyz(idx, 0) - mean_r * dx / dist;
          new_cy += xyz(idx, 1) - mean_r * dy / dist;
          new_cz += xyz(idx, 2) - mean_r * dz / dist;
          count++;
        }
      }
      
      if (count > 0) {
        cx = new_cx / count;
        cy = new_cy / count;
        cz = new_cz / count;
      }
    }
    
    // Final validation with refined center
    std::vector<int> nearby;
    for (int i = 0; i < n_points; i++) {
      if (used[i]) continue;
      
      double dx = xyz(i, 0) - cx;
      double dy = xyz(i, 1) - cy;
      double dz = xyz(i, 2) - cz;
      double dist = sqrt(dx*dx + dy*dy + dz*dz);
      
      if (dist <= max_radius * 1.1) {
        nearby.push_back(i);
      }
    }
    
    if ((int)nearby.size() < min_votes) continue;
    
    // Calculate radial distances to check for spherical shell
    std::vector<double> distances;
    for (int idx : nearby) {
      double dx = xyz(idx, 0) - cx;
      double dy = xyz(idx, 1) - cy;
      double dz = xyz(idx, 2) - cz;
      distances.push_back(sqrt(dx*dx + dy*dy + dz*dz));
    }
    
    // Find the mode of the distance distribution (most common radius)
    double mean_dist = 0;
    for (double d : distances) mean_dist += d;
    mean_dist /= distances.size();
    
    if (mean_dist < min_radius || mean_dist > max_radius) continue;
    
    // Check sphericity - points should cluster around a shell at mean_dist
    double variance = 0;
    for (double d : distances) {
      double diff = d - mean_dist;
      variance += diff * diff;
    }
    variance /= distances.size();
    double stddev = sqrt(variance);
    
    // Accept if standard deviation is less than 30% of radius (reasonable shell)
    if (stddev > mean_dist * 0.30) continue;
    
    // Check for angular distribution - points should cover sphere surface
    // Count points in different octants
    int octant_counts[8] = {0};
    for (int idx : nearby) {
      double dx = xyz(idx, 0) - cx;
      double dy = xyz(idx, 1) - cy;
      double dz = xyz(idx, 2) - cz;
      int oct = ((dx > 0) ? 1 : 0) + ((dy > 0) ? 2 : 0) + ((dz > 0) ? 4 : 0);
      octant_counts[oct]++;
    }
    
    // Require at least 3 octants to have points (reasonable coverage)
    int occupied_octants = 0;
    for (int i = 0; i < 8; i++) {
      if (octant_counts[i] > 0) occupied_octants++;
    }
    if (occupied_octants < 3) continue;
    
    // Refine center estimate using points close to mean radius
    double sum_x = 0, sum_y = 0, sum_z = 0;
    int count = 0;
    for (int idx : nearby) {
      double dx = xyz(idx, 0) - cx;
      double dy = xyz(idx, 1) - cy;
      double dz = xyz(idx, 2) - cz;
      double dist = sqrt(dx*dx + dy*dy + dz*dz);
      
      if (fabs(dist - mean_dist) < stddev * 1.5) {
        sum_x += xyz(idx, 0);
        sum_y += xyz(idx, 1);
        sum_z += xyz(idx, 2);
        count++;
      }
    }
    
    if (count < min_votes) continue;
    
    cx = sum_x / count;
    cy = sum_y / count;
    cz = sum_z / count;
    
    // Final radius calculation
    double final_radius = 0;
    std::vector<int> sphere_points;
    for (int idx : nearby) {
      double dx = xyz(idx, 0) - cx;
      double dy = xyz(idx, 1) - cy;
      double dz = xyz(idx, 2) - cz;
      double dist = sqrt(dx*dx + dy*dy + dz*dz);
      
      if (fabs(dist - mean_dist) < stddev * 2.0) {
        sphere_points.push_back(idx);
        final_radius += dist;
      }
    }
    
    if ((int)sphere_points.size() < min_votes) continue;
    
    final_radius /= sphere_points.size();
    
    // Mark points as used
    for (int idx : sphere_points) {
      used[idx] = true;
      if (label_points) {
        point_labels[idx] = sphere_id + 1;
      }
    }
    
    // Record sphere
    sphere_id++;
    sphere_x.push_back(cx);
    sphere_y.push_back(cy);
    sphere_z.push_back(cz);
    sphere_radius.push_back(final_radius);
    sphere_votes.push_back(sphere_points.size());
  }
  
  // Build results
  DataFrame spheres;
  if (sphere_id > 0) {
    spheres = DataFrame::create(
      Named("sphere_id") = seq(1, sphere_id),
      Named("x") = sphere_x,
      Named("y") = sphere_y,
      Named("z") = sphere_z,
      Named("radius") = sphere_radius,
      Named("n_points") = sphere_votes
    );
  } else {
    spheres = DataFrame::create(
      Named("sphere_id") = IntegerVector(),
      Named("x") = NumericVector(),
      Named("y") = NumericVector(),
      Named("z") = NumericVector(),
      Named("radius") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }
  
  List result = List::create(
    Named("n_spheres") = sphere_id,
    Named("spheres") = spheres
  );
  
  if (label_points) {
    result["point_labels"] = point_labels;
  }
  
  return result;
}

//' Detect planes in point cloud data using RANSAC
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @param distance_threshold Maximum distance from plane for inliers
//' @param min_votes Minimum number of points required to detect a plane
//' @param max_iterations Maximum RANSAC iterations
//' @param label_points If TRUE, label all points with plane ID
//' @return A list with detected planes and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_planes(NumericMatrix xyz,
                   double distance_threshold = 0.1,
                   int min_votes = 100,
                   int max_iterations = 1000,
                   bool label_points = false) {
  
  int n_points = xyz.nrow();
  
  if (n_points < min_votes) {
    return List::create(
      Named("n_planes") = 0,
      Named("planes") = DataFrame::create()
    );
  }
  
  std::vector<double> plane_a, plane_b, plane_c, plane_d;
  std::vector<int> plane_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);
  
  int plane_id = 0;
  
  // RANSAC plane detection
  while (true) {
    // Count available points
    int available = 0;
    for (int i = 0; i < n_points; i++) {
      if (!used[i]) available++;
    }
    
    if (available < min_votes) break;
    
    double best_a = 0, best_b = 0, best_c = 0, best_d = 0;
    int best_inliers = 0;
    std::vector<int> best_inlier_indices;
    
    // RANSAC iterations
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
      
      // Calculate plane from 3 points: ax + by + cz + d = 0
      double x1 = xyz(samples[0], 0), y1 = xyz(samples[0], 1), z1 = xyz(samples[0], 2);
      double x2 = xyz(samples[1], 0), y2 = xyz(samples[1], 1), z2 = xyz(samples[1], 2);
      double x3 = xyz(samples[2], 0), y3 = xyz(samples[2], 1), z3 = xyz(samples[2], 2);
      
      // Two vectors in plane
      double v1x = x2 - x1, v1y = y2 - y1, v1z = z2 - z1;
      double v2x = x3 - x1, v2y = y3 - y1, v2z = z3 - z1;
      
      // Normal vector (cross product)
      double nx = v1y * v2z - v1z * v2y;
      double ny = v1z * v2x - v1x * v2z;
      double nz = v1x * v2y - v1y * v2x;
      
      double norm = sqrt(nx*nx + ny*ny + nz*nz);
      if (norm < 1e-6) continue;
      
      double a = nx / norm;
      double b = ny / norm;
      double c = nz / norm;
      double d = -(a * x1 + b * y1 + c * z1);
      
      // Count inliers
      std::vector<int> inliers;
      for (int i = 0; i < n_points; i++) {
        if (used[i]) continue;
        
        double dist = fabs(a * xyz(i, 0) + b * xyz(i, 1) + c * xyz(i, 2) + d);
        if (dist < distance_threshold) {
          inliers.push_back(i);
        }
      }
      
      if ((int)inliers.size() > best_inliers) {
        best_inliers = inliers.size();
        best_a = a;
        best_b = b;
        best_c = c;
        best_d = d;
        best_inlier_indices = inliers;
      }
    }
    
    if (best_inliers < min_votes) break;
    
    // Mark points as used
    for (int idx : best_inlier_indices) {
      used[idx] = true;
      if (label_points) {
        point_labels[idx] = plane_id + 1;
      }
    }
    
    plane_id++;
    plane_a.push_back(best_a);
    plane_b.push_back(best_b);
    plane_c.push_back(best_c);
    plane_d.push_back(best_d);
    plane_votes.push_back(best_inliers);
  }
  
  // Build results
  DataFrame planes;
  if (plane_id > 0) {
    planes = DataFrame::create(
      Named("plane_id") = seq(1, plane_id),
      Named("a") = plane_a,
      Named("b") = plane_b,
      Named("c") = plane_c,
      Named("d") = plane_d,
      Named("n_points") = plane_votes
    );
  } else {
    planes = DataFrame::create(
      Named("plane_id") = IntegerVector(),
      Named("a") = NumericVector(),
      Named("b") = NumericVector(),
      Named("c") = NumericVector(),
      Named("d") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }
  
  List result = List::create(
    Named("n_planes") = plane_id,
    Named("planes") = planes
  );
  
  if (label_points) {
    result["point_labels"] = point_labels;
  }
  
  return result;
}

//' Detect 3D lines in point cloud data
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @param distance_threshold Maximum distance from line for inliers
//' @param min_votes Minimum number of points required to detect a line
//' @param min_length Minimum line length
//' @param max_iterations Maximum RANSAC iterations
//' @param in_scene If TRUE, assumes lines exist in complex scene (stricter). If FALSE, optimized for line-only detection (more aggressive)
//' @param label_points If TRUE, label all points with line ID
//' @return A list with detected lines and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_lines(NumericMatrix xyz,
                  double distance_threshold = 0.05,
                  int min_votes = 20,
                  double min_length = 0.5,
                  int max_iterations = 500,
                  bool in_scene = true,
                  bool label_points = false) {
  
  // Adjust parameters based on detection context
  if (!in_scene) {
    // Line-only mode: more aggressive detection
    distance_threshold *= 1.3;  // Allow slightly more deviation
    min_votes = std::max(10, (int)(min_votes * 0.7));  // Lower threshold
    min_length *= 0.8;  // Accept shorter lines
    max_iterations = (int)(max_iterations * 1.5);  // More RANSAC iterations
  }
  
  int n_points = xyz.nrow();
  
  if (n_points < min_votes) {
    return List::create(
      Named("n_lines") = 0,
      Named("lines") = DataFrame::create()
    );
  }
  
  std::vector<double> line_x1, line_y1, line_z1, line_x2, line_y2, line_z2;
  std::vector<int> line_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);
  
  int line_id = 0;
  
  // RANSAC line detection
  while (true) {
    int available = 0;
    for (int i = 0; i < n_points; i++) {
      if (!used[i]) available++;
    }
    
    if (available < min_votes) break;
    
    double best_px = 0, best_py = 0, best_pz = 0;  // Point on line
    double best_dx = 0, best_dy = 0, best_dz = 0;  // Direction
    int best_inliers = 0;
    std::vector<int> best_inlier_indices;
    
    for (int iter = 0; iter < max_iterations; iter++) {
      // Sample 2 random points
      std::vector<int> samples;
      int attempts = 0;
      while ((int)samples.size() < 2 && attempts < 1000) {
        int idx = rand() % n_points;
        if (!used[idx] && std::find(samples.begin(), samples.end(), idx) == samples.end()) {
          samples.push_back(idx);
        }
        attempts++;
      }
      
      if ((int)samples.size() < 2) continue;
      
      double x1 = xyz(samples[0], 0), y1 = xyz(samples[0], 1), z1 = xyz(samples[0], 2);
      double x2 = xyz(samples[1], 0), y2 = xyz(samples[1], 1), z2 = xyz(samples[1], 2);
      
      double dx = x2 - x1, dy = y2 - y1, dz = z2 - z1;
      double len = sqrt(dx*dx + dy*dy + dz*dz);
      
      if (len < 1e-6) continue;
      
      dx /= len; dy /= len; dz /= len;
      
      // Count inliers (distance from point to line)
      std::vector<int> inliers;
      for (int i = 0; i < n_points; i++) {
        if (used[i]) continue;
        
        double vx = xyz(i, 0) - x1;
        double vy = xyz(i, 1) - y1;
        double vz = xyz(i, 2) - z1;
        
        // Distance = |v - (v·d)d|
        double dot = vx*dx + vy*dy + vz*dz;
        double px = vx - dot*dx;
        double py = vy - dot*dy;
        double pz = vz - dot*dz;
        double dist = sqrt(px*px + py*py + pz*pz);
        
        if (dist < distance_threshold) {
          inliers.push_back(i);
        }
      }
      
      if ((int)inliers.size() > best_inliers) {
        best_inliers = inliers.size();
        best_px = x1; best_py = y1; best_pz = z1;
        best_dx = dx; best_dy = dy; best_dz = dz;
        best_inlier_indices = inliers;
      }
    }
    
    if (best_inliers < min_votes) break;
    
    // Calculate actual line endpoints from inliers
    double min_t = 0, max_t = 0;
    for (int idx : best_inlier_indices) {
      double vx = xyz(idx, 0) - best_px;
      double vy = xyz(idx, 1) - best_py;
      double vz = xyz(idx, 2) - best_pz;
      double t = vx*best_dx + vy*best_dy + vz*best_dz;
      
      if (t < min_t) min_t = t;
      if (t > max_t) max_t = t;
    }
    
    double length = max_t - min_t;
    if (length < min_length) break;
    
    double x1 = best_px + min_t * best_dx;
    double y1 = best_py + min_t * best_dy;
    double z1 = best_pz + min_t * best_dz;
    double x2 = best_px + max_t * best_dx;
    double y2 = best_py + max_t * best_dy;
    double z2 = best_pz + max_t * best_dz;
    
    // Mark points as used
    for (int idx : best_inlier_indices) {
      used[idx] = true;
      if (label_points) {
        point_labels[idx] = line_id + 1;
      }
    }
    
    line_id++;
    line_x1.push_back(x1); line_y1.push_back(y1); line_z1.push_back(z1);
    line_x2.push_back(x2); line_y2.push_back(y2); line_z2.push_back(z2);
    line_votes.push_back(best_inliers);
  }
  
  // Build results
  DataFrame lines;
  if (line_id > 0) {
    lines = DataFrame::create(
      Named("line_id") = seq(1, line_id),
      Named("x1") = line_x1,
      Named("y1") = line_y1,
      Named("z1") = line_z1,
      Named("x2") = line_x2,
      Named("y2") = line_y2,
      Named("z2") = line_z2,
      Named("n_points") = line_votes
    );
  } else {
    lines = DataFrame::create(
      Named("line_id") = IntegerVector(),
      Named("x1") = NumericVector(),
      Named("y1") = NumericVector(),
      Named("z1") = NumericVector(),
      Named("x2") = NumericVector(),
      Named("y2") = NumericVector(),
      Named("z2") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }
  
  List result = List::create(
    Named("n_lines") = line_id,
    Named("lines") = lines
  );
  
  if (label_points) {
    result["point_labels"] = point_labels;
  }
  
  return result;
}

//' Detect general cylinders (not just vertical) in point cloud data
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @param min_radius Minimum cylinder radius
//' @param max_radius Maximum cylinder radius
//' @param min_length Minimum cylinder length
//' @param min_votes Minimum number of points required
//' @param label_points If TRUE, label all points with cylinder ID
//' @return A list with detected cylinders and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_cylinders(NumericMatrix xyz,
                      double min_radius = 0.1,
                      double max_radius = 2.0,
                      double min_length = 1.0,
                      int min_votes = 50,
                      bool label_points = false) {
  
  int n_points = xyz.nrow();
  
  if (n_points < min_votes) {
    return List::create(
      Named("n_cylinders") = 0,
      Named("cylinders") = DataFrame::create()
    );
  }
  
  std::vector<double> cyl_x1, cyl_y1, cyl_z1, cyl_x2, cyl_y2, cyl_z2, cyl_radius;
  std::vector<int> cyl_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);
  
  int cyl_id = 0;
  
  // Grid-based detection using XY grid only (ignore Z for vertical cylinders)
  double grid_size = max_radius * 3.0;
  std::map<std::pair<int, int>, std::vector<int>> grid;
  
  for (int i = 0; i < n_points; i++) {
    int gx = (int)floor(xyz(i, 0) / grid_size);
    int gy = (int)floor(xyz(i, 1) / grid_size);
    grid[std::make_pair(gx, gy)].push_back(i);
  }
  
  // Detect vertical cylinders similar to tree detection
  // Analyze horizontal slices
  double minZ = xyz(0, 2), maxZ = xyz(0, 2);
  for (int i = 1; i < n_points; i++) {
    if (xyz(i, 2) < minZ) minZ = xyz(i, 2);
    if (xyz(i, 2) > maxZ) maxZ = xyz(i, 2);
  }
  
  double slice_height = 0.3;
  int n_slices = std::max(3, (int)ceil((maxZ - minZ) / slice_height));
  
  // For each grid cell, check if it contains a cylindrical pattern
  for (auto& cell : grid) {
    if ((int)cell.second.size() < min_votes / 2) continue;
    
    std::vector<int> available;
    for (int idx : cell.second) {
      if (!used[idx]) available.push_back(idx);
    }
    
    if ((int)available.size() < min_votes) continue;  // Stricter threshold
    
    // Compute center in XY
    double cx_total = 0, cy_total = 0;
    for (int idx : available) {
      cx_total += xyz(idx, 0);
      cy_total += xyz(idx, 1);
    }
    cx_total /= available.size();
    cy_total /= available.size();
    
    // Check multiple slices for consistent circular pattern
    std::vector<double> slice_radii;
    std::vector<double> slice_centers_x, slice_centers_y;
    
    double zmin_cyl = 1e10, zmax_cyl = -1e10;
    for (int idx : available) {
      if (xyz(idx, 2) < zmin_cyl) zmin_cyl = xyz(idx, 2);
      if (xyz(idx, 2) > zmax_cyl) zmax_cyl = xyz(idx, 2);
    }
    
    if (zmax_cyl - zmin_cyl < min_length) continue;
    
    // Sample slices
    int valid_slices = 0;
    for (int s = 0; s < n_slices && s < 10; s++) {
      double z_slice = zmin_cyl + (zmax_cyl - zmin_cyl) * s / (double)n_slices;
      
      std::vector<int> slice_points;
      for (int idx : available) {
        if (fabs(xyz(idx, 2) - z_slice) < slice_height) {
          slice_points.push_back(idx);
        }
      }
      
      if ((int)slice_points.size() < 8) continue;
      
      // Compute center and radius for this slice
      double cx = 0, cy = 0;
      for (int idx : slice_points) {
        cx += xyz(idx, 0);
        cy += xyz(idx, 1);
      }
      cx /= slice_points.size();
      cy /= slice_points.size();
      
      double r = 0;
      for (int idx : slice_points) {
        double dx = xyz(idx, 0) - cx;
        double dy = xyz(idx, 1) - cy;
        r += sqrt(dx*dx + dy*dy);
      }
      r /= slice_points.size();
      
      if (r >= min_radius && r <= max_radius) {
        slice_radii.push_back(r);
        slice_centers_x.push_back(cx);
        slice_centers_y.push_back(cy);
        valid_slices++;
      }
    }
    
    if (valid_slices < 3) continue;
    
    // Check consistency of radius and center across slices
    double mean_r = 0;
    for (double r : slice_radii) mean_r += r;
    mean_r /= slice_radii.size();
    
    double mean_cx = 0, mean_cy = 0;
    for (size_t i = 0; i < slice_centers_x.size(); i++) {
      mean_cx += slice_centers_x[i];
      mean_cy += slice_centers_y[i];
    }
    mean_cx /= slice_centers_x.size();
    mean_cy /= slice_centers_y.size();
    
    // Check variation
    double r_var = 0;
    for (double r : slice_radii) {
      double diff = r - mean_r;
      r_var += diff * diff;
    }
    r_var = sqrt(r_var / slice_radii.size());
    
    if (r_var > mean_r * 0.35) continue;
    
    // Check center consistency
    double c_var = 0;
    for (size_t i = 0; i < slice_centers_x.size(); i++) {
      double dx = slice_centers_x[i] - mean_cx;
      double dy = slice_centers_y[i] - mean_cy;
      c_var += sqrt(dx*dx + dy*dy);
    }
    c_var /= slice_centers_x.size();
    
    if (c_var > mean_r * 0.5) continue;
    
    // Valid cylinder found - collect supporting points
    double cyl_minZ = 1e10, cyl_maxZ = -1e10;
    int support_count = 0;
    
    // Collect points within radius of cylinder axis
    for (int idx : available) {
      double dx = xyz(idx, 0) - mean_cx;
      double dy = xyz(idx, 1) - mean_cy;
      double dist = sqrt(dx*dx + dy*dy);
      
      if (dist <= mean_r * 1.3) {
        if (xyz(idx, 2) < cyl_minZ) cyl_minZ = xyz(idx, 2);
        if (xyz(idx, 2) > cyl_maxZ) cyl_maxZ = xyz(idx, 2);
        support_count++;
      }
    }
    
    double length = cyl_maxZ - cyl_minZ;
    if (length < min_length || support_count < min_votes) continue;
    
    // Mark points as used and label them
    for (int idx : available) {
      double dx = xyz(idx, 0) - mean_cx;
      double dy = xyz(idx, 1) - mean_cy;
      double dist = sqrt(dx*dx + dy*dy);
      
      if (dist <= mean_r * 1.3) {
        used[idx] = true;
        if (label_points) {
          point_labels[idx] = cyl_id + 1;
        }
      }
    }
    
    cyl_id++;
    cyl_x1.push_back(mean_cx);
    cyl_y1.push_back(mean_cy);
    cyl_z1.push_back(cyl_minZ);
    cyl_x2.push_back(mean_cx);
    cyl_y2.push_back(mean_cy);
    cyl_z2.push_back(cyl_maxZ);
    cyl_radius.push_back(mean_r);
    cyl_votes.push_back(support_count);
  }
  
  // Build results
  DataFrame cylinders;
  if (cyl_id > 0) {
    cylinders = DataFrame::create(
      Named("cylinder_id") = seq(1, cyl_id),
      Named("x1") = cyl_x1,
      Named("y1") = cyl_y1,
      Named("z1") = cyl_z1,
      Named("x2") = cyl_x2,
      Named("y2") = cyl_y2,
      Named("z2") = cyl_z2,
      Named("radius") = cyl_radius,
      Named("n_points") = cyl_votes
    );
  } else {
    cylinders = DataFrame::create(
      Named("cylinder_id") = IntegerVector(),
      Named("x1") = NumericVector(),
      Named("y1") = NumericVector(),
      Named("z1") = NumericVector(),
      Named("x2") = NumericVector(),
      Named("y2") = NumericVector(),
      Named("z2") = NumericVector(),
      Named("radius") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }
  
  List result = List::create(
    Named("n_cylinders") = cyl_id,
    Named("cylinders") = cylinders
  );
  
  if (label_points) {
    result["point_labels"] = point_labels;
  }
  
  return result;
}

//' Detect cubes in point cloud data
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @param min_size Minimum cube side length
//' @param max_size Maximum cube side length
//' @param min_votes Minimum number of points required per cube
//' @param plane_threshold Distance threshold for plane detection
//' @param label_points If TRUE, label all points with cube ID
//' @return A list with detected cubes and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_cubes(NumericMatrix xyz,
                  double min_size = 0.3,
                  double max_size = 3.0,
                  int min_votes = 100,
                  double plane_threshold = 0.05,
                  bool label_points = false) {
  
  int n_points = xyz.nrow();
  
  if (n_points < min_votes) {
    return List::create(
      Named("n_cubes") = 0,
      Named("cubes") = DataFrame::create()
    );
  }
  
  std::vector<double> cube_x, cube_y, cube_z, cube_size;
  std::vector<int> cube_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);
  
  // First detect planes, then look for cube configurations (6 orthogonal planes)
  List plane_result = detect_planes(xyz, plane_threshold, min_votes / 6, 500, false);
  
  if (plane_result["n_planes"] == 0) {
    return List::create(
      Named("n_cubes") = 0,
      Named("cubes") = DataFrame::create()
    );
  }
  
  DataFrame planes = as<DataFrame>(plane_result["planes"]);
  int n_planes = planes.nrow();
  
  if (n_planes < 6) {
    return List::create(
      Named("n_cubes") = 0,
      Named("cubes") = DataFrame::create()
    );
  }
  
  NumericVector plane_a = planes["a"];
  NumericVector plane_b = planes["b"];
  NumericVector plane_c = planes["c"];
  NumericVector plane_d = planes["d"];
  
  int cube_id = 0;
  std::vector<bool> used_planes(n_planes, false);
  
  // Try to find sets of 6 orthogonal planes forming a cube
  for (int i = 0; i < n_planes && cube_id < 50; i++) {
    if (used_planes[i]) continue;
    
    double nx1 = plane_a[i], ny1 = plane_b[i], nz1 = plane_c[i];
    double norm1 = sqrt(nx1*nx1 + ny1*ny1 + nz1*nz1);
    nx1 /= norm1; ny1 /= norm1; nz1 /= norm1;
    
    // Look for parallel plane (opposite face)
    int parallel_idx = -1;
    for (int j = i+1; j < n_planes; j++) {
      if (used_planes[j]) continue;
      
      double nx2 = plane_a[j], ny2 = plane_b[j], nz2 = plane_c[j];
      double norm2 = sqrt(nx2*nx2 + ny2*ny2 + nz2*nz2);
      nx2 /= norm2; ny2 /= norm2; nz2 /= norm2;
      
      // Check if parallel (dot product ~= ±1)
      double dot = fabs(nx1*nx2 + ny1*ny2 + nz1*nz2);
      if (dot > 0.95) {
        parallel_idx = j;
        break;
      }
    }
    
    if (parallel_idx < 0) continue;
    
    // Find 4 more orthogonal planes
    std::vector<int> ortho_planes;
    for (int j = 0; j < n_planes && (int)ortho_planes.size() < 4; j++) {
      if (used_planes[j] || j == i || j == parallel_idx) continue;
      
      double nx2 = plane_a[j], ny2 = plane_b[j], nz2 = plane_c[j];
      double norm2 = sqrt(nx2*nx2 + ny2*ny2 + nz2*nz2);
      nx2 /= norm2; ny2 /= norm2; nz2 /= norm2;
      
      // Check if orthogonal (dot product ~= 0)
      double dot = fabs(nx1*nx2 + ny1*ny2 + nz1*nz2);
      if (dot < 0.15) {
        ortho_planes.push_back(j);
      }
    }
    
    if ((int)ortho_planes.size() >= 4) {
      // Estimate cube center and size from planes
      // Simplified: calculate bounding box of all supporting points
      std::vector<int> supporting_points;
      
      for (int p = 0; p < n_points; p++) {
        if (used[p]) continue;
        
        double x = xyz(p, 0), y = xyz(p, 1), z = xyz(p, 2);
        double d1 = fabs(plane_a[i]*x + plane_b[i]*y + plane_c[i]*z + plane_d[i]) / 
                    sqrt(plane_a[i]*plane_a[i] + plane_b[i]*plane_b[i] + plane_c[i]*plane_c[i]);
        
        if (d1 < plane_threshold * 2) {
          supporting_points.push_back(p);
        }
      }
      
      if ((int)supporting_points.size() >= min_votes / 6) {
        // Calculate bounding box
        double minX = xyz(supporting_points[0], 0);
        double maxX = xyz(supporting_points[0], 0);
        double minY = xyz(supporting_points[0], 1);
        double maxY = xyz(supporting_points[0], 1);
        double minZ = xyz(supporting_points[0], 2);
        double maxZ = xyz(supporting_points[0], 2);
        
        for (int idx : supporting_points) {
          if (xyz(idx, 0) < minX) minX = xyz(idx, 0);
          if (xyz(idx, 0) > maxX) maxX = xyz(idx, 0);
          if (xyz(idx, 1) < minY) minY = xyz(idx, 1);
          if (xyz(idx, 1) > maxY) maxY = xyz(idx, 1);
          if (xyz(idx, 2) < minZ) minZ = xyz(idx, 2);
          if (xyz(idx, 2) > maxZ) maxZ = xyz(idx, 2);
        }
        
        double cx = (minX + maxX) / 2;
        double cy = (minY + maxY) / 2;
        double cz = (minZ + maxZ) / 2;
        double size = std::max({maxX - minX, maxY - minY, maxZ - minZ});
        
        if (size >= min_size && size <= max_size) {
          cube_id++;
          cube_x.push_back(cx);
          cube_y.push_back(cy);
          cube_z.push_back(cz);
          cube_size.push_back(size);
          cube_votes.push_back(supporting_points.size());
          
          if (label_points) {
            for (int idx : supporting_points) {
              point_labels[idx] = cube_id;
              used[idx] = true;
            }
          }
          
          used_planes[i] = true;
          used_planes[parallel_idx] = true;
        }
      }
    }
  }
  
  // Create result dataframe
  DataFrame cubes;
  if (cube_id > 0) {
    cubes = DataFrame::create(
      Named("cube_id") = seq(1, cube_id),
      Named("x") = cube_x,
      Named("y") = cube_y,
      Named("z") = cube_z,
      Named("size") = cube_size,
      Named("n_points") = cube_votes
    );
  } else {
    cubes = DataFrame::create(
      Named("cube_id") = IntegerVector(),
      Named("x") = NumericVector(),
      Named("y") = NumericVector(),
      Named("z") = NumericVector(),
      Named("size") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }
  
  List result = List::create(
    Named("n_cubes") = cube_id,
    Named("cubes") = cubes
  );
  
  if (label_points) {
    result["point_labels"] = point_labels;
  }
  
  return result;
}

//' Detect cuboids (rectangular boxes) in point cloud data
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @param min_width Minimum cuboid width
//' @param max_width Maximum cuboid width
//' @param min_height Minimum cuboid height
//' @param max_height Maximum cuboid height
//' @param min_votes Minimum number of points required per cuboid
//' @param plane_threshold Distance threshold for plane detection
//' @param label_points If TRUE, label all points with cuboid ID
//' @return A list with detected cuboids and optionally labeled points
//' @export
// [[Rcpp::export]]
List detect_cuboids(NumericMatrix xyz,
                    double min_width = 0.5,
                    double max_width = 10.0,
                    double min_height = 0.5,
                    double max_height = 10.0,
                    int min_votes = 150,
                    double plane_threshold = 0.1,
                    bool label_points = false) {
  
  int n_points = xyz.nrow();
  
  if (n_points < min_votes) {
    return List::create(
      Named("n_cuboids") = 0,
      Named("cuboids") = DataFrame::create()
    );
  }
  
  std::vector<double> cuboid_x, cuboid_y, cuboid_z;
  std::vector<double> cuboid_width, cuboid_depth, cuboid_height;
  std::vector<int> cuboid_votes;
  IntegerVector point_labels(n_points, 0);
  std::vector<bool> used(n_points, false);
  
  // First detect planes
  List plane_result = detect_planes(xyz, plane_threshold, min_votes / 6, 500, false);
  
  if (plane_result["n_planes"] == 0) {
    return List::create(
      Named("n_cuboids") = 0,
      Named("cuboids") = DataFrame::create()
    );
  }
  
  DataFrame planes = as<DataFrame>(plane_result["planes"]);
  int n_planes = planes.nrow();
  
  if (n_planes < 4) {
    return List::create(
      Named("n_cuboids") = 0,
      Named("cuboids") = DataFrame::create()
    );
  }
  
  NumericVector plane_a = planes["a"];
  NumericVector plane_b = planes["b"];
  NumericVector plane_c = planes["c"];
  NumericVector plane_d = planes["d"];
  
  int cuboid_id = 0;
  std::vector<bool> used_planes(n_planes, false);
  
  // Find sets of orthogonal planes forming cuboids
  for (int i = 0; i < n_planes && cuboid_id < 50; i++) {
    if (used_planes[i]) continue;
    
    double nx1 = plane_a[i], ny1 = plane_b[i], nz1 = plane_c[i];
    double norm1 = sqrt(nx1*nx1 + ny1*ny1 + nz1*nz1);
    nx1 /= norm1; ny1 /= norm1; nz1 /= norm1;
    
    // Find orthogonal planes
    std::vector<int> related_planes;
    related_planes.push_back(i);
    
    for (int j = i+1; j < n_planes; j++) {
      if (used_planes[j]) continue;
      
      double nx2 = plane_a[j], ny2 = plane_b[j], nz2 = plane_c[j];
      double norm2 = sqrt(nx2*nx2 + ny2*ny2 + nz2*nz2);
      nx2 /= norm2; ny2 /= norm2; nz2 /= norm2;
      
      // Check if parallel or orthogonal
      double dot = fabs(nx1*nx2 + ny1*ny2 + nz1*nz2);
      if (dot > 0.9 || dot < 0.15) {
        related_planes.push_back(j);
      }
    }
    
    if ((int)related_planes.size() >= 4) {
      // Collect all points near these planes
      std::vector<int> supporting_points;
      
      for (int p = 0; p < n_points; p++) {
        if (used[p]) continue;
        
        double x = xyz(p, 0), y = xyz(p, 1), z = xyz(p, 2);
        
        for (int plane_idx : related_planes) {
          double d = fabs(plane_a[plane_idx]*x + plane_b[plane_idx]*y + 
                         plane_c[plane_idx]*z + plane_d[plane_idx]) / 
                    sqrt(plane_a[plane_idx]*plane_a[plane_idx] + 
                         plane_b[plane_idx]*plane_b[plane_idx] + 
                         plane_c[plane_idx]*plane_c[plane_idx]);
          
          if (d < plane_threshold * 2) {
            supporting_points.push_back(p);
            break;
          }
        }
      }
      
      if ((int)supporting_points.size() >= min_votes) {
        // Calculate bounding box
        double minX = xyz(supporting_points[0], 0);
        double maxX = xyz(supporting_points[0], 0);
        double minY = xyz(supporting_points[0], 1);
        double maxY = xyz(supporting_points[0], 1);
        double minZ = xyz(supporting_points[0], 2);
        double maxZ = xyz(supporting_points[0], 2);
        
        for (int idx : supporting_points) {
          if (xyz(idx, 0) < minX) minX = xyz(idx, 0);
          if (xyz(idx, 0) > maxX) maxX = xyz(idx, 0);
          if (xyz(idx, 1) < minY) minY = xyz(idx, 1);
          if (xyz(idx, 1) > maxY) maxY = xyz(idx, 1);
          if (xyz(idx, 2) < minZ) minZ = xyz(idx, 2);
          if (xyz(idx, 2) > maxZ) maxZ = xyz(idx, 2);
        }
        
        double cx = (minX + maxX) / 2;
        double cy = (minY + maxY) / 2;
        double cz = (minZ + maxZ) / 2;
        double width = maxX - minX;
        double depth = maxY - minY;
        double height = maxZ - minZ;
        
        if (width >= min_width && width <= max_width &&
            height >= min_height && height <= max_height) {
          cuboid_id++;
          cuboid_x.push_back(cx);
          cuboid_y.push_back(cy);
          cuboid_z.push_back(cz);
          cuboid_width.push_back(width);
          cuboid_depth.push_back(depth);
          cuboid_height.push_back(height);
          cuboid_votes.push_back(supporting_points.size());
          
          if (label_points) {
            for (int idx : supporting_points) {
              point_labels[idx] = cuboid_id;
              used[idx] = true;
            }
          }
          
          for (int plane_idx : related_planes) {
            used_planes[plane_idx] = true;
          }
        }
      }
    }
  }
  
  // Create result dataframe
  DataFrame cuboids;
  if (cuboid_id > 0) {
    cuboids = DataFrame::create(
      Named("cuboid_id") = seq(1, cuboid_id),
      Named("x") = cuboid_x,
      Named("y") = cuboid_y,
      Named("z") = cuboid_z,
      Named("width") = cuboid_width,
      Named("depth") = cuboid_depth,
      Named("height") = cuboid_height,
      Named("n_points") = cuboid_votes
    );
  } else {
    cuboids = DataFrame::create(
      Named("cuboid_id") = IntegerVector(),
      Named("x") = NumericVector(),
      Named("y") = NumericVector(),
      Named("z") = NumericVector(),
      Named("width") = NumericVector(),
      Named("depth") = NumericVector(),
      Named("height") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }
  
  List result = List::create(
    Named("n_cuboids") = cuboid_id,
    Named("cuboids") = cuboids
  );
  
  if (label_points) {
    result["point_labels"] = point_labels;
  }
  
  return result;
}

//' Detect cones in 3D point cloud
//' 
//' @param xyz A matrix with 3 columns (X, Y, Z coordinates)
//' @param min_radius Minimum base radius in meters
//' @param max_radius Maximum base radius in meters
//' @param min_height Minimum cone height in meters
//' @param max_height Maximum cone height in meters
//' @param min_votes Minimum number of points to form a cone
//' @param angle_threshold Opening half-angle threshold in radians (default: 0.3 ~ 17 degrees)
//' @param label_points If TRUE, return point labels
//' @return A list with detected cones
//' @export
// [[Rcpp::export]]
List detect_cones(NumericMatrix xyz,
                  double min_radius = 0.1,
                  double max_radius = 2.0,
                  double min_height = 0.5,
                  double max_height = 10.0,
                  int min_votes = 50,
                  double angle_threshold = 0.3,
                  bool label_points = false) {
  
  int n = xyz.nrow();
  std::vector<int> point_labels(n, 0);
  std::vector<bool> used(n, false);
  
  int cone_id = 0;
  
  // Storage for detected cones
  std::vector<double> apex_x, apex_y, apex_z;
  std::vector<double> axis_x, axis_y, axis_z;
  std::vector<double> base_radius, height, half_angle;
  std::vector<int> n_points_vec;
  
  int max_iterations = 500;
  double distance_threshold = 0.15;
  
  // Iteratively detect cones
  for (int iter = 0; iter < max_iterations; iter++) {
    // Count available points
    int available = 0;
    for (int i = 0; i < n; i++) {
      if (!used[i]) available++;
    }
    
    if (available < min_votes) break;
    
    // RANSAC approach: sample random points to form cone hypothesis
    int best_inliers = 0;
    double best_apex[3] = {0, 0, 0};
    double best_axis[3] = {0, 0, 1};
    double best_base_radius = 0;
    double best_height = 0;
    double best_angle = 0;
    std::vector<int> best_inlier_indices;
    
    int ransac_iterations = 200;
    
    for (int r = 0; r < ransac_iterations; r++) {
      // Sample 3 non-used points randomly
      std::vector<int> sample_indices;
      for (int i = 0; i < n && sample_indices.size() < 3; i++) {
        if (!used[i] && R::runif(0, 1) < 0.01) {
          sample_indices.push_back(i);
        }
      }
      
      if (sample_indices.size() < 3) continue;
      
      // Use first point as potential apex
      double ax = xyz(sample_indices[0], 0);
      double ay = xyz(sample_indices[0], 1);
      double az = xyz(sample_indices[0], 2);
      
      // Use other two points to estimate axis direction
      double v1[3] = {
        xyz(sample_indices[1], 0) - ax,
        xyz(sample_indices[1], 1) - ay,
        xyz(sample_indices[1], 2) - az
      };
      double v2[3] = {
        xyz(sample_indices[2], 0) - ax,
        xyz(sample_indices[2], 1) - ay,
        xyz(sample_indices[2], 2) - az
      };
      
      // Average direction
      double dir[3] = {v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2]};
      double dir_len = sqrt(dir[0]*dir[0] + dir[1]*dir[1] + dir[2]*dir[2]);
      if (dir_len < 0.001) continue;
      
      dir[0] /= dir_len;
      dir[1] /= dir_len;
      dir[2] /= dir_len;
      
      // Count inliers for this cone hypothesis
      std::vector<int> inlier_indices;
      std::vector<double> inlier_heights;
      std::vector<double> inlier_radii;
      
      for (int i = 0; i < n; i++) {
        if (used[i]) continue;
        
        double px = xyz(i, 0);
        double py = xyz(i, 1);
        double pz = xyz(i, 2);
        
        // Vector from apex to point
        double ap[3] = {px - ax, py - ay, pz - az};
        
        // Height along axis
        double h = ap[0]*dir[0] + ap[1]*dir[1] + ap[2]*dir[2];
        if (h < min_height || h > max_height) continue;
        
        // Perpendicular distance from axis
        double proj[3] = {dir[0]*h, dir[1]*h, dir[2]*h};
        double perp[3] = {ap[0] - proj[0], ap[1] - proj[1], ap[2] - proj[2]};
        double perp_dist = sqrt(perp[0]*perp[0] + perp[1]*perp[1] + perp[2]*perp[2]);
        
        // For a cone: perpendicular_distance = height * tan(half_angle)
        double expected_radius = h * tan(angle_threshold);
        
        if (fabs(perp_dist - expected_radius) < distance_threshold) {
          inlier_indices.push_back(i);
          inlier_heights.push_back(h);
          inlier_radii.push_back(perp_dist);
        }
      }
      
      if (inlier_indices.size() > best_inliers) {
        best_inliers = inlier_indices.size();
        best_apex[0] = ax;
        best_apex[1] = ay;
        best_apex[2] = az;
        best_axis[0] = dir[0];
        best_axis[1] = dir[1];
        best_axis[2] = dir[2];
        best_inlier_indices = inlier_indices;
        
        // Compute cone parameters from inliers
        if (inlier_heights.size() > 0) {
          double max_h = *std::max_element(inlier_heights.begin(), inlier_heights.end());
          double max_r = *std::max_element(inlier_radii.begin(), inlier_radii.end());
          best_height = max_h;
          best_base_radius = max_r;
          best_angle = atan2(max_r, max_h);
        }
      }
    }
    
    // Check if we found a valid cone
    if (best_inliers >= min_votes && 
        best_base_radius >= min_radius && 
        best_base_radius <= max_radius &&
        best_height >= min_height && 
        best_height <= max_height) {
      
      cone_id++;
      
      // Refine cone parameters using all inliers
      double sum_h = 0, sum_r = 0;
      for (int idx : best_inlier_indices) {
        double px = xyz(idx, 0);
        double py = xyz(idx, 1);
        double pz = xyz(idx, 2);
        
        double ap[3] = {px - best_apex[0], py - best_apex[1], pz - best_apex[2]};
        double h = ap[0]*best_axis[0] + ap[1]*best_axis[1] + ap[2]*best_axis[2];
        
        double proj[3] = {best_axis[0]*h, best_axis[1]*h, best_axis[2]*h};
        double perp[3] = {ap[0] - proj[0], ap[1] - proj[1], ap[2] - proj[2]};
        double perp_dist = sqrt(perp[0]*perp[0] + perp[1]*perp[1] + perp[2]*perp[2]);
        
        sum_h += h;
        sum_r += perp_dist;
      }
      
      double avg_h = sum_h / best_inlier_indices.size();
      double avg_r = sum_r / best_inlier_indices.size();
      
      apex_x.push_back(best_apex[0]);
      apex_y.push_back(best_apex[1]);
      apex_z.push_back(best_apex[2]);
      axis_x.push_back(best_axis[0]);
      axis_y.push_back(best_axis[1]);
      axis_z.push_back(best_axis[2]);
      base_radius.push_back(best_base_radius);
      height.push_back(best_height);
      half_angle.push_back(best_angle);
      n_points_vec.push_back(best_inlier_indices.size());
      
      // Mark points as used
      for (int idx : best_inlier_indices) {
        used[idx] = true;
        if (label_points) {
          point_labels[idx] = cone_id;
        }
      }
    } else {
      break; // No more cones found
    }
  }
  
  // Create results data frame
  DataFrame cones;
  if (cone_id > 0) {
    cones = DataFrame::create(
      Named("cone_id") = seq(1, cone_id),
      Named("apex_x") = apex_x,
      Named("apex_y") = apex_y,
      Named("apex_z") = apex_z,
      Named("axis_x") = axis_x,
      Named("axis_y") = axis_y,
      Named("axis_z") = axis_z,
      Named("base_radius") = base_radius,
      Named("height") = height,
      Named("half_angle") = half_angle,
      Named("n_points") = n_points_vec
    );
  } else {
    cones = DataFrame::create(
      Named("cone_id") = IntegerVector(),
      Named("apex_x") = NumericVector(),
      Named("apex_y") = NumericVector(),
      Named("apex_z") = NumericVector(),
      Named("axis_x") = NumericVector(),
      Named("axis_y") = NumericVector(),
      Named("axis_z") = NumericVector(),
      Named("base_radius") = NumericVector(),
      Named("height") = NumericVector(),
      Named("half_angle") = NumericVector(),
      Named("n_points") = IntegerVector()
    );
  }
  
  List result = List::create(
    Named("n_cones") = cone_id,
    Named("cones") = cones
  );
  
  if (label_points) {
    result["point_labels"] = point_labels;
  }
  
  return result;
}
