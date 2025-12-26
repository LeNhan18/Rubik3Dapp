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
  
  bool _isRotating = false;
  bool _isAutoSwapping = false;
  bool _isAutoSolving = false;
  
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
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _cameraController.updateCameraPosition(_scene);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final currentFocal = details.focalPoint;

    // Xử lý pan (kéo để xoay camera)
    if (_lastFocalPoint != null) {
      final delta = currentFocal - _lastFocalPoint!;
      _cameraController.updateFromPan(delta);
    }

    // Xử lý scale (pinch zoom)
    if (details.scale != 1.0) {
      _cameraController.updateFromScale(details.scale);
    }

    _lastFocalPoint = currentFocal;
    _cameraController.updateCameraPosition(_scene);
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
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
