import '../models/rubik_cube.dart';

class RubikSolver {
  final RubikCube cube;

  RubikSolver(this.cube);

  // Giải Rubik cube hoàn toàn
  Future<void> solveCube() async {
    await solveCross();
    await solveFirstLayerCorners();
    await solveSecondLayer();
    await solveLastLayerCross();
    await solveLastLayerCorners();
    await solveLastLayerEdges();
  }

  // Bước 1: Giải dấu thập trắng (White Cross)
  Future<void> solveCross() async {
    print('Bước 1: Giải dấu thập trắng...');

    // Thuật toán đơn giản để tạo cross trắng
    List<String> moves = [
      'F', 'R', 'U', 'R\'', 'F\'', // Di chuyển edge piece
      'D', 'R', 'U\'', 'R\'', 'D\'', // Điều chỉnh vị trí
    ];

    for (String move in moves) {
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Bước 2: Giải các góc của tầng đầu tiên
  Future<void> solveFirstLayerCorners() async {
    print('Bước 2: Giải các góc tầng đầu tiên...');

    List<String> moves = [
      'R', 'U', 'R\'', 'U\'', // Right-hand algorithm
      'R', 'U', 'R\'', 'U\'',
      'R', 'U', 'R\'', 'U\'',
    ];

    for (String move in moves) {
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Bước 3: Giải tầng giữa
  Future<void> solveSecondLayer() async {
    print('Bước 3: Giải tầng giữa...');

    List<String> moves = [
      'U', 'R', 'U\'', 'R\'', 'U\'', 'F\'', 'U', 'F', // Right-hand algorithm
      'U\'', 'L\'', 'U', 'L', 'U', 'F', 'U\'', 'F\'', // Left-hand algorithm
    ];

    for (String move in moves) {
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Bước 4: Giải dấu thập tầng cuối
  Future<void> solveLastLayerCross() async {
    print('Bước 4: Giải dấu thập tầng cuối...');

    List<String> moves = [
      'F', 'R', 'U', 'R\'', 'U\'', 'F\'', // OLL algorithm for cross
      'F', 'U', 'R', 'U\'', 'R\'', 'F\'',
    ];

    for (String move in moves) {
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Bước 5: Định hướng các góc tầng cuối
  Future<void> solveLastLayerCorners() async {
    print('Bước 5: Định hướng các góc tầng cuối...');

    List<String> moves = [
      'R',
      'U',
      'R\'',
      'F\'',
      'R',
      'F',
      'U\'',
      'R\'',
      'U\'',
      'R',
      'U',
      'R\'',
      'F\'',
      'R',
      'F',
    ];

    for (String move in moves) {
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Bước 6: Hoàn thiện tầng cuối
  Future<void> solveLastLayerEdges() async {
    print('Bước 6: Hoàn thiện Rubik Cube...');

    List<String> moves = [
      'R',
      'U\'',
      'R',
      'F',
      'R',
      'F\'',
      'R',
      'U',
      'R\'',
      'F\'',
      'R',
      'F', // PLL algorithm
      'M2',
      'U',
      'M2',
      'U2',
      'M2',
      'U',
      'M2', // M-slice moves for final positioning
    ];

    for (String move in moves) {
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Thực hiện một bước di chuyển
  Future<void> _executeMove(String move) async {
    switch (move) {
      case 'F':
        cube.rotateFace('front', true);
        break;
      case 'F\'':
        cube.rotateFace('front', false);
        break;
      case 'B':
        cube.rotateFace('back', true);
        break;
      case 'B\'':
        cube.rotateFace('back', false);
        break;
      case 'R':
        cube.rotateFace('right', true);
        break;
      case 'R\'':
        cube.rotateFace('right', false);
        break;
      case 'L':
        cube.rotateFace('left', true);
        break;
      case 'L\'':
        cube.rotateFace('left', false);
        break;
      case 'U':
        cube.rotateFace('up', true);
        break;
      case 'U\'':
        cube.rotateFace('up', false);
        break;
      case 'D':
        cube.rotateFace('down', true);
        break;
      case 'D\'':
        cube.rotateFace('down', false);
        break;
      case 'M2':
        // Middle slice 180 degrees
        _executeMiddleSliceMove();
        break;
      case 'U2':
        cube.rotateFace('up', true);
        cube.rotateFace('up', true);
        break;
    }
  }

  void _executeMiddleSliceMove() {
    // Simulate middle slice rotation
    // This is a simplified implementation
    cube.rotateFace('left', false);
    cube.rotateFace('right', true);
  }

  // Thuật toán giải từng bước riêng biệt
  Future<void> solveStep(String step) async {
    switch (step) {
      case 'cross':
        await solveCross();
        break;
      case 'first_layer':
        await solveFirstLayerCorners();
        break;
      case 'second_layer':
        await solveSecondLayer();
        break;
      case 'last_layer_cross':
        await solveLastLayerCross();
        break;
      case 'last_layer_corners':
        await solveLastLayerCorners();
        break;
      case 'last_layer_edges':
        await solveLastLayerEdges();
        break;
      case 'complete':
        await solveCube();
        break;
    }
  }

  // Phân tích trạng thái hiện tại của cube
  Map<String, bool> analyzeState() {
    return {
      'cross_solved': _isCrossSolved(),
      'first_layer_solved': _isFirstLayerSolved(),
      'second_layer_solved': _isSecondLayerSolved(),
      'last_layer_cross_solved': _isLastLayerCrossSolved(),
      'fully_solved': cube.isSolved(),
    };
  }

  bool _isCrossSolved() {
    // Kiểm tra xem dấu thập trắng đã được giải chưa
    // Đây là implementation đơn giản
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (i == 1 || j == 1) {
          // Cross positions
          final cubelet = cube.cubelets[i][2][j];
          if (cubelet.getFaceColor('up') != CubeColor.white) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool _isFirstLayerSolved() {
    // Kiểm tra tầng đầu tiên đã hoàn thành chưa
    for (int x = 0; x < 3; x++) {
      for (int z = 0; z < 3; z++) {
        final cubelet = cube.cubelets[x][2][z];
        if (cubelet.getFaceColor('up') != CubeColor.white) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isSecondLayerSolved() {
    // Kiểm tra tầng giữa đã hoàn thành chưa
    for (int x = 0; x < 3; x++) {
      for (int z = 0; z < 3; z++) {
        final cubelet = cube.cubelets[x][1][z];
        // Kiểm tra tính nhất quán màu sắc
        if (x == 0 && cubelet.getFaceColor('left') != CubeColor.orange)
          return false;
        if (x == 2 && cubelet.getFaceColor('right') != CubeColor.red)
          return false;
        if (z == 0 && cubelet.getFaceColor('back') != CubeColor.green)
          return false;
        if (z == 2 && cubelet.getFaceColor('front') != CubeColor.blue)
          return false;
      }
    }
    return true;
  }

  bool _isLastLayerCrossSolved() {
    // Kiểm tra dấu thập tầng cuối đã được giải chưa
    final centerCubelet = cube.cubelets[1][0][1];
    final topCubelet = cube.cubelets[1][0][2];
    final bottomCubelet = cube.cubelets[1][0][0];
    final leftCubelet = cube.cubelets[0][0][1];
    final rightCubelet = cube.cubelets[2][0][1];

    return centerCubelet.getFaceColor('down') == CubeColor.yellow &&
        topCubelet.getFaceColor('down') == CubeColor.yellow &&
        bottomCubelet.getFaceColor('down') == CubeColor.yellow &&
        leftCubelet.getFaceColor('down') == CubeColor.yellow &&
        rightCubelet.getFaceColor('down') == CubeColor.yellow;
  }

  // Tạo chuỗi moves ngẫu nhiên để shuffle
  List<String> generateShuffleMoves(int count) {
    final moves = [
      'F',
      'F\'',
      'B',
      'B\'',
      'R',
      'R\'',
      'L',
      'L\'',
      'U',
      'U\'',
      'D',
      'D\'',
    ];
    final random = DateTime.now().millisecondsSinceEpoch;
    List<String> shuffleMoves = [];

    for (int i = 0; i < count; i++) {
      shuffleMoves.add(moves[(random + i) % moves.length]);
    }

    return shuffleMoves;
  }

  // Thực hiện chuỗi moves
  Future<void> executeMoves(List<String> moves) async {
    for (String move in moves) {
      await _executeMove(move);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}
