import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/rubik_cube.dart';
import 'ml_color_classifier.dart';
import 'kmeans_color_classifier.dart';

/// Service để scan và nhận diện màu từ ảnh Rubik's Cube
/// Hỗ trợ nhiều phương pháp: ML, K-Means, hoặc kết hợp
class CubeScannerService {
  /// Nhận diện màu sử dụng Machine Learning (KNN + Neural Network)
  static CubeColor? detectColor(int r, int g, int b) {
    return MLColorClassifier.classify(r, g, b);
  }

  /// Scan một mặt 3x3 từ ảnh sử dụng Machine Learning
  static List<List<CubeColor?>> scanFace(Uint8List imageBytes) {
    return scanFaceML(imageBytes);
  }

  /// Nhận diện màu từ RGB values - cải thiện để chính xác hơn
  /// Ưu tiên phân biệt theo Hue trước, sau đó mới đến Saturation và Brightness
  static CubeColor? detectColor(int r, int g, int b) {
    // Nếu quá tối, không nhận diện được (giảm threshold)
    final brightness = (r + g + b) / 3.0;
    if (brightness < 15) {
      print('⚫ Quá tối: brightness=$brightness');
      return null;
    }
    
    // Chuyển sang HSV
    final hsv = _rgbToHsv(r, g, b);
    final h = hsv[0];
    final s = hsv[1];
    final v = hsv[2];
    
    print('🎨 RGB($r, $g, $b) → HSV(${h.toStringAsFixed(1)}°, ${(s * 100).toStringAsFixed(1)}%, ${(v * 100).toStringAsFixed(1)}%)');
    
    // =====================================
    // BƯỚC 1: PHÂN LOẠI TRẮNG/ĐEN/XÁM
    // =====================================
    
    // 1. TRẮNG - Saturation rất thấp, Brightness cao (nới lỏng hơn)
    if (s < 0.25 && v > 0.65) {
      print('  → TRẮNG (low saturation, high brightness)');
      return CubeColor.white;
    }
    
    // 2. MÀU XÁM/ĐEN - Saturation thấp, Brightness thấp (không phải màu Rubik)
    if (s < 0.15 && v < 0.35) {
      print('  → NULL (xám/đen, không phải màu Rubik)');
      return null;
    }

    final width = processedImage.width;
    final height = processedImage.height;
    
    // =====================================
    // BƯỚC 2: PHÂN LOẠI THEO HUE (GÓC MÀU)
    // Bao phủ toàn bộ 360° không có gaps
    // =====================================
    
    // Kiểm tra saturation tối thiểu để là màu (giảm threshold)
    if (s < 0.15) {
      print('  → NULL (saturation quá thấp: ${(s * 100).toStringAsFixed(1)}%)');
      return null;
    }
    
    // 3. ĐỎ - Hue 0-15° hoặc 345-360°, Saturation cao
    if ((h >= 0 && h <= 18) || (h >= 340 && h <= 360)) {
      print('  → ĐỎ (hue = ${h.toStringAsFixed(1)}°, gần 0°/360°)');
      return CubeColor.red;
    }
    
    // 4. CAM - Hue từ 18-38°, Saturation cao
    if (h > 18 && h <= 38) {
      print('  → CAM (hue = ${h.toStringAsFixed(1)}°, trong range 18-38°)');
      return CubeColor.orange;
    }
    
    // 5. VÀNG - Hue từ 38-68°, Saturation cao, Brightness cao (giảm threshold)
    if (h > 38 && h <= 68) {
      if (v > 0.40) {
        print('  → VÀNG (hue = ${h.toStringAsFixed(1)}°, trong range 38-68°)');
        return CubeColor.yellow;
      } else {
        print('  → CAM (hue vàng nhưng brightness thấp → cam tối)');
        return CubeColor.orange;
      }
      face.add(faceRow);
    }
    
    // 6. VÀNG-XANH (gap) - Hue từ 68-80°, ưu tiên vàng hoặc xanh lá
    if (h > 68 && h <= 80) {
      if (g > r * 1.1 && g > b) {
        print('  → XANH LÁ (hue = ${h.toStringAsFixed(1)}°, green dominant)');
        return CubeColor.green;
      } else {
        print('  → VÀNG (hue = ${h.toStringAsFixed(1)}°, yellow-green → vàng)');
        return CubeColor.yellow;
      }
    }

    final processedImage = useWhiteBalance ? _applyAutoWhiteBalance(image) : image;
    final width = processedImage.width;
    final height = processedImage.height;
    
    // 7. XANH LÁ - Hue từ 80-165°, Saturation cao
    if (h > 80 && h <= 165) {
      print('  → XANH LÁ (hue = ${h.toStringAsFixed(1)}°, trong range 80-165°)');
      return CubeColor.green;
    }
    
    // 8. XANH LÁ-XANH DƯƠNG (gap) - Hue từ 165-185°, ưu tiên theo tỷ lệ G/B
    if (h > 165 && h <= 185) {
      if (b > g * 1.1) {
        print('  → XANH DƯƠNG (hue = ${h.toStringAsFixed(1)}°, blue > green)');
        return CubeColor.blue;
      } else {
        print('  → XANH LÁ (hue = ${h.toStringAsFixed(1)}°, green ≥ blue)');
        return CubeColor.green;
      }
    }
    
    // 9. XANH DƯƠNG - Hue từ 185-250° (THU HẸP từ 180-260°)
    if (h > 185 && h <= 250) {
      print('  → XANH DƯƠNG (hue = ${h.toStringAsFixed(1)}°, trong range 185-250°)');
      return CubeColor.blue;
    }
    
    // 10. XANH DƯƠNG-TÍM-ĐỎ (gap) - Hue từ 250-340°
    // Đây là vùng tím/hồng, không có trong Rubik chuẩn
    // Ưu tiên: nếu R > B → đỏ, nếu B > R → xanh dương
    if (h > 250 && h < 340) {
      if (r > b * 1.2 && r > g) {
        print('  → ĐỎ (hue = ${h.toStringAsFixed(1)}°, red dominant trong vùng tím)');
        return CubeColor.red;
      } else if (b > r && b > g) {
        print('  → XANH DƯƠNG (hue = ${h.toStringAsFixed(1)}°, blue dominant trong vùng tím)');
        return CubeColor.blue;
      } else {
        print('  → NULL (hue = ${h.toStringAsFixed(1)}°, vùng tím không xác định)');
        return null;
      }
    }
    
    // =====================================
    // FALLBACK: Tìm màu gần nhất bằng RGB
    // =====================================
    print('  ⚠️ Không match Hue range, dùng RGB fallback...');
    
    double minDistance = double.infinity;
    CubeColor? closestColor;
    
    // TRICK: Ưu tiên màu có component dominant rõ ràng
    final maxRGB = [r, g, b].reduce((a, b) => a > b ? a : b);
    final minRGB = [r, g, b].reduce((a, b) => a < b ? a : b);
    final dominance = maxRGB - minRGB;
    
    print('  📊 RGB dominance: $dominance (R:$r, G:$g, B:$b)');
    
    // Nếu có component dominant rõ ràng (> 40), dùng logic đơn giản
    if (dominance > 40) {
      if (r > g && r > b) {
        // Red dominant
        if (r > g * 1.3 && r > b * 1.3) {
          print('  → ĐỎ (red dominant, fallback simple)');
          return CubeColor.red;
        } else if (g > b) {
          print('  → CAM (red-yellow mix, fallback simple)');
          return CubeColor.orange;
        }
      } else if (g > r && g > b) {
        // Green dominant
        if (g > r * 1.3 && g > b * 1.3) {
          print('  → XANH LÁ (green dominant, fallback simple)');
          return CubeColor.green;
        } else if (r > b) {
          print('  → VÀNG (green-red mix, fallback simple)');
          return CubeColor.yellow;
        }
      } else if (b > r && b > g) {
        // Blue dominant
        if (b > r * 1.3 && b > g * 1.3) {
          print('  → XANH DƯƠNG (blue dominant, fallback simple)');
          return CubeColor.blue;
        }
      }
    }
    
    // Nếu không có component dominant, dùng Euclidean distance
    for (var entry in _standardColors.entries) {
      final color = entry.key;
      final standards = entry.value;
      
      // Lấy giá trị chuẩn đầu tiên (representative)
      final standard = standards[0];
      final dr = r - standard[0];
      final dg = g - standard[1];
      final db = b - standard[2];
      
      // Euclidean distance trong RGB space
      final distance = (dr * dr + dg * dg + db * db).toDouble();
      
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }
    
    // Tăng threshold lên 35000 để chấp nhận nhiều trường hợp hơn
    if (minDistance < 35000) {
      print('  → ${getColorName(closestColor!)} (RGB fallback distance, distance=${minDistance.toStringAsFixed(0)})');
      return closestColor;
    }
    
    print('  → NULL (không khớp màu nào, min distance=${minDistance.toStringAsFixed(0)})');
    return null;
  }

