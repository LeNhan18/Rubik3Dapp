import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_text.dart';

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
      color: PixelColors.accent,
    ),
    _HomeButton(
      title: '3D Cube',
      subtitle: 'Interactive cube',
      icon: Icons.view_in_ar,
      route: '/cube3d',
      color: PixelColors.success,
    ),
    _HomeButton(
      title: 'Solver',
      subtitle: 'Auto solve cube',
      icon: Icons.psychology,
      route: '/solver',
      color: PixelColors.primary,
    ),
    _HomeButton(
      title: 'Solver UI ✨',
      subtitle: 'Modern solver UI',
      icon: Icons.dashboard_customize,
      route: '/solver-ui',
      color: Colors.deepPurple,
    ),
    _HomeButton(
      title: '3D Solver',
      subtitle: 'Shuffle & solve 3D',
      icon: Icons.auto_fix_high,
      route: '/cube3d-solver',
      color: PixelColors.warning,
    ),
    _HomeButton(
      title: 'Thi đấu',
      subtitle: 'Match & Chat',
      icon: Icons.sports_esports,
      route: '/matches',
      color: PixelColors.error,
    ),
    _HomeButton(
      title: 'Bạn bè',
      subtitle: 'Friends & Challenge',
      icon: Icons.people,
      route: '/friends',
      color: PixelColors.info,
    ),
    _HomeButton(
      title: 'Xếp hạng',
      subtitle: 'ELO Leaderboard',
      icon: Icons.leaderboard,
      route: '/leaderboard',
      color: PixelColors.primaryDark,
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
    return Scaffold(
      backgroundColor: PixelColors.background,
      body: SafeArea(
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
                    PixelHeader(
                      title: 'TRANG CHỦ',
                      logoText: null,
                      showBackButton: false,
                      actions: [
                        if (_isLoadingUser)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PixelColors.background,
                              ),
                            ),
                          )
                        else if (_currentUser != null)
                          PopupMenuButton<String>(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: PixelColors.background,
                                      border: Border.all(
                                        color: PixelColors.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: PixelText(
                                        text: _currentUser!.username
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: PixelTextStyle.caption,
                                        color: PixelColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PixelText(
                                    text: _currentUser!.username.toUpperCase(),
                                    style: PixelTextStyle.caption,
                                    color: PixelColors.background,
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 8),
                                    PixelText(
                                      text: 'Xem thông tin',
                                      style: PixelTextStyle.caption,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    context.push('/profile');
                                  });
                                },
                              ),
                              if (_currentUser!.isAdmin)
                                PopupMenuItem(
                                  value: 'admin',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.admin_panel_settings, size: 16),
                                      const SizedBox(width: 8),
                                      PixelText(
                                        text: 'Admin Panel',
                                        style: PixelTextStyle.caption,
                                        color: PixelColors.error,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      context.push('/admin');
                                    });
                                  },
                                ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout, size: 16),
                                    const SizedBox(width: 8),
                                    PixelText(
                                      text: 'Đăng xuất',
                                      style: PixelTextStyle.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'logout') {
                                _logout();
                              }
                            },
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              constraints: const BoxConstraints(
                                  maxWidth: 60, maxHeight: 28),
                              child: PixelButton(
                                text: 'ĐĂNG NHẬP',
                                onPressed: () => context.go('/login'),
                                backgroundColor: PixelColors.primaryDark,
                                borderWidth: 2,
                                shadowOffset: 2,
                                isLarge: false,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Main content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            PixelText(
                              text: _currentUser != null
                                  ? 'XIN CHÀO, ${_currentUser!.username.toUpperCase()}!'
                                  : 'YOUR COMPLETE CUBING COMPANION',
                              style: PixelTextStyle.title,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Main Buttons Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio:
                                    0.95, // Tăng từ 1.0 lên 0.95 để có thêm không gian
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
                                      child: _buildHomeButton(button),
                                    );
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            PixelText(
                              text: 'TAP ANY BUTTON TO GET STARTED!',
                              style: PixelTextStyle.caption,
                              color: PixelColors.textSecondary,
                              textAlign: TextAlign.center,
                            ),
                          ],
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
    );
  }

  Widget _buildHomeButton(_HomeButton button) {
    return PixelCard(
      backgroundColor: button.color,
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          context.go(button.route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              button.icon,
              size: 36,
              color: PixelColors.background,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: PixelText(
                text: button.title.toUpperCase(),
                style: PixelTextStyle.button,
                color: PixelColors.background,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: PixelText(
                text: button.subtitle.toUpperCase(),
                style: PixelTextStyle.caption,
                color: PixelColors.background.withOpacity(0.9),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
