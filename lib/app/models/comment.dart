import 'package:nylo_framework/nylo_framework.dart';

class Comment extends Model {
  String? id;
  String? userId;
  String? userName;
  String? userAvatar;
  String? lessonId;
  String? courseId;
  String? moduleId;
  String? parentId; // For threaded comments (null for top-level comments)
  String? content;
  int? likes;
  bool? isLiked;
  List<Comment>? replies; // Nested replies
  DateTime? createdAt;
  DateTime? updatedAt;

  static StorageKey key = 'comments';

  Comment() : super(key: key);

  Comment.fromJson(dynamic data) {
    id = data['id']?.toString();
    userId = data['user_id']?.toString() ?? data['userId']?.toString();
    userName = data['user_name'] ?? data['userName'] ?? 'Anonymous';
    userAvatar = data['user_avatar'] ?? data['userAvatar'];
    lessonId = data['lesson_id']?.toString() ?? data['lessonId']?.toString();
    courseId = data['course_id']?.toString() ?? data['courseId']?.toString();
    moduleId = data['module_id']?.toString() ?? data['moduleId']?.toString();
    parentId = data['parent_id']?.toString() ?? data['parentId']?.toString();
    content = data['content'];
    likes = data['likes'] ?? 0;
    isLiked = data['is_liked'] ?? data['isLiked'] ?? false;
    
    if (data['replies'] != null) {
      replies = (data['replies'] as List)
          .map((reply) => Comment.fromJson(reply))
          .toList();
    }
    
    if (data['created_at'] != null || data['createdAt'] != null) {
      createdAt = DateTime.tryParse(
          data['created_at']?.toString() ?? data['createdAt']?.toString() ?? '');
    }
    if (data['updated_at'] != null || data['updatedAt'] != null) {
      updatedAt = DateTime.tryParse(
          data['updated_at']?.toString() ?? data['updatedAt']?.toString() ?? '');
    }
  }

  @override
  toJson() => {
        "id": id,
        "user_id": userId,
        "user_name": userName,
        "user_avatar": userAvatar,
        "lesson_id": lessonId,
        "course_id": courseId,
        "module_id": moduleId,
        "parent_id": parentId,
        "content": content,
        "likes": likes ?? 0,
        "is_liked": isLiked ?? false,
        "replies": replies?.map((r) => r.toJson()).toList(),
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
  
  // Helper method to check if comment has replies
  bool get hasReplies => replies != null && replies!.isNotEmpty;
  
  // Helper method to get reply count
  int get replyCount => replies?.length ?? 0;
}
