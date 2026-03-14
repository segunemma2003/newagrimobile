import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';
import '/app/networking/api_service.dart';
import '/app/services/offline_queue_service.dart';

/// Service for syncing data between local storage and backend
/// Implements offline-first architecture: download all data, refresh when online
class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final OfflineQueueService _queueService = OfflineQueueService();
  final ApiService _apiService = ApiService();

  /// Check if device is online
  Future<bool> isOnline() async {
    return await _queueService.isOnline();
  }

  /// Sync all course data for offline use
  Future<void> syncAllCourseData() async {
    if (!await isOnline()) {
      print('Device is offline, cannot sync course data');
      return;
    }

    try {
      print('Starting full course data sync...');

      // Sync courses
      await _syncCourses();

      // Sync user enrollments
      await _syncEnrollments();

      // Sync certificates
      await _syncCertificates();

      // Sync user profile
      await _syncUserProfile();

      // Update last sync time
      await Keys.lastSyncTime.save(DateTime.now().toIso8601String());

      print('Course data sync completed successfully');
    } catch (e) {
      print('Error syncing course data: $e');
      rethrow;
    }
  }

  /// Sync courses list
  Future<void> _syncCourses() async {
    try {
      final response = await _apiService.fetchCourses();
      final data = response['data'] as List<dynamic>? ?? [];
      
      // Save to local storage
      await Keys.courses.save(data);
      print('Synced ${data.length} courses');
    } catch (e) {
      print('Error syncing courses: $e');
    }
  }

  /// Sync user enrollments
  Future<void> _syncEnrollments() async {
    try {
      final response = await _apiService.fetchMyEnrollments();
      final data = response is List ? response : (response['data'] as List<dynamic>? ?? []);
      
      // Save enrollments (used for checking enrollment status)
      await Keys.courseProgress.save(data);
      print('Synced ${data.length} enrollments');
    } catch (e) {
      print('Error syncing enrollments: $e');
    }
  }

  /// Sync certificates
  Future<void> _syncCertificates() async {
    try {
      final response = await _apiService.fetchUserCertificates();
      final data = response['data'] as List<dynamic>? ?? [];
      
      await Keys.certificates.save(data);
      print('Synced ${data.length} certificates');
    } catch (e) {
      print('Error syncing certificates: $e');
    }
  }

  /// Sync user profile
  Future<void> _syncUserProfile() async {
    try {
      final response = await _apiService.getCurrentUser();
      final userData = response is Map<String, dynamic> ? response : (response['data'] ?? response);
      
      if (userData is Map<String, dynamic>) {
        await Keys.auth.save(userData);
        backpackSave(Keys.auth, userData);
        print('Synced user profile');
      }
    } catch (e) {
      print('Error syncing user profile: $e');
    }
  }

  /// Sync a specific course with all its modules and lessons
  Future<void> syncCourseDetails(String courseId) async {
    if (!await isOnline()) {
      print('Device is offline, cannot sync course details');
      return;
    }

    try {
      // Fetch course details - use course-information endpoint
      final courseResponse = await _apiService.fetchCourseInformation(courseId);
      final courseData = courseResponse['data'] ?? courseResponse;

      // Update course in local courses list
      final courses = await Keys.courses.read<List>() ?? [];
      final coursesList = courses.map((c) {
        if (c is Map<String, dynamic>) return c;
        if (c is Map) return Map<String, dynamic>.from(c);
        return <String, dynamic>{};
      }).where((c) => c.isNotEmpty).toList();

      final courseIndex = coursesList.indexWhere((c) => c['id']?.toString() == courseId);
      if (courseIndex != -1) {
        coursesList[courseIndex] = courseData;
      } else {
        coursesList.add(courseData);
      }

      await Keys.courses.save(coursesList);
      print('Synced course details for course $courseId');
    } catch (e) {
      print('Error syncing course details: $e');
    }
  }

  /// Refresh data when online (lightweight refresh)
  Future<void> refreshDataWhenOnline() async {
    if (!await isOnline()) {
      print('Device is offline, skipping refresh');
      return;
    }

    try {
      // Check last sync time
      final lastSyncStr = await Keys.lastSyncTime.read<String>();
      if (lastSyncStr != null) {
        final lastSync = DateTime.tryParse(lastSyncStr);
        if (lastSync != null) {
          final now = DateTime.now();
          final diff = now.difference(lastSync);
          
          // Only refresh if last sync was more than 5 minutes ago
          if (diff.inMinutes < 5) {
            print('Data is fresh, skipping refresh');
            return;
          }
        }
      }

      // Perform lightweight refresh
      await _syncEnrollments();
      await _syncCertificates();
      await _syncUserProfile();

      // Update last sync time
      await Keys.lastSyncTime.save(DateTime.now().toIso8601String());
      print('Data refresh completed');
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  /// Sync offline queue (process queued API requests)
  Future<void> syncOfflineQueue() async {
    await _queueService.syncQueue();
  }

  /// Initialize sync on app startup
  Future<void> initializeSync() async {
    // Sync offline queue first (process any pending requests)
    await syncOfflineQueue();

    // Then refresh data if online
    await refreshDataWhenOnline();
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final timestamp = await Keys.lastSyncTime.read<String>();
      if (timestamp != null) {
        return DateTime.tryParse(timestamp);
      }
    } catch (e) {
      print('Error reading last sync time: $e');
    }
    return null;
  }

  /// Check if data needs refresh
  Future<bool> needsRefresh() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    final diff = now.difference(lastSync);
    
    // Refresh if last sync was more than 30 minutes ago
    return diff.inMinutes > 30;
  }
}
