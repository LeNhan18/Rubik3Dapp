import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:go_router/go_router.dart';
import '../models/rubik_cube.dart';
import '../solver/rubik_solver.dart';
import '../widgets/rubik_scene.dart';
import '../services/rubik_rotation_service.dart';
import '../services/rubik_auto_service.dart';
import '../widgets/rubik_controls.dart';
import '../utils/rubik_gesture_handler.dart';

class Cube3DScreen extends StatefulWidget {
  const Cube3DScreen({Key? key}) : super(key: key);

  @override
  State<Cube3DScreen> createState() => _Cube3DScreenState();
}

class _Cube3DScreenState extends State<Cube3DScreen> with TickerProviderStateMixin {
  late Scene _scene;
  late Map<Object, List<int>> _cubeGridPositions = {};
  late Map<Object, List<Color>> _cubeFaceColors = {};
  
  late RubikCube _rubikCube;
  late RubikSolver _solver;
  
  late CameraController _cameraController;
  RubikRotationService? _rotationService;
  RubikAutoService? _autoService;
  RubikGestureHandler? _gestureHandler;
  
  bool _isRotating = false;
  bool _isAutoSwapping = false;
  bool _isAutoSolving = false;
  bool _isScaling = false; // Flag để tránh xung đột với pan gesture
  
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    _rubikCube = RubikCube();
    _solver = RubikSolver(_rubikCube);
    _cameraController = CameraController();
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _cubeGridPositions.clear();
    _cubeFaceColors.clear();

    // Tạo 27 cubes
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          final faceColors = CubeGeometryHelper.getInitialCubeColors(x, y, z);

          final mesh = Mesh(
            vertices: CubeGeometryHelper.createCubeVertices(),
            texcoords: CubeGeometryHelper.createCubeTexcoords(),
            indices: CubeGeometryHelper.createCubeIndices(),
            colors: CubeGeometryHelper.createColorsFromFaces(faceColors),
          );

          final obj = Object(
            name: 'cube_${x}_${y}_$z',
            mesh: mesh,
            position: Vector3((x - 1) * 4.0, (y - 1) * 4.0, (z - 1) * 4.0),
            scale: Vector3(1.8, 1.8, 1.8),
            backfaceCulling: false,
          );

