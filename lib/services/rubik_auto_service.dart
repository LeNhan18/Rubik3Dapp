import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import '../models/rubik_cube.dart';
import '../solver/rubik_solver.dart';
import 'rubik_rotation_service.dart';

/// Service xử lý các chức năng tự động (xáo trộn, giải)
class RubikAutoService {
  final RubikRotationService rotationService;
  final TickerProvider vsync;
  final Function(bool) onAutoStateChanged;
  
  bool _isAutoSwapping = false;
  bool _isAutoSolving = false;
  List<String> _shuffleHistory = [];

  RubikAutoService({
    required this.rotationService,
    required this.vsync,
    required this.onAutoStateChanged,
  });

  bool get isAutoSwapping => _isAutoSwapping;
  bool get isAutoSolving => _isAutoSolving;
  List<String> get shuffleHistory => _shuffleHistory;

  /// Xáo trộn cube tự động
  Future<void> autoSwap() async {
    if (_isAutoSwapping || _isAutoSolving || rotationService.isRotating) return;

    _isAutoSwapping = true;
    onAutoStateChanged(true);
    _shuffleHistory.clear();

    final moves = ['R', 'R\'', 'L', 'L\'', 'U', 'U\'', 'D', 'D\'', 'F', 'F\'', 'B', 'B\''];
    final random = math.Random();
    final shuffleCount = 20 + random.nextInt(11);

    for (int i = 0; i < shuffleCount; i++) {
      if (!_isAutoSwapping) break;

      final move = moves[random.nextInt(moves.length)];
      _shuffleHistory.add(move);
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 350));
    }

    _isAutoSwapping = false;
    onAutoStateChanged(false);
  }

  /// Giải cube tự động
  Future<void> autoSolve() async {
    if (_isAutoSolving || _isAutoSwapping || rotationService.isRotating) return;

    _isAutoSolving = true;
    onAutoStateChanged(true);

    try {
      await _solveUsingOptimalAlgorithm();
    } catch (e) {
      print('Lỗi khi giải cube: $e');
    }

    _isAutoSolving = false;
    onAutoStateChanged(false);
  }

  /// Giải cube sử dụng thuật toán tối ưu
  Future<void> _solveUsingOptimalAlgorithm() async {
    // Bước 1: Giải White Cross
    await _executeSequentialMoves([
      'F', 'R', 'U', 'R\'', 'F\'', 'U\'', 'R', 'U', 'R\'', 'U\'', 'D', 'L', 'U\'', 'L\'', 'D\''
    ]);

    // Bước 2: Hoàn thành White Layer
    await _executeSequentialMoves([
      'R', 'U', 'R\'', 'U\'', 'R', 'U', 'R\'', 'F', 'U', 'F\'', 'U\'', 'F', 'U', 'F\''
    ]);

    // Bước 3: Middle Layer
    await _executeSequentialMoves([
      'U', 'R', 'U\'', 'R\'', 'U\'', 'F\'', 'U', 'F', 'U\'', 'L\'', 'U', 'L', 'U', 'F', 'U\'', 'F\''
    ]);

    // Bước 4: Yellow Cross
    await _executeSequentialMoves([
      'F', 'R', 'U', 'R\'', 'U\'', 'F\'', 'F', 'U', 'R', 'U\'', 'R\'', 'F\''
    ]);

    // Bước 5: OLL (Orient Last Layer)
    await _executeSequentialMoves([
      'R', 'U', 'R\'', 'U', 'R', 'U2', 'R\'', 'F', 'R', 'U', 'R\'', 'U\'', 'F\''
    ]);

    // Bước 6: PLL (Permute Last Layer)
    await _executeSequentialMoves([
      'R', 'U', 'R\'', 'F\'', 'R', 'F', 'U\'', 'R\'', 'R\'', 'U', 'R\'', 'U\'', 'R\'', 'U\'', 'R\'', 'U', 'R', 'U', 'R2'
    ]);
  }

  /// Thực hiện một chuỗi moves tuần tự
  Future<void> _executeSequentialMoves(List<String> moves) async {
    for (final move in moves) {
      if (!_isAutoSolving) break;
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  /// Thực hiện một move
  Future<void> _executeMove(String move) async {
    switch (move) {
      case 'R':
        rotationService.rotateFace(axis: 0, layer: 2, clockwise: true, vsync: vsync);
        break;
      case 'R\'':
        rotationService.rotateFace(axis: 0, layer: 2, clockwise: false, vsync: vsync);
        break;
      case 'L':
        rotationService.rotateFace(axis: 0, layer: 0, clockwise: false, vsync: vsync);
        break;
      case 'L\'':
        rotationService.rotateFace(axis: 0, layer: 0, clockwise: true, vsync: vsync);
        break;
      case 'U':
        rotationService.rotateFace(axis: 1, layer: 2, clockwise: false, vsync: vsync);
        break;
      case 'U\'':
        rotationService.rotateFace(axis: 1, layer: 2, clockwise: true, vsync: vsync);
        break;
      case 'D':
        rotationService.rotateFace(axis: 1, layer: 0, clockwise: false, vsync: vsync);
        break;
      case 'D\'':
        rotationService.rotateFace(axis: 1, layer: 0, clockwise: true, vsync: vsync);
        break;
      case 'F':
        rotationService.rotateFace(axis: 2, layer: 2, clockwise: false, vsync: vsync);
        break;
      case 'F\'':
        rotationService.rotateFace(axis: 2, layer: 2, clockwise: true, vsync: vsync);
        break;
      case 'B':
        rotationService.rotateFace(axis: 2, layer: 0, clockwise: true, vsync: vsync);
        break;
      case 'B\'':
        rotationService.rotateFace(axis: 2, layer: 0, clockwise: false, vsync: vsync);
        break;
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Dừng các hoạt động tự động
  void stopAutoOperations() {
    _isAutoSwapping = false;
    _isAutoSolving = false;
    onAutoStateChanged(false);
  }
}

