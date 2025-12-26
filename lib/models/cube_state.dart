enum CubeColor {
  white, // U (Up)
  red, // R (Right)
  blue, // F (Front)
  orange, // L (Left)
  green, // B (Back)
  yellow, // D (Down)
}

enum CubeFace {
  up, // U
  right, // R
  front, // F
  left, // L
  back, // B
  down, // D
}

class CubeMove {
  final String notation;
  final CubeFace face;
  final bool clockwise;
  final bool double;
  final bool wide;

  const CubeMove({
    required this.notation,
    required this.face,
    required this.clockwise,
    required this.double,
    this.wide = false,
  });

  CubeMove copyWith({
    String? notation,
    CubeFace? face,
    bool? clockwise,
    bool? double,
    bool? wide,
  }) {
    return CubeMove(
      notation: notation ?? this.notation,
      face: face ?? this.face,
      clockwise: clockwise ?? this.clockwise,
      double: double ?? this.double,
      wide: wide ?? this.wide,
    );
  }

  factory CubeMove.fromNotation(String notation) {
    final cleanNotation = notation.trim();

    // Parse wide moves (lowercase or 'w')
    final isWide = cleanNotation.toLowerCase() != cleanNotation ||
        cleanNotation.contains('w');

    // Get base face
    final faceChar = cleanNotation[0].toUpperCase();
    final face = _parseFace(faceChar);

    // Parse modifiers
    final isDouble = cleanNotation.contains('2');
    final isCounterClockwise = cleanNotation.contains("'");

    return CubeMove(
      notation: cleanNotation,
      face: face,
      clockwise: !isCounterClockwise,
      double: isDouble,
      wide: isWide,
    );
  }

  static CubeFace _parseFace(String faceChar) {
    switch (faceChar) {
      case 'U':
        return CubeFace.up;
      case 'R':
        return CubeFace.right;
      case 'F':
        return CubeFace.front;
      case 'L':
        return CubeFace.left;
      case 'B':
        return CubeFace.back;
      case 'D':
        return CubeFace.down;
      case 'M':
        return CubeFace.left; // Middle slice
      case 'E':
        return CubeFace.down; // Equatorial slice
      case 'S':
        return CubeFace.front; // Standing slice
      default:
        throw ArgumentError('Invalid face: $faceChar');
    }
  }
}

class CubeState {
  // Each face has 9 stickers (3x3)
  final List<List<CubeColor>> faces;
  final List<CubeMove> moveHistory;

  CubeState({required this.faces, required this.moveHistory});

  factory CubeState.solved() {
    return CubeState(
      faces: [
        List.filled(9, CubeColor.white), // Up
        List.filled(9, CubeColor.red), // Right
        List.filled(9, CubeColor.blue), // Front
        List.filled(9, CubeColor.orange), // Left
        List.filled(9, CubeColor.green), // Back
        List.filled(9, CubeColor.yellow), // Down
      ],
      moveHistory: [],
    );
  }

  CubeState copyWith({
    List<List<CubeColor>>? faces,
    List<CubeMove>? moveHistory,
  }) {
    return CubeState(
      faces: faces ??
          this.faces.map((face) => List<CubeColor>.from(face)).toList(),
      moveHistory: moveHistory ?? List<CubeMove>.from(this.moveHistory),
    );
  }

  bool get isSolved {
    for (int faceIndex = 0; faceIndex < 6; faceIndex++) {
      final expectedColor = CubeColor.values[faceIndex];
      for (final sticker in faces[faceIndex]) {
        if (sticker != expectedColor) return false;
      }
    }
    return true;
  }

  int get moveCount => moveHistory.length;

  String get scrambleString =>
      moveHistory.map((move) => move.notation).join(' ');
}
