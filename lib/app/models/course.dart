import 'package:nylo_framework/nylo_framework.dart';
import 'lesson.dart';
import 'category.dart';
import 'module.dart';

class Course extends Model {
  String? id;
  String? title;
  String? description;
  String? categoryId;
  Category? category;
  String? thumbnail;
  String? thumbnailPath;
  List<Module>? modules;
  List<Lesson>? lessons;
  int? totalLessons;
  int? completedLessons;
  bool? isCompleted;
  String? updatedAt;
  String? projectId; // Reference to course capstone project

  static StorageKey key = 'courses';

  Course() : super(key: key);

  Course.fromJson(dynamic data) {
    id = data['id']?.toString();
    title = data['title'];
    description = data['description'] ?? data['short_description'];
    categoryId = data['category_id']?.toString() ?? data['categoryId']?.toString();
    thumbnail = data['image'] ?? data['thumbnail'];
    thumbnailPath = data['thumbnail_path'] ?? data['thumbnailPath'];
    totalLessons = data['total_lessons'] ?? data['totalLessons'] ?? 0;
    completedLessons = data['completed_lessons'] ?? data['completedLessons'] ?? 0;
    isCompleted = data['is_completed'] ?? data['isCompleted'] ?? false;
    updatedAt = data['updated_at'] ?? data['updatedAt'];
    projectId = data['project_id']?.toString() ?? data['projectId']?.toString();
    
    if (data['category'] != null) {
      category = Category.fromJson(data['category']);
    }
    
    if (data['modules'] != null) {
      modules = (data['modules'] as List)
          .map((module) => Module.fromJson(module))
          .toList();
      modules?.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      
      totalLessons = modules?.fold<int>(0, (sum, m) => sum + (m.totalLessons ?? 0)) ?? 0;
      completedLessons = modules?.fold<int>(0, (sum, m) => sum + (m.completedLessons ?? 0)) ?? 0;
    }
    
    if (data['lessons'] != null && (modules == null || modules!.isEmpty)) {
      lessons = (data['lessons'] as List)
          .map((lesson) => Lesson.fromJson(lesson))
          .toList();
      lessons?.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      totalLessons = lessons?.length ?? 0;
    }
  }

  @override
  toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "category_id": categoryId,
        "thumbnail": thumbnail,
        "thumbnail_path": thumbnailPath,
        "total_lessons": totalLessons,
        "completed_lessons": completedLessons,
        "is_completed": isCompleted,
        "updated_at": updatedAt,
        "project_id": projectId,
        "category": category?.toJson(),
        "modules": modules?.map((m) => m.toJson()).toList(),
        "lessons": lessons?.map((l) => l.toJson()).toList(),
      };
}




