import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/lesson.dart';
import '/app/models/course.dart';
import '/app/controllers/lesson_controller.dart';
import '/app/services/video_download_service.dart';
import '/resources/widgets/safearea_widget.dart';
import '/resources/pages/quiz_page.dart';
import '/bootstrap/extensions.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LessonDetailPage extends NyStatefulWidget<LessonController> {
  static RouteView path = ("/lesson-detail", (_) => LessonDetailPage());

  LessonDetailPage({super.key}) : super(child: () => _LessonDetailPageState());
}

class _LessonDetailPageState extends NyPage<LessonDetailPage> {
  Lesson? lesson;
  Course? course;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  final VideoDownloadService _downloadService = VideoDownloadService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isDownloaded = false;
  bool _hasWatchedVideo = false;
  double _videoWatchProgress = 0.0;
  bool _showTranscript = false;

  @override
  get init => () async {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          lesson = data['lesson'] as Lesson?;
          course = data['course'] as Course?;
        }
        if (lesson != null) {
          await widget.controller.loadLesson(lesson!);
          if (lesson!.type == 'video' && lesson!.videoUrl != null) {
            // Check if video is downloaded
            _isDownloaded = await _downloadService.isVideoDownloaded(
              lesson!.videoUrl!,
              lesson!.id ?? '',
            );
            await _initializeVideo();
          }
        }
      };

  Future<void> _initializeVideo() async {
    try {
      String? videoPath;

      // First, try to get local video file
      if (lesson!.id != null && lesson!.videoUrl != null) {
        final localFile = await _downloadService.getLocalVideoFile(
          lesson!.videoUrl!,
          lesson!.id!,
        );
        if (localFile != null) {
          videoPath = localFile.path;
        }
      }

      // Fallback to stored path
      if (videoPath == null &&
          lesson!.videoPath != null &&
          lesson!.videoPath!.isNotEmpty) {
        final file = File(lesson!.videoPath!);
        if (await file.exists()) {
          videoPath = lesson!.videoPath;
        }
      }

      // Use local video if available, otherwise use network URL (only if online)
      if (videoPath != null) {
        _videoController = VideoPlayerController.file(File(videoPath));
      } else if (lesson!.videoUrl != null && lesson!.videoUrl!.isNotEmpty) {
        // Check if online before trying network video
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(lesson!.videoUrl!),
          );
        } else {
          // Offline and no local video
          setState(() {
            _isVideoInitialized = false;
          });
          return;
        }
      } else {
        return; // No video available
      }

      await _videoController!.initialize();

      // Listen to video position to track watch progress
      _videoController!.addListener(_onVideoPositionChanged);

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print("Error initializing video: $e");
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  Future<void> _downloadVideo() async {
    if (lesson == null || lesson!.videoUrl == null || lesson!.id == null) {
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    await _downloadService.downloadVideo(
      videoUrl: lesson!.videoUrl!,
      lessonId: lesson!.id!,
      onProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
      onError: (error) {
        setState(() {
          _isDownloading = false;
        });
        print("Download Failed: ${error ?? "Failed to download video"}");
      },
      onComplete: (path) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
          _downloadProgress = 1.0;
        });
        showToastSuccess(
          title: "Download Complete",
          description: "Video downloaded successfully",
        );
        // Reinitialize video with local file
        _initializeVideo();
      },
    );
  }

  void _onVideoPositionChanged() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;

      if (duration.inSeconds > 0) {
        final progress = position.inSeconds / duration.inSeconds;
        setState(() {
          _videoWatchProgress = progress;
          // Consider video watched if user watched at least 95% of it
          _hasWatchedVideo = progress >= 0.95;
        });
      }
    }
  }

  Future<void> _deleteDownloadedVideo() async {
    if (lesson == null || lesson!.videoUrl == null || lesson!.id == null) {
      return;
    }

    final deleted = await _downloadService.deleteVideo(
      lesson!.videoUrl!,
      lesson!.id!,
    );

    if (deleted) {
      setState(() {
        _isDownloaded = false;
        lesson!.videoPath = null;
      });
      showToastSuccess(
        title: "Deleted",
        description: "Video deleted successfully",
      );
      // Reinitialize video
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoPositionChanged);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "Lesson",
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: Text("Lesson not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          lesson!.title ?? "Lesson",
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeAreaWidget(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson!.title ?? "Untitled Lesson",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).displayLarge(color: context.color.primaryAccent),
              const SizedBox(height: 8),
              if (lesson!.description != null)
                Text(
                  lesson!.description!,
                  style: const TextStyle(fontSize: 16),
                ).bodyLarge(color: context.color.content),
              const SizedBox(height: 24),
              _buildLessonContent(context),
              const SizedBox(height: 24),
              // Transcript section for video lessons
              if (lesson!.type == 'video' &&
                  lesson!.transcript != null &&
                  lesson!.transcript!.isNotEmpty)
                _buildTranscriptSection(context),
              const SizedBox(height: 24),
              if (lesson!.type == 'quiz' && lesson!.quizzes != null)
                _buildQuizSection(context),
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context) {
    switch (lesson!.type) {
      case 'video':
        return _buildVideoPlayer(context);
      case 'diy':
        return _buildDIYContent(context);
      default:
        return _buildWriteupContent(context);
    }
  }

  Widget _buildVideoPlayer(BuildContext context) {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        height: 200,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _isDownloading
                    ? "Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%"
                    : "Loading video...",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 48,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
              ),
            ],
          ),
        ),
        // Download controls
        if (lesson!.videoUrl != null && lesson!.videoUrl!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: context.color.surfaceBackground,
            child: Row(
              children: [
                if (_isDownloaded)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text("Downloaded",
                            style: TextStyle(fontSize: 12)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _deleteDownloadedVideo,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text("Delete"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: _isDownloading
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(value: _downloadProgress),
                              const SizedBox(height: 4),
                              Text(
                                "Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          )
                        : TextButton.icon(
                            onPressed: _downloadVideo,
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text("Download for Offline"),
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWriteupContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lesson!.content ?? "No content available",
        style: const TextStyle(fontSize: 16, height: 1.6),
      ).bodyLarge(color: context.color.surfaceContent),
    );
  }

  Widget _buildDIYContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                "DIY Activity",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ).titleLarge(color: Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lesson!.content ?? "No DIY instructions available",
            style: const TextStyle(fontSize: 16, height: 1.6),
          ).bodyLarge(color: context.color.surfaceContent),
        ],
      ),
    );
  }

  Widget _buildQuizSection(BuildContext context) {
    if (lesson!.quizzes == null || lesson!.quizzes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () {
        routeTo(QuizPage.path, data: {
          "lesson": lesson,
          "course": course,
        });
      },
      icon: const Icon(Icons.quiz),
      label: const Text("Take Quiz"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildTranscriptSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showTranscript = !_showTranscript;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined,
                      color: Color(0xFF2D8659)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Transcript",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Icon(
                    _showTranscript ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF2D8659),
                  ),
                ],
              ),
            ),
          ),
          if (_showTranscript)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E5E5)),
                ),
              ),
              child: Text(
                lesson!.transcript!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF666666),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final canComplete = lesson!.type == 'video'
        ? _hasWatchedVideo
        : true; // Non-video lessons can be completed immediately

    return Column(
      children: [
        // Video watch progress indicator
        if (lesson!.type == 'video' && !_hasWatchedVideo) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFA726)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFF9800)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Watch the video to complete this lesson",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Progress: ${(_videoWatchProgress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _videoWatchProgress,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFFFE0B2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF9800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: canComplete
                    ? () async {
                        await widget.controller
                            .markLessonCompleted(lesson!.id!);
                        showToastSuccess(
                          title: "Completed",
                          description: "Lesson marked as completed",
                        );
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canComplete ? const Color(0xFF2D8659) : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(canComplete
                    ? "Mark as Completed"
                    : "Watch Video to Complete"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
