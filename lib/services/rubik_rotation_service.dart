import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'dart:math' as math;
import '../widgets/rubik_scene.dart';

/// Service xử lý logic xoay các mặt của Rubik's Cube
class RubikRotationService {
  final Scene scene;
  final Map<Object, List<int>> cubeGridPositions;
  final Map<Object, List<Color>> cubeFaceColors;
  final Function() onRotationStateChanged;
  
  AnimationController? _rotationController;
  bool _isRotating = false;

  RubikRotationService({
    required this.scene,
    required this.cubeGridPositions,
    required this.cubeFaceColors,
    required this.onRotationStateChanged,
  });

  bool get isRotating => _isRotating;

  /// Xoay một mặt của cube
  void rotateFace({
    required int axis,
    required int layer,
    required bool clockwise,
    required TickerProvider vsync,
  }) {
    if (_isRotating) return;
    _isRotating = true;
    onRotationStateChanged();

    final cubes = _getCubesForRotation(axis, layer);
    final angle = clockwise ? -math.pi / 2 : math.pi / 2;
    final originalGridPositions = <Object, List<int>>{};

    for (final cube in cubes) {
      originalGridPositions[cube] = List.from(cubeGridPositions[cube]!);
    }

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    );

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rotationController!,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _rotationController!.addListener(() {
      final progress = animation.value;
      final currentAngle = angle * progress;
      final rotationDegrees = currentAngle * 180 / math.pi;

      for (final cube in cubes) {
        final originalGridPos = originalGridPositions[cube]!;
        final tempGridPos = _rotateGridPosition(
          originalGridPos,
          axis,
          currentAngle,
        );

        final targetX = (tempGridPos[0] - 1) * 4.0;
        final targetY = (tempGridPos[1] - 1) * 4.0;
        final targetZ = (tempGridPos[2] - 1) * 4.0;

        cube.position.setFrom(Vector3(targetX, targetY, targetZ));

        final smoothRotation = rotationDegrees;
        if (axis == 0) {
          cube.rotation.setValues(smoothRotation, 0, 0);
        } else if (axis == 1) {
          cube.rotation.setValues(0, smoothRotation, 0);
        } else {
          cube.rotation.setValues(0, 0, smoothRotation);
        }

        cube.updateTransform();
      }

      onRotationStateChanged();
    });

    _rotationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        for (final cube in cubes) {
          cube.rotation.setValues(0, 0, 0);
          cube.updateTransform();
        }

        _updateGridPositionsAfterRotation(cubes, axis, layer, clockwise);
        _rotateFaceColors(cubes, axis, clockwise);

        for (final cube in cubes) {
          final gridPos = cubeGridPositions[cube]!;
          cube.position.setFrom(
            Vector3(
              (gridPos[0] - 1) * 4.0,
              (gridPos[1] - 1) * 4.0,
              (gridPos[2] - 1) * 4.0,
            ),
          );

          final newColors = CubeGeometryHelper.createColorsFromFaces(cubeFaceColors[cube]!);
          cube.mesh.colors = newColors;
          cube.updateTransform();
        }

