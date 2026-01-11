import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/rubik_cube.dart';
import '../services/cube_scanner_service.dart';
import '../utils/cube_validator.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_button.dart';

class CubeScanScreen extends StatefulWidget {
  const CubeScanScreen({super.key});

  @override
  State<CubeScanScreen> createState() => _CubeScanScreenState();
}

class _CubeScanScreenState extends State<CubeScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  // Trạng thái scan: 6 faces cần scan
  final List<String> _faces = ['up', 'front', 'right', 'back', 'left', 'down'];
  int _currentFaceIndex = 0;
  
  // Kết quả scan: Map<face, 3x3 grid>
  Map<String, List<List<CubeColor?>>> _scannedFaces = {};
  
  // Overlay để hướng dẫn người dùng
  bool _showOverlay = true;
  
  // Trạng thái edit: cho phép chỉnh sửa màu sau khi scan
  bool _isEditMode = false;
  
  // Multi-pass voting: scan nhiều lần và vote (chính xác hơn nhưng chậm hơn)
  bool _useMultiPass = false;
  
  // Phương pháp scan: 'ml', 'kmeans', 'hybrid'
  String _scanMethod = 'hybrid'; // Mặc định dùng hybrid (tốt nhất)

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('Không tìm thấy camera');
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi tạo camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  String get _currentFaceName {
    if (_currentFaceIndex >= _faces.length) return 'Hoàn thành';
    return _faces[_currentFaceIndex];
  }

  String get _currentFaceDisplayName {
    final names = {
      'up': 'Mặt TRÊN (U)',
      'front': 'Mặt TRƯỚC (F)',
      'right': 'Mặt PHẢI (R)',
      'back': 'Mặt SAU (B)',
      'left': 'Mặt TRÁI (L)',
      'down': 'Mặt DƯỚI (D)',
    };
    return names[_currentFaceName] ?? _currentFaceName;
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Chụp ảnh
      final image = await _cameraController!.takePicture();
      final imageBytes = await File(image.path).readAsBytes();
      
      // Scan mặt này với phương pháp đã chọn
      List<List<CubeColor?>> scannedFace;
      
      switch (_scanMethod) {
        case 'kmeans':
          scannedFace = CubeScannerService.scanFaceKMeans(imageBytes);
          break;
        case 'hybrid':
          scannedFace = CubeScannerService.scanFaceHybrid(
            imageBytes,
            useMultiPass: _useMultiPass,
          );
          break;
        case 'ml':
        default:
          scannedFace = CubeScannerService.scanFaceML(
            imageBytes,
            useMultiPass: _useMultiPass,
          );
          break;
      }
      
      // Kiểm tra xem có scan được đủ màu không (ít nhất 5/9 ô phải có màu)
      int validColors = 0;
      for (var row in scannedFace) {
        for (var color in row) {
          if (color != null) validColors++;
        }
      }
      
      if (validColors < 5) {
        // Nếu scan không đủ màu, báo lỗi và không chuyển mặt
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Scan không đủ màu ($validColors/9)'),
                  SizedBox(height: 4),
                  Text(
                    '💡 Mẹo: Đảm bảo ánh sáng đủ, camera vuông góc, Rubik chiếm đầy khung',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      // Lưu kết quả và cho phép chỉnh sửa
      setState(() {
        _scannedFaces[_currentFaceName] = scannedFace;
        _isProcessing = false;
        _isEditMode = true; // Bật chế độ edit
      });
      
      // Hiển thị thông báo và hướng dẫn chỉnh sửa
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✓ Đã scan! Tap vào ô để chỉnh sửa màu nếu cần',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi scan: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onScanComplete() {
    // Validate trước khi hoàn thành
    final validation = CubeValidator.validate(_scannedFaces);
    
    if (!validation.isValid) {
      // Hiển thị lỗi validation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: Text(
            validation.warning ? '⚠️ Cảnh báo' : '❌ Lỗi',
            style: TextStyle(
              color: validation.warning ? Colors.orange : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                validation.error ?? 'Có lỗi xảy ra',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Thống kê màu:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ...CubeValidator.getColorStatistics(_scannedFaces)
                  .entries
                  .map((e) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _getColorFromCubeColor(e.key),
                                border: Border.all(color: Colors.white30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${CubeScannerService.getColorName(e.key)}: ${e.value}/9',
                              style: TextStyle(
                                color: e.value == 9 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                validation.warning ? 'Tiếp tục' : 'Sửa lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (validation.warning)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (Navigator.of(context).canPop()) {
                    context.pop(_scannedFaces);
                  } else {
                    context.go('/');
                  }
                },
                child: Text(
                  'Bỏ qua',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
      );
      return;
    }
    
    // Validation thành công - hiển thị thông báo và chuyển màn hình
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Scan hoàn tất! Rubik hợp lệ'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      if (Navigator.of(context).canPop()) {
        context.pop(_scannedFaces);
      } else {
        context.go('/');
      }
    }
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Đang khởi tạo camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          
          // Overlay hướng dẫn
          if (_showOverlay)
            Positioned.fill(
              child: _buildOverlay(),
            ),
          
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
               child: PixelHeader(
                 title: 'SCAN RUBIK',
                 showBackButton: true,
                 onBackPressed: () {
                   if (Navigator.of(context).canPop()) {
                     context.pop();
                   } else {
                     context.go('/');
                   }
                 },
               ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final gridSize = screenSize.width * 0.7; // 70% chiều rộng màn hình
    
    return Container(
      color: Colors.black54,
      child: Stack(
        children: [
          // Hướng dẫn ở trên
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mặt ${_currentFaceIndex + 1}/6',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _currentFaceDisplayName,
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Đặt mặt này vào khung 3x3',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Đảm bảo đủ ánh sáng và căn chỉnh đúng',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Khung 3x3 căn giữa màn hình
          Center(
            child: Container(
              width: gridSize,
              height: gridSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellow, width: 3),
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ),
              child: Table(
                border: TableBorder.all(
                  color: Colors.white30,
                  width: 1,
                ),
                children: List.generate(3, (row) {
                  return TableRow(
                    children: List.generate(3, (col) {
                      // Hiển thị màu đã scan nếu có
                      Color cellColor = Colors.transparent;
                      CubeColor? currentColor;
                      
                      if (_scannedFaces.containsKey(_currentFaceName)) {
                        final face = _scannedFaces[_currentFaceName]!;
                        if (row < face.length && col < face[row].length) {
                          currentColor = face[row][col];
                          if (currentColor != null) {
                            cellColor = _getColorFromCubeColor(currentColor);
                          }
                        }
                      }
                      
                      return GestureDetector(
                        onTap: _isEditMode ? () => _editColor(row, col) : null,
                        child: Container(
                          width: gridSize / 3,
                          height: gridSize / 3,
                          decoration: _isEditMode
                              ? BoxDecoration(
                                  color: cellColor,
                                  border: Border.all(
                                    color: Colors.yellow,
                                    width: currentColor != null ? 3 : 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : BoxDecoration(
                                  color: cellColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                          child: _isEditMode
                              ? Stack(
                                  children: [
                                    if (currentColor == null)
                                      Center(
                                        child: Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.white70,
                                          size: 30,
                                        ),
                                      ),
                                    // Hiển thị icon edit khi có màu
                                    if (currentColor != null)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            color: Colors.yellow,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromCubeColor(CubeColor? color) {
    if (color == null) return Colors.grey;
    
    switch (color) {
      case CubeColor.white:
        return Colors.white;
      case CubeColor.red:
        return Colors.red;
      case CubeColor.blue:
        return Colors.blue;
      case CubeColor.orange:
        return Colors.orange;
      case CubeColor.green:
        return Colors.green;
      case CubeColor.yellow:
        return Colors.yellow;
    }
  }

  /// Chỉnh sửa màu của một ô
  void _editColor(int row, int col) {
    if (!_scannedFaces.containsKey(_currentFaceName)) {
      // Nếu chưa có face, tạo mới
      _scannedFaces[_currentFaceName] = List.generate(
        3,
        (r) => List.generate(3, (c) => null as CubeColor?),
      );
    }
    
    final face = _scannedFaces[_currentFaceName]!;
    final currentColor = face[row][col];
    
    // Hiển thị bottom sheet để chọn màu
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn màu cho ô ($row, $col)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                // Nút xóa màu (null)
                _buildColorOption(
                  null,
                  'Xóa',
                  Colors.grey,
                  currentColor == null,
                  () {
                    setState(() {
                      face[row][col] = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                // Các màu Rubik
                _buildColorOption(
                  CubeColor.white,
                  'Trắng',
                  Colors.white,
                  currentColor == CubeColor.white,
                  () {
                    setState(() {
                      face[row][col] = CubeColor.white;
                    });
                    Navigator.pop(context);
                  },
                ),
                _buildColorOption(
                  CubeColor.red,
                  'Đỏ',
                  Colors.red,
                  currentColor == CubeColor.red,
                  () {
                    setState(() {
                      face[row][col] = CubeColor.red;
                    });
                    Navigator.pop(context);
                  },
                ),
                _buildColorOption(
                  CubeColor.blue,
                  'Xanh dương',
                  Colors.blue,
                  currentColor == CubeColor.blue,
                  () {
                    setState(() {
                      face[row][col] = CubeColor.blue;
                    });
                    Navigator.pop(context);
                  },
                ),
                _buildColorOption(
                  CubeColor.orange,
                  'Cam',
                  Colors.orange,
                  currentColor == CubeColor.orange,
                  () {
                    setState(() {
                      face[row][col] = CubeColor.orange;
                    });
                    Navigator.pop(context);
                  },
                ),
                _buildColorOption(
                  CubeColor.green,
                  'Xanh lá',
                  Colors.green,
                  currentColor == CubeColor.green,
                  () {
                    setState(() {
                      face[row][col] = CubeColor.green;
                    });
                    Navigator.pop(context);
                  },
                ),
                _buildColorOption(
                  CubeColor.yellow,
                  'Vàng',
                  Colors.yellow,
                  currentColor == CubeColor.yellow,
                  () {
                    setState(() {
                      face[row][col] = CubeColor.yellow;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(
    CubeColor? color,
    String label,
    Color displayColor,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: displayColor,
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.white30,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: displayColor,
                border: Border.all(color: Colors.black26, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodButton(String label, String method, IconData icon) {
    final isSelected = _scanMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _scanMethod = method;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              method == 'ml' 
                  ? 'Đã chọn: Machine Learning (nhanh)'
                  : method == 'kmeans'
                      ? 'Đã chọn: K-Means (tự động phát hiện màu)'
                      : 'Đã chọn: Hybrid (K-Means + ML - khuyến nghị)',
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Row(
            children: List.generate(6, (index) {
              final isScanned = index < _currentFaceIndex;
              final isCurrent = index == _currentFaceIndex;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isScanned 
                        ? Colors.green 
                        : isCurrent 
                            ? Colors.yellow 
                            : Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          
          SizedBox(height: 20),
          
          // Nút chụp hoặc tiếp tục
          if (_isEditMode)
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    text: 'SCAN LẠI',
                    onPressed: () {
                      setState(() {
                        _isEditMode = false;
                        _scannedFaces.remove(_currentFaceName);
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PixelButton(
                    text: 'TIẾP TỤC',
                    onPressed: () {
                      setState(() {
                        _isEditMode = false;
                        _currentFaceIndex++;
                      });
                      
                      if (_currentFaceIndex >= _faces.length) {
                        _onScanComplete();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chuyển sang mặt ${_currentFaceIndex + 1}/6'),
                            backgroundColor: Colors.blue,
                            duration: Duration(milliseconds: 800),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            )
          else if (_currentFaceIndex < _faces.length)
            PixelButton(
              text: _isProcessing ? 'ĐANG XỬ LÝ...' : 'CHỤP VÀ SCAN',
              onPressed: _isProcessing ? null : _captureAndScan,
              width: double.infinity,
            )
          else
            PixelButton(
              text: 'HOÀN THÀNH',
              onPressed: _onScanComplete,
              width: double.infinity,
            ),
          
          SizedBox(height: 10),
          
          // Chọn phương pháp scan
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMethodButton('ML', 'ml', Icons.psychology),
              SizedBox(width: 8),
              _buildMethodButton('K-Means', 'kmeans', Icons.auto_awesome),
              SizedBox(width: 8),
              _buildMethodButton('Hybrid', 'hybrid', Icons.workspace_premium),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Toggle Multi-Pass Voting (chỉ khi dùng ML hoặc Hybrid)
          if (_scanMethod == 'ml' || _scanMethod == 'hybrid')
            GestureDetector(
              onTap: () {
                setState(() {
                  _useMultiPass = !_useMultiPass;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _useMultiPass 
                          ? 'Đã bật Multi-Pass Voting (chính xác hơn, chậm hơn)'
                          : 'Đã tắt Multi-Pass Voting (nhanh hơn)',
                    ),
                    backgroundColor: Colors.purple,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _useMultiPass ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: _useMultiPass ? Colors.purple : Colors.white54,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Multi-Pass Voting',
                    style: TextStyle(
                      color: _useMultiPass ? Colors.purple : Colors.white70,
                      fontSize: 11,
                      fontWeight: _useMultiPass ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 8),
          
          // Nút toggle overlay
          TextButton(
            onPressed: _toggleOverlay,
            child: Text(
              _showOverlay ? 'Ẩn hướng dẫn' : 'Hiện hướng dẫn',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

