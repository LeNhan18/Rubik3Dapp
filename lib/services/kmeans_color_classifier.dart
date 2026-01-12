import 'dart:math' as math;
import '../models/rubik_cube.dart';
import 'color_utils.dart';

/// K-Means Clustering Color Classifier - Phiên bản cải tiến
class KMeansColorClassifier {
  /// Chạy K-Means++ clustering để tìm 6 màu chính
  /// K-Means++ cho kết quả ổn định hơn random initialization
  static List<List<int>> findClusters(List<List<int>> colors, {int k = 6}) {
    if (colors.isEmpty) return [];
    if (colors.length < k) {
      final avg = _averageColor(colors);
      return List.generate(k, (_) => avg);
    }

    // Lọc outliers trước (loại bỏ pixel quá sáng/tối)
    final filtered = _filterOutliers(colors);
    if (filtered.length < k) {
      return findClusters(colors, k: k); // Fallback nếu lọc quá mạnh
    }

    // K-Means++ initialization (tốt hơn random)
    List<List<double>> centroids = _initializeKMeansPlusPlus(filtered, k);

    // Iterate để tìm optimal centroids
    int iterations = 0;
    const maxIterations = 100; // Tăng số iterations

    while (iterations < maxIterations) {
      // Assign mỗi màu vào cluster gần nhất (dùng LAB space)
      final clusters = List.generate(k, (_) => <List<int>>[]);

      for (var color in filtered) {
        int nearestCluster = 0;
        double minDistance = double.infinity;

        final colorLab = ColorUtils.rgbToLab(color[0], color[1], color[2]);

        for (int i = 0; i < k; i++) {
          final centroidLab = ColorUtils.rgbToLab(
            centroids[i][0].round(),
            centroids[i][1].round(),
            centroids[i][2].round(),
          );
          final distance = ColorUtils.labDistance(colorLab, centroidLab);

          if (distance < minDistance) {
            minDistance = distance;
            nearestCluster = i;
          }
        }
        clusters[nearestCluster].add(color);
      }

      // Update centroids (dùng median thay vì mean để chống outliers)
      List<List<double>> oldCentroids = List.from(centroids);
      for (int i = 0; i < k; i++) {
        if (clusters[i].isNotEmpty) {
          final median = _medianColor(clusters[i]);
          centroids[i] = [
            median[0].toDouble(),
            median[1].toDouble(),
            median[2].toDouble()
          ];
        }
      }

      // Kiểm tra convergence
      bool converged = true;
      for (int i = 0; i < k; i++) {
        if (_euclideanDistance(centroids[i], oldCentroids[i]) > 0.5) {
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

  /// K-Means++ initialization - ổn định hơn random
  static List<List<double>> _initializeKMeansPlusPlus(
      List<List<int>> colors,
      int k,
      ) {
    final random = math.Random(42); // Seed cố định cho reproducibility
    final centroids = <List<double>>[];

    // Chọn centroid đầu tiên ngẫu nhiên
    final firstColor = colors[random.nextInt(colors.length)];
    centroids.add([
      firstColor[0].toDouble(),
      firstColor[1].toDouble(),
      firstColor[2].toDouble(),
    ]);

    // Chọn các centroid tiếp theo xa nhất với các centroid hiện tại
    for (int i = 1; i < k; i++) {
      final distances = <double>[];

      for (var color in colors) {
        double minDist = double.infinity;
        final colorVec = [
          color[0].toDouble(),
          color[1].toDouble(),
          color[2].toDouble()
        ];

        for (var centroid in centroids) {
          final dist = _euclideanDistance(colorVec, centroid);
          if (dist < minDist) minDist = dist;
        }
        distances.add(minDist);
      }

      // Chọn màu có khoảng cách lớn nhất
      final maxDistIndex = distances.indexOf(distances.reduce(math.max));
      centroids.add([
        colors[maxDistIndex][0].toDouble(),
        colors[maxDistIndex][1].toDouble(),
        colors[maxDistIndex][2].toDouble(),
      ]);
    }

    return centroids;
  }

  /// Lọc outliers (pixel quá sáng, quá tối, hoặc quá xa median)
  static List<List<int>> _filterOutliers(List<List<int>> colors) {
    if (colors.length < 10) return colors;

    // Tính brightness trung bình
    final brightnesses = colors.map((c) =>
    (c[0] + c[1] + c[2]) / 3
    ).toList();

    brightnesses.sort();
    final medianBrightness = brightnesses[brightnesses.length ~/ 2];

    // Lọc pixel có brightness quá xa median (>40%)
    return colors.where((color) {
      final brightness = (color[0] + color[1] + color[2]) / 3;
      final diff = (brightness - medianBrightness).abs();
      return diff < medianBrightness * 0.4;
    }).toList();
  }

  /// Dùng median thay vì mean để chống outliers
  static List<int> _medianColor(List<List<int>> colors) {
    if (colors.isEmpty) return [128, 128, 128];
    if (colors.length == 1) return colors[0];

    final reds = colors.map((c) => c[0]).toList()..sort();
    final greens = colors.map((c) => c[1]).toList()..sort();
    final blues = colors.map((c) => c[2]).toList()..sort();

    final mid = colors.length ~/ 2;
    return [reds[mid], greens[mid], blues[mid]];
  }

  /// Phân loại một màu vào một trong 6 cluster
  static CubeColor? classify(
      int r,
      int g,
      int b,
      List<List<int>> clusters,
      Map<int, CubeColor> colorMap,
      ) {
    if (clusters.isEmpty) return null;

    final colorLab = ColorUtils.rgbToLab(r, g, b);

    int nearestCluster = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < clusters.length; i++) {
      final clusterLab = ColorUtils.rgbToLab(
        clusters[i][0],
        clusters[i][1],
        clusters[i][2],
      );
      final distance = ColorUtils.labDistance(colorLab, clusterLab);
      if (distance < minDistance) {
        minDistance = distance;
        nearestCluster = i;
      }
    }

    return colorMap[nearestCluster];
  }

  /// Tự động map 6 clusters sang 6 màu Rubik với scoring
  static Map<int, CubeColor> mapClustersToColors(List<List<int>> clusters) {
    if (clusters.length != 6) {
      throw Exception('Phải có đúng 6 clusters');
    }

    // Màu chuẩn của Rubik (RGB) - điều chỉnh cho phù hợp với ánh sáng thực tế
    final standardColors = {
      CubeColor.white: [240, 240, 240],    // Trắng có thể hơi xám
      CubeColor.yellow: [255, 220, 0],     // Vàng
      CubeColor.red: [200, 30, 30],        // Đỏ
      CubeColor.orange: [255, 120, 0],     // Cam
      CubeColor.blue: [0, 70, 200],        // Xanh dương
      CubeColor.green: [0, 155, 0],        // Xanh lá
    };

    // Tính score cho mỗi cặp (cluster, color) - ưu tiên màu tương phản
    final scores = <Map<String, dynamic>>[];

    for (int i = 0; i < clusters.length; i++) {
      final clusterLab = ColorUtils.rgbToLab(
        clusters[i][0],
        clusters[i][1],
        clusters[i][2],
      );

      for (var entry in standardColors.entries) {
        final standardLab = ColorUtils.rgbToLab(
          entry.value[0],
          entry.value[1],
          entry.value[2],
        );
        final distance = ColorUtils.labDistance(clusterLab, standardLab);

        scores.add({
          'cluster': i,
          'color': entry.key,
          'distance': distance,
        });
      }
    }

    // Sắp xếp theo distance và assign
    scores.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    final mapping = <int, CubeColor>{};
    final usedClusters = <int>{};
    final usedColors = <CubeColor>{};

    for (var score in scores) {
      final cluster = score['cluster'] as int;
      final color = score['color'] as CubeColor;

      if (!usedClusters.contains(cluster) && !usedColors.contains(color)) {
        mapping[cluster] = color;
        usedClusters.add(cluster);
        usedColors.add(color);
      }

      if (mapping.length == 6) break;
    }

    return mapping;
  }

  /// Validate mapping bằng cách kiểm tra độ tương phản
  static bool validateMapping(
      List<List<int>> clusters,
      Map<int, CubeColor> mapping,
      ) {
    // Kiểm tra màu đối diện có đủ tương phản không
    final oppositePairs = [
      [CubeColor.white, CubeColor.yellow],
      [CubeColor.red, CubeColor.orange],
      [CubeColor.blue, CubeColor.green],
    ];

    for (var pair in oppositePairs) {
      final cluster1 = mapping.entries
          .firstWhere((e) => e.value == pair[0], orElse: () => MapEntry(-1, pair[0]))
          .key;
      final cluster2 = mapping.entries
          .firstWhere((e) => e.value == pair[1], orElse: () => MapEntry(-1, pair[1]))
          .key;

      if (cluster1 == -1 || cluster2 == -1) return false;

      final lab1 = ColorUtils.rgbToLab(
        clusters[cluster1][0],
        clusters[cluster1][1],
        clusters[cluster1][2],
      );
      final lab2 = ColorUtils.rgbToLab(
        clusters[cluster2][0],
        clusters[cluster2][1],
        clusters[cluster2][2],
      );

      // Khoảng cách tối thiểu giữa các màu đối diện
      if (ColorUtils.labDistance(lab1, lab2) < 20) {
        return false;
      }
    }

    return true;
  }

  static double _euclideanDistance(List<double> color1, List<double> color2) {
    return math.sqrt(
        math.pow(color1[0] - color2[0], 2) +
            math.pow(color1[1] - color2[1], 2) +
            math.pow(color1[2] - color2[2], 2)
    );
  }

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