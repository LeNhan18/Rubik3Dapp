import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_text.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  final _apiService = ApiService();
  List<Match> _matches = [];
  bool _isLoading = true;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null || token.isEmpty) {
      // Not logged in, redirect to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để sử dụng tính năng này'),
          ),
        );
        context.go('/login');
      }
      return;
    }
    
    // User is logged in, load matches
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _apiService.getMyMatches(
        statusFilter: _selectedStatus,
      );
      setState(() {
        _matches = matches;
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

  Future<void> _createMatch({int? opponentId}) async {
    try {
      final match = opponentId != null
          ? await _apiService.createMatch(opponentId: opponentId)
          : await _apiService.findOpponent();

      if (mounted) {
        context.go('/match/${match.matchId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PixelHeader(
              title: 'TRẬN ĐẤU',
              showBackButton: true,
              onBackPressed: () => context.go('/'),
              actions: [
                PixelButton(
                  text: '↻',
                  onPressed: _loadMatches,
                  backgroundColor: PixelColors.primaryDark,
                  width: 36,
                  height: 36,
                  borderWidth: 2,
                  shadowOffset: 2,
                ),
              ],
            ),
            // Filter chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              constraints: const BoxConstraints(maxHeight: 56),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('TẤT CẢ', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('CHỜ BẮT ĐẦU', 'waiting'),
                    const SizedBox(width: 8),
                    _buildFilterChip('ĐANG THI ĐẤU', 'active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('HOÀN THÀNH', 'completed'),
                  ],
                ),
              ),
            ),

            // Match list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _matches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_esports,
                                size: 64,
                                color: PixelColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              PixelText(
                                text: 'CHƯA CÓ TRẬN ĐẤU NÀO',
                                style: PixelTextStyle.title,
                                color: PixelColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              PixelButton(
                                text: 'TÌM ĐỐI THỦ',
                                onPressed: () => _createMatch(),
                                icon: Icons.add,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMatches,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _matches.length,
                            itemBuilder: (context, index) {
                              return _buildMatchCard(_matches[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: PixelButton(
        text: 'TẠO TRẬN ĐẤU',
        onPressed: () => _showCreateMatchDialog(),
        icon: Icons.add,
        backgroundColor: PixelColors.accent,
        isLarge: true,
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return PixelButton(
      text: label,
      onPressed: () {
        setState(() {
          _selectedStatus = isSelected ? null : status;
        });
        _loadMatches();
      },
      backgroundColor: isSelected ? PixelColors.primary : PixelColors.surface,
      textColor: isSelected ? PixelColors.background : PixelColors.textPrimary,
      borderColor: PixelColors.border,
      width: null,
      height: 32,
      borderWidth: 2,
      shadowOffset: 2,
    );
  }

  Widget _buildMatchCard(Match match) {
    final isActive = match.isActive;
    final isCompleted = match.isCompleted;

    return PixelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/match/${match.matchId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: PixelText(
                    text: match.status.displayName.toUpperCase(),
                    style: PixelTextStyle.subtitle,
                    color: isActive
                        ? PixelColors.success
                        : isCompleted
                            ? PixelColors.info
                            : PixelColors.textPrimary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCompleted && match.winnerId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: match.isDraw ? PixelColors.warning : PixelColors.success,
                      border: Border.all(color: PixelColors.border, width: 2),
                    ),
                    child: PixelText(
                      text: match.isDraw ? 'HÒA' : 'KẾT QUẢ',
                      style: PixelTextStyle.caption,
                      color: PixelColors.background,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPlayerInfo('PLAYER 1', match.player1Time),
                ),
                PixelText(
                  text: 'VS',
                  style: PixelTextStyle.title,
                  color: PixelColors.textSecondary,
                ),
                Expanded(
                  child: _buildPlayerInfo('PLAYER 2', match.player2Time),
                ),
              ],
            ),
            if (match.startedAt != null) ...[
              const SizedBox(height: 8),
              PixelText(
                text: 'BẮT ĐẦU: ${_formatDateTime(match.startedAt!)}',
                style: PixelTextStyle.caption,
                color: PixelColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(String label, int? time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PixelText(
          text: label,
          style: PixelTextStyle.caption,
          color: PixelColors.textSecondary,
        ),
        const SizedBox(height: 4),
        PixelText(
          text: time != null ? _formatTime(time) : 'CHƯA NỘP',
          style: PixelTextStyle.body,
          color: time != null ? PixelColors.info : PixelColors.textLight,
        ),
      ],
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => PixelCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelText(
              text: 'TẠO TRẬN ĐẤU',
              style: PixelTextStyle.headline,
              color: PixelColors.primary,
            ),
            const SizedBox(height: 24),
            PixelButton(
              text: 'TÌM ĐỐI THỦ NGẪU NHIÊN',
              onPressed: () {
                Navigator.pop(context);
                _createMatch();
              },
              icon: Icons.shuffle,
              isLarge: true,
            ),
            const SizedBox(height: 12),
            PixelButton(
              text: 'THÁCH ĐẤU BẠN BÈ',
              onPressed: () {
                Navigator.pop(context);
                context.go('/friends');
              },
              icon: Icons.person_add,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }
}

