import 'dart:math' as math;
import '../models/rubik_cube.dart';

/// K-Means Clustering Color Classifier
/// Tự động phát hiện 6 màu chính trong ảnh mà không cần training data
class KMeansColorClassifier {
  /// Chạy K-Means clustering để tìm 6 màu chính
  /// [colors]: Danh sách RGB colors từ ảnh
  /// [k]: Số cluster (6 cho Rubik's Cube)
  static List<List<int>> findClusters(List<List<int>> colors, {int k = 6}) {
    if (colors.isEmpty) return [];
    if (colors.length < k) {
      // Nếu không đủ màu, trả về trung bình của tất cả
      final avg = _averageColor(colors);
      return List.generate(k, (_) => avg);
    }

    // Khởi tạo centroids ngẫu nhiên
    final random = math.Random();
    List<List<double>> centroids = [];
    final usedIndices = <int>{};
    
    for (int i = 0; i < k; i++) {
      int index;
      do {
        index = random.nextInt(colors.length);
      } while (usedIndices.contains(index));
      usedIndices.add(index);
      centroids.add([
        colors[index][0].toDouble(),
        colors[index][1].toDouble(),
        colors[index][2].toDouble(),
      ]);
    }

    // Iterate để tìm optimal centroids
    List<List<double>>? oldCentroids;
    int iterations = 0;
    const maxIterations = 50;

    while (iterations < maxIterations) {
      // Assign mỗi màu vào cluster gần nhất
      final clusters = List.generate(k, (_) => <List<int>>[]);
      
      for (var color in colors) {
        int nearestCluster = 0;
        double minDistance = double.infinity;
        
        for (int i = 0; i < k; i++) {
          final distance = _euclideanDistance(
            [color[0].toDouble(), color[1].toDouble(), color[2].toDouble()],
            centroids[i],
          );
          if (distance < minDistance) {
            minDistance = distance;
            nearestCluster = i;
          }
        }
        clusters[nearestCluster].add(color);
      }

      // Update centroids
      oldCentroids = List.from(centroids);
      for (int i = 0; i < k; i++) {
        if (clusters[i].isNotEmpty) {
          final avg = _averageColor(clusters[i]);
          centroids[i] = [avg[0].toDouble(), avg[1].toDouble(), avg[2].toDouble()];
        }
      }

      // Kiểm tra convergence
      bool converged = true;
      for (int i = 0; i < k; i++) {
        if (_euclideanDistance(centroids[i], oldCentroids![i]) > 1.0) {
          converged = false;
          break;
        }
      }
      
      if (converged) break;
      iterations++;
    }

    // Trả về centroids dưới dạng RGB integers
    return centroids.map((c) => [c[0].round(), c[1].round(), c[2].round()]).toList();
  }

  /// Phân loại một màu vào một trong 6 cluster
  /// [r, g, b]: Màu cần phân loại
  /// [clusters]: 6 cluster centroids từ K-Means
  /// [colorMap]: Map từ cluster index sang CubeColor
  static CubeColor? classify(
    int r,
    int g,
    int b,
    List<List<int>> clusters,
    Map<int, CubeColor> colorMap,
  ) {
    if (clusters.isEmpty) return null;

    // Tìm cluster gần nhất
    int nearestCluster = 0;
    double minDistance = double.infinity;
    
    final color = [r.toDouble(), g.toDouble(), b.toDouble()];
    
    for (int i = 0; i < clusters.length; i++) {
      final cluster = [
        clusters[i][0].toDouble(),
        clusters[i][1].toDouble(),
        clusters[i][2].toDouble(),
      ];
      final distance = _euclideanDistance(color, cluster);
      if (distance < minDistance) {
        minDistance = distance;
        nearestCluster = i;
      }
    }

    return colorMap[nearestCluster];
  }

  /// Tự động map 6 clusters sang 6 màu Rubik
  /// Sử dụng heuristic để match cluster với màu chuẩn
  static Map<int, CubeColor> mapClustersToColors(List<List<int>> clusters) {
    if (clusters.length != 6) {
      throw Exception('Phải có đúng 6 clusters');
    }

    // Màu chuẩn của Rubik (RGB)
    final standardColors = {
      CubeColor.white: [255, 255, 255],
      CubeColor.red: [220, 30, 30],
      CubeColor.blue: [0, 80, 220],
      CubeColor.orange: [255, 130, 0],
      CubeColor.green: [0, 170, 0],
      CubeColor.yellow: [255, 230, 0],
    };

    final mapping = <int, CubeColor>{};
    final usedColors = <CubeColor>{};

    // Match mỗi cluster với màu chuẩn gần nhất
    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      CubeColor? bestMatch;
      double minDistance = double.infinity;

      for (var entry in standardColors.entries) {
        if (usedColors.contains(entry.key)) continue;

        final distance = _euclideanDistance(
          [cluster[0].toDouble(), cluster[1].toDouble(), cluster[2].toDouble()],
          [entry.value[0].toDouble(), entry.value[1].toDouble(), entry.value[2].toDouble()],
        );

        if (distance < minDistance) {
          minDistance = distance;
          bestMatch = entry.key;
        }
      }

      if (bestMatch != null) {
        mapping[i] = bestMatch;
        usedColors.add(bestMatch);
      }
    }

    return mapping;
  }

  /// Tính Euclidean distance giữa 2 màu RGB
  static double _euclideanDistance(List<double> color1, List<double> color2) {
    return math.sqrt(
      math.pow(color1[0] - color2[0], 2) +
      math.pow(color1[1] - color2[1], 2) +
      math.pow(color1[2] - color2[2], 2)
    );
  }

  /// Tính trung bình của một danh sách màu
  static List<int> _averageColor(List<List<int>> colors) {
    if (colors.isEmpty) return [128, 128, 128];
    
    int sumR = 0, sumG = 0, sumB = 0;
    for (var color in colors) {
      sumR += color[0];
      sumG += color[1];
      sumB += color[2];
    }
    
    return [
      (sumR / colors.length).round(),
      (sumG / colors.length).round(),
      (sumB / colors.length).round(),
    ];
  }
}
