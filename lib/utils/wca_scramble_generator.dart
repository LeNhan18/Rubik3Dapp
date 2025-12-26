import 'dart:math';

class WCAScrambleGenerator {
  static final Random _random = Random();

  // WCA official moves for different cubes
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
  static const List<String> _facesMega = ['R++', 'R--', 'D++', 'D--', 'U'];

  static const List<String> _modifiers = ['', "'", '2'];
  static const List<String> _modifiersPyra = ['', "'"];
  static const List<String> _modifiersMega = ['', "'"];

  /// Generates a WCA official 3x3 scramble
  /// Default length is 20 moves (WCA standard)
  static String generate3x3({int length = 20}) {
    final scramble = <String>[];
    String? lastFace;
    String? secondToLastFace;

    for (int i = 0; i < length; i++) {
      String face;

      do {
        face = _faces3x3[_random.nextInt(_faces3x3.length)];
      } while (_shouldRejectMove(face, lastFace, secondToLastFace));

      final modifier = _modifiers[_random.nextInt(_modifiers.length)];
      scramble.add('$face$modifier');

      secondToLastFace = lastFace;
      lastFace = face;
    }

    return scramble.join(' ');
  }

  /// Check if a move should be rejected based on WCA rules
  static bool _shouldRejectMove(
    String face,
    String? lastFace,
    String? secondToLastFace,
  ) {
    // Don't repeat the same face consecutively
    if (face == lastFace) return true;

    // Don't use opposite faces consecutively (R-L, U-D, F-B)
    if (lastFace != null && _areOppositeFaces(face, lastFace)) {
      // If the second-to-last face is the same as current, reject
      if (face == secondToLastFace) return true;
    }

    return false;
  }

  /// Check if two faces are opposite
  static bool _areOppositeFaces(String face1, String face2) {
    final opposites = {
      'R': 'L',
      'L': 'R',
      'U': 'D',
      'D': 'U',
      'F': 'B',
      'B': 'F',
    };

    return opposites[face1] == face2;
  }

  /// Generate scramble for different cube types
  static String generateScramble(String cubeType, {int? customLength}) {
    switch (cubeType) {
      case '2x2':
        return _generate2x2(length: customLength ?? 9);
      case '3x3':
        return generate3x3(length: customLength ?? 20);
      case '4x4':
        return _generate4x4(length: customLength ?? 40);
      case '5x5':
        return _generate5x5(length: customLength ?? 60);
      default:
        return generate3x3(length: customLength ?? 20);
    }
  }

  /// Generate 2x2 scramble (uses R, U, F moves only)
  static String _generate2x2({int length = 9}) {
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

  /// Generate 4x4 scramble (includes wide moves)
  static String _generate4x4({int length = 40}) {
    final faces4x4 = [
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
    final scramble = <String>[];
    String? lastFace;
    String? secondToLastFace;

    for (int i = 0; i < length; i++) {
      String face;

      do {
        face = faces4x4[_random.nextInt(faces4x4.length)];
      } while (_shouldRejectMove4x4(face, lastFace, secondToLastFace));

      final modifier = _modifiers[_random.nextInt(_modifiers.length)];
      scramble.add('$face$modifier');

      secondToLastFace = lastFace;
      lastFace = face;
    }

    return scramble.join(' ');
  }

  static bool _shouldRejectMove4x4(
    String face,
    String? lastFace,
    String? secondToLastFace,
  ) {
    if (face == lastFace) return true;

    // Group inner and outer layer moves
    final baseFace = face.replaceAll('w', '');
    final lastBaseFace = lastFace?.replaceAll('w', '');

    if (lastBaseFace != null && _areOppositeFaces(baseFace, lastBaseFace)) {
      final secondToLastBaseFace = secondToLastFace?.replaceAll('w', '');
      if (baseFace == secondToLastBaseFace) return true;
    }

    return false;
  }

  /// Generate 5x5 scramble
  static String _generate5x5({int length = 60}) {
    final faces5x5 = [
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
    final scramble = <String>[];
    String? lastFace;
    String? secondToLastFace;

    for (int i = 0; i < length; i++) {
      String face;

      do {
        face = faces5x5[_random.nextInt(faces5x5.length)];
      } while (_shouldRejectMove4x4(face, lastFace, secondToLastFace));

      final modifier = _modifiers[_random.nextInt(_modifiers.length)];
      scramble.add('$face$modifier');

      secondToLastFace = lastFace;
      lastFace = face;
    }

    return scramble.join(' ');
  }

  /// Parse a scramble string into individual moves
  static List<String> parseScramble(String scramble) {
    return scramble.trim().split(RegExp(r'\s+'));
  }

  /// Validate if a scramble string is valid
  static bool isValidScramble(String scramble) {
    if (scramble.trim().isEmpty) return false;

    final moves = parseScramble(scramble);
    final validMovePattern = RegExp(r"^[RLUDfb]w?['2]?$", caseSensitive: false);

    return moves.every((move) => validMovePattern.hasMatch(move));
  }
}
