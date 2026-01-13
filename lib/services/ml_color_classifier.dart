import 'dart:math' as math;
import '../models/rubik_cube.dart';

/// Machine Learning-based Color Classifier
/// Sử dụng K-Nearest Neighbors (KNN) và Simple Neural Network
class MLColorClassifier {
  // Training data: RGB values của các màu Rubik chuẩn
  // Mỗi màu có nhiều samples để cover các điều kiện ánh sáng khác nhau
  static final Map<CubeColor, List<List<double>>> _trainingData = {
    CubeColor.white: [
      // Trắng - nhiều biến thể với độ sáng khác nhau
      [255, 255, 255], [250, 250, 250], [240, 240, 240], [230, 230, 230],
      [245, 245, 245], [235, 235, 235], [225, 225, 225], [220, 220, 220],
      [248, 248, 248], [242, 242, 242], [238, 238, 238], [232, 232, 232],
      [228, 228, 228], [218, 218, 218], [215, 215, 215], [210, 210, 210],
    ],
    CubeColor.red: [
      // Đỏ - nhiều biến thể
      [220, 30, 30], [200, 20, 20], [180, 15, 15], [240, 40, 40],
      [210, 25, 25], [190, 18, 18], [230, 35, 35], [250, 45, 45],
      [215, 28, 28], [205, 22, 22], [195, 16, 16], [235, 38, 38],
      [225, 32, 32], [185, 12, 12], [245, 42, 42], [255, 50, 50],
    ],
    CubeColor.blue: [
      // Xanh dương - nhiều biến thể
      [0, 80, 220], [0, 70, 200], [0, 60, 180], [0, 90, 240],
      [0, 75, 210], [0, 65, 190], [0, 85, 230], [0, 95, 250],
      [5, 82, 215], [3, 72, 205], [2, 62, 185], [8, 92, 235],
      [6, 77, 212], [4, 67, 192], [7, 87, 225], [10, 97, 245],
    ],
    CubeColor.orange: [
      // Cam - QUAN TRỌNG: phải phân biệt rõ với vàng và đỏ
      [255, 130, 0], [255, 110, 0], [240, 100, 0], [255, 150, 20],
      [250, 120, 5], [245, 105, 2], [255, 140, 10], [255, 160, 25],
      [255, 125, 3], [255, 115, 1], [245, 108, 1], [255, 145, 15],
      [252, 122, 4], [247, 107, 1], [255, 135, 8], [255, 155, 22],
      // Cam tối hơn (trong điều kiện ánh sáng yếu)
      [230, 100, 0], [220, 90, 0], [210, 85, 0], [240, 110, 5],
      [225, 95, 0], [215, 88, 0], [235, 105, 3], [245, 120, 10],
    ],
    CubeColor.green: [
      // Xanh lá - nhiều biến thể
      [0, 170, 0], [0, 150, 0], [0, 130, 0], [0, 190, 20],
      [0, 160, 5], [0, 140, 2], [0, 180, 15], [0, 200, 25],
      [3, 165, 3], [2, 155, 2], [1, 135, 1], [5, 185, 18],
      [4, 162, 4], [2, 142, 1], [4, 175, 12], [6, 195, 22],
    ],
    CubeColor.yellow: [
      // Vàng - QUAN TRỌNG: phải phân biệt rõ với cam và trắng
      [255, 230, 0], [255, 210, 0], [240, 190, 0], [255, 250, 30],
      [250, 220, 5], [245, 200, 2], [255, 240, 15], [255, 255, 35],
      [255, 225, 3], [255, 205, 1], [245, 195, 1], [255, 245, 25],
      [252, 215, 4], [247, 202, 1], [255, 235, 12], [255, 252, 32],
      // Vàng sáng hơn (gần trắng nhưng vẫn có màu)
      [255, 245, 100], [255, 240, 80], [250, 235, 70], [255, 250, 120],
      [253, 242, 90], [248, 238, 75], [255, 247, 110], [255, 252, 130],
    ],
  };

  // Normalize RGB values về [0, 1] để ML model hoạt động tốt hơn
  static List<double> _normalizeRgb(int r, int g, int b) {
    return [r / 255.0, g / 255.0, b / 255.0];
  }

