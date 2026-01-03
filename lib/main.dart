import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rubik_master/screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/cube_3d_screen.dart';
import 'screens/solver_screen.dart';
import 'screens/cube_3d_solver_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/match_list_screen.dart';
import 'screens/match_detail_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/friend_chat_screen.dart';
import 'screens/rubik_solver_ui_screen.dart';
import 'screens/cube_scan_screen.dart';
import 'screens/admin_screen.dart';
import 'models/user.dart';
import 'theme/pixel_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== APP STARTING ===');

  try {
    print('Initializing Hive...');
    // Initialize Hive database
    await Hive.initFlutter();
    print('Hive initialized');

    print('Opening settings box...');
    // Open basic settings box
    await Hive.openBox('settings');
    print('Settings box opened');
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Đảm bảo dialog quyền không bị che khuất và nội dung không tràn lên status bar
    // Sử dụng SystemUiMode.edgeToEdge nhưng vẫn giữ padding để tránh tràn
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    print('System UI configured');
  } catch (e, stackTrace) {
    // Log error nhưng vẫn chạy app
    print('ERROR initializing app: $e');
    print('Stack: $stackTrace');
  }

  // Wrap app với error boundary
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('=== FLUTTER ERROR ===');
    print('Exception: ${details.exception}');
    print('Stack: ${details.stack}');
    print('Library: ${details.library}');
    print('Context: ${details.context}');
  };

  print('Running app...');
  runApp(
    ProviderScope(
      child: RubikMasterApp(),
    ),
  );
  print('App started');
}

class RubikMasterApp extends ConsumerWidget {
  RubikMasterApp({super.key});

  // GoRouter configuration với error handling
  GoRouter _createRouter() {
    try {
      return GoRouter(
        initialLocation: '/splash',
        debugLogDiagnostics: true,
        routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/timer',
        builder: (context, state) => const TimerScreen(),
      ),
      GoRoute(
        path: '/cube3d',
        builder: (context, state) => const Cube3DScreen(),
      ),
      GoRoute(
        path: '/solver',
        builder: (context, state) => const SolverScreen(),
      ),
      GoRoute(
        path: '/solver-ui',
        builder: (context, state) => const RubikSolverUIScreen(),
      ),
      GoRoute(
        path: '/cube3d-solver',
        builder: (context, state) => const Cube3DSolverScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/matches',
        builder: (context, state) => const MatchListScreen(),
      ),
      GoRoute(
        path: '/match/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return MatchDetailScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          return ProfileScreen(
            userId: userId != null ? int.tryParse(userId) : null,
          );
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final friend = state.extra as User?;
          if (friend == null) {
            return const Scaffold(
              body: Center(child: Text('Không tìm thấy người dùng')),
            );
          }
          return FriendChatScreen(friend: friend);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/scan-cube',
        builder: (context, state) => const CubeScanScreen(),
      ),
    ],
      );
    } catch (e, stackTrace) {
      print('Error creating router: $e');
      print('Stack: $stackTrace');
      // Trả về router đơn giản với splash screen
      return GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Lỗi khởi tạo router'),
                    SizedBox(height: 8),
                    Text('$e', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      print('RubikMasterApp: build called');
      final router = _createRouter();
      print('RubikMasterApp: router created');
      
      ThemeData theme;
      try {
        theme = PixelTheme.lightTheme;
        print('RubikMasterApp: theme created');
      } catch (e) {
        print('RubikMasterApp: ERROR creating theme: $e');
        // Fallback theme
        theme = ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        );
      }
      
      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: theme,
        routerConfig: router,
        // Đảm bảo nội dung không tràn lên status bar
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          // Giữ nguyên padding từ MediaQuery gốc để tránh tràn lên status bar
          return MediaQuery(
            data: mediaQuery,
            child: child ?? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      // Nếu có lỗi, hiển thị error screen thay vì crash
      print('Error building app: $e');
      print('Stack: $stackTrace');
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Lỗi khởi động app'),
                SizedBox(height: 8),
                Text('$e', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }
  }
}
