import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId; // null = current user, otherwise = other user

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  User? _user;
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      User user;
      if (widget.userId == null) {
        // Load current user
        user = await _apiService.getCurrentUser();
        _isCurrentUser = true;
      } else {
        // Load other user (TODO: implement getUserById if needed)
        user = await _apiService.getCurrentUser(); // Temporary
        _isCurrentUser = false;
      }
      setState(() {
        _user = user;
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

  String _formatTime(int? milliseconds) {
    if (milliseconds == null) return 'Chưa có';
    final seconds = milliseconds / 1000;
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    final ms = (milliseconds % 1000) ~/ 10;
    if (minutes > 0) {
      return '${minutes}m ${secs}s ${ms.toString().padLeft(2, '0')}';
    }
    return '${secs}s ${ms.toString().padLeft(2, '0')}';
  }

  String _formatAverageTime(double? seconds) {
    if (seconds == null) return 'Chưa có';
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    if (minutes > 0) {
      return '${minutes}m ${secs.toStringAsFixed(1)}s';
    }
    return '${secs.toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: const Text('Hồ sơ'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: const Text('Hồ sơ'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Không tìm thấy người dùng')),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar and basic info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      _user!.username.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _user!.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _user!.isOnline ? 'Đang online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thống kê',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Thắng',
                          _user!.totalWins.toString(),
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Thua',
                          _user!.totalLosses.toString(),
                          Icons.close,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Hòa',
                          _user!.totalDraws.toString(),
                          Icons.handshake,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Thời gian',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    theme,
                    'Thời gian tốt nhất',
                    _formatTime(_user!.bestTime),
                    Icons.timer,
                  ),
                  _buildInfoRow(
                    theme,
                    'Thời gian trung bình',
                    _formatAverageTime(_user!.averageTime),
                    Icons.access_time,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Xếp hạng',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    theme,
                    'ELO Rating',
                    _user!.eloRating.toString(),
                    Icons.star,
                    Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Thông tin khác',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    theme,
                    'Ngày tham gia',
                    _user!.createdAt.toString().substring(0, 10),
                    Icons.calendar_today,
                  ),
                  if (_user!.lastSeen != null)
                    _buildInfoRow(
                      theme,
                      'Hoạt động lần cuối',
                      _user!.lastSeen!.toString().substring(0, 16),
                      Icons.schedule,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value, IconData icon, [Color? iconColor]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
        title: Text(label),
        trailing: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

