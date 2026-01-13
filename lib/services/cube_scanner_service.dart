import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/rubik_cube.dart';
import 'ml_color_classifier.dart';
import 'kmeans_color_classifier.dart';

/// Service để scan và nhận diện màu từ ảnh Rubik's Cube
/// Sử dụng phương pháp Hybrid tối ưu: K-Means + ML + Multi-Pass Voting
class CubeScannerService {
  /// Scan một mặt 3x3 từ ảnh - PHƯƠNG PHÁP CHÍNH XÁC NHẤT
  /// Kết hợp K-Means (tự động phát hiện màu) + ML (phân loại chính xác) + Multi-Pass Voting
  static List<List<CubeColor?>> scanFace(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Không thể decode ảnh');
    }

    // KHÔNG dùng white balance (gây sai lệch màu)
    final processedImage = image;
    final width = processedImage.width;
    final height = processedImage.height;
    final cellWidth = width ~/ 3;
    final cellHeight = height ~/ 3;

    // BƯỚC 1: Thu thập NHIỀU pixel từ mỗi vùng cho K-Means
    final allColors = <List<int>>[];
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final x1 = col * cellWidth;
        final y1 = row * cellHeight;
        final x2 = (col + 1) * cellWidth;
        final y2 = (row + 1) * cellHeight;

