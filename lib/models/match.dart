enum MatchStatus {
  waiting,
  active,
  completed,
  cancelled;

  static MatchStatus fromString(String value) {
    switch (value) {
      case 'waiting':
        return MatchStatus.waiting;
      case 'active':
        return MatchStatus.active;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.waiting;
    }
  }

  String get displayName {
    switch (this) {
      case MatchStatus.waiting:
        return 'Chờ bắt đầu';
      case MatchStatus.active:
        return 'Đang thi đấu';
      case MatchStatus.completed:
        return 'Hoàn thành';
      case MatchStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

class Match {
  final int id;
  final String matchId;
  final int player1Id;
  final int player2Id;
  final String scramble;
  final MatchStatus status;
  final int? player1Time; // milliseconds
  final int? player2Time; // milliseconds
  final int? winnerId;
  final bool isDraw;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Optional: player info (from API response)
  final String? player1Username;
  final String? player2Username;

  Match({
    required this.id,
    required this.matchId,
    required this.player1Id,
    required this.player2Id,
    required this.scramble,
    required this.status,
    this.player1Time,
    this.player2Time,
    this.winnerId,
    required this.isDraw,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.player1Username,
    this.player2Username,
  });


  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as int,
      matchId: json['match_id'] as String,
      player1Id: json['player1_id'] as int,
      player2Id: json['player2_id'] as int,
      scramble: json['scramble'] as String,
      status: MatchStatus.fromString(json['status'] as String),
      player1Time: json['player1_time'] is int 
          ? json['player1_time'] as int?
          : (json['player1_time'] is String ? int.tryParse(json['player1_time'] as String) : null),
      player2Time: json['player2_time'] is int
          ? json['player2_time'] as int?
          : (json['player2_time'] is String ? int.tryParse(json['player2_time'] as String) : null),
      winnerId: json['winner_id'] as int?,
      isDraw: json['is_draw'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'scramble': scramble,
      'status': status.name,
      'player1_time': player1Time,
      'player2_time': player2Time,
      'winner_id': winnerId,
      'is_draw': isDraw,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  bool get isActive => status == MatchStatus.active;
  bool get isCompleted => status == MatchStatus.completed;
  bool get isWaiting => status == MatchStatus.waiting;

  String? getWinner(int currentUserId) {
    if (!isCompleted) return null;
    if (isDraw) return 'Hòa';
    if (winnerId == currentUserId) return 'Bạn thắng';
    return 'Bạn thua';
  }
}

