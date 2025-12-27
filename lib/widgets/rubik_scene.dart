import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'dart:math' as math;

/// Widget quản lý 3D Rubik's Cube scene
class RubikScene extends StatefulWidget {
  final Function(Scene) onSceneCreated;
  final Function(ScaleStartDetails) onScaleStart;
  final Function(ScaleUpdateDetails) onScaleUpdate;
  final Function(ScaleEndDetails) onScaleEnd;
  // Callbacks cho pan gesture (để xoay Rubik)
  final Function(DragStartDetails, Size)? onPanStart;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;

  const RubikScene({
    Key? key,
    required this.onSceneCreated,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  }) : super(key: key);

  @override
  State<RubikScene> createState() => _RubikSceneState();
}

class _RubikSceneState extends State<RubikScene> {
  Scene? _scene;
  int _pointerCount = 0; // Theo dõi số lượng pointer

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        // Chỉ dùng onScale* và phân biệt single touch (pan) vs multi-touch (scale)
        // Flutter không cho phép dùng cả onPan* và onScale* cùng lúc
        // 
        // QUAN TRỌNG: Logic xoay camera (xoay xung quanh Rubik) vẫn được giữ nguyên!
        // - 2 ngón tay trở lên = scale gesture = xoay camera xung quanh Rubik
        // - 1 ngón tay = pan gesture = xoay Rubik
        // Dùng Listener để theo dõi số lượng pointer chính xác
        return Listener(
          onPointerDown: (event) {
            // Lưu số lượng pointer để phân biệt single touch vs multi-touch
            _pointerCount = event.pointer;
          },
          child: GestureDetector(
            onScaleStart: (details) {
              // Nếu có 2 ngón tay trở lên = scale gesture = xoay camera xung quanh Rubik
              // Logic này vẫn được giữ nguyên, không thay đổi
              if (details.pointerCount >= 2) {
                widget.onScaleStart(details);
              } else if (widget.onPanStart != null) {
                // Single touch = pan gesture = xoay Rubik
                // Không cần kiểm tra pointerCount == 1, vì nếu không >= 2 thì là single touch
                // Convert ScaleStartDetails sang DragStartDetails
                final dragDetails = DragStartDetails(
                  globalPosition: details.focalPoint,
                  localPosition: details.localFocalPoint,
                );
                widget.onPanStart!(dragDetails, screenSize);
              }
            },
            onScaleUpdate: (details) {
              // Nếu có 2 ngón tay trở lên = scale gesture = xoay camera xung quanh Rubik
              // Logic này vẫn được giữ nguyên, không thay đổi
              if (details.pointerCount >= 2) {
                widget.onScaleUpdate(details);
              } else if (widget.onPanUpdate != null) {
                // Single touch = pan gesture = xoay Rubik
                // Không cần kiểm tra pointerCount == 1, vì nếu không >= 2 thì là single touch
                // Convert ScaleUpdateDetails sang DragUpdateDetails
                final dragDetails = DragUpdateDetails(
                  globalPosition: details.focalPoint,
                  localPosition: details.localFocalPoint,
                  delta: details.focalPointDelta,
                );
                widget.onPanUpdate!(dragDetails);
              }
            },
            onScaleEnd: (details) {
              // Nếu có 2 ngón tay trở lên = scale gesture = xoay camera xung quanh Rubik
              // Logic này vẫn được giữ nguyên, không thay đổi
              if (details.pointerCount >= 2) {
                widget.onScaleEnd(details);
              } else if (widget.onPanEnd != null) {
                // Single touch = pan gesture = xoay Rubik
                // Không cần kiểm tra pointerCount == 1, vì nếu không >= 2 thì là single touch
                // Convert ScaleEndDetails sang DragEndDetails
                final dragDetails = DragEndDetails(
                  velocity: Velocity.zero,
                );
                widget.onPanEnd!(dragDetails);
              }
            },
            // Thêm behavior để đảm bảo gesture được nhận diện
            behavior: HitTestBehavior.opaque,
            child: Cube(
              onSceneCreated: (Scene scene) {
                _scene = scene;
                widget.onSceneCreated(scene);
              },
              interactive: false,
            ),
          ),
        );
      },
    );
  }
}

