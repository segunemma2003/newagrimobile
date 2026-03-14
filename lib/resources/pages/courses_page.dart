import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/controllers/courses_controller.dart';
import '/app/helpers/storage_helper.dart';
import '/app/helpers/image_helper.dart';
import '/resources/pages/course_detail_page.dart';
import '/resources/pages/notifications_page.dart';
import '/config/keys.dart';

class CoursesPage extends NyStatefulWidget<CoursesController> {
  static RouteView path = ("/courses", (_) => CoursesPage());

  CoursesPage({super.key}) : super(child: () => _CoursesPageState());
}

class _CoursesPageState extends NyPage<CoursesPage> {
  String _selectedTab = "Ongoing";
  Map<String, dynamic>? _userData;

  // Color scheme from HTML
  static const Color primary = Color(0xFF3E6866);
  static const Color accent = Color(0xFF50C1AE);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF161c1b);

  @override
  get init => () async {
        // Load user data first (fast)
        await _loadUserData();

        // Load courses from storage immediately (fast)
        await widget.controller.loadCoursesFromStorage();

        // Update UI immediately with cached data
        setState(() {});

        // Load categories in background (non-blocking)
        widget.controller.loadCategories().then((_) {
          if (mounted) {
            setState(() {});
          }
        }).catchError((e) {
          print("Error loading categories: $e");
        });

        // Sync courses in background (non-blocking) - don't block UI
        // Only sync if online, don't await it
        widget.controller.syncCourses().then((_) {
          // Update UI after sync completes
          if (mounted) {
            setState(() {});
          }
        }).catchError((e) {
          print("Error syncing courses: $e");
        });
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

  List<Course> get _ongoingCourses {
    return widget.controller.courses
        .where((course) => course.isCompleted != true)
        .toList();
  }

  List<Course> get _completedCourses {
    return widget.controller.courses
        .where((course) => course.isCompleted == true)
        .toList();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final cardColor = isDark ? surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey[900];
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[500];

    final userName = _userData?['name']?.toString();
    final displayName = (userName != null && userName.trim().isNotEmpty) 
        ? userName.trim() 
        : "User";
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: Row(
                children: [
                  // Back button to main home page
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: textColor,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 4),
                  // User Avatar and Name
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primary, width: 2),
                          image: _userData?['avatar'] != null &&
                                  _userData!['avatar'].toString().isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                      getImageUrl(_userData!['avatar'])),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                )
                              : null,
                        ),
                        child: _userData?['avatar'] == null ||
                                _userData!['avatar'].toString().isEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary.withValues(alpha: 0.2),
                                ),
                                child: Center(
                                  child: Text(
                                    firstName.isNotEmpty
                                        ? firstName[0].toUpperCase()
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action buttons
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 24),
                    color: textColor,
                    onPressed: () {
                      routeTo(NotificationsPage.path);
                    },
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // My Learning Title and Tabs
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Learning",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Tabs
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTab(
                                      "Ongoing",
                                      _selectedTab == "Ongoing",
                                      cardColor,
                                      textColor ?? Colors.grey[900]!,
                                      secondaryTextColor ?? Colors.grey[500]!,
                                      isDark),
                                  const SizedBox(width: 12),
                                  _buildTab(
                                      "Completed",
                                      _selectedTab == "Completed",
                                      cardColor,
                                      textColor ?? Colors.grey[900]!,
                                      secondaryTextColor ?? Colors.grey[500]!,
                                      isDark),
                                  const SizedBox(width: 12),
                                  _buildTab(
                                      "Saved",
                                      _selectedTab == "Saved",
                                      cardColor,
                                      textColor ?? Colors.grey[900]!,
                                      secondaryTextColor ?? Colors.grey[500]!,
                                      isDark),
                                  const SizedBox(width: 12),
                                  _buildTab(
                                      "Certificates",
                                      _selectedTab == "Certificates",
                                      cardColor,
                                      textColor ?? Colors.grey[900]!,
                                      secondaryTextColor ?? Colors.grey[500]!,
                                      isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Active Courses Section
                      if (_selectedTab == "Ongoing") ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Active Courses",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "${_ongoingCourses.length} Total",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Course Cards
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: _ongoingCourses.take(3).map((course) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildCourseCard(
                                  course,
                                  cardColor,
                                  textColor ?? Colors.grey[900]!,
                                  secondaryTextColor ?? Colors.grey[500]!,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      // Completed Courses
                      if (_selectedTab == "Completed") ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Completed Courses",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "${_completedCourses.length} Total",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: _completedCourses.map((course) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildCourseCard(
                                  course,
                                  cardColor,
                                  textColor ?? Colors.grey[900]!,
                                  secondaryTextColor ?? Colors.grey[500]!,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      // Empty states for other tabs
                      if (_selectedTab != "Ongoing" &&
                          _selectedTab != "Completed") ...[
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 64,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No ${_selectedTab.toLowerCase()} courses",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, Color cardColor,
      Color textColor, Color secondaryTextColor, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color:
              isSelected ? primary : (isDark ? surfaceDark : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[300]! : Colors.grey[600]!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, Color cardColor, Color textColor,
      Color secondaryTextColor) {
    final totalUnits = course.totalLessons ?? course.lessonsCount ?? 0;
    final completedUnits = course.completedLessons ?? 0;
    final progress = totalUnits > 0 ? completedUnits / totalUnits : 0.0;
    final progressPercent = (progress * 100).toInt();

    // Use real data from API with sensible fallbacks
    final displayTitle = course.title ?? "Untitled Course";
    final displayInstructor =
        course.tutor?.name ?? course.category?.name ?? "Instructor";
    final displayProgress = progressPercent;
    final displayLevel = course.level?.isNotEmpty == true
        ? course.level!
        : (progressPercent < 30
            ? "Beginner"
            : progressPercent < 70
                ? "Intermediate"
                : "Advanced");
    final displayImage = course.thumbnail ?? "";

    return GestureDetector(
      onTap: () => routeTo(CourseDetailPage.path, data: {"course": course}),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      image: displayImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(getImageUrl(displayImage)),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: displayImage.isEmpty
                        ? const Center(
                            child: Icon(Icons.school,
                                size: 48, color: Colors.grey),
                          )
                        : null,
                  ),
                  // Level Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        displayLevel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
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
                    displayTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayInstructor,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Course Progress",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                          Text(
                            "$displayProgress%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 8,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[200],
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: displayProgress / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Resume Learning Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => routeTo(CourseDetailPage.path,
                          data: {"course": course}),
                      icon: const Icon(Icons.play_circle, size: 20),
                      label: const Text(
                        "Resume Learning",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
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
}
