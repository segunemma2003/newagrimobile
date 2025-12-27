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
    completedLessons = data['completed_lessons'] ?? data['completedLessons'] ?? 0;
    totalLessons = data['total_lessons'] ?? data['totalLessons'] ?? 0;

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
        "topics": lessons?.map((l) => l.toJson()).toList(),
      };
}

