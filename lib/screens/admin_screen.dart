import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_api_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/match.dart';
import '../models/chat_message.dart';
import '../models/role.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_text.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final _adminApiService = AdminApiService();
  final _apiService = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _statistics;
  List<User> _users = [];
  List<Match> _matches = [];
  List<ChatMessage> _messages = [];
  List<Role> _roles = [];
  List<Permission> _permissions = [];
  bool _isLoading = true;
  bool _isLoadingUsers = false;
  bool _isLoadingMatches = false;
  bool _isLoadingMessages = false;
  bool _isLoadingRoles = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final index = _tabController.index;
        if (index == 2 && _matches.isEmpty) {
          _loadMatches();
        } else if (index == 3 && _messages.isEmpty) {
          _loadMessages();
        } else if (index == 4 && _roles.isEmpty) {
          _loadRoles();
        }
      }
    });
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoad() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (!user.isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn không có quyền truy cập trang admin'),
              backgroundColor: Colors.red,
            ),
          );
          context.go('/');
        }
        return;
      }

      setState(() => _currentUser = user);
      await _loadStatistics();
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
        context.go('/');
      }
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminApiService.getStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thống kê: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _adminApiService.getAllUsers();
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải users: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoadingMatches = true);
    try {
      final matches = await _adminApiService.getAllMatches();
      setState(() {
        _matches = matches;
        _isLoadingMatches = false;
      });
    } catch (e) {
      setState(() => _isLoadingMatches = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải matches: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoadingMessages = true);
    try {
      final messages = await _adminApiService.getAllMessages();
      setState(() {
        _messages = messages;
        _isLoadingMessages = false;
      });
    } catch (e) {
      setState(() => _isLoadingMessages = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải messages: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa user này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminApiService.deleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa user thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _toggleAdmin(int userId) async {
    try {
      await _adminApiService.toggleAdmin(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thay đổi quyền admin'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa match này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminApiService.deleteMatch(matchId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa match thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMatches();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminApiService.deleteMessage(messageId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa tin nhắn thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMessages();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
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
              title: 'ADMIN PANEL',
              showBackButton: true,
              onBackPressed: () => context.go('/'),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: PixelColors.border, width: 2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: PixelColors.primary,
                unselectedLabelColor: PixelColors.textSecondary,
                indicatorColor: PixelColors.primary,
                tabs: const [
                  Tab(text: 'THỐNG KÊ'),
                  Tab(text: 'NGƯỜI DÙNG'),
                  Tab(text: 'TRẬN ĐẤU'),
                  Tab(text: 'TIN NHẮN'),
                  Tab(text: 'PHÂN QUYỀN'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStatisticsTab(),
                  _buildUsersTab(),
                  _buildMatchesTab(),
                  _buildMessagesTab(),
                  _buildRolesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_statistics == null) {
      return Center(
        child: PixelText(
          text: 'KHÔNG CÓ DỮ LIỆU',
          style: PixelTextStyle.title,
          color: PixelColors.textSecondary,
        ),
      );
    }

    final users = _statistics!['users'] as Map<String, dynamic>;
    final matches = _statistics!['matches'] as Map<String, dynamic>;
    final messages = _statistics!['messages'] as Map<String, dynamic>;
    final friendships = _statistics!['friendships'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelCard(
            backgroundColor: PixelColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(
                  text: 'NGƯỜI DÙNG',
                  style: PixelTextStyle.title,
                  color: PixelColors.background,
                ),
                const SizedBox(height: 8),
                PixelText(
                  text: 'Tổng: ${users['total']}',
                  style: PixelTextStyle.body,
                  color: PixelColors.background,
                ),
                PixelText(
                  text: 'Online: ${users['online']}',
                  style: PixelTextStyle.body,
                  color: PixelColors.background,
                ),
                PixelText(
                  text: 'Admin: ${users['admins']}',
                  style: PixelTextStyle.body,
                  color: PixelColors.background,
                ),
                PixelText(
                  text: 'Mới (24h): ${users['recent_24h']}',
                  style: PixelTextStyle.caption,
                  color: PixelColors.background,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PixelCard(
            backgroundColor: PixelColors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(
                  text: 'TRẬN ĐẤU',
                  style: PixelTextStyle.title,
                  color: PixelColors.background,
                ),
                const SizedBox(height: 8),
                PixelText(
                  text: 'Tổng: ${matches['total']}',
                  style: PixelTextStyle.body,
                  color: PixelColors.background,
                ),
                PixelText(
                  text: 'Đang diễn ra: ${matches['active']}',
                  style: PixelTextStyle.body,
                  color: PixelColors.background,
                ),
                PixelText(
                  text: 'Hoàn thành: ${matches['completed']}',
                  style: PixelTextStyle.body,
                  color: PixelColors.background,
                ),
                PixelText(
                  text: 'Mới (24h): ${matches['recent_24h']}',
                  style: PixelTextStyle.caption,
                  color: PixelColors.background,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PixelCard(
            backgroundColor: PixelColors.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(
                  text: 'TIN NHẮN',
                  style: PixelTextStyle.title,
                  color: PixelColors.background,
                ),
                const SizedBox(height: 8),
                PixelText(
                  text: 'Tổng: ${messages['total']}',
                  style: PixelTextStyle.body,
                  color: PixelColors.background,
                ),
                PixelText(
                  text: 'Mới (24h): ${messages['recent_24h']}',
                  style: PixelTextStyle.caption,
                  color: PixelColors.background,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PixelCard(
            backgroundColor: PixelColors.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(
                  text: 'BẠN BÈ',
                  style: PixelTextStyle.title,
                  color: PixelColors.background,
                ),
                const SizedBox(height: 8),
                PixelText(
                  text: 'Tổng: ${friendships['total']}',
                  style: PixelTextStyle.body,
                  color: PixelColors.background,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PixelButton(
            text: 'LÀM MỚI',
            onPressed: () {
              _loadStatistics();
              _loadUsers();
            },
            backgroundColor: PixelColors.primary,
            isLarge: false,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(
        child: PixelText(
          text: 'KHÔNG CÓ NGƯỜI DÙNG',
          style: PixelTextStyle.title,
          color: PixelColors.textSecondary,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return PixelCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PixelColors.primary,
                      border: Border.all(color: PixelColors.border, width: 2),
                    ),
                    child: Center(
                      child: PixelText(
                        text: user.username.substring(0, 1).toUpperCase(),
                        style: PixelTextStyle.subtitle,
                        color: PixelColors.background,
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
                            Flexible(
                              child: PixelText(
                                text: user.username.toUpperCase(),
                                style: PixelTextStyle.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: PixelColors.error,
                                  border: Border.all(color: PixelColors.border, width: 1),
                                ),
                                child: PixelText(
                                  text: 'ADMIN',
                                  style: PixelTextStyle.caption,
                                  color: PixelColors.background,
                                ),
                              ),
                            ],
                          ],
                        ),
                        PixelText(
                          text: user.email,
                          style: PixelTextStyle.caption,
                          color: PixelColors.textSecondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        PixelText(
                          text: 'ELO: ${user.eloRating} | W: ${user.totalWins} L: ${user.totalLosses}',
                          style: PixelTextStyle.caption,
                          color: PixelColors.textLight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PixelButton(
                    text: user.isAdmin ? 'BỎ ADMIN' : 'THÊM ADMIN',
                    onPressed: () => _toggleAdmin(user.id),
                    backgroundColor: user.isAdmin ? PixelColors.warning : PixelColors.success,
                    width: 110,
                    height: 32,
                    borderWidth: 2,
                    shadowOffset: 2,
                    isLarge: false,
                  ),
                  PixelButton(
                    text: 'XÓA',
                    onPressed: () => _deleteUser(user.id),
                    backgroundColor: PixelColors.error,
                    width: 70,
                    height: 32,
                    borderWidth: 2,
                    shadowOffset: 2,
                    isLarge: false,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    if (_isLoadingMatches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelText(
              text: 'KHÔNG CÓ TRẬN ĐẤU',
              style: PixelTextStyle.title,
              color: PixelColors.textSecondary,
            ),
            const SizedBox(height: 16),
            PixelButton(
              text: 'TẢI DỮ LIỆU',
              onPressed: _loadMatches,
              backgroundColor: PixelColors.primary,
              isLarge: false,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return PixelCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelText(
                text: 'MATCH: ${match.matchId.substring(0, 8)}',
                style: PixelTextStyle.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              PixelText(
                text: 'Status: ${match.status.displayName.toUpperCase()}',
                style: PixelTextStyle.caption,
                color: PixelColors.textSecondary,
              ),
              if (match.player1Time != null && match.player2Time != null) ...[
                const SizedBox(height: 4),
                PixelText(
                  text: 'P1: ${_formatTime(match.player1Time!)} | P2: ${_formatTime(match.player2Time!)}',
                  style: PixelTextStyle.caption,
                  color: PixelColors.textLight,
                ),
              ],
              const SizedBox(height: 8),
              PixelButton(
                text: 'XÓA',
                onPressed: () => _deleteMatch(match.matchId),
                backgroundColor: PixelColors.error,
                width: 70,
                height: 32,
                borderWidth: 2,
                shadowOffset: 2,
                isLarge: false,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelText(
              text: 'KHÔNG CÓ TIN NHẮN',
              style: PixelTextStyle.title,
              color: PixelColors.textSecondary,
            ),
            const SizedBox(height: 16),
            PixelButton(
              text: 'TẢI DỮ LIỆU',
              onPressed: _loadMessages,
              backgroundColor: PixelColors.primary,
              isLarge: false,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return PixelCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelText(
                text: 'Match: ${message.matchId.substring(0, 8)}',
                style: PixelTextStyle.caption,
                color: PixelColors.textSecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              PixelText(
                text: message.content,
                style: PixelTextStyle.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              PixelText(
                text: 'Sender: ${message.senderId} | ${_formatDateTime(message.createdAt)}',
                style: PixelTextStyle.caption,
                color: PixelColors.textLight,
              ),
              const SizedBox(height: 8),
              PixelButton(
                text: 'XÓA',
                onPressed: () => _deleteMessage(message.id),
                backgroundColor: PixelColors.error,
                width: 70,
                height: 32,
                borderWidth: 2,
                shadowOffset: 2,
                isLarge: false,
              ),
            ],
          ),
        );
      },
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

  Future<void> _loadRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final roles = await _adminApiService.getAllRoles();
      final permissions = await _adminApiService.getAllPermissions();
      setState(() {
        _roles = roles;
        _permissions = permissions;
        _isLoadingRoles = false;
      });
    } catch (e) {
      setState(() => _isLoadingRoles = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải roles: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildRolesTab() {
    if (_isLoadingRoles) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: PixelColors.border, width: 2),
              ),
            ),
            child: const TabBar(
              labelColor: PixelColors.primary,
              unselectedLabelColor: PixelColors.textSecondary,
              indicatorColor: PixelColors.primary,
              tabs: [
                Tab(text: 'ROLES'),
                Tab(text: 'PERMISSIONS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRolesList(),
                _buildPermissionsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    if (_roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelText(
              text: 'KHÔNG CÓ ROLES',
              style: PixelTextStyle.title,
              color: PixelColors.textSecondary,
            ),
            const SizedBox(height: 16),
            PixelButton(
              text: 'TẢI DỮ LIỆU',
              onPressed: _loadRoles,
              backgroundColor: PixelColors.primary,
              isLarge: false,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _roles.length,
      itemBuilder: (context, index) {
        final role = _roles[index];
        return PixelCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PixelText(
                          text: role.name.toUpperCase(),
                          style: PixelTextStyle.subtitle,
                        ),
                        if (role.description != null) ...[
                          const SizedBox(height: 4),
                          PixelText(
                            text: role.description!,
                            style: PixelTextStyle.caption,
                            color: PixelColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionsList() {
    if (_permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelText(
              text: 'KHÔNG CÓ PERMISSIONS',
              style: PixelTextStyle.title,
              color: PixelColors.textSecondary,
            ),
            const SizedBox(height: 16),
            PixelButton(
              text: 'TẢI DỮ LIỆU',
              onPressed: _loadRoles,
              backgroundColor: PixelColors.primary,
              isLarge: false,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _permissions.length,
      itemBuilder: (context, index) {
        final permission = _permissions[index];
        return PixelCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelText(
                text: permission.name.toUpperCase(),
                style: PixelTextStyle.subtitle,
              ),
              const SizedBox(height: 4),
              PixelText(
                text: '${permission.resource}.${permission.action}',
                style: PixelTextStyle.caption,
                color: PixelColors.textSecondary,
              ),
              if (permission.description != null) ...[
                const SizedBox(height: 4),
                PixelText(
                  text: permission.description!,
                  style: PixelTextStyle.caption,
                  color: PixelColors.textLight,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

