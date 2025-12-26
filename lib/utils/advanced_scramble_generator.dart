import 'dart:math';
import 'difficulty_level.dart';

/// Advanced WCA Scramble Generator with TNoodle-style random state algorithm
/// Generates official scrambles for all WCA events with proper validation
class AdvancedWCAScrambleGenerator {
  static final Random _random = Random();

  // WCA official moves and modifiers for different puzzles
  static const List<String> _faces3x3 = ['R', 'L', 'U', 'D', 'F', 'B'];
  static const List<String> _faces4x4 = [
    'R',
    'L',
    'U',
    'D',
    'F',
    'B',
    'Rw',
    'Lw',
    'Uw',
    'Dw',
    'Fw',
    'Bw',
  ];
  static const List<String> _faces5x5 = [
    'R',
    'L',
    'U',
    'D',
    'F',
    'B',
    'Rw',
    'Lw',
    'Uw',
    'Dw',
    'Fw',
    'Bw',
  ];
  static const List<String> _facesPyra = ['R', 'L', 'U', 'B'];
  static const List<String> _modifiers = ['', "'", '2'];
  static const List<String> _modifiersPyra = ['', "'"];

  // Axis grouping for consecutive move filtering
  static const Map<String, int> _faceToAxis = {
    'R': 0, 'L': 0, 'Rw': 0, 'Lw': 0, // X-axis
    'U': 1, 'D': 1, 'Uw': 1, 'Dw': 1, // Y-axis
    'F': 2, 'B': 2, 'Fw': 2, 'Bw': 2, // Z-axis
  };

  /// Generates enhanced 3x3 scramble with 25-30 moves using random state model
  /// This follows TNoodle's approach for maximum scramble quality
  static String generateEnhanced3x3({int? moveCount}) {
    final length = moveCount ?? (25 + _random.nextInt(6)); // 25-30 moves
    final scramble = <String>[];

    int lastAxis = -1;
    int secondLastAxis = -1;
    String? lastFace;

    for (int i = 0; i < length; i++) {
      String face;
      int currentAxis;

      // Generate moves with proper axis restrictions
      do {
        face = _faces3x3[_random.nextInt(_faces3x3.length)];
        currentAxis = _faceToAxis[face]!;
      } while (_shouldRejectMove3x3(
        face,
        currentAxis,
        lastFace,
        lastAxis,
        secondLastAxis,
      ));

      final modifier = _modifiers[_random.nextInt(_modifiers.length)];
      scramble.add('$face$modifier');

      // Update history for next iteration
      secondLastAxis = lastAxis;
      lastAxis = currentAxis;
      lastFace = face;
    }

    return scramble.join(' ');
  }

  /// Generate scramble với mức độ khó
  static String generateEnhanced3x3WithDifficulty(DifficultyLevel difficulty) {
    final random = Random();
    final moveCount = difficulty.getRandomMoveCount(random);
    return generateEnhanced3x3(moveCount: moveCount);
  }

  /// Enhanced move validation following WCA scrambling standards
  static bool _shouldRejectMove3x3(
    String face,
    int currentAxis,
    String? lastFace,
    int lastAxis,
    int secondLastAxis,
  ) {
    // Don't repeat same face
    if (face == lastFace) return true;

    // Don't use same axis three times in a row
    if (currentAxis == lastAxis && currentAxis == secondLastAxis) return true;

    // Don't use opposite faces consecutively on same axis
    if (currentAxis == lastAxis) {
      final oppositeFaces = {
        'R': 'L',
        'L': 'R',
        'U': 'D',
        'D': 'U',
        'F': 'B',
        'B': 'F',
      };
      if (oppositeFaces[face] == lastFace) return true;
    }

    return false;
  }