/// Helper class để tạo cube geometry
class CubeGeometryHelper {
  /// Tạo vertices cho cube
  static List<Vector3> createCubeVertices() {
    return [
      // Front face (z+)
      Vector3(-1, -1, 1),
      Vector3(1, -1, 1),
      Vector3(1, 1, 1),
      Vector3(-1, 1, 1),
      // Back face (z-)
      Vector3(-1, -1, -1),
      Vector3(-1, 1, -1),
      Vector3(1, 1, -1),
      Vector3(1, -1, -1),
      // Top face (y+)
      Vector3(-1, 1, -1),
      Vector3(-1, 1, 1),
      Vector3(1, 1, 1),
      Vector3(1, 1, -1),
      // Bottom face (y-)
      Vector3(-1, -1, -1),
      Vector3(1, -1, -1),
      Vector3(1, -1, 1),
      Vector3(-1, -1, 1),
      // Right face (x+)
      Vector3(1, -1, -1),
      Vector3(1, 1, -1),
      Vector3(1, 1, 1),
      Vector3(1, -1, 1),
      // Left face (x-)
      Vector3(-1, -1, -1),
      Vector3(-1, -1, 1),
      Vector3(-1, 1, 1),
      Vector3(-1, 1, -1),
    ];
  }

  /// Tạo texture coordinates
  static List<Offset> createCubeTexcoords() {
    List<Offset> texcoords = [];
    for (int i = 0; i < 6; i++) {
      texcoords.addAll([
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ]);
    }
    return texcoords;
  }

  /// Tạo indices cho các tam giác
  static List<Polygon> createCubeIndices() {
    List<Polygon> polygons = [];
    for (int i = 0; i < 6; i++) {
      int offset = i * 4;
      polygons.add(Polygon(offset, offset + 1, offset + 2));
      polygons.add(Polygon(offset, offset + 2, offset + 3));
    }
    return polygons;
  }

  /// Tạo danh sách 24 màu từ 6 màu mặt
  static List<Color> createColorsFromFaces(List<Color> faceColors) {
    List<Color> colors = [];
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 4; j++) {
        colors.add(faceColors[i]);
      }
    }
    return colors;
  }

  /// Lấy màu ban đầu cho cube tại vị trí (x, y, z)
  static List<Color> getInitialCubeColors(int x, int y, int z) {
    final grey = Colors.grey[900]!;
    return [
      z == 2 ? Colors.white : grey, // front
      z == 0 ? Colors.yellow : grey, // back
      y == 2 ? Colors.red : grey, // top
      y == 0 ? Colors.orange : grey, // bottom
      x == 2 ? Colors.blue : grey, // right
      x == 0 ? Colors.green : grey, // left
    ];
  }
}

/// Helper class để quản lý camera
class CameraController {
  double distance = 25.0;
  double angleX = 0.3;
  double angleY = 0.7;

  void updateCameraPosition(Scene scene) {
    final x = distance * math.cos(angleX) * math.sin(angleY);
    final y = distance * math.sin(angleX);
    final z = distance * math.cos(angleX) * math.cos(angleY);

    scene.camera.position.setValues(x, y, z);
    scene.camera.target.setValues(0, 0, 0);
  }

  void updateFromPan(Offset delta) {
    angleY += delta.dx * 0.01;
    angleX += delta.dy * 0.01;
    angleX = angleX.clamp(-math.pi / 2 + 0.1, math.pi / 2 - 0.1);
  }

  void updateFromScale(double scale) {
    final scaleFactor = scale > 1.0 ? 0.95 : 1.05;
    distance *= scaleFactor;
    distance = distance.clamp(10.0, 50.0);
  }
}

