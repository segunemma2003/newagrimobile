import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/models/lesson.dart';
import '/app/controllers/course_detail_controller.dart';
import '/resources/pages/lesson_detail_page.dart';
import '/resources/pages/quiz_page.dart';
import '/resources/pages/modules_overview_page.dart';
import '/resources/pages/assignment_page.dart';
import '/app/models/assignment.dart';
import '/app/models/review.dart';
import '/app/helpers/text_helper.dart';
import '/app/helpers/storage_helper.dart';
import '/app/helpers/image_helper.dart';
import '/app/networking/api_service.dart';
import '/config/keys.dart';

class CourseDetailPage extends NyStatefulWidget<CourseDetailController> {
  static RouteView path = ("/course-detail", (_) => CourseDetailPage());

  CourseDetailPage({super.key}) : super(child: () => _CourseDetailPageState());
}

class _CourseDetailPageState extends NyPage<CourseDetailPage> {
  Course? course;
  String _selectedTab = "Overview";
  Map<String, bool> _expandedModules = {}; // Track which modules are expanded
  YoutubePlayerController? _previewVideoController;
  final TextEditingController _enrollmentCodeController =
      TextEditingController();

  // Enrollment state from /my-courses
  Set<String> _enrolledCourseIds = {};

  // Reviews
  List<Review> _reviews = [];
  TextEditingController? _reviewController;
  int _selectedRating = 5;
  Map<String, dynamic>? _currentUser;

  // Color scheme - maintain from other pages
  static const Color primary = Color(0xFF3E6866);
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Check if course is enrolled - primarily via /my-courses
  bool _isEnrolled(Course course) {
    final courseId = course.id?.toString();

    if (courseId != null && _enrolledCourseIds.contains(courseId)) {
      return true;
    }

    // Fallback to flag on course details if needed
    return course.isEnrolled == true;
  }

