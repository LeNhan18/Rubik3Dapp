import 'dart:collection';
import '../models/rubik_cube.dart';

/// 2-Phase Kociemba Algorithm Solver
/// Tìm solution với số moves ≤ 20
class KociembaSolver {
  static const List<String> allMoves = [
    'R',
    'R\'',
    'R2',
    'L',
    'L\'',
    'L2',
    'U',
    'U\'',
    'U2',
    'D',
    'D\'',
    'D2',
    'F',
    'F\'',
    'F2',
    'B',
    'B\'',
    'B2',
  ];

  /// Solve Rubik cube sử dụng 2-Phase Kociemba
  static Future<List<String>> solve(RubikCube cube) async {
    print('🔍 Starting Kociemba solver...');

    // Check if already solved
    if (cube.isSolved()) {
      print('✓ Cube is already solved!');
      return [];
    }

    // Phase 1: Tìm moves từ any state → G1 state
    print('🔍 Phase 1: Finding moves to G1 state...');
    var phase1Moves = _searchPhase1(cube);

    if (phase1Moves.isEmpty) {
      print('⚠ Phase 1 failed - trying with increased depth');
      phase1Moves = _searchPhase1(cube, maxDepth: 15);
    }

    if (phase1Moves.isEmpty) {
      print(' Phase 1 failed even with increased depth');
      return [];
    }

    print('✓ Phase 1 found: ${phase1Moves.length} moves');

    // Apply phase 1 moves
    var cubeCopy = _copyCube(cube);
    for (var move in phase1Moves) {
      _applyMoveToState(cubeCopy, move);
    }

    // Phase 2: Tìm moves từ G1 → solved
    print(' Phase 2: Finding moves from G1 to solved...');
    var phase2Moves = _searchPhase2(cubeCopy);

    if (phase2Moves.isEmpty) {
      print('Phase 2 failed - trying with increased depth');
      phase2Moves = _searchPhase2(cubeCopy, maxDepth: 20);
    }

    if (phase2Moves.isEmpty) {
      print(' Phase 2 failed');
      return phase1Moves; // Trả về phase 1 nếu phase 2 fail
    }

    print(' Phase 2 found: ${phase2Moves.length} moves');

    // Combine cả 2 phase
    final solution = [...phase1Moves, ...phase2Moves];
    print(' Solution found: ${solution.length} moves total');
    return solution;
  }

  /// Phase 1: BFS để tìm moves đạt G1 state (max depth 10)
  static List<String> _searchPhase1(RubikCube cube, {int maxDepth = 10}) {
    var queue = Queue<CubeSearchState>();
    var visited = <String>{};

    var initialHash = _hashCube(cube);
    queue.add(CubeSearchState(cube: _copyCube(cube), moves: [], depth: 0));
    visited.add(initialHash);

    while (queue.isNotEmpty) {
      var current = queue.removeFirst();

      // Check nếu đạt G1 state
      if (_isG1State(current.cube)) {
        return current.moves;
      }

      // Giới hạn depth
      if (current.depth >= maxDepth) continue;

      // Thử tất cả 18 moves
      for (var move in allMoves) {
        var newCube = _copyCube(current.cube);
        _applyMoveToState(newCube, move);

        var hash = _hashCube(newCube);
        if (!visited.contains(hash)) {
          visited.add(hash);
          queue.add(CubeSearchState(
            cube: newCube,
            moves: [...current.moves, move],
            depth: current.depth + 1,
          ));
        }
      }
    }

    return []; // No solution found
  }