        _isRotating = false;
        onRotationStateChanged();
        _rotationController?.dispose();
      }
    });
    _rotationController!.forward();
  }

  /// Xoay grid position (dùng cho animation)
  Vector3 _rotateGridPosition(List<int> gridPos, int axis, double angle) {
    final x = (gridPos[0] - 1).toDouble();
    final y = (gridPos[1] - 1).toDouble();
    final z = (gridPos[2] - 1).toDouble();

    final cos = math.cos(angle);
    final sin = math.sin(angle);

    double newX, newY, newZ;

    if (axis == 0) {
      newX = x;
      newY = y * cos - z * sin;
      newZ = y * sin + z * cos;
    } else if (axis == 1) {
      newX = x * cos + z * sin;
      newY = y;
      newZ = -x * sin + z * cos;
    } else {
      newX = x * cos - y * sin;
      newY = x * sin + y * cos;
      newZ = z;
    }

    return Vector3(
      double.parse((newX + 1).toStringAsFixed(6)),
      double.parse((newY + 1).toStringAsFixed(6)),
      double.parse((newZ + 1).toStringAsFixed(6)),
    );
  }

  /// Lấy danh sách các cube cần xoay
  List<Object> _getCubesForRotation(int axis, int layer) {
    List<Object> result = [];

    for (final entry in cubeGridPositions.entries) {
      final cube = entry.key;
      final gridPos = entry.value;

      bool shouldRotate = false;
      if (axis == 0) {
        if (layer == -1) {
          shouldRotate = gridPos[0] == 1;
        } else {
          shouldRotate = gridPos[0] == layer;
        }
      } else if (axis == 1) {
        if (layer == -1) {
          shouldRotate = gridPos[1] == 1;
        } else {
          shouldRotate = gridPos[1] == layer;
        }
      } else if (axis == 2) {
        if (layer == -1) {
          shouldRotate = gridPos[2] == 1;
        } else {
          shouldRotate = gridPos[2] == layer;
        }
      }

      if (shouldRotate) {
        result.add(cube);
      }
    }
    return result;
  }

  /// Cập nhật vị trí grid sau khi xoay
  void _updateGridPositionsAfterRotation(
    List<Object> cubes,
    int axis,
    int layer,
    bool clockwise,
  ) {
    Map<Object, List<int>> newPositions = {};

    for (final cube in cubes) {
      final currentGridPos = cubeGridPositions[cube]!;
      final x = currentGridPos[0];
      final y = currentGridPos[1];
      final z = currentGridPos[2];

      late List<int> newGridPos;

      if (axis == 0) {
        if (clockwise) {
          newGridPos = [x, z, 2 - y];
        } else {
          newGridPos = [x, 2 - z, y];
        }
      } else if (axis == 1) {
        if (clockwise) {
          newGridPos = [2 - z, y, x];
        } else {
          newGridPos = [z, y, 2 - x];
        }
      } else if (axis == 2) {
        if (clockwise) {
          newGridPos = [y, 2 - x, z];
        } else {
          newGridPos = [2 - y, x, z];
        }
      }

      newPositions[cube] = newGridPos;
    }

    newPositions.forEach((cube, pos) {
      cubeGridPositions[cube] = pos;
    });
  }

  /// Xoay màu sắc các mặt của cube
  void _rotateFaceColors(List<Object> cubes, int axis, bool clockwise) {
    for (final cube in cubes) {
      final oldColors = List<Color>.from(cubeFaceColors[cube]!);
      final newColors = List<Color>.filled(6, Colors.black);

      // [front, back, top, bottom, right, left] = [0, 1, 2, 3, 4, 5]
      if (axis == 0) {
        if (clockwise) {
          newColors[0] = oldColors[3];
          newColors[1] = oldColors[2];
          newColors[2] = oldColors[0];
          newColors[3] = oldColors[1];
          newColors[4] = oldColors[4];
          newColors[5] = oldColors[5];
        } else {
          newColors[0] = oldColors[2];
          newColors[1] = oldColors[3];
          newColors[2] = oldColors[1];
          newColors[3] = oldColors[0];
          newColors[4] = oldColors[4];
          newColors[5] = oldColors[5];
        }
      } else if (axis == 1) {
        if (clockwise) {
          newColors[0] = oldColors[4];
          newColors[1] = oldColors[5];
          newColors[4] = oldColors[1];
          newColors[5] = oldColors[0];
          newColors[2] = oldColors[2];
          newColors[3] = oldColors[3];
        } else {
          newColors[0] = oldColors[5];
          newColors[1] = oldColors[4];
          newColors[4] = oldColors[0];
          newColors[5] = oldColors[1];
          newColors[2] = oldColors[2];
          newColors[3] = oldColors[3];
        }
      } else {
        if (clockwise) {
          newColors[2] = oldColors[5];
          newColors[3] = oldColors[4];
          newColors[4] = oldColors[2];
          newColors[5] = oldColors[3];
          newColors[0] = oldColors[0];
          newColors[1] = oldColors[1];
        } else {
          newColors[2] = oldColors[4];
          newColors[3] = oldColors[5];
          newColors[4] = oldColors[3];
          newColors[5] = oldColors[2];
          newColors[0] = oldColors[0];
          newColors[1] = oldColors[1];
        }
      }
      cubeFaceColors[cube] = newColors;
    }
  }

  void dispose() {
    _rotationController?.dispose();
  }
}

