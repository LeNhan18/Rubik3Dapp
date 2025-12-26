import 'package:flutter/material.dart';
import '../models/rubik_cube.dart';

/// Widget để chọn màu cho một sticker của cube
class CubeColorPicker extends StatelessWidget {
  final CubeColor? selectedColor;
  final Function(CubeColor) onColorSelected;
  final double size;

  const CubeColorPicker({
    Key? key,
    this.selectedColor,
    required this.onColorSelected,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selectedColor != null
              ? _getColor(selectedColor!)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: selectedColor == null
            ? Icon(Icons.add, size: size * 0.5, color: Colors.grey[600])
            : null,
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn màu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: CubeColor.values.map((color) {
                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getColor(color),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedColor == color
                            ? Colors.black
                            : Colors.grey[400]!,
                        width: selectedColor == color ? 3 : 1,
                      ),
                    ),
                    child: selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getColor(CubeColor color) {
    switch (color) {
      case CubeColor.white:
        return const Color(0xFFFFFFF0);
      case CubeColor.red:
        return const Color(0xFFB71C1C);
      case CubeColor.blue:
        return const Color(0xFF0D47A1);
      case CubeColor.orange:
        return const Color(0xFFFF6F00);
      case CubeColor.green:
        return const Color(0xFF2E7D32);
      case CubeColor.yellow:
        return const Color(0xFFFDD835);
    }
  }
}

/// Widget để hiển thị một mặt của cube (3x3 grid)
class CubeFaceEditor extends StatelessWidget {
  final String faceName;
  final List<List<CubeColor?>> faceColors; // 3x3 grid
  final Function(int row, int col, CubeColor color) onColorChanged;

  const CubeFaceEditor({
    Key? key,
    required this.faceName,
    required this.faceColors,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Giảm thêm padding
        child: Column(
          mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
          children: [
            Text(
              _getFaceDisplayName(faceName),
              style: Theme.of(context).textTheme.bodySmall?.copyWith( // Giảm từ bodyMedium
                    fontWeight: FontWeight.bold,
                    fontSize: 11, // Giảm font size thêm
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4), // Giảm từ 6
            ...List.generate(3, (row) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
                children: List.generate(3, (col) {
                  return Padding(
                    padding: const EdgeInsets.all(0.5), // Giảm từ 1
                    child: CubeColorPicker(
                      selectedColor: faceColors[row][col],
                      onColorSelected: (color) {
                        onColorChanged(row, col, color);
                      },
                      size: 24, // Giảm từ 26
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getFaceDisplayName(String face) {
    switch (face) {
      case 'up':
        return 'Mặt Trên (U)';
      case 'down':
        return 'Mặt Dưới (D)';
      case 'front':
        return 'Mặt Trước (F)';
      case 'back':
        return 'Mặt Sau (B)';
      case 'left':
        return 'Mặt Trái (L)';
      case 'right':
        return 'Mặt Phải (R)';
      default:
        return face;
    }
  }
}