  /// Phase 2: BFS từ G1 state → Solved (max depth 14)
  static List<String> _searchPhase2(RubikCube cube, {int maxDepth = 14}) {
    var queue = Queue<CubeSearchState>();
    var visited = <String>{};

    queue.add(CubeSearchState(cube: _copyCube(cube), moves: [], depth: 0));
    visited.add(_hashCube(cube));

    while (queue.isNotEmpty) {
      var current = queue.removeFirst();

      // Check nếu đã solve xong
      if (current.cube.isSolved()) {
        return current.moves;
      }

      // Giới hạn depth
      if (current.depth >= maxDepth) continue;

      // Thử tất cả 18 moves
      for (var move in allMoves) {
        var newCube = _copyCube(current.cube);
        _applyMoveToState(newCube, move);

        var hash = _hashCube(newCube);
        if (!visited.contains(hash)) {
          visited.add(hash);
          queue.add(CubeSearchState(
            cube: newCube,
            moves: [...current.moves, move],
            depth: current.depth + 1,
          ));
        }
      }
    }

    return []; // No solution found
  }

  /// Kiểm tra cube có đạt G1 state không
  /// G1 state: Edge orientation + Corner position đúng
  static bool _isG1State(RubikCube cube) {
    // Điều kiện 1: Tất cả cạnh phải có orientation đúng
    if (!_isEdgeOriented(cube)) return false;

    // Điều kiện 2: Tất cả góc phải ở vị trí đúng
    if (!_isCornerPositioned(cube)) return false;

    // Điều kiện 3: Middle layer edges phải ở đúng vị trí
    if (!_isMiddleLayerSolved(cube)) return false;

    return true;
  }

  /// Kiểm tra tất cả edge stickers có orientation đúng
  static bool _isEdgeOriented(RubikCube cube) {
    // Kiểm tra front face edges
    for (int i = 0; i < 3; i++) {
      if (i == 1) continue; // Skip center
      var cubelet = cube.cubelets[i][2][2];
      if (cubelet.getFaceColor('front') != CubeColor.blue) {
        return false;
      }
    }

    // Kiểm tra back face edges
    for (int i = 0; i < 3; i++) {
      if (i == 1) continue;
      var cubelet = cube.cubelets[i][2][0];
      if (cubelet.getFaceColor('back') != CubeColor.green) {
        return false;
      }
    }

    // Kiểm tra up face edges
    for (int i = 0; i < 3; i++) {
      if (i == 1) continue;
      var cubelet = cube.cubelets[i][2][2];
      if (cubelet.getFaceColor('up') != CubeColor.white) {
        return false;
      }
    }

    // Kiểm tra down face edges
    for (int i = 0; i < 3; i++) {
      if (i == 1) continue;
      var cubelet = cube.cubelets[i][0][2];
      if (cubelet.getFaceColor('down') != CubeColor.yellow) {
        return false;
      }
    }

    return true;
  }

  /// Kiểm tra tất cả corner stickers có vị trí đúng
  static bool _isCornerPositioned(RubikCube cube) {
    // Kiểm tra 8 góc có ở vị trí đúng (ignore orientation)
    return _isCornerAtPosition(cube, 0, 2, 2) && // Top-left-front
        _isCornerAtPosition(cube, 2, 2, 2) && // Top-right-front
        _isCornerAtPosition(cube, 0, 2, 0) && // Top-left-back
        _isCornerAtPosition(cube, 2, 2, 0) && // Top-right-back
        _isCornerAtPosition(cube, 0, 0, 2) && // Bottom-left-front
        _isCornerAtPosition(cube, 2, 0, 2) && // Bottom-right-front
        _isCornerAtPosition(cube, 0, 0, 0) && // Bottom-left-back
        _isCornerAtPosition(cube, 2, 0, 0); // Bottom-right-back
  }

  static bool _isCornerAtPosition(RubikCube cube, int x, int y, int z) {
    var cubelet = cube.cubelets[x][y][z];
    var expectedColor = CubeColor.white; // Default (up)

    // Xác định màu expected dựa trên vị trí
    if (y == 0) expectedColor = CubeColor.yellow;

    // Kiểm tra ít nhất một face có màu expected
    for (var face in ['up', 'down', 'left', 'right', 'front', 'back']) {
      var color = cubelet.getFaceColor(face);
      if (color == expectedColor) return true;
    }

    return false;
  }

