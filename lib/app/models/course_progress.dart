import 'package:nylo_framework/nylo_framework.dart';

class CourseProgress extends Model {
  String? userId;
  String? courseId;
  String? lessonId;
  bool? isCompleted;
  int? progress; // 0-100
  Map<String, dynamic>? quizResults; // lessonId -> {score, answers}
  DateTime? completedAt;
  DateTime? lastAccessedAt;

  static StorageKey key = 'course_progress';

  CourseProgress() : super(key: key);

  CourseProgress.fromJson(dynamic data) {
    userId = data['user_id']?.toString() ?? data['userId']?.toString();
    courseId = data['course_id']?.toString() ?? data['courseId']?.toString();
    lessonId = data['lesson_id']?.toString() ?? data['lessonId']?.toString();
    isCompleted = data['is_completed'] ?? data['isCompleted'] ?? false;
    progress = data['progress'] ?? 0;
    quizResults = data['quiz_results'] ?? data['quizResults'];
    if (data['completed_at'] != null || data['completedAt'] != null) {
      completedAt = DateTime.tryParse(
          data['completed_at']?.toString() ?? data['completedAt']?.toString() ?? '');
    }
    if (data['last_accessed_at'] != null || data['lastAccessedAt'] != null) {
      lastAccessedAt = DateTime.tryParse(
          data['last_accessed_at']?.toString() ?? data['lastAccessedAt']?.toString() ?? '');
    }
  }

  @override
  toJson() => {
        "user_id": userId,
        "course_id": courseId,
        "lesson_id": lessonId,
        "is_completed": isCompleted,
        "progress": progress,
        "quiz_results": quizResults,
        "completed_at": completedAt?.toIso8601String(),
        "last_accessed_at": lastAccessedAt?.toIso8601String(),
      };
}




