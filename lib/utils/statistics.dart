import 'dart:math' show sqrt;
import '../models/solve_time.dart';

class Statistics {
  final List<SolveTime> solves;

  Statistics(this.solves);

  /// Calculate average of 5 (ao5)
  /// Removes best and worst, averages the middle 3
  double? calculateAo5() {
    if (solves.length < 5) return null;

    final recentSolves =
        solves.takeLast(5).where((solve) => !solve.isDNF).toList();
    if (recentSolves.length < 3) return null; // Need at least 3 valid solves

    recentSolves.sort((a, b) => a.totalTime.compareTo(b.totalTime));

    // Remove best and worst
    final middle3 = recentSolves.sublist(1, recentSolves.length - 1);
    final sum = middle3.fold<int>(0, (sum, solve) => sum + solve.totalTime);

    return sum / middle3.length;
  }

  /// Calculate average of 12 (ao12)
  /// Removes best and worst, averages the middle 10
  double? calculateAo12() {
    if (solves.length < 12) return null;

    final recentSolves =
        solves.takeLast(12).where((solve) => !solve.isDNF).toList();
    if (recentSolves.length < 10) return null; // Need at least 10 valid solves

    recentSolves.sort((a, b) => a.totalTime.compareTo(b.totalTime));

    // Remove best and worst
    final middle10 = recentSolves.sublist(1, recentSolves.length - 1);
    final sum = middle10.fold<int>(0, (sum, solve) => sum + solve.totalTime);

    return sum / middle10.length;
  }

  /// Calculate average of 100 (ao100)
  double? calculateAo100() {
    if (solves.length < 100) return null;

    final recentSolves =
        solves.takeLast(100).where((solve) => !solve.isDNF).toList();
    if (recentSolves.length < 95) return null; // Allow up to 5 DNFs

    recentSolves.sort((a, b) => a.totalTime.compareTo(b.totalTime));

    // Remove 5 best and 5 worst
    final toRemove = (recentSolves.length * 0.05).floor();
    final middle = recentSolves.sublist(
      toRemove,
      recentSolves.length - toRemove,
    );
    final sum = middle.fold<int>(0, (sum, solve) => sum + solve.totalTime);

    return sum / middle.length;
  }

  /// Calculate mean (average of all solves)
  double? calculateMean() {
    final validSolves = solves.where((solve) => !solve.isDNF).toList();
    if (validSolves.isEmpty) return null;

    final sum = validSolves.fold<int>(0, (sum, solve) => sum + solve.totalTime);
    return sum / validSolves.length;
  }

  /// Get best time
  SolveTime? getBest() {
    final validSolves = solves.where((solve) => !solve.isDNF).toList();
    if (validSolves.isEmpty) return null;

    validSolves.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    return validSolves.first;
  }

  /// Get worst time
  SolveTime? getWorst() {
    final validSolves = solves.where((solve) => !solve.isDNF).toList();
    if (validSolves.isEmpty) return null;

    validSolves.sort((a, b) => b.totalTime.compareTo(a.totalTime));
    return validSolves.first;
  }

  /// Get current session best ao5
  double? getBestAo5() {
    if (solves.length < 5) return null;

    double? bestAo5;

    for (int i = 4; i < solves.length; i++) {
      final sessionSolves = solves.sublist(0, i + 1);
      final ao5 = Statistics(sessionSolves).calculateAo5();

      if (ao5 != null && (bestAo5 == null || ao5 < bestAo5)) {
        bestAo5 = ao5;
      }
    }

    return bestAo5;
  }

  /// Get current session best ao12
  double? getBestAo12() {
    if (solves.length < 12) return null;

    double? bestAo12;

    for (int i = 11; i < solves.length; i++) {
      final sessionSolves = solves.sublist(0, i + 1);
      final ao12 = Statistics(sessionSolves).calculateAo12();

      if (ao12 != null && (bestAo12 == null || ao12 < bestAo12)) {
        bestAo12 = ao12;
      }
    }

    return bestAo12;
  }

  /// Get solve count
  int get solveCount => solves.length;

  /// Get DNF count
  int get dnfCount => solves.where((solve) => solve.isDNF).length;

  /// Get success rate (percentage of non-DNF solves)
  double get successRate {
    if (solves.isEmpty) return 0.0;
    return (solves.length - dnfCount) / solves.length * 100;
  }

  /// Get standard deviation
  double? getStandardDeviation() {
    final validSolves = solves.where((solve) => !solve.isDNF).toList();
    if (validSolves.length < 2) return null;

    final mean = calculateMean();
    if (mean == null) return null;

    final sumOfSquaredDifferences = validSolves.fold<double>(
      0.0,
      (sum, solve) =>
          sum + ((solve.totalTime - mean) * (solve.totalTime - mean)),
    );

    return sqrt(sumOfSquaredDifferences / (validSolves.length - 1));
  }

  /// Format time for display
  static String formatTime(double? milliseconds) {
    if (milliseconds == null) return '-';

    final minutes = (milliseconds ~/ 60000);
    final seconds = ((milliseconds % 60000) ~/ 1000);
    final millis = (milliseconds % 1000) ~/ 10;

    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}.${millis.toString().padLeft(2, '0')}';
    }
  }
}

// Helper extension for takeLast
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}
