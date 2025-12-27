import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/networking/api_service.dart';
import '/app/services/dummy_data_service.dart';
import '/config/keys.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CourseDetailController extends NyController {
  Course? course;
  Map<String, bool> completedLessons = {};
  Map<String, bool> completedModules = {};
  Map<String, bool> lockedModules = {};
  Map<String, bool> lockedLessons = {};

  Future<void> loadCourseDetails(String courseId) async {
    // Always load full course details with modules from dummy data
    // This ensures modules are always available
    final dummyData = DummyDataService.getDummyCourseDetails(int.tryParse(courseId) ?? 1);
    course = Course.fromJson(dummyData);
    
    // Try to sync if online (for real API)
    if (await _isOnline()) {
      try {
        Map<String, dynamic>? response = await api<ApiService>(
          (request) => request.fetchCourse(courseId),
        );

        if (response != null) {
          final data = response['data'] ?? response;
          course = Course.fromJson(data);
          await _saveCourseToStorage();
          await _loadProgress();
          return;
        }
      } catch (e) {
        print("Error fetching course details from API: $e - Using dummy data");
      }
    }

    // Save the dummy data course with modules to storage
    await _saveCourseToStorage();

    // Load progress
    await _loadProgress();
  }

  Future<void> _saveCourseToStorage() async {
    if (course == null) return;

    try {
      final coursesJson = await Keys.courses.read<List>();
      List<Map<String, dynamic>> courses = [];
      if (coursesJson != null) {
        courses = List<Map<String, dynamic>>.from(coursesJson);
      }

      final index = courses.indexWhere((c) => c['id'] == course!.id);
      if (index >= 0) {
        courses[index] = course!.toJson();
      } else {
        courses.add(course!.toJson());
      }

      await Keys.courses.save(courses);
    } catch (e) {
      print("Error saving course to storage: $e");
    }
  }

  Future<void> _loadProgress() async {
    if (course == null) return;

    try {
      final progressJson = await Keys.courseProgress.read<List>();
      if (progressJson != null) {
        final progressList = progressJson
            .map((json) => json as Map<String, dynamic>)
            .toList();

        for (final progress in progressList) {
          if (progress['course_id'] == course!.id) {
            if (progress['is_completed'] == true) {
              if (progress['lesson_id'] != null) {
                completedLessons[progress['lesson_id']] = true;
              }
              if (progress['module_id'] != null) {
                completedModules[progress['module_id']] = true;
              }
            }
          }
        }
      }

      // Calculate module locking based on completion
      _updateModuleLocking();
    } catch (e) {
      print("Error loading progress: $e");
    }
  }

  void _updateModuleLocking() {
    if (course == null || course!.modules == null) return;

    lockedModules.clear();
    lockedLessons.clear();

    // First module is never locked
    if (course!.modules!.isNotEmpty) {
      lockedModules[course!.modules![0].id!] = false;
    }

    // Check each module - lock if previous module is not completed
    for (int i = 1; i < course!.modules!.length; i++) {
      final previousModule = course!.modules![i - 1];
      final currentModule = course!.modules![i];

      // Check if previous module is completed
      final prevCompleted = completedModules[previousModule.id!] ?? 
                            previousModule.isCompleted == true ||
                            _isModuleFullyCompleted(previousModule);

      lockedModules[currentModule.id!] = !prevCompleted;

      // Lock all lessons in locked modules
      if (lockedModules[currentModule.id!] == true) {
        if (currentModule.lessons != null) {
          for (final lesson in currentModule.lessons!) {
            lockedLessons[lesson.id!] = true;
          }
        }
      }
    }
  }

  bool _isModuleFullyCompleted(Module module) {
    if (module.lessons == null || module.lessons!.isEmpty) return false;
    
    final totalLessons = module.lessons!.length;
    final completedCount = module.lessons!
        .where((l) => completedLessons[l.id!] == true)
        .length;
    
    return completedCount == totalLessons;
  }

  bool isModuleLocked(String moduleId) {
    return lockedModules[moduleId] ?? false;
  }

  bool isLessonLocked(String lessonId, String moduleId) {
    // Lesson is locked if its module is locked
    if (lockedModules[moduleId] == true) {
      return true;
    }
    
    // Check if previous lessons in the same module are completed
    if (course?.modules != null) {
      final module = course!.modules!.firstWhere(
        (m) => m.id == moduleId,
        orElse: () => Module(),
      );
      
      if (module.lessons != null) {
        final lessonIndex = module.lessons!.indexWhere((l) => l.id == lessonId);
        if (lessonIndex > 0) {
          // Check if previous lesson is completed
          final previousLesson = module.lessons![lessonIndex - 1];
          return !(completedLessons[previousLesson.id!] ?? false);
        }
      }
    }
    
    return lockedLessons[lessonId] ?? false;
  }

  bool isLessonCompleted(String lessonId) {
    return completedLessons[lessonId] ?? false;
  }

  Future<void> markLessonCompleted(String lessonId) async {
    if (course == null) return;

    completedLessons[lessonId] = true;

    try {
      final progressJson = await Keys.courseProgress.read<List>();
      List<Map<String, dynamic>> progressList = [];
      if (progressJson != null) {
        progressList = List<Map<String, dynamic>>.from(progressJson);
      }

      // Remove existing progress for this lesson
      progressList.removeWhere(
        (p) => p['course_id'] == course!.id && p['lesson_id'] == lessonId,
      );

      // Add new progress
      final userData = await Keys.auth.read<Map<String, dynamic>>();
      progressList.add({
        'user_id': userData?['id']?.toString(),
        'course_id': course!.id,
        'lesson_id': lessonId,
        'is_completed': true,
        'progress': 100,
        'completed_at': DateTime.now().toIso8601String(),
      });

      await Keys.courseProgress.save(progressList);

      // Update module completion if this was the last lesson in a module
      if (course!.modules != null) {
        for (final module in course!.modules!) {
          if (module.lessons != null) {
            final moduleLessons = module.lessons!;
            final allCompleted = moduleLessons.every(
              (l) => completedLessons[l.id!] == true,
            );
            
            if (allCompleted && (completedModules[module.id!] != true)) {
              completedModules[module.id!] = true;
              // Save module completion
              final moduleProgress = {
                'user_id': userData?['id']?.toString(),
                'course_id': course!.id,
                'module_id': module.id,
                'is_completed': true,
                'completed_at': DateTime.now().toIso8601String(),
              };
              progressList.add(moduleProgress);
              await Keys.courseProgress.save(progressList);
              
              // Unlock next module
              _updateModuleLocking();
            }
          }
        }
      }

      // Update course completed lessons count
      if (course!.modules != null) {
        int total = 0;
        int completed = 0;
        for (final module in course!.modules!) {
          if (module.lessons != null) {
            total += module.lessons!.length;
            completed += module.lessons!
                .where((l) => completedLessons[l.id!] == true)
                .length;
          }
        }
        course!.completedLessons = completed;
        course!.totalLessons = total;
        course!.isCompleted = completed == total;
      } else if (course!.lessons != null) {
        final completedCount = course!.lessons!
            .where((l) => completedLessons[l.id] == true)
            .length;
        course!.completedLessons = completedCount;
        course!.isCompleted = completedCount == course!.lessons!.length;
      }
      
      await _saveCourseToStorage();

      // Sync to server if online
      if (await _isOnline()) {
        try {
          await api<ApiService>(
            (request) => request.syncProgress({
              'course_id': course!.id,
              'lesson_id': lessonId,
              'is_completed': true,
            }),
          );
        } catch (e) {
          print("Error syncing progress: $e");
        }
      }
    } catch (e) {
      print("Error marking lesson completed: $e");
    }
  }

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}