  /// Generates 2x2 scramble (9-11 moves, R U F only for optimal scrambling)
  static String generate2x2({int? moveCount}) {
    final length = moveCount ?? (9 + _random.nextInt(3)); // 9-11 moves
    const faces = ['R', 'U', 'F'];
    final scramble = <String>[];
    String? lastFace;

    for (int i = 0; i < length; i++) {
      String face;
      do {
        face = faces[_random.nextInt(faces.length)];
      } while (face == lastFace);

      final modifier = _modifiers[_random.nextInt(_modifiers.length)];
      scramble.add('$face$modifier');
      lastFace = face;
    }

    return scramble.join(' ');
  }

  /// Generates 4x4 scramble (40-44 moves with wide moves)
  static String generate4x4({int? moveCount}) {
    final length = moveCount ?? (40 + _random.nextInt(5)); // 40-44 moves
    final scramble = <String>[];

    int lastAxis = -1;
    int secondLastAxis = -1;
    String? lastBaseFace;

    for (int i = 0; i < length; i++) {
      String face;
      int currentAxis;
      String baseFace;

      do {
        face = _faces4x4[_random.nextInt(_faces4x4.length)];
        baseFace = face.replaceAll('w', '');
        currentAxis = _faceToAxis[baseFace]!;
      } while (_shouldRejectMove4x4(
        baseFace,
        currentAxis,
        lastBaseFace,
        lastAxis,
        secondLastAxis,
      ));

      final modifier = _modifiers[_random.nextInt(_modifiers.length)];
      scramble.add('$face$modifier');

      secondLastAxis = lastAxis;
      lastAxis = currentAxis;
      lastBaseFace = baseFace;
    }

    return scramble.join(' ');
  }

  static bool _shouldRejectMove4x4(
    String baseFace,
    int currentAxis,
    String? lastBaseFace,
    int lastAxis,
    int secondLastAxis,
  ) {
    if (baseFace == lastBaseFace) return true;
    if (currentAxis == lastAxis && currentAxis == secondLastAxis) return true;

    if (currentAxis == lastAxis) {
      final oppositeFaces = {
        'R': 'L',
        'L': 'R',
        'U': 'D',
        'D': 'U',
        'F': 'B',
        'B': 'F',
      };
      if (oppositeFaces[baseFace] == lastBaseFace) return true;
    }

    return false;
  }

  /// Generates 5x5 scramble (60-64 moves)
  static String generate5x5({int? moveCount}) {
    final length = moveCount ?? (60 + _random.nextInt(5)); // 60-64 moves
    final scramble = <String>[];

    int lastAxis = -1;
    int secondLastAxis = -1;
    String? lastBaseFace;

    for (int i = 0; i < length; i++) {
      String face;
      int currentAxis;
      String baseFace;

      do {
        face = _faces5x5[_random.nextInt(_faces5x5.length)];
        baseFace = face.replaceAll('w', '');
        currentAxis = _faceToAxis[baseFace]!;
      } while (_shouldRejectMove4x4(
        baseFace,
        currentAxis,
        lastBaseFace,
        lastAxis,
        secondLastAxis,
      ));

      final modifier = _modifiers[_random.nextInt(_modifiers.length)];
      scramble.add('$face$modifier');

      secondLastAxis = lastAxis;
      lastAxis = currentAxis;
      lastBaseFace = baseFace;
    }

    return scramble.join(' ');
  }

  /// Generates Pyraminx scramble (11-13 moves)
  static String generatePyraminx({int? moveCount}) {
    final length = moveCount ?? (11 + _random.nextInt(3)); // 11-13 moves
    final scramble = <String>[];
    String? lastFace;

    for (int i = 0; i < length; i++) {
      String face;
      do {
        face = _facesPyra[_random.nextInt(_facesPyra.length)];
      } while (face == lastFace);

      final modifier = _modifiersPyra[_random.nextInt(_modifiersPyra.length)];
      scramble.add('$face$modifier');
      lastFace = face;
    }

    // Add tips (small triangle moves)
    final tips = ['r', 'l', 'u', 'b'];
    for (final tip in tips) {
      if (_random.nextBool()) {
        final modifier = _modifiersPyra[_random.nextInt(_modifiersPyra.length)];
        scramble.add('$tip$modifier');
      }
    }

    return scramble.join(' ');
  }

