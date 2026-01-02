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
    // Xoay màu các mặt phụ khi xoay một mặt
    // Ví dụ: Xoay mặt Front (F) sẽ ảnh hưởng đến Up, Right, Down, Left

    switch (face) {
      case 'front':
        _rotateFrontFaceColors(clockwise);
        break;
      case 'back':
        _rotateBackFaceColors(clockwise);
        break;
      case 'left':
        _rotateLeftFaceColors(clockwise);
        break;
      case 'right':
        _rotateRightFaceColors(clockwise);
        break;
      case 'up':
        _rotateUpFaceColors(clockwise);
        break;
      case 'down':
        _rotateDownFaceColors(clockwise);
        break;
    }
  }

  void _rotateFrontFaceColors(bool clockwise) {
    // Front xoay ảnh hưởng đến Up, Right, Down, Left edges
    // Lưu các edge stickers theo thứ tự (left to right, top to bottom)
    List<CubeColor?> upEdge = [];
    List<CubeColor?> rightEdge = [];
    List<CubeColor?> downEdge = [];
    List<CubeColor?> leftEdge = [];

    // Lấy colors từ 4 edges xung quanh front face (z=2)
    for (int i = 0; i < 3; i++) {
      upEdge.add(cubelets[i][2][2].getFaceColor('up')); // row y=2
      rightEdge.add(cubelets[2][2 - i][2].getFaceColor('right')); // col x=2
      downEdge.add(cubelets[2 - i][0][2].getFaceColor('down')); // row y=0
      leftEdge.add(cubelets[0][i][2].getFaceColor('left')); // col x=0
    }

    if (clockwise) {
      // Rotation: Up -> Right -> Down -> Left -> Up
      for (int i = 0; i < 3; i++) {
        final upColor = upEdge[i] ?? CubeColor.white;
        final rightColor = rightEdge[i] ?? CubeColor.red;
        final downColor = downEdge[i] ?? CubeColor.yellow;
        final leftColor = leftEdge[i] ?? CubeColor.orange;
        cubelets[2][2 - i][2].setFaceColor('right', upColor);
        cubelets[2 - i][0][2].setFaceColor('down', rightColor);
        cubelets[0][2 - i][2].setFaceColor('left', downColor);
        cubelets[i][2][2].setFaceColor('up', leftColor);
      }
    } else {
      // Rotation: Up -> Left -> Down -> Right -> Up
      for (int i = 0; i < 3; i++) {
        final upColor = upEdge[i] ?? CubeColor.white;
        final leftColor = leftEdge[i] ?? CubeColor.orange;
        final downColor = downEdge[i] ?? CubeColor.yellow;
        final rightColor = rightEdge[i] ?? CubeColor.red;
        cubelets[0][2 - i][2].setFaceColor('left', upColor);
        cubelets[2 - i][0][2].setFaceColor('down', leftColor);
        cubelets[2][2 - i][2].setFaceColor('right', downColor);
        cubelets[2 - i][2][2].setFaceColor('up', rightColor);
      }
    }
  }

  void _rotateBackFaceColors(bool clockwise) {
    // Back face is at z=0
    // Top row: (0,2,0), (1,2,0), (2,2,0) - connected to Up face
    // Bottom row: (0,0,0), (1,0,0), (2,0,0) - connected to Down face
    // Left col: (0,0,0), (0,1,0), (0,2,0) - connected to Left face
    // Right col: (2,0,0), (2,1,0), (2,2,0) - connected to Right face

    if (clockwise) {
      // Back clockwise (looking at back face)
      // Up → Right → Down → Left → Up
      final upTop = [
        cubelets[2][2][0].getFaceColor('up') ?? CubeColor.white,
        cubelets[1][2][0].getFaceColor('up') ?? CubeColor.white,
        cubelets[0][2][0].getFaceColor('up') ?? CubeColor.white,
      ];
      final rightBack = [
        cubelets[2][2][0].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][1][0].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][0][0].getFaceColor('right') ?? CubeColor.red,
      ];
      final downBottom = [
        cubelets[0][0][0].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[1][0][0].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[2][0][0].getFaceColor('down') ?? CubeColor.yellow,
      ];
      final leftBack = [
        cubelets[0][0][0].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][1][0].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][2][0].getFaceColor('left') ?? CubeColor.orange,
      ];

      // Up → Right
      cubelets[2][2][0].setFaceColor('right', upTop[0]);
      cubelets[2][1][0].setFaceColor('right', upTop[1]);
      cubelets[2][0][0].setFaceColor('right', upTop[2]);

      // Right → Down
      cubelets[0][0][0].setFaceColor('down', rightBack[0]);
      cubelets[1][0][0].setFaceColor('down', rightBack[1]);
      cubelets[2][0][0].setFaceColor('down', rightBack[2]);

      // Down → Left
      cubelets[0][0][0].setFaceColor('left', downBottom[2]);
      cubelets[0][1][0].setFaceColor('left', downBottom[1]);
      cubelets[0][2][0].setFaceColor('left', downBottom[0]);

      // Left → Up
      cubelets[0][2][0].setFaceColor('up', leftBack[2]);
      cubelets[1][2][0].setFaceColor('up', leftBack[1]);
      cubelets[2][2][0].setFaceColor('up', leftBack[0]);
    } else {
      // Back counter-clockwise: Up ← Right ← Down ← Left ← Up
      final rightBack = [
        cubelets[2][2][0].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][1][0].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][0][0].getFaceColor('right') ?? CubeColor.red,
      ];
      final downBottom = [
        cubelets[0][0][0].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[1][0][0].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[2][0][0].getFaceColor('down') ?? CubeColor.yellow,
      ];
      final leftBack = [
        cubelets[0][0][0].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][1][0].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][2][0].getFaceColor('left') ?? CubeColor.orange,
      ];

      // Left → Up
      cubelets[0][2][0].setFaceColor('up', leftBack[0]);
      cubelets[1][2][0].setFaceColor('up', leftBack[1]);
      cubelets[2][2][0].setFaceColor('up', leftBack[2]);

      // Up → Right
      cubelets[2][2][0].setFaceColor('right', downBottom[0]);
      cubelets[2][1][0].setFaceColor('right', downBottom[1]);
      cubelets[2][0][0].setFaceColor('right', downBottom[2]);

      // Right → Down
      cubelets[0][0][0].setFaceColor('down', leftBack[2]);
      cubelets[1][0][0].setFaceColor('down', leftBack[1]);
      cubelets[2][0][0].setFaceColor('down', leftBack[0]);

      // Down → Left
      cubelets[0][0][0].setFaceColor('left', rightBack[2]);
      cubelets[0][1][0].setFaceColor('left', rightBack[1]);
      cubelets[0][2][0].setFaceColor('left', rightBack[0]);
    }
  }

  void _rotateLeftFaceColors(bool clockwise) {
    // Left face is at x=0
    // Front col: (0,0,2), (0,1,2), (0,2,2) - connected to Front face
    // Back col: (0,0,0), (0,1,0), (0,2,0) - connected to Back face
    // Top row: (0,2,0), (0,2,1), (0,2,2) - connected to Up face
    // Bottom row: (0,0,0), (0,0,1), (0,0,2) - connected to Down face

    if (clockwise) {
      // Left clockwise (looking at left face)
      // Front → Up → Back → Down → Front
      final frontCol = [
        cubelets[0][0][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[0][1][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[0][2][2].getFaceColor('front') ?? CubeColor.blue,
      ];
      final upRow = [
        cubelets[0][2][0].getFaceColor('up') ?? CubeColor.white,
        cubelets[0][2][1].getFaceColor('up') ?? CubeColor.white,
        cubelets[0][2][2].getFaceColor('up') ?? CubeColor.white,
      ];
      final backCol = [
        cubelets[0][2][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[0][1][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[0][0][0].getFaceColor('back') ?? CubeColor.green,
      ];
      final downRow = [
        cubelets[0][0][2].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[0][0][1].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[0][0][0].getFaceColor('down') ?? CubeColor.yellow,
      ];

      // Front → Up
      cubelets[0][2][0].setFaceColor('up', frontCol[0]);
      cubelets[0][2][1].setFaceColor('up', frontCol[1]);
      cubelets[0][2][2].setFaceColor('up', frontCol[2]);

      // Up → Back
      cubelets[0][2][0].setFaceColor('back', upRow[2]);
      cubelets[0][1][0].setFaceColor('back', upRow[1]);
      cubelets[0][0][0].setFaceColor('back', upRow[0]);

      // Back → Down
      cubelets[0][0][0].setFaceColor('down', backCol[0]);
      cubelets[0][0][1].setFaceColor('down', backCol[1]);
      cubelets[0][0][2].setFaceColor('down', backCol[2]);

      // Down → Front
      cubelets[0][0][2].setFaceColor('front', downRow[0]);
      cubelets[0][1][2].setFaceColor('front', downRow[1]);
      cubelets[0][2][2].setFaceColor('front', downRow[2]);
    } else {
      // Left counter-clockwise: Front ← Up ← Back ← Down ← Front
      final frontCol = [
        cubelets[0][0][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[0][1][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[0][2][2].getFaceColor('front') ?? CubeColor.blue,
      ];
      final upRow = [
        cubelets[0][2][0].getFaceColor('up') ?? CubeColor.white,
        cubelets[0][2][1].getFaceColor('up') ?? CubeColor.white,
        cubelets[0][2][2].getFaceColor('up') ?? CubeColor.white,
      ];
      final backCol = [
        cubelets[0][2][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[0][1][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[0][0][0].getFaceColor('back') ?? CubeColor.green,
      ];
      final downRow = [
        cubelets[0][0][2].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[0][0][1].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[0][0][0].getFaceColor('down') ?? CubeColor.yellow,
      ];

      // Down → Front
      cubelets[0][0][2].setFaceColor('front', downRow[2]);
      cubelets[0][1][2].setFaceColor('front', downRow[1]);
      cubelets[0][2][2].setFaceColor('front', downRow[0]);

      // Front → Up
      cubelets[0][2][0].setFaceColor('up', frontCol[2]);
      cubelets[0][2][1].setFaceColor('up', frontCol[1]);
      cubelets[0][2][2].setFaceColor('up', frontCol[0]);

      // Up → Back
      cubelets[0][0][0].setFaceColor('back', upRow[0]);
      cubelets[0][1][0].setFaceColor('back', upRow[1]);
      cubelets[0][2][0].setFaceColor('back', upRow[2]);

      // Back → Down
      cubelets[0][0][0].setFaceColor('down', backCol[2]);
      cubelets[0][0][1].setFaceColor('down', backCol[1]);
      cubelets[0][0][2].setFaceColor('down', backCol[0]);
    }
  }

  void _rotateRightFaceColors(bool clockwise) {
    // Right face is at x=2
    // Front col: (2,0,2), (2,1,2), (2,2,2) - connected to Front face
    // Back col: (2,0,0), (2,1,0), (2,2,0) - connected to Back face
    // Top row: (2,2,0), (2,2,1), (2,2,2) - connected to Up face
    // Bottom row: (2,0,0), (2,0,1), (2,0,2) - connected to Down face

    if (clockwise) {
      // Right clockwise (looking at right face)
      // Front → Down → Back → Up → Front
      final frontCol = [
        cubelets[2][0][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[2][1][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[2][2][2].getFaceColor('front') ?? CubeColor.blue,
      ];
      final downRow = [
        cubelets[2][0][2].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[2][0][1].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[2][0][0].getFaceColor('down') ?? CubeColor.yellow,
      ];
      final backCol = [
        cubelets[2][2][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[2][1][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[2][0][0].getFaceColor('back') ?? CubeColor.green,
      ];
      final upRow = [
        cubelets[2][2][0].getFaceColor('up') ?? CubeColor.white,
        cubelets[2][2][1].getFaceColor('up') ?? CubeColor.white,
        cubelets[2][2][2].getFaceColor('up') ?? CubeColor.white,
      ];

      // Front → Down
      cubelets[2][0][2].setFaceColor('down', frontCol[0]);
      cubelets[2][0][1].setFaceColor('down', frontCol[1]);
      cubelets[2][0][0].setFaceColor('down', frontCol[2]);

      // Down → Back
      cubelets[2][2][0].setFaceColor('back', downRow[0]);
      cubelets[2][1][0].setFaceColor('back', downRow[1]);
      cubelets[2][0][0].setFaceColor('back', downRow[2]);

      // Back → Up
      cubelets[2][2][0].setFaceColor('up', backCol[2]);
      cubelets[2][2][1].setFaceColor('up', backCol[1]);
      cubelets[2][2][2].setFaceColor('up', backCol[0]);

      // Up → Front
      cubelets[2][0][2].setFaceColor('front', upRow[2]);
      cubelets[2][1][2].setFaceColor('front', upRow[1]);
      cubelets[2][2][2].setFaceColor('front', upRow[0]);
    } else {
      // Right counter-clockwise: Front ← Down ← Back ← Up ← Front
      final frontCol = [
        cubelets[2][0][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[2][1][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[2][2][2].getFaceColor('front') ?? CubeColor.blue,
      ];
      final downRow = [
        cubelets[2][0][2].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[2][0][1].getFaceColor('down') ?? CubeColor.yellow,
        cubelets[2][0][0].getFaceColor('down') ?? CubeColor.yellow,
      ];
      final backCol = [
        cubelets[2][2][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[2][1][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[2][0][0].getFaceColor('back') ?? CubeColor.green,
      ];
      final upRow = [
        cubelets[2][2][0].getFaceColor('up') ?? CubeColor.white,
        cubelets[2][2][1].getFaceColor('up') ?? CubeColor.white,
        cubelets[2][2][2].getFaceColor('up') ?? CubeColor.white,
      ];

      // Up → Front
      cubelets[2][0][2].setFaceColor('front', upRow[0]);
      cubelets[2][1][2].setFaceColor('front', upRow[1]);
      cubelets[2][2][2].setFaceColor('front', upRow[2]);

      // Front → Down
      cubelets[2][0][2].setFaceColor('down', frontCol[2]);
      cubelets[2][0][1].setFaceColor('down', frontCol[1]);
      cubelets[2][0][0].setFaceColor('down', frontCol[0]);

      // Down → Back
      cubelets[2][2][0].setFaceColor('back', downRow[2]);
      cubelets[2][1][0].setFaceColor('back', downRow[1]);
      cubelets[2][0][0].setFaceColor('back', downRow[0]);

      // Back → Up
      cubelets[2][2][0].setFaceColor('up', backCol[0]);
      cubelets[2][2][1].setFaceColor('up', backCol[1]);
      cubelets[2][2][2].setFaceColor('up', backCol[2]);
    }
  }

  void _rotateUpFaceColors(bool clockwise) {
    // Up face is at y=2
    // Front row: (0,2,2), (1,2,2), (2,2,2) - connected to Front face
    // Left row: (0,2,0), (0,2,1), (0,2,2) - connected to Left face
    // Back row: (0,2,0), (1,2,0), (2,2,0) - connected to Back face
    // Right row: (2,2,0), (2,2,1), (2,2,2) - connected to Right face

    if (clockwise) {
      // Up clockwise (looking from top)
      // Front → Left → Back → Right → Front
      final frontRow = [
        cubelets[0][2][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[1][2][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[2][2][2].getFaceColor('front') ?? CubeColor.blue,
      ];
      final leftRow = [
        cubelets[0][2][0].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][2][1].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][2][2].getFaceColor('left') ?? CubeColor.orange,
      ];
      final backRow = [
        cubelets[2][2][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[1][2][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[0][2][0].getFaceColor('back') ?? CubeColor.green,
      ];
      final rightRow = [
        cubelets[2][2][0].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][2][1].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][2][2].getFaceColor('right') ?? CubeColor.red,
      ];

      // Front → Left
      cubelets[0][2][0].setFaceColor('left', frontRow[0]);
      cubelets[0][2][1].setFaceColor('left', frontRow[1]);
      cubelets[0][2][2].setFaceColor('left', frontRow[2]);

      // Left → Back
      cubelets[2][2][0].setFaceColor('back', leftRow[0]);
      cubelets[1][2][0].setFaceColor('back', leftRow[1]);
      cubelets[0][2][0].setFaceColor('back', leftRow[2]);

      // Back → Right
      cubelets[2][2][0].setFaceColor('right', backRow[2]);
      cubelets[2][2][1].setFaceColor('right', backRow[1]);
      cubelets[2][2][2].setFaceColor('right', backRow[0]);

      // Right → Front
      cubelets[0][2][2].setFaceColor('front', rightRow[2]);
      cubelets[1][2][2].setFaceColor('front', rightRow[1]);
      cubelets[2][2][2].setFaceColor('front', rightRow[0]);
    } else {
      // Up counter-clockwise: Front ← Left ← Back ← Right ← Front
      final frontRow = [
        cubelets[0][2][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[1][2][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[2][2][2].getFaceColor('front') ?? CubeColor.blue,
      ];
      final leftRow = [
        cubelets[0][2][0].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][2][1].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][2][2].getFaceColor('left') ?? CubeColor.orange,
      ];
      final backRow = [
        cubelets[2][2][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[1][2][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[0][2][0].getFaceColor('back') ?? CubeColor.green,
      ];
      final rightRow = [
        cubelets[2][2][0].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][2][1].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][2][2].getFaceColor('right') ?? CubeColor.red,
      ];

      // Right → Front
      cubelets[0][2][2].setFaceColor('front', rightRow[0]);
      cubelets[1][2][2].setFaceColor('front', rightRow[1]);
      cubelets[2][2][2].setFaceColor('front', rightRow[2]);

      // Front → Left
      cubelets[0][2][2].setFaceColor('left', frontRow[2]);
      cubelets[0][2][1].setFaceColor('left', frontRow[1]);
      cubelets[0][2][0].setFaceColor('left', frontRow[0]);

      // Left → Back
      cubelets[0][2][0].setFaceColor('back', leftRow[0]);
      cubelets[1][2][0].setFaceColor('back', leftRow[1]);
      cubelets[2][2][0].setFaceColor('back', leftRow[2]);

      // Back → Right
      cubelets[2][2][2].setFaceColor('right', backRow[0]);
      cubelets[2][2][1].setFaceColor('right', backRow[1]);
      cubelets[2][2][0].setFaceColor('right', backRow[2]);
    }
  }

  void _rotateDownFaceColors(bool clockwise) {
    // Down face is at y=0
    // Front row: (0,0,2), (1,0,2), (2,0,2) - connected to Front face
    // Left row: (0,0,0), (0,0,1), (0,0,2) - connected to Left face
    // Back row: (0,0,0), (1,0,0), (2,0,0) - connected to Back face
    // Right row: (2,0,0), (2,0,1), (2,0,2) - connected to Right face

    if (clockwise) {
      // Down clockwise (looking from bottom)
      // Front → Right → Back → Left → Front
      final frontRow = [
        cubelets[0][0][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[1][0][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[2][0][2].getFaceColor('front') ?? CubeColor.blue,
      ];
      final rightRow = [
        cubelets[2][0][0].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][0][1].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][0][2].getFaceColor('right') ?? CubeColor.red,
      ];
      final backRow = [
        cubelets[2][0][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[1][0][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[0][0][0].getFaceColor('back') ?? CubeColor.green,
      ];
      final leftRow = [
        cubelets[0][0][0].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][0][1].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][0][2].getFaceColor('left') ?? CubeColor.orange,
      ];

      // Front → Right
      cubelets[2][0][0].setFaceColor('right', frontRow[0]);
      cubelets[2][0][1].setFaceColor('right', frontRow[1]);
      cubelets[2][0][2].setFaceColor('right', frontRow[2]);

      // Right → Back
      cubelets[2][0][0].setFaceColor('back', rightRow[2]);
      cubelets[1][0][0].setFaceColor('back', rightRow[1]);
      cubelets[0][0][0].setFaceColor('back', rightRow[0]);

      // Back → Left
      cubelets[0][0][0].setFaceColor('left', backRow[0]);
      cubelets[0][0][1].setFaceColor('left', backRow[1]);
      cubelets[0][0][2].setFaceColor('left', backRow[2]);

      // Left → Front
      cubelets[0][0][2].setFaceColor('front', leftRow[2]);
      cubelets[1][0][2].setFaceColor('front', leftRow[1]);
      cubelets[2][0][2].setFaceColor('front', leftRow[0]);
    } else {
      // Down counter-clockwise: Front ← Right ← Back ← Left ← Front
      final frontRow = [
        cubelets[0][0][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[1][0][2].getFaceColor('front') ?? CubeColor.blue,
        cubelets[2][0][2].getFaceColor('front') ?? CubeColor.blue,
      ];
      final rightRow = [
        cubelets[2][0][0].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][0][1].getFaceColor('right') ?? CubeColor.red,
        cubelets[2][0][2].getFaceColor('right') ?? CubeColor.red,
      ];
      final backRow = [
        cubelets[2][0][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[1][0][0].getFaceColor('back') ?? CubeColor.green,
        cubelets[0][0][0].getFaceColor('back') ?? CubeColor.green,
      ];
      final leftRow = [
        cubelets[0][0][0].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][0][1].getFaceColor('left') ?? CubeColor.orange,
        cubelets[0][0][2].getFaceColor('left') ?? CubeColor.orange,
      ];

      // Left → Front
      cubelets[0][0][2].setFaceColor('front', leftRow[0]);
      cubelets[1][0][2].setFaceColor('front', leftRow[1]);
      cubelets[2][0][2].setFaceColor('front', leftRow[2]);

      // Front → Right
      cubelets[2][0][0].setFaceColor('right', frontRow[2]);
      cubelets[2][0][1].setFaceColor('right', frontRow[1]);
      cubelets[2][0][2].setFaceColor('right', frontRow[0]);

      // Right → Back
      cubelets[0][0][0].setFaceColor('back', rightRow[0]);
      cubelets[1][0][0].setFaceColor('back', rightRow[1]);
      cubelets[2][0][0].setFaceColor('back', rightRow[2]);

      // Back → Left
      cubelets[0][0][0].setFaceColor('left', backRow[2]);
      cubelets[0][0][1].setFaceColor('left', backRow[1]);
      cubelets[0][0][2].setFaceColor('left', backRow[0]);
    }
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
