import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/models/lesson.dart';
import '/app/helpers/storage_helper.dart';
import '/config/keys.dart';

class ProgressionService {
  static const int REQUIRED_SCORE = 80; // 80% required to unlock next module

  /// Check if a module is locked based on previous module completion
  static Future<bool> isModuleLocked(Module module, Course course) async {
    if (course.modules == null || course.modules!.isEmpty) return false;
    
    // First module is never locked
    if (module.order == 0 || module.order == 1) {
      return false;
    }

    // Find previous module
    final previousModule = course.modules!.firstWhere(
      (m) => (m.order ?? 0) == (module.order ?? 0) - 1,
      orElse: () => Module(),
    );

    if (previousModule.id == null) return false;

    // Check if previous module is completed and passed with 80%
    final isPreviousCompleted = previousModule.isCompleted == true;
    final previousScore = previousModule.testScore ?? 0;
    final hasPassedPrevious = previousScore >= REQUIRED_SCORE;

    // Module is locked if previous is not completed or didn't pass 80%
    return !isPreviousCompleted || !hasPassedPrevious;
  }

  /// Check if a lesson is locked based on previous lesson completion
  static Future<bool> isLessonLocked(Lesson lesson, Module module) async {
    if (module.lessons == null || module.lessons!.isEmpty) return false;

    // First lesson is never locked
    if (lesson.order == 0 || lesson.order == 1) {
      return false;
    }

    // Find previous lesson
    final previousLesson = module.lessons!.firstWhere(
      (l) => (l.order ?? 0) == (lesson.order ?? 0) - 1,
      orElse: () => Lesson(),
    );

    if (previousLesson.id == null) return false;

    // Lesson is locked if previous lesson is not completed
    return previousLesson.isCompleted != true;
  }

  /// Update module lock status based on progression
  static Future<void> updateModuleLocks(Course course) async {
    if (course.modules == null || course.modules!.isEmpty) return;

    // Sort modules by order
    final sortedModules = List<Module>.from(course.modules!);
    sortedModules.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    for (int i = 0; i < sortedModules.length; i++) {
      final module = sortedModules[i];
      
      // First module is never locked
      if (i == 0) {
        module.isLocked = false;
        continue;
      }

      // Check previous module
      final previousModule = sortedModules[i - 1];
      final isPreviousCompleted = previousModule.isCompleted == true;
      final previousScore = previousModule.testScore ?? 0;
      final hasPassedPrevious = previousScore >= REQUIRED_SCORE;

      module.isLocked = !isPreviousCompleted || !hasPassedPrevious;
    }

    // Save updated modules
    await _saveCourse(course);
  }

  /// Update lesson lock status based on progression
  static Future<void> updateLessonLocks(Module module) async {
    if (module.lessons == null || module.lessons!.isEmpty) return;

    // Sort lessons by order
    final sortedLessons = List<Lesson>.from(module.lessons!);
    sortedLessons.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    for (int i = 0; i < sortedLessons.length; i++) {
      final lesson = sortedLessons[i];
      
      // First lesson is never locked
      if (i == 0) {
        lesson.isLocked = false;
        continue;
      }

      // Check previous lesson
      final previousLesson = sortedLessons[i - 1];
      lesson.isLocked = previousLesson.isCompleted != true;
    }

    // Save updated module
    await _saveModule(module);
  }

  /// Mark lesson as completed and unlock next lesson
  static Future<void> completeLesson(Lesson lesson, Module module, Course course) async {
    lesson.isCompleted = true;
    
    // Update module progress
    final completedCount = (module.lessons ?? [])
        .where((l) => l.isCompleted == true)
        .length;
    module.completedLessons = completedCount;
    module.totalLessons = module.lessons?.length ?? 0;

    // Check if all lessons are completed
    if (module.completedLessons == module.totalLessons) {
      module.isCompleted = true;
    }

    // Update lesson locks
    await updateLessonLocks(module);
    
    // Update module locks
    await updateModuleLocks(course);

    // Save to storage
    await _saveLesson(lesson);
    await _saveModule(module);
    await _saveCourse(course);
  }

  /// Mark module test as passed and unlock next module
  static Future<void> completeModuleTest(Module module, int score, Course course) async {
    module.testScore = score;
    module.testPassed = score >= REQUIRED_SCORE;
    
    if (module.testPassed == true) {
      module.isCompleted = true;
    }

    // Update module locks
    await updateModuleLocks(course);

    // Save to storage
    await _saveModule(module);
    await _saveCourse(course);
  }

  /// Save course to storage
  static Future<void> _saveCourse(Course course) async {
    try {
      // Use safe helper to read courses data
      List<Map<String, dynamic>> courses = [];
      
      try {
        final data = await Keys.courses.read<List>();
        if (data != null) {
          courses = data.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).where((item) => item.isNotEmpty).toList();
        }
      } catch (e) {
        if (!e.toString().contains('-34018')) {
          print("Warning: Error reading courses in progression service: $e");
        }
        final safeData = safeReadCoursesData();
        if (safeData != null) {
          courses = safeData;
        }
      }
      
      if (courses.isEmpty) {
        final safeData = safeReadCoursesData();
        if (safeData != null) {
          courses = safeData;
        }
      }

      final index = courses.indexWhere((c) => c['id'] == course.id);
      if (index >= 0) {
        courses[index] = course.toJson();
      } else {
        courses.add(course.toJson());
      }

      await Keys.courses.save(courses);
    } catch (e) {
      print('Error saving course: $e');
    }
  }

  /// Save module to storage (through course)
  static Future<void> _saveModule(Module module) async {
    // Modules are saved as part of the course, so we don't need separate storage
    // The course save will handle modules
  }

  /// Save lesson to storage (through course/module)
  static Future<void> _saveLesson(Lesson lesson) async {
    // Lessons are saved as part of the module, which is part of the course
    // The course save will handle lessons
  }
}
