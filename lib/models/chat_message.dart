enum MessageType {
  text,
  system;

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}

class ChatMessage {
  final int id;
  final String matchId;
  final int senderId;
  final String? senderUsername;
  final String content;
  final MessageType messageType;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    this.senderUsername,
    required this.content,
    required this.messageType,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as int,
      senderUsername: json['sender_username'] as String?,
      content: json['content'] as String,
      messageType: MessageType.fromString(json['message_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'sender_username': senderUsername,
      'content': content,
      'message_type': messageType.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

