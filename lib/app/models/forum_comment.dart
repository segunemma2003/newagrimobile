import 'package:nylo_framework/nylo_framework.dart';

class ForumComment extends Model {
  String? id;
  String? postId;
  String? userId;
  String? userName;
  String? userAvatar;
  bool? isVerified;
  String? content;
  DateTime? createdAt;
  int? likes;
  bool? isLiked;
  String? parentId; // For nested replies

  static StorageKey key = 'forum_comments';

  ForumComment() : super(key: key);

  ForumComment.fromJson(dynamic data) {
    id = data['id']?.toString();
    postId = data['post_id']?.toString() ?? data['postId']?.toString();
    userId = data['user_id']?.toString() ?? data['userId']?.toString();
    userName = data['user_name'] ?? data['userName'];
    userAvatar = data['user_avatar'] ?? data['userAvatar'];
    isVerified = data['is_verified'] ?? data['isVerified'] ?? false;
    content = data['content'];
    likes = data['likes'] ?? 0;
    isLiked = data['is_liked'] ?? data['isLiked'] ?? false;
    parentId = data['parent_id']?.toString() ?? data['parentId']?.toString();
    if (data['created_at'] != null || data['createdAt'] != null) {
      createdAt = DateTime.tryParse(
          data['created_at']?.toString() ?? data['createdAt']?.toString() ?? '');
    }
  }

  @override
  toJson() => {
        "id": id,
        "post_id": postId,
        "user_id": userId,
        "user_name": userName,
        "user_avatar": userAvatar,
        "is_verified": isVerified,
        "content": content,
        "created_at": createdAt?.toIso8601String(),
        "likes": likes,
        "is_liked": isLiked,
        "parent_id": parentId,
      };
}
