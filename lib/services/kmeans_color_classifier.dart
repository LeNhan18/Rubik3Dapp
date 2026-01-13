import 'dart:math' as math;
import '../models/rubik_cube.dart';
import 'color_utils.dart';

/// K-Means Clustering Color Classifier - Phiên bản cải tiến
class KMeansColorClassifier {
  /// Chạy K-Means++ clustering để tìm 6 màu chính
  /// Chạy nhiều lần và chọn kết quả tốt nhất (tối ưu hơn)
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

    // Chạy K-Means nhiều lần và chọn kết quả tốt nhất
    List<List<int>>? bestClusters;
    double bestScore = -1;
    
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final clusters = _runKMeans(filtered, k);
        final score = _scoreClusters(clusters, filtered);
        
        if (score > bestScore) {
          bestScore = score;
          bestClusters = clusters;
        }
      } catch (e) {
        continue;
      }
    }

    return bestClusters ?? _runKMeans(filtered, k);
  }

  /// Chạy một lần K-Means
  static List<List<int>> _runKMeans(List<List<int>> colors, int k) {
    // K-Means++ initialization (tốt hơn random)
    List<List<double>> centroids = _initializeKMeansPlusPlus(colors, k);

    // Iterate để tìm optimal centroids
    int iterations = 0;
    const maxIterations = 50; // Giảm xuống 50 để nhanh hơn

    while (iterations < maxIterations) {
      // Assign mỗi màu vào cluster gần nhất (dùng LAB space)
      final clusters = List.generate(k, (_) => <List<int>>[]);

      for (var color in colors) {
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
        if (_euclideanDistance(centroids[i], oldCentroids[i]) > 1.0) {
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

  /// Score clusters dựa trên độ phân tán (clusters càng xa nhau càng tốt)
  static double _scoreClusters(List<List<int>> clusters, List<List<int>> colors) {
    if (clusters.length < 2) return 0;
    
    // Tính khoảng cách trung bình giữa các clusters
    double totalDistance = 0;
    int pairCount = 0;
    
    for (int i = 0; i < clusters.length; i++) {
      for (int j = i + 1; j < clusters.length; j++) {
        final lab1 = ColorUtils.rgbToLab(clusters[i][0], clusters[i][1], clusters[i][2]);
        final lab2 = ColorUtils.rgbToLab(clusters[j][0], clusters[j][1], clusters[j][2]);
        totalDistance += ColorUtils.labDistance(lab1, lab2);
        pairCount++;
      }
    }
    
    return pairCount > 0 ? totalDistance / pairCount : 0;
  }

  /// K-Means++ initialization - ổn định hơn random
  static List<List<double>> _initializeKMeansPlusPlus(
      List<List<int>> colors,
      int k,
      ) {
    final random = math.Random(); // Không dùng seed cố định để đa dạng hơn
    final centroids = <List<double>>[];

    // Chọn centroid đầu tiên ngẫu nhiên
    final firstColor = colors[random.nextInt(colors.length)];
    centroids.add([
      firstColor[0].toDouble(),
      firstColor[1].toDouble(),
      firstColor[2].toDouble(),
    ]);

    // Chọn các centroid tiếp theo xa nhất với các centroid hiện tại (dùng LAB space)
    for (int i = 1; i < k; i++) {
      final distances = <double>[];

      for (var color in colors) {
        double minDist = double.infinity;
        final colorLab = ColorUtils.rgbToLab(color[0], color[1], color[2]);

        for (var centroid in centroids) {
          final centroidLab = ColorUtils.rgbToLab(
            centroid[0].round(),
            centroid[1].round(),
            centroid[2].round(),
          );
          final dist = ColorUtils.labDistance(colorLab, centroidLab);
          if (dist < minDist) minDist = dist;
        }
        distances.add(minDist);
      }

      // Chọn màu có khoảng cách lớn nhất (weighted random để tránh outliers)
      final maxDist = distances.reduce(math.max);
      final candidates = <int>[];
      for (int j = 0; j < distances.length; j++) {
        if (distances[j] >= maxDist * 0.8) {
          candidates.add(j);
        }
      }
      
      final selectedIndex = candidates[random.nextInt(candidates.length)];
      centroids.add([
        colors[selectedIndex][0].toDouble(),
        colors[selectedIndex][1].toDouble(),
        colors[selectedIndex][2].toDouble(),
      ]);
    }

    return centroids;
  }

  /// Lọc outliers (pixel quá sáng, quá tối, hoặc quá xa median)
  /// Cải thiện: lọc tốt hơn để giữ lại màu sắc đa dạng
  static List<List<int>> _filterOutliers(List<List<int>> colors) {
    if (colors.length < 10) return colors;

    // Tính brightness và saturation
    final stats = colors.map((c) {
      final r = c[0];
      final g = c[1];
      final b = c[2];
      final brightness = (r + g + b) / 3.0;
      final maxColor = math.max(math.max(r, g), b);
      final minColor = math.min(math.min(r, g), b);
      final saturation = maxColor == 0 ? 0.0 : (maxColor - minColor) / maxColor;
      return {'brightness': brightness, 'saturation': saturation, 'color': c};
    }).toList();

    // Tính median brightness
    final brightnesses = stats.map((s) => s['brightness'] as double).toList()..sort();
    final medianBrightness = brightnesses[brightnesses.length ~/ 2];

    // Lọc: giữ lại màu có brightness hợp lý VÀ có saturation (không phải xám)
    return stats.where((stat) {
      final brightness = stat['brightness'] as double;
      final saturation = stat['saturation'] as double;
      final diff = (brightness - medianBrightness).abs();
      
      // Giữ lại nếu:
      // 1. Brightness không quá xa median (50% thay vì 40%)
      // 2. Hoặc có saturation cao (là màu thật, không phải xám)
      return diff < medianBrightness * 0.5 || saturation > 0.15;
    }).map((stat) => stat['color'] as List<int>).toList();
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
  /// Trả về null nếu distance quá xa (không chắc chắn)
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
    double secondMinDistance = double.infinity;

    for (int i = 0; i < clusters.length; i++) {
      final clusterLab = ColorUtils.rgbToLab(
        clusters[i][0],
        clusters[i][1],
        clusters[i][2],
      );
      final distance = ColorUtils.labDistance(colorLab, clusterLab);
      if (distance < minDistance) {
        secondMinDistance = minDistance;
        minDistance = distance;
        nearestCluster = i;
      } else if (distance < secondMinDistance) {
        secondMinDistance = distance;
      }
    }

    // Chỉ chấp nhận nếu min distance rõ ràng hơn second (ít nhất 30% chênh lệch)
    if (secondMinDistance > 0 && minDistance / secondMinDistance > 0.7) {
      return null; // Không chắc chắn
    }

    // Chỉ chấp nhận nếu distance không quá xa (threshold = 50 Delta E)
    if (minDistance > 50) {
      return null;
    }

    return colorMap[nearestCluster];
  }

  /// Tự động map 6 clusters sang 6 màu Rubik với scoring
  static Map<int, CubeColor> mapClustersToColors(List<List<int>> clusters) {
    if (clusters.length != 6) {
      throw Exception('Phải có đúng 6 clusters');
    }

    // Màu chuẩn của Rubik (RGB) - điều chỉnh cho phù hợp với ánh sáng thực tế
    // Sử dụng nhiều biến thể cho mỗi màu để tăng độ chính xác
    final standardColors = {
      CubeColor.white: [
        [240, 240, 240], [250, 250, 250], [230, 230, 230], [245, 245, 245],
      ],
      CubeColor.yellow: [
        [255, 220, 0], [255, 210, 0], [255, 230, 10], [250, 215, 5],
      ],
      CubeColor.red: [
        [200, 30, 30], [220, 25, 25], [180, 20, 20], [210, 28, 28],
      ],
      CubeColor.orange: [
        [255, 120, 0], [255, 110, 0], [255, 130, 5], [250, 115, 2],
      ],
      CubeColor.blue: [
        [0, 70, 200], [0, 75, 210], [0, 65, 190], [5, 72, 205],
      ],
      CubeColor.green: [
        [0, 155, 0], [0, 160, 5], [0, 150, 2], [3, 157, 3],
      ],
    };

    // Tính score cho mỗi cặp (cluster, color) - dùng min distance từ tất cả biến thể
    final scores = <Map<String, dynamic>>[];

    for (int i = 0; i < clusters.length; i++) {
      final clusterLab = ColorUtils.rgbToLab(
        clusters[i][0],
        clusters[i][1],
        clusters[i][2],
      );

      for (var entry in standardColors.entries) {
        // Tính min distance từ cluster đến tất cả biến thể của màu này
        double minDistance = double.infinity;
        for (var variant in entry.value) {
          final variantLab = ColorUtils.rgbToLab(variant[0], variant[1], variant[2]);
          final distance = ColorUtils.labDistance(clusterLab, variantLab);
          if (distance < minDistance) {
            minDistance = distance;
          }
        }

        scores.add({
          'cluster': i,
          'color': entry.key,
          'distance': minDistance,
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