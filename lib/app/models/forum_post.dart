import 'package:nylo_framework/nylo_framework.dart';

class ForumPost extends Model {
  String? id;
  String? userId;
  String? userName;
  String? userAvatar;
  bool? isVerified;
  String? category;
  String? content;
  String? imageUrl;
  DateTime? createdAt;
  int? likes;
  int? comments;
  int? shares;
  bool? isLiked;
  List<String>? likedBy;

  static StorageKey key = 'forum_posts';

  ForumPost() : super(key: key);

  ForumPost.fromJson(dynamic data) {
    id = data['id']?.toString();
    userId = data['user_id']?.toString() ?? data['userId']?.toString();
    userName = data['user_name'] ?? data['userName'];
    userAvatar = data['user_avatar'] ?? data['userAvatar'];
    isVerified = data['is_verified'] ?? data['isVerified'] ?? false;
    category = data['category'];
    content = data['content'];
    imageUrl = data['image_url'] ?? data['imageUrl'];
    likes = data['likes'] ?? 0;
    comments = data['comments'] ?? 0;
    shares = data['shares'] ?? 0;
    isLiked = data['is_liked'] ?? data['isLiked'] ?? false;
    likedBy = data['liked_by'] != null
        ? List<String>.from(data['liked_by'] ?? data['likedBy'] ?? [])
        : [];
    if (data['created_at'] != null || data['createdAt'] != null) {
      createdAt = DateTime.tryParse(
          data['created_at']?.toString() ?? data['createdAt']?.toString() ?? '');
    }
  }

  @override
  toJson() => {
        "id": id,
        "user_id": userId,
        "user_name": userName,
        "user_avatar": userAvatar,
        "is_verified": isVerified,
        "category": category,
        "content": content,
        "image_url": imageUrl,
        "created_at": createdAt?.toIso8601String(),
        "likes": likes,
        "comments": comments,
        "shares": shares,
        "is_liked": isLiked,
        "liked_by": likedBy,
      };
}
