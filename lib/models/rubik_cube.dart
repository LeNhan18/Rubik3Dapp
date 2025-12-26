import 'package:flutter/material.dart';

enum CubeColor { white, red, blue, orange, green, yellow }

class Cubelet {
  final int x, y, z;
  Map<String, CubeColor> faces;

  Cubelet({required this.x, required this.y, required this.z}) : faces = {};

  void setFaceColor(String face, CubeColor color) {
    faces[face] = color;
  }

  CubeColor? getFaceColor(String face) {
    return faces[face];
  }

  Color getFlutterColor(CubeColor color) {
    switch (color) {
      case CubeColor.white:
        return const Color(0xFFFFFFF0); // Ivory white
      case CubeColor.red:
        return const Color(0xFFB71C1C); // Deep red
      case CubeColor.blue:
        return const Color(0xFF0D47A1); // Deep blue
      case CubeColor.orange:
        return const Color(0xFFFF6F00); // Deep orange
      case CubeColor.green:
        return const Color(0xFF2E7D32); // Deep green
      case CubeColor.yellow:
        return const Color(0xFFFDD835); // Bright yellow
    }
  }
}

class RubikCube extends ChangeNotifier {
  List<List<List<Cubelet>>> cubelets = [];
  double rotationX = 0.0;
  double rotationY = 0.0;
  double rotationZ = 0.0;

  // Animation controllers for face rotations
  Map<String, double> faceRotations = {
    'front': 0.0,
    'back': 0.0,
    'left': 0.0,
    'right': 0.0,
    'up': 0.0,
    'down': 0.0,
  };

  // Animation states
  bool isAnimating = false;
  String? currentAnimatingFace;
  RubikCube() {
    _initializeCube();
  }

  void _initializeCube() {
    cubelets = List.generate(
      3,
      (x) => List.generate(
        3,
        (y) => List.generate(3, (z) => Cubelet(x: x, y: y, z: z)),
      ),
    );

    // Gán màu cho các mặt của cube
    _assignColors();
  }

