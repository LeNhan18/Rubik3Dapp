import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/rubik_cube.dart';

/// Service để scan và nhận diện màu từ ảnh Rubik's Cube
class CubeScannerService {
  // Màu chuẩn của Rubik (RGB values)
  static const Map<CubeColor, List<int>> _standardColors = {
    CubeColor.white: [255, 255, 255],
    CubeColor.red: [220, 0, 0],
    CubeColor.blue: [0, 0, 220],
    CubeColor.orange: [255, 140, 0],
    CubeColor.green: [0, 180, 0],
    CubeColor.yellow: [255, 255, 0],
  };

  /// Nhận diện màu từ RGB values
  static CubeColor? detectColor(int r, int g, int b) {
    // Tính khoảng cách đến từng màu chuẩn
    double minDistance = double.infinity;
    CubeColor? closestColor;

    for (var entry in _standardColors.entries) {
      final color = entry.key;
      final standard = entry.value;
      
      // Tính khoảng cách Euclidean trong không gian RGB
      final dr = r - standard[0];
      final dg = g - standard[1];
      final db = b - standard[2];
      final distance = (dr * dr + dg * dg + db * db).toDouble();
      
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    // Nếu khoảng cách quá xa, có thể là màu không hợp lệ
    // Threshold: 15000 (khoảng cách tối đa chấp nhận được)
    if (minDistance > 15000) {
      return null; // Không nhận diện được
    }

    return closestColor;
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
  static List<int> _getAverageColor(
    img.Image image, 
    int x1, int y1, int x2, int y2
  ) {
    int rSum = 0, gSum = 0, bSum = 0;
    int pixelCount = 0;
    
    // Lấy mẫu từ giữa vùng (60% diện tích) để tránh edge và shadow
    final marginX = (x2 - x1) ~/ 5;
    final marginY = (y2 - y1) ~/ 5;
    
    final sampleX1 = x1 + marginX;
    final sampleY1 = y1 + marginY;
    final sampleX2 = x2 - marginX;
    final sampleY2 = y2 - marginY;
    
    for (int y = sampleY1; y < sampleY2 && y < image.height; y++) {
      for (int x = sampleX1; x < sampleX2 && x < image.width; x++) {
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
          
          rSum += r;
          gSum += g;
          bSum += b;
          pixelCount++;
        }
      }
    }
    
    if (pixelCount == 0) {
      return [128, 128, 128]; // Màu xám mặc định
    }
    
    return [
      rSum ~/ pixelCount,
      gSum ~/ pixelCount,
      bSum ~/ pixelCount,
    ];
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

