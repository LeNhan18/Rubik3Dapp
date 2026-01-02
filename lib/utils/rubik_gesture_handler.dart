import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enum định nghĩa các mặt của Rubik Cube
/// Dựa trên ký hiệu chuẩn: R, L, U, D, F, B
enum CubeFace {
  right,   // R - Mặt phải (x = 2)
  left,    // L - Mặt trái (x = 0)
  up,      // U - Mặt trên (y = 2)
  down,    // D - Mặt dưới (y = 0)
  front,   // F - Mặt trước (z = 2)
  back,    // B - Mặt sau (z = 0)
}

/// Enum định nghĩa hướng vuốt (swipe direction)
enum SwipeDirection {
  left,    // Vuốt sang trái
  right,   // Vuốt sang phải
  up,      // Vuốt lên trên
  down,    // Vuốt xuống dưới
}

/// Class xử lý gesture để xoay Rubik Cube
/// 
/// QUAN TRỌNG: Gesture KHÔNG xoay Rubik trực tiếp theo pixel!
/// 
/// Cách hoạt động:
/// 1. onPanStart: Xác định mặt nào đang được vuốt (dựa trên vị trí click)
/// 2. onPanUpdate: CHỈ thu thập thông tin (delta, khóa trục) - KHÔNG xoay
/// 3. onPanEnd: Xác định move (R, R', U, U', ...) và gọi hàm rotate MỘT LẦN
/// 
/// Tại sao không xoay trong onPanUpdate?
/// - onPanUpdate được gọi liên tục khi đang vuốt (mỗi pixel di chuyển)
/// - Nếu xoay trong onPanUpdate → xoay theo từng pixel → xoay lung tung, sai trục
/// - Nếu xoay trong onPanEnd → chỉ xoay một lần sau khi vuốt xong → xoay đúng 90 độ
/// 
/// Tại sao không xoay sai trục?
/// - Gesture chỉ xác định MOVE (R, R', U, U', ...)
/// - Gọi hàm _rotateR(), _rotateL(), ... có sẵn
/// - Các hàm này gọi rotationService.rotateFace() với axis, layer, clockwise ĐÚNG
/// - rotationService đã được implement đúng → mọi phép quay đều xoay quanh tâm Rubik
/// 
/// Chức năng:
/// - Xác định mặt nào đang được vuốt dựa trên vị trí click
/// - Xác định hướng vuốt (trái/phải/lên/xuống)
/// - Map hướng vuốt sang các hàm rotate tương ứng
/// - Có threshold để tránh rung và chỉ xoay 90 độ
class RubikGestureHandler {
  // Threshold để xác định hướng vuốt (pixels)
  // Nếu khoảng cách vuốt < threshold này, không xoay (tránh rung)
  // Tăng lên để tránh xoay nhầm khi chưa đủ khoảng cách
  static const double _swipeThreshold = 40.0;
  
  // Threshold để khóa trục (tỷ lệ)
  // Nếu |dx| / |dy| > threshold hoặc ngược lại, khóa trục đó
  // Tăng lên để khóa trục sớm hơn, tránh xoay nhầm hướng
  static const double _axisLockThreshold = 2.0;
  
  // Vị trí bắt đầu vuốt
  Offset? _startPosition;
  
  // Mặt đang được vuốt (xác định khi bắt đầu)
  CubeFace? _activeFace;
  
  // Trục đã được khóa (horizontal hoặc vertical)
  bool _isAxisLocked = false;
  bool _isHorizontalLocked = false;
  
  /// Callback khi cần xoay mặt
  /// Tham số: (face, clockwise)
  final Function(CubeFace, bool)? onRotateFace;
  
  /// Callback để lấy góc camera hiện tại
  /// Trả về: (angleX, angleY) - góc camera trong không gian 3D
  final Function()? getCameraAngles;
  
  RubikGestureHandler({
    this.onRotateFace,
    this.getCameraAngles,
  });
  
