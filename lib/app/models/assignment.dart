import 'package:nylo_framework/nylo_framework.dart';

class Assignment extends Model {
  String? id;
  String? courseId;
  String? moduleId;
  String? lessonId;
  String? title;
  String? description;
  String? brief;
  List<String>? requirements;
  List<Map<String, dynamic>>? resources; // {name, url, type, size}
  DateTime? dueDate;
  int? estimatedHours;
  String? status; // "not_submitted", "draft", "submitted", "graded"
  String? submissionFile;
  String? submissionFilePath;
  DateTime? submittedAt;
  int? score;
  String? feedback;
  String? rubricUrl;

  static StorageKey key = 'assignments';

  Assignment() : super(key: key);

  Assignment.fromJson(dynamic data) {
    id = data['id']?.toString();
    courseId = data['course_id']?.toString() ?? data['courseId']?.toString();
    moduleId = data['module_id']?.toString() ?? data['moduleId']?.toString();
    lessonId = data['lesson_id']?.toString() ?? data['lessonId']?.toString();
    title = data['title'];
    description = data['description'];
    brief = data['brief'];
    status = data['status'] ?? 'not_submitted';
    submissionFile = data['submission_file'] ?? data['submissionFile'];
    submissionFilePath = data['submission_file_path'] ?? data['submissionFilePath'];
    score = data['score'];
    feedback = data['feedback'];
    rubricUrl = data['rubric_url'] ?? data['rubricUrl'];
    
    if (data['requirements'] != null) {
      requirements = List<String>.from(data['requirements']);
    }
    
    if (data['resources'] != null) {
      resources = List<Map<String, dynamic>>.from(data['resources']);
    }
    
    if (data['due_date'] != null || data['dueDate'] != null) {
      dueDate = DateTime.tryParse(
          data['due_date']?.toString() ?? data['dueDate']?.toString() ?? '');
    }
    
    estimatedHours = data['estimated_hours'] ?? data['estimatedHours'];
    
    if (data['submitted_at'] != null || data['submittedAt'] != null) {
      submittedAt = DateTime.tryParse(
          data['submitted_at']?.toString() ?? data['submittedAt']?.toString() ?? '');
    }
  }

  @override
  toJson() => {
        "id": id,
        "course_id": courseId,
        "module_id": moduleId,
        "lesson_id": lessonId,
        "title": title,
        "description": description,
        "brief": brief,
        "requirements": requirements,
        "resources": resources,
        "due_date": dueDate?.toIso8601String(),
        "estimated_hours": estimatedHours,
        "status": status,
        "submission_file": submissionFile,
        "submission_file_path": submissionFilePath,
        "submitted_at": submittedAt?.toIso8601String(),
        "score": score,
        "feedback": feedback,
        "rubric_url": rubricUrl,
      };
}