  void _assignColors() {
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          final cubelet = cubelets[x][y][z];

          // Gán màu cho các mặt bên ngoài
          if (x == 0) cubelet.setFaceColor('left', CubeColor.orange);
          if (x == 2) cubelet.setFaceColor('right', CubeColor.red);
          if (y == 0) cubelet.setFaceColor('down', CubeColor.yellow);
          if (y == 2) cubelet.setFaceColor('up', CubeColor.white);
          if (z == 0) cubelet.setFaceColor('back', CubeColor.green);
          if (z == 2) cubelet.setFaceColor('front', CubeColor.blue);
        }
      }
    }
  }

  // Xoay cube toàn bộ
  void rotateCube(double deltaX, double deltaY) {
    rotationX += deltaY * 0.01;
    rotationY += deltaX * 0.01;
    notifyListeners();
  }

  // Xoay một mặt của cube
  void rotateFace(String face, bool clockwise) {
    final direction = clockwise ? 1.0 : -1.0;

    switch (face) {
      case 'front':
        _rotateFrontFace(clockwise);
        break;
      case 'back':
        _rotateBackFace(clockwise);
        break;
      case 'left':
        _rotateLeftFace(clockwise);
        break;
      case 'right':
        _rotateRightFace(clockwise);
        break;
      case 'up':
        _rotateUpFace(clockwise);
        break;
      case 'down':
        _rotateDownFace(clockwise);
        break;
    }

    faceRotations[face] = (faceRotations[face]! + direction * 90) % 360;
    notifyListeners();
  }

  void _rotateFrontFace(bool clockwise) {
    // Lưu trạng thái các cubelet trước khi xoay
    List<List<Cubelet>> frontLayer = [];
    for (int x = 0; x < 3; x++) {
      frontLayer.add([]);
      for (int y = 0; y < 3; y++) {
        frontLayer[x].add(cubelets[x][y][2]);
      }
    }

    // Xoay các cubelet trong mặt front
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        if (clockwise) {
          cubelets[x][y][2] = frontLayer[2 - y][x];
        } else {
          cubelets[x][y][2] = frontLayer[y][2 - x];
        }
      }
    }

    _rotateFaceColors('front', clockwise);
  }

  void _rotateBackFace(bool clockwise) {
    List<List<Cubelet>> backLayer = [];
    for (int x = 0; x < 3; x++) {
      backLayer.add([]);
      for (int y = 0; y < 3; y++) {
        backLayer[x].add(cubelets[x][y][0]);
      }
    }

    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        if (clockwise) {
          cubelets[x][y][0] = backLayer[y][2 - x];
        } else {
          cubelets[x][y][0] = backLayer[2 - y][x];
        }
      }
    }

    _rotateFaceColors('back', clockwise);
  }

  void _rotateLeftFace(bool clockwise) {
    List<List<Cubelet>> leftLayer = [];
    for (int y = 0; y < 3; y++) {
      leftLayer.add([]);
      for (int z = 0; z < 3; z++) {
        leftLayer[y].add(cubelets[0][y][z]);
      }
    }

    for (int y = 0; y < 3; y++) {
      for (int z = 0; z < 3; z++) {
        if (clockwise) {
          cubelets[0][y][z] = leftLayer[2 - z][y];
        } else {
          cubelets[0][y][z] = leftLayer[z][2 - y];
        }
      }
    }

    _rotateFaceColors('left', clockwise);
  }

  void _rotateRightFace(bool clockwise) {
    List<List<Cubelet>> rightLayer = [];
    for (int y = 0; y < 3; y++) {
      rightLayer.add([]);
      for (int z = 0; z < 3; z++) {
        rightLayer[y].add(cubelets[2][y][z]);
      }
    }

    for (int y = 0; y < 3; y++) {
      for (int z = 0; z < 3; z++) {
        if (clockwise) {
          cubelets[2][y][z] = rightLayer[z][2 - y];
        } else {
          cubelets[2][y][z] = rightLayer[2 - z][y];
        }
      }
    }

    _rotateFaceColors('right', clockwise);
  }

  void _rotateUpFace(bool clockwise) {
    List<List<Cubelet>> upLayer = [];
    for (int x = 0; x < 3; x++) {
      upLayer.add([]);
      for (int z = 0; z < 3; z++) {
        upLayer[x].add(cubelets[x][2][z]);
      }
    }

    for (int x = 0; x < 3; x++) {
      for (int z = 0; z < 3; z++) {
        if (clockwise) {
          cubelets[x][2][z] = upLayer[2 - z][x];
        } else {
          cubelets[x][2][z] = upLayer[z][2 - x];
        }
      }
    }

    _rotateFaceColors('up', clockwise);
  }

  void _rotateDownFace(bool clockwise) {
    List<List<Cubelet>> downLayer = [];
    for (int x = 0; x < 3; x++) {
      downLayer.add([]);
      for (int z = 0; z < 3; z++) {
        downLayer[x].add(cubelets[x][0][z]);
      }
    }

    for (int x = 0; x < 3; x++) {
      for (int z = 0; z < 3; z++) {
        if (clockwise) {
          cubelets[x][0][z] = downLayer[z][2 - x];
        } else {
          cubelets[x][0][z] = downLayer[2 - z][x];
        }
      }
    }

    _rotateFaceColors('down', clockwise);
  }

  void _rotateFaceColors(String face, bool clockwise) {
    // Logic để xoay màu các mặt khi xoay face
    // Đây là phần phức tạp nhất của Rubik cube
    // Sẽ cần implement logic cụ thể cho từng face
  }

  // Shuffle cube (trộn ngẫu nhiên)
  void shuffle({int moves = 20}) {
    final faces = ['front', 'back', 'left', 'right', 'up', 'down'];
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < moves; i++) {
      final face = faces[random % faces.length];
      final clockwise = (random + i) % 2 == 0;
      rotateFace(face, clockwise);
    }
  }

  // Reset cube về trạng thái ban đầu
  void reset() {
    rotationX = 0.0;
    rotationY = 0.0;
    rotationZ = 0.0;

    faceRotations = {
      'front': 0.0,
      'back': 0.0,
      'left': 0.0,
      'right': 0.0,
      'up': 0.0,
      'down': 0.0,
    };

    _initializeCube();
    notifyListeners();
  }

  // Kiểm tra cube đã được giải chưa
  bool isSolved() {
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          final cubelet = cubelets[x][y][z];

          // Kiểm tra tính nhất quán của màu trên từng mặt
          if (x == 0) {
            if (cubelet.getFaceColor('left') != CubeColor.orange) return false;
          }
          if (x == 2) {
            if (cubelet.getFaceColor('right') != CubeColor.red) return false;
          }
          if (y == 0) {
            if (cubelet.getFaceColor('down') != CubeColor.yellow) return false;
          }
          if (y == 2) {
            if (cubelet.getFaceColor('up') != CubeColor.white) return false;
          }
          if (z == 0) {
            if (cubelet.getFaceColor('back') != CubeColor.green) return false;
          }
          if (z == 2) {
            if (cubelet.getFaceColor('front') != CubeColor.blue) return false;
          }
        }
      }
    }
    return true;
  }
}
