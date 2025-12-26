import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/rubik_cube.dart';
import '../services/rubik_solver_service.dart';
import '../widgets/cube_color_picker.dart';
import '../widgets/cube_net_view.dart';

class SolverScreen extends StatefulWidget {
  const SolverScreen({super.key});

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  // Cube state - 6 faces, mỗi face là 3x3 grid
  // Khởi tạo với màu sắc chuẩn của Rubik's Cube đã giải
  late Map<String, List<List<CubeColor?>>> _cubeState = _initializeSolvedCube();

  // Khởi tạo cube với trạng thái đã giải (mỗi mặt có cùng một màu)
  Map<String, List<List<CubeColor?>>> _initializeSolvedCube() {
    return {
      'up': List.generate(3, (_) => List.filled(3, CubeColor.white)), // Mặt trên - trắng
      'down': List.generate(3, (_) => List.filled(3, CubeColor.yellow)), // Mặt dưới - vàng
      'front': List.generate(3, (_) => List.filled(3, CubeColor.blue)), // Mặt trước - xanh dương
      'back': List.generate(3, (_) => List.filled(3, CubeColor.green)), // Mặt sau - xanh lá
      'left': List.generate(3, (_) => List.filled(3, CubeColor.orange)), // Mặt trái - cam
      'right': List.generate(3, (_) => List.filled(3, CubeColor.red)), // Mặt phải - đỏ
    };
  }

  RubikSolverService? _solverService;
  List<String> _solutionSteps = [];
  int _currentStepIndex = 0;
  bool _isSolving = false;
  String? _currentStep;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Về trang chủ',
        ),
        title: const Text('Rubik Solver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCube,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Hướng dẫn',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Chọn màu cho từng sticker trên 6 mặt của cube\n'
                      '2. Nhấn "Tìm giải pháp" để generate solution\n'
                      '3. Nhấn "Gợi ý tiếp theo" để xem từng bước giải',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cube faces editor
            Text(
              'Nhập trạng thái cube',
              style: Theme.of(context).textTheme.titleMedium?.copyWith( // Giảm từ titleLarge
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Cube Net View (Unfolded) - Hiển thị dạng "net" như trong hình
            Card(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CubeNetView(
                  cubeState: _cubeState,
                  onColorChanged: (face, row, col, color) {
                    setState(() {
                      _cubeState[face]![row][col] = color;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16), // Giảm từ 24

            // Solution section
            if (_solutionSteps.isNotEmpty) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Giải pháp đã tìm thấy',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tổng số bước: ${_solutionSteps.length}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (_currentStepIndex > 0)
                        Text(
                          'Đã thực hiện: $_currentStepIndex / ${_solutionSteps.length}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current step display
              if (_currentStep != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Bước hiện tại:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _currentStep!,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Solution steps list
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tất cả các bước:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _solutionSteps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          final isCurrent = index == _currentStepIndex - 1;
                          final isDone = index < _currentStepIndex - 1;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.blue[200]
                                  : isDone
                                      ? Colors.green[200]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? Colors.blue[700]!
                                    : Colors.grey[400]!,
                                width: isCurrent ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              step,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent
                                    ? Colors.blue[900]
                                    : isDone
                                        ? Colors.green[900]
                                        : Colors.grey[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSolving ? null : _generateSolution,
                        icon: _isSolving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isSolving ? 'Đang tìm...' : 'Tìm giải pháp'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (_solutionSteps.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _solverService?.hasNextStep() ?? false
                              ? _showNextStep
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Gợi ý tiếp theo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_solutionSteps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetSolution,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset giải pháp'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showAllSteps,
                          icon: const Icon(Icons.list),
                          label: const Text('Xem tất cả'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            if (_solutionSteps.isNotEmpty && _currentStepIndex >= _solutionSteps.length) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hoàn thành! Cube đã được giải.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _generateSolution() async {
    // Kiểm tra xem đã nhập đủ màu chưa
    bool allFilled = true;
    for (final face in _cubeState.values) {
      for (final row in face) {
        for (final color in row) {
          if (color == null) {
            allFilled = false;
            break;
          }
        }
        if (!allFilled) break;
      }
      if (!allFilled) break;
    }

    if (!allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ màu cho tất cả các mặt!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSolving = true;
    });

    // Tạo cube từ state
    final cube = RubikCube();
    // TODO: Map colors từ _cubeState vào cube
    // Hiện tại chỉ generate solution đơn giản

    _solverService = RubikSolverService(cube);
    final steps = _solverService!.generateSolution();

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate solving

    setState(() {
      _solutionSteps = steps;
      _currentStepIndex = 0;
      _currentStep = null;
      _isSolving = false;
    });
  }

  void _showNextStep() {
    if (_solverService == null) return;

    final nextStep = _solverService!.getNextStep();
    if (nextStep != null) {
      setState(() {
        _currentStep = nextStep;
      });

      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bước $_currentStepIndex: $nextStep'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetCube() {
    setState(() {
      // Reset về trạng thái đã giải với màu sắc chuẩn
      _cubeState = _initializeSolvedCube();
      _solutionSteps.clear();
      _currentStepIndex = 0;
      _currentStep = null;
      _solverService = null;
    });
  }

  void _resetSolution() {
    if (_solverService != null) {
      _solverService!.reset();
      setState(() {
        _currentStepIndex = 0;
        _currentStep = null;
      });
    }
  }

  void _showAllSteps() {
    if (_solutionSteps.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tất cả các bước giải'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng số bước: ${_solutionSteps.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _solutionSteps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Chip(
                    label: Text(
                      '${index + 1}. $step',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    backgroundColor: index < _currentStepIndex
                        ? Colors.green[100]
                        : Colors.grey[200],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
