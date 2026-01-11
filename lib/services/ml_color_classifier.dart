import 'dart:math' as math;
import '../models/rubik_cube.dart';

/// Machine Learning-based Color Classifier
/// Sử dụng K-Nearest Neighbors (KNN) và Simple Neural Network
class MLColorClassifier {
  // Training data: RGB values của các màu Rubik chuẩn
  // Mỗi màu có nhiều samples để cover các điều kiện ánh sáng khác nhau
  static final Map<CubeColor, List<List<double>>> _trainingData = {
    CubeColor.white: [
      [255, 255, 255], [250, 250, 250], [240, 240, 240], [230, 230, 230],
      [245, 245, 245], [235, 235, 235], [225, 225, 225], [220, 220, 220],
    ],
    CubeColor.red: [
      [220, 30, 30], [200, 20, 20], [180, 15, 15], [240, 40, 40],
      [210, 25, 25], [190, 18, 18], [230, 35, 35], [250, 45, 45],
    ],
    CubeColor.blue: [
      [0, 80, 220], [0, 70, 200], [0, 60, 180], [0, 90, 240],
      [0, 75, 210], [0, 65, 190], [0, 85, 230], [0, 95, 250],
    ],
    CubeColor.orange: [
      [255, 130, 0], [255, 110, 0], [240, 100, 0], [255, 150, 20],
      [250, 120, 5], [245, 105, 2], [255, 140, 10], [255, 160, 25],
    ],
    CubeColor.green: [
      [0, 170, 0], [0, 150, 0], [0, 130, 0], [0, 190, 20],
      [0, 160, 5], [0, 140, 2], [0, 180, 15], [0, 200, 25],
    ],
    CubeColor.yellow: [
      [255, 230, 0], [255, 210, 0], [240, 190, 0], [255, 250, 30],
      [250, 220, 5], [245, 200, 2], [255, 240, 15], [255, 255, 35],
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

