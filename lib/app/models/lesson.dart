import 'package:nylo_framework/nylo_framework.dart';
import 'quiz.dart';

class Lesson extends Model {
  String? id;
  String? courseId;
  String? moduleId;
  String? title;
  String? description;
  String? content;
  String? videoUrl;
  String? videoPath;
  String? transcript;
  String? type;
  int? order;
  int? duration;
  List<Quiz>? quizzes;
  String? assignmentId; // Reference to assignment if lesson has one
  bool? isCompleted;
  bool? isLocked;

  static StorageKey key = 'lessons';

  Lesson() : super(key: key);

  Lesson.fromJson(dynamic data) {
    id = data['id']?.toString();
    courseId = data['course_id']?.toString() ?? data['courseId']?.toString();
    moduleId = data['module_id']?.toString() ?? data['moduleId']?.toString();
    title = data['title'];
    description = data['description'];
    content = data['content'];
    videoUrl = data['video_url'] ?? data['videoUrl'];
    videoPath = data['video_path'] ?? data['videoPath'];
    transcript = data['transcript'];
    type = data['type'] ?? 'writeup';
    order = data['order'] ?? 0;
    duration = data['duration'] ?? 0;
    isCompleted = data['is_completed'] ?? data['isCompleted'] ?? false;
    isLocked = data['is_locked'] ?? data['isLocked'] ?? false;
    assignmentId = data['assignment_id']?.toString() ?? data['assignmentId']?.toString();
    if (data['quizzes'] != null) {
      quizzes = (data['quizzes'] as List)
          .map((quiz) => Quiz.fromJson(quiz))
          .toList();
    }
  }

  @override
  toJson() => {
        "id": id,
        "course_id": courseId,
        "module_id": moduleId,
        "title": title,
        "description": description,
        "content": content,
        "video_url": videoUrl,
        "video_path": videoPath,
        "transcript": transcript,
        "type": type,
        "order": order,
        "duration": duration,
        "is_completed": isCompleted,
        "is_locked": isLocked,
        "assignment_id": assignmentId,
        "quizzes": quizzes?.map((q) => q.toJson()).toList(),
      };
}

