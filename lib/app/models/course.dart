import 'package:nylo_framework/nylo_framework.dart';
import 'lesson.dart';
import 'category.dart';
import 'module.dart';
import 'user.dart';
import 'review.dart';

class Course extends Model {
  String? id;
  String? title;
  String? description;
  String? shortDescription;
  String? categoryId;
  Category? category;
  User? tutor; // Course tutor/instructor
  String? thumbnail;
  String? thumbnailPath;
  String? previewVideoUrl; // Preview video URL for course
  // Detailed course meta from API
  String? about;
  String? requirements;
  String? whatToExpect;
  bool? certificateIncluded;
  int? lessonsCount;
  int? moduleCount; // Number of modules in the course
  int? materialsCount;
  String? rating;
  int? ratingCount;
  int? enrollmentCount;
  String? price;
  bool? isFree;
  int? durationMinutes;
  String? level;
  String? language;
  List<String>? whatYouWillLearn;
  List<String>? whatYouWillGet;
  List<String>? courseInformation;
  List<String>? tags;
  List<Module>? modules;
  List<Lesson>? lessons;
  List<Review>? reviews;
  int? totalLessons;
  int? completedLessons;
  bool? isCompleted;
  bool? isEnrolled; // Real enrollment status from API
  String? updatedAt;
  String? projectId; // Reference to course capstone project

  static StorageKey key = 'courses';

  Course() : super(key: key);

  Course.fromJson(dynamic data) {
    id = data['id']?.toString();
    title = data['title'];
    description = data['description'] ?? data['short_description'];
    shortDescription = data['short_description'] ?? data['shortDescription'];
    categoryId =
        data['category_id']?.toString() ?? data['categoryId']?.toString();
    thumbnail = data['image'] ?? data['thumbnail'];
    thumbnailPath = data['thumbnail_path'] ?? data['thumbnailPath'];
    previewVideoUrl = data['preview_video_url'] ??
        data['previewVideoUrl'] ??
        data['video_url'] ??
        data['videoUrl'];
    about = data['about'];
    requirements = data['requirements'];
    whatToExpect = data['what_to_expect'] ?? data['whatToExpect'];
    certificateIncluded =
        data['certificate_included'] ?? data['certificateIncluded'];
    lessonsCount = data['lessons_count'] ?? data['lessonsCount'];
    moduleCount = data['modules_count'] ??
        data['modulesCount'] ??
        data['module_count'] ??
        data['moduleCount'];
    materialsCount = data['materials_count'] ?? data['materialsCount'];
    rating = data['rating']?.toString();
    ratingCount = data['rating_count'] ?? data['ratingCount'];
    enrollmentCount = data['enrollment_count'] ?? data['enrollmentCount'];
    price = data['price']?.toString();
    isFree = data['is_free'] ?? data['isFree'];
    durationMinutes = data['duration_minutes'] ?? data['durationMinutes'];
    level = data['level'];
    language = data['language'];

    // Parse list fields like: [{item: "..."}]
    if (data['what_you_will_learn'] is List) {
      whatYouWillLearn = (data['what_you_will_learn'] as List)
          .map((e) => e is Map ? e['item']?.toString() : e.toString())
          .whereType<String>()
          .toList();
    }
    if (data['what_you_will_get'] is List) {
      whatYouWillGet = (data['what_you_will_get'] as List)
          .map((e) => e is Map ? e['item']?.toString() : e.toString())
          .whereType<String>()
          .toList();
    }
    if (data['course_information'] is List) {
      courseInformation = (data['course_information'] as List)
          .map((e) => e is Map ? e['item']?.toString() : e.toString())
          .whereType<String>()
          .toList();
    }
    if (data['tags'] is List) {
      tags = (data['tags'] as List).map((e) => e.toString()).toList();
    }

    if (data['reviews'] is List) {
      reviews =
          (data['reviews'] as List).map((r) => Review.fromJson(r)).toList();
    }

    totalLessons = data['total_lessons'] ?? data['totalLessons'] ?? 0;
    completedLessons =
        data['completed_lessons'] ?? data['completedLessons'] ?? 0;
    isCompleted = data['is_completed'] ?? data['isCompleted'] ?? false;
    isEnrolled = data['is_enrolled'] ?? data['isEnrolled'] ?? false;
    updatedAt = data['updated_at'] ?? data['updatedAt'];
    projectId = data['project_id']?.toString() ?? data['projectId']?.toString();

    if (data['category'] != null) {
      category = Category.fromJson(data['category']);
    }

    // Parse tutor information
    if (data['tutor'] != null) {
      tutor = User.fromJson(data['tutor']);
    }

    if (data['modules'] != null) {
      modules = (data['modules'] as List)
          .map((module) => Module.fromJson(module))
          .toList();
      modules?.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

      totalLessons =
          modules?.fold<int>(0, (sum, m) => sum + (m.totalLessons ?? 0)) ?? 0;
      completedLessons =
          modules?.fold<int>(0, (sum, m) => sum + (m.completedLessons ?? 0)) ??
              0;
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
        "short_description": shortDescription,
        "category_id": categoryId,
        "thumbnail": thumbnail,
        "thumbnail_path": thumbnailPath,
        "preview_video_url": previewVideoUrl,
        "about": about,
        "requirements": requirements,
        "what_to_expect": whatToExpect,
        "certificate_included": certificateIncluded,
        "lessons_count": lessonsCount,
        "modules_count": moduleCount,
        "materials_count": materialsCount,
        "rating": rating,
        "rating_count": ratingCount,
        "enrollment_count": enrollmentCount,
        "price": price,
        "is_free": isFree,
        "duration_minutes": durationMinutes,
        "level": level,
        "language": language,
        "what_you_will_learn": whatYouWillLearn,
        "what_you_will_get": whatYouWillGet,
        "course_information": courseInformation,
        "tags": tags,
        "reviews": reviews?.map((r) => r.toJson()).toList(),
        "total_lessons": totalLessons,
        "completed_lessons": completedLessons,
        "is_completed": isCompleted,
        "is_enrolled": isEnrolled,
        "updated_at": updatedAt,
        "project_id": projectId,
        "category": category?.toJson(),
        "modules": modules?.map((m) => m.toJson()).toList(),
        "lessons": lessons?.map((l) => l.toJson()).toList(),
      };
}
