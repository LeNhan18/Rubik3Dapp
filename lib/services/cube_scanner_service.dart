import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/rubik_cube.dart';

/// Service để scan và nhận diện màu từ ảnh Rubik's Cube
class CubeScannerService {
  // Màu chuẩn của Rubik (RGB values) - điều chỉnh cho gần với Rubik thực tế hơn
  // Dùng nhiều giá trị để cover các điều kiện ánh sáng khác nhau
  static const Map<CubeColor, List<List<int>>> _standardColors = {
    CubeColor.white: [
      [255, 255, 255], [250, 250, 250], [240, 240, 240], [230, 230, 230], // Trắng
    ],
    CubeColor.red: [
      [220, 30, 30], [200, 20, 20], [180, 15, 15], [240, 40, 40], // Đỏ đậm
    ],
    CubeColor.blue: [
      [0, 80, 220], [0, 70, 200], [0, 60, 180], [0, 90, 240], // Xanh dương đậm
    ],
    CubeColor.orange: [
      [255, 130, 0], [255, 110, 0], [240, 100, 0], [255, 150, 20], // Cam
    ],
    CubeColor.green: [
      [0, 170, 0], [0, 150, 0], [0, 130, 0], [0, 190, 20], // Xanh lá đậm
    ],
    CubeColor.yellow: [
      [255, 230, 0], [255, 210, 0], [240, 190, 0], [255, 250, 30], // Vàng
    ],
  };

  /// Chuyển RGB sang HSV để nhận diện màu tốt hơn
  static List<double> _rgbToHsv(int r, int g, int b) {
    final rNorm = r / 255.0;
    final gNorm = g / 255.0;
    final bNorm = b / 255.0;
    
    final max = rNorm > gNorm 
        ? (rNorm > bNorm ? rNorm : bNorm)
        : (gNorm > bNorm ? gNorm : bNorm);
    final min = rNorm < gNorm 
        ? (rNorm < bNorm ? rNorm : bNorm)
        : (gNorm < bNorm ? gNorm : bNorm);
    final delta = max - min;
    
    double h = 0;
    if (delta != 0) {
      if (max == rNorm) {
        h = 60 * (((gNorm - bNorm) / delta) % 6);
      } else if (max == gNorm) {
        h = 60 * (((bNorm - rNorm) / delta) + 2);
      } else {
        h = 60 * (((rNorm - gNorm) / delta) + 4);
      }
    }
    if (h < 0) h += 360;
    
    final saturation = max == 0 ? 0.0 : delta / max;
    final value = max;
    
    return [h, saturation, value];
  }

  /// Normalize RGB theo độ sáng để ít bị ảnh hưởng bởi ánh sáng
  static List<double> _normalizeRgb(int r, int g, int b) {
    final brightness = (r + g + b) / 3.0;
    if (brightness == 0) return [0.0, 0.0, 0.0];
    
    // Normalize về độ sáng trung bình (128)
    final factor = 128.0 / brightness;
    return [
      (r * factor).clamp(0.0, 255.0),
      (g * factor).clamp(0.0, 255.0),
      (b * factor).clamp(0.0, 255.0),
    ];
  }

  /// Nhận diện màu từ RGB values - cải thiện để chính xác hơn
  /// Ưu tiên HSV vì ít bị ảnh hưởng bởi ánh sáng
  static CubeColor? detectColor(int r, int g, int b) {
    // Nếu quá tối, không nhận diện được
    final brightness = (r + g + b) / 3.0;
    if (brightness < 20) {
      return null;
    }
    
    // Chuyển sang HSV ngay từ đầu (ưu tiên HSV)
    final hsv = _rgbToHsv(r, g, b);
    final h = hsv[0];
    final s = hsv[1];
    final v = hsv[2];
    
    // Nếu quá tối hoặc quá xám, không nhận diện được
    if (v < 0.15 || (s < 0.08 && v < 0.3)) {
      return null;
    }
    
    // Nhận diện bằng HSV (chính xác hơn RGB)
    double minHsvDistance = double.infinity;
    CubeColor? hsvClosestColor;
    
    for (var entry in _standardColors.entries) {
      final color = entry.key;
      final standards = entry.value;
      
      // So sánh với TẤT CẢ các giá trị chuẩn, lấy giá trị tốt nhất
      for (var standard in standards) {
        final standardHsv = _rgbToHsv(standard[0], standard[1], standard[2]);
        
        // Tính khoảng cách Hue (quan trọng nhất)
        final hDiff = (h - standardHsv[0]).abs();
        final hDistance = hDiff > 180 ? 360 - hDiff : hDiff;
        
        // Tính khoảng cách Saturation
        final sDiff = (s - standardHsv[1]).abs();
        
        // Tính khoảng cách Value (ít quan trọng hơn)
        final vDiff = (v - standardHsv[2]).abs();
        
        // Kết hợp: Hue quan trọng nhất, Saturation thứ hai, Value ít quan trọng
        final hsvDistance = hDistance * hDistance * 3 + 
                           sDiff * sDiff * 1000 + 
                           vDiff * vDiff * 100;
        
        if (hsvDistance < minHsvDistance) {
          minHsvDistance = hsvDistance;
          hsvClosestColor = color;
        }
      }
    }
    
    // Threshold: 2500 - chấp nhận màu gần với chuẩn
    if (minHsvDistance < 2500) {
      return hsvClosestColor;
    }
    
    // Nếu HSV không khớp, thử RGB như fallback
    double minRgbDistance = double.infinity;
    CubeColor? rgbClosestColor;
    
    for (var entry in _standardColors.entries) {
      final color = entry.key;
      final standards = entry.value;
      
      for (var standard in standards) {
        final dr = r - standard[0];
        final dg = g - standard[1];
        final db = b - standard[2];
        final distance = (dr * dr + dg * dg + db * db).toDouble();
        
        if (distance < minRgbDistance) {
          minRgbDistance = distance;
          rgbClosestColor = color;
        }
      }
    }
    
    // Threshold RGB: 40000 - chỉ chấp nhận nếu rất gần
    if (minRgbDistance < 40000) {
      return rgbClosestColor;
    }
    
    return null;
  }

