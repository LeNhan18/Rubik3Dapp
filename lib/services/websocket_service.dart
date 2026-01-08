import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;
  int? _userId;
  String? _token;

  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(int userId, String token) async {
    if (_isConnected && _userId == userId) {
      return; // Already connected
    }

    await disconnect(); // Disconnect previous connection if any

    _userId = userId;
    _token = token;

    // Local development
    final uri = Uri.parse('ws://192.168.2.26:8000/ws/$userId?token=$token');
    
    // Fly.io production (commented)
    // final uri = Uri.parse('wss://app-falling-wind-2135.fly.dev/ws/$userId?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            _messageController?.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
        },
      );
    } catch (e) {
      print('Error connecting WebSocket: $e');
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    await _messageController?.close();
    _channel = null;
    _messageController = null;
    _isConnected = false;
  }

  void joinMatch(String matchId) {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    _channel!.sink.add(jsonEncode({
      'type': 'join_match',
      'match_id': matchId,
    }));
  }

  void leaveMatch(String matchId) {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    _channel!.sink.add(jsonEncode({
      'type': 'leave_match',
      'match_id': matchId,
    }));
  }

  void sendChatMessage(String matchId, String content) {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    _channel!.sink.add(jsonEncode({
      'type': 'chat',
      'match_id': matchId,
      'content': content,
    }));
  }
}