  /// Scan một mặt 3x3 từ ảnh
  /// Ảnh phải chứa một mặt Rubik, chia thành 9 vùng (3x3)
  static List<List<CubeColor?>> scanFace(Uint8List imageBytes) {
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
      image = _adjustBrightness(image, 1.5); // Tăng 50%
    } else if (avgBrightness > 200) {
      print('⚡ Ảnh quá sáng, giảm độ sáng...');
      image = _adjustBrightness(image, 0.8); // Giảm 20%
    }

    final width = image.width;
    final height = image.height;
    
    final processedImage = useWhiteBalance ? _applyAutoWhiteBalance(image) : image;
    final width = processedImage.width;
    final height = processedImage.height;
    final cellWidth = width ~/ 3;
    final cellHeight = height ~/ 3;
    
    List<List<CubeColor?>> face = [];
    for (int row = 0; row < 3; row++) {
      List<CubeColor?> faceRow = [];
      for (int col = 0; col < 3; col++) {
        final x1 = col * cellWidth;
        final y1 = row * cellHeight;
        final x2 = (col + 1) * cellWidth;
        final y2 = (row + 1) * cellHeight;
        
        final dominantColor = _getDominantColor(processedImage, x1, y1, x2, y2);
        
        // Nhận diện màu
        print('\n=== Ô [$row][$col] ===');
        final detectedColor = detectColor(
          avgColor[0], 
          avgColor[1], 
          avgColor[2]
        );
        
        if (detectedColor == null) {
          print('❌ Không nhận diện được màu!');
        }

  /// Multi-pass voting: scan nhiều lần với các offset khác nhau và vote
  /// Phương pháp này chính xác hơn vì loại bỏ noise và outliers
  static List<List<CubeColor?>> _scanFaceMultiPass(img.Image image) {
    final width = image.width;
    final height = image.height;
    final cellWidth = width ~/ 3;
    final cellHeight = height ~/ 3;
    
    // Tạo voting matrix: Map<position, Map<color, count>>
    final votes = <String, Map<CubeColor, int>>{};
    
    // Scan 3 lần với các offset khác nhau
    final offsets = [
      [0, 0],      // Không offset
      [-2, -2],    // Offset nhỏ
      [2, 2],      // Offset ngược lại
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
          
          final dominantColor = _getDominantColor(image, x1, y1, x2, y2);
          final detectedColor = detectColor(
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
          // Lấy màu có nhiều vote nhất
          CubeColor? winner;
          int maxVotes = 0;
          for (var entry in cellVotes.entries) {
            if (entry.value > maxVotes) {
              maxVotes = entry.value;
              winner = entry.key;
            }
          }
          // Chỉ chấp nhận nếu có ít nhất 2/3 votes
          faceRow.add(maxVotes >= 2 ? winner : null);
        }
      }
      face.add(faceRow);
    }
    
    // Tổng kết kết quả scan
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
    print('');
    
    return face;
  }
  
  /// Lấy emoji tương ứng với màu
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

  /// Lấy màu chủ đạo từ một vùng bằng histogram-based method
  /// Phương pháp này chính xác hơn: tạo histogram màu và lấy cluster lớn nhất
  static List<int> _getDominantColor(
    img.Image image, 
    int x1, int y1, int x2, int y2
  ) {
    // Lấy mẫu từ giữa vùng (80% diện tích) để tránh edge và shadow tốt hơn
    final marginX = (x2 - x1) ~/ 5;
    final marginY = (y2 - y1) ~/ 5;
    
    final sampleX1 = x1 + marginX;
    final sampleY1 = y1 + marginY;
    final sampleX2 = x2 - marginX;
    final sampleY2 = y2 - marginY;
    
    // Thu thập tất cả pixel values (lấy nhiều mẫu hơn)
    final rValues = <int>[];
    final gValues = <int>[];
    final bValues = <int>[];
    
    // Lấy mẫu mỗi 2-3 pixel (đủ chính xác và nhanh hơn nhiều)
    final stepX = 2;
    final stepY = 2;
    
    // Histogram: Map<quantizedColor, [sumR, sumG, sumB, count]>
    final colorHistogram = <String, List<int>>{};
    
    // Thu thập tất cả pixel hợp lệ
    for (int y = sampleY1; y < sampleY2 && y < image.height; y += stepY) {
      for (int x = sampleX1; x < sampleX2 && x < image.width; x += stepX) {
        if (x >= 0 && y >= 0) {
          final pixel = image.getPixel(x, y);
          final rValue = pixel.r;
          final gValue = pixel.g;
          final bValue = pixel.b;
          
          final r = (rValue is int) ? rValue : (rValue as num).toInt();
          final g = (gValue is int) ? gValue : (gValue as num).toInt();
          final b = (bValue is int) ? bValue : (bValue as num).toInt();
          
          // Lọc màu quá tối (có thể là edge/shadow) - giảm threshold
          final brightness = (r + g + b) / 3.0;
          if (brightness < 20) {
            continue; // Bỏ qua màu quá tối
          }
          
          // Lọc màu quá xám (độ bão hòa thấp) - có thể là edge, NHƯNG giữ lại trắng
          final maxColor = r > g ? (r > b ? r : b) : (g > b ? g : b);
          final minColor = r < g ? (r < b ? r : b) : (g < b ? g : b);
          final saturation = maxColor == 0 ? 0.0 : (maxColor - minColor) / maxColor;
          
          // Chỉ loại bỏ màu xám TỐI (không phải trắng) - giảm threshold
          if (saturation < 0.05 && brightness < 80) {
            continue; // Bỏ qua màu xám tối
          }
          
          if (!colorHistogram.containsKey(colorKey)) {
            colorHistogram[colorKey] = [r, g, b, 1];
          } else {
            // Cộng dồn màu và tăng count (weighted average)
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
    
    if (rValues.isEmpty) {
      print('⚠️ WARNING: Không có pixel hợp lệ, dùng xám mặc định');
      return [128, 128, 128]; // Màu xám mặc định
    }
    
    // Tìm top bucket có count lớn nhất
    final sortedBuckets = colorHistogram.entries.toList()
      ..sort((a, b) => b.value[3].compareTo(a.value[3]));
    
    // Lấy top bucket (màu xuất hiện nhiều nhất)
    final topBucket = sortedBuckets[0];
    final result = [topBucket.value[0], topBucket.value[1], topBucket.value[2]];
    
    // Tính thống kê để debug
    final avgR = rValues.reduce((a, b) => a + b) / rValues.length;
    final avgG = gValues.reduce((a, b) => a + b) / gValues.length;
    final avgB = bValues.reduce((a, b) => a + b) / bValues.length;
    
    print('   📷 Đã lấy ${rValues.length} pixels hợp lệ');
    print('   📊 Median RGB: (${result[0]}, ${result[1]}, ${result[2]})');
    print('   📊 Average RGB: (${avgR.toStringAsFixed(0)}, ${avgG.toStringAsFixed(0)}, ${avgB.toStringAsFixed(0)})');
    
    return result;
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
  
  /// Tính độ sáng trung bình của ảnh
  static double _calculateAverageBrightness(img.Image image) {
    int totalBrightness = 0;
    int count = 0;
    
    // Sample mỗi 10 pixel để tính nhanh
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
  
  /// Điều chỉnh độ sáng của ảnh
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
}
