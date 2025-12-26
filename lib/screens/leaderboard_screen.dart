import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _apiService = ApiService();
  List<User> _leaderboard = [];
  bool _isLoading = true;
  int _selectedLimit = 100;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadLeaderboard();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      try {
        final user = await _apiService.getCurrentUser();
        setState(() {
          _currentUserId = user.id;
        });
      } catch (e) {
        // User not logged in, that's okay
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final leaderboard = await _apiService.getLeaderboard(limit: _selectedLimit);
      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.brown.shade400;
    return Colors.blue;
  }

  IconData _getRankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events;
    if (rank == 2) return Icons.workspace_premium;
    if (rank == 3) return Icons.stars;
    return Icons.person;
  }

  String _getRankLabel(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Bảng xếp hạng ELO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (limit) {
              setState(() {
                _selectedLimit = limit;
              });
              _loadLeaderboard();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 10, child: Text('Top 10')),
              const PopupMenuItem(value: 50, child: Text('Top 50')),
              const PopupMenuItem(value: 100, child: Text('Top 100')),
              const PopupMenuItem(value: 200, child: Text('Top 200')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Tổng số', '${_leaderboard.length}'),
                _buildStatItem('Top 1', _leaderboard.isNotEmpty ? '${_leaderboard[0].eloRating}' : '-'),
                _buildStatItem('Trung bình', _leaderboard.isNotEmpty 
                  ? '${(_leaderboard.map((u) => u.eloRating).reduce((a, b) => a + b) / _leaderboard.length).round()}' 
                  : '-'),
              ],
            ),
          ),

          // Leaderboard list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _leaderboard.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.leaderboard_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có dữ liệu xếp hạng',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLeaderboard,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _leaderboard.length,
                          itemBuilder: (context, index) {
                            final user = _leaderboard[index];
                            final rank = index + 1;
                            final isCurrentUser = _currentUserId != null && user.id == _currentUserId;

                            return _buildLeaderboardItem(user, rank, isCurrentUser, theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(User user, int rank, bool isCurrentUser, ThemeData theme) {
    final rankColor = _getRankColor(rank);
    final rankIcon = _getRankIcon(rank);
    final rankLabel = _getRankLabel(rank);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isCurrentUser ? theme.colorScheme.primaryContainer : null,
      elevation: isCurrentUser ? 4 : 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: rankColor,
              width: 2,
            ),
          ),
          child: Center(
            child: rank <= 3
                ? Text(
                    rankLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  )
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.username,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  'ELO: ${user.eloRating}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Thắng: ${user.totalWins}',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thua: ${user.totalLosses}',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hòa: ${user.totalDraws}',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (user.bestTime != null)
              Text(
                _formatTime(user.bestTime!),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            if (user.isOnline)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final seconds = milliseconds / 1000;
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(2)}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds.toStringAsFixed(0)}s';
  }
}