  /// Scan một mặt 3x3 từ ảnh
  /// Ảnh phải chứa một mặt Rubik, chia thành 9 vùng (3x3)
  static List<List<CubeColor?>> scanFace(Uint8List imageBytes) {
    // Decode ảnh
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Không thể decode ảnh');
    }

    final width = image.width;
    final height = image.height;
    
    // Chia ảnh thành 9 vùng (3x3 grid)
    final cellWidth = width ~/ 3;
    final cellHeight = height ~/ 3;
    
    List<List<CubeColor?>> face = [];
    
    for (int row = 0; row < 3; row++) {
      List<CubeColor?> faceRow = [];
      
      for (int col = 0; col < 3; col++) {
        // Tính vùng của sticker này
        final x1 = col * cellWidth;
        final y1 = row * cellHeight;
        final x2 = (col + 1) * cellWidth;
        final y2 = (row + 1) * cellHeight;
        
        // Lấy màu trung bình của vùng này (lấy mẫu từ giữa để tránh edge)
        final avgColor = _getAverageColor(image, x1, y1, x2, y2);
        
        // Nhận diện màu
        final detectedColor = detectColor(
          avgColor[0], 
          avgColor[1], 
          avgColor[2]
        );

        faceRow.add(detectedColor);
      }
      face.add(faceRow);
    }
    
    return face;
  }

  /// Lấy màu trung bình của một vùng (lấy mẫu từ giữa để tránh edge và shadow)
  /// Sử dụng median và lọc màu tối/xám để loại bỏ edge và shadow
  static List<int> _getAverageColor(
    img.Image image, 
    int x1, int y1, int x2, int y2
  ) {
    // Lấy mẫu từ giữa vùng (70% diện tích) để tránh edge và shadow tốt hơn
    final marginX = (x2 - x1) ~/ 3;
    final marginY = (y2 - y1) ~/ 3;
    
    final sampleX1 = x1 + marginX;
    final sampleY1 = y1 + marginY;
    final sampleX2 = x2 - marginX;
    final sampleY2 = y2 - marginY;
    
    // Thu thập tất cả pixel values (lấy nhiều mẫu hơn)
    final rValues = <int>[];
    final gValues = <int>[];
    final bValues = <int>[];
    
    // Lấy mẫu mỗi pixel để có nhiều dữ liệu nhất (chính xác hơn)
    final stepX = 1;
    final stepY = 1;
    
    for (int y = sampleY1; y < sampleY2 && y < image.height; y += stepY) {
      for (int x = sampleX1; x < sampleX2 && x < image.width; x += stepX) {
        if (x >= 0 && y >= 0) {
          final pixel = image.getPixel(x, y);
          
          // getPixel returns Pixel object, access r, g, b properties directly
          // Convert to int if they are double
          final rValue = pixel.r;
          final gValue = pixel.g;
          final bValue = pixel.b;
          
          final r = (rValue is int) ? rValue : (rValue as num).toInt();
          final g = (gValue is int) ? gValue : (gValue as num).toInt();
          final b = (bValue is int) ? bValue : (bValue as num).toInt();
          
          // Lọc màu quá tối (có thể là edge/shadow) - chỉ lấy màu sáng hơn
          final brightness = (r + g + b) / 3.0;
          if (brightness < 25) {
            continue; // Bỏ qua màu quá tối
          }
          
          // Lọc màu quá xám (độ bão hòa thấp) - có thể là edge
          final maxColor = r > g ? (r > b ? r : b) : (g > b ? g : b);
          final minColor = r < g ? (r < b ? r : b) : (g < b ? g : b);
          final saturation = maxColor == 0 ? 0.0 : (maxColor - minColor) / maxColor;
          if (saturation < 0.08 && brightness < 80) {
            continue; // Bỏ qua màu quá xám và tối
          }
          
          rValues.add(r);
          gValues.add(g);
          bValues.add(b);
        }
      }
    }
    
    if (rValues.isEmpty) {
      print('Warning: No valid pixels found, using default gray');
      return [128, 128, 128]; // Màu xám mặc định
    }
    
    // Sắp xếp và lấy median (giá trị giữa) để loại bỏ outliers
    rValues.sort();
    gValues.sort();
    bValues.sort();
    
    final mid = rValues.length ~/ 2;

    final result = [
      rValues[mid],
      gValues[mid],
      bValues[mid],
    ];
    
    print('Sampled ${rValues.length} pixels, median RGB: $result');
    
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
}

