import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final _apiService = ApiService();
  User? _currentUser;
  bool _isLoadingUser = true;

  final List<_HomeButton> _buttons = [
    _HomeButton(
      title: 'Timer',
      subtitle: 'WCA official timer',
      icon: Icons.timer,
      route: '/timer',
      color: Colors.blue,
    ),
    _HomeButton(
      title: '3D Cube',
      subtitle: 'Interactive cube',
      icon: Icons.view_in_ar,
      route: '/cube3d',
      color: Colors.green,
    ),
    _HomeButton(
      title: 'Solver',
      subtitle: 'Auto solve cube',
      icon: Icons.psychology,
      route: '/solver',
      color: Colors.purple,
    ),
    _HomeButton(
      title: '3D Solver',
      subtitle: 'Shuffle & solve 3D',
      icon: Icons.auto_fix_high,
      route: '/cube3d-solver',
      color: Colors.orange,
    ),
    _HomeButton(
      title: 'Thi đấu',
      subtitle: 'Match & Chat',
      icon: Icons.sports_esports,
      route: '/matches',
      color: Colors.red,
    ),
    _HomeButton(
      title: 'Bạn bè',
      subtitle: 'Friends & Challenge',
      icon: Icons.people,
      route: '/friends',
      color: Colors.teal,
    ),
    _HomeButton(
      title: 'Xếp hạng',
      subtitle: 'ELO Leaderboard',
      icon: Icons.leaderboard,
      route: '/leaderboard',
      color: Colors.indigo,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token != null && token.isNotEmpty) {
        final user = await _apiService.getCurrentUser();
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _logout() async {
    await _apiService.clearToken();
    setState(() {
      _currentUser = null;
    });
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Rubik Master'),
        actions: [
          if (_isLoadingUser)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_currentUser != null)
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(
                        _currentUser!.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentUser!.username,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text('Xem thông tin'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout),
                      const SizedBox(width: 8),
                      Text('Đăng xuất'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                } else if (value == 'profile') {
                  // TODO: Navigate to profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Xin chào ${_currentUser!.username}!'),
                    ),
                  );
                }
              },
            )
          else
            TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập'),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'Rubik Master',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentUser != null
                                  ? 'Xin chào, ${_currentUser!.username}!'
                                  : 'Your complete cubing companion',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main Buttons Grid
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.0, // Giảm từ 1.1 xuống 1.0 để card cao hơn
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _buttons.length,
                            itemBuilder: (context, index) {
                              final button = _buttons[index];
                              return TweenAnimationBuilder<double>(
                                duration: Duration(
                                  milliseconds: 600 + (index * 100),
                                ),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: _buildHomeButton(button, theme),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Giảm vertical padding
                        child: Text(
                          'Tap any button to get started!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(_HomeButton button, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go(button.route);
        },
        child: Container(
          padding: const EdgeInsets.all(12), // Giảm từ 16 xuống 12
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Giảm từ 12 xuống 10
                decoration: BoxDecoration(
                  color: button.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(button.icon, size: 28, color: button.color), // Giảm từ 32 xuống 28
              ),
              const SizedBox(height: 8), // Giảm từ 12 xuống 8
              Flexible( // Thay Text bằng Flexible để tránh overflow
                child: Text(
                  button.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15, // Giảm font size một chút
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible( // Thay Text bằng Flexible để tránh overflow
                child: Text(
                  button.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11, // Giảm font size một chút
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;

  const _HomeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });
}
