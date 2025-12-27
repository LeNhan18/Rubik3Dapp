import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_text.dart';

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
    return Scaffold(
      backgroundColor: PixelColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PixelHeader(
              title: 'BẢNG XẾP HẠNG ELO',
              showBackButton: true,
              onBackPressed: () => context.go('/'),
              actions: [
                PopupMenuButton<int>(
                  icon: const Icon(Icons.filter_list, color: PixelColors.background),
                  onSelected: (limit) {
                    setState(() {
                      _selectedLimit = limit;
                    });
                    _loadLeaderboard();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 10, child: PixelText(text: 'Top 10', style: PixelTextStyle.caption)),
                    PopupMenuItem(value: 50, child: PixelText(text: 'Top 50', style: PixelTextStyle.caption)),
                    PopupMenuItem(value: 100, child: PixelText(text: 'Top 100', style: PixelTextStyle.caption)),
                    PopupMenuItem(value: 200, child: PixelText(text: 'Top 200', style: PixelTextStyle.caption)),
                  ],
                ),
                PixelButton(
                  text: '↻',
                  onPressed: _loadLeaderboard,
                  backgroundColor: PixelColors.primaryDark,
                  width: 40,
                  height: 40,
                  borderWidth: 2,
                  shadowOffset: 2,
                ),
              ],
            ),
            // Header info
            PixelCard(
              backgroundColor: PixelColors.surface,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('TỔNG SỐ', '${_leaderboard.length}'),
                  _buildStatItem('TOP 1', _leaderboard.isNotEmpty ? '${_leaderboard[0].eloRating}' : '-'),
                  _buildStatItem('TRUNG BÌNH', _leaderboard.isNotEmpty 
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
                                color: PixelColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              PixelText(
                                text: 'CHƯA CÓ DỮ LIỆU XẾP HẠNG',
                                style: PixelTextStyle.title,
                                color: PixelColors.textSecondary,
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

                              return _buildLeaderboardItem(user, rank, isCurrentUser);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        PixelText(
          text: value,
          style: PixelTextStyle.headline,
          color: PixelColors.primary,
        ),
        const SizedBox(height: 4),
        PixelText(
          text: label,
          style: PixelTextStyle.caption,
          color: PixelColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(User user, int rank, bool isCurrentUser) {
    final rankColor = _getRankColor(rank);
    final rankIcon = _getRankIcon(rank);
    final rankLabel = _getRankLabel(rank);

    return PixelCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: isCurrentUser ? PixelColors.accent.withOpacity(0.3) : PixelColors.card,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              border: Border.all(
                color: rankColor,
                width: 2,
              ),
            ),
            child: Center(
              child: PixelText(
                text: rank <= 3 ? rankLabel : '#$rank',
                style: rank <= 3 ? PixelTextStyle.headline : PixelTextStyle.subtitle,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PixelText(
                        text: user.username.toUpperCase(),
                        style: PixelTextStyle.subtitle,
                        color: isCurrentUser ? PixelColors.primary : PixelColors.textPrimary,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: PixelColors.primary,
                          border: Border.all(color: PixelColors.border, width: 2),
                        ),
                        child: PixelText(
                          text: 'BẠN',
                          style: PixelTextStyle.caption,
                          color: PixelColors.background,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: PixelColors.warning),
                    const SizedBox(width: 4),
                    PixelText(
                      text: 'ELO: ${user.eloRating}',
                      style: PixelTextStyle.body,
                      color: PixelColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    PixelText(
                      text: 'THẮNG: ${user.totalWins}',
                      style: PixelTextStyle.caption,
                      color: PixelColors.success,
                    ),
                    const SizedBox(width: 12),
                    PixelText(
                      text: 'THUA: ${user.totalLosses}',
                      style: PixelTextStyle.caption,
                      color: PixelColors.error,
                    ),
                    const SizedBox(width: 12),
                    PixelText(
                      text: 'HÒA: ${user.totalDraws}',
                      style: PixelTextStyle.caption,
                      color: PixelColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (user.bestTime != null)
                  PixelText(
                    text: _formatTime(user.bestTime!),
                    style: PixelTextStyle.caption,
                    color: PixelColors.textSecondary,
                  ),
                if (user.isOnline)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: PixelColors.success,
                      border: Border.all(color: PixelColors.border, width: 1),
                    ),
                  ),
              ],
            ),
          ],
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

