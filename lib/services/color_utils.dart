import 'dart:math' as math;

/// Color utilities: RGB to LAB conversion và Delta E calculation
class ColorUtils {
  /// Chuyển RGB sang LAB color space
  /// RGB phải ở dạng [0-255]
  static List<double> rgbToLab(int r, int g, int b) {
    // Normalize về [0, 1]
    double rNorm = r / 255.0;
    double gNorm = g / 255.0;
    double bNorm = b / 255.0;

    // Convert to linear RGB
    rNorm = rNorm > 0.04045 ? math.pow((rNorm + 0.055) / 1.055, 2.4).toDouble() : rNorm / 12.92;
    gNorm = gNorm > 0.04045 ? math.pow((gNorm + 0.055) / 1.055, 2.4).toDouble() : gNorm / 12.92;
    bNorm = bNorm > 0.04045 ? math.pow((bNorm + 0.055) / 1.055, 2.4).toDouble() : bNorm / 12.92;

    // Convert to XYZ (D65 illuminant)
    double x = (rNorm * 0.4124564 + gNorm * 0.3575761 + bNorm * 0.1804375) / 0.95047;
    double y = (rNorm * 0.2126729 + gNorm * 0.7151522 + bNorm * 0.0721750) / 1.00000;
    double z = (rNorm * 0.0193339 + gNorm * 0.1191920 + bNorm * 0.9503041) / 1.08883;

    // Convert to LAB
    x = x > 0.008856 ? math.pow(x, 1.0 / 3.0).toDouble() : (7.787 * x + 16.0 / 116.0);
    y = y > 0.008856 ? math.pow(y, 1.0 / 3.0).toDouble() : (7.787 * y + 16.0 / 116.0);
    z = z > 0.008856 ? math.pow(z, 1.0 / 3.0).toDouble() : (7.787 * z + 16.0 / 116.0);

    double l = (116.0 * y) - 16.0;
    double a = 500.0 * (x - y);
    double bLab = 200.0 * (y - z);

    return [l, a, bLab];
  }

  /// Tính Delta E (CIE76) - khoảng cách màu trong LAB space
  /// Delta E < 2.3: Không thể phân biệt bằng mắt
  /// Delta E < 10: Rất giống nhau
  /// Delta E > 50: Khác biệt rõ ràng
  static double deltaE(int r1, int g1, int b1, int r2, int g2, int b2) {
    final lab1 = rgbToLab(r1, g1, b1);
    final lab2 = rgbToLab(r2, g2, b2);

    final deltaL = lab1[0] - lab2[0];
    final deltaA = lab1[1] - lab2[1];
    final deltaB = lab1[2] - lab2[2];

    return math.sqrt(deltaL * deltaL + deltaA * deltaA + deltaB * deltaB);
  }

  /// Tính khoảng cách màu trong LAB space (chính xác hơn RGB)
  static double labDistance(List<double> lab1, List<double> lab2) {
    final deltaL = lab1[0] - lab2[0];
    final deltaA = lab1[1] - lab2[1];
    final deltaB = lab1[2] - lab2[2];
    return math.sqrt(deltaL * deltaL + deltaA * deltaA + deltaB * deltaB);
  }

  /// Lấy median của một danh sách số
  static double median(List<double> numbers) {
    if (numbers.isEmpty) return 0;
    final sorted = List<double>.from(numbers)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    } else {
      return sorted[mid];
    }
  }
}