  /// Xử lý khi bắt đầu vuốt (onPanStart)
  /// 
  /// Bước 1: Lưu vị trí bắt đầu
  /// Bước 2: Xác định mặt nào đang được vuốt dựa trên vị trí click
  ///         (đơn giản hóa: chia màn hình thành 9 vùng 3x3)
  /// 
  /// Lưu ý: Chỉ xác định mặt, KHÔNG xoay Rubik ở đây
  void handlePanStart(DragStartDetails details, Size screenSize) {
    // Reset state
    _resetState();
    
    _startPosition = details.localPosition;
    _isAxisLocked = false;
    _isHorizontalLocked = false;
    
    // Xác định mặt dựa trên vị trí click trên màn hình
    // Chia màn hình thành 9 vùng (3x3 grid)
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;
    final width = screenSize.width;
    final height = screenSize.height;
    
    // Lấy góc camera để xác định mặt nào đang hướng về người dùng
    double? angleX, angleY;
    if (getCameraAngles != null) {
      final angles = getCameraAngles!();
      angleX = angles[0];
      angleY = angles[1];
    }
    
    // Xác định mặt dựa trên vị trí click và góc camera
    _activeFace = _determineFaceFromPosition(x, y, width, height, angleX, angleY);
    
    // Debug: In ra mặt đã xác định
    print('Gesture Start: Face = $_activeFace, Position = ($x, $y)');
  }
  
  /// Xử lý khi đang vuốt (onPanUpdate)
  /// 
  /// QUAN TRỌNG: KHÔNG xoay Rubik trong hàm này!
  /// Chỉ thu thập thông tin để xác định move, không gọi rotate.
  /// 
  /// Bước 1: Tính toán delta (khoảng cách đã vuốt)
  /// Bước 2: Kiểm tra threshold - nếu chưa đủ, không làm gì
  /// Bước 3: Khóa trục (horizontal hoặc vertical) để tránh xoay nhầm
  /// Bước 4: Lưu hướng vuốt để xử lý sau (KHÔNG xoay ngay)
  void handlePanUpdate(DragUpdateDetails details) {
    if (_startPosition == null || _activeFace == null) return;
    
    // Tính toán delta (khoảng cách đã vuốt)
    final delta = details.localPosition - _startPosition!;
    final dx = delta.dx;
    final dy = delta.dy;
    
    // Tính khoảng cách tổng
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Bước 2: Kiểm tra threshold - nếu chưa đủ, không làm gì (tránh rung)
    // Nhưng vẫn lưu delta để có thể xoay khi đủ threshold
    if (distance < _swipeThreshold) {
      _lastDelta = delta; // Vẫn lưu để tích lũy
      return;
    }
    
    // Bước 3: Khóa trục để tránh xoay nhầm
    // Khóa trục sớm hơn để tránh xoay nhầm hướng
    if (!_isAxisLocked) {
      final absDx = dx.abs();
      final absDy = dy.abs();
      
      // Nếu vuốt theo chiều ngang nhiều hơn chiều dọc
      if (absDx > absDy * _axisLockThreshold) {
        _isHorizontalLocked = true;
        _isAxisLocked = true;
        // Khi đã khóa trục ngang, chỉ lưu delta theo chiều ngang
        _lastDelta = Offset(dx, 0);
      }
      // Nếu vuốt theo chiều dọc nhiều hơn chiều ngang
      else if (absDy > absDx * _axisLockThreshold) {
        _isHorizontalLocked = false;
        _isAxisLocked = true;
        // Khi đã khóa trục dọc, chỉ lưu delta theo chiều dọc
        _lastDelta = Offset(0, dy);
      } else {
        // Chưa đủ để khóa trục, vẫn lưu delta đầy đủ
        _lastDelta = delta;
      }
    } else {
      // Đã khóa trục, chỉ cập nhật theo trục đã khóa
      if (_isHorizontalLocked) {
        _lastDelta = Offset(dx, 0);
      } else {
        _lastDelta = Offset(0, dy);
      }
    }
  }
  
  // Lưu delta cuối cùng để xác định hướng trong onPanEnd
  Offset? _lastDelta;
  
