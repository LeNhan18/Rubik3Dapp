import 'package:flutter/material.dart';
import '../models/rubik_cube.dart';
import 'cube_color_picker.dart';

/// Widget hiển thị Rubik's Cube dạng "net" (unfolded) - 2D view
class CubeNetView extends StatelessWidget {
  final Map<String, List<List<CubeColor?>>> cubeState;
  final Function(String face, int row, int col, CubeColor color) onColorChanged;

  const CubeNetView({
    Key? key,
    required this.cubeState,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top face (U) - ở trên cùng
              _buildFace(context, 'up', 'Mặt Trên (U)'),
              const SizedBox(height: 6),
              
              // Middle row: Left, Front, Right, Back
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFace(context, 'left', 'Mặt Trái (L)'),
                  const SizedBox(width: 6),
                  _buildFace(context, 'front', 'Mặt Trước (F)'),
                  const SizedBox(width: 6),
                  _buildFace(context, 'right', 'Mặt Phải (R)'),
                  const SizedBox(width: 6),
                  _buildFace(context, 'back', 'Mặt Sau (B)'),
                ],
              ),
              
              const SizedBox(height: 6),
              // Bottom face (D) - ở dưới cùng
              _buildFace(context, 'down', 'Mặt Dưới (D)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFace(BuildContext context, String faceName, String displayName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (col) {
                return Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: CubeColorPicker(
                    selectedColor: cubeState[faceName]?[row][col],
                    onColorSelected: (color) {
                      onColorChanged(faceName, row, col, color);
                    },
                    size: 28,
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }
}

