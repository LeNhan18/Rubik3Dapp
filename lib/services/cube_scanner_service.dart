import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/rubik_cube.dart';
import 'ml_color_classifier.dart';
import 'kmeans_color_classifier.dart';

/// Service để scan và nhận diện màu từ ảnh Rubik's Cube
/// Hỗ trợ nhiều phương pháp: ML, K-Means, hoặc kết hợp
class CubeScannerService {
  
  /// Standard colors for fallback matching
  static final Map<CubeColor, List<List<int>>> _standardColors = {
    CubeColor.white: [[255, 255, 255], [240, 240, 240]],
    CubeColor.red: [[183, 18, 52], [200, 30, 60]],
    CubeColor.blue: [[0, 69, 173], [20, 80, 200]],
    CubeColor.orange: [[255, 88, 0], [255, 120, 30]],
    CubeColor.green: [[0, 155, 72], [20, 180, 90]],
    CubeColor.yellow: [[255, 213, 0], [255, 230, 50]],
  };

  /// Scan một mặt 3x3 từ ảnh sử dụng Machine Learning
  static List<List<CubeColor?>> scanFaceML(Uint8List imageBytes) {
    return _scanFaceWithMethod(imageBytes, (r, g, b) => MLColorClassifier.classify(r, g, b));
  }

  /// Scan một mặt 3x3 từ ảnh sử dụng K-Means
  static List<List<CubeColor?>> scanFaceKMeans(Uint8List imageBytes) {
    // K-Means cần clusters và colorMap, sử dụng detectColor thay thế
    return _scanFaceWithMethod(imageBytes, detectColor);
  }

  /// Scan một mặt 3x3 từ ảnh sử dụng phương pháp Hybrid (ML + K-Means)
  static List<List<CubeColor?>> scanFaceHybrid(Uint8List imageBytes) {
    return _scanFaceWithMethod(imageBytes, detectColor);
  }

  /// Scan một mặt 3x3 từ ảnh (default method)
  static List<List<CubeColor?>> scanFace(Uint8List imageBytes) {
    return scanFaceML(imageBytes);
  }

  /// Internal scan method with custom color detector
  static List<List<CubeColor?>> _scanFaceWithMethod(
    Uint8List imageBytes,
    CubeColor? Function(int, int, int) colorDetector,
  ) {
    // Decode ảnh
    var image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Không thể decode ảnh');
    }

    // Kiểm tra và điều chỉnh độ sáng ảnh nếu cần
    final avgBrightness = _calculateAverageBrightness(image);
    print('📊 Độ sáng ảnh trung bình: ${avgBrightness.toStringAsFixed(1)}');
    
    if (avgBrightness < 80) {
      print('⚡ Ảnh quá tối, tăng độ sáng...');
      image = _adjustBrightness(image, 1.5);
    } else if (avgBrightness > 200) {
      print('⚡ Ảnh quá sáng, giảm độ sáng...');
      image = _adjustBrightness(image, 0.8);
    }

