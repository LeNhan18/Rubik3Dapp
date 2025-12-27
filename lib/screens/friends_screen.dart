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
    return Scaffold(
      backgroundColor: PixelColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PixelHeader(
              title: 'BẠN BÈ',
              showBackButton: true,
              onBackPressed: () => context.go('/'),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: PixelCard(
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontFamily: 'VT323',
                    fontSize: 20,
                    color: PixelColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'TÌM KIẾM NGƯỜI DÙNG...',
                    hintStyle: const TextStyle(
                      fontFamily: 'VT323',
                      fontSize: 18,
                      color: PixelColors.textLight,
                    ),
                    prefixIcon: const Icon(Icons.search, color: PixelColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: PixelColors.primary),
                            onPressed: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: _searchUsers,
                ),
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
      ),
    );
  }

  Widget _buildMainContent() {
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
            child: TabBar(
              labelColor: PixelColors.primary,
              unselectedLabelColor: PixelColors.textSecondary,
              indicatorColor: PixelColors.primary,
              tabs: const [
                Tab(text: 'BẠN BÈ'),
                Tab(text: 'LỜI MỜI'),
              ],
            ),
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
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: PixelColors.textSecondary,
            ),
            const SizedBox(height: 16),
            PixelText(
              text: 'CHƯA CÓ BẠN BÈ NÀO',
              style: PixelTextStyle.title,
              color: PixelColors.textSecondary,
            ),
            const SizedBox(height: 8),
            PixelText(
              text: 'TÌM KIẾM ĐỂ THÊM BẠN BÈ',
              style: PixelTextStyle.body,
              color: PixelColors.textLight,
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
              color: PixelColors.textSecondary,
            ),
            const SizedBox(height: 16),
            PixelText(
              text: 'CHƯA CÓ LỜI MỜI NÀO',
              style: PixelTextStyle.title,
              color: PixelColors.textSecondary,
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
    final friendshipId = request['id'] as int;
    // user1 là người gửi request, user2 là người nhận (current user)
    final senderUsername = request['user1_username'] as String? ?? 'Unknown';

    return PixelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PixelColors.primary,
              border: Border.all(color: PixelColors.border, width: 2),
            ),
            child: Center(
              child: PixelText(
                text: senderUsername.substring(0, 1).toUpperCase(),
                style: PixelTextStyle.title,
                color: PixelColors.background,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(
                  text: senderUsername.toUpperCase(),
                  style: PixelTextStyle.subtitle,
                ),
                PixelText(
                  text: 'ĐÃ GỬI LỜI MỜI KẾT BẠN',
                  style: PixelTextStyle.caption,
                  color: PixelColors.textSecondary,
                ),
              ],
            ),
          ),
          PixelButton(
            text: 'CHẤP NHẬN',
            onPressed: () => _acceptFriendRequest(friendshipId),
            icon: Icons.check,
            backgroundColor: PixelColors.success,
            width: 120,
            height: 36,
            borderWidth: 2,
            shadowOffset: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: PixelText(
          text: 'KHÔNG TÌM THẤY NGƯỜI DÙNG NÀO',
          style: PixelTextStyle.title,
          color: PixelColors.textSecondary,
        ),
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
    // Kiểm tra xem user có phải là bạn không (trong danh sách _friends)
    final isActuallyFriend = _friends.any((friend) => friend.id == user.id);

    return PixelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PixelColors.primary,
              border: Border.all(color: PixelColors.border, width: 2),
            ),
            child: Center(
              child: PixelText(
                text: user.username.substring(0, 1).toUpperCase(),
                style: PixelTextStyle.title,
                color: PixelColors.background,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(
                  text: user.username.toUpperCase(),
                  style: PixelTextStyle.subtitle,
                ),
                PixelText(
                  text: user.email.toUpperCase(),
                  style: PixelTextStyle.caption,
                  color: PixelColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: user.isOnline ? PixelColors.success : PixelColors.textLight,
                        border: Border.all(color: PixelColors.border, width: 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PixelText(
                      text: user.isOnline ? 'ĐANG ONLINE' : 'OFFLINE',
                      style: PixelTextStyle.caption,
                      color: PixelColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          (isFriend || isActuallyFriend)
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: PixelColors.primary),
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
                    PopupMenuItem(
                      value: 'chat',
                      child: Row(
                        children: [
                          const Icon(Icons.chat, size: 16),
                          const SizedBox(width: 8),
                          PixelText(
                            text: 'Nhắn tin',
                            style: PixelTextStyle.caption,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'challenge',
                      child: Row(
                        children: [
                          const Icon(Icons.sports_esports, size: 16),
                          const SizedBox(width: 8),
                          PixelText(
                            text: 'Thách đấu',
                            style: PixelTextStyle.caption,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 8),
                          PixelText(
                            text: 'Xem hồ sơ',
                            style: PixelTextStyle.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : PixelButton(
                  text: 'THÊM BẠN',
                  onPressed: () => _sendFriendRequest(user),
                  icon: Icons.person_add,
                  backgroundColor: PixelColors.accent,
                  width: 100,
                  height: 36,
                  borderWidth: 2,
                  shadowOffset: 2,
                ),
        ],
      ),
    );
  }
}