  /// K-Nearest Neighbors (KNN) Classifier
  /// Tìm K neighbors gần nhất và vote cho màu xuất hiện nhiều nhất
  static CubeColor? classifyWithKNN(int r, int g, int b, {int k = 5}) {
    final input = _normalizeRgb(r, g, b);
    
    // Tính khoảng cách đến tất cả training samples
    final distances = <_DistanceLabel>[];
    
    for (var entry in _trainingData.entries) {
      final color = entry.key;
      final samples = entry.value;
      
      for (var sample in samples) {
        final normalized = _normalizeRgb(
          sample[0].toInt(),
          sample[1].toInt(),
          sample[2].toInt(),
        );
        
        // Euclidean distance
        final distance = math.sqrt(
          math.pow(input[0] - normalized[0], 2) +
          math.pow(input[1] - normalized[1], 2) +
          math.pow(input[2] - normalized[2], 2)
        );
        
        distances.add(_DistanceLabel(distance, color));
      }
    }
    
    // Sắp xếp theo distance và lấy K nearest
    distances.sort((a, b) => a.distance.compareTo(b.distance));
    final kNearest = distances.take(k).toList();
    
    // Vote: đếm số lần xuất hiện của mỗi màu trong K nearest
    final votes = <CubeColor, int>{};
    for (var item in kNearest) {
      votes[item.label] = (votes[item.label] ?? 0) + 1;
    }
    
    // Tìm màu có nhiều vote nhất
    CubeColor? winner;
    int maxVotes = 0;
    for (var entry in votes.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winner = entry.key;
      }
    }
    
    // Chỉ chấp nhận nếu có ít nhất 2/5 votes (confidence threshold)
    if (maxVotes >= (k * 0.4).ceil()) {
      return winner;
    }
    
    return null;
  }

  /// Simple Neural Network Classifier
  /// Single-layer perceptron với weights được tính từ training data
  static CubeColor? classifyWithNeuralNetwork(int r, int g, int b) {
    final input = _normalizeRgb(r, g, b);
    
    // Tính confidence score cho mỗi màu
    final scores = <CubeColor, double>{};
    
    for (var entry in _trainingData.entries) {
      final color = entry.key;
      final samples = entry.value;
      
      // Tính trung bình của tất cả samples cho màu này (centroid)
      double sumR = 0, sumG = 0, sumB = 0;
      for (var sample in samples) {
        sumR += sample[0];
        sumG += sample[1];
        sumB += sample[2];
      }
      final centroid = [
        sumR / samples.length / 255.0,
        sumG / samples.length / 255.0,
        sumB / samples.length / 255.0,
      ];
      
      // Tính similarity score (inverse distance)
      final distance = math.sqrt(
        math.pow(input[0] - centroid[0], 2) +
        math.pow(input[1] - centroid[1], 2) +
        math.pow(input[2] - centroid[2], 2)
      );
      
      // Convert distance to similarity score (closer = higher score)
      final similarity = 1.0 / (1.0 + distance * 10);
      scores[color] = similarity;
    }
    
    // Tìm màu có score cao nhất
    CubeColor? winner;
    double maxScore = 0;
    for (var entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        winner = entry.key;
      }
    }
    
    // Confidence threshold: chỉ chấp nhận nếu score > 0.3
    if (maxScore > 0.3) {
      return winner;
    }
    
    return null;
  }

  /// Ensemble Method: Kết hợp KNN và Neural Network
  /// Vote từ cả 2 methods để tăng độ chính xác
  static CubeColor? classifyEnsemble(int r, int g, int b) {
    final knnResult = classifyWithKNN(r, g, b, k: 7);
    final nnResult = classifyWithNeuralNetwork(r, g, b);
    
    // Nếu cả 2 methods đồng ý, return kết quả
    if (knnResult != null && nnResult != null && knnResult == nnResult) {
      return knnResult;
    }
    
    // Nếu chỉ 1 method có kết quả, return nó
    if (knnResult != null) return knnResult;
    if (nnResult != null) return nnResult;
    
    return null;
  }

  /// Main classification method - sử dụng Ensemble
  static CubeColor? classify(int r, int g, int b) {
    // Lọc màu quá tối
    final brightness = (r + g + b) / 3.0;
    if (brightness < 30) {
      return null;
    }
    
    return classifyEnsemble(r, g, b);
  }
}

/// Helper class để lưu distance và label
class _DistanceLabel {
  final double distance;
  final CubeColor label;
  
  _DistanceLabel(this.distance, this.label);
}

