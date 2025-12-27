import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/models/category.dart';
import '/app/models/lesson.dart';
import '/app/networking/api_service.dart';
import '/app/services/dummy_data_service.dart';
import '/app/services/video_download_service.dart';
import '/config/keys.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CoursesController extends NyController {
  List<Course> courses = [];
  List<Category> categories = [];

  Future<void> loadCourses() async {
    // Load from local storage first
    await _loadCoursesFromStorage();

    // Try to sync if online
    if (await _isOnline()) {
      await syncCourses();
    }
  }

  Future<void> _loadCoursesFromStorage() async {
    try {
      final coursesJson = await Keys.courses.read<List>();
      if (coursesJson != null && coursesJson.isNotEmpty) {
        courses = coursesJson
            .map((json) => Course.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Load dummy data if storage is empty
        courses = DummyDataService.getDummyCourses();
        try {
          await Keys.courses.save(courses.map((c) => c.toJson()).toList());
        } catch (e) {
          // Suppress error logging for Keychain issues on simulator
          if (!e.toString().contains('-34018')) {
            print("Warning: Failed to save courses to storage: $e");
          }
        }
      }
    } catch (e) {
      print("Error loading courses from storage: $e");
      // Fallback to dummy data
      courses = DummyDataService.getDummyCourses();
    }
  }

  Future<void> loadCategories() async {
    try {
      // Load from local storage first
      final categoriesJson = await Keys.categories.read<List>();
      if (categoriesJson != null) {
        categories = categoriesJson
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Try to fetch from API if online
      if (await _isOnline()) {
        try {
          Map<String, dynamic>? response = await api<ApiService>(
            (request) => request.fetchCategories(),
          );

          if (response != null && response['data'] != null) {
            final List<dynamic> data = response['data'] is List
                ? response['data']
                : [response['data']];
            categories = data.map((json) => Category.fromJson(json)).toList();
            try {
              await Keys.categories.save(categories.map((c) => c.toJson()).toList());
            } catch (e) {
              // Suppress error logging for Keychain issues on simulator
              if (!e.toString().contains('-34018')) {
                print("Warning: Failed to save categories to storage: $e");
              }
            }
            return;
          }
        } catch (e) {
          print("Error fetching categories from API: $e - Using dummy data");
        }
      }

      // Fallback to dummy data if API fails or offline
      if (categories.isEmpty) {
        categories = DummyDataService.getDummyCategories();
        try {
          await Keys.categories.save(categories.map((c) => c.toJson()).toList());
        } catch (e) {
          print("Warning: Failed to save categories to storage: $e");
        }
      }
    } catch (e) {
      print("Error loading categories: $e");
      // Final fallback to dummy data
      categories = DummyDataService.getDummyCategories();
    }
  }

  Future<void> syncCourses() async {
    if (!await _isOnline()) {
      print("No Internet: Cannot sync courses. Please check your connection.");
      return;
    }

    try {
      print("Syncing courses...");

      Map<String, dynamic>? response = await api<ApiService>(
        (request) => request.fetchCourses(),
      );

      if (response != null && response['data'] != null) {
        final List<dynamic> data =
            response['data'] is List ? response['data'] : [response['data']];
        courses = data.map((json) => Course.fromJson(json)).toList();

        // Save to local storage
        try {
          await Keys.courses.save(courses.map((c) => c.toJson()).toList());
          await Keys.lastSyncTime.save(DateTime.now().toIso8601String());
        } catch (e) {
          // Suppress error logging for Keychain issues on simulator
          if (!e.toString().contains('-34018')) {
            print("Warning: Failed to save courses to storage: $e");
          }
        }

        // Download course videos in background
        _downloadCourseVideos();

        print("Synced: Courses updated successfully");
        return;
      }
    } catch (e) {
      print("Sync Failed: $e - Using dummy data");
    }

    // Fallback to dummy data if API fails
    courses = DummyDataService.getDummyCourses();
    try {
      await Keys.courses.save(courses.map((c) => c.toJson()).toList());
    } catch (e) {
      print("Warning: Failed to save courses to storage: $e");
    }
    print("Using dummy courses data for testing");
  }

  Future<void> _downloadCourseVideos() async {
    // Download videos in background for offline access
    final downloadService = VideoDownloadService();
    List<Lesson> allLessons = [];
    
    for (final course in courses) {
      if (course.lessons != null) {
        allLessons.addAll(course.lessons!);
      }
    }
    
    // Download all videos in background (non-blocking)
    downloadService.downloadVideosInBackground(allLessons);
  }

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> logout() async {
    try {
      await Keys.auth.save(null);
      await Keys.bearerToken.save(null);
      } catch (e) {
        // Suppress error logging for Keychain issues on simulator
        if (!e.toString().contains('-34018')) {
          print("Warning: Failed to clear auth data from storage: $e");
        }
      }
    // Clear from Backpack as well
    backpackDelete(Keys.auth);
    backpackDelete(Keys.bearerToken);
    routeTo("/login");
  }
}

