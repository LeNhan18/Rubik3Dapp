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
  // Giảm xuống để dễ xoay hơn, nhưng vẫn đủ để tránh rung
  static const double _swipeThreshold = 20.0;
  
  // Threshold để khóa trục (tỷ lệ)
  // Nếu |dx| / |dy| > threshold hoặc ngược lại, khóa trục đó
  static const double _axisLockThreshold = 1.5;
  
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
    if (!_isAxisLocked) {
      final absDx = dx.abs();
      final absDy = dy.abs();
      
      // Nếu vuốt theo chiều ngang nhiều hơn chiều dọc
      if (absDx > absDy * _axisLockThreshold) {
        _isHorizontalLocked = true;
        _isAxisLocked = true;
      }
      // Nếu vuốt theo chiều dọc nhiều hơn chiều ngang
      else if (absDy > absDx * _axisLockThreshold) {
        _isHorizontalLocked = false;
        _isAxisLocked = true;
      }
    }
    
    // Bước 4: Lưu hướng vuốt (KHÔNG xoay ngay)
    // Hướng sẽ được xử lý trong onPanEnd để đảm bảo chỉ xoay một lần
    // Lưu delta cuối cùng để xác định hướng trong onPanEnd
    _lastDelta = delta;
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
  /// Logic mapping đơn giản và mượt mà:
  /// - Vuốt trên mặt nào thì xoay mặt đó theo hướng vuốt
  /// - Vuốt sang phải/trái trên mặt ngang → xoay mặt đó theo chiều ngang
  /// - Vuốt lên/xuống trên mặt dọc → xoay mặt đó theo chiều dọc
  /// 
  /// Ví dụ:
  /// - Vuốt trên mặt Front: trái = L', phải = R, lên = U', xuống = D'
  /// - Vuốt trên mặt Right: trái = R', phải = R, lên = U', xuống = D'
  /// - Vuốt trên mặt Up: trái = L', phải = R', lên = U', xuống = U
  (CubeFace?, bool) _mapSwipeToRotation(CubeFace face, SwipeDirection direction) {
    switch (face) {
      case CubeFace.right:
        // Vuốt trên mặt Right
        switch (direction) {
          case SwipeDirection.left:
            return (CubeFace.right, false); // R'
          case SwipeDirection.right:
            return (CubeFace.right, true); // R
          case SwipeDirection.up:
            return (CubeFace.up, false); // U'
          case SwipeDirection.down:
            return (CubeFace.down, false); // D'
        }
        
      case CubeFace.left:
        // Vuốt trên mặt Left
        switch (direction) {
          case SwipeDirection.left:
            return (CubeFace.left, true); // L
          case SwipeDirection.right:
            return (CubeFace.left, false); // L'
          case SwipeDirection.up:
            return (CubeFace.up, true); // U
          case SwipeDirection.down:
            return (CubeFace.down, true); // D
        }
        
      case CubeFace.up:
        // Vuốt trên mặt Up
        switch (direction) {
          case SwipeDirection.left:
            return (CubeFace.left, false); // L'
          case SwipeDirection.right:
            return (CubeFace.right, false); // R'
          case SwipeDirection.up:
            return (CubeFace.up, false); // U'
          case SwipeDirection.down:
            return (CubeFace.up, true); // U
        }
        
      case CubeFace.down:
        // Vuốt trên mặt Down
        switch (direction) {
          case SwipeDirection.left:
            return (CubeFace.left, true); // L
          case SwipeDirection.right:
            return (CubeFace.right, true); // R
          case SwipeDirection.up:
            return (CubeFace.down, true); // D
          case SwipeDirection.down:
            return (CubeFace.down, false); // D'
        }
        
      case CubeFace.front:
        // Vuốt trên mặt Front
        switch (direction) {
          case SwipeDirection.left:
            return (CubeFace.left, false); // L'
          case SwipeDirection.right:
            return (CubeFace.right, true); // R
          case SwipeDirection.up:
            return (CubeFace.up, false); // U'
          case SwipeDirection.down:
            return (CubeFace.down, false); // D'
        }
        
      case CubeFace.back:
        // Vuốt trên mặt Back
        switch (direction) {
          case SwipeDirection.left:
            return (CubeFace.right, false); // R'
          case SwipeDirection.right:
            return (CubeFace.left, true); // L
          case SwipeDirection.up:
            return (CubeFace.up, true); // U
          case SwipeDirection.down:
            return (CubeFace.down, true); // D
        }
    }
  }
}

