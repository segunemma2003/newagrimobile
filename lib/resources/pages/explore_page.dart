import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/controllers/courses_controller.dart';
import '/resources/pages/course_detail_page.dart';
import '/resources/pages/notifications_page.dart';

class ExplorePage extends NyStatefulWidget<CoursesController> {
  static RouteView path = ("/explore", (_) => ExplorePage());

  ExplorePage({super.key}) : super(child: () => _ExplorePageState());
}

class _ExplorePageState extends NyPage<ExplorePage> {
  List<Course> _allCourses = [];

  // Color scheme from HTML
  static const Color primary = Color(0xFF50C1AE);
  static const Color secondary = Color(0xFF3E6866);
  static const Color charcoal = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1f2928);

  @override
  get init => () async {
        await widget.controller.loadCourses();
        await widget.controller.loadCategories();
        _allCourses = widget.controller.courses;
        setState(() {});
      };

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = secondary.withOpacity(0.1); // Maintain background color
    final cardColor = isDark ? surfaceDark : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : Colors.grey[900];
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[500];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Logo and Title
                  Row(
                    children: [
                      Image.asset(
                        "logo-without.png",
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ).localAsset(),
                      const SizedBox(width: 8),
                      Text(
                        "Explore",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
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
                    const SizedBox(height: 24),
                    // Hero Banner Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              secondary,
                              secondary.withOpacity(0.8),
                              primary.withOpacity(0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: secondary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative elements
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary.withOpacity(0.2),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -20,
                              left: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary.withOpacity(0.15),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Discover New Courses",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Explore our curated collection of agriculture courses",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Featured Courses Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Featured Courses",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Featured Courses Horizontal Scroll
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            _allCourses.length >= 3 ? 3 : _allCourses.length,
                        itemBuilder: (context, index) {
                          final course = _allCourses[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildFeaturedCourseCard(
                              course,
                              index == 0
                                  ? "Bestseller"
                                  : index == 1
                                      ? "New"
                                      : "Popular",
                              index == 0
                                  ? primary
                                  : index == 1
                                      ? secondary
                                      : primary,
                              textColor ?? Colors.grey[900]!,
                              secondaryTextColor ?? Colors.grey[500]!,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Recommended for You Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Recommended for You",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Recommended Courses List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _allCourses
                            .take(2)
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final course = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildRecommendedCourseCard(
                              course,
                              index,
                              cardColor,
                              textColor ?? Colors.grey[900]!,
                              secondaryTextColor ?? Colors.grey[500]!,
                            ),
                          );
                        }).toList(),
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

  Widget _buildFeaturedCourseCard(
    Course course,
    String badge,
    Color badgeColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return GestureDetector(
      onTap: () => routeTo(CourseDetailPage.path, data: {"course": course}),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[300],
                image: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(course.thumbnail!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badge == "Bestseller" || badge == "Popular"
                              ? charcoal
                              : Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Course Info
            Text(
              course.title ?? "Modern Irrigation Systems",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              course.description?.substring(
                      0,
                      course.description!.length > 50
                          ? 50
                          : course.description!.length) ??
                  "Master water management for efficiency",
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$49.99",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      "4.9 (1.2k)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCourseCard(
    Course course,
    int index,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final courseTitles = ["Digital Farming 101", "Sustainable Livestock"];
    final courseSubtitles = ["By Dr. Elena Vance", "Animal Science Essentials"];
    final coursePrices = ["\$24.00", "Free"];
    final courseButtons = ["Enroll", "Start Now"];

    return GestureDetector(
      onTap: () => routeTo(CourseDetailPage.path, data: {"course": course}),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
                image: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(course.thumbnail!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
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
                children: [
                  Text(
                    index < courseTitles.length
                        ? courseTitles[index]
                        : (course.title ?? "Untitled Course"),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    index < courseSubtitles.length
                        ? courseSubtitles[index]
                        : "By ${course.category?.name ?? 'Instructor'}",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        index < coursePrices.length
                            ? coursePrices[index]
                            : "\$24.00",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => routeTo(CourseDetailPage.path,
                            data: {"course": course}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              index == 0 ? secondary.withOpacity(0.2) : primary,
                          foregroundColor: index == 0 ? primary : charcoal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          index < courseButtons.length
                              ? courseButtons[index]
                              : "Enroll",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
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
