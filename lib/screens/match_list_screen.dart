import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import '../services/api_service.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trận đấu của tôi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chờ bắt đầu', 'waiting'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đang thi đấu', 'active'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Hoàn thành', 'completed'),
                ],
              ),
            ),
          ),
          const Divider(),

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
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có trận đấu nào',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _createMatch(),
                              icon: const Icon(Icons.add),
                              label: const Text('Tìm đối thủ'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMatchDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo trận đấu'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
        _loadMatches();
      },
    );
  }

  Widget _buildMatchCard(Match match) {
    final theme = Theme.of(context);
    final isActive = match.isActive;
    final isCompleted = match.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/match/${match.matchId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.status.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isActive
                            ? Colors.green
                            : isCompleted
                                ? Colors.blue
                                : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCompleted && match.winnerId != null)
                    Chip(
                      label: Text(
                        match.isDraw ? 'Hòa' : 'Đã có kết quả',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: match.isDraw
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Scramble: ${match.scramble}',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPlayerInfo('Player 1', match.player1Time),
                  ),
                  const Text('VS'),
                  Expanded(
                    child: _buildPlayerInfo('Player 2', match.player2Time),
                  ),
                ],
              ),
              if (match.startedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Bắt đầu: ${_formatDateTime(match.startedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(String label, int? time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          time != null ? _formatTime(time) : 'Chưa nộp',
          style: TextStyle(
            fontSize: 14,
            color: time != null ? Colors.blue : Colors.grey,
          ),
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
      builder: (context) => AlertDialog(
        title: const Text('Tạo trận đấu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('Tìm đối thủ ngẫu nhiên'),
              onTap: () {
                Navigator.pop(context);
                _createMatch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Thách đấu bạn bè'),
              onTap: () {
                Navigator.pop(context);
                context.go('/friends');
              },
            ),
          ],
        ),
      ),
    );
  }
}

