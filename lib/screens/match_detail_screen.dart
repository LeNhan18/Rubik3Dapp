import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../models/rubik_cube.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../widgets/rubik_scene.dart';
import '../services/rubik_rotation_service.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({
    super.key,
    required this.matchId,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with TickerProviderStateMixin {
  final _apiService = ApiService();
  final _wsService = WebSocketService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  Match? _match;
  User? _currentUser;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Timer
  Timer? _timer;
  Stopwatch _stopwatch = Stopwatch();
  int _elapsedMilliseconds = 0;
  bool _isTimerRunning = false;

  // 3D Cube
  Scene? _scene;
  Map<Object, List<int>> _cubeGridPositions = {};
  Map<Object, List<Color>> _cubeFaceColors = {};
  late RubikCube _rubikCube;
  CameraController _cameraController = CameraController();
  RubikRotationService? _rotationService;
  bool _isRotating = false;
  bool _hasAppliedScramble = false;
  bool _isScrambling = false;
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    _rubikCube = RubikCube();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null || token.isEmpty) {
      // Not logged in, redirect to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để sử dụng tính năng này'),
          ),
        );
        context.go('/login');
      }
      return;
    }
    
    // User is logged in, load match data
    _loadMatch();
    _loadCurrentUser();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _messageController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _cubeGridPositions.clear();
    _cubeFaceColors.clear();

    // Tạo 27 cubes
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          final faceColors = CubeGeometryHelper.getInitialCubeColors(x, y, z);
          final mesh = Mesh(
            vertices: CubeGeometryHelper.createCubeVertices(),
            texcoords: CubeGeometryHelper.createCubeTexcoords(),
            indices: CubeGeometryHelper.createCubeIndices(),
            colors: CubeGeometryHelper.createColorsFromFaces(faceColors),
          );
          final obj = Object(
            name: 'cube_${x}_${y}_$z',
            mesh: mesh,
            position: Vector3((x - 1) * 4.0, (y - 1) * 4.0, (z - 1) * 4.0),
            scale: Vector3(1.8, 1.8, 1.8),
            backfaceCulling: false,
          );
          scene.world.add(obj);
          _cubeGridPositions[obj] = [x, y, z];
          _cubeFaceColors[obj] = faceColors;
        }
      }
    }

    // Khởi tạo rotation service
    _rotationService = RubikRotationService(
      scene: _scene!,
      cubeGridPositions: _cubeGridPositions,
      cubeFaceColors: _cubeFaceColors,
      onRotationStateChanged: () {
        if (mounted && _rotationService != null) {
          setState(() {
            _isRotating = _rotationService!.isRotating;
          });
        }
      },
    );

    scene.light.position.setFrom(Vector3(15, 15, 15));
    _cameraController.updateCameraPosition(scene);
    scene.camera.target.setValues(0, 0, 0);

    // Áp dụng scramble nếu match đã active (khi bắt đầu trận đấu)
    if (_match?.isActive == true && !_hasAppliedScramble && _rotationService != null) {
      _applyScramble();
    }
  }

  Future<void> _applyScramble() async {
    if (_match == null || _rotationService == null || _hasAppliedScramble) return;

    final scramble = _match!.scramble;
    final moves = scramble.split(' ').where((m) => m.isNotEmpty).toList();

    setState(() {
      _isScrambling = true;
      _hasAppliedScramble = true;
    });

    // Áp dụng từng move với delay
    for (final move in moves) {
      await _applyMoveTo3D(move);
    }

    // Scramble xong, cho phép hiển thị nút xoay
    setState(() {
      _isScrambling = false;
    });
  }

  Future<void> _applyMoveTo3D(String move) async {
    if (_rotationService == null) return;

    // Wait for any ongoing rotation
    while (_isRotating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final cleanMove = move.replaceAll("'", "p").replaceAll("2", "2");

    switch (move) {
      case 'R':
        _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: true, vsync: this);
        break;
      case 'R\'':
        _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: false, vsync: this);
        break;
      case 'L':
        _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: false, vsync: this);
        break;
      case 'L\'':
        _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: true, vsync: this);
        break;
      case 'U':
        _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: false, vsync: this);
        break;
      case 'U\'':
        _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: true, vsync: this);
        break;
      case 'D':
        _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: false, vsync: this);
        break;
      case 'D\'':
        _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: true, vsync: this);
        break;
      case 'F':
        _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: false, vsync: this);
        break;
      case 'F\'':
        _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: true, vsync: this);
        break;
      case 'B':
        _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: true, vsync: this);
        break;
      case 'B\'':
        _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: false, vsync: this);
        break;
      case 'M':
        _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: false, vsync: this);
        break;
      case 'M\'':
        _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: true, vsync: this);
        break;
      case 'E':
        _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: false, vsync: this);
        break;
      case 'E\'':
        _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: true, vsync: this);
        break;
      case 'S':
        _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: false, vsync: this);
        break;
      case 'S\'':
        _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: true, vsync: this);
        break;
    }

    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 550));
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    if (_scene != null) {
      _cameraController.updateCameraPosition(_scene!);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_scene == null) return;
    final currentFocal = details.focalPoint;
    if (_lastFocalPoint != null) {
      final delta = currentFocal - _lastFocalPoint!;
      _cameraController.updateFromPan(delta);
    }
    _lastFocalPoint = currentFocal;
    _cameraController.updateCameraPosition(_scene!);
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
  }

  // Rotation methods
  void _rotateR() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: true, vsync: this);
  }

  void _rotateRPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 2, clockwise: false, vsync: this);
  }

  void _rotateL() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: false, vsync: this);
  }

  void _rotateLPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: 0, clockwise: true, vsync: this);
  }

  void _rotateU() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: false, vsync: this);
  }

  void _rotateUPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 2, clockwise: true, vsync: this);
  }

  void _rotateD() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: false, vsync: this);
  }

  void _rotateDPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: 0, clockwise: true, vsync: this);
  }

  void _rotateF() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: false, vsync: this);
  }

  void _rotateFPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 2, clockwise: true, vsync: this);
  }

  void _rotateB() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: true, vsync: this);
  }

  void _rotateBPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: 0, clockwise: false, vsync: this);
  }

  void _rotateM() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: false, vsync: this);
  }

  void _rotateMPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 0, layer: -1, clockwise: true, vsync: this);
  }

  void _rotateE() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: false, vsync: this);
  }

  void _rotateEPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 1, layer: -1, clockwise: true, vsync: this);
  }

  void _rotateS() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: false, vsync: this);
  }

  void _rotateSPrime() {
    if (_isRotating || _rotationService == null) return;
    _rotationService!.rotateFace(axis: 2, layer: -1, clockwise: true, vsync: this);
  }

  Widget _buildRotationButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(50, 40),
      ),
      child: Text(label),
    );
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      setState(() => _currentUser = user);
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadMatch() async {
    setState(() => _isLoading = true);
    try {
      final match = await _apiService.getMatch(widget.matchId);
      setState(() {
        _match = match;
        _isLoading = false;
      });
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      final user = await _apiService.getCurrentUser();
      final token = await _apiService.getToken();
      if (token != null) {
        await _wsService.connect(user.id, token);
        _wsService.joinMatch(widget.matchId);

        // Cancel previous subscription if exists
        await _wsSubscription?.cancel();
        
        // Listen to WebSocket messages
        _wsSubscription = _wsService.messageStream?.listen(
          (data) {
            if (!mounted) return;
            
            if (data['type'] == 'chat') {
              // Check if message already exists to avoid duplicates
              final newMessage = ChatMessage(
                id: 0,
                matchId: widget.matchId,
                senderId: data['sender_id'] as int,
                content: data['content'] as String,
                messageType: MessageType.text,
                createdAt: DateTime.parse(data['timestamp'] as String),
                senderUsername: data['sender_username'] as String?,
              );
              
              // Check for duplicates
              final exists = _messages.any((msg) => 
                msg.senderId == newMessage.senderId &&
                msg.content == newMessage.content &&
                msg.createdAt.difference(newMessage.createdAt).inSeconds.abs() < 2
              );
              
              if (!exists) {
                setState(() {
                  _messages.add(newMessage);
                });
                _scrollToBottom();
              }
            }
          },
          onError: (error) {
            print('WebSocket stream error: $error');
          },
        );
      }
    } catch (e) {
      print('Error connecting WebSocket: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _apiService.getMessages(widget.matchId);
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startMatch() async {
    try {
      final match = await _apiService.startMatch(widget.matchId);
      setState(() => _match = match);
      
      // Áp dụng scramble ngay khi bắt đầu trận đấu
      // Nếu rotationService chưa sẵn sàng, nó sẽ được áp dụng trong _onSceneCreated()
      if (_rotationService != null && !_hasAppliedScramble) {
        await _applyScramble();
      }
      // Nếu rotationService chưa sẵn sàng, _onSceneCreated() sẽ tự động áp dụng scramble
      
      // KHÔNG bắt đầu timer ở đây - timer chỉ bắt đầu khi người dùng nhấn "Bắt đầu giải"
      // KHÔNG hiển thị nút xoay ở đây - nút xoay chỉ hiển thị khi người dùng nhấn "Bắt đầu giải"
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  void _startTimer() {
    // Bắt đầu timer - scramble đã được áp dụng khi bắt đầu trận đấu
    _stopwatch.start();
    _isTimerRunning = true;
    setState(() {}); // Trigger rebuild để hiển thị nút xoay
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        _elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
      });
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _isTimerRunning = false;
    _timer?.cancel();
  }

  // Kiểm tra cube đã giải xong chưa
  bool _isCubeSolved() {
    if (_rotationService == null || _cubeFaceColors.isEmpty || _cubeGridPositions.isEmpty) {
      return false;
    }
    
    // Màu chuẩn của cube đã giải (theo getInitialCubeColors):
    // [0] front (z=2): White
    // [1] back (z=0): Yellow
    // [2] top (y=2): Red
    // [3] bottom (y=0): Orange
    // [4] right (x=2): Blue
    // [5] left (x=0): Green
    
    final whiteColor = Colors.white;
    final yellowColor = Colors.yellow;
    final redColor = Colors.red;
    final orangeColor = Colors.orange;
    final blueColor = Colors.blue;
    final greenColor = Colors.green;
    
    // Kiểm tra từng mặt của cube (9 stickers mỗi mặt)
    // Front face (z=2): tất cả phải là white
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        final cubeEntry = _cubeGridPositions.entries.firstWhere(
          (e) => e.value[0] == x && e.value[1] == y && e.value[2] == 2,
        );
        final colors = _cubeFaceColors[cubeEntry.key] ?? [];
        if (colors.length < 6) return false;
        // Màu front là index 0
        if (colors[0] != whiteColor) return false;
      }
    }
    
    // Back face (z=0): tất cả phải là yellow
    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        final cubeEntry = _cubeGridPositions.entries.firstWhere(
          (e) => e.value[0] == x && e.value[1] == y && e.value[2] == 0,
        );
        final colors = _cubeFaceColors[cubeEntry.key] ?? [];
        if (colors.length < 6) return false;
        // Màu back là index 1
        if (colors[1] != yellowColor) return false;
      }
    }
    
    // Top face (y=2): tất cả phải là red
    for (int x = 0; x < 3; x++) {
      for (int z = 0; z < 3; z++) {
        final cubeEntry = _cubeGridPositions.entries.firstWhere(
          (e) => e.value[0] == x && e.value[1] == 2 && e.value[2] == z,
        );
        final colors = _cubeFaceColors[cubeEntry.key] ?? [];
        if (colors.length < 6) return false;
        // Màu top là index 2
        if (colors[2] != redColor) return false;
      }
    }
    
    // Bottom face (y=0): tất cả phải là orange
    for (int x = 0; x < 3; x++) {
      for (int z = 0; z < 3; z++) {
        final cubeEntry = _cubeGridPositions.entries.firstWhere(
          (e) => e.value[0] == x && e.value[1] == 0 && e.value[2] == z,
        );
        final colors = _cubeFaceColors[cubeEntry.key] ?? [];
        if (colors.length < 6) return false;
        // Màu bottom là index 3
        if (colors[3] != orangeColor) return false;
      }
    }
    
    // Right face (x=2): tất cả phải là blue
    for (int y = 0; y < 3; y++) {
      for (int z = 0; z < 3; z++) {
        final cubeEntry = _cubeGridPositions.entries.firstWhere(
          (e) => e.value[0] == 2 && e.value[1] == y && e.value[2] == z,
        );
        final colors = _cubeFaceColors[cubeEntry.key] ?? [];
        if (colors.length < 6) return false;
        // Màu right là index 4
        if (colors[4] != blueColor) return false;
      }
    }
    
    // Left face (x=0): tất cả phải là green
    for (int y = 0; y < 3; y++) {
      for (int z = 0; z < 3; z++) {
        final cubeEntry = _cubeGridPositions.entries.firstWhere(
          (e) => e.value[0] == 0 && e.value[1] == y && e.value[2] == z,
        );
        final colors = _cubeFaceColors[cubeEntry.key] ?? [];
        if (colors.length < 6) return false;
        // Màu left là index 5
        if (colors[5] != greenColor) return false;
      }
    }
    
    return true;
  }

  Future<void> _submitResult() async {
    if (_elapsedMilliseconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng giải cube trước khi nộp kết quả')),
      );
      return;
    }

    // Kiểm tra cube đã giải xong chưa
    if (!_isCubeSolved()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cube chưa được giải xong! Vui lòng giải cube hoàn chỉnh trước khi nộp kết quả.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final match = await _apiService.submitResult(
        widget.matchId,
        _elapsedMilliseconds,
      );
      setState(() {
        _match = match;
        _isSubmitting = false;
      });
      _stopTimer();

      if (match.isCompleted) {
        _showResultDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Optimistic update - thêm tin nhắn ngay lập tức
    final tempMessage = ChatMessage(
      id: 0,
      matchId: widget.matchId,
      senderId: _currentUser?.id ?? 0,
      content: content,
      messageType: MessageType.text,
      createdAt: DateTime.now(),
      senderUsername: _currentUser?.username,
    );
    
    setState(() {
      _messages.add(tempMessage);
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Gửi tin nhắn qua API (WebSocket sẽ broadcast tự động)
      await _apiService.sendMessage(
        matchId: widget.matchId,
        content: content,
      );
      
      // Reload messages để lấy ID chính xác từ server
      await _loadMessages();
    } catch (e) {
      // Nếu lỗi, xóa tin nhắn tạm
      setState(() {
        _messages.removeWhere((msg) => 
          msg.id == 0 && 
          msg.content == content &&
          msg.senderId == _currentUser?.id
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  void _showResultDialog() {
    if (_match == null || _currentUser == null) return;

    final isPlayer1 = _currentUser!.id == _match!.player1Id;
    final myTime = isPlayer1 ? _match!.player1Time : _match!.player2Time;
    final opponentTime = isPlayer1 ? _match!.player2Time : _match!.player1Time;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Kết quả trận đấu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thời gian của bạn: ${_formatTime(myTime ?? 0)}'),
            if (opponentTime != null)
              Text('Thời gian đối thủ: ${_formatTime(opponentTime)}'),
            const SizedBox(height: 16),
            Text(
              _match!.isDraw
                  ? 'Hòa!'
                  : (_match!.winnerId == _currentUser!.id
                      ? 'Bạn thắng! 🎉'
                      : 'Bạn thua 😢'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/matches');
            },
            child: const Text('Xem danh sách'),
          ),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final seconds = milliseconds / 1000;
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(2)}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds.toStringAsFixed(0)}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/matches'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_match == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/matches'),
          ),
        ),
        body: const Center(child: Text('Không tìm thấy trận đấu')),
      );
    }

    final theme = Theme.of(context);
    final isPlayer1 = _currentUser?.id == _match!.player1Id;
    final myTime = isPlayer1 ? _match!.player1Time : _match!.player2Time;
    final opponentTime = isPlayer1 ? _match!.player2Time : _match!.player1Time;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text('Trận đấu #${_match!.matchId.substring(0, 8)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/matches'),
        ),
        actions: [
          Chip(
            label: Text(_match!.status.displayName),
            backgroundColor: _match!.isActive
                ? Colors.green.withOpacity(0.2)
                : _match!.isCompleted
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Match info and scramble
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scramble - Ẩn để người dùng không thấy
                // Card(
                //   child: Padding(
                //     padding: const EdgeInsets.all(12),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(
                //           'Scramble:',
                //           style: theme.textTheme.titleSmall?.copyWith(
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const SizedBox(height: 8),
                //         SelectableText(
                //           _match!.scramble,
                //           style: theme.textTheme.bodyMedium,
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 12),

                // Timer
                if (_match!.isActive)
                  Card(
                    color: _isTimerRunning
                        ? Colors.red.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_elapsedMilliseconds),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isTimerRunning ? Colors.red : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!_isTimerRunning && myTime == null)
                            ElevatedButton.icon(
                              onPressed: _startTimer,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Bắt đầu giải'),
                            ),
                          if (_isTimerRunning)
                            ElevatedButton.icon(
                              onPressed: () {
                                _stopTimer();
                                _submitResult();
                              },
                              icon: const Icon(Icons.stop),
                              label: const Text('Nộp kết quả'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          if (myTime != null)
                            Text(
                              'Đã nộp: ${_formatTime(myTime)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Opponent status
                if (_match!.isActive && opponentTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text('Đối thủ đã nộp: ${_formatTime(opponentTime)}'),
                      backgroundColor: Colors.blue.withOpacity(0.2),
                    ),
                  ),

                // Start match button
                if (_match!.isWaiting)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startMatch,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Bắt đầu trận đấu'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // 3D Cube Section
          if (_match!.isActive)
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.black,
                child: RubikScene(
                  onSceneCreated: _onSceneCreated,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                ),
              ),
            ),

          // Rotation controls - chỉ hiển thị khi match active, không đang scramble, đã scramble xong, và timer đang chạy
          // Nút xoay chỉ hiển thị khi người dùng đã nhấn "Bắt đầu giải"
          if (_match!.isActive && !_isScrambling && _hasAppliedScramble && _isTimerRunning)
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRotationButton('R', _rotateR),
                    _buildRotationButton("R'", _rotateRPrime),
                    _buildRotationButton('L', _rotateL),
                    _buildRotationButton("L'", _rotateLPrime),
                    _buildRotationButton('U', _rotateU),
                    _buildRotationButton("U'", _rotateUPrime),
                    _buildRotationButton('D', _rotateD),
                    _buildRotationButton("D'", _rotateDPrime),
                    _buildRotationButton('F', _rotateF),
                    _buildRotationButton("F'", _rotateFPrime),
                    _buildRotationButton('B', _rotateB),
                    _buildRotationButton("B'", _rotateBPrime),
                    _buildRotationButton('M', _rotateM),
                    _buildRotationButton("M'", _rotateMPrime),
                    _buildRotationButton('E', _rotateE),
                    _buildRotationButton("E'", _rotateEPrime),
                    _buildRotationButton('S', _rotateS),
                    _buildRotationButton("S'", _rotateSPrime),
                  ],
                ),
              ),
            ),

          const Divider(),

          // Chat section
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Chat header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.surface,
                  child: Row(
                    children: [
                      const Icon(Icons.chat, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Chat',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Messages
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có tin nhắn nào',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isMe = message.senderId == _currentUser?.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              child: Text(
                message.senderUsername?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderUsername ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMe
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                _currentUser?.username.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

