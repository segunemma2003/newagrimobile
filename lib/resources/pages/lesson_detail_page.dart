import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import '/app/models/lesson.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/models/note.dart';
import '/app/controllers/lesson_controller.dart';
import '/resources/pages/quiz_page.dart';
import '/resources/pages/assignment_page.dart';
import '/app/models/assignment.dart';
import '/app/models/comment.dart';
import '/app/services/progression_service.dart';
import '/app/services/video_download_service.dart';
import '/app/networking/api_service.dart';
import '/app/helpers/text_helper.dart';
import '/app/helpers/storage_helper.dart';
import '/app/helpers/image_helper.dart';
import '/config/keys.dart';

class LessonDetailPage extends NyStatefulWidget<LessonController> {
  static RouteView path = ("/lesson-detail", (_) => LessonDetailPage());

  LessonDetailPage({super.key}) : super(child: () => _LessonDetailPageState());
}

class _LessonDetailPageState extends NyPage<LessonDetailPage> {
  Lesson? lesson;
  Course? course;
  Module? module;
  YoutubePlayerController? _youtubeController;
  TextEditingController? _noteController;
  Note? _currentNote;
  List<Note> _lessonNotes = [];
  Map<String, bool> _diyActivities = {}; // Track DIY activity completion

  // Comments
  List<Comment> _comments = [];
  TextEditingController? _commentController;
  TextEditingController? _replyController;
  String? _replyingToCommentId;
  Map<String, bool> _expandedReplies = {}; // Track expanded replies
  Map<String, dynamic>? _currentUser;

