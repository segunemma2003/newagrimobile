import 'package:nylo_framework/nylo_framework.dart';

class Message extends Model {
  String? id;
  String? conversationId;
  String? senderId;
  String? senderName;
  String? senderAvatar;
  String? senderType; // 'instructor', 'student', 'group', 'bot'
  String? content;
  DateTime? timestamp;
  bool? isRead;
  bool? isPinned;
  int? unreadCount; // For conversations
  String? lastMessagePreview;
  DateTime? lastMessageTime;

  static StorageKey key = 'messages';

  Message() : super(key: key);

  Message.fromJson(dynamic data) {
    id = data['id']?.toString();
    conversationId = data['conversation_id']?.toString() ?? data['conversationId']?.toString();
    senderId = data['sender_id']?.toString() ?? data['senderId']?.toString();
    senderName = data['sender_name'] ?? data['senderName'] ?? 'Unknown';
    senderAvatar = data['sender_avatar'] ?? data['senderAvatar'];
    senderType = data['sender_type'] ?? data['senderType'] ?? 'student';
    content = data['content'];
    lastMessagePreview = data['last_message_preview'] ?? data['lastMessagePreview'] ?? content;
    isRead = data['is_read'] ?? data['isRead'] ?? false;
    isPinned = data['is_pinned'] ?? data['isPinned'] ?? false;
    unreadCount = data['unread_count'] ?? data['unreadCount'] ?? 0;
    
    if (data['timestamp'] != null || data['created_at'] != null || data['createdAt'] != null) {
      timestamp = DateTime.tryParse(
          data['timestamp']?.toString() ?? 
          data['created_at']?.toString() ?? 
          data['createdAt']?.toString() ?? '');
    }
    if (data['last_message_time'] != null || data['lastMessageTime'] != null) {
      lastMessageTime = DateTime.tryParse(
          data['last_message_time']?.toString() ?? 
          data['lastMessageTime']?.toString() ?? '');
    }
  }

  @override
  toJson() => {
        "id": id,
        "conversation_id": conversationId,
        "sender_id": senderId,
        "sender_name": senderName,
        "sender_avatar": senderAvatar,
        "sender_type": senderType,
        "content": content,
        "last_message_preview": lastMessagePreview,
        "is_read": isRead ?? false,
        "is_pinned": isPinned ?? false,
        "unread_count": unreadCount ?? 0,
        "timestamp": timestamp?.toIso8601String(),
        "last_message_time": lastMessageTime?.toIso8601String(),
      };
}