        // Tăng số pixel lấy từ mỗi vùng (50 pixel thay vì 30)
        final regionColors = _getColorsFromRegion(
          processedImage, x1, y1, x2, y2,
          sampleCount: 50
        );
        allColors.addAll(regionColors);
      }
    }
    
    // Debug: In số lượng pixel đã thu thập
    print('📊 Đã thu thập ${allColors.length} pixels cho K-Means');

    // BƯỚC 2: Chạy K-Means để tìm 6 cluster màu chính
    final clusters = KMeansColorClassifier.findClusters(allColors, k: 6);
    
    if (clusters.length != 6) {
      print('⚠️ K-Means không tìm đủ 6 clusters (chỉ có ${clusters.length})');
      // Fallback: tạo clusters từ average colors
      return _fallbackScan(processedImage, width, height);
    }

    // BƯỚC 3: Map clusters sang màu Rubik (dùng LAB color space)
    final colorMap = KMeansColorClassifier.mapClustersToColors(clusters);
    
    // Validate mapping
    if (!KMeansColorClassifier.validateMapping(clusters, colorMap)) {
      print('⚠️ Color mapping không hợp lệ, retry...');
      // Retry với clusters khác
      final retryClusters = KMeansColorClassifier.findClusters(allColors, k: 6);
      if (retryClusters.length == 6) {
        final retryMap = KMeansColorClassifier.mapClustersToColors(retryClusters);
        if (KMeansColorClassifier.validateMapping(retryClusters, retryMap)) {
          return _scanWithClusters(processedImage, width, height, cellWidth, cellHeight, retryClusters, retryMap);
        }
      }
    }

    return _scanWithClusters(processedImage, width, height, cellWidth, cellHeight, clusters, colorMap);
  }

  /// Scan với clusters đã có
  static List<List<CubeColor?>> _scanWithClusters(
    img.Image processedImage,
    int width,
    int height,
    int cellWidth,
    int cellHeight,
    List<List<int>> clusters,
    Map<int, CubeColor> colorMap,
  ) {
    // BƯỚC 4: Multi-Pass Voting - scan nhiều lần với offset khác nhau
    final votes = <String, Map<CubeColor, int>>{};
    final offsets = [
      [0, 0],      // Không offset
      [-4, -4],    // Offset nhỏ
      [4, 4],      // Offset ngược lại
      [-3, 3],     // Offset chéo
      [3, -3],     // Offset chéo ngược
      [-2, 0],     // Offset ngang
      [2, 0],      // Offset ngang ngược
      [0, -2],     // Offset dọc
      [0, 2],      // Offset dọc ngược
    ];

    for (var offset in offsets) {
      final offsetX = offset[0];
      final offsetY = offset[1];

      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final key = '$row,$col';

          // Tính vùng với offset
          var x1 = col * cellWidth + offsetX;
          var y1 = row * cellHeight + offsetY;
          var x2 = (col + 1) * cellWidth + offsetX;
          var y2 = (row + 1) * cellHeight + offsetY;

          // Đảm bảo không vượt quá biên
          x1 = x1.clamp(0, width - 1);
          y1 = y1.clamp(0, height - 1);
          x2 = x2.clamp(x1 + 1, width);
          y2 = y2.clamp(y1 + 1, height);

          final dominantColor = _getDominantColor(processedImage, x1, y1, x2, y2);

          // Dùng K-Means để phân loại (chính xác hơn với LAB)
          final kmeansResult = KMeansColorClassifier.classify(
            dominantColor[0],
            dominantColor[1],
            dominantColor[2],
            clusters,
            colorMap,
          );

          // Dùng ML để refine (nếu có kết quả)
          final mlResult = MLColorClassifier.classify(
            dominantColor[0],
            dominantColor[1],
            dominantColor[2],
          );

          // Vote: Ưu tiên ML nếu có, nếu không dùng K-Means
          // Nếu cả 2 đều có kết quả và đồng ý, vote mạnh hơn (weight = 2)
          CubeColor? finalColor;
          int voteWeight = 1;
          
          if (mlResult != null && kmeansResult != null && mlResult == kmeansResult) {
            // Cả 2 đồng ý → vote mạnh hơn
            finalColor = mlResult;
            voteWeight = 2;
          } else if (mlResult != null) {
            // Chỉ ML có kết quả
            finalColor = mlResult;
            voteWeight = 1;
          } else if (kmeansResult != null) {
            // Chỉ K-Means có kết quả
            finalColor = kmeansResult;
            voteWeight = 1;
          }

          if (finalColor != null) {
            votes.putIfAbsent(key, () => <CubeColor, int>{});
            votes[key]![finalColor] = (votes[key]![finalColor] ?? 0) + voteWeight;
          }
        }
      }
    }

    // BƯỚC 5: Tạo kết quả từ votes (lấy màu có nhiều vote nhất)
    List<List<CubeColor?>> face = [];
    for (int row = 0; row < 3; row++) {
      List<CubeColor?> faceRow = [];
      for (int col = 0; col < 3; col++) {
        final key = '$row,$col';
        final cellVotes = votes[key];

        if (cellVotes == null || cellVotes.isEmpty) {
          faceRow.add(null);
        } else {
          // Lấy màu có nhiều vote nhất
          CubeColor? winner;
          int maxVotes = 0;
          for (var entry in cellVotes.entries) {
            if (entry.value > maxVotes) {
              maxVotes = entry.value;
              winner = entry.key;
            }
          }
          // Giảm threshold xuống 40% để chấp nhận nhiều trường hợp hơn
          // (vì có vote weight = 2, nên cần tính lại threshold)
          final minVotes = (offsets.length * 0.4).ceil();
          faceRow.add(maxVotes >= minVotes ? winner : null);
          
          // Debug log
          if (maxVotes < minVotes) {
            print('⚠️ Ô [$row][$col]: Không đủ confidence (${maxVotes}/${offsets.length} votes)');
          }
        }
      }
      face.add(faceRow);
    }

    return face;
  }

  /// Fallback scan khi K-Means thất bại
  static List<List<CubeColor?>> _fallbackScan(
    img.Image image,
    int width,
    int height,
  ) {
    final cellWidth = width ~/ 3;
    final cellHeight = height ~/ 3;
    final face = <List<CubeColor?>>[];
    
    for (int row = 0; row < 3; row++) {
      final faceRow = <CubeColor?>[];
      for (int col = 0; col < 3; col++) {
        final x1 = col * cellWidth;
        final y1 = row * cellHeight;
        final x2 = (col + 1) * cellWidth;
        final y2 = (row + 1) * cellHeight;
        
        final dominantColor = _getDominantColor(image, x1, y1, x2, y2);
        final mlResult = MLColorClassifier.classify(
          dominantColor[0],
          dominantColor[1],
          dominantColor[2],
        );
        
        faceRow.add(mlResult);
      }
      face.add(faceRow);
    }
    
    return face;
  }

  /// Lấy nhiều pixel từ một vùng để dùng cho K-Means
  static List<List<int>> _getColorsFromRegion(
    img.Image image,
    int x1, int y1, int x2, int y2,
    {int sampleCount = 30}
  ) {
    final centerX = (x1 + x2) ~/ 2;
    final centerY = (y1 + y2) ~/ 2;
    final regionWidth = (x2 - x1) * 0.6;
    final regionHeight = (y2 - y1) * 0.6;

    final sampleX1 = (centerX - regionWidth / 2).round().clamp(x1, x2);
    final sampleY1 = (centerY - regionHeight / 2).round().clamp(y1, y2);
    final sampleX2 = (centerX + regionWidth / 2).round().clamp(x1, x2);
    final sampleY2 = (centerY + regionHeight / 2).round().clamp(y1, y2);

    final colors = <List<int>>[];
    final stepX = math.max(1, ((sampleX2 - sampleX1) / math.sqrt(sampleCount)).ceil());
    final stepY = math.max(1, ((sampleY2 - sampleY1) / math.sqrt(sampleCount)).ceil());

    for (int y = sampleY1; y < sampleY2 && y < image.height; y += stepY) {
      for (int x = sampleX1; x < sampleX2 && x < image.width; x += stepX) {
        if (x >= 0 && y >= 0 && colors.length < sampleCount) {
          final pixel = image.getPixel(x, y);
          final r = _toInt(pixel.r);
          final g = _toInt(pixel.g);
          final b = _toInt(pixel.b);

          final brightness = (r + g + b) / 3.0;
          if (brightness >= 25 && brightness <= 245) {
            colors.add([r, g, b]);
          }
        }
      }
    }

    return colors;
  }

  /// Lấy màu chủ đạo từ một vùng - TỐI ƯU: dùng histogram để tìm màu xuất hiện nhiều nhất
  static List<int> _getDominantColor(
    img.Image image,
    int x1, int y1, int x2, int y2
  ) {
    final centerX = (x1 + x2) ~/ 2;
    final centerY = (y1 + y2) ~/ 2;
    final regionWidth = (x2 - x1) * 0.7; // Tăng lên 70% để lấy nhiều pixel hơn
    final regionHeight = (y2 - y1) * 0.7;

    final sampleX1 = (centerX - regionWidth / 2).round().clamp(x1, x2);
    final sampleY1 = (centerY - regionHeight / 2).round().clamp(y1, y2);
    final sampleX2 = (centerX + regionWidth / 2).round().clamp(x1, x2);
    final sampleY2 = (centerY + regionHeight / 2).round().clamp(y1, y2);

    // Dùng histogram với quantization để nhóm màu tương tự
    final colorHistogram = <String, List<int>>{}; // Key: "r,g,b" (quantized), Value: [sumR, sumG, sumB, count]
    const quantizeStep = 8; // Quantize mỗi 8 levels để nhóm màu tương tự

    for (int y = sampleY1; y < sampleY2 && y < image.height; y++) {
      for (int x = sampleX1; x < sampleX2 && x < image.width; x++) {
        if (x >= 0 && y >= 0) {
          final pixel = image.getPixel(x, y);
          final r = _toInt(pixel.r);
          final g = _toInt(pixel.g);
          final b = _toInt(pixel.b);

          // Lọc pixel quá tối (shadow) hoặc quá sáng (reflection)
          final brightness = (r + g + b) / 3.0;
          if (brightness < 30 || brightness > 240) continue;

          // Quantize để nhóm màu tương tự
          final qR = (r ~/ quantizeStep) * quantizeStep;
          final qG = (g ~/ quantizeStep) * quantizeStep;
          final qB = (b ~/ quantizeStep) * quantizeStep;
          final key = '$qR,$qG,$qB';

          if (colorHistogram.containsKey(key)) {
            final bucket = colorHistogram[key]!;
            final count = bucket[3];
            // Weighted average
            bucket[0] = ((bucket[0] * count + r) / (count + 1)).round();
            bucket[1] = ((bucket[1] * count + g) / (count + 1)).round();
            bucket[2] = ((bucket[2] * count + b) / (count + 1)).round();
            bucket[3] = count + 1;
          } else {
            colorHistogram[key] = [r, g, b, 1];
          }
        }
      }
    }

    if (colorHistogram.isEmpty) {
      final centerPixelX = (x1 + x2) ~/ 2;
      final centerPixelY = (y1 + y2) ~/ 2;
      if (centerPixelX >= 0 && centerPixelX < image.width &&
          centerPixelY >= 0 && centerPixelY < image.height) {
        final pixel = image.getPixel(centerPixelX, centerPixelY);
        return [_toInt(pixel.r), _toInt(pixel.g), _toInt(pixel.b)];
      }
      return [128, 128, 128];
    }

    // Tìm bucket có count lớn nhất (màu xuất hiện nhiều nhất)
    final sortedBuckets = colorHistogram.entries.toList()
      ..sort((a, b) => b.value[3].compareTo(a.value[3]));
    
    final topBucket = sortedBuckets[0];
    return [topBucket.value[0], topBucket.value[1], topBucket.value[2]];
  }

  static int _toInt(num value) {
    return (value is int) ? value : value.toInt();
  }

  /// Chuyển đổi CubeColor sang tên hiển thị
  static String getColorName(CubeColor color) {
    switch (color) {
      case CubeColor.white:
        return 'Trắng';
      case CubeColor.red:
        return 'Đỏ';
      case CubeColor.blue:
        return 'Xanh dương';
      case CubeColor.orange:
        return 'Cam';
      case CubeColor.green:
        return 'Xanh lá';
      case CubeColor.yellow:
        return 'Vàng';
    }
  }
}