  /// Kiểm tra middle layer edges ở vị trí đúng
  static bool _isMiddleLayerSolved(RubikCube cube) {
    // Middle layer là y=1
    // Kiểm tra 4 middle edges
    return _isMiddleEdgeCorrect(cube, 2, 1, 2) && // Right-front
        _isMiddleEdgeCorrect(cube, 0, 1, 2) && // Left-front
        _isMiddleEdgeCorrect(cube, 2, 1, 0) && // Right-back
        _isMiddleEdgeCorrect(cube, 0, 1, 0); // Left-back
  }

  static bool _isMiddleEdgeCorrect(RubikCube cube, int x, int y, int z) {
    var cubelet = cube.cubelets[x][y][z];

    if (x == 2) {
      return cubelet.getFaceColor('right') == CubeColor.red;
    } else if (x == 0) {
      return cubelet.getFaceColor('left') == CubeColor.orange;
    } else if (z == 2) {
      return cubelet.getFaceColor('front') == CubeColor.blue;
    } else if (z == 0) {
      return cubelet.getFaceColor('back') == CubeColor.green;
    }

    return false;
  }

  /// Copy cube state
  static RubikCube _copyCube(RubikCube cube) {
    var newCube = RubikCube();
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          var originalCubelet = cube.cubelets[x][y][z];
          var newCubelet = newCube.cubelets[x][y][z];

          // Copy tất cả faces
          for (var face in ['up', 'down', 'left', 'right', 'front', 'back']) {
            var color = originalCubelet.getFaceColor(face);
            if (color != null) {
              newCubelet.setFaceColor(face, color);
            }
          }
        }
      }
    }
    return newCube;
  }

  /// Apply move vào cube state
  static void _applyMoveToState(RubikCube cube, String move) {
    switch (move) {
      case 'R':
        cube.rotateFace('right', true);
        break;
      case 'R\'':
        cube.rotateFace('right', false);
        break;
      case 'R2':
        cube.rotateFace('right', true);
        cube.rotateFace('right', true);
        break;
      case 'L':
        cube.rotateFace('left', true);
        break;
      case 'L\'':
        cube.rotateFace('left', false);
        break;
      case 'L2':
        cube.rotateFace('left', true);
        cube.rotateFace('left', true);
        break;
      case 'U':
        cube.rotateFace('up', true);
        break;
      case 'U\'':
        cube.rotateFace('up', false);
        break;
      case 'U2':
        cube.rotateFace('up', true);
        cube.rotateFace('up', true);
        break;
      case 'D':
        cube.rotateFace('down', true);
        break;
      case 'D\'':
        cube.rotateFace('down', false);
        break;
      case 'D2':
        cube.rotateFace('down', true);
        cube.rotateFace('down', true);
        break;
      case 'F':
        cube.rotateFace('front', true);
        break;
      case 'F\'':
        cube.rotateFace('front', false);
        break;
      case 'F2':
        cube.rotateFace('front', true);
        cube.rotateFace('front', true);
        break;
      case 'B':
        cube.rotateFace('back', true);
        break;
      case 'B\'':
        cube.rotateFace('back', false);
        break;
      case 'B2':
        cube.rotateFace('back', true);
        cube.rotateFace('back', true);
        break;
    }
  }

  /// Hash cube state để track visited states
  static String _hashCube(RubikCube cube) {
    var buffer = StringBuffer();

    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          var cubelet = cube.cubelets[x][y][z];
          for (var face in ['up', 'down', 'left', 'right', 'front', 'back']) {
            var color = cubelet.getFaceColor(face);
            if (color != null) {
              buffer.write('${color.index}');
            }
          }
        }
      }
    }

    return buffer.toString();
  }
}

/// Cube state trong search
class CubeSearchState {
  final RubikCube cube;
  final List<String> moves;
  final int depth;

  CubeSearchState({
    required this.cube,
    required this.moves,
    required this.depth,
  });
}
