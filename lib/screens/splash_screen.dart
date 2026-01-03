import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_text.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    print('SplashScreen: initState called');

    try {
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _scaleController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      _rotationController = AnimationController(
        duration: const Duration(milliseconds: 3000),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ));

      _scaleAnimation = Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ));

      _rotationAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOut,
      ));

      print('SplashScreen: Animations initialized');
      _startAnimations();
    } catch (e, stackTrace) {
      print('SplashScreen: ERROR in initState: $e');
      print('Stack: $stackTrace');
    }
  }

  void _startAnimations() async {
    // Start fade animation
    _fadeController.forward();

    // Start scale animation after a delay
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();

    // Start rotation animation
    await Future.delayed(const Duration(milliseconds: 200));
    _rotationController.forward();

    // Navigate after splash duration
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      // TẠM THỜI: Bỏ qua API call để test app có chạy được không
      // TODO: Bật lại sau khi fix network issue
      print('Splash: Skipping API call for testing - navigating to home');
      if (mounted) {
        context.go('/');
      }
      
      /* COMMENTED OUT - Uncomment sau khi fix network
      // Kiểm tra xem user đã đăng nhập chưa và có phải admin không
      try {
        print('Splash: Checking user authentication...');
        final apiService = ApiService();
        // Giảm timeout xuống 2 giây để nhanh hơn
        final user = await apiService.getCurrentUser().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            print('Splash: API timeout - navigating to home');
            throw TimeoutException('API timeout');
          },
        );
        print('Splash: User authenticated - isAdmin: ${user.isAdmin}');
        // Nếu là admin thì chuyển đến admin panel
        if (user.isAdmin) {
          if (mounted) {
            print('Splash: Navigating to admin panel');
            context.go('/admin');
          }
        } else {
          if (mounted) {
            print('Splash: Navigating to home');
            context.go('/');
          }
        }
      } catch (e) {
        // Nếu chưa đăng nhập hoặc lỗi, về home
        // Log error để debug
        print('Splash screen error: $e');
        print('Splash: Navigating to home (error fallback)');
        if (mounted) {
          context.go('/');
        }
      }
      */
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('SplashScreen: build called');
    try {
      return Scaffold(
        backgroundColor: PixelColors.background,
        body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: PixelColors.primary,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Main logo and animation
              AnimatedBuilder(
                animation: Listenable.merge([
                  _fadeAnimation,
                  _scaleAnimation,
                  _rotationAnimation,
                ]),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFFFFF), // White face
                                    Color(0xFFEF4444), // Red face
                                    Color(0xFF22C55E), // Green face
                                    Color(0xFF3B82F6), // Blue face
                                    Color(0xFFEAB308), // Yellow face
                                    Color(0xFFFF8C00), // Orange face
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.view_in_ar_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // App name
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PixelText(
                          text: 'RUBIK MASTER',
                          style: PixelTextStyle.display,
                          color: PixelColors.background,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        PixelText(
                          text: 'KHÁM PHÁ THẾ GIỚI RUBIK',
                          style: PixelTextStyle.body,
                          color: PixelColors.background.withOpacity(0.9),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 3),

              // Loading indicator
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PixelText(
                          text: 'ĐANG KHỞI TẠO...',
                          style: PixelTextStyle.caption,
                          color: PixelColors.background.withOpacity(0.7),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('SplashScreen: ERROR in build: $e');
      print('Stack: $stackTrace');
      // Fallback UI nếu có lỗi
      return Scaffold(
        backgroundColor: Colors.blue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.white),
              SizedBox(height: 16),
              Text('Lỗi hiển thị splash screen', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              Text('$e', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }
}
