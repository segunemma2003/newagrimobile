import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/controllers/courses_controller.dart';
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

  @override
  get init => () async {
        await _loadUserData();
        await widget.controller.loadCourses();
        await widget.controller.loadCategories();
        setState(() {});
      };

  Future<void> _loadUserData() async {
    try {
      _userData = await Keys.auth.read<Map<String, dynamic>>();
      if (_userData == null) {
        _userData = backpackRead(Keys.auth);
      }
      setState(() {});
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to load user data: $e');
      }
      _userData = backpackRead(Keys.auth);
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
    final bgColor = accent.withValues(alpha: 0.1); // Maintain background color
    final cardColor = isDark ? surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey[900];
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[500];

    final userName = _userData?['name']?.toString() ?? "Alex Rivers";
    final firstName = userName.split(' ').first;

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
                                  image: NetworkImage(_userData!['avatar']),
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
    final progress = course.totalLessons != null && course.totalLessons! > 0
        ? (course.completedLessons ?? 0) / course.totalLessons!
        : 0.0;
    final progressPercent = (progress * 100).toInt();

    // Determine level based on progress or use placeholder
    final level = progressPercent < 30
        ? "Beginner"
        : progressPercent < 70
            ? "Intermediate"
            : "Advanced";

    // Course data with placeholders
    final courseTitles = [
      "Sustainable Crop Management",
      "Hydroponics Basics",
      "Precision Agri-Tech"
    ];
    final courseInstructors = [
      "Dr. Sarah James",
      "Prof. Marcus Chen",
      "Dr. Elena Rodriguez"
    ];
    final courseProgress = [65, 22, 89];
    final courseLevels = ["Intermediate", "Beginner", "Advanced"];
    final courseImages = [
      "https://lh3.googleusercontent.com/aida-public/AB6AXuBLxwirSVnr11yzO-QJFnYMKcSvuzT9oJROn-1RDVwIT5w561uc67Of8RlhLeyVR4ZOZ8-yYMMqL-3_h0ajhzI5Fi-eqz_5GEprZAC8_eoa0uX_N63YFzYD7tL2_RAFzjKhIQYlCSL063VlpZJ_4wTJcjLBPb9kxy4vN7JZHvp-ZfkyIsqKwK_bFXdzFM10PJofv6lnA1mng5mZkQ5nOu9trIKWTfnstLoC9EWAFb3xvBhhSWv8iG4AW4fItlbYcu-tw8xi1SwdNo8",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCkmgxAhwO9byrfOwzBYvjEL_EI26zI45kfgUyFqZvKY_CUNd6G6Yo_ohNJply0jafw9vFu8jniOHT_no5o5bkoiOfHSoz-qertGQU-eacwgoHpsiL0NfZ2KU9E_JEUyXeODDALbPMrpKQHQGV_e7yEfb1Jfz3-yNbmAnsFukYQ8gT8f42f5mnHeMaJh2r2rp7FZu6wnpnkp2Qj4a0kZ2WP6kQLjnoMcbcYB3MITFCVxGnLbThr4QqZln_zH7rIZct5SnCChaSkv9A",
      "https://lh3.googleusercontent.com/aida-public/AB6AXuB6QqZAdcgkQ2dp14I4HTXNUtM7XHlIdFyPvdLbQA4S1nlvWHyksPj-SWh-yNm84OF9gMTfTAg9Sj4wX7VENcpBXVFGZiBgLtGcbHcF02CZSsAayBpwoON-MLeTR2sI5ghRtua8q4z4Yb-9-QP7lObYX-goxFN0MKXgLqe0GOokqwOSW26gOnlrIwuXMBybbilZr8Y1QRH8VDm8QiIVJ-I_lunjCYnOJP6AdlFr5uwynj3tvf12oj0SBRrMDfCcbtLqtekZUkVMzYk",
    ];

    final index = _ongoingCourses.indexOf(course);
    final displayTitle = index < courseTitles.length
        ? courseTitles[index]
        : (course.title ?? "Untitled Course");
    final displayInstructor = index < courseInstructors.length
        ? courseInstructors[index]
        : (course.category?.name ?? "Instructor");
    final displayProgress =
        index < courseProgress.length ? courseProgress[index] : progressPercent;
    final displayLevel =
        index < courseLevels.length ? courseLevels[index] : level;
    final displayImage = index < courseImages.length
        ? courseImages[index]
        : (course.thumbnail ?? "");

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
                              image: NetworkImage(displayImage),
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