  /// Xử lý khi kết thúc vuốt (onPanEnd)
  /// 
  /// ĐÂY LÀ NƠI DUY NHẤT GỌI ROTATE!
  /// 
  /// Tại sao không xoay trong onPanUpdate?
  /// - onPanUpdate được gọi liên tục khi đang vuốt (mỗi pixel)
  /// - Nếu xoay trong onPanUpdate → xoay theo từng pixel → xoay lung tung
  /// - Nếu xoay trong onPanEnd → chỉ xoay một lần sau khi vuốt xong → xoay đúng 90 độ
  /// 
  /// Bước 1: Kiểm tra đã có đủ thông tin để xác định move
  /// Bước 2: Xác định hướng vuốt cuối cùng
  /// Bước 3: Map hướng vuốt sang move (R, R', U, U', ...)
  /// Bước 4: Gọi hàm rotate có sẵn một lần duy nhất
  /// Bước 5: Reset các biến trạng thái
  void handlePanEnd(DragEndDetails details) {
    // Bước 1: Kiểm tra đã có đủ thông tin
    if (_startPosition == null || _activeFace == null || _lastDelta == null) {
      _resetState();
      return;
    }
    
    final dx = _lastDelta!.dx;
    final dy = _lastDelta!.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Kiểm tra threshold một lần nữa
    if (distance < _swipeThreshold) {
      _resetState();
      return;
    }
    
    // Bước 2: Xác định hướng vuốt cuối cùng
    SwipeDirection? direction;
    if (_isAxisLocked) {
      // Đã khóa trục, chỉ xét trục đã khóa
      if (_isHorizontalLocked) {
        direction = dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      } else {
        direction = dy > 0 ? SwipeDirection.down : SwipeDirection.up;
      }
    } else {
      // Chưa khóa trục, chọn hướng có độ lớn lớn hơn
      if (dx.abs() > dy.abs()) {
        direction = dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      } else {
        direction = dy > 0 ? SwipeDirection.down : SwipeDirection.up;
      }
    }
    
    // Bước 3 & 4: Map hướng vuốt sang move và gọi hàm rotate MỘT LẦN DUY NHẤT
    if (direction != null && onRotateFace != null) {
      final (face, clockwise) = _mapSwipeToRotation(_activeFace!, direction);
      if (face != null) {
        // Debug: In ra move sẽ được thực hiện
        print('Gesture End: Face = $_activeFace, Direction = $direction, Rotate = $face, Clockwise = $clockwise');
        
        // GỌI HÀM ROTATE CÓ SẴN - Đảm bảo xoay đúng trục, đúng tâm
        // Các hàm _rotateR(), _rotateL(), ... đã được implement đúng
        // Chúng gọi rotationService.rotateFace() với axis, layer, clockwise đúng
        // → Đảm bảo mọi phép quay đều xoay quanh tâm Rubik
        onRotateFace!(face, clockwise);
      } else {
        print('Gesture End: Face mapping returned null');
      }
    } else {
      print('Gesture End: direction = $direction, onRotateFace = ${onRotateFace != null}');
    }
    
    // Bước 5: Reset
    _resetState();
  }
  
  /// Reset tất cả biến trạng thái
  void _resetState() {
    _startPosition = null;
    _activeFace = null;
    _isAxisLocked = false;
    _isHorizontalLocked = false;
    _lastDelta = null;
  }
  
