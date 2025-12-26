import 'package:hive/hive.dart';

part 'timer_session.g.dart';

@HiveType(typeId: 2)
class TimerSession {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime lastUsedAt;

  @HiveField(4)
  final String cubeType; // '3x3', '2x2', '4x4', etc.

  @HiveField(5)
  final List<String> solveIds;

  const TimerSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastUsedAt,
    required this.cubeType,
    required this.solveIds,
  });

  TimerSession copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    String? cubeType,
    List<String>? solveIds,
  }) {
    return TimerSession(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      cubeType: cubeType ?? this.cubeType,
      solveIds: solveIds ?? this.solveIds,
    );
  }
}
