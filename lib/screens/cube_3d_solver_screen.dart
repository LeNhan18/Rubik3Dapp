import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:go_router/go_router.dart';
import '../models/rubik_cube.dart';
import '../solver/rubik_solver.dart';
import '../widgets/rubik_scene.dart';
import '../services/rubik_rotation_service.dart';
import '../services/rubik_auto_service.dart';
import '../services/rubik_solver_service.dart';

class Cube3DSolverScreen extends StatefulWidget {
  const Cube3DSolverScreen({Key? key}) : super(key: key);

  @override
  State<Cube3DSolverScreen> createState() => _Cube3DSolverScreenState();
}

class _Cube3DSolverScreenState extends State<Cube3DSolverScreen> with TickerProviderStateMixin {
  late Scene _scene;
  late Map<Object, List<int>> _cubeGridPositions = {};
  late Map<Object, List<Color>> _cubeFaceColors = {};
  
  late RubikCube _rubikCube;
  late RubikSolver _solver;
  RubikSolverService? _solverService;
  
  late CameraController _cameraController;
  RubikRotationService? _rotationService;
  RubikAutoService? _autoService;
  
  bool _isRotating = false;
  bool _isShuffling = false;
  bool _isSolving = false;
  bool _hasShuffled = false;
  bool _isTrackingMoves = false; // Bật/tắt tracking moves
  
  List<String> _userMoves = []; // Lưu các moves người dùng đã làm
  List<String> _solutionSteps = [];
  int _currentStepIndex = 0;
  String? _currentStep;
  
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
            _isShuffling = _autoService!.isAutoSwapping;
            _isSolving = _autoService!.isAutoSolving;
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

  /// Bắt đầu tracking moves của người dùng
  void _startTrackingMoves() {
    setState(() {
      _isTrackingMoves = true;
      _userMoves.clear();
      _hasShuffled = false;
      _solutionSteps.clear();
      _currentStepIndex = 0;
      _currentStep = null;
      _solverService = null;
    });
  }

  /// Dừng tracking và tạo giải pháp ngược lại
  void _stopTrackingAndSolve() {
    if (_userMoves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có moves nào được ghi nhận!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTrackingMoves = false;
      _hasShuffled = true;
      // Đảo ngược các moves để giải
      _solutionSteps = _reverseMoves(_userMoves);
      _currentStepIndex = 0;
      _currentStep = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã ghi nhận ${_userMoves.length} moves. Giải pháp: ${_solutionSteps.length} bước.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Đảo ngược một move
  String _reverseMove(String move) {
    switch (move) {
      case 'R':
        return 'R\'';
      case 'R\'':
        return 'R';
      case 'L':
        return 'L\'';
      case 'L\'':
        return 'L';
      case 'U':
        return 'U\'';
      case 'U\'':
        return 'U';
      case 'D':
        return 'D\'';
      case 'D\'':
        return 'D';
      case 'F':
        return 'F\'';
      case 'F\'':
        return 'F';
      case 'B':
        return 'B\'';
      case 'B\'':
        return 'B';
      case 'M':
        return 'M\'';
      case 'M\'':
        return 'M';
      case 'E':
        return 'E\'';
      case 'E\'':
        return 'E';
      case 'S':
        return 'S\'';
      case 'S\'':
        return 'S';
      default:
        return move;
    }
  }

  /// Đảo ngược toàn bộ moves (theo thứ tự ngược lại và đảo chiều)
  List<String> _reverseMoves(List<String> moves) {
    // Đảo ngược thứ tự và đảo chiều từng move
    return moves.reversed.map((move) => _reverseMove(move)).toList();
  }

  /// Ghi lại move khi người dùng xoay mặt
  void _recordUserMove(String move) {
    if (_isTrackingMoves) {
      setState(() {
        _userMoves.add(move);
      });
    }
  }

  // Các hàm xoay mặt và ghi lại moves
  void _rotateR() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: true, vsync: this);
    _recordUserMove('R');
    _applyMoveToModel('R');
  }

