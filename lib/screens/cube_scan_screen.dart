import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/rubik_cube.dart';
import '../services/cube_scanner_service.dart';
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
      
      // Scan mặt này
      final scannedFace = CubeScannerService.scanFace(imageBytes);
      
      setState(() {
        _scannedFaces[_currentFaceName] = scannedFace;
        _currentFaceIndex++;
        _isProcessing = false;
      });
      
      // Nếu đã scan xong 6 mặt
      if (_currentFaceIndex >= _faces.length) {
        _onScanComplete();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã scan mặt $_currentFaceDisplayName'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
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
          ),
        );
      }
    }
  }

  void _onScanComplete() {
    // Chuyển kết quả về màn hình trước đó
    if (mounted) {
      context.pop(_scannedFaces);
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
                 onBackPressed: () => context.pop(),
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
    return Container(
      color: Colors.black54,
      child: Column(
        children: [
          SizedBox(height: 100),
          
          // Hướng dẫn
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow, width: 2),
            ),
            child: Column(
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
          
          Spacer(),
          
          // Khung 3x3 để căn chỉnh
          Container(
            margin: EdgeInsets.all(40),
            width: double.infinity,
            height: MediaQuery.of(context).size.width - 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.yellow, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                // Hiển thị màu đã scan nếu có
                if (_currentFaceIndex > 0 && 
                    _scannedFaces.containsKey(_faces[_currentFaceIndex - 1])) {
                  final row = index ~/ 3;
                  final col = index % 3;
                  final face = _scannedFaces[_faces[_currentFaceIndex - 1]]!;
                  
                  if (row < face.length && col < face[row].length) {
                    final color = face[row][col];
                    if (color != null) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30, width: 1),
                          color: _getColorFromCubeColor(color),
                        ),
                      );
                    }
                  }
                }
                
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                );
              },
            ),
          ),
          
          Spacer(),
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
          
          // Nút chụp
          if (_currentFaceIndex < _faces.length)
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

