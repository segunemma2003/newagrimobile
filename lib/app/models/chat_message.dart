import 'package:nylo_framework/nylo_framework.dart';

class ChatMessage extends Model {
  String? id;
  String? conversationId;
  String? senderId;
  String? senderName;
  String? senderAvatar;
  String? content;
  DateTime? timestamp;
  bool? isSent; // true if sent by current user, false if received
  bool? isRead;
  String? type; // "text", "image", "file", etc.

  static StorageKey key = 'chat_messages';

  ChatMessage() : super(key: key);

  ChatMessage.fromJson(dynamic data) {
    id = data['id']?.toString();
    conversationId = data['conversation_id']?.toString() ?? data['conversationId']?.toString();
    senderId = data['sender_id']?.toString() ?? data['senderId']?.toString();
    senderName = data['sender_name'] ?? data['senderName'];
    senderAvatar = data['sender_avatar'] ?? data['senderAvatar'];
    content = data['content'];
    isSent = data['is_sent'] ?? data['isSent'] ?? false;
    isRead = data['is_read'] ?? data['isRead'] ?? false;
    type = data['type'] ?? 'text';
    if (data['timestamp'] != null) {
      timestamp = DateTime.tryParse(data['timestamp'].toString());
    }
  }

  @override
  toJson() => {
        "id": id,
        "conversation_id": conversationId,
        "sender_id": senderId,
        "sender_name": senderName,
        "sender_avatar": senderAvatar,
        "content": content,
        "timestamp": timestamp?.toIso8601String(),
        "is_sent": isSent,
        "is_read": isRead,
        "type": type,
      };
}