  Future<void> _showEnrollDialog(Course course) async {
    _enrollmentCodeController.clear();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? backgroundDark : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF131515);
        final secondaryTextColor = isDark
            ? (Colors.grey[400] ?? Colors.grey)
            : (Colors.grey[600] ?? Colors.grey);

        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Enter Enrollment Code",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "To enroll in this course, please enter the enrollment code provided to you.\n\n"
                "If you don't have an enrollment code, please contact the Agrisiti team at "
                "info@agrisiti.com to request access.",
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _enrollmentCodeController,
                decoration: InputDecoration(
                  labelText: "Enrollment Code",
                  hintText: "e.g. 20252025",
                  labelStyle: TextStyle(color: secondaryTextColor),
                  hintStyle: TextStyle(color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = _enrollmentCodeController.text.trim();
                if (code.isEmpty || course.id == null) {
                  return;
                }
                Navigator.of(context).pop(); // Close dialog before API call
                await _enrollInCourse(course, code);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text("Enroll"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _enrollInCourse(Course course, String code) async {
    try {
      final response = await api<ApiService>(
        (request) => request.enrollInCourse(
          courseId: course.id!,
          enrollmentCode: code,
        ),
      );

      if (response is Map && response['success'] == true) {
        // Refresh course details to get updated is_enrolled status
        await widget.controller.loadCourseDetails(course.id!);
        setState(() {
          this.course = widget.controller.course;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Successfully enrolled in course"),
            backgroundColor: accent,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final message = response is Map && response['message'] != null
            ? response['message'].toString()
            : "Failed to enroll in course. Please check your code.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error enrolling in course: $e"),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Get button text based on enrollment status
  String _getEnrollButtonText(Course course) {
    if (_isEnrolled(course)) {
      // Check if there's progress
      if (course.completedLessons != null && course.completedLessons! > 0) {
        return "Continue Course";
      } else {
        return "Start Course";
      }
    }
    return "Enroll Now";
  }

  @override
  get init => () async {
        // Lock orientation to portrait on page load
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          course = data['course'] as Course?;
          if (course != null) {
            await widget.controller.loadCourseDetails(course!.id!);
            course = widget.controller.course;
            // Load reviews from course details if available
            if (course?.reviews != null) {
              _reviews = course!.reviews!;
            }

            // Handle selected tab from route data
            if (data['selectedTab'] != null) {
              _selectedTab = data['selectedTab'] as String;
            }

            // Handle module expansion from route data
            if (data['expandModuleId'] != null) {
              final moduleId = data['expandModuleId'] as String?;
              if (moduleId != null && course?.modules != null) {
                _expandedModules[moduleId] = true;
              }
            }

            // Initialize preview video controller with course preview video
            _initializePreviewVideo();

            setState(() {});
          }
        }
        await _loadReviews();
        await _loadCurrentUser();
        await _loadEnrollmentStatus();
      };

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

  Future<void> _loadEnrollmentStatus() async {
    if (course?.id == null) return;

    try {
      final api = ApiService();
      final response = await api.fetchMyCourses();
      final rawData = response['data'] ?? response;

      if (rawData is List) {
        final ids = <String>{};
        for (final item in rawData) {
          if (item is Map<String, dynamic>) {
            final courseId = item['course_id']?.toString() ??
                item['course']?['id']?.toString();
            if (courseId != null && courseId.isNotEmpty) {
              ids.add(courseId);
            }
          }
        }
        _enrolledCourseIds = ids;
        setState(() {});
      }
    } catch (e) {
      print('Warning: Failed to load enrollment status from /my-courses: $e');
    }
  }

  Future<void> _loadReviews() async {
    if (course?.id == null) return;

    try {
      // Prefer API reviews
      Map<String, dynamic>? response = await api<ApiService>(
        (request) =>
            request.fetchCourseReviews(course!.id!, perPage: 20, page: 1),
      );

      // Handle different response formats
      List<dynamic>? reviewsData;
      if (response != null) {
        // Check if response has 'data' key (could be List or Map with pagination)
        if (response['data'] != null) {
          if (response['data'] is List) {
            reviewsData = response['data'] as List<dynamic>;
          } else if (response['data'] is Map &&
              response['data']['data'] is List) {
            // Paginated response
            reviewsData = response['data']['data'] as List<dynamic>;
          }
        } else if (response is List) {
          // Direct list response
          reviewsData = response as List<dynamic>;
        }

        print('Reviews API response format: ${response.runtimeType}');
        print('Reviews data found: ${reviewsData?.length ?? 0} reviews');
      }

      if (reviewsData != null && reviewsData.isNotEmpty) {
        _reviews = reviewsData
            .map((r) {
              try {
                return Review.fromJson(r);
              } catch (e) {
                print('Error parsing review: $e, data: $r');
                return null;
              }
            })
            .whereType<Review>()
            .toList();
        print('Successfully parsed ${_reviews.length} reviews');
      } else if (course?.reviews != null && course!.reviews!.isNotEmpty) {
        _reviews = List.from(course!.reviews!);
        print('Using reviews from course object: ${_reviews.length} reviews');
      } else {
        print('No reviews found in API response or course object');
      }

      // Sort by creation date (newest first)
      if (_reviews.isNotEmpty) {
        _reviews.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(2000);
          final bDate = b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
      }

      setState(() {});
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController?.text.trim().isEmpty == true || course?.id == null)
      return;

    try {
      await api<ApiService>(
        (request) => request.addCourseReview(
          course!.id!,
          rating: _selectedRating,
          review: _reviewController!.text.trim(),
        ),
      );

      _reviewController?.clear();
      _selectedRating = 5;

      // Reload reviews from API
      await _loadReviews();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Review submitted successfully!'),
          backgroundColor: accent,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Extract YouTube video ID from URL
  String? _extractYouTubeId(String? url) {
    if (url == null || url.isEmpty) return null;

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

        // Try watch URLs: youtube.com/watch?v=VIDEO_ID
        if (pathSegments.isNotEmpty && pathSegments[0] == 'watch') {
          final videoId = uri.queryParameters['v'];
          if (videoId != null && videoId.isNotEmpty) {
            String cleanId = videoId.split('&').first.split('?').first.trim();
            if (cleanId.length == 11 &&
                RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanId)) {
              return cleanId;
            }
          }
        }
      }
    }

    // Fallback: try to extract from any URL format
    String tempId = url.trim();
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
    if (tempId.length == 11 &&
        RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(tempId)) {
      return tempId;
    }

    return null;
  }

  /// Initialize preview video controller with course preview video URL
  void _initializePreviewVideo() {
    try {
      String? videoId;

      // Extract video ID from course preview video URL
      if (course?.previewVideoUrl != null &&
          course!.previewVideoUrl!.isNotEmpty) {
        videoId = _extractYouTubeId(course!.previewVideoUrl!);
        print("Extracted preview video ID from course: $videoId");
      }

      // Use default video if no valid video ID found
      if (videoId == null || videoId.isEmpty || videoId.length != 11) {
        videoId = "aoweVTb5lXQ"; // Fallback to default preview video
        print("Using default preview video ID: $videoId");
      }

      _previewVideoController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          showLiveFullscreenButton: true,
          controlsVisibleAtStart: true,
        ),
      );
      print("✅ Preview video controller initialized with video ID: $videoId");
    } catch (e) {
      print("Error initializing preview video: $e");
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
    _previewVideoController?.dispose();
    _enrollmentCodeController.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final displayCourse = widget.controller.course ?? course;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final surfaceColor = isDark ? surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : (Colors.grey[500] ?? Colors.grey);

    if (displayCourse == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: surfaceColor,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: textColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Course",
            style: TextStyle(color: textColor),
          ),
        ),
        body: Center(
          child: Text(
            "Course not found",
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: textColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Course Details",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, size: 20),
            color: textColor,
            onPressed: () {
              // TODO: Share course
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section (Video/Image Preview)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        // Background Image
                        Positioned.fill(
                          child: Image.network(
                            getImageUrl(displayCourse.thumbnail) != ''
                                ? getImageUrl(displayCourse.thumbnail!)
                                : "https://via.placeholder.com/640x360",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Icon(Icons.image,
                                      size: 48, color: Colors.grey)),
                            ),
                          ),
                        ),
                        // Gradient Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.9),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Play Button
                        Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _showPreviewVideo(context, isDark, bgColor,
                                    textColor, secondaryTextColor);
                              },
                              borderRadius: BorderRadius.circular(32),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Preview Label
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  "Preview Course",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Bookmark
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                displayCourse.title ?? "Untitled Course",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark_border, size: 28),
                              color: Colors.grey[400],
                              onPressed: () {
                                // TODO: Toggle bookmark
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Ratings & Enrollment
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (Colors.yellow[400] ?? Colors.yellow)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "4.8",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          Colors.yellow[400] ?? Colors.yellow,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ...List.generate(
                                      4,
                                      (index) => Icon(Icons.star,
                                          size: 16,
                                          color: Colors.yellow[400] ??
                                              Colors.yellow)),
                                  Icon(Icons.star_half,
                                      size: 16,
                                      color:
                                          Colors.yellow[400] ?? Colors.yellow),
                                  const SizedBox(width: 4),
                                  Text(
                                    "(1.2k)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Icon(Icons.group,
                                    size: 18, color: secondaryTextColor),
                                const SizedBox(width: 4),
                                Text(
                                  "3,542 students",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Sticky Tabs
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildTab(
                                      "Overview", _selectedTab == "Overview",
                                      () {
                                    setState(() => _selectedTab = "Overview");
                                  }, textColor, secondaryTextColor),
                                  const SizedBox(width: 24),
                                  _buildTab("Curriculum",
                                      _selectedTab == "Curriculum", () {
                                    setState(() => _selectedTab = "Curriculum");
                                  }, textColor, secondaryTextColor),
                                  const SizedBox(width: 24),
                                  _buildTab(
                                      "Reviews", _selectedTab == "Reviews", () {
                                    setState(() => _selectedTab = "Reviews");
                                  }, textColor, secondaryTextColor),
                                  const SizedBox(width: 24),
                                  _buildTab("Instructor",
                                      _selectedTab == "Instructor", () {
                                    setState(() => _selectedTab = "Instructor");
                                  }, textColor, secondaryTextColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Tab Content
                        _buildTabContent(
                          _selectedTab,
                          displayCourse,
                          surfaceColor,
                          textColor,
                          secondaryTextColor,
                          isDark,
                        ),
                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : (Colors.grey[200] ?? Colors.grey),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Only show price if not enrolled
                  if (!_isEnrolled(displayCourse)) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Price",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                displayCourse.isFree == true ||
                                        displayCourse.price == null ||
                                        displayCourse.price == "0" ||
                                        displayCourse.price == "0.00"
                                    ? "Free"
                                    : "\$${displayCourse.price}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  // Button takes full width if enrolled, otherwise normal
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_isEnrolled(displayCourse)) {
                          // Navigate to modules overview for enrolled courses
                          routeTo(ModulesOverviewPage.path,
                              data: {"course": displayCourse});
                        } else {
                          _showEnrollDialog(displayCourse);
                        }
                      },
                      icon: Icon(
                          _isEnrolled(displayCourse)
                              ? (displayCourse.completedLessons != null &&
                                      displayCourse.completedLessons! > 0
                                  ? Icons.play_circle_outline
                                  : Icons.play_arrow)
                              : Icons.arrow_forward,
                          size: 20),
                      label: Text(_getEnrollButtonText(displayCourse)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 4,
                        shadowColor: accent.withValues(alpha: 0.25),
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

  Widget _buildTabContent(
    String selectedTab,
    Course course,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    switch (selectedTab) {
      case "Curriculum":
        return _buildCurriculumTab(
            course, surfaceColor, textColor, secondaryTextColor, isDark);
      case "Reviews":
        return _buildReviewsTab(
            surfaceColor, textColor, secondaryTextColor, isDark);
      case "Instructor":
        return _buildInstructorTab(
            surfaceColor, textColor, secondaryTextColor, isDark);
      case "Overview":
      default:
        return _buildOverviewTab(
            course, surfaceColor, textColor, secondaryTextColor, isDark);
    }
  }

  Widget _buildOverviewTab(
    Course course,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    // Derive dynamic values from API data with sensible fallbacks
    final durationLabel =
        course.durationMinutes != null && course.durationMinutes! > 0
            ? _formatDuration(course.durationMinutes!)
            : "Self-paced";
    final levelLabel = (course.level != null && course.level!.isNotEmpty)
        ? course.level!
        : "All levels";
    final certificateLabel =
        course.certificateIncluded == false ? "Not included" : "Included";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule,
                label: "Duration",
                value: durationLabel,
                surfaceColor: surfaceColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.signal_cellular_alt,
                label: "Level",
                value: levelLabel,
                surfaceColor: surfaceColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.verified,
                label: "Certificate",
                value: certificateLabel,
                surfaceColor: surfaceColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // About Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "About this course",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              stripHtmlTags(course.about ??
                  course.description ??
                  "Learn how to grow your own food in small spaces using sustainable methods. This comprehensive guide covers everything from soil health to hydroponics, perfect for urban dwellers looking to reconnect with nature and produce fresh, organic vegetables."),
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // TODO: Expand description
              },
              child: Text(
                "Read more",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // What you'll learn
        if (course.whatYouWillLearn != null &&
            course.whatYouWillLearn!.isNotEmpty) ...[
          Text(
            "What you'll learn",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...course.whatYouWillLearn!.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle,
                      size: 18, color: accent.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stripHtmlTags(item),
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // What you'll get
        if (course.whatYouWillGet != null &&
            course.whatYouWillGet!.isNotEmpty) ...[
          Text(
            "What you'll get",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...course.whatYouWillGet!.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.workspace_premium,
                      size: 18, color: accent.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stripHtmlTags(item),
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Course information
        if (course.courseInformation != null &&
            course.courseInformation!.isNotEmpty) ...[
          Text(
            "Course information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...course.courseInformation!.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: accent.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stripHtmlTags(item),
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Instructor Card
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Instructor",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : (Colors.grey[100] ?? Colors.grey),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: primary.withValues(alpha: 0.2), width: 2),
                      image: course.tutor?.avatar != null &&
                              course.tutor!.avatar!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                  getImageUrl(course.tutor!.avatar!)),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: (course.tutor?.avatar == null ||
                            course.tutor!.avatar!.isEmpty)
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Text(
                                (course.tutor?.name?.isNotEmpty == true
                                        ? course.tutor!.name![0].toUpperCase()
                                        : "I")
                                    .toString(),
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.tutor?.name ?? "Instructor",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course.category?.name ?? "Course Tutor",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stripHtmlTags(course.tutor?.bio ??
                              "Instructor for this course."),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: secondaryTextColor),
                    onPressed: () {
                      // TODO: View instructor profile
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Course Project Card (if course has project)
        if (course.projectId != null)
          _buildCourseProjectCard(
            course,
            surfaceColor,
            textColor,
            secondaryTextColor,
            isDark,
            accent,
          ),
        if (course.projectId != null) const SizedBox(height: 24),
        // Curriculum Preview
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Curriculum",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  "${course.totalLessons ?? 12} Lessons • 4h 20m",
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : (Colors.grey[100] ?? Colors.grey),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Week 1 (Unlocked)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "01",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Introduction to Soil Health",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "3 Lessons • 45m",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.expand_more, color: secondaryTextColor),
                      ],
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : (Colors.grey[100] ?? Colors.grey)),
                  // Week 2 (Locked)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.grey[50],
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(Icons.lock,
                                size: 16, color: secondaryTextColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hydroponics Basics",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "4 Lessons • 1h 15m",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: secondaryTextColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // TODO: Show full syllabus
              },
              child: Text(
                "See Full Syllabus",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Reviews Snapshot
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Student Reviews",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : (Colors.grey[100] ?? Colors.grey),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Text(
                            "4.8",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (index) {
                              if (index < 4) {
                                return Icon(Icons.star,
                                    size: 14,
                                    color: Colors.yellow[400] ?? Colors.yellow);
                              } else {
                                return Icon(Icons.star_half,
                                    size: 14,
                                    color: Colors.yellow[400] ?? Colors.yellow);
                              }
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "1,200 ratings",
                            style: TextStyle(
                              fontSize: 10,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildRatingBar(
                                5, 0.77, textColor, secondaryTextColor, isDark),
                            const SizedBox(height: 6),
                            _buildRatingBar(
                                4, 0.15, textColor, secondaryTextColor, isDark),
                            const SizedBox(height: 6),
                            _buildRatingBar(
                                3, 0.05, textColor, secondaryTextColor, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Show all reviews
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[50],
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Read all reviews",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return "Self-paced";
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return "${hours}h ${mins}m";
    } else if (hours > 0) {
      return "${hours}h";
    } else {
      return "${mins}m";
    }
  }

  Widget _buildTab(String label, bool isSelected, VoidCallback onTap,
      Color textColor, Color secondaryTextColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? accent : secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color surfaceColor,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating, double percentage, Color textColor,
      Color secondaryTextColor, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            "$rating",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      percentage > 0.5 ? accent : accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurriculumTab(
    Course course,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    // Calculate total duration (approximate based on lessons count)
    final totalLessons = course.totalLessons ?? course.lessonsCount ?? 0;
    final totalDuration = totalLessons * 20; // ~20 mins per lesson
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    final durationText = hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Curriculum",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    routeTo(ModulesOverviewPage.path, data: {"course": course});
                  },
                  icon: const Icon(Icons.view_module, size: 18),
                  label: const Text("View All Modules"),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                  ),
                ),
              ],
            ),
            Text(
              "${course.totalLessons ?? 0} Lessons • $durationText",
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Actual modules from course
        if (course.modules != null && course.modules!.isNotEmpty)
          ...course.modules!.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            // Lock logic:
            // - If user is NOT enrolled, only first 2 modules are accessible
            // - If enrolled, all modules use normal completion logic
            bool isLocked = false;
            if (!_isEnrolled(course) && index > 1) {
              isLocked = true;
            }
            // Override with module's own isLocked property if set,
            // but only when the user is NOT enrolled.
            if (!_isEnrolled(course) && module.isLocked == true) {
              isLocked = true;
            }

            return _buildModuleItem(
              module,
              index + 1,
              isLocked,
              course,
              surfaceColor,
              textColor,
              secondaryTextColor,
              isDark,
            );
          }).toList()
        else
          // Fallback placeholder modules if no modules available
          ...[
          _buildModuleItem(
            null,
            1,
            false,
            course,
            surfaceColor,
            textColor,
            secondaryTextColor,
            isDark,
          ),
          _buildModuleItem(
            null,
            2,
            true,
            course,
            surfaceColor,
            textColor,
            secondaryTextColor,
            isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildModuleItem(
    Module? module,
    int index,
    bool isLocked,
    Course course,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final moduleId = module?.id ?? "module_$index";
    final isExpanded = _expandedModules[moduleId] ?? false;
    final title = module?.title ?? "Module $index";
    final lessons = module?.lessons ?? [];
    final lessonCount = lessons.length;
    // Calculate progress from lessons if not provided in module
    final completedLessonsCount =
        lessons.where((l) => l.isCompleted == true).length;
    final completedLessons = module?.completedLessons ?? completedLessonsCount;
    final totalLessons = module?.totalLessons ?? lessonCount;
    final progress = totalLessons > 0 ? (completedLessons / totalLessons) : 0.0;
    final progressPercent = (progress * 100).toInt();
    final duration = lessonCount * 15; // Approximate 15 min per lesson
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    final subtitle = hours > 0
        ? "$lessonCount Lessons • ${hours}h ${minutes}m"
        : "$lessonCount Lessons • ${minutes}m";

    // Check if module is completed (all lessons done AND test passed)
    final allLessonsCompleted =
        completedLessons == totalLessons && totalLessons > 0;
    final testPassed = module?.testPassed == true ||
        (module?.testScore != null && module!.testScore! >= 80);
    final isModuleCompleted = allLessonsCompleted && testPassed;
    final isModuleActive =
        !isLocked && !isModuleCompleted && completedLessons > 0;
    final hasTestScore = module?.testScore != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLocked
            ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[50])
            : (isModuleActive
                ? (isDark
                    ? accent.withValues(alpha: 0.05)
                    : accent.withValues(alpha: 0.05))
                : surfaceColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isModuleActive
              ? accent.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : (Colors.grey[100] ?? Colors.grey)),
          width: isModuleActive ? 1.5 : 1,
        ),
        boxShadow: isModuleActive
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        children: [
          // Module Header (Clickable)
          InkWell(
            onTap: isLocked
                ? null
                : () {
                    setState(() {
                      _expandedModules[moduleId] = !isExpanded;
                    });
                  },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Module Icon/Progress Indicator
                  _buildModuleIcon(
                    isLocked,
                    isModuleCompleted,
                    isModuleActive,
                    progressPercent,
                    index,
                    accent,
                    secondaryTextColor,
                    isDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? textColor.withValues(alpha: 0.7)
                                : textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Module Status Text
                        if (isModuleCompleted)
                          Text(
                            "Completed",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: accent,
                            ),
                          )
                        else if (isModuleActive)
                          Text(
                            "In Progress",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: accent,
                            ),
                          )
                        else if (isLocked)
                          Text(
                            "Locked • Complete Previous Module",
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          )
                        else
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    isLocked
                        ? Icons.chevron_right
                        : (isExpanded ? Icons.expand_less : Icons.expand_more),
                    color: secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
          // Lessons List (Expanded) - Animated
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded && !isLocked && lessons.isNotEmpty
                ? Column(
                    children: [
                      ...lessons.asMap().entries.map((lessonEntry) {
                        final lessonIndex = lessonEntry.key;
                        final lesson = lessonEntry.value;

                        // If user is enrolled, all lessons are open.
                        // If not enrolled, respect existing lesson locking flags.
                        bool finalLocked = false;
                        if (!_isEnrolled(course)) {
                          final isLessonLocked = lesson.isLocked == true;

                          // Lock lesson if previous lesson is not completed (except first lesson)
                          bool shouldLock = false;
                          if (lessonIndex > 0) {
                            final previousLesson = lessons[lessonIndex - 1];
                            shouldLock = previousLesson.isCompleted != true;
                          }
                          finalLocked = isLessonLocked || shouldLock;
                        }

                        return _buildLessonItem(
                          lesson,
                          lessonIndex + 1,
                          finalLocked,
                          course,
                          module,
                          surfaceColor,
                          textColor,
                          secondaryTextColor,
                          isDark,
                        );
                      }).toList(),
                      // Module Assessment Card (always show, but can be taken after lessons are completed)
                      _buildModuleAssessmentCard(
                        module,
                        testPassed,
                        module?.testScore,
                        hasTestScore,
                        surfaceColor,
                        textColor,
                        secondaryTextColor,
                        isDark,
                        accent,
                      ),
                      // Module Project Card (if module has project)
                      if (module?.projectId != null)
                        _buildModuleProjectCard(
                          module!,
                          course,
                          surfaceColor,
                          textColor,
                          secondaryTextColor,
                          isDark,
                          accent,
                        ),
                      // VR Experience Card (if module has VR)
                      if (module?.hasVR == true)
                        _buildVRExperienceCard(
                          module!,
                          course,
                          surfaceColor,
                          textColor,
                          secondaryTextColor,
                          isDark,
                          accent,
                        ),
                      // DIY Activities Card (if module has DIY lessons)
                      if (module?.lessons != null &&
                          module!.lessons!.any((l) => l.type == 'diy'))
                        _buildModuleDIYCard(
                          module,
                          course,
                          surfaceColor,
                          textColor,
                          secondaryTextColor,
                          isDark,
                          accent,
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleIcon(
    bool isLocked,
    bool isCompleted,
    bool isActive,
    int progressPercent,
    int index,
    Color accent,
    Color secondaryTextColor,
    bool isDark,
  ) {
    if (isLocked) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.lock, size: 18, color: secondaryTextColor),
      );
    }

    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: 20, color: accent),
      );
    }

    if (isActive) {
      // Circular progress indicator
      return SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progressPercent / 100,
                strokeWidth: 3,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            // Percentage text
            Text(
              "$progressPercent",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0f172a),
              ),
            ),
          ],
        ),
      );
    }

    // Default: show module number
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          index.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
    );
  }

