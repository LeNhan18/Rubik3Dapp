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

  /// Scan một mặt 3x3 từ ảnh với Machine Learning
  /// [useMultiPass]: true = scan nhiều lần và vote (chính xác hơn nhưng chậm hơn)
  /// [useWhiteBalance]: false = tắt auto white balance (khuyến nghị để tránh sai lệch màu)
  static List<List<CubeColor?>> scanFaceML(
    Uint8List imageBytes, {
    bool useMultiPass = false,
    bool useWhiteBalance = false, // TẮT MẶC ĐỊNH
  }) {
    // Decode ảnh
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Không thể decode ảnh');
    }

    // CHỈ áp dụng auto white balance nếu được yêu cầu (mặc định TẮT)
    final processedImage = useWhiteBalance ? _applyAutoWhiteBalance(image) : image;

    // Multi-pass voting: scan nhiều lần với các vùng hơi khác nhau và vote
    if (useMultiPass) {
      return _scanFaceMultiPass(processedImage);
    }

    final width = processedImage.width;
    final height = processedImage.height;
    
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
        
        // Lấy màu chủ đạo của vùng này (histogram-based)
        final dominantColor = _getDominantColor(processedImage, x1, y1, x2, y2);
        
        // Nhận diện màu bằng Machine Learning
        final detectedColor = detectColor(
          dominantColor[0], 
          dominantColor[1], 
          dominantColor[2]
        );

        faceRow.add(detectedColor);
      }
      face.add(faceRow);
    }
    
    return face;
  }

  /// Scan một mặt 3x3 sử dụng K-Means Clustering
  /// Tự động phát hiện 6 màu chính trong ảnh mà không cần training data
  static List<List<CubeColor?>> scanFaceKMeans(
    Uint8List imageBytes, {
    bool useWhiteBalance = false,
  }) {
    // Decode ảnh
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Không thể decode ảnh');
    }

    final processedImage = useWhiteBalance ? _applyAutoWhiteBalance(image) : image;
    final width = processedImage.width;
    final height = processedImage.height;
    
    // Thu thập tất cả màu từ 9 vùng
    final allColors = <List<int>>[];
    final cellWidth = width ~/ 3;
    final cellHeight = height ~/ 3;
    
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final x1 = col * cellWidth;
        final y1 = row * cellHeight;
        final x2 = (col + 1) * cellWidth;
        final y2 = (row + 1) * cellHeight;
        
        final dominantColor = _getDominantColor(processedImage, x1, y1, x2, y2);
        allColors.add(dominantColor);
      }
    }
    
    // Chạy K-Means để tìm 6 cluster
    final clusters = KMeansColorClassifier.findClusters(allColors, k: 6);
    
    // Map clusters sang màu Rubik
    final colorMap = KMeansColorClassifier.mapClustersToColors(clusters);
    
    // Phân loại mỗi vùng vào cluster gần nhất
    List<List<CubeColor?>> face = [];
    for (int row = 0; row < 3; row++) {
      List<CubeColor?> faceRow = [];
      for (int col = 0; col < 3; col++) {
        final x1 = col * cellWidth;
        final y1 = row * cellHeight;
        final x2 = (col + 1) * cellWidth;
        final y2 = (row + 1) * cellHeight;
        
        final dominantColor = _getDominantColor(processedImage, x1, y1, x2, y2);
        final detectedColor = KMeansColorClassifier.classify(
          dominantColor[0],
          dominantColor[1],
          dominantColor[2],
          clusters,
          colorMap,
        );
        
        faceRow.add(detectedColor);
      }
      face.add(faceRow);
    }
    
    return face;
  }

  /// Scan kết hợp: Dùng K-Means để tìm 6 màu, sau đó dùng ML để phân loại chính xác hơn
  static List<List<CubeColor?>> scanFaceHybrid(
    Uint8List imageBytes, {
    bool useMultiPass = false,
    bool useWhiteBalance = false,
  }) {
    // Bước 1: Dùng K-Means để tìm 6 màu chính
    final kmeansResult = scanFaceKMeans(imageBytes, useWhiteBalance: useWhiteBalance);
    
    // Bước 2: Dùng ML để refine kết quả
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Không thể decode ảnh');
    }
    
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
        
        // Dùng ML để phân loại
        final mlResult = MLColorClassifier.classify(
          dominantColor[0],
          dominantColor[1],
          dominantColor[2],
        );
        
        // Nếu ML có kết quả, dùng nó; nếu không, dùng K-Means
        faceRow.add(mlResult ?? kmeansResult[row][col]);
      }
      face.add(faceRow);
    }
    
    return face;
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
    
    // Thu thập pixel với bước nhảy nhỏ hơn để có nhiều dữ liệu hơn
    final stepX = 1; // Lấy mẫu mỗi pixel để chính xác hơn
    final stepY = 1;
    
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
          
          // Lọc màu quá tối hoặc quá xám
          final brightness = (r + g + b) / 3.0;
          if (brightness < 35) continue;
          
          final maxColor = r > g ? (r > b ? r : b) : (g > b ? g : b);
          final minColor = r < g ? (r < b ? r : b) : (g < b ? g : b);
          final saturation = maxColor == 0 ? 0.0 : (maxColor - minColor) / maxColor;
          if (saturation < 0.12 && brightness < 100) continue;
          
          // Quantize màu với độ phân giải cao hơn (16 bins)
          final qR = (r ~/ 16) * 16;
          final qG = (g ~/ 16) * 16;
          final qB = (b ~/ 16) * 16;
          
          final colorKey = '$qR,$qG,$qB';
          
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
    
    if (colorHistogram.isEmpty) {
      print('Warning: No valid pixels found, using default gray');
      return [128, 128, 128];
    }
    
    // Tìm top bucket có count lớn nhất
    final sortedBuckets = colorHistogram.entries.toList()
      ..sort((a, b) => b.value[3].compareTo(a.value[3]));
    
    // Lấy top bucket (màu xuất hiện nhiều nhất)
    final topBucket = sortedBuckets[0];
    final result = [topBucket.value[0], topBucket.value[1], topBucket.value[2]];
    
    // Nếu có nhiều bucket với count tương đương, lấy trung bình của top 2
    if (sortedBuckets.length > 1 && 
        sortedBuckets[1].value[3] > topBucket.value[3] * 0.7) {
      final secondBucket = sortedBuckets[1];
      final totalCount = topBucket.value[3] + secondBucket.value[3];
      final weightedR = ((topBucket.value[0] * topBucket.value[3] + 
                          secondBucket.value[0] * secondBucket.value[3]) / totalCount).round();
      final weightedG = ((topBucket.value[1] * topBucket.value[3] + 
                          secondBucket.value[1] * secondBucket.value[3]) / totalCount).round();
      final weightedB = ((topBucket.value[2] * topBucket.value[3] + 
                          secondBucket.value[2] * secondBucket.value[3]) / totalCount).round();
      
      return [weightedR, weightedG, weightedB];
    }
    
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
