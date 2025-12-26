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



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  await Hive.initFlutter();

  // Open basic settings box
  await Hive.openBox('settings'); // Set preferred orientations
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

  runApp(
    ProviderScope(
      child: RubikMasterApp(),
    ),
  );
}

class RubikMasterApp extends ConsumerWidget {
  RubikMasterApp({super.key});

  // GoRouter configuration
  late final GoRouter _router = GoRouter(
    initialLocation: '/splash',
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
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
