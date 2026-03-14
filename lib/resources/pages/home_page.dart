import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/controllers/courses_controller.dart';
import '/app/helpers/text_helper.dart';
import '/app/helpers/storage_helper.dart';
import '/app/helpers/image_helper.dart';
import '/resources/pages/course_detail_page.dart';
import '/resources/pages/notifications_page.dart';
import '/resources/pages/community_forum_page.dart';
import '/resources/pages/certificates_page.dart';
import '/resources/pages/help_support_page.dart';
import '/resources/pages/courses_page.dart';
import '/config/keys.dart';

class HomePage extends NyStatefulWidget<CoursesController> {
  static RouteView path = ("/home", (_) => HomePage());

  HomePage({super.key}) : super(child: () => _HomePageState());
}

class _HomePageState extends NyPage<HomePage> {
  Map<String, dynamic>? _userData;
  List<Course> _allCourses = [];
  Course? _resumeCourse;

  // Color scheme from HTML
  static const Color primary = Color(0xFF3E6866);
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF161c1b);

  @override
  get init => () async {
        await _loadUserData();
        await _loadCourses();
        _findResumeCourse();
      };

  Future<void> _loadUserData() async {
    try {
      _userData = await Keys.auth.read<Map<String, dynamic>>();
      if (_userData == null) {
        _userData = safeReadAuthData();
      }
      setState(() {});
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to load user data: $e');
      }
      _userData = safeReadAuthData();
      setState(() {});
    }
  }

  Future<void> _loadCourses() async {
    await widget.controller.loadCourses();
    _allCourses = widget.controller.courses;
    setState(() {});
  }

  void _findResumeCourse() {
    final inProgress = _allCourses.where((c) => c.isCompleted != true).toList();
    if (inProgress.isEmpty) {
      _resumeCourse = null;
      return;
    }
    // Sort by progress (highest first)
    inProgress.sort((a, b) {
      final aProgress = (a.completedLessons ?? 0) / (a.totalLessons ?? 1);
      final bProgress = (b.completedLessons ?? 0) / (b.totalLessons ?? 1);
      return bProgress.compareTo(aProgress);
    });
    _resumeCourse = inProgress.first;
    setState(() {});
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    final userName = _userData?['name']?.toString() ?? "Alex Rivera";
    final userAvatar = _userData?['avatar']?.toString();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: bgColor,
              ),
              child: Row(
                children: [
                  // User Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: accent.withValues(alpha: 0.2), width: 2),
                      image: userAvatar != null && userAvatar.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(getImageUrl(userAvatar)),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: userAvatar == null || userAvatar.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withValues(alpha: 0.2),
                            ),
                            child: Center(
                              child: Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : "A",
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
                  const SizedBox(width: 12),
                  // Welcome Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good Morning,",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications, size: 20),
                      color: primary,
                      onPressed: () {
                        routeTo(NotificationsPage.path);
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[100]!,
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
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Icon(
                                Icons.search,
                                color: Colors.grey[400],
                                size: 22,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Search for courses...",
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Continue Learning Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Continue Learning",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to all courses
                            },
                            child: Text(
                              "View All",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Continue Learning Card
                    if (_resumeCourse != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildContinueLearningCard(
                          _resumeCourse!,
                          bgColor,
                          textColor,
                          isDark,
                        ),
                      ),
                    // My Dashboard Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Dashboard",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
                              _buildDashboardCard(
                                icon: Icons.book,
                                label: "My Courses",
                                iconColor: accent,
                                bgColor: accent.withValues(alpha: 0.1),
                                borderColor: accent.withValues(alpha: 0.2),
                                textColor: primary,
                                isDark: isDark,
                                onTap: () {
                                  routeTo(CoursesPage.path);
                                },
                              ),
                              _buildDashboardCard(
                                icon: Icons.workspace_premium,
                                label: "Certificates",
                                iconColor: primary,
                                bgColor: primary.withValues(alpha: 0.1),
                                borderColor: primary.withValues(alpha: 0.2),
                                textColor: primary,
                                isDark: isDark,
                                onTap: () {
                                  routeTo(CertificatesPage.path);
                                },
                              ),
                              _buildDashboardCard(
                                icon: Icons.groups,
                                label: "Community",
                                iconColor: primary,
                                bgColor: primary.withValues(alpha: 0.1),
                                borderColor: primary.withValues(alpha: 0.2),
                                textColor: primary,
                                isDark: isDark,
                                onTap: () {
                                  routeTo(CommunityForumPage.path);
                                },
                              ),
                              _buildDashboardCard(
                                icon: Icons.support_agent,
                                label: "Support",
                                iconColor: accent,
                                bgColor: accent.withValues(alpha: 0.1),
                                borderColor: accent.withValues(alpha: 0.2),
                                textColor: primary,
                                isDark: isDark,
                                onTap: () {
                                  routeTo(HelpSupportPage.path);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Daily Recommendation Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Daily Recommendation",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDailyRecommendationCard(
                            _allCourses.isNotEmpty ? _allCourses.first : null,
                            bgColor,
                            textColor,
                            secondaryTextColor,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearningCard(
    Course course,
    Color bgColor,
    Color textColor,
    bool isDark,
  ) {
    final progress = course.totalLessons != null && course.totalLessons! > 0
        ? (course.completedLessons ?? 0) / course.totalLessons!
        : 0.0;
    final progressPercent = (progress * 100).toInt();

    return GestureDetector(
      onTap: () => routeTo(CourseDetailPage.path, data: {"course": course}),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[50]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image with Badge
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      image: course.thumbnail != null &&
                              course.thumbnail!.isNotEmpty
                          ? DecorationImage(
                              image:
                                  NetworkImage(getImageUrl(course.thumbnail!)),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: course.thumbnail == null || course.thumbnail!.isEmpty
                        ? const Center(
                            child: Icon(Icons.school,
                                size: 48, color: Colors.grey),
                          )
                        : null,
                  ),
                  // Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                    ),
                  ),
                  // In Progress Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "IN PROGRESS",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Course Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title ?? "Untitled Course",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "By ${course.tutor?.name ?? course.category?.name ?? 'Instructor'} • ${course.moduleCount != null && course.moduleCount! > 0 ? '${course.moduleCount} Modules' : '${course.totalLessons ?? 12} Lessons'}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "COURSE PROGRESS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[400],
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            "$progressPercent%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Resume Lesson Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => routeTo(CourseDetailPage.path,
                          data: {"course": course}),
                      icon: const Icon(Icons.play_circle, size: 20),
                      label: const Text("Resume Lesson"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ??
            () {
              // TODO: Navigate to respective page
            },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyRecommendationCard(
    Course? course,
    Color bgColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    if (course == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => routeTo(CourseDetailPage.path, data: {"course": course}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[100]!,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
                image: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(getImageUrl(course.thumbnail!)),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : const DecorationImage(
                        image: NetworkImage(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuAnW3EA6QRCZFTFvODuIByX2uGR-MBatiH7BpAVy_nDa27-0ndHm1Jtvf7zZeFPFqIwfXhDfJNXjXV7zF7hyd56HBM3epcjgc5qa1ztcI9JkLzoeoZ9X6Tmh1b7xb2HxvkepCACjJiE_BsDYeRJvXuifiIA27G3Q08bOwS3woL3IR2wIDxeB6fxYZLLge1L7BD5VODavTvfgRorxTCmrRQGYjluFVn74g7Jxe_ZbI-Gy-kjFCQ8l7TJbMS8wNi3DUp6X_hGma7or0I",
                        ),
                        fit: BoxFit.cover,
                      ),
              ),
              child: course.thumbnail == null || course.thumbnail!.isEmpty
                  ? const Center(
                      child: Icon(Icons.school, size: 32, color: Colors.grey),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Course Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title ?? "Soil Nutrition Basics",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stripHtmlTags(course.description ??
                            "Essential guide to maintaining soil health for premium crop yields."),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "EXPERT TIP",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "5 min read",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
