import 'dart:collection';
import '../models/rubik_cube.dart';

/// Simple BFS Solver - tìm solution bằng BFS
class SimpleBFSSolver {
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

  /// Solve cube using simple BFS
  static Future<List<String>> solve(RubikCube cube) async {
    print(' Starting BFS solver...');

    // Check if already solved
    if (cube.isSolved()) {
      print('✓ Cube is already solved!');
      return [];
    }

    // BFS search
    var solution = _bfsSearch(cube, maxDepth: 20);

    if (solution.isEmpty) {
      print(' No solution found');
      return [];
    }

    print(' Solution found: ${solution.length} moves');
    return solution;
  }

  /// BFS search for solution
  static List<String> _bfsSearch(RubikCube cube, {int maxDepth = 20}) {
    var queue = Queue<_SearchState>();
    var visited = <String>{};

    queue.add(_SearchState(cube: _copyCube(cube), moves: [], depth: 0));
    visited.add(_hashCube(cube));

    int exploredCount = 0;

    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      exploredCount++;

      if (exploredCount % 10000 == 0) {
        print('  Explored: $exploredCount states, Queue: ${queue.length}');
      }

      // Check if solved
      if (current.cube.isSolved()) {
        print('  ✓ Found solution after exploring $exploredCount states');
        return current.moves;
      }

      // Limit depth
      if (current.depth >= maxDepth) continue;

      // Try all moves
      for (var move in allMoves) {
        var newCube = _copyCube(current.cube);
        _applyMove(newCube, move);

        var hash = _hashCube(newCube);
        if (!visited.contains(hash)) {
          visited.add(hash);
          queue.add(_SearchState(
            cube: newCube,
            moves: [...current.moves, move],
            depth: current.depth + 1,
          ));
        }
      }
    }

    print(' No solution found (explored $exploredCount states)');
    return [];
  }

  /// Apply move to cube
  static void _applyMove(RubikCube cube, String move) {
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

  /// Deep copy cube
  static RubikCube _copyCube(RubikCube cube) {
    var newCube = RubikCube();
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          var srcCubelet = cube.cubelets[x][y][z];
          var dstCubelet = newCube.cubelets[x][y][z];

          // Copy all face colors
          srcCubelet.faces.forEach((face, color) {
            dstCubelet.setFaceColor(face, color);
          });
        }
      }
    }
    return newCube;
  }

  /// Hash cube state
  static String _hashCube(RubikCube cube) {
    var buffer = StringBuffer();
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          var cubelet = cube.cubelets[x][y][z];
          cubelet.faces.forEach((face, color) {
            buffer.write(color.toString());
          });
        }
      }
    }
    return buffer.toString();
  }
}

class _SearchState {
  final RubikCube cube;
  final List<String> moves;
  final int depth;

  _SearchState({
    required this.cube,
    required this.moves,
    required this.depth,
  });
}
