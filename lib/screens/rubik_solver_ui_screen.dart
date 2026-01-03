import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/rubik_cube.dart';
import '../solver/simple_bfs_solver.dart';
import '../widgets/cube_net_view.dart';
import '../widgets/rubik_control_button.dart';

class RubikSolverUIScreen extends StatefulWidget {
  const RubikSolverUIScreen({super.key});

  @override
  State<RubikSolverUIScreen> createState() => _RubikSolverUIScreenState();
}

class _RubikSolverUIScreenState extends State<RubikSolverUIScreen>
    with TickerProviderStateMixin {
  // Cube state - 6 faces, mỗi face là 3x3 grid
  late Map<String, List<List<CubeColor?>>> _cubeState = _initializeSolvedCube();
  late RubikCube _cube = RubikCube();

  // View mode: 0=3D, 1=Net/Unfolded, 2=Perspective
  int _viewMode = 0;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Solution state
  List<String> _solutionSteps = [];
  int _currentStepIndex = 0;
  bool _isSolving = false;
  String? _hint;
  bool _isLoadingHint = false;

  Map<String, List<List<CubeColor?>>> _initializeSolvedCube() {
    return {
      'up': List.generate(
          3, (_) => List.filled(3, CubeColor.white, growable: false).toList()),
      'down': List.generate(
          3, (_) => List.filled(3, CubeColor.yellow, growable: false).toList()),
      'front': List.generate(
          3, (_) => List.filled(3, CubeColor.blue, growable: false).toList()),
      'back': List.generate(
          3, (_) => List.filled(3, CubeColor.green, growable: false).toList()),
      'left': List.generate(
          3, (_) => List.filled(3, CubeColor.orange, growable: false).toList()),
      'right': List.generate(
          3, (_) => List.filled(3, CubeColor.red, growable: false).toList()),
    };
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _changeView(int newView) {
    _fadeController.forward(from: 0);
    _pageController.animateToPage(
      newView,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _blankCube() {
    setState(() {
      _cubeState = {
        'up': List.generate(
            3, (_) => List.filled(3, null, growable: false).toList()),
        'down': List.generate(
            3, (_) => List.filled(3, null, growable: false).toList()),
        'front': List.generate(
            3, (_) => List.filled(3, null, growable: false).toList()),
        'back': List.generate(
            3, (_) => List.filled(3, null, growable: false).toList()),
        'left': List.generate(
            3, (_) => List.filled(3, null, growable: false).toList()),
        'right': List.generate(
            3, (_) => List.filled(3, null, growable: false).toList()),
      };
      _solutionSteps.clear();
      _currentStepIndex = 0;
    });
  }

  void _resetCube() {
    setState(() {
      _cubeState = _initializeSolvedCube();
      _solutionSteps.clear();
      _currentStepIndex = 0;
    });
  }

  void _scrambleCube() {
    setState(() {
      _cube = RubikCube();
      _cube.shuffle(moves: 10);
      // Update _cubeState từ _cube
      _updateCubeState();
      _solutionSteps.clear();
      _currentStepIndex = 0;
      print('✓ Scrambled cube');
      print('Is solved after scramble: ${_cube.isSolved()}');
    });
  }

  Future<void> _scanCube() async {
    // Navigate to scan screen
    final result = await context.push<Map<String, List<List<CubeColor?>>>>(
      '/scan-cube',
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        // Update cube state với kết quả scan
        _cubeState = result;
        _solutionSteps.clear();
        _currentStepIndex = 0;
        
        // Update RubikCube model từ scanned data
        _cube = RubikCube();
        _mapColorsToRubikCube(_cube, _cubeState);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Đã scan Rubik thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateCubeState() {
    // Reset tất cả các faces
    _cubeState = {
      'up': List.generate(
          3, (_) => List.filled(3, null, growable: false).toList()),
      'down': List.generate(
          3, (_) => List.filled(3, null, growable: false).toList()),
      'front': List.generate(
          3, (_) => List.filled(3, null, growable: false).toList()),
      'back': List.generate(
          3, (_) => List.filled(3, null, growable: false).toList()),
      'left': List.generate(
          3, (_) => List.filled(3, null, growable: false).toList()),
      'right': List.generate(
          3, (_) => List.filled(3, null, growable: false).toList()),
    };

    // Map cube state sang UI
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          final cubelet = _cube.cubelets[x][y][z];

          // Up face (y = 2)
          if (y == 2) {
            final color = cubelet.getFaceColor('up');
            if (color != null) {
              _cubeState['up']![z][x] = color;
            }
          }

          // Down face (y = 0)
          if (y == 0) {
            final color = cubelet.getFaceColor('down');
            if (color != null) {
              _cubeState['down']![z][x] = color;
            }
          }

          // Left face (x = 0)
          if (x == 0) {
            final color = cubelet.getFaceColor('left');
            if (color != null) {
              _cubeState['left']![y][2 - z] = color;
            }
          }

          // Right face (x = 2)
          if (x == 2) {
            final color = cubelet.getFaceColor('right');
            if (color != null) {
              _cubeState['right']![y][z] = color;
            }
          }

          // Front face (z = 2)
          if (z == 2) {
            final color = cubelet.getFaceColor('front');
            if (color != null) {
              _cubeState['front']![2 - y][x] = color;
            }
          }

          // Back face (z = 0)
          if (z == 0) {
            final color = cubelet.getFaceColor('back');
            if (color != null) {
              _cubeState['back']![2 - y][2 - x] = color;
            }
          }
        }
      }
    }
  }

  void _solveCube() async {
    setState(() => _isSolving = true);

    // Khởi tạo cube mới
    final cube = RubikCube();

    // Set colors từ UI vào cube (chỉ những sticker visible)
    _mapColorsToRubikCube(cube, _cubeState);

    print('🚀 Bắt đầu BFS solver...');
    final steps = await SimpleBFSSolver.solve(cube);

    print('📝 Steps found: $steps');

    if (steps.isEmpty) {
      setState(() {
        _solutionSteps = [];
        _isSolving = false;
      });
      _showSnackBar('⚠ Không tìm được solution', Colors.orange);
      return;
    }

    // Apply moves
    for (final move in steps) {
      _applyCubeMove(cube, move);
    }

    setState(() {
      _solutionSteps = steps;
      _currentStepIndex = 0;
      _isSolving = false;
    });

    if (cube.isSolved()) {
      _showSnackBar('✓ Giải thành công! 🎉', Colors.green);
    } else {
      _showSnackBar('⚠ Chưa hoàn toàn giải', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Convert cube state to Kociemba format (54 characters)
  String _cubeStateToKociembaFormat() {
    // Kociemba format: URFDLB (6 faces)
    // Each face: 9 characters (3x3 grid)
    // Colors: U=0, R=1, F=2, D=3, L=4, B=5

    String result = '';

    // U (Up) face
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        result += _colorToKociembaChar(_cubeState['up']![row][col]);
      }
    }

    // R (Right) face
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        result += _colorToKociembaChar(_cubeState['right']![row][col]);
      }
    }

    // F (Front) face
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        result += _colorToKociembaChar(_cubeState['front']![row][col]);
      }
    }

    // D (Down) face
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        result += _colorToKociembaChar(_cubeState['down']![row][col]);
      }
    }

    // L (Left) face
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        result += _colorToKociembaChar(_cubeState['left']![row][col]);
      }
    }

    // B (Back) face
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        result += _colorToKociembaChar(_cubeState['back']![row][col]);
      }
    }

    return result;
  }

  /// Convert CubeColor to Kociemba character
  String _colorToKociembaChar(CubeColor? color) {
    if (color == null) return '?'; // Invalid
    switch (color) {
      case CubeColor.white:
        return 'U';
      case CubeColor.red:
        return 'R';
      case CubeColor.blue:
        return 'F';
      case CubeColor.yellow:
        return 'D';
      case CubeColor.orange:
        return 'L';
      case CubeColor.green:
        return 'B';
    }
  }

  /// Get hint from backend API
  Future<void> _getHint() async {
    setState(() => _isLoadingHint = true);

    try {
      final cubeStateStr = _cubeStateToKociembaFormat();

      // Validate cube state (no null colors)
      if (cubeStateStr.contains('?')) {
        _showSnackBar('⚠ Điền đầy đủ tất cả màu sắc', Colors.orange);
        setState(() => _isLoadingHint = false);
        return;
      }

      // Call backend API
      // Local development
      const apiUrl = 'http://172.20.10.5:8000/rubik/hint';
      
      // Fly.io production (commented)
      // const apiUrl = 'https://app-falling-wind-2135.fly.dev/rubik/hint';

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cube_state': cubeStateStr,
              'n_moves': 1,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hints = data['hint'] as List<dynamic>;

        if (hints.isNotEmpty) {
          final hint = hints[0] as String;

          setState(() {
            _hint = hint;
            _isLoadingHint = false;
          });

          final description = _getMoveDescription(hint);
          _showSnackBar('💡 $description', Colors.blue);
        } else {
          _showSnackBar('Không tìm được gợi ý', Colors.orange);
          setState(() => _isLoadingHint = false);
        }
      } else {
        _showSnackBar('⚠ Lỗi API: ${response.statusCode}', Colors.red);
        setState(() => _isLoadingHint = false);
      }
    } catch (e) {
      print('Error getting hint: $e');
      _showSnackBar('⚠ Không thể kết nối tới server: $e', Colors.red);
      setState(() => _isLoadingHint = false);
    }
  }

  void _mapColorsToRubikCube(
    RubikCube cube,
    Map<String, List<List<CubeColor?>>> cubeState,
  ) {
    // Map từ UI sang cube model
    final upColors = cubeState['up']!;
    for (int x = 0; x < 3; x++) {
      for (int z = 0; z < 3; z++) {
        final color = upColors[z][x];
        if (color != null) {
          cube.cubelets[x][2][z].setFaceColor('up', color);
        }
      }
    }

    final downColors = cubeState['down']!;
    for (int x = 0; x < 3; x++) {
      for (int z = 0; z < 3; z++) {
        final color = downColors[z][x];
        if (color != null) {
          cube.cubelets[x][0][z].setFaceColor('down', color);
        }
      }
    }

    final leftColors = cubeState['left']!;
    for (int y = 0; y < 3; y++) {
      for (int z = 0; z < 3; z++) {
        final color = leftColors[y][2 - z];
        if (color != null) {
          cube.cubelets[0][y][z].setFaceColor('left', color);
        }
      }
    }

    final rightColors = cubeState['right']!;
    for (int y = 0; y < 3; y++) {
      for (int z = 0; z < 3; z++) {
        final color = rightColors[y][z];
        if (color != null) {
          cube.cubelets[2][y][z].setFaceColor('right', color);
        }
      }
    }

    final frontColors = cubeState['front']!;
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        final color = frontColors[2 - y][x];
        if (color != null) {
          cube.cubelets[x][y][2].setFaceColor('front', color);
        }
      }
    }

    final backColors = cubeState['back']!;
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        final color = backColors[2 - y][2 - x];
        if (color != null) {
          cube.cubelets[x][y][0].setFaceColor('back', color);
        }
      }
    }
  }

  void _applyCubeMove(RubikCube cube, String move) {
    switch (move) {
      case 'F':
        cube.rotateFace('front', true);
        break;
      case 'F\'':
        cube.rotateFace('front', false);
        break;
      case 'R':
        cube.rotateFace('right', true);
        break;
      case 'R\'':
        cube.rotateFace('right', false);
        break;
      case 'U':
        cube.rotateFace('up', true);
        break;
      case 'U\'':
        cube.rotateFace('up', false);
        break;
      case 'D':
        cube.rotateFace('down', true);
        break;
      case 'D\'':
        cube.rotateFace('down', false);
        break;
      case 'L':
        cube.rotateFace('left', true);
        break;
      case 'L\'':
        cube.rotateFace('left', false);
        break;
      case 'B':
        cube.rotateFace('back', true);
        break;
      case 'B\'':
        cube.rotateFace('back', false);
        break;
      case 'R2':
        cube.rotateFace('right', true);
        cube.rotateFace('right', true);
        break;
      case 'L2':
        cube.rotateFace('left', true);
        cube.rotateFace('left', true);
        break;
      case 'U2':
        cube.rotateFace('up', true);
        cube.rotateFace('up', true);
        break;
      case 'D2':
        cube.rotateFace('down', true);
        cube.rotateFace('down', true);
        break;
      case 'F2':
        cube.rotateFace('front', true);
        cube.rotateFace('front', true);
        break;
      case 'B2':
        cube.rotateFace('back', true);
        cube.rotateFace('back', true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Rubik Solver'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // View Mode Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildViewTabButton('3D', 0),
                _buildViewTabButton('Net', 1),
                _buildViewTabButton('Perspective', 2),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _viewMode = index);
                },
                children: [
                  // View 1: 3D Cube
                  _build3DView(),
                  // View 2: Net/Unfolded
                  _buildNetView(),
                  // View 3: Perspective
                  _buildPerspectiveView(),
                ],
              ),
            ),
          ),
          // Solution Info
          if (_solutionSteps.isNotEmpty) ...[
            Container(
              color: Colors.blue[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Solution: ${_solutionSteps.length} moves',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _solutionSteps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final move = entry.value;
                        final isDone = index < _currentStepIndex;
                        final isCurrent = index == _currentStepIndex - 1;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: AnimatedSolutionCard(
                            move: move,
                            isCurrent: isCurrent,
                            isDone: isDone,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Control Buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RubikControlButton(
                      label: 'Scan',
                      icon: Icons.camera_alt,
                      onPressed: _scanCube,
                      color: Colors.blue,
                    ),
                    RubikControlButton(
                      label: 'Blank',
                      icon: Icons.clear,
                      onPressed: _blankCube,
                      color: Colors.grey[600]!,
                    ),
                    RubikControlButton(
                      label: 'Reset',
                      icon: Icons.refresh,
                      onPressed: _resetCube,
                      color: Colors.orange,
                    ),
                    RubikControlButton(
                      label: 'Scramble',
                      icon: Icons.shuffle,
                      onPressed: _scrambleCube,
                      color: Colors.red,
                    ),
                    RubikControlButton(
                      label: 'Hint',
                      icon: Icons.lightbulb,
                      onPressed: _isLoadingHint ? null : _getHint,
                      color: Colors.amber[600]!,
                      isLoading: _isLoadingHint,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSolving ? null : _solveCube,
                        icon: _isSolving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.play_arrow),
                        label: const Text('Solve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Hint display
          if (_hint != null) ...[
            Container(
              color: Colors.amber[50],
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gợi ý:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getMoveDescription(_hint!),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get description for a move
  String _getMoveDescription(String move) {
    switch (move) {
      case 'R':
        return 'Xoay mặt phải theo chiều kim đồng hồ';
      case 'R\'':
        return 'Xoay mặt phải ngược chiều kim đồng hồ';
      case 'R2':
        return 'Xoay mặt phải 180 độ';
      case 'L':
        return 'Xoay mặt trái theo chiều kim đồng hồ';
      case 'L\'':
        return 'Xoay mặt trái ngược chiều kim đồng hồ';
      case 'L2':
        return 'Xoay mặt trái 180 độ';
      case 'U':
        return 'Xoay mặt trên theo chiều kim đồng hồ';
      case 'U\'':
        return 'Xoay mặt trên ngược chiều kim đồng hồ';
      case 'U2':
        return 'Xoay mặt trên 180 độ';
      case 'D':
        return 'Xoay mặt dưới theo chiều kim đồng hồ';
      case 'D\'':
        return 'Xoay mặt dưới ngược chiều kim đồng hồ';
      case 'D2':
        return 'Xoay mặt dưới 180 độ';
      case 'F':
        return 'Xoay mặt trước theo chiều kim đồng hồ';
      case 'F\'':
        return 'Xoay mặt trước ngược chiều kim đồng hồ';
      case 'F2':
        return 'Xoay mặt trước 180 độ';
      case 'B':
        return 'Xoay mặt sau theo chiều kim đồng hồ';
      case 'B\'':
        return 'Xoay mặt sau ngược chiều kim đồng hồ';
      case 'B2':
        return 'Xoay mặt sau 180 độ';
      default:
        return move;
    }
  }

  Widget _buildViewTabButton(String label, int index) {
    final isSelected = _viewMode == index;
    return GestureDetector(
      onTap: () => _changeView(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _build3DView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.threed_rotation,
                size: 100,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '3D View\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNetView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CubeNetView(
          cubeState: _cubeState,
          onColorChanged: (face, row, col, color) {
            setState(() {
              _cubeState[face]![row][col] = color;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPerspectiveView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.view_in_ar,
                size: 100,
                color: Colors.purple,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Perspective View\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
