import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../models/solve_time.dart';
import '../utils/advanced_scramble_generator.dart';
import '../utils/statistics.dart';
import '../utils/difficulty_level.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerState { idle, ready, inspection, running, finished }

enum InspectionState {
  none,
  active,
  warning, // Last 3 seconds
  overtime, // After 15 seconds
}

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  TimerState _timerState = TimerState.idle;
  InspectionState _inspectionState = InspectionState.none;

  late Stopwatch _stopwatch;
  late Stopwatch _inspectionStopwatch;
  Timer? _timer;
  Timer? _inspectionTimer;

  String _currentScramble = '';
  int _holdStartTime = 0;
  bool _isHolding = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  // Confetti
  late ConfettiController _confettiController;

  // Sample times for demo
  List<SolveTime> _sampleTimes = [];
  Statistics? _stats;

  // Focus node for keyboard input
  late FocusNode _focusNode;

  // Difficulty level
  DifficultyLevel _selectedDifficulty = DifficultyLevel.medium;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _inspectionStopwatch = Stopwatch();
    _focusNode = FocusNode();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade animation removed as it was unused

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Load difficulty preference
    _loadDifficultyPreference();

    // Generate initial scramble
    _generateNewScramble();

    // Initialize sample data
    _initializeSampleData();

    // Request focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _initializeSampleData() {
    final now = DateTime.now();
    _sampleTimes = [
      SolveTime(
        id: '1',
        timestamp: now.subtract(const Duration(minutes: 5)),
        milliseconds: 12340,
        scramble: "R U R' U' R U R'",
        status: SolveStatus.normal,
        sessionId: 'session1',
      ),
      SolveTime(
        id: '2',
        timestamp: now.subtract(const Duration(minutes: 4)),
        milliseconds: 11890,
        scramble: "F R U' R' F' R U R'",
        status: SolveStatus.normal,
        sessionId: 'session1',
      ),
      SolveTime(
        id: '3',
        timestamp: now.subtract(const Duration(minutes: 3)),
        milliseconds: 13560,
        scramble: "R U2 R' U' R U' R'",
        status: SolveStatus.plusTwo,
        sessionId: 'session1',
        penalty: 2000,
      ),
      SolveTime(
        id: '4',
        timestamp: now.subtract(const Duration(minutes: 2)),
        milliseconds: 10230,
        scramble: "F' U F U' F' U' F",
        status: SolveStatus.normal,
        sessionId: 'session1',
      ),
      SolveTime(
        id: '5',
        timestamp: now.subtract(const Duration(minutes: 1)),
        milliseconds: 14120,
        scramble: "R U R' F R F' U' R'",
        status: SolveStatus.normal,
        sessionId: 'session1',
      ),
    ];
    _stats = Statistics(_sampleTimes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inspectionTimer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateNewScramble() {
    setState(() {
      _currentScramble = AdvancedWCAScrambleGenerator.generateEnhanced3x3WithDifficulty(
        _selectedDifficulty,
      );
    });
  }

  Future<void> _loadDifficultyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final difficultyIndex = prefs.getInt('difficulty_level') ?? 1; // Default: medium
    if (mounted) {
      setState(() {
        _selectedDifficulty = DifficultyLevel.values[difficultyIndex];
      });
    }
  }

  Future<void> _saveDifficultyPreference(DifficultyLevel difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('difficulty_level', difficulty.index);
  }

  void _startInspection() {
    setState(() {
      _timerState = TimerState.inspection;
      _inspectionState = InspectionState.active;
    });

    _inspectionStopwatch.reset();
    _inspectionStopwatch.start();

    _inspectionTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      final elapsed = _inspectionStopwatch.elapsedMilliseconds;

      setState(() {
        if (elapsed >= 15000) {
          _inspectionState = InspectionState.overtime;
        } else if (elapsed >= 12000) {
          _inspectionState = InspectionState.warning;
        }
      });

      // Voice countdown for last 3 seconds
      if (elapsed >= 12000 && elapsed < 15000) {
        // Calculate seconds left: 15 - (elapsed ~/ 1000);
        if (elapsed % 1000 < 100) {
          // Trigger voice countdown or sound
          SystemSound.play(SystemSoundType.click);
        }
      }
    });
  }

  void _startTimer() {
    _inspectionTimer?.cancel();

    setState(() {
      _timerState = TimerState.running;
      _inspectionState = InspectionState.none;
    });

    _stopwatch.reset();
    _stopwatch.start();

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _stopwatch.stop();

    setState(() {
      _timerState = TimerState.finished;
    });

    // Add solve to history
    final solveTime = SolveTime(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      milliseconds: _stopwatch.elapsedMilliseconds,
      scramble: _currentScramble,
      status: SolveStatus.normal,
      sessionId: 'current_session',
    );

    _sampleTimes.add(solveTime);
    _stats = Statistics(_sampleTimes);

    // Check for personal best
    if (_stats!.getBest()?.id == solveTime.id) {
      _confettiController.play();
      _scaleController.forward().then((_) => _scaleController.reverse());
    }

    // Generate new scramble for next solve
    _generateNewScramble();
  }

  void _resetTimer() {
    _timer?.cancel();
    _inspectionTimer?.cancel();

    setState(() {
      _timerState = TimerState.idle;
      _inspectionState = InspectionState.none;
      _isHolding = false;
    });

    _stopwatch.reset();
    _inspectionStopwatch.reset();
  }

  void _handleSpacePress(bool isPressed) {
    if (isPressed) {
      _handleTouchStart();
    } else {
      _handleTouchEnd();
    }
  }

  void _handleTouchStart() {
    if (_timerState == TimerState.running) {
      _stopTimer();
      return;
    }

    _isHolding = true;
    _holdStartTime = DateTime.now().millisecondsSinceEpoch;

    if (_timerState == TimerState.idle) {
      setState(() {
        _timerState = TimerState.ready;
      });

      // Delayed start of inspection
      Timer(const Duration(milliseconds: 500), () {
        if (_isHolding && _timerState == TimerState.ready) {
          _startInspection();
        }
      });
    }
  }

  void _handleTouchEnd() {
    if (!_isHolding) return;

    _isHolding = false;
    final holdDuration = DateTime.now().millisecondsSinceEpoch - _holdStartTime;

    if (_timerState == TimerState.ready && holdDuration < 500) {
      _resetTimer();
    } else if (_timerState == TimerState.inspection ||
        (_timerState == TimerState.ready && holdDuration >= 500)) {
      _startTimer();
    } else if (_timerState == TimerState.finished) {
      _resetTimer();
    }
  }

  Color _getTimerColor() {
    switch (_timerState) {
      case TimerState.idle:
        return Colors.white;
      case TimerState.ready:
        return _isHolding ? Colors.red : Colors.yellow;
      case TimerState.inspection:
        switch (_inspectionState) {
          case InspectionState.warning:
            return Colors.orange;
          case InspectionState.overtime:
            return Colors.red;
          default:
            return Colors.blue;
        }
      case TimerState.running:
        return Colors.green;
      case TimerState.finished:
        return Colors.white;
    }
  }

  String _getDisplayTime() {
    switch (_timerState) {
      case TimerState.idle:
      case TimerState.ready:
        return '0.00';
      case TimerState.inspection:
        final elapsed = _inspectionStopwatch.elapsedMilliseconds;
        final remaining = max(0, 15000 - elapsed);
        return (remaining / 1000).toStringAsFixed(1);
      case TimerState.running:
        final elapsed = _stopwatch.elapsedMilliseconds;
        final seconds = elapsed / 1000;
        return seconds.toStringAsFixed(2);
      case TimerState.finished:
        final elapsed = _stopwatch.elapsedMilliseconds;
        final seconds = elapsed / 1000;
        return seconds.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Về trang chủ',
        ),
        title: const Text('Timer'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            _handleSpacePress(event is KeyDownEvent);
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  colors: const [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ),

              // Main content
              GestureDetector(
                onTapDown: (_) => _handleTouchStart(),
                onTapUp: (_) => _handleTouchEnd(),
                onTapCancel: () => _handleTouchEnd(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    children: [
                      // Scramble section
                      Expanded(flex: 2, child: _buildScrambleSection()),

                      // Timer section
                      Expanded(flex: 4, child: _buildTimerSection()),

                      // Statistics section
                      Expanded(flex: 2, child: _buildStatsSection()),

                      // Controls section
                      Expanded(flex: 1, child: _buildControlsSection()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrambleSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Giảm padding
      child: Column(
        mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
        children: [
          // Difficulty selector
          _buildDifficultySelector(),
          const SizedBox(height: 12), // Giảm spacing
          Text(
            'Scramble',
            style: Theme.of(context).textTheme.titleMedium?.copyWith( // Giảm từ headlineSmall
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // Giảm spacing
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: SingleChildScrollView( // Thêm scroll để tránh overflow
                  child: Text(
                    _currentScramble,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith( // Giảm từ titleLarge
                      fontFamily: 'monospace',
                      letterSpacing: 1.5, // Giảm letter spacing
                      fontSize: 16, // Giảm font size
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer display
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _timerState == TimerState.ready
                    ? _pulseAnimation.value
                    : _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: _getTimerColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getTimerColor(), width: 3),
                  ),
                  child: Text(
                    _getDisplayTime(),
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: _getTimerColor(),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Instructions
          Text(
            _getInstructionText(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getInstructionText() {
    switch (_timerState) {
      case TimerState.idle:
        return 'Hold SPACE or touch and hold to start';
      case TimerState.ready:
        return 'Keep holding...';
      case TimerState.inspection:
        return 'Inspection time - Release to start timer';
      case TimerState.running:
        return 'Solving... Press SPACE or tap to stop';
      case TimerState.finished:
        return 'Tap to reset for next solve';
    }
  }
  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Giảm padding
      child: Column(
        mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith( // Giảm từ headlineSmall
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // Giảm từ 16
          Row(
            children: [
              _buildStatCard(
                'ao5',
                Statistics.formatTime(_stats!.calculateAo5()),
              ),
              _buildStatCard(
                'ao12',
                Statistics.formatTime(_stats!.calculateAo12()),
              ),
              _buildStatCard('Best', _stats!.getBest()?.formattedTime ?? '-'),
              _buildStatCard(
                'Mean',
                Statistics.formatTime(_stats!.calculateMean()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Giảm padding
        child: Row(
          mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
          children: [
            Icon(
              _getDifficultyIcon(_selectedDifficulty),
              color: _getDifficultyColor(_selectedDifficulty),
              size: 18, // Giảm icon size
            ),
            const SizedBox(width: 8), // Giảm spacing
            Flexible( // Wrap Text trong Flexible
              child: Text(
                'Mức độ khó:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith( // Giảm font size
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Giảm padding
              decoration: BoxDecoration(
                color: _getDifficultyColor(_selectedDifficulty).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getDifficultyColor(_selectedDifficulty).withOpacity(0.3),
                ),
              ),
              child: DropdownButton<DifficultyLevel>(
                value: _selectedDifficulty,
                underline: const SizedBox(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: _getDifficultyColor(_selectedDifficulty),
                ),
                items: DifficultyLevel.values.map((difficulty) {
                  return DropdownMenuItem<DifficultyLevel>(
                    value: difficulty,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDifficultyIcon(difficulty),
                          size: 14, // Giảm icon size
                          color: _getDifficultyColor(difficulty),
                        ),
                        const SizedBox(width: 6), // Giảm spacing
                        Flexible( // Wrap Text trong Flexible
                          child: Text(
                            difficulty.nameVi,
                            style: TextStyle(
                              color: _getDifficultyColor(difficulty),
                              fontWeight: FontWeight.w500,
                              fontSize: 13, // Giảm font size
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (DifficultyLevel? newDifficulty) {
                  if (newDifficulty != null) {
                    setState(() {
                      _selectedDifficulty = newDifficulty;
                    });
                    _saveDifficultyPreference(newDifficulty);
                    _generateNewScramble();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDifficultyIcon(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Icons.sentiment_very_satisfied;
      case DifficultyLevel.medium:
        return Icons.sentiment_neutral;
      case DifficultyLevel.hard:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3), // Giảm từ 4
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // Giảm padding
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7),
                fontSize: 11, // Giảm font size
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Flexible( // Thay Text bằng Flexible
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith( // Giảm từ titleMedium
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 13, // Giảm font size
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _timerState == TimerState.finished
                ? () {
                    // Add +2 penalty
                    if (_sampleTimes.isNotEmpty) {
                      final lastSolve = _sampleTimes.last;
                      _sampleTimes.removeLast();
                      _sampleTimes.add(
                        lastSolve.copyWith(
                          status: SolveStatus.plusTwo,
                          penalty: 2000,
                        ),
                      );
                      _stats = Statistics(_sampleTimes);
                      setState(() {});
                    }
                  }
                : null,
            child: const Text('+2'),
          ),
          ElevatedButton(
            onPressed: _timerState == TimerState.finished
                ? () {
                    // Mark as DNF
                    if (_sampleTimes.isNotEmpty) {
                      final lastSolve = _sampleTimes.last;
                      _sampleTimes.removeLast();
                      _sampleTimes.add(
                        lastSolve.copyWith(status: SolveStatus.dnf),
                      );
                      _stats = Statistics(_sampleTimes);
                      setState(() {});
                    }
                  }
                : null,
            child: const Text('DNF'),
          ),
          ElevatedButton(
            onPressed: () {
              _generateNewScramble();
              setState(() {});
            },
            child: const Text('New Scramble'),
          ),
        ],
      ),
    );
  }
}