  // Color scheme
  static const Color accent = Color(0xFF48C9B0);
  static const Color brandBg = Color(0xFF3D6360);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF0A1612);
  static const Color surfaceDark = Color(0xFF13251E);

  @override
  get init => () async {
        // Lock orientation to portrait on page load
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          lesson = data['lesson'] as Lesson?;
          course = data['course'] as Course?;
          module = data['module'] as Module?;
        }
        if (lesson != null && module != null && course != null) {
          // Never lock lessons - user requested no locking at all
          lesson!.isLocked = false;

          await widget.controller.loadLesson(lesson!);
          // Initialize YouTube player for video lessons
          String? videoId;

          // Try to extract video ID from lesson videoUrl
          if (lesson!.videoUrl != null && lesson!.videoUrl!.isNotEmpty) {
            // If it's already a YouTube URL, extract the ID
            if (_isYouTubeUrl(lesson!.videoUrl!)) {
              videoId = _extractYouTubeId(lesson!.videoUrl!);
              print("Extracted video ID from URL: $videoId");
            } else {
              // Try to extract video ID from any URL format
              String tempId = lesson!.videoUrl!.trim();
              tempId = tempId.replaceAll(RegExp(r'^https?://'), '');
              tempId = tempId.replaceAll(RegExp(r'^www\.'), '');
              tempId = tempId.replaceAll(RegExp(r'^youtube\.com/'), '');
              tempId = tempId.replaceAll(RegExp(r'^youtu\.be/'), '');
              tempId = tempId.replaceAll(RegExp(r'^embed/'), '');
              tempId = tempId.replaceAll(RegExp(r'^watch\?v='), '');
              if (tempId.contains('&')) {
                tempId = tempId.split('&').first;
              }
              if (tempId.contains('?')) {
                tempId = tempId.split('?').first;
              }
              // Check if it's a valid 11-character video ID
              if (tempId.length == 11 &&
                  RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(tempId)) {
                videoId = tempId;
                print("Extracted video ID from cleaned URL: $videoId");
              }
            }
          }

          // Use demo video for lessons if no valid video ID found
          if (videoId == null || videoId.isEmpty || videoId.length != 11) {
            videoId = "_Ffw8zxHHMk"; // Demo video for lessons
            print("Using default demo video ID: $videoId");
          }

          // Initialize YouTube player with the video ID
          try {
            _youtubeController = YoutubePlayerController(
              initialVideoId: videoId,
              flags: const YoutubePlayerFlags(
                autoPlay: false,
                mute: false,
                enableCaption: true,
                showLiveFullscreenButton: true,
                controlsVisibleAtStart: true,
              ),
            );
            print(
                "✅ YouTube player initialized successfully with video ID: $videoId");
          } catch (e) {
            print("❌ Error initializing YouTube player: $e");
            // Try to initialize with default video as fallback
            try {
              _youtubeController = YoutubePlayerController(
                initialVideoId: "_Ffw8zxHHMk",
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: false,
                  enableCaption: true,
                  showLiveFullscreenButton: true,
                  controlsVisibleAtStart: true,
                ),
              );
              print("✅ Using fallback video: _Ffw8zxHHMk");
            } catch (e2) {
              print("❌ Error initializing fallback YouTube player: $e2");
            }
          }
          // Load notes for this lesson
          await _loadNotes();
          await _loadComments();
          await _loadCurrentUser();
          // Initialize DIY activities
          _initializeDIYActivities();
        }
        _noteController = TextEditingController();
      };

  void _initializeDIYActivities() {
    if (lesson?.type == 'diy' && lesson?.content != null) {
      // Parse DIY activities from content or use defaults
      final activities = [
        'Collect "Browns"',
        'Collect "Greens"',
        'Layer Materials',
      ];
      for (var activity in activities) {
        _diyActivities[activity] = false;
      }
    }
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  String? _extractYouTubeId(String url) {
    // If it's already just a video ID (11 characters)
    if (!url.contains('://') && !url.contains('/') && url.length == 11) {
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
        return url;
      }
    }

    // Try to parse as URI first
    final uri = Uri.tryParse(url);
    if (uri != null) {
      // Handle youtu.be URLs
      if (uri.host.contains('youtu.be')) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          String id = pathSegments.last;
          // Remove query parameters
          id = id.split('?').first.split('&').first;
          if (id.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) {
            return id;
          }
        }
      }

      // Handle youtube.com URLs
      if (uri.host.contains('youtube.com')) {
        // Try query parameter first (most common: ?v=VIDEO_ID)
        final videoId = uri.queryParameters['v'];
        if (videoId != null && videoId.isNotEmpty) {
          // Clean up the video ID (remove any extra parameters that might be in the value)
          String cleanId = videoId.split('&').first.split('?').first.trim();
          if (cleanId.length == 11 &&
              RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanId)) {
            return cleanId;
          }
        }

        // Try embed URLs: youtube.com/embed/VIDEO_ID
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty && pathSegments[0] == 'embed') {
          if (pathSegments.length > 1) {
            String id = pathSegments[1].split('?').first.split('&').first;
            if (id.length == 11 &&
                RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) {
              return id;
            }
          }
        }

        // Try /v/VIDEO_ID format
        if (pathSegments.isNotEmpty && pathSegments[0] == 'v') {
          if (pathSegments.length > 1) {
            String id = pathSegments[1].split('?').first.split('&').first;
            if (id.length == 11 &&
                RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) {
              return id;
            }
          }
        }
      }
    }

    // Fallback: Try regex patterns
    // Pattern 1: ?v=VIDEO_ID or &v=VIDEO_ID
    final match1 = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (match1 != null) {
      String id = match1.group(1)!;
      if (id.length == 11) return id;
    }

    // Pattern 2: youtu.be/VIDEO_ID
    final match2 = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (match2 != null) {
      String id = match2.group(1)!;
      if (id.length == 11) return id;
    }

    // Pattern 3: embed/VIDEO_ID
    final match3 = RegExp(r'embed/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (match3 != null) {
      String id = match3.group(1)!;
      if (id.length == 11) return id;
    }

    return null;
  }

  Lesson? _getNextLesson() {
    if (module?.lessons == null || lesson == null) return null;
    final lessons = module!.lessons!;
    final currentIndex = lessons.indexWhere((l) => l.id == lesson!.id);
    if (currentIndex >= 0 && currentIndex < lessons.length - 1) {
      return lessons[currentIndex + 1];
    }
    return null;
  }

  Lesson? _getPreviousLesson() {
    if (module?.lessons == null || lesson == null) return null;
    final lessons = module!.lessons!;
    final currentIndex = lessons.indexWhere((l) => l.id == lesson!.id);
    if (currentIndex > 0) {
      return lessons[currentIndex - 1];
    }
    return null;
  }

  Future<void> _loadNotes() async {
    try {
      final notesJson = await Keys.notes.read<List>();
      if (notesJson != null) {
        _lessonNotes = notesJson
            .map((n) => Note.fromJson(n))
            .where((n) => n.lessonId == lesson?.id)
            .toList();
        if (_lessonNotes.isNotEmpty) {
          _currentNote = _lessonNotes.first;
          _noteController?.text = _currentNote?.content ?? '';
        }
      }
    } catch (e) {
      print("Error loading notes: $e");
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await Keys.auth.read<Map<String, dynamic>>();
      if (_currentUser == null) {
        _currentUser = safeReadAuthData();
      }
      setState(() {});
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to load user data: $e');
      }
      _currentUser = safeReadAuthData();
      setState(() {});
    }
  }

  Future<void> _loadComments() async {
    if (lesson?.id == null || course?.id == null) return;

    try {
      final api = ApiService();
      // Use a direct GET request here to avoid stale cached responses
      // after posting a new comment.
      final response =
          await api.get('/courses/${course!.id}/topics/${lesson!.id}/comments');
      final data = response['data'] as List<dynamic>? ?? [];

      final allComments = data.map((c) => Comment.fromJson(c)).toList();

      // Filter comments for this lesson and build thread structure
      final lessonComments =
          allComments.where((c) => c.parentId == null).toList();

      // Attach replies to each comment
      for (var comment in lessonComments) {
        comment.replies =
            allComments.where((c) => c.parentId == comment.id).toList();
      }

      // Sort by creation date (newest first)
      lessonComments.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      _comments = lessonComments;
      setState(() {});
    } catch (e) {
      print('Error loading comments from API: $e');
    }
  }

  Future<void> _postComment(String content, {String? parentId}) async {
    if (content.trim().isEmpty || lesson?.id == null || course?.id == null)
      return;

    try {
      final api = ApiService();
      await api.addLessonComment(
        course!.id!,
        lesson!.id!.toString(),
        comment: content.trim(),
        parentId: parentId != null ? int.tryParse(parentId) : null,
      );

      // Refresh comments from API
      await _loadComments();

      // Clear controllers
      if (parentId == null) {
        _commentController?.clear();
      } else {
        _replyController?.clear();
        _replyingToCommentId = null;
      }
    } catch (e) {
      print('Error posting comment: $e');
    }
  }

  Future<void> _toggleLikeComment(String commentId) async {
    // Backend doesn't currently support like toggling for lesson comments.
    // For now, we just update the UI locally.
    try {
      final updated = _comments.expand<Comment>((c) {
        return [c, ...?c.replies];
      }).toList();

      final target = updated.firstWhere(
        (c) => c.id == commentId,
        orElse: () => Comment(),
      );

      if (target.id != null) {
        setState(() {
          target.isLiked = !(target.isLiked ?? false);
          if (target.isLiked == true) {
            target.likes = (target.likes ?? 0) + 1;
          } else {
            target.likes = (target.likes ?? 0) - 1;
            if (target.likes! < 0) target.likes = 0;
          }
        });
      }
    } catch (e) {
      print('Error toggling like locally: $e');
    }
  }

  @override
  void dispose() {
    // Restore all orientations when leaving the page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _youtubeController?.dispose();
    _noteController?.dispose();
    _commentController?.dispose();
    _replyController?.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final surfaceColor = isDark ? surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0f172a);
    final secondaryTextColor = isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : (Colors.grey[500] ?? Colors.grey);

    if (lesson == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: bgColor,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: textColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Lesson", style: TextStyle(color: textColor)),
        ),
        body: Center(
          child: Text("Lesson not found", style: TextStyle(color: textColor)),
        ),
      );
    }

    // Never show locked screen - user requested no locking at all
    // All lessons are always accessible

    final moduleNumber = module?.order ?? 1;
    final moduleTitle = module?.title ?? "Module $moduleNumber";
    final previousLesson = _getPreviousLesson();
    final nextLesson = _getNextLesson();

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  color: textColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "MODULE $moduleNumber",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: accent,
                        ),
                      ),
                      Text(
                        moduleTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  color: textColor,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Video Player (Sticky)
                  _buildVideoPlayer(isDark, textColor),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lesson Title
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                lesson!.title ?? "Lesson",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Description
                        _buildHtmlContent(
                          lesson!.description ?? lesson!.content ?? "",
                          secondaryTextColor,
                        ),
                        const SizedBox(height: 20),
                        // Download Offline Button
                        _buildDownloadButton(surfaceColor, textColor,
                            secondaryTextColor, isDark),
                        const SizedBox(height: 20),
                        // Quick Actions Grid
                        _buildQuickActionsGrid(surfaceColor, textColor,
                            secondaryTextColor, isDark, bgColor),
                        const SizedBox(height: 24),
                        // Divider
                        Divider(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[200]),
                        const SizedBox(height: 24),
                        // Notes Section
                        _buildNotesSection(surfaceColor, textColor,
                            secondaryTextColor, isDark),
                        const SizedBox(height: 24),
                        // Interactive Experience
                        if (lesson!.type == 'video')
                          _buildInteractiveExperience(
                              textColor, secondaryTextColor, isDark),
                        const SizedBox(height: 24),
                        // DIY Activity
                        if (lesson!.type == 'diy')
                          _buildDIYActivity(surfaceColor, textColor,
                              secondaryTextColor, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
          // Bottom Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Previous Button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: secondaryTextColor,
                      onPressed: previousLesson != null
                          ? () {
                              routeTo(LessonDetailPage.path, data: {
                                "lesson": previousLesson,
                                "course": course,
                                "module": module,
                              });
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Complete/Mark Complete Button
                  if (lesson!.isCompleted != true)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (lesson == null ||
                              module == null ||
                              course == null) return;

                          try {
                            // Mark lesson as complete using progression service
                            await ProgressionService.completeLesson(
                                lesson!, module!, course!);

                            // Update local state
                            lesson!.isCompleted = true;

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text("Lesson marked as complete!"),
                                backgroundColor: accent,
                                duration: const Duration(seconds: 2),
                              ),
                            );

                            // Update UI
                            setState(() {});
                          } catch (e) {
                            print('Error marking lesson complete: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: ${e.toString()}"),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Mark Complete",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Next Lesson Button
                  if (lesson!.isCompleted == true)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: nextLesson != null
                            ? () {
                                routeTo(LessonDetailPage.path, data: {
                                  "lesson": nextLesson,
                                  "course": course,
                                  "module": module,
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "NEXT LESSON",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  nextLesson?.title ?? "Complete",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                              child: const Icon(Icons.arrow_forward, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build HTML content widget (renders HTML like Django/Laravel {!! !!})
  Widget _buildHtmlContent(String? htmlString, Color textColor) {
    if (htmlString == null || htmlString.isEmpty) {
      return const SizedBox.shrink();
    }

    return Html(
      data: htmlString,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(14),
          color: textColor,
          lineHeight: const LineHeight(1.5),
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
        ),
        "h1": Style(
          fontSize: FontSize(24),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 12),
        ),
        "h2": Style(
          fontSize: FontSize(20),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 10),
        ),
        "h3": Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.bold,
          margin: Margins.only(bottom: 8),
        ),
        "ul": Style(
          margin: Margins.only(bottom: 8),
        ),
        "ol": Style(
          margin: Margins.only(bottom: 8),
        ),
        "li": Style(
          margin: Margins.only(bottom: 4),
        ),
        "strong": Style(
          fontWeight: FontWeight.bold,
        ),
        "em": Style(
          fontStyle: FontStyle.italic,
        ),
      },
    );
  }

  Widget _buildVideoPlayer(bool isDark, Color textColor) {
    // Always show YouTube player if controller is initialized
    if (_youtubeController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayerBuilder(
          onExitFullScreen: () {
            // Restore all orientations when exiting fullscreen
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          },
          onEnterFullScreen: () {
            // Lock to portrait when entering fullscreen
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
          },
          player: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: accent,
            progressColors: ProgressBarColors(
              playedColor: accent,
              handleColor: accent,
              bufferedColor: Colors.grey[300]!,
              backgroundColor: Colors.grey[600]!,
            ),
            onReady: () {
              print("✅ YouTube player is ready");
            },
            onEnded: (metadata) {
              print("Video ended: ${metadata.videoId}");
            },
          ),
          builder: (context, player) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: player,
            );
          },
        ),
      );
    }

    // Fallback thumbnail with play button
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          image: course?.thumbnail != null
              ? DecorationImage(
                  image: NetworkImage(getImageUrl(course!.thumbnail!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                "Video player loading...",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(Color surfaceColor, Color textColor,
      Color secondaryTextColor, bool isDark) {
    return InkWell(
      onTap: () async {
        if (lesson == null ||
            lesson!.videoUrl == null ||
            lesson!.videoUrl!.isEmpty ||
            lesson!.id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No video available to download for this lesson."),
            ),
          );
          return;
        }

        final downloadService = VideoDownloadService();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Starting download..."),
          ),
        );

        await downloadService.downloadVideo(
          videoUrl: lesson!.videoUrl!,
          lessonId: lesson!.id!,
          onProgress: (progress) {
            // Optionally you can update state to show progress in UI
            if (progress >= 1.0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Video downloaded for offline viewing."),
                ),
              );
            }
          },
          onError: (error) {
            if (error != null && error.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.download, color: accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Download Offline",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "MP4 HD • 24.5 MB",
                    style: TextStyle(
                      fontSize: 10,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: accent.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(Color surfaceColor, Color textColor,
      Color secondaryTextColor, bool isDark, Color bgColor) {
    final hasAssignment = lesson?.assignmentId != null;
    final hasQuiz = lesson?.quizzes != null && lesson!.quizzes!.isNotEmpty;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                Icons.description,
                "Transcript",
                surfaceColor,
                textColor,
                secondaryTextColor,
                isDark,
                () {
                  _showTranscript(
                      context, textColor, secondaryTextColor, isDark, bgColor);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                Icons.note,
                "Notes",
                surfaceColor,
                textColor,
                secondaryTextColor,
                isDark,
                () {
                  // Navigate to notes page
                  routeTo("/notes", data: {
                    "lesson": lesson,
                    "course": course,
                    "module": module,
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                hasAssignment ? Icons.assignment : Icons.quiz,
                hasAssignment ? "Assignment" : "Quiz",
                surfaceColor,
                textColor,
                secondaryTextColor,
                isDark,
                () {
                  if (hasAssignment) {
                    // Navigate to assignment page
                    _navigateToAssignment();
                  } else if (hasQuiz) {
                    routeTo(QuizPage.path, data: {
                      "lesson": lesson,
                      "course": course,
                      "module": module,
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                Icons.comment,
                "Comments",
                surfaceColor,
                textColor,
                secondaryTextColor,
                isDark,
                () {
                  _showCommentsSection(context, surfaceColor, textColor,
                      secondaryTextColor, isDark, bgColor);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _navigateToAssignment() async {
    if (lesson?.assignmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No assignment available for this lesson."),
        ),
      );
      return;
    }

    try {
      Assignment? assignment;

      // Try to load from local storage first
      try {
        final assignmentsJson = await Keys.assignments.read<List>();
        if (assignmentsJson != null) {
          final assignments =
              assignmentsJson.map((a) => Assignment.fromJson(a)).toList();
          assignment = assignments.firstWhere(
            (a) => a.id == lesson!.assignmentId,
          );
        }
      } catch (e) {
        print("Error loading assignment from storage: $e");
      }

      // If not in storage, fetch from API
      if (assignment == null && lesson?.assignmentId != null) {
        try {
          final api = ApiService();
          final response =
              await api.fetchAssignmentDetails(lesson!.assignmentId!);
          final assignmentData = response['data'] ?? response;
          assignment = Assignment.fromJson(assignmentData);

          // Save to local storage
          final assignmentsJson = await Keys.assignments.read<List>() ?? [];
          assignmentsJson.add(assignment.toJson());
          await Keys.assignments.save(assignmentsJson);
        } catch (e) {
          print("Error fetching assignment from API: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to load assignment: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (assignment != null) {
        routeTo(AssignmentPage.path, data: {
          "assignment": assignment,
          "course": course,
          "module": module,
          "lesson": lesson,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Assignment not found."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error navigating to assignment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading assignment: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveExperience(
      Color textColor, Color secondaryTextColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.view_in_ar, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(
              "INTERACTIVE EXPERIENCE",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [brandBg, backgroundDark],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "VR READY",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Step into the Greenhouse",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Visualize compost layers and heat zones in an immersive 3D environment.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Launch VR experience
                },
                icon: const Icon(Icons.rocket_launch, size: 18),
                label: const Text("Launch Experience"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDIYActivity(Color surfaceColor, Color textColor,
      Color secondaryTextColor, bool isDark) {
    final completedCount = _diyActivities.values.where((v) => v).length;
    final totalCount = _diyActivities.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.build, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  "DIY ACTIVITY",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: accent,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Text(
                "$completedCount/$totalCount Completed",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // DIY Description
        if (lesson?.description != null || lesson?.content != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[200]!,
              ),
            ),
            child: _buildHtmlContent(
              lesson?.description ??
                  lesson?.content ??
                  "Follow the step-by-step instructions to complete this DIY activity.",
              textColor,
            ),
          ),
        const SizedBox(height: 16),
        // DIY Video (if available)
        if (lesson?.videoUrl != null && lesson!.videoUrl!.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[200]!,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildVideoPlayer(isDark, textColor),
            ),
          ),
        const SizedBox(height: 16),
        // DIY Steps Checklist
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: _diyActivities.entries.map((entry) {
              return CheckboxListTile(
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  _getDIYActivitySubtitle(entry.key),
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    _diyActivities[entry.key] = value ?? false;
                  });
                },
                activeColor: accent,
                checkColor: Colors.black87,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getDIYActivitySubtitle(String activity) {
    switch (activity) {
      case 'Collect "Browns"':
        return 'Leaves, twigs, paper';
      case 'Collect "Greens"':
        return 'Grass, veggie scraps';
      case 'Layer Materials':
        return '3:1 Brown to Green ratio';
      default:
        return '';
    }
  }

  Widget _buildNotesSection(Color surfaceColor, Color textColor,
      Color secondaryTextColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.note, size: 20, color: accent),
                const SizedBox(width: 8),
                Text(
                  "My Notes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                routeTo("/notes", data: {
                  "lesson": lesson,
                  "course": course,
                  "module": module,
                });
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text("View All"),
              style: TextButton.styleFrom(
                foregroundColor: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Take notes here...",
                  hintStyle: TextStyle(color: secondaryTextColor),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  // Auto-save notes
                  _saveNote(value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_lessonNotes.length} note${_lessonNotes.length != 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final content = _noteController?.text.trim() ?? "";
                      if (content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Type something before saving your note."),
                          ),
                        );
                        return;
                      }
                      await _saveNote(content);
                      FocusScope.of(context).unfocus();
                      final isDarkTheme =
                          Theme.of(context).brightness == Brightness.dark;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor:
                              isDarkTheme ? Colors.white : Colors.black87,
                          content: Text(
                            "Note saved.",
                            style: TextStyle(
                              color: isDarkTheme ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveNote(String content) async {
    if (lesson == null || content.trim().isEmpty) return;

    try {
      final note = Note()
        ..id =
            _currentNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString()
        ..lessonId = lesson!.id
        ..courseId = course?.id
        ..moduleId = module?.id
        ..title = lesson!.title ?? "Lesson Note"
        ..content = content
        ..updatedAt = DateTime.now();

      if (_currentNote == null) {
        note.createdAt = DateTime.now();
      }

      final notesJson = await Keys.notes.read<List>() ?? [];
      final notes = notesJson.map((n) => Note.fromJson(n)).toList();

      // Remove old note if exists
      notes.removeWhere((n) => n.id == note.id);
      notes.add(note);

      await Keys.notes.save(notes.map((n) => n.toJson()).toList());

      setState(() {
        _currentNote = note;
        if (!_lessonNotes.any((n) => n.id == note.id)) {
          _lessonNotes.add(note);
        } else {
          final index = _lessonNotes.indexWhere((n) => n.id == note.id);
          _lessonNotes[index] = note;
        }
      });

      // Also sync note to backend if course and lesson IDs are available
      if (course?.id != null && lesson?.id != null) {
        try {
          final api = ApiService();
          await api.createNote({
            "course_id": course!.id,
            "topic_id": lesson!.id,
            "notes": content,
          });
        } catch (e) {
          print("Warning: Failed to sync note to API: $e");
        }
      }
    } catch (e) {
      print("Error saving note: $e");
    }
  }

  void _showTranscript(BuildContext context, Color textColor,
      Color secondaryTextColor, bool isDark, Color bgColor) {
    final transcript = stripHtmlTags(lesson?.transcript ??
        lesson?.content ??
        "No transcript available for this lesson.");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryTextColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Transcript",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson?.title ?? "Lesson Transcript",
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: textColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Transcript Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  transcript,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[200]!,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsSection(BuildContext context, Color surfaceColor,
      Color textColor, Color secondaryTextColor, bool isDark, Color bgColor) {
    _commentController ??= TextEditingController();
    _replyController ??= TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: secondaryTextColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Comments",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_comments.length} comment${_comments.length != 1 ? 's' : ''}",
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: textColor,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.comment_outlined,
                                size: 64, color: secondaryTextColor),
                            const SizedBox(height: 16),
                            Text(
                              "No comments yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Be the first to comment!",
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentItem(
                            _comments[index],
                            surfaceColor,
                            textColor,
                            secondaryTextColor,
                            isDark,
                            bgColor,
                            setModalState,
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) async {
                          if (value.trim().isNotEmpty) {
                            await _postComment(value);
                            setModalState(() {});
                            FocusScope.of(context).unfocus();
                          }
                        },
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          hintStyle: TextStyle(color: secondaryTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: accent, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          filled: true,
                          fillColor: bgColor,
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.send, color: accent),
                      onPressed: () async {
                        if (_commentController?.text.trim().isNotEmpty ==
                            true) {
                          await _postComment(_commentController!.text);
                          setModalState(() {});
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(
      Comment comment,
      Color surfaceColor,
      Color textColor,
      Color secondaryTextColor,
      bool isDark,
      Color bgColor,
      StateSetter setModalState) {
    final hasReplies = comment.hasReplies;
    final isRepliesExpanded = _expandedReplies[comment.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent.withValues(alpha: 0.2),
                backgroundImage:
                    comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                        ? NetworkImage(getImageUrl(comment.userAvatar!))
                        : null,
                child: comment.userAvatar == null || comment.userAvatar!.isEmpty
                    ? Text(
                        (comment.userName ?? 'A')[0].toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.userName ?? 'Anonymous',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(comment.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stripHtmlTags(comment.content ?? ''),
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            await _toggleLikeComment(comment.id!);
                            setModalState(() {});
                          },
                          child: Row(
                            children: [
                              Icon(
                                comment.isLiked == true
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: comment.isLiked == true
                                    ? Colors.red
                                    : secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${comment.likes ?? 0}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              _replyingToCommentId = comment.id;
                              _replyController ??= TextEditingController();
                            });
                          },
                          child: Row(
                            children: [
                              Icon(Icons.reply,
                                  size: 18, color: secondaryTextColor),
                              const SizedBox(width: 4),
                              Text(
                                "Reply",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasReplies) ...[
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                _expandedReplies[comment.id!] =
                                    !isRepliesExpanded;
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  isRepliesExpanded ? "Hide" : "View",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${comment.replyCount} ${comment.replyCount == 1 ? 'reply' : 'replies'}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  isRepliesExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 16,
                                  color: accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_replyingToCommentId == comment.id) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(width: 32),
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                hintText: "Write a reply...",
                                hintStyle: TextStyle(color: secondaryTextColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: accent, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                filled: true,
                                fillColor: bgColor,
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.send, color: accent, size: 20),
                            onPressed: () async {
                              if (_replyController?.text.trim().isNotEmpty ==
                                  true) {
                                await _postComment(_replyController!.text,
                                    parentId: comment.id);
                                setModalState(() {
                                  _replyingToCommentId = null;
                                  _replyController?.clear();
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: secondaryTextColor, size: 20),
                            onPressed: () {
                              setModalState(() {
                                _replyingToCommentId = null;
                                _replyController?.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasReplies && isRepliesExpanded) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Column(
                children: comment.replies!.map((reply) {
                  return _buildReplyItem(reply, surfaceColor, textColor,
                      secondaryTextColor, isDark, setModalState);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyItem(Comment reply, Color surfaceColor, Color textColor,
      Color secondaryTextColor, bool isDark, StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.2),
            backgroundImage:
                reply.userAvatar != null && reply.userAvatar!.isNotEmpty
                    ? NetworkImage(getImageUrl(reply.userAvatar!))
                    : null,
            child: reply.userAvatar == null || reply.userAvatar!.isEmpty
                ? Text(
                    (reply.userName ?? 'A')[0].toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            reply.userName ?? 'Anonymous',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(reply.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stripHtmlTags(reply.content ?? ''),
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        await _toggleLikeComment(reply.id!);
                        setModalState(() {});
                      },
                      child: Row(
                        children: [
                          Icon(
                            reply.isLiked == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: reply.isLiked == true
                                ? Colors.red
                                : secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${reply.likes ?? 0}",
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
