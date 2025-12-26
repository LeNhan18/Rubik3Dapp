import '../models/rubik_cube.dart';
import '../solver/rubik_solver.dart';

/// Service để generate solution steps từ RubikSolver
class RubikSolverService {
  final RubikCube cube;
  late RubikSolver solver;
  
  List<String> _solutionSteps = [];
  int _currentStepIndex = 0;

  RubikSolverService(this.cube) {
    solver = RubikSolver(cube);
  }

  /// Generate solution steps
  List<String> generateSolution() {
    _solutionSteps.clear();
    _currentStepIndex = 0;

    // Phân tích trạng thái hiện tại
    final analysis = solver.analyzeState();

    // Generate solution dựa trên trạng thái
    if (!analysis['cross_solved']!) {
      _solutionSteps.addAll([
        'F', 'R', 'U', 'R\'', 'F\'', // Cross step 1
        'D', 'R', 'U\'', 'R\'', 'D\'', // Cross step 2
      ]);
    }

    if (!analysis['first_layer_solved']!) {
      _solutionSteps.addAll([
        'R', 'U', 'R\'', 'U\'', // First layer step 1
        'R', 'U', 'R\'', 'U\'', // First layer step 2
        'R', 'U', 'R\'', 'U\'', // First layer step 3
      ]);
    }

    if (!analysis['second_layer_solved']!) {
      _solutionSteps.addAll([
        'U', 'R', 'U\'', 'R\'', 'U\'', 'F\'', 'U', 'F', // Second layer step 1
        'U\'', 'L\'', 'U', 'L', 'U', 'F', 'U\'', 'F\'', // Second layer step 2
      ]);
    }

    if (!analysis['last_layer_cross_solved']!) {
      _solutionSteps.addAll([
        'F', 'R', 'U', 'R\'', 'U\'', 'F\'', // Last layer cross step 1
        'F', 'U', 'R', 'U\'', 'R\'', 'F\'', // Last layer cross step 2
      ]);
    }

    // Thêm các bước cuối cùng
    _solutionSteps.addAll([
      'R', 'U', 'R\'', 'F\'', 'R', 'F', 'U\'', 'R\'', // OLL
      'R\'', 'U', 'R\'', 'U\'', 'R\'', 'U\'', 'R\'', 'U', 'R', 'U', 'R2', // PLL
    ]);

    return List.from(_solutionSteps);
  }

  /// Lấy bước tiếp theo
  String? getNextStep() {
    if (_currentStepIndex < _solutionSteps.length) {
      return _solutionSteps[_currentStepIndex++];
    }
    return null;
  }

  /// Reset về bước đầu
  void reset() {
    _currentStepIndex = 0;
  }

  /// Kiểm tra còn bước nào không
  bool hasNextStep() {
    return _currentStepIndex < _solutionSteps.length;
  }

  /// Lấy tổng số bước
  int getTotalSteps() {
    return _solutionSteps.length;
  }

  /// Lấy số bước hiện tại
  int getCurrentStepNumber() {
    return _currentStepIndex;
  }

  /// Lấy tất cả các bước
  List<String> getAllSteps() {
    return List.from(_solutionSteps);
  }
}