  /// Xác định mặt nào đang được vuốt dựa trên vị trí click
  /// 
  /// Cải thiện: Xác định mặt dựa trên vị trí click và góc camera
  /// - Chia màn hình thành các vùng dựa trên vị trí tương đối
  /// - Xem xét góc camera để xác định mặt nào đang hướng về người dùng
  /// - Đảm bảo hoạt động mượt mà trên tất cả các mặt
  CubeFace _determineFaceFromPosition(
    double x,
    double y,
    double width,
    double height,
    double? angleX,
    double? angleY,
  ) {
    // Tính vị trí tương đối (0.0 - 1.0)
    final relX = x / width;
    final relY = y / height;
    
    // Chia màn hình thành các vùng dựa trên vị trí tương đối
    // Vùng trung tâm (40% - 60%) = Front
    if (relX >= 0.3 && relX <= 0.7 && relY >= 0.3 && relY <= 0.7) {
      return CubeFace.front;
    }
    
    // Xác định mặt dựa trên vị trí click
    // Hàng trên (0% - 30%): Up
    if (relY < 0.3) {
      return CubeFace.up;
    }
    // Hàng dưới (70% - 100%): Down
    if (relY > 0.7) {
      return CubeFace.down;
    }
    // Cột trái (0% - 30%): Left
    if (relX < 0.3) {
      return CubeFace.left;
    }
    // Cột phải (70% - 100%): Right
    if (relX > 0.7) {
      return CubeFace.right;
    }
    
    // Vùng giữa: Xác định dựa trên góc camera nếu có
    if (angleX != null && angleY != null) {
      // Nếu camera nhìn từ trên xuống (angleX > 0.5)
      if (angleX > 0.5) {
        if (relY < 0.5) return CubeFace.up;
        return CubeFace.down;
      }
      // Nếu camera nhìn từ dưới lên (angleX < -0.5)
      if (angleX < -0.5) {
        if (relY < 0.5) return CubeFace.down;
        return CubeFace.up;
      }
      // Nếu camera nhìn từ trái (angleY < -0.5)
      if (angleY < -0.5) {
        if (relX < 0.5) return CubeFace.back;
        return CubeFace.front;
      }
      // Nếu camera nhìn từ phải (angleY > 0.5)
      if (angleY > 0.5) {
        if (relX < 0.5) return CubeFace.front;
        return CubeFace.back;
      }
    }
    
    // Mặc định: Front (mặt trước)
    return CubeFace.front;
  }
  
  /// Map hướng vuốt sang hàm rotate tương ứng
  /// 
  /// Trả về: (CubeFace, clockwise)
  /// - CubeFace: Mặt cần xoay
  /// - clockwise: true = xoay theo chiều kim đồng hồ, false = ngược chiều
  /// 
  /// Logic mapping đã được sửa để đúng với mong muốn:
  /// - Vuốt sang ngang (trái/phải) → xoay mặt U (trên) hoặc D (dưới)
  /// - Vuốt lên xuống → xoay mặt R (phải) hoặc L (trái)
  /// 
  /// Logic đơn giản và nhất quán:
  /// - Vuốt sang phải → xoay U (mặt trên) theo chiều kim đồng hồ
  /// - Vuốt sang trái → xoay U' (mặt trên) ngược chiều kim đồng hồ
  /// - Vuốt xuống → xoay R (mặt phải) theo chiều kim đồng hồ
  /// - Vuốt lên → xoay R' (mặt phải) ngược chiều kim đồng hồ
  /// 
  /// Lưu ý: Logic này không phụ thuộc vào mặt đang được vuốt,
  /// chỉ phụ thuộc vào hướng vuốt để đảm bảo nhất quán và dễ dự đoán.
  (CubeFace?, bool) _mapSwipeToRotation(CubeFace face, SwipeDirection direction) {
    // Logic đơn giản: Chỉ dựa vào hướng vuốt, không phụ thuộc vào mặt đang vuốt
    // Điều này đảm bảo hành vi nhất quán và dễ dự đoán
    
    switch (direction) {
      case SwipeDirection.left:
        // Vuốt sang trái → xoay U' (mặt trên ngược chiều)
        return (CubeFace.up, false);
        
      case SwipeDirection.right:
        // Vuốt sang phải → xoay U (mặt trên theo chiều kim đồng hồ)
        return (CubeFace.up, true);
        
      case SwipeDirection.up:
        // Vuốt lên → xoay R' (mặt phải ngược chiều)
        return (CubeFace.right, false);
        
      case SwipeDirection.down:
        // Vuốt xuống → xoay R (mặt phải theo chiều kim đồng hồ)
        return (CubeFace.right, true);
    }
  }
}

