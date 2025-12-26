import 'package:flutter/material.dart';
import 'dart:async';

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _displayTime = '0.00';
  bool _isReady = false;
  bool _isRunning = false;
  List<String> _times = [];
  String _scramble = '';

  // Scramble moves
  final List<String> _moves = [
    'F',
    'F\'',
    'B',
    'B\'',
    'R',
    'R\'',
    'L',
    'L\'',
    'U',
    'U\'',
    'D',
    'D\'',
  ];

  @override
  void initState() {
    super.initState();
    _generateScramble();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateScramble() {
    final random = DateTime.now().millisecondsSinceEpoch;
    List<String> scramble = [];
    for (int i = 0; i < 20; i++) {
      scramble.add(_moves[random % _moves.length]);
    }
    setState(() {
      _scramble = scramble.join(' ');
    });
  }

  void _startTimer() {
    if (!_isReady) return;

    setState(() {
      _isRunning = true;
      _isReady = false;
    });

    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        _displayTime = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(
          2,
        );
      });
    });
  }

  void _stopTimer() {
    if (!_isRunning) return;

    _stopwatch.stop();
    _timer?.cancel();

    setState(() {
      _isRunning = false;
      _times.add(_displayTime);
      if (_times.length > 10) _times.removeAt(0);
    });

    _resetTimer();
  }

  void _resetTimer() {
    _stopwatch.reset();
    setState(() {
      _displayTime = '0.00';
      _isReady = false;
    });
    _generateScramble();
  }

  String _getAverageOf5() {
    if (_times.length < 5) return '--';
    List<double> lastFive =
        _times
            .sublist(_times.length - 5)
            .map((time) => double.parse(time))
            .toList();
    lastFive.sort();
    // Remove best and worst, average the middle 3
    double average = (lastFive[1] + lastFive[2] + lastFive[3]) / 3;
    return average.toStringAsFixed(2);
  }

  String _getBestTime() {
    if (_times.isEmpty) return '--';
    return _times
        .map((time) => double.parse(time))
        .reduce((min, time) => time < min ? time : min)
        .toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.timer, size: 40, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Speedcubing Timer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Hold SPACE or tap to start/stop',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scramble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scramble:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _generateScramble,
                      tooltip: 'New scramble',
                    ),
                  ],
                ),
                Text(
                  _scramble,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Timer Display
          Expanded(
            child: GestureDetector(
              onTapDown: (_) {
                if (_isRunning) {
                  _stopTimer();
                } else if (!_isReady) {
                  setState(() {
                    _isReady = true;
                  });
                }
              },
              onTapUp: (_) {
                if (_isReady && !_isRunning) {
                  _startTimer();
                }
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      _isRunning
                          ? Colors.red.shade50
                          : _isReady
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _isRunning
                            ? Colors.red.shade300
                            : _isReady
                            ? Colors.green.shade300
                            : Colors.blue.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _displayTime,
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color:
                            _isRunning
                                ? Colors.red.shade700
                                : _isReady
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isRunning
                          ? 'Release to stop'
                          : _isReady
                          ? 'Release to start!'
                          : 'Hold to get ready',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Best', _getBestTime(), Colors.green),
                    _buildStatItem('Avg 5', _getAverageOf5(), Colors.blue),
                    _buildStatItem('Count', '${_times.length}', Colors.purple),
                  ],
                ),
                const SizedBox(height: 12),
                if (_times.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _times.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _times[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
