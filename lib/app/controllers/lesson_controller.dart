import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/lesson.dart';
import '/app/networking/api_service.dart';
import '/config/keys.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LessonController extends NyController {
  Lesson? lesson;

  Future<void> loadLesson(Lesson lessonData) async {
    lesson = lessonData;
  }

  Future<void> markLessonCompleted(String lessonId) async {
    try {
      final progressJson = await Keys.courseProgress.read<List>();
      List<Map<String, dynamic>> progressList = [];
      if (progressJson != null) {
        progressList = List<Map<String, dynamic>>.from(progressJson);
      }

      // Remove existing progress for this lesson
      progressList.removeWhere(
        (p) => p['lesson_id'] == lessonId,
      );

      // Add new progress
      final userData = await Keys.auth.read<Map<String, dynamic>>();
      progressList.add({
        'user_id': userData?['id']?.toString(),
        'lesson_id': lessonId,
        'is_completed': true,
        'progress': 100,
        'completed_at': DateTime.now().toIso8601String(),
      });

      await Keys.courseProgress.save(progressList);

      // Sync to server if online
      if (await _isOnline()) {
        try {
          await api<ApiService>(
            (request) => request.syncProgress({
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

