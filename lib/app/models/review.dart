import 'package:nylo_framework/nylo_framework.dart';

class Review extends Model {
  String? id;
  String? userId;
  String? userName;
  String? userAvatar;
  String? courseId;
  int? rating; // 1-5 stars
  String? comment;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool? isVerified; // Verified purchase/enrollment

  static StorageKey key = 'reviews';

  Review() : super(key: key);

  Review.fromJson(dynamic data) {
    id = data['id']?.toString();
    userId = data['user_id']?.toString() ?? data['userId']?.toString();
    // Try direct fields, then nested user relationship
    userName = data['user_name'] ??
        data['userName'] ??
        (data['user'] != null ? data['user']['name'] : null) ??
        'Anonymous';
    userAvatar = data['user_avatar'] ??
        data['userAvatar'] ??
        (data['user'] != null ? data['user']['avatar'] : null);
    courseId = data['course_id']?.toString() ?? data['courseId']?.toString();
    rating = data['rating'] ?? 5;
    // Backend uses 'review' field for comment content
    comment = data['comment'] ?? data['review'] ?? data['content'];
    isVerified =
        data['is_verified'] ?? data['isVerified'] ?? data['is_verified_purchase'] ?? false;
    
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
        "course_id": courseId,
        "rating": rating ?? 5,
        "comment": comment,
        "is_verified": isVerified ?? false,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
