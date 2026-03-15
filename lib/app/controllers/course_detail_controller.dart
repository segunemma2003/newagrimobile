import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/networking/api_service.dart';
import '/app/helpers/storage_helper.dart';
import '/config/keys.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CourseDetailController extends NyController {
  Course? course;
  Map<String, bool> completedLessons = {};
  Map<String, bool> completedModules = {};
  Map<String, bool> lockedModules = {};
  Map<String, bool> lockedLessons = {};

  Future<void> loadCourseDetails(String courseId, {bool forceRefresh = false}) async {
    if (await _isOnline()) {
      try {
        // Clear cache if forcing refresh
        if (forceRefresh) {
          try {
            backpackDelete('course_$courseId');
          } catch (e) {
            // Ignore cache deletion errors
          }
        }
        
        dynamic response = await api<ApiService>(
          (request) => request.fetchCourse(courseId),
        );

        if (response != null) {
          // Handle different response formats
          dynamic data;
          if (response is Map<String, dynamic>) {
            data = response['data'] ?? response;
          } else if (response is List && response.isNotEmpty) {
            // If API returns a List directly, find the course by ID
            data = response.firstWhere(
              (item) => item is Map && (item['id']?.toString() == courseId || item['id'] == courseId),
              orElse: () => null,
            );
            if (data == null) {
              print("Course not found in list response");
              return;
            }
          } else {
            data = response;
          }
          
          if (data != null && data is Map) {
            course = Course.fromJson(data as Map<String, dynamic>);
            await _saveCourseToStorage();
            await _loadProgress();
            return;
          }
        }
      } catch (e) {
        print("Error fetching course details from API: $e");
        // If API fails, continue to try loading from storage
      }
    }

    // Try to load from storage if API fails
    try {
      List<Map<String, dynamic>>? coursesJson;
      
      // Try reading from Keys.courses first
      try {
        final data = await Keys.courses.read<List>();
        if (data != null) {
          coursesJson = data.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).where((item) => item.isNotEmpty).toList();
        }
      } catch (e) {
        // If reading fails, try using safe helper
        if (!e.toString().contains('-34018')) {
          print("Warning: Error reading courses from Keys.courses: $e");
        }
        coursesJson = safeReadCoursesData();
      }
      
      // Fallback to safe helper if still null
      if (coursesJson == null) {
        coursesJson = safeReadCoursesData();
      }
      
      if (coursesJson != null && coursesJson.isNotEmpty) {
        final courseData = coursesJson.firstWhere(
          (c) => c['id']?.toString() == courseId,
          orElse: () => <String, dynamic>{},
        );
        if (courseData.isNotEmpty) {
          course = Course.fromJson(courseData);
          await _loadProgress();
        }
      }
    } catch (e) {
      print("Error loading course from storage: $e");
    }
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
      dynamic progressData;
      try {
        progressData = await Keys.courseProgress.read<List>();
      } catch (e) {
        // If reading fails due to FormatException, try to handle it
        if (e.toString().contains('FormatException') || e.toString().contains('Unexpected character')) {
          print('Warning: Progress data may be corrupted, skipping...');
          return;
        }
        rethrow;
      }
      
      if (progressData != null && progressData is List) {
        final progressList = progressData.map((json) {
          if (json is Map<String, dynamic>) {
            return json;
          } else if (json is Map) {
            return Map<String, dynamic>.from(json);
          }
          return <String, dynamic>{};
        }).where((item) => item.isNotEmpty).toList();

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
      _updateModuleLocking();
    } catch (e) {
      print("Error loading progress: $e");
    }
  }

  void _updateModuleLocking() {
    if (course == null || course!.modules == null) return;

    lockedModules.clear();
    lockedLessons.clear();

    if (course!.modules!.isNotEmpty) {
      lockedModules[course!.modules![0].id!] = false;
    }

    for (int i = 1; i < course!.modules!.length; i++) {
      final previousModule = course!.modules![i - 1];
      final currentModule = course!.modules![i];

      final prevCompleted = completedModules[previousModule.id!] ??
          previousModule.isCompleted == true ||
              _isModuleFullyCompleted(previousModule);

      lockedModules[currentModule.id!] = !prevCompleted;

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
    final completedCount =
        module.lessons!.where((l) => completedLessons[l.id!] == true).length;

    return completedCount == totalLessons;
  }

  bool isModuleLocked(String moduleId) {
    return lockedModules[moduleId] ?? false;
  }

  bool isLessonLocked(String lessonId, String moduleId) {
    if (lockedModules[moduleId] == true) {
      return true;
    }

    if (course?.modules != null) {
      final module = course!.modules!.firstWhere(
        (m) => m.id == moduleId,
        orElse: () => Module(),
      );

      if (module.lessons != null) {
        final lessonIndex = module.lessons!.indexWhere((l) => l.id == lessonId);
        if (lessonIndex > 0) {
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

      progressList.removeWhere(
        (p) => p['course_id'] == course!.id && p['lesson_id'] == lessonId,
      );

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

      if (course!.modules != null) {
        for (final module in course!.modules!) {
          if (module.lessons != null) {
            final moduleLessons = module.lessons!;
            final allCompleted = moduleLessons.every(
              (l) => completedLessons[l.id!] == true,
            );

            if (allCompleted && (completedModules[module.id!] != true)) {
              completedModules[module.id!] = true;
              final moduleProgress = {
                'user_id': userData?['id']?.toString(),
                'course_id': course!.id,
                'module_id': module.id,
                'is_completed': true,
                'completed_at': DateTime.now().toIso8601String(),
              };
              progressList.add(moduleProgress);
              await Keys.courseProgress.save(progressList);
              _updateModuleLocking();
            }
          }
        }
      }

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
