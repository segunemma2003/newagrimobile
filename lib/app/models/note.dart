import 'package:nylo_framework/nylo_framework.dart';

class Note extends Model {
  String? id;
  String? userId;
  String? courseId;
  String? moduleId;
  String? lessonId;
  String? title;
  String? content;
  DateTime? createdAt;
  DateTime? updatedAt;

  static StorageKey key = 'notes';

  Note() : super(key: key);

  Note.fromJson(dynamic data) {
    id = data['id']?.toString();
    userId = data['user_id']?.toString() ?? data['userId']?.toString();
    courseId = data['course_id']?.toString() ?? data['courseId']?.toString();
    moduleId = data['module_id']?.toString() ?? data['moduleId']?.toString();
    lessonId = data['lesson_id']?.toString() ?? data['lessonId']?.toString();
    title = data['title'];
    content = data['content'];
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
        "course_id": courseId,
        "module_id": moduleId,
        "lesson_id": lessonId,
        "title": title,
        "content": content,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
