import '../models/rubik_cube.dart';

/// Validate tính hợp lệ của cấu hình Rubik Cube
class CubeValidator {
  /// Kiểm tra xem 6 mặt đã scan có hợp lệ không
  static ValidationResult validate(Map<String, List<List<CubeColor?>>> faces) {
    // 1. Kiểm tra đủ 6 mặt
    final requiredFaces = ['up', 'front', 'right', 'back', 'left', 'down'];
    for (var face in requiredFaces) {
      if (!faces.containsKey(face)) {
        return ValidationResult(
          isValid: false,
          error: 'Thiếu mặt $face',
        );
      }
    }
    
    // 2. Đếm số lượng mỗi màu (phải có đúng 9 ô mỗi màu)
    Map<CubeColor, int> colorCounts = {};
    
    for (var face in faces.values) {
      for (var row in face) {
        for (var color in row) {
          if (color != null) {
            colorCounts[color] = (colorCounts[color] ?? 0) + 1;
          }
        }
      }
    }
    
    // Kiểm tra số lượng màu
    for (var color in CubeColor.values) {
      final count = colorCounts[color] ?? 0;
      if (count != 9) {
        return ValidationResult(
          isValid: false,
          error: 'Màu ${_getColorName(color)} có $count ô (phải có 9 ô)',
          warning: count > 0,
        );
      }
    }
    
    // 3. Kiểm tra center của mỗi mặt (center[1][1] phải khác nhau)
    Set<CubeColor> centerColors = {};
    Map<String, CubeColor> faceCenters = {};
    
    for (var entry in faces.entries) {
      final face = entry.value;
      if (face.length == 3 && face[1].length == 3) {
        final centerColor = face[1][1];
        if (centerColor != null) {
          if (centerColors.contains(centerColor)) {
            return ValidationResult(
              isValid: false,
              error: 'Có 2 mặt cùng màu center (${_getColorName(centerColor)})',
            );
          }
          centerColors.add(centerColor);
          faceCenters[entry.key] = centerColor;
        }
      }
    }
    
    // 4. Kiểm tra có đủ 6 màu center khác nhau
    if (centerColors.length != 6) {
      return ValidationResult(
        isValid: false,
        error: 'Chỉ có ${centerColors.length} màu center (phải có 6)',
      );
    }
    
    // 5. Tất cả ô phải có màu
    int totalCells = 0;
    int validCells = 0;
    
    for (var face in faces.values) {
      for (var row in face) {
        for (var color in row) {
          totalCells++;
          if (color != null) validCells++;
        }
      }
    }
    
    if (validCells < totalCells) {
      return ValidationResult(
        isValid: false,
        error: 'Có ${totalCells - validCells} ô chưa có màu',
        warning: validCells >= 45, // Nếu >= 45/54 thì chỉ warning
      );
    }
    
    return ValidationResult(
      isValid: true,
      error: null,
    );
  }
  
  static String _getColorName(CubeColor color) {
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
  
  /// Lấy thống kê màu
  static Map<CubeColor, int> getColorStatistics(
    Map<String, List<List<CubeColor?>>> faces,
  ) {
    Map<CubeColor, int> colorCounts = {};
    
    for (var face in faces.values) {
      for (var row in face) {
        for (var color in row) {
          if (color != null) {
            colorCounts[color] = (colorCounts[color] ?? 0) + 1;
          }
        }
      }
    }
    
    return colorCounts;
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;
  final bool warning; // true = warning, false = error
  
  ValidationResult({
    required this.isValid,
    this.error,
    this.warning = false,
  });
}