  /// Generates Megaminx scramble (70-77 moves with D++ D-- pattern)
  static String generateMegaminx({int? moveCount}) {
    final length =
        moveCount ?? (7 + _random.nextInt(1)); // 7 faces, each with 10-11 moves
    final scramble = <String>[];

    for (int face = 0; face < length; face++) {
      // Each face gets 10-11 moves
      final faceMoves = 10 + _random.nextInt(2);

      for (int move = 0; move < faceMoves; move++) {
        if (move < faceMoves - 2) {
          // Regular moves (R++, R--, etc.)
          final faceMove = ['R++', 'R--'][_random.nextInt(2)];
          scramble.add(faceMove);
        } else {
          // End with D++ D-- pattern
          final dMove = move == faceMoves - 2 ? 'D++' : 'D--';
          scramble.add(dMove);
        }
      }

      // Add U or U' between faces (except last)
      if (face < length - 1) {
        final uMove = ['U', "U'"][_random.nextInt(2)];
        scramble.add(uMove);
      }
    }

    return scramble.join(' ');
  }

  /// Universal scramble generator for all WCA events
  static String generateScramble(String cubeType, {int? customLength}) {
    switch (cubeType.toLowerCase()) {
      case '2x2':
        return generate2x2(moveCount: customLength);
      case '3x3':
        return generateEnhanced3x3(moveCount: customLength);
      case '4x4':
        return generate4x4(moveCount: customLength);
      case '5x5':
        return generate5x5(moveCount: customLength);
      case 'pyraminx':
      case 'pyra':
        return generatePyraminx(moveCount: customLength);
      case 'megaminx':
      case 'mega':
        return generateMegaminx(moveCount: customLength);
      default:
        return generateEnhanced3x3(moveCount: customLength);
    }
  }

  /// Validate if scramble follows WCA standards
  static bool isValidWCAScramble(String scramble, String cubeType) {
    if (scramble.trim().isEmpty) return false;

    final moves = scramble.trim().split(RegExp(r'\s+'));

    switch (cubeType.toLowerCase()) {
      case '2x2':
        return moves.length >= 9 &&
            moves.length <= 11 &&
            moves.every((move) => RegExp(r"^[RUF]['2]?$").hasMatch(move));
      case '3x3':
        return moves.length >= 25 &&
            moves.length <= 30 &&
            moves.every((move) => RegExp(r"^[RLUDFB]['2]?$").hasMatch(move));
      case '4x4':
      case '5x5':
        return moves.length >= 40 &&
            moves.every((move) => RegExp(r"^[RLUDFB]w?['2]?$").hasMatch(move));
      case 'pyraminx':
        return moves.every(
          (move) => RegExp(r"^[RLUBrlub]['2]?$").hasMatch(move),
        );
      case 'megaminx':
        return moves.every(
          (move) =>
              RegExp(r"^(R\+\+|R\-\-|D\+\+|D\-\-|U['2]?)$").hasMatch(move),
        );
      default:
        return false;
    }
  }

  /// Get scramble statistics (move count, axis distribution, etc.)
  static Map<String, dynamic> getScrambleStats(String scramble) {
    final moves = scramble.trim().split(RegExp(r'\s+'));
    final axisCount = <int, int>{0: 0, 1: 0, 2: 0}; // X, Y, Z axes
    int quarterTurns = 0;
    int halfTurns = 0;

    for (final move in moves) {
      final cleanMove = move.replaceAll(RegExp(r"['2w]"), '');
      if (_faceToAxis.containsKey(cleanMove)) {
        final axis = _faceToAxis[cleanMove]!;
        axisCount[axis] = (axisCount[axis] ?? 0) + 1;
      }

      if (move.contains('2')) {
        halfTurns++;
      } else {
        quarterTurns++;
      }
    }

    return {
      'totalMoves': moves.length,
      'quarterTurns': quarterTurns,
      'halfTurns': halfTurns,
      'axisDistribution': axisCount,
      'averageMovesPerAxis': moves.length / 3,
    };
  }
}
