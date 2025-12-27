import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/lesson.dart';
import '/app/networking/api_service.dart';
import '/config/keys.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for downloading and managing video files locally
class VideoDownloadService {
  static final VideoDownloadService _instance = VideoDownloadService._internal();
  factory VideoDownloadService() => _instance;
  VideoDownloadService._internal();

  // Download progress tracking
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, String> _downloadErrors = {};

  /// Get download progress for a video
  double? getDownloadProgress(String videoUrl) {
    return _downloadProgress[videoUrl];
  }

  /// Check if video is currently downloading
  bool isDownloading(String videoUrl) {
    return _isDownloading[videoUrl] ?? false;
  }

  /// Get download error if any
  String? getDownloadError(String videoUrl) {
    return _downloadErrors[videoUrl];
  }

  /// Get local video directory
  Future<Directory> _getVideoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }

  /// Get local file path for a video
  Future<String> getLocalVideoPath(String videoUrl, String lessonId) async {
    final videoDir = await _getVideoDirectory();
    final fileName = 'lesson_${lessonId}_${videoUrl.split('/').last}';
    // Clean filename
    final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
    return '${videoDir.path}/$cleanFileName';
  }

  /// Check if video is downloaded locally
  Future<bool> isVideoDownloaded(String videoUrl, String lessonId) async {
    try {
      final localPath = await getLocalVideoPath(videoUrl, lessonId);
      final file = File(localPath);
      return await file.exists();
    } catch (e) {
      print("Error checking video download: $e");
      return false;
    }
  }

  /// Get local video file if exists
  Future<File?> getLocalVideoFile(String videoUrl, String lessonId) async {
    try {
      final localPath = await getLocalVideoPath(videoUrl, lessonId);
      final file = File(localPath);
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print("Error getting local video file: $e");
    }
    return null;
  }

  /// Download video in background
  Future<String?> downloadVideo({
    required String videoUrl,
    required String lessonId,
    Function(double progress)? onProgress,
    Function(String? error)? onError,
    Function(String? path)? onComplete,
  }) async {
    // Check if already downloading
    if (_isDownloading[videoUrl] == true) {
      print("Video already downloading: $videoUrl");
      return null;
    }

    // Check if already downloaded
    if (await isVideoDownloaded(videoUrl, lessonId)) {
      final localPath = await getLocalVideoPath(videoUrl, lessonId);
      onComplete?.call(localPath);
      return localPath;
    }

    // Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      final error = "No internet connection. Cannot download video.";
      _downloadErrors[videoUrl] = error;
      onError?.call(error);
      return null;
    }

    try {
      _isDownloading[videoUrl] = true;
      _downloadErrors.remove(videoUrl);
      _downloadProgress[videoUrl] = 0.0;

      final localPath = await getLocalVideoPath(videoUrl, lessonId);
      final file = File(localPath);

      // Create parent directory if needed
      await file.parent.create(recursive: true);

      // Download using Dio with progress tracking
      final apiService = ApiService();
      await apiService.downloadVideo(
        videoUrl, 
        localPath,
        onProgress: (count, total) {
          final progress = count / total;
          _downloadProgress[videoUrl] = progress;
          onProgress?.call(progress);
        },
      );

      // Update progress
      _downloadProgress[videoUrl] = 1.0;
      _isDownloading[videoUrl] = false;

      // Update lesson with local path
      await _updateLessonVideoPath(lessonId, localPath);

      onComplete?.call(localPath);
      return localPath;
    } catch (e) {
      final error = "Failed to download video: $e";
      _downloadErrors[videoUrl] = error;
      _isDownloading[videoUrl] = false;
      _downloadProgress.remove(videoUrl);
      onError?.call(error);
      print(error);
      return null;
    }
  }

  /// Download multiple videos in background
  Future<void> downloadVideosInBackground(List<Lesson> lessons) async {
    for (final lesson in lessons) {
      if (lesson.type == 'video' && 
          lesson.videoUrl != null && 
          lesson.videoUrl!.isNotEmpty &&
          lesson.id != null) {
        
        // Skip if already downloaded
        if (await isVideoDownloaded(lesson.videoUrl!, lesson.id!)) {
          continue;
        }

        // Download in background (don't await to allow parallel downloads)
        downloadVideo(
          videoUrl: lesson.videoUrl!,
          lessonId: lesson.id!,
          onProgress: (progress) {
            print("Downloading ${lesson.title}: ${(progress * 100).toStringAsFixed(0)}%");
          },
          onError: (error) {
            print("Error downloading ${lesson.title}: $error");
          },
          onComplete: (path) {
            print("Downloaded ${lesson.title} to $path");
          },
        );
      }
    }
  }

  /// Update lesson video path in storage
  Future<void> _updateLessonVideoPath(String lessonId, String localPath) async {
    try {
      // Load all courses
      final coursesJson = await Keys.courses.read<List>();
      if (coursesJson != null) {
        List<Map<String, dynamic>> courses = 
            List<Map<String, dynamic>>.from(coursesJson);

        // Find and update lesson in courses
        for (var course in courses) {
          if (course['lessons'] != null) {
            final lessons = List<Map<String, dynamic>>.from(course['lessons']);
            for (var lesson in lessons) {
              if (lesson['id']?.toString() == lessonId) {
                lesson['video_path'] = localPath;
                break;
              }
            }
            course['lessons'] = lessons;
          }
        }

        // Save updated courses
        await Keys.courses.save(courses);
      }
    } catch (e) {
      print("Error updating lesson video path: $e");
    }
  }

  /// Delete downloaded video
  Future<bool> deleteVideo(String videoUrl, String lessonId) async {
    try {
      final localPath = await getLocalVideoPath(videoUrl, lessonId);
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        
        // Update lesson to remove video path
        await _updateLessonVideoPath(lessonId, '');
        
        _downloadProgress.remove(videoUrl);
        _downloadErrors.remove(videoUrl);
        return true;
      }
    } catch (e) {
      print("Error deleting video: $e");
    }
    return false;
  }

  /// Get total size of downloaded videos
  Future<int> getTotalDownloadSize() async {
    try {
      final videoDir = await _getVideoDirectory();
      int totalSize = 0;
      
      await for (final entity in videoDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      print("Error calculating download size: $e");
      return 0;
    }
  }

  /// Clear all downloaded videos
  Future<void> clearAllDownloads() async {
    try {
      final videoDir = await _getVideoDirectory();
      if (await videoDir.exists()) {
        await videoDir.delete(recursive: true);
        await videoDir.create(recursive: true);
        
        // Clear all video paths from lessons
        final coursesJson = await Keys.courses.read<List>();
        if (coursesJson != null) {
          List<Map<String, dynamic>> courses = 
              List<Map<String, dynamic>>.from(coursesJson);

          for (var course in courses) {
            if (course['lessons'] != null) {
              final lessons = List<Map<String, dynamic>>.from(course['lessons']);
              for (var lesson in lessons) {
                lesson['video_path'] = '';
              }
              course['lessons'] = lessons;
            }
          }

          await Keys.courses.save(courses);
        }
        
        _downloadProgress.clear();
        _downloadErrors.clear();
      }
    } catch (e) {
      print("Error clearing downloads: $e");
    }
  }
}

