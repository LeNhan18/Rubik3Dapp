import 'package:hive/hive.dart';

part 'solve_time.g.dart';

@HiveType(typeId: 0)
class SolveTime {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final int milliseconds;

  @HiveField(3)
  final String scramble;

  @HiveField(4)
  final SolveStatus status;

  @HiveField(5)
  final String sessionId;

  @HiveField(6)
  final String? comment;

  @HiveField(7)
  final int? penalty; // +2 penalty in milliseconds

  const SolveTime({
    required this.id,
    required this.timestamp,
    required this.milliseconds,
    required this.scramble,
    required this.status,
    required this.sessionId,
    this.comment,
    this.penalty,
  });

  int get totalTime => milliseconds + (penalty ?? 0);

  bool get isDNF => status == SolveStatus.dnf;
  bool get hasPenalty => penalty != null && penalty! > 0;

  String get formattedTime {
    if (isDNF) return 'DNF';

    final total = totalTime;
    final minutes = total ~/ 60000;
    final seconds = (total % 60000) ~/ 1000;
    final millis = total % 1000;

    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}';
    } else {
      return '${seconds}.${(millis ~/ 10).toString().padLeft(2, '0')}';
    }
  }

  SolveTime copyWith({
    String? id,
    DateTime? timestamp,
    int? milliseconds,
    String? scramble,
    SolveStatus? status,
    String? sessionId,
    String? comment,
    int? penalty,
  }) {
    return SolveTime(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      milliseconds: milliseconds ?? this.milliseconds,
      scramble: scramble ?? this.scramble,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      comment: comment ?? this.comment,
      penalty: penalty ?? this.penalty,
    );
  }
}

@HiveType(typeId: 1)
enum SolveStatus {
  @HiveField(0)
  normal,
  @HiveField(1)
  dnf,
  @HiveField(2)
  plusTwo,
}
