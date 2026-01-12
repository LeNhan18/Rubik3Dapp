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
    // Decode ảnh
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

        // Lấy 30 pixel từ mỗi vùng (270 pixels tổng)
        final regionColors = _getColorsFromRegion(
          processedImage, x1, y1, x2, y2,
          sampleCount: 30
        );
        allColors.addAll(regionColors);
      }
    }

    // BƯỚC 2: Chạy K-Means để tìm 6 cluster màu chính
    final clusters = KMeansColorClassifier.findClusters(allColors, k: 6);

    // BƯỚC 3: Map clusters sang màu Rubik (dùng LAB color space)
    final colorMap = KMeansColorClassifier.mapClustersToColors(clusters);

    // BƯỚC 4: Multi-Pass Voting - scan nhiều lần với offset khác nhau
    final votes = <String, Map<CubeColor, int>>{};
    final offsets = [
      [0, 0],      // Không offset
      [-3, -3],    // Offset nhỏ
      [3, 3],      // Offset ngược lại
      [-2, 2],     // Offset chéo
      [2, -2],     // Offset chéo ngược
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
          final finalColor = mlResult ?? kmeansResult;

          if (finalColor != null) {
            votes.putIfAbsent(key, () => <CubeColor, int>{});
            votes[key]![finalColor] = (votes[key]![finalColor] ?? 0) + 1;
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
          // Chỉ chấp nhận nếu có ít nhất 3/5 votes (60% confidence)
          faceRow.add(maxVotes >= 3 ? winner : null);
        }
      }
      face.add(faceRow);
    }

    return face;
  }


  /// Áp dụng Auto White Balance để chuẩn hóa màu theo ánh sáng
  static img.Image _applyAutoWhiteBalance(img.Image image) {
    // Tính trung bình RGB của toàn bộ ảnh
    double rSum = 0, gSum = 0, bSum = 0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r is int) ? pixel.r : (pixel.r as num).toInt();
        final g = (pixel.g is int) ? pixel.g : (pixel.g as num).toInt();
        final b = (pixel.b is int) ? pixel.b : (pixel.b as num).toInt();

        rSum += r;
        gSum += g;
        bSum += b;
        pixelCount++;
      }
    }

    if (pixelCount == 0) return image;

    final avgR = rSum / pixelCount;
    final avgG = gSum / pixelCount;
    final avgB = bSum / pixelCount;

    // Tính hệ số điều chỉnh để cân bằng màu về xám trung tính
    final avgGray = (avgR + avgG + avgB) / 3.0;
    final rGain = avgGray / (avgR + 0.001); // Tránh chia 0
    final gGain = avgGray / (avgG + 0.001);
    final bGain = avgGray / (avgB + 0.001);

    // Tạo ảnh mới với white balance đã áp dụng
    final balanced = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r is int) ? pixel.r : (pixel.r as num).toInt();
        final g = (pixel.g is int) ? pixel.g : (pixel.g as num).toInt();
        final b = (pixel.b is int) ? pixel.b : (pixel.b as num).toInt();

        final newR = (r * rGain).clamp(0, 255).toInt();
        final newG = (g * gGain).clamp(0, 255).toInt();
        final newB = (b * bGain).clamp(0, 255).toInt();

        balanced.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }

    return balanced;
  }

  /// Lấy màu chủ đạo từ một vùng - CẢI THIỆN: Lấy từ center region nhỏ hơn
  /// Sử dụng median thay vì histogram để tránh nhiễu
  static List<int> _getDominantColor(
    img.Image image,
    int x1, int y1, int x2, int y2
  ) {
    // Lấy từ center 50% của vùng (tránh edge và shadow)
    final centerX = (x1 + x2) ~/ 2;
    final centerY = (y1 + y2) ~/ 2;
    final regionWidth = (x2 - x1) ~/ 2;
    final regionHeight = (y2 - y1) ~/ 2;

    final sampleX1 = (centerX - regionWidth ~/ 2).clamp(x1, x2);
    final sampleY1 = (centerY - regionHeight ~/ 2).clamp(y1, y2);
    final sampleX2 = (centerX + regionWidth ~/ 2).clamp(x1, x2);
    final sampleY2 = (centerY + regionHeight ~/ 2).clamp(y1, y2);

    // Thu thập tất cả pixel từ center region
    final rValues = <int>[];
    final gValues = <int>[];
    final bValues = <int>[];

    for (int y = sampleY1; y < sampleY2 && y < image.height; y++) {
      for (int x = sampleX1; x < sampleX2 && x < image.width; x++) {
        if (x >= 0 && y >= 0) {
          final pixel = image.getPixel(x, y);
          final rValue = pixel.r;
          final gValue = pixel.g;
          final bValue = pixel.b;

          final r = (rValue is int) ? rValue : (rValue as num).toInt();
          final g = (gValue is int) ? gValue : (gValue as num).toInt();
          final b = (bValue is int) ? bValue : (bValue as num).toInt();

          // Lọc màu quá tối
          final brightness = (r + g + b) / 3.0;
          if (brightness < 30) continue;

          rValues.add(r);
          gValues.add(g);
          bValues.add(b);
        }
      }
    }

    if (rValues.isEmpty) {
      // Fallback: lấy pixel ở center
      final centerPixelX = (x1 + x2) ~/ 2;
      final centerPixelY = (y1 + y2) ~/ 2;
      if (centerPixelX >= 0 && centerPixelX < image.width &&
          centerPixelY >= 0 && centerPixelY < image.height) {
        final pixel = image.getPixel(centerPixelX, centerPixelY);
        final rValue = pixel.r;
        final gValue = pixel.g;
        final bValue = pixel.b;
        return [
          (rValue is int) ? rValue : (rValue as num).toInt(),
          (gValue is int) ? gValue : (gValue as num).toInt(),
          (bValue is int) ? bValue : (bValue as num).toInt(),
        ];
      }
      return [128, 128, 128];
    }

    // Dùng median thay vì mean để tránh outliers
    rValues.sort();
    gValues.sort();
    bValues.sort();

    final medianR = rValues[rValues.length ~/ 2];
    final medianG = gValues[gValues.length ~/ 2];
    final medianB = bValues[bValues.length ~/ 2];

    return [medianR, medianG, medianB];
  }

  /// Lấy nhiều pixel từ một vùng (cho K-Means)
  static List<List<int>> _getColorsFromRegion(
    img.Image image,
    int x1, int y1, int x2, int y2,
    {int sampleCount = 20}
  ) {
    final centerX = (x1 + x2) ~/ 2;
    final centerY = (y1 + y2) ~/ 2;
    final regionWidth = (x2 - x1) ~/ 2;
    final regionHeight = (y2 - y1) ~/ 2;

    final sampleX1 = (centerX - regionWidth ~/ 2).clamp(x1, x2);
    final sampleY1 = (centerY - regionHeight ~/ 2).clamp(y1, y2);
    final sampleX2 = (centerX + regionWidth ~/ 2).clamp(x1, x2);
    final sampleY2 = (centerY + regionHeight ~/ 2).clamp(y1, y2);

    final colors = <List<int>>[];
    final stepX = ((sampleX2 - sampleX1) / math.sqrt(sampleCount)).ceil();
    final stepY = ((sampleY2 - sampleY1) / math.sqrt(sampleCount)).ceil();

    for (int y = sampleY1; y < sampleY2 && y < image.height; y += stepY) {
      for (int x = sampleX1; x < sampleX2 && x < image.width; x += stepX) {
        if (x >= 0 && y >= 0 && colors.length < sampleCount) {
          final pixel = image.getPixel(x, y);
          final rValue = pixel.r;
          final gValue = pixel.g;
          final bValue = pixel.b;
          final r = (rValue is int) ? rValue : (rValue as num).toInt();
          final g = (gValue is int) ? gValue : (gValue as num).toInt();
          final b = (bValue is int) ? bValue : (bValue as num).toInt();

          final brightness = (r + g + b) / 3.0;
          if (brightness >= 30) {
            colors.add([r, g, b]);
          }
        }
      }
    }

    return colors;
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
