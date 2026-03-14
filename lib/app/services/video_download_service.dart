import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/lesson.dart';
import '/app/networking/api_service.dart';
import '/app/helpers/storage_helper.dart';
import '/config/keys.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for downloading and managing video files locally
/// Uses youtube_explode_dart for YouTube videos and Dio for foreground downloads
class VideoDownloadService {
  static final VideoDownloadService _instance =
      VideoDownloadService._internal();
  factory VideoDownloadService() => _instance;
  VideoDownloadService._internal();

  // Download progress tracking
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, String> _downloadErrors = {};

  /// Check if URL is a YouTube URL
  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('youtube-nocookie.com');
  }

  /// Extract YouTube video ID from URL
  String? _extractYouTubeId(String url) {
    try {
      final uri = Uri.parse(url);

      // Handle youtu.be short URLs
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }

      // Handle youtube.com URLs
      if (uri.host.contains('youtube.com')) {
        // Standard watch URLs: ?v=VIDEO_ID
        if (uri.queryParameters.containsKey('v')) {
          return uri.queryParameters['v'];
        }

        // Embed URLs: /embed/VIDEO_ID
        if (uri.pathSegments.contains('embed')) {
          final embedIndex = uri.pathSegments.indexOf('embed');
          if (embedIndex >= 0 && embedIndex < uri.pathSegments.length - 1) {
            return uri.pathSegments[embedIndex + 1];
          }
        }

        // Short URLs: /VIDEO_ID
        if (uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.last;
        }
      }

      // If URL is just a video ID
      if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
        return url;
      }

      return null;
    } catch (e) {
      print("Error extracting YouTube ID: $e");
      return null;
    }
  }

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

    String fileName;
    if (_isYouTubeUrl(videoUrl)) {
      final videoId = _extractYouTubeId(videoUrl) ?? 'unknown';
      fileName = 'lesson_${lessonId}_youtube_$videoId.mp4';
    } else {
      fileName = 'lesson_${lessonId}_${videoUrl.split('/').last}';
      // Ensure .mp4 extension if missing
      if (!fileName.endsWith('.mp4') &&
          !fileName.endsWith('.mov') &&
          !fileName.endsWith('.avi')) {
        fileName = '$fileName.mp4';
      }
    }

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

  /// Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // Try manage external storage for Android 11+
      final manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    }
    return true; // iOS doesn't need explicit permission for app documents
  }

  /// Download YouTube video using youtube_explode_dart
  Future<String?> _downloadYouTubeVideo({
    required String videoUrl,
    required String lessonId,
    required String localPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      final videoId = _extractYouTubeId(videoUrl);
      if (videoId == null) {
        throw Exception(
            "Could not extract YouTube video ID from URL: $videoUrl");
      }

      final yt = YoutubeExplode();

      // Get video manifest
      final manifest = await yt.videos.streamsClient.getManifest(videoId);

      // Get best quality video stream (prefer mp4)
      final videoStream = manifest.videoOnly
          .where((s) => s.container.name == 'mp4')
          .sortByVideoQuality()
          .firstOrNull;

      if (videoStream == null) {
        throw Exception("No video stream available for this YouTube video");
      }

      // If we have both video and audio, we need to merge them
      // For simplicity, we'll use the best combined stream if available
      final combinedStream = manifest.muxed.sortByVideoQuality().lastOrNull;

      final streamToDownload = combinedStream ?? videoStream;
      final streamUrl = streamToDownload.url.toString();

      yt.close();

      // Download using Dio (foreground, non-background) to prevent app hanging
      final apiService = ApiService();
      await apiService.downloadVideo(
        streamUrl,
        localPath,
        onProgress: (count, total) {
          final progress = count / total;
          _downloadProgress[videoUrl] = progress;
          onProgress?.call(progress);
        },
      );

      return localPath;
    } catch (e) {
      print("Error downloading YouTube video: $e");
      rethrow;
    }
  }

  /// Download non-YouTube video using Dio (foreground only - non-background)
  Future<String?> _downloadRegularVideo({
    required String videoUrl,
    required String lessonId,
    required String localPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Use Dio directly for foreground downloads (prevents app hanging)
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
      return localPath;
    } catch (e) {
      print("Error downloading regular video: $e");
      rethrow;
    }
  }

  /// Download video (foreground only - non-blocking but visible)
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

    // Request storage permission
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      final error = "Storage permission denied. Cannot download video.";
      _downloadErrors[videoUrl] = error;
      onError?.call(error);
      return null;
    }

    try {
      _isDownloading[videoUrl] = true;
      _downloadErrors.remove(videoUrl);
      _downloadProgress[videoUrl] = 0.0;

      final localPath = await getLocalVideoPath(videoUrl, lessonId);

      // Create parent directory if needed
      final file = File(localPath);
      await file.parent.create(recursive: true);

      String? downloadedPath;

      // Download based on video type
      if (_isYouTubeUrl(videoUrl)) {
        downloadedPath = await _downloadYouTubeVideo(
          videoUrl: videoUrl,
          lessonId: lessonId,
          localPath: localPath,
          onProgress: onProgress,
        );
      } else {
        downloadedPath = await _downloadRegularVideo(
          videoUrl: videoUrl,
          lessonId: lessonId,
          localPath: localPath,
          onProgress: onProgress,
        );
      }

      // Update progress
      _downloadProgress[videoUrl] = 1.0;
      _isDownloading[videoUrl] = false;

      // Update lesson with local path
      if (downloadedPath != null) {
        await _updateLessonVideoPath(lessonId, downloadedPath);
      }

      onComplete?.call(downloadedPath);
      return downloadedPath;
    } catch (e) {
      final error = "Failed to download video: $e";
      _downloadErrors[videoUrl] = error;
      _isDownloading[videoUrl] = false;
      _downloadProgress.remove(videoUrl);
      _downloadTaskIds.remove(videoUrl);
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
            print(
                "Downloading ${lesson.title}: ${(progress * 100).toStringAsFixed(0)}%");
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
      // Load all courses using safe helper
      List<Map<String, dynamic>> courses = [];

      try {
        final data = await Keys.courses.read<List>();
        if (data != null) {
          courses = data
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              })
              .where((item) => item.isNotEmpty)
              .toList();
        }
      } catch (e) {
        if (!e.toString().contains('-34018')) {
          print("Warning: Error reading courses in video download service: $e");
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

      if (courses.isNotEmpty) {
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

        // Cancel download task if exists
        final taskId = _downloadTaskIds[videoUrl];
        if (taskId != null) {
          await FlutterDownloader.remove(
              taskId: taskId, shouldDeleteContent: true);
          _downloadTaskIds.remove(videoUrl);
        }

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
        List<Map<String, dynamic>> courses = [];

        try {
          final data = await Keys.courses.read<List>();
          if (data != null) {
            courses = data
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return item;
                  } else if (item is Map) {
                    return Map<String, dynamic>.from(item);
                  }
                  return <String, dynamic>{};
                })
                .where((item) => item.isNotEmpty)
                .toList();
          }
        } catch (e) {
          if (!e.toString().contains('-34018')) {
            print("Warning: Error reading courses in clear cache: $e");
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

        if (courses.isNotEmpty) {
          for (var course in courses) {
            if (course['lessons'] != null) {
              final lessons =
                  List<Map<String, dynamic>>.from(course['lessons']);
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
        _downloadTaskIds.clear();
      }
    } catch (e) {
      print("Error clearing downloads: $e");
    }
  }
}
