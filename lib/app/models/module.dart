import 'package:nylo_framework/nylo_framework.dart';
import 'lesson.dart';

class Module extends Model {
  String? id;
  String? courseId;
  String? title;
  String? description;
  int? order;
  List<Lesson>? lessons; // topics/lessons in this module
  bool? isCompleted;
  bool? isLocked;
  int? completedLessons;
  int? totalLessons;
  int? testScore; // Module test score (0-100)
  bool? testPassed; // Whether test passed (80% threshold)
  int? testRetries; // Number of test retry attempts (max 3)
  String? projectId; // Reference to module project
  bool? hasVR; // Whether module has VR experience
  String? subTutorId; // Sub tutor ID for this module
  String? subTutorName; // Sub tutor name
  String? subTutorAvatar; // Sub tutor avatar URL

  static StorageKey key = 'modules';

  Module() : super(key: key);

  Module.fromJson(dynamic data) {
    id = data['id']?.toString();
    courseId = data['course_id']?.toString() ?? data['courseId']?.toString();
    title = data['title'];
    description = data['description'];
    order = data['order'] ?? 0;
    isCompleted = data['is_completed'] ?? data['isCompleted'] ?? false;
    isLocked = data['is_locked'] ?? data['isLocked'] ?? false;
    completedLessons =
        data['completed_lessons'] ?? data['completedLessons'] ?? 0;
    totalLessons = data['total_lessons'] ?? data['totalLessons'] ?? 0;
    testScore = data['test_score'] ?? data['testScore'];
    testPassed = data['test_passed'] ?? data['testPassed'] ?? false;
    testRetries = data['test_retries'] ?? data['testRetries'] ?? 0;
    projectId = data['project_id']?.toString() ?? data['projectId']?.toString();
    hasVR = data['has_vr'] ?? data['hasVR'] ?? false;
    subTutorId =
        data['sub_tutor_id']?.toString() ?? data['subTutorId']?.toString();
    subTutorName = data['sub_tutor_name'] ?? data['subTutorName'];
    subTutorAvatar = data['sub_tutor_avatar'] ?? data['subTutorAvatar'];

    // Handle topics/lessons
    if (data['topics'] != null) {
      lessons = (data['topics'] as List)
          .map((topic) => Lesson.fromJson(topic))
          .toList();
      lessons?.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } else if (data['lessons'] != null) {
      lessons = (data['lessons'] as List)
          .map((lesson) => Lesson.fromJson(lesson))
          .toList();
      lessons?.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    }
  }

  @override
  toJson() => {
        "id": id,
        "course_id": courseId,
        "title": title,
        "description": description,
        "order": order,
        "is_completed": isCompleted,
        "is_locked": isLocked,
        "completed_lessons": completedLessons,
        "total_lessons": totalLessons,
        "test_score": testScore,
        "test_passed": testPassed,
        "test_retries": testRetries,
        "project_id": projectId,
        "has_vr": hasVR,
        "sub_tutor_id": subTutorId,
        "sub_tutor_name": subTutorName,
        "sub_tutor_avatar": subTutorAvatar,
        "topics": lessons?.map((l) => l.toJson()).toList(),
      };
}