          scene.world.add(obj);
          _cubeGridPositions[obj] = [x, y, z];
          _cubeFaceColors[obj] = faceColors;
        }
      }
    }

    // Khởi tạo services sau khi scene đã được tạo
    _rotationService = RubikRotationService(
      scene: _scene,
      cubeGridPositions: _cubeGridPositions,
      cubeFaceColors: _cubeFaceColors,
      onRotationStateChanged: () {
        if (mounted && _rotationService != null) {
          setState(() {
            _isRotating = _rotationService!.isRotating;
          });
        }
      },
    );

    _autoService = RubikAutoService(
      rotationService: _rotationService!,
      vsync: this,
      onAutoStateChanged: (isActive) {
        if (mounted && _autoService != null) {
          setState(() {
            _isAutoSwapping = _autoService!.isAutoSwapping;
            _isAutoSolving = _autoService!.isAutoSolving;
          });
        }
      },
    );

    // Thêm ánh sáng và cập nhật camera
    scene.light.position.setFrom(Vector3(15, 15, 15));
    _cameraController.updateCameraPosition(scene);
    scene.camera.target.setValues(0, 0, 0);
    
    // Khởi tạo gesture handler để xoay Rubik bằng chuột
    _gestureHandler = RubikGestureHandler(
      onRotateFace: (face, clockwise) {
        print('onRotateFace called: face = $face, clockwise = $clockwise');
        _handleRotateFace(face, clockwise);
      },
      getCameraAngles: () => [_cameraController.angleX, _cameraController.angleY],
    );
  }
  
  /// Xử lý xoay mặt từ gesture handler
  /// 
  /// QUAN TRỌNG: Hàm này chỉ map gesture sang các hàm rotate có sẵn.
  /// KHÔNG xoay Rubik trực tiếp, mà gọi các hàm _rotateR(), _rotateL(), ... đã được implement đúng.
  /// 
  /// Tại sao cách này đảm bảo xoay đúng trục?
  /// 1. Các hàm _rotateR(), _rotateL(), ... đã được implement đúng với:
  ///    - axis: trục xoay đúng (0 = X, 1 = Y, 2 = Z)
  ///    - layer: lớp cần xoay đúng (0, 1, 2 hoặc -1 cho M, E, S)
  ///    - clockwise: chiều xoay đúng (true/false)
  /// 
  /// 2. Các hàm này gọi rotationService.rotateFace() với tham số đúng
  /// 
  /// 3. rotationService.rotateFace() đã được implement đúng để:
  ///    - Xoay đúng các cube con trong layer tương ứng
  ///    - Xoay quanh tâm Rubik (không lệch)
  ///    - Cập nhật đúng vị trí và màu sắc
  /// 
  /// → Vì vậy, gesture chỉ cần xác định MOVE (R, R', U, U', ...) và gọi hàm tương ứng.
  /// → Không cần viết lại logic xoay, đảm bảo xoay đúng trục, đúng tâm.
  void _handleRotateFace(CubeFace face, bool clockwise) {
    if (_isRotating || _rotationService == null) return;
    
    // Map gesture sang các hàm rotate có sẵn
    // Mỗi hàm này đã được implement đúng với axis, layer, clockwise đúng
    switch (face) {
      case CubeFace.right:
        if (clockwise) {
          _rotateR();
        } else {
          _rotateRPrime();
        }
        break;
      case CubeFace.left:
        if (clockwise) {
          _rotateL();
        } else {
          _rotateLPrime();
        }
        break;
      case CubeFace.up:
        if (clockwise) {
          _rotateU();
        } else {
          _rotateUPrime();
        }
        break;
      case CubeFace.down:
        if (clockwise) {
          _rotateD();
        } else {
          _rotateDPrime();
        }
        break;
      case CubeFace.front:
        if (clockwise) {
          _rotateF();
        } else {
          _rotateFPrime();
        }
        break;
      case CubeFace.back:
        if (clockwise) {
          _rotateB();
        } else {
          _rotateBPrime();
        }
        break;
    }
  }

  /// Xử lý khi bắt đầu xoay camera (xoay xung quanh Rubik)
  /// 
  /// QUAN TRỌNG: Logic xoay camera xung quanh Rubik vẫn được giữ nguyên!
  /// - 2 ngón tay trở lên = xoay camera xung quanh Rubik
  /// - Logic này không thay đổi, vẫn hoạt động bình thường
  void _onScaleStart(ScaleStartDetails details) {
    // Chỉ set _isScaling = true khi thực sự là multi-touch (2+ ngón tay)
    // Logic này được xử lý trong RubikScene, chỉ gọi khi pointerCount >= 2
    _isScaling = true; // Đang xoay camera, không cho xoay Rubik
    _lastFocalPoint = details.focalPoint;
    _cameraController.updateCameraPosition(_scene);
  }

  /// Xử lý khi đang xoay camera (xoay xung quanh Rubik)
  /// 
  /// QUAN TRỌNG: Logic xoay camera xung quanh Rubik vẫn được giữ nguyên!
  /// - Pan (kéo): Xoay camera xung quanh Rubik
  /// - Scale (pinch): Zoom in/out
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final currentFocal = details.focalPoint;

    // Xử lý pan (kéo để xoay camera xung quanh Rubik)
    // Logic này vẫn được giữ nguyên, không thay đổi
    if (_lastFocalPoint != null) {
      final delta = currentFocal - _lastFocalPoint!;
      _cameraController.updateFromPan(delta);
    }

    // Xử lý scale (pinch zoom)
    // Logic này vẫn được giữ nguyên, không thay đổi
    if (details.scale != 1.0) {
      _cameraController.updateFromScale(details.scale);
    }

    _lastFocalPoint = currentFocal;
    _cameraController.updateCameraPosition(_scene);
    setState(() {});
  }

  /// Xử lý khi kết thúc xoay camera (xoay xung quanh Rubik)
  /// 
  /// QUAN TRỌNG: Logic xoay camera xung quanh Rubik vẫn được giữ nguyên!
  void _onScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
    _isScaling = false; // Kết thúc xoay camera, cho phép xoay Rubik
  }

  // Rotation methods
  void _rotateR() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: true, vsync: this);
  }

  void _rotateRPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: false, vsync: this);
  }

  void _rotateL() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: false, vsync: this);
  }

  void _rotateLPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: true, vsync: this);
  }

  void _rotateU() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: false, vsync: this);
  }

  void _rotateUPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: true, vsync: this);
  }

  void _rotateD() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: false, vsync: this);
  }

  void _rotateDPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: true, vsync: this);
  }

  void _rotateF() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: false, vsync: this);
  }

  void _rotateFPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: true, vsync: this);
  }

  void _rotateB() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: true, vsync: this);
  }

  void _rotateBPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: false, vsync: this);
  }

  void _rotateM() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: false, vsync: this);
  }

  void _rotateMPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: true, vsync: this);
  }

  void _rotateE() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: false, vsync: this);
  }

  void _rotateEPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: true, vsync: this);
  }

  void _rotateS() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: false, vsync: this);
  }

  void _rotateSPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: true, vsync: this);
  }

  Future<void> _autoSwap() async {
    if (_autoService == null) return;
    await _autoService!.autoSwap();
  }

  Future<void> _autoSolve() async {
    if (_autoService == null) return;
    await _autoService!.autoSolve();
  }

  void _stopAutoOperations() {
    _autoService?.stopAutoOperations();
  }

  void _resetCube() {
    if (_isRotating || _isAutoSwapping || _isAutoSolving) return;

    setState(() {
      _isRotating = true;
    });

    // Khôi phục màu sắc ban đầu cho tất cả các cube
    for (final entry in _cubeGridPositions.entries) {
      final cube = entry.key;
      final gridPos = entry.value;
      final x = gridPos[0];
      final y = gridPos[1];
      final z = gridPos[2];

      _cubeFaceColors[cube] = CubeGeometryHelper.getInitialCubeColors(x, y, z);

      // Cập nhật mesh với màu mới
      cube.mesh.colors = CubeGeometryHelper.createColorsFromFaces(_cubeFaceColors[cube]!);
    }

    // Khởi tạo lại cube model
    _rubikCube = RubikCube();
    _solver = RubikSolver(_rubikCube);

    setState(() {
      _isRotating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Về trang chủ',
        ),
        title: const Text('Rubik\'s Cube - Ký Hiệu Chuẩn'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: RubikScene(
              onSceneCreated: _onSceneCreated,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              // Gesture để xoay Rubik bằng chuột
              // Không cần kiểm tra _isScaling vì logic đã được xử lý trong RubikScene
              onPanStart: _gestureHandler?.handlePanStart,
              onPanUpdate: _gestureHandler?.handlePanUpdate,
              onPanEnd: _gestureHandler?.handlePanEnd,
            ),
          ),
          Expanded(
            flex: 2,
            child: RubikControls(
              isRotating: _isRotating,
              isAutoSwapping: _isAutoSwapping,
              isAutoSolving: _isAutoSolving,
              onRotateR: _rotateR,
              onRotateRPrime: _rotateRPrime,
              onRotateL: _rotateL,
              onRotateLPrime: _rotateLPrime,
              onRotateU: _rotateU,
              onRotateUPrime: _rotateUPrime,
              onRotateD: _rotateD,
              onRotateDPrime: _rotateDPrime,
              onRotateF: _rotateF,
              onRotateFPrime: _rotateFPrime,
              onRotateB: _rotateB,
              onRotateBPrime: _rotateBPrime,
              onRotateM: _rotateM,
              onRotateMPrime: _rotateMPrime,
              onRotateE: _rotateE,
              onRotateEPrime: _rotateEPrime,
              onRotateS: _rotateS,
              onRotateSPrime: _rotateSPrime,
              onAutoSwap: _autoSwap,
              onAutoSolve: _autoSolve,
              onStop: _stopAutoOperations,
              onReset: _resetCube,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rotationService?.dispose();
    super.dispose();
  }
}
