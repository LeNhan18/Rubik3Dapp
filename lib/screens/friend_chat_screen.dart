import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_text.dart';

class FriendChatScreen extends StatefulWidget {
  final User friend;

  const FriendChatScreen({super.key, required this.friend});

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  final _apiService = ApiService();
  final _wsService = WebSocketService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  Timer? _syncTimer;

  User? _currentUser;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _chatMatchId; // Match ID for this chat

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();

    // Sync messages every 30 seconds as backup
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_chatMatchId != null) {
        _syncMessages();
      }
    });
  }

  Future<void> _checkAuthAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
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

    await _loadCurrentUser();
    await _getOrCreateChatMatch();
    await _connectWebSocket();
    await _loadMessages();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      setState(() => _currentUser = user);
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _getOrCreateChatMatch() async {
    try {
      // Tìm match hiện có giữa 2 user
      final matches = await _apiService.getMyMatches();
      final existingMatch = matches.firstWhere(
        (match) =>
            (match.player1Id == _currentUser!.id &&
                match.player2Id == widget.friend.id) ||
            (match.player1Id == widget.friend.id &&
                match.player2Id == _currentUser!.id),
        orElse: () => throw Exception('No match found'),
      );

      setState(() => _chatMatchId = existingMatch.matchId);
    } catch (e) {
      // Không tìm thấy match, tạo match mới cho chat
      try {
        final match =
            await _apiService.createMatch(opponentId: widget.friend.id);
        setState(() => _chatMatchId = match.matchId);
      } catch (createError) {
        print('Error creating chat match: $createError');
        // Fallback: tạo match_id từ user IDs (sẽ không hoạt động với backend hiện tại)
        final userId1 = _currentUser!.id;
        final userId2 = widget.friend.id;
        final smallerId = userId1 < userId2 ? userId1 : userId2;
        final largerId = userId1 < userId2 ? userId2 : userId1;
        setState(() => _chatMatchId = 'chat_${smallerId}_$largerId');
      }
    }
  }

  Future<void> _connectWebSocket() async {
    if (_currentUser == null || _chatMatchId == null) return;

    try {
      final token = await _apiService.getToken();
      if (token != null) {
        await _wsService.connect(_currentUser!.id, token);
        _wsService.joinMatch(_chatMatchId!);

        // Cancel previous subscription if exists
        await _wsSubscription?.cancel();

        // Listen to WebSocket messages
        _wsSubscription = _wsService.messageStream?.listen(
          (data) {
            if (!mounted) return;

            if (data['type'] == 'chat' && data['match_id'] == _chatMatchId) {
              final newMessage = ChatMessage(
                id: 0,
                matchId: _chatMatchId!,
                senderId: data['sender_id'] as int,
                content: data['content'] as String,
                messageType: MessageType.text,
                createdAt: DateTime.parse(data['timestamp'] as String),
                senderUsername: data['sender_username'] as String?,
              );

              // Always add new messages from WebSocket, avoid duplicates by checking recent messages
              final isDuplicate = _messages
                  .where((msg) =>
                          DateTime.now().difference(msg.createdAt).inMinutes <
                          5 // Check recent 5 minutes
                      )
                  .any((msg) =>
                      msg.senderId == newMessage.senderId &&
                      msg.content == newMessage.content &&
                      msg.createdAt
                              .difference(newMessage.createdAt)
                              .inSeconds
                              .abs() <
                          5);

              if (!isDuplicate) {
                setState(() {
                  _messages.add(newMessage);
                  // Sort messages by timestamp to maintain order
                  _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
    if (_chatMatchId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final messages = await _apiService.getMessages(_chatMatchId!);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
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

  Future<void> _sendMessage() async {
    if (_chatMatchId == null) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Optimistic update
    final tempMessage = ChatMessage(
      id: 0,
      matchId: _chatMatchId!,
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
      await _apiService.sendMessage(
        matchId: _chatMatchId!,
        content: content,
      );

      // API already broadcasts via WebSocket, no need to send again
      // _wsService.sendChatMessage(_chatMatchId!, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
        // Remove optimistic message on error
        setState(() {
          _messages.removeWhere((msg) =>
              msg.id == 0 &&
              msg.content == content &&
              msg.senderId == (_currentUser?.id ?? 0));
        });
      }
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isMe = message.senderId == (_currentUser?.id ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                (message.senderUsername ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(18),
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
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white70
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
              backgroundColor: theme.colorScheme.secondary,
              child: Text(
                (_currentUser?.username ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _syncTimer?.cancel();
    super.dispose();
  }

  // Sync messages từ server (backup cho WebSocket)
  Future<void> _syncMessages() async {
    if (_chatMatchId == null || !mounted) return;

    try {
      final serverMessages = await _apiService.getMessages(_chatMatchId!);

      // Chỉ update nếu có messages mới
      if (serverMessages.length > _messages.length) {
        setState(() {
          _messages = serverMessages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Silent fail cho sync operation
      print('Sync messages error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PixelColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PixelHeader(
              title: widget.friend.username.toUpperCase(),
              showBackButton: true,
              onBackPressed: () => context.pop(),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PixelColors.background,
                  border: Border.all(color: PixelColors.border, width: 2),
                ),
                child: Center(
                  child: PixelText(
                    text: widget.friend.username.substring(0, 1).toUpperCase(),
                    style: PixelTextStyle.subtitle,
                    color: PixelColors.primary,
                  ),
                ),
              ),
              actions: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.friend.isOnline
                        ? PixelColors.success
                        : PixelColors.textLight,
                    border: Border.all(color: PixelColors.border, width: 2),
                  ),
                  child: PixelText(
                    text: widget.friend.isOnline ? 'ONLINE' : 'OFFLINE',
                    style: PixelTextStyle.caption,
                    color: PixelColors.background,
                  ),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Messages
                        Expanded(
                          child: _messages.isEmpty
                              ? Center(
                                  child: Text(
                                    'Chưa có tin nhắn nào',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: _messages.length,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return _buildMessageBubble(
                                        _messages[index]);
                                  },
                                ),
                        ),

                        // Message input
                        Container(
                          padding: const EdgeInsets.all(12),
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
      ),
    );
  }
}
