import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  List<User> _friends = [];
  List<User> _searchResults = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingPending = false;
  int? _currentUserId;

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
    
    // User is logged in, load current user ID, friends and pending requests
    _loadCurrentUserId();
    _loadFriends();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _apiService.getFriends();
      print('Loaded ${friends.length} friends');
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friends: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _apiService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final user = await _apiService.getCurrentUser();
      setState(() {
        _currentUserId = user.id;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoadingPending = true);
    try {
      final requests = await _apiService.getPendingRequests();
      setState(() {
        _pendingRequests = requests;
        _isLoadingPending = false;
      });
    } catch (e) {
      print('Error loading pending requests: $e');
      setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _sendFriendRequest(User user) async {
    try {
      await _apiService.sendFriendRequest(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi lời mời kết bạn đến ${user.username}'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload pending requests
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptFriendRequest(int friendshipId) async {
    try {
      await _apiService.acceptFriendRequest(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chấp nhận lời mời kết bạn'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload friends and pending requests
        _loadFriends();
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _challengeUser(User user) async {
    try {
      final match = await _apiService.createMatch(opponentId: user.id);
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
      extendBodyBehindAppBar: false, // Đảm bảo không tràn lên status bar
      appBar: AppBar(
        title: const Text('Bạn bè'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isNotEmpty
                    ? _buildSearchResults()
                    : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Bạn bè'),
              Tab(text: 'Lời mời'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFriendsList(),
                _buildPendingRequestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    final theme = Theme.of(context);

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bạn bè nào',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tìm kiếm để thêm bạn bè',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_friends[index], isFriend: true);
      },
    );
  }

  Widget _buildPendingRequestsList() {
    final theme = Theme.of(context);

    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lời mời nào',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _buildPendingRequestCard(request);
      },
    );
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> request) {
    final theme = Theme.of(context);
    final friendshipId = request['id'] as int;
    // user1 là người gửi request, user2 là người nhận (current user)
    final senderUsername = request['user1_username'] as String? ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            senderUsername.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(senderUsername),
        subtitle: const Text('Đã gửi lời mời kết bạn'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Chấp nhận'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _acceptFriendRequest(friendshipId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy người dùng nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_searchResults[index], isFriend: false);
      },
    );
  }

  Widget _buildUserCard(User user, {required bool isFriend}) {
    final theme = Theme.of(context);
    // Kiểm tra xem user có phải là bạn không (trong danh sách _friends)
    final isActuallyFriend = _friends.any((friend) => friend.id == user.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            user.username.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(user.username),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                if (user.isOnline)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 4),
                Text(
                  user.isOnline ? 'Đang online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: (isFriend || isActuallyFriend)
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'chat') {
                    context.push('/chat', extra: user);
                  } else if (value == 'challenge') {
                    _challengeUser(user);
                  } else if (value == 'profile') {
                    context.push('/profile?userId=${user.id}');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'chat',
                    child: Row(
                      children: [
                        Icon(Icons.chat, size: 20),
                        SizedBox(width: 8),
                        Text('Nhắn tin'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'challenge',
                    child: Row(
                      children: [
                        Icon(Icons.sports_esports, size: 20),
                        SizedBox(width: 8),
                        Text('Thách đấu'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('Xem hồ sơ'),
                      ],
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Thêm bạn'),
                onPressed: () => _sendFriendRequest(user),
              ),
      ),
    );
  }
}

