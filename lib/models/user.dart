class User {
  final int id;
  final String username;
  final String email;
  final String? avatarUrl;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final double? averageTime;
  final int? bestTime;
  final int eloRating;
  final bool isOnline;
  final bool isAdmin;
  final DateTime? lastSeen;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.totalWins,
    required this.totalLosses,
    required this.totalDraws,
    this.averageTime,
    this.bestTime,
    this.eloRating = 1000,
    required this.isOnline,
    this.isAdmin = false,
    this.lastSeen,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      totalWins: json['total_wins'] as int? ?? 0,
      totalLosses: json['total_losses'] as int? ?? 0,
      totalDraws: json['total_draws'] as int? ?? 0,
      averageTime: json['average_time'] != null
          ? (json['average_time'] as num).toDouble()
          : null,
      bestTime: json['best_time'] as int?,
      eloRating: json['elo_rating'] as int? ?? 1000,
      isOnline: json['is_online'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'total_wins': totalWins,
      'total_losses': totalLosses,
      'total_draws': totalDraws,
      'average_time': averageTime,
      'best_time': bestTime,
      'elo_rating': eloRating,
      'is_online': isOnline,
      'is_admin': isAdmin,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