  Widget _buildModuleAssessmentCard(
    Module? module,
    bool testPassed,
    int? testScore,
    bool hasTestScore,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color accent,
  ) {
    // Create a lesson object for the module quiz
    final moduleQuizLesson = Lesson()
      ..id = module?.id ?? "module_quiz"
      ..title = "${module?.title ?? 'Module'} Assessment"
      ..type = "quiz"
      ..moduleId = module?.id
      ..courseId = module?.courseId;

    return InkWell(
      onTap: () {
        // Navigate to quiz page for module assessment
        routeTo(QuizPage.path, data: {
          "lesson": moduleQuizLesson,
          "course": course,
          "module": module,
          "isModuleQuiz": true, // Flag to indicate this is a module-level quiz
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(left: 44, right: 16, top: 8, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey[300]!,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            // Quiz Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz,
                size: 18,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            // Quiz Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Module Assessment",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    testPassed ? "Test Passed" : "Test Required",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: testPassed ? accent : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            // Score/Requirement Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasTestScore && testScore != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$testScore%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: testPassed ? accent : Colors.orange,
                        ),
                      ),
                      Text(
                        testPassed ? "Passed" : "Failed",
                        style: TextStyle(
                          fontSize: 11,
                          color: testPassed ? accent : Colors.orange,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    "Score 80% to\nUnlock Next",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonItem(
    Lesson lesson,
    int lessonNumber,
    bool isLocked,
    Course course,
    Module? module,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final duration = lesson.duration ?? 15;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    final durationText =
        minutes > 0 ? "${minutes}m ${seconds}s" : "${seconds}s";

    return Container(
      margin: const EdgeInsets.only(left: 44, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: isLocked
            ? (isDark
                ? Colors.white.withValues(alpha: 0.01)
                : Colors.grey[50]?.withValues(alpha: 0.5))
            : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : (Colors.grey[100] ?? Colors.grey).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isLocked
            ? null
            : () {
                routeTo(LessonDetailPage.path, data: {
                  "lesson": lesson,
                  "course": course,
                  "module": module,
                  "isEnrolled": _isEnrolled(course),
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Lesson Icon/Number
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isLocked
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[200])
                      : (lesson.isCompleted == true
                          ? accent.withValues(alpha: 0.2)
                          : accent.withValues(alpha: 0.1)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isLocked
                      ? Icon(Icons.lock, size: 14, color: secondaryTextColor)
                      : lesson.isCompleted == true
                          ? Icon(Icons.check_circle, size: 16, color: accent)
                          : Text(
                              lessonNumber.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              // Lesson Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title ?? "Lesson $lessonNumber",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? textColor.withValues(alpha: 0.6)
                            : textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          lesson.type == 'video'
                              ? Icons.play_circle_outline
                              : lesson.type == 'quiz'
                                  ? Icons.quiz
                                  : Icons.article,
                          size: 12,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          durationText,
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                        if (lesson.isCompleted == true) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle, size: 12, color: accent),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isLocked
                    ? secondaryTextColor.withValues(alpha: 0.5)
                    : secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsTab(
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    // Calculate average rating and rating distribution from real data
    double averageRating = 0.0;
    int totalReviews = _reviews.length;
    Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    if (_reviews.isNotEmpty) {
      int totalRating = 0;
      for (var review in _reviews) {
        final rating = review.rating ?? 5;
        totalRating += rating;
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
      }
      averageRating = totalRating / totalReviews;
    }

    // Calculate percentages
    Map<int, double> ratingPercentages = {};
    for (int i = 5; i >= 1; i--) {
      ratingPercentages[i] =
          totalReviews > 0 ? (ratingCounts[i] ?? 0) / totalReviews : 0.0;
    }

    return StatefulBuilder(
      builder: (context, setModalState) {
        String _selectedFilter = "Most Recent";
        _reviewController ??= TextEditingController();

        // Filter reviews based on selected filter
        List<Review> filteredReviews = List.from(_reviews);
        if (_selectedFilter == "Highest Rated") {
          filteredReviews
              .sort((a, b) => (b.rating ?? 5).compareTo(a.rating ?? 5));
        } else if (_selectedFilter == "Lowest Rated") {
          filteredReviews
              .sort((a, b) => (a.rating ?? 5).compareTo(b.rating ?? 5));
        } else if (_selectedFilter == "Most Recent") {
          filteredReviews.sort((a, b) {
            final aDate = a.createdAt ?? DateTime(2000);
            final bDate = b.createdAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : (Colors.grey[100] ?? Colors.grey),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          final starRating = index + 1;
                          if (starRating <= averageRating.floor()) {
                            return Icon(Icons.star, size: 20, color: accent);
                          } else if (starRating == averageRating.ceil() &&
                              averageRating % 1 >= 0.5) {
                            return Icon(Icons.star_half,
                                size: 20, color: accent);
                          } else {
                            return Icon(Icons.star_border,
                                size: 20, color: accent.withValues(alpha: 0.3));
                          }
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingBar(5, ratingPercentages[5] ?? 0.0,
                            textColor, secondaryTextColor, isDark),
                        const SizedBox(height: 6),
                        _buildRatingBar(4, ratingPercentages[4] ?? 0.0,
                            textColor, secondaryTextColor, isDark),
                        const SizedBox(height: 6),
                        _buildRatingBar(3, ratingPercentages[3] ?? 0.0,
                            textColor, secondaryTextColor, isDark),
                        const SizedBox(height: 6),
                        _buildRatingBar(2, ratingPercentages[2] ?? 0.0,
                            textColor, secondaryTextColor, isDark),
                        const SizedBox(height: 6),
                        _buildRatingBar(1, ratingPercentages[1] ?? 0.0,
                            textColor, secondaryTextColor, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[200]),
            const SizedBox(height: 12),
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                      "Most Recent", _selectedFilter == "Most Recent", () {
                    setModalState(() => _selectedFilter = "Most Recent");
                  }, surfaceColor, textColor, secondaryTextColor, isDark),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                      "Highest Rated", _selectedFilter == "Highest Rated", () {
                    setModalState(() => _selectedFilter = "Highest Rated");
                  }, surfaceColor, textColor, secondaryTextColor, isDark),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                      "Lowest Rated", _selectedFilter == "Lowest Rated", () {
                    setModalState(() => _selectedFilter = "Lowest Rated");
                  }, surfaceColor, textColor, secondaryTextColor, isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Write Review Section
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Write a Review",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rating Selection
                  Row(
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedRating = rating;
                          });
                        },
                        child: Icon(
                          rating <= _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 32,
                          color: rating <= _selectedRating
                              ? accent
                              : Colors.grey[400],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Review Text Input
                  TextField(
                    controller: _reviewController,
                    style: TextStyle(color: textColor),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Share your experience with this course...",
                      hintStyle: TextStyle(color: secondaryTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accent, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _submitReview();
                        setModalState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Submit Review",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Reviews List
            if (filteredReviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.reviews_outlined,
                          size: 64, color: secondaryTextColor),
                      const SizedBox(height: 16),
                      Text(
                        "No reviews yet",
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Be the first to review this course!",
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredReviews
                  .map((review) => _buildReviewItem(
                        review,
                        surfaceColor,
                        textColor,
                        secondaryTextColor,
                        isDark,
                      ))
                  .toList(),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildReviewItem(
    Review review,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent.withValues(alpha: 0.2),
                backgroundImage:
                    review.userAvatar != null && review.userAvatar!.isNotEmpty
                        ? NetworkImage(getImageUrl(review.userAvatar!))
                        : null,
                child: review.userAvatar == null || review.userAvatar!.isEmpty
                    ? Text(
                        (review.userName ?? 'A')[0].toUpperCase(),
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
                    Row(
                      children: [
                        Text(
                          review.userName ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if (review.isVerified == true) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified, size: 16, color: accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review.rating ?? 5)
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: accent,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _formatReviewTime(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewTime(DateTime? dateTime) {
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

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent : surfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[200]!),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && label == "Most Recent")
              Icon(Icons.sort, size: 18, color: Colors.white),
            if (isSelected && label == "Most Recent") const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorTab(
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final mainTutor = course?.tutor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : (Colors.grey[100] ?? Colors.grey),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: primary.withValues(alpha: 0.2), width: 2),
                  image: mainTutor?.avatar != null &&
                          mainTutor!.avatar!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(getImageUrl(mainTutor.avatar!)),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: (mainTutor?.avatar == null || mainTutor!.avatar!.isEmpty)
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.15),
                        ),
                        child: Center(
                          child: Text(
                            (mainTutor?.name?.isNotEmpty == true
                                    ? mainTutor!.name![0].toUpperCase()
                                    : "I")
                                .toString(),
                            style: TextStyle(
                              color: primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainTutor?.name ?? "Instructor",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course?.category?.name ?? "Course Tutor",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stripHtmlTags(
                          mainTutor?.bio ?? "Instructor for this course."),
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: secondaryTextColor),
                onPressed: () {
                  // TODO: View instructor profile
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModuleProjectCard(
    Module module,
    Course course,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color accent,
  ) {
    return InkWell(
      onTap: () {
        // Navigate to module project
        final assignment = Assignment()
          ..id = module.projectId
          ..courseId = course.id
          ..moduleId = module.id
          ..title = "${module.title ?? 'Module'} Capstone Project"
          ..description =
              "Complete this capstone project to demonstrate mastery of module concepts."
          ..brief =
              "In this project, you will apply all the concepts learned in this module. Design and implement a comprehensive solution that showcases your understanding."
          ..requirements = [
            "Include all required components",
            "Follow the formatting guidelines",
            "Submit in PDF or DOCX format",
            "Include diagrams and calculations",
          ]
          ..resources = [
            {
              "name": "Project_Template_v2.pdf",
              "url": "https://example.com/template.pdf",
              "type": "pdf",
              "size": "2.4 MB",
            },
            {
              "name": "Grading_Rubric.docx",
              "url": "https://example.com/rubric.docx",
              "type": "docx",
              "size": "1.1 MB",
            },
          ]
          ..dueDate = DateTime.now().add(const Duration(days: 14))
          ..estimatedHours = 4
          ..status = 'not_submitted';

        routeTo(AssignmentPage.path, data: {
          "assignment": assignment,
          "course": course,
          "module": module,
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(left: 44, right: 16, top: 8, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey[300]!,
            width: 1,
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
              ),
              child: Icon(Icons.assignment, color: accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Module Project",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Capstone Project",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: secondaryTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVRExperienceCard(
    Module module,
    Course course,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 44, right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3D6360),
            isDark ? const Color(0xFF0A1612) : const Color(0xFF102214),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Step into the ${module.title ?? 'Module'}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Experience immersive 3D learning in a virtual environment.",
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleDIYCard(
    Module module,
    Course course,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color accent,
  ) {
    final diyLessons =
        module.lessons?.where((l) => l.type == 'diy').toList() ?? [];

    return Container(
      margin: const EdgeInsets.only(left: 44, right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                "DIY Activities",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  "${diyLessons.length} Activities",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...diyLessons.take(3).map((lesson) {
            return InkWell(
              onTap: () {
                routeTo(LessonDetailPage.path, data: {
                  "lesson": lesson,
                  "course": course,
                  "module": module,
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.build, size: 20, color: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lesson.title ?? "DIY Activity",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18, color: secondaryTextColor),
                  ],
                ),
              ),
            );
          }).toList(),
          if (diyLessons.length > 3)
            TextButton(
              onPressed: () {
                // Show all DIY activities
              },
              child: Text(
                "View All ${diyLessons.length} Activities",
                style: TextStyle(color: accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseProjectCard(
    Course course,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color accent,
  ) {
    return InkWell(
      onTap: () {
        // Navigate to course project
        final assignment = Assignment()
          ..id = course.projectId
          ..courseId = course.id
          ..title = "${course.title ?? 'Course'} Capstone Project"
          ..description =
              "Complete this comprehensive capstone project to demonstrate mastery of all course concepts."
          ..brief =
              "In this final project, you will integrate all the knowledge and skills acquired throughout the course. Design and implement a comprehensive solution that showcases your understanding of sustainable farming practices."
          ..requirements = [
            "Include all required components from all modules",
            "Follow the formatting guidelines",
            "Submit in PDF or DOCX format",
            "Include diagrams, calculations, and analysis",
            "Provide a detailed implementation plan",
          ]
          ..resources = [
            {
              "name": "Capstone_Project_Template.pdf",
              "url": "https://example.com/capstone_template.pdf",
              "type": "pdf",
              "size": "3.2 MB",
            },
            {
              "name": "Final_Project_Rubric.docx",
              "url": "https://example.com/final_rubric.docx",
              "type": "docx",
              "size": "1.5 MB",
            },
          ]
          ..dueDate = DateTime.now().add(const Duration(days: 30))
          ..estimatedHours = 8
          ..status = 'not_submitted';

        routeTo(AssignmentPage.path, data: {
          "assignment": assignment,
          "course": course,
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.workspace_premium, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Course Capstone Project",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Final project integrating all course concepts",
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: accent, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPreviewVideo(BuildContext context, bool isDark, Color bgColor,
      Color textColor, Color secondaryTextColor) {
    if (_previewVideoController == null) {
      // Initialize if not already done
      _initializePreviewVideo();
      if (_previewVideoController == null) {
        print("Failed to initialize preview video");
        return;
      }
      // Reinitialize with autoplay for fullscreen preview
      try {
        final currentVideoId = _previewVideoController!.metadata.videoId;
        _previewVideoController!.dispose();
        _previewVideoController = YoutubePlayerController(
          initialVideoId: currentVideoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            showLiveFullscreenButton: true,
            controlsVisibleAtStart: true,
          ),
        );
      } catch (e) {
        print("Error updating preview video flags: $e");
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
                          "Course Preview",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course?.title ?? "Preview",
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
            // Video Player
            Expanded(
              child: AspectRatio(
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
                    controller: _previewVideoController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: accent,
                    progressColors: ProgressBarColors(
                      playedColor: accent,
                      handleColor: accent,
                    ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