  void _rotateRPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: false, vsync: this);
    _recordUserMove('R\'');
    _applyMoveToModel('R\'');
  }

  void _rotateL() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: false, vsync: this);
    _recordUserMove('L');
    _applyMoveToModel('L');
  }

  void _rotateLPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: true, vsync: this);
    _recordUserMove('L\'');
    _applyMoveToModel('L\'');
  }

  void _rotateU() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: false, vsync: this);
    _recordUserMove('U');
    _applyMoveToModel('U');
  }

  void _rotateUPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: true, vsync: this);
    _recordUserMove('U\'');
    _applyMoveToModel('U\'');
  }

  void _rotateD() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: false, vsync: this);
    _recordUserMove('D');
    _applyMoveToModel('D');
  }

  void _rotateDPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: true, vsync: this);
    _recordUserMove('D\'');
    _applyMoveToModel('D\'');
  }

  void _rotateF() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: false, vsync: this);
    _recordUserMove('F');
    _applyMoveToModel('F');
  }

  void _rotateFPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: true, vsync: this);
    _recordUserMove('F\'');
    _applyMoveToModel('F\'');
  }

  void _rotateB() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: true, vsync: this);
    _recordUserMove('B');
    _applyMoveToModel('B');
  }

  void _rotateBPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: false, vsync: this);
    _recordUserMove('B\'');
    _applyMoveToModel('B\'');
  }

  void _rotateM() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: false, vsync: this);
    _recordUserMove('M');
  }

  void _rotateMPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: true, vsync: this);
    _recordUserMove('M\'');
  }

  void _rotateE() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: false, vsync: this);
    _recordUserMove('E');
  }

  void _rotateEPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: true, vsync: this);
    _recordUserMove('E\'');
  }

  void _rotateS() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: false, vsync: this);
    _recordUserMove('S');
  }

  void _rotateSPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: true, vsync: this);
    _recordUserMove('S\'');
  }

  /// Shuffle cube và đồng bộ với RubikCube model
  Future<void> _shuffleCube() async {
    if (_isRotating || _isShuffling || _isSolving || _rotationService == null || _autoService == null) return;

    setState(() {
      _hasShuffled = false;
      _solutionSteps.clear();
      _currentStepIndex = 0;
      _currentStep = null;
      _solverService = null;
    });

    // Reset cube model về trạng thái đã giải
    _rubikCube = RubikCube();
    _solver = RubikSolver(_rubikCube);

    // Shuffle cube 3D (autoSwap sẽ tự động generate moves và áp dụng vào 3D scene)
    await _autoService!.autoSwap();

    // Sau khi shuffle xong, áp dụng các moves vào RubikCube model để đồng bộ
    // Lưu lại shuffle history trước khi nó bị clear
    final shuffleMoves = List<String>.from(_autoService!.shuffleHistory);
    
    // Áp dụng các moves vào RubikCube model để đồng bộ
    for (final move in shuffleMoves) {
      await _applyMoveToModel(move);
      await Future.delayed(const Duration(milliseconds: 30));
    }

    setState(() {
      _hasShuffled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xáo cube với ${shuffleMoves.length} bước! Bấm "Tìm giải pháp" để giải.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  /// Áp dụng move vào RubikCube model
  Future<void> _applyMoveToModel(String move) async {
    switch (move) {
      case 'R':
        _rubikCube.rotateFace('right', true);
        break;
      case 'R\'':
        _rubikCube.rotateFace('right', false);
        break;
      case 'L':
        _rubikCube.rotateFace('left', true);
        break;
      case 'L\'':
        _rubikCube.rotateFace('left', false);
        break;
      case 'U':
        _rubikCube.rotateFace('up', true);
        break;
      case 'U\'':
        _rubikCube.rotateFace('up', false);
        break;
      case 'D':
        _rubikCube.rotateFace('down', true);
        break;
      case 'D\'':
        _rubikCube.rotateFace('down', false);
        break;
      case 'F':
        _rubikCube.rotateFace('front', true);
        break;
      case 'F\'':
        _rubikCube.rotateFace('front', false);
        break;
      case 'B':
        _rubikCube.rotateFace('back', true);
        break;
      case 'B\'':
        _rubikCube.rotateFace('back', false);
        break;
    }
  }

  /// Tìm giải pháp
  Future<void> _findSolution() async {
    if (!_hasShuffled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng xáo cube trước!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isRotating || _isShuffling || _isSolving) return;

    setState(() {
      _isSolving = true;
    });

    // Tạo solver service từ cube model hiện tại
    _solverService = RubikSolverService(_rubikCube);
    final steps = _solverService!.generateSolution();

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _solutionSteps = steps;
      _currentStepIndex = 0;
      _currentStep = null;
      _isSolving = false;
    });

    if (_solutionSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cube đã được giải rồi!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tìm thấy ${_solutionSteps.length} bước giải!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Áp dụng bước tiếp theo vào cube 3D
  Future<void> _applyNextStep() async {
    if (_isRotating || _isShuffling || _isSolving || _solutionSteps.isEmpty) return;

    // Nếu đã hết các bước
    if (_currentStepIndex >= _solutionSteps.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hết các bước giải!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Lấy bước tiếp theo từ danh sách
    final nextStep = _solutionSteps[_currentStepIndex];
    
    setState(() {
      _currentStep = nextStep;
      _currentStepIndex++;
    });

    // Áp dụng move vào cube 3D
    await _applyMoveTo3D(nextStep);
    
    // Nếu có solverService, cũng cập nhật nó
    if (_solverService != null) {
      _solverService!.getNextStep(); // Để cập nhật internal state
    }
  }

  /// Áp dụng move vào cube 3D và đợi animation hoàn thành
  Future<void> _applyMoveTo3D(String move) async {
    if (_rotationService == null) return;

    // Đợi cho đến khi không còn đang xoay
    while (_isRotating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    switch (move) {
      case 'R':
        _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: true, vsync: this);
        break;
      case 'R\'':
        _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: false, vsync: this);
        break;
      case 'L':
        _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: false, vsync: this);
        break;
      case 'L\'':
        _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: true, vsync: this);
        break;
      case 'U':
        _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: false, vsync: this);
        break;
      case 'U\'':
        _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: true, vsync: this);
        break;
      case 'D':
        _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: false, vsync: this);
        break;
      case 'D\'':
        _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: true, vsync: this);
        break;
      case 'F':
        _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: false, vsync: this);
        break;
      case 'F\'':
        _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: true, vsync: this);
        break;
      case 'B':
        _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: true, vsync: this);
        break;
      case 'B\'':
        _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: false, vsync: this);
        break;
      case 'M':
        _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: false, vsync: this);
        break;
      case 'M\'':
        _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: true, vsync: this);
        break;
      case 'E':
        _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: false, vsync: this);
        break;
      case 'E\'':
        _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: true, vsync: this);
        break;
      case 'S':
        _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: false, vsync: this);
        break;
      case 'S\'':
        _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: true, vsync: this);
        break;
    }

    // Đợi animation hoàn thành (500ms + buffer)
    await Future.delayed(const Duration(milliseconds: 550));
    
    // Đợi thêm một chút để đảm bảo _isRotating đã được set về false
    while (_isRotating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Tự động giải tất cả các bước
  Future<void> _autoSolveAll() async {
    if (_isRotating || _isShuffling || _isSolving) return;

    if (_solutionSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có giải pháp! Vui lòng tìm giải pháp trước.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSolving = true;
      // Reset về đầu để giải từ đầu
      _currentStepIndex = 0;
      _currentStep = null;
    });

    // Reset về đầu nếu cần
    if (_solverService != null) {
      _solverService!.reset();
    }
    
    // Bắt đầu từ đầu
    for (int i = 0; i < _solutionSteps.length; i++) {
      if (!mounted) break;
      final step = _solutionSteps[i];
      setState(() {
        _currentStep = step;
        _currentStepIndex = i + 1;
      });
      // _applyMoveTo3D đã đợi animation hoàn thành rồi, không cần delay thêm
      await _applyMoveTo3D(step);
    }

    setState(() {
      _isSolving = false;
      _currentStep = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã giải xong cube!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Reset cube về trạng thái ban đầu
  void _resetCube() {
    if (_isRotating || _isShuffling || _isSolving) return;

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
      cube.mesh.colors = CubeGeometryHelper.createColorsFromFaces(_cubeFaceColors[cube]!);
    }

    // Khởi tạo lại cube model
    _rubikCube = RubikCube();
    _solver = RubikSolver(_rubikCube);
    _solverService = null;
    _solutionSteps.clear();
    _currentStepIndex = 0;
    _currentStep = null;
    _hasShuffled = false;
    _isTrackingMoves = false;
    _userMoves.clear();

    setState(() {
      _isRotating = false;
    });
  }

  /// Widget để tạo nút xoay
  Widget _buildRotationButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: (_isRotating || _isShuffling || _isSolving || !_isTrackingMoves) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(50, 36),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
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
        title: const Text('Rubik Solver 3D'),
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
            child: Container(
              color: Colors.deepPurple[800],
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nút điều khiển tracking
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: (_isRotating || _isShuffling || _isSolving) ? null : (_isTrackingMoves ? null : _startTrackingMoves),
                          icon: Icon(_isTrackingMoves ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                          label: Text(_isTrackingMoves ? 'Đang ghi nhận...' : 'Bắt đầu ghi nhận'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTrackingMoves ? Colors.green : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: (_isRotating || _isShuffling || _isSolving || !_isTrackingMoves) ? null : _stopTrackingAndSolve,
                          icon: const Icon(Icons.stop),
                          label: const Text('Dừng & Tìm giải'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: (_isRotating || _isShuffling || _isSolving) ? null : _shuffleCube,
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Xáo Tự Động'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: (_isRotating || _isShuffling || _isSolving) ? null : _resetCube,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Hiển thị số moves đã ghi nhận
                    if (_isTrackingMoves || _userMoves.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isTrackingMoves ? Icons.fiber_manual_record : Icons.check_circle,
                              color: _isTrackingMoves ? Colors.green : Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Đã ghi nhận: ${_userMoves.length} moves',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Nút xoay các mặt (chỉ hiện khi đang tracking)
                    if (_isTrackingMoves) ...[
                      const Text(
                        'Xoay cube để xáo:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildRotationButton('R', _rotateR),
                          _buildRotationButton('R\'', _rotateRPrime),
                          _buildRotationButton('L', _rotateL),
                          _buildRotationButton('L\'', _rotateLPrime),
                          _buildRotationButton('U', _rotateU),
                          _buildRotationButton('U\'', _rotateUPrime),
                          _buildRotationButton('D', _rotateD),
                          _buildRotationButton('D\'', _rotateDPrime),
                          _buildRotationButton('F', _rotateF),
                          _buildRotationButton('F\'', _rotateFPrime),
                          _buildRotationButton('B', _rotateB),
                          _buildRotationButton('B\'', _rotateBPrime),
                          _buildRotationButton('M', _rotateM),
                          _buildRotationButton('M\'', _rotateMPrime),
                          _buildRotationButton('E', _rotateE),
                          _buildRotationButton('E\'', _rotateEPrime),
                          _buildRotationButton('S', _rotateS),
                          _buildRotationButton('S\'', _rotateSPrime),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Hiển thị các moves đã ghi nhận
                    if (_userMoves.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Moves đã ghi nhận:',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: _userMoves.map((move) => Chip(
                                label: Text(move, style: const TextStyle(fontSize: 11)),
                                backgroundColor: Colors.blue[700],
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    // Hiển thị trạng thái
                    if (_isShuffling)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Đang xáo cube...',
                            style: TextStyle(color: Colors.orange, fontSize: 14),
                          ),
                        ),
                      ),
                    if (_isSolving)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Đang giải cube...',
                            style: TextStyle(color: Colors.green, fontSize: 14),
                          ),
                        ),
                      ),
                    // Nút giải pháp
                    if (_solutionSteps.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (_isRotating || _isShuffling || _isSolving || _solutionSteps.isEmpty) ? null : _applyNextStep,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Bước Tiếp Theo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: (_isRotating || _isShuffling || _isSolving || _solutionSteps.isEmpty) ? null : _autoSolveAll,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Tự Động Giải'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Hiển thị giải pháp
                    if (_solutionSteps.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Giải pháp (${_currentStepIndex}/${_solutionSteps.length}):',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: _solutionSteps.asMap().entries.map((entry) {
                                final index = entry.key;
                                final step = entry.value;
                                final isCurrent = index == _currentStepIndex - 1;
                                final isCompleted = index < _currentStepIndex - 1;
                                return Chip(
                                  label: Text(
                                    step,
                                    style: TextStyle(
                                      color: isCurrent ? Colors.white : Colors.grey[300],
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  backgroundColor: isCurrent
                                      ? Colors.green
                                      : isCompleted
                                          ? Colors.green[800]
                                          : Colors.grey[700],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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