    return _scanFaceMultiPass(image, colorDetector);
  }

  /// Multi-pass voting: scan nhiều lần với các offset khác nhau và vote
  static List<List<CubeColor?>> _scanFaceMultiPass(
    img.Image image,
    CubeColor? Function(int, int, int) colorDetector,
  ) {
    final width = image.width;
    final height = image.height;
    final cellWidth = width ~/ 3;
    final cellHeight = height ~/ 3;
    
    // Tạo voting matrix
    final votes = <String, Map<CubeColor, int>>{};
    
    // Scan 3 lần với các offset khác nhau
    final offsets = [[0, 0], [-2, -2], [2, 2]];
    
    for (var offset in offsets) {
      final offsetX = offset[0];
      final offsetY = offset[1];
      
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final key = '$row,$col';
          
          var x1 = (col * cellWidth + offsetX).clamp(0, width - 1);
          var y1 = (row * cellHeight + offsetY).clamp(0, height - 1);
          var x2 = ((col + 1) * cellWidth + offsetX).clamp(x1 + 1, width);
          var y2 = ((row + 1) * cellHeight + offsetY).clamp(y1 + 1, height);
          
          final dominantColor = _getDominantColor(image, x1, y1, x2, y2);
          final detectedColor = colorDetector(
            dominantColor[0],
            dominantColor[1],
            dominantColor[2],
          );
          
          if (detectedColor != null) {
            votes.putIfAbsent(key, () => <CubeColor, int>{});
            votes[key]![detectedColor] = (votes[key]![detectedColor] ?? 0) + 1;
          }
        }
      }
    }
    
    // Tạo kết quả từ votes
    List<List<CubeColor?>> face = [];
    for (int row = 0; row < 3; row++) {
      List<CubeColor?> faceRow = [];
      for (int col = 0; col < 3; col++) {
        final key = '$row,$col';
        final cellVotes = votes[key];
        
        if (cellVotes == null || cellVotes.isEmpty) {
          faceRow.add(null);
        } else {
          CubeColor? winner;
          int maxVotes = 0;
          for (var entry in cellVotes.entries) {
            if (entry.value > maxVotes) {
              maxVotes = entry.value;
              winner = entry.key;
            }
          }
          faceRow.add(maxVotes >= 2 ? winner : null);
        }
      }
      face.add(faceRow);
    }
    
    // Log kết quả
    _logScanResult(face);
    return face;
  }

  /// Nhận diện màu từ RGB - phương pháp cải tiến
  static CubeColor? detectColor(int r, int g, int b) {
    final brightness = (r + g + b) / 3.0;
    if (brightness < 15) return null;
    
    // Chuyển sang HSV
    final hsv = _rgbToHsv(r, g, b);
    final h = hsv[0];
    final s = hsv[1];
    final v = hsv[2];
    
    // Trắng
    if (s < 0.25 && v > 0.65) return CubeColor.white;
    
    // Xám/Đen
    if (s < 0.15 && v < 0.35) return null;
    
    // Kiểm tra saturation tối thiểu
    if (s < 0.15) return null;
    
    // Đỏ
    if ((h >= 0 && h <= 18) || (h >= 340 && h <= 360)) return CubeColor.red;
    
    // Cam
    if (h > 18 && h <= 38) return CubeColor.orange;
    
    // Vàng
    if (h > 38 && h <= 68) {
      return v > 0.40 ? CubeColor.yellow : CubeColor.orange;
    }
    
    // Vàng-Xanh lá transition
    if (h > 68 && h <= 80) {
      return (g > r * 1.1 && g > b) ? CubeColor.green : CubeColor.yellow;
    }
    
    // Xanh lá
    if (h > 80 && h <= 165) return CubeColor.green;
    
    // Xanh lá-Xanh dương transition
    if (h > 165 && h <= 185) {
      return b > g * 1.1 ? CubeColor.blue : CubeColor.green;
    }
    
    // Xanh dương
    if (h > 185 && h <= 250) return CubeColor.blue;
    
    // Vùng tím (250-340)
    if (h > 250 && h < 340) {
      if (r > b * 1.2 && r > g) return CubeColor.red;
      if (b > r && b > g) return CubeColor.blue;
      return null;
    }
    
    // Fallback: RGB distance
    return _findClosestColorByRGB(r, g, b);
  }

  /// Tìm màu gần nhất bằng RGB distance
  static CubeColor? _findClosestColorByRGB(int r, int g, int b) {
    final maxRGB = [r, g, b].reduce((a, b) => a > b ? a : b);
    final minRGB = [r, g, b].reduce((a, b) => a < b ? a : b);
    final dominance = maxRGB - minRGB;
    
    // Component dominant rõ ràng
    if (dominance > 40) {
      if (r > g && r > b) {
        if (r > g * 1.3 && r > b * 1.3) return CubeColor.red;
        if (g > b) return CubeColor.orange;
      } else if (g > r && g > b) {
        if (g > r * 1.3 && g > b * 1.3) return CubeColor.green;
        if (r > b) return CubeColor.yellow;
      } else if (b > r && b > g) {
        if (b > r * 1.3 && b > g * 1.3) return CubeColor.blue;
      }
    }
    
    // Euclidean distance
    double minDistance = double.infinity;
    CubeColor? closestColor;
    
    for (var entry in _standardColors.entries) {
      final standard = entry.value[0];
      final dr = r - standard[0];
      final dg = g - standard[1];
      final db = b - standard[2];
      final distance = (dr * dr + dg * dg + db * db).toDouble();
      
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = entry.key;
      }
    }
    
    return minDistance < 35000 ? closestColor : null;
  }

  /// Chuyển RGB sang HSV
  static List<double> _rgbToHsv(int r, int g, int b) {
    final rNorm = r / 255.0;
    final gNorm = g / 255.0;
    final bNorm = b / 255.0;
    
    final maxC = [rNorm, gNorm, bNorm].reduce((a, b) => a > b ? a : b);
    final minC = [rNorm, gNorm, bNorm].reduce((a, b) => a < b ? a : b);
    final delta = maxC - minC;
    
    double h = 0;
    if (delta != 0) {
      if (maxC == rNorm) {
        h = 60 * (((gNorm - bNorm) / delta) % 6);
      } else if (maxC == gNorm) {
        h = 60 * (((bNorm - rNorm) / delta) + 2);
      } else {
        h = 60 * (((rNorm - gNorm) / delta) + 4);
      }
    }
    if (h < 0) h += 360;
    
    final s = maxC == 0 ? 0.0 : delta / maxC;
    final v = maxC;
    
    return [h, s, v];
  }

  /// Lấy màu chủ đạo từ một vùng
  static List<int> _getDominantColor(
    img.Image image,
    int x1, int y1, int x2, int y2,
  ) {
    final marginX = (x2 - x1) ~/ 5;
    final marginY = (y2 - y1) ~/ 5;
    
    final sampleX1 = x1 + marginX;
    final sampleY1 = y1 + marginY;
    final sampleX2 = x2 - marginX;
    final sampleY2 = y2 - marginY;
    
    final rValues = <int>[];
    final gValues = <int>[];
    final bValues = <int>[];
    final colorHistogram = <String, List<int>>{};
    
    for (int y = sampleY1; y < sampleY2 && y < image.height; y += 2) {
      for (int x = sampleX1; x < sampleX2 && x < image.width; x += 2) {
        if (x >= 0 && y >= 0) {
          final pixel = image.getPixel(x, y);
          final r = (pixel.r is int) ? pixel.r as int : (pixel.r as num).toInt();
          final g = (pixel.g is int) ? pixel.g as int : (pixel.g as num).toInt();
          final b = (pixel.b is int) ? pixel.b as int : (pixel.b as num).toInt();
          
          final brightness = (r + g + b) / 3.0;
          if (brightness < 20) continue;
          
          final maxColor = r > g ? (r > b ? r : b) : (g > b ? g : b);
          final minColor = r < g ? (r < b ? r : b) : (g < b ? g : b);
          final saturation = maxColor == 0 ? 0.0 : (maxColor - minColor) / maxColor;
          
          if (saturation < 0.05 && brightness < 80) continue;
          
          rValues.add(r);
          gValues.add(g);
          bValues.add(b);
          
          // Quantize color for histogram (bucket size 10)
          final colorKey = '${(r ~/ 10) * 10}_${(g ~/ 10) * 10}_${(b ~/ 10) * 10}';
          
          if (!colorHistogram.containsKey(colorKey)) {
            colorHistogram[colorKey] = [r, g, b, 1];
          } else {
            final bucket = colorHistogram[colorKey]!;
            final count = bucket[3];
            bucket[0] = ((bucket[0] * count + r) / (count + 1)).round();
            bucket[1] = ((bucket[1] * count + g) / (count + 1)).round();
            bucket[2] = ((bucket[2] * count + b) / (count + 1)).round();
            bucket[3] = count + 1;
          }
        }
      }
    }
    
    if (rValues.isEmpty) return [128, 128, 128];
    
    // Lấy màu xuất hiện nhiều nhất
    final sortedBuckets = colorHistogram.entries.toList()
      ..sort((a, b) => b.value[3].compareTo(a.value[3]));
    
    final topBucket = sortedBuckets[0];
    return [topBucket.value[0], topBucket.value[1], topBucket.value[2]];
  }

  /// Tính độ sáng trung bình
  static double _calculateAverageBrightness(img.Image image) {
    int totalBrightness = 0;
    int count = 0;
    
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r is int) ? pixel.r as int : (pixel.r as num).toInt();
        final g = (pixel.g is int) ? pixel.g as int : (pixel.g as num).toInt();
        final b = (pixel.b is int) ? pixel.b as int : (pixel.b as num).toInt();
        
        totalBrightness += ((r + g + b) ~/ 3);
        count++;
      }
    }
    
    return count > 0 ? totalBrightness / count : 128.0;
  }
  
  /// Điều chỉnh độ sáng
  static img.Image _adjustBrightness(img.Image image, double factor) {
    final adjusted = image.clone();
    
    for (int y = 0; y < adjusted.height; y++) {
      for (int x = 0; x < adjusted.width; x++) {
        final pixel = adjusted.getPixel(x, y);
        final r = (pixel.r is int) ? pixel.r as int : (pixel.r as num).toInt();
        final g = (pixel.g is int) ? pixel.g as int : (pixel.g as num).toInt();
        final b = (pixel.b is int) ? pixel.b as int : (pixel.b as num).toInt();
        
        final newR = (r * factor).clamp(0, 255).toInt();
        final newG = (g * factor).clamp(0, 255).toInt();
        final newB = (b * factor).clamp(0, 255).toInt();
        
        adjusted.setPixelRgba(x, y, newR, newG, newB, 255);
      }
    }
    
    return adjusted;
  }

  /// Log kết quả scan
  static void _logScanResult(List<List<CubeColor?>> face) {
    print('\n📊 KẾT QUẢ SCAN:');
    int validCount = 0;
    Map<CubeColor, int> colorCount = {};
    
    for (int r = 0; r < face.length; r++) {
      String rowStr = '';
      for (int c = 0; c < face[r].length; c++) {
        final color = face[r][c];
        if (color != null) {
          validCount++;
          colorCount[color] = (colorCount[color] ?? 0) + 1;
          rowStr += '${_getColorEmoji(color)} ';
        } else {
          rowStr += '⬛ ';
        }
      }
      print('  $rowStr');
    }
    
    print('✅ Scan được: $validCount/9 ô');
    print('📈 Phân bố màu:');
    colorCount.forEach((color, count) {
      print('   ${_getColorEmoji(color)} ${getColorName(color)}: $count');
    });
  }

  /// Lấy emoji màu
  static String _getColorEmoji(CubeColor color) {
    switch (color) {
      case CubeColor.white:
        return '⬜';
      case CubeColor.red:
        return '🟥';
      case CubeColor.blue:
        return '🟦';
      case CubeColor.orange:
        return '🟧';
      case CubeColor.green:
        return '🟩';
      case CubeColor.yellow:
        return '🟨';
    }
  }

  /// Lấy tên màu
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
