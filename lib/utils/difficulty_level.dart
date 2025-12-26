import 'dart:math';

enum DifficultyLevel {
  easy('Dễ', 'Easy', 15, 18),
  medium('Trung bình', 'Medium', 20, 25),
  hard('Khó', 'Hard', 25, 30);

  final String nameVi;
  final String nameEn;
  final int minMoves;
  final int maxMoves;

  const DifficultyLevel(this.nameVi, this.nameEn, this.minMoves, this.maxMoves);

  int getRandomMoveCount(Random random) {
    return minMoves + random.nextInt(maxMoves - minMoves + 1);
  }
}

