import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/models/lesson.dart';
import '/app/controllers/course_detail_controller.dart';
import '/resources/pages/course_detail_page.dart';
import '/resources/pages/quiz_page.dart';
import '/resources/pages/lesson_detail_page.dart';
import '/resources/pages/assignment_page.dart';
import '/resources/pages/notes_page.dart';
import '/app/models/assignment.dart';
import '/app/services/progression_service.dart';

class ModulesOverviewPage extends NyStatefulWidget<CourseDetailController> {
  static RouteView path = ("/modules-overview", (_) => ModulesOverviewPage());

  ModulesOverviewPage({super.key})
      : super(child: () => _ModulesOverviewPageState());
}

class _ModulesOverviewPageState extends NyPage<ModulesOverviewPage> {
  Course? course;
  Map<String, int> _moduleProgress = {}; // moduleId -> progress percentage
  Map<String, int?> _moduleTestScores = {}; // moduleId -> test score

  // Color scheme
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  @override
  get init => () async {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          course = data['course'] as Course?;
          if (course != null) {
            await widget.controller.loadCourseDetails(course!.id!);
            course = widget.controller.course;
            // Update module locks based on progression
            if (course != null) {
              await ProgressionService.updateModuleLocks(course!);
            }
            await _loadModuleProgress();
            setState(() {});
          }
        }
      };

  Future<void> _loadModuleProgress() async {
    if (course?.modules == null) return;

    for (final module in course!.modules!) {
      // Calculate lesson progress
      final lessons = module.lessons ?? [];
      if (lessons.isNotEmpty) {
        final completedLessons =
            lessons.where((l) => l.isCompleted == true).length;
        final lessonProgress =
            (completedLessons / lessons.length * 100).toInt();
        _moduleProgress[module.id!] = lessonProgress;
      }

      // Get test score
      if (module.testScore != null) {
        _moduleTestScores[module.id!] = module.testScore;
      }
    }
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF0f172a);
    final secondaryTextColor = isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : (Colors.grey[600] ?? Colors.grey);

    if (course == null || course!.modules == null || course!.modules!.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: textColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Modules",
            style: TextStyle(color: textColor),
          ),
        ),
        body: Center(
          child: Text(
            "No modules available",
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      );
    }

    // Calculate overall course progress
    final totalModules = course!.modules!.length;
    int completedModules = 0;
    int totalProgress = 0;
    for (final module in course!.modules!) {
      final progress = _moduleProgress[module.id!] ?? 0;
      totalProgress += progress;
      if (module.isCompleted == true) {
        completedModules++;
      }
    }
    final overallProgress =
        totalModules > 0 ? (totalProgress / totalModules).toInt() : 0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: textColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Course Modules",
          style: TextStyle(color: textColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: textColor,
            onPressed: () async {
              await _loadModuleProgress();
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Progress Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Course Progress",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "$overallProgress%",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: overallProgress / 100,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : (Colors.grey[200] ?? Colors.grey),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$completedModules of $totalModules modules completed",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Modules List
            Text(
              "All Modules",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...course!.modules!.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              final progress = _moduleProgress[module.id!] ?? 0;
              final testScore = _moduleTestScores[module.id!];
              final isCompleted = module.isCompleted == true;
              final testPassed = module.testPassed == true ||
                  (testScore != null && testScore >= 80);
              final isLocked = module.isLocked == true;

              return _buildModuleCard(
                module,
                index + 1,
                progress,
                testScore,
                isCompleted,
                testPassed,
                isLocked,
                textColor,
                secondaryTextColor,
                isDark,
                bgColor,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    Module module,
    int moduleNumber,
    int progress,
    int? testScore,
    bool isCompleted,
    bool testPassed,
    bool isLocked,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color bgColor,
  ) {
    return InkWell(
      onTap: isLocked
          ? null
          : () {
              // Navigate to course detail page with curriculum tab selected and module expanded
              routeTo(CourseDetailPage.path, data: {
                "course": course,
                "selectedTab": "Curriculum",
                "expandModuleId": module.id,
              });
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Module Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked
                        ? Colors.grey.withValues(alpha: 0.1)
                        : (isCompleted
                            ? accent.withValues(alpha: 0.2)
                            : accent.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: isLocked
                        ? Icon(Icons.lock, color: Colors.grey, size: 24)
                        : (isCompleted
                            ? Icon(Icons.check, color: accent, size: 24)
                            : Text(
                                moduleNumber.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              )),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              module.title ?? "Module $moduleNumber",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isLocked ? Colors.grey : textColor,
                              ),
                            ),
                          ),
                          if (isLocked)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Locked",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocked
                            ? "Complete previous module with 80% to unlock"
                            : "${module.totalLessons ?? module.lessons?.length ?? 0} Lessons",
                        style: TextStyle(
                          fontSize: 14,
                          color: isLocked ? Colors.orange : secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress Percentage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$progress%",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    if (testScore != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: testPassed
                              ? accent.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Test: $testScore%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: testPassed ? accent : Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            LinearProgressIndicator(
              value: isLocked ? 0 : (progress / 100),
              backgroundColor:
                  isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isLocked ? Colors.grey : accent,
              ),
              minHeight: 6,
            ),
            const SizedBox(height: 16),
            // Sub Tutor Info
            if (module.subTutorName != null && !isLocked)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    if (module.subTutorAvatar != null &&
                        module.subTutorAvatar!.isNotEmpty)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(module.subTutorAvatar!),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.2),
                        ),
                        child: Icon(Icons.person, color: accent, size: 20),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sub Tutor",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            module.subTutorName ?? "Instructor",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (module.subTutorName != null && !isLocked)
              const SizedBox(height: 16),
            // Module Features (Projects, VR, DIY)
            if (module.projectId != null ||
                module.hasVR == true ||
                (module.lessons != null &&
                    module.lessons!.any((l) => l.type == 'diy')))
              Column(
                children: [
                  if (module.projectId != null)
                    _buildFeatureButton(
                      "Module Assignment",
                      Icons.assignment,
                      accent,
                      textColor,
                      isDark,
                      () {
                        final assignment = Assignment()
                          ..id = module.projectId
                          ..courseId = course?.id
                          ..moduleId = module.id
                          ..title =
                              "${module.title ?? 'Module'} Capstone Project"
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
                          ..dueDate =
                              DateTime.now().add(const Duration(days: 14))
                          ..estimatedHours = 4
                          ..status = 'not_submitted';

                        routeTo(AssignmentPage.path, data: {
                          "assignment": assignment,
                          "course": course,
                          "module": module,
                        });
                      },
                    ),
                  if (module.hasVR == true) ...[
                    const SizedBox(height: 8),
                    _buildFeatureButton(
                      "VR Experience",
                      Icons.rocket_launch,
                      const Color(0xFF3D6360),
                      textColor,
                      isDark,
                      () {
                        // Launch VR experience
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("VR Experience launching..."),
                            backgroundColor: accent,
                          ),
                        );
                      },
                    ),
                  ],
                  if (module.lessons != null &&
                      module.lessons!.any((l) => l.type == 'diy')) ...[
                    const SizedBox(height: 8),
                    _buildFeatureButton(
                      "DIY Activities",
                      Icons.build,
                      Colors.orange,
                      textColor,
                      isDark,
                      () {
                        // Show DIY activities
                        final diyLessons = module.lessons!
                            .where((l) => l.type == 'diy')
                            .toList();
                        if (diyLessons.isNotEmpty && course != null) {
                          routeTo(LessonDetailPage.path, data: {
                            "lesson": diyLessons.first,
                            "course": course,
                            "module": module,
                          });
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: course != null
                        ? () {
                            // Show lessons in a bottom sheet
                            _showLessonsBottomSheet(context, module, course!,
                                textColor, secondaryTextColor, isDark, bgColor);
                          }
                        : null,
                    icon: const Icon(Icons.book, size: 18),
                    label: const Text("View Lessons"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to module test
                      final moduleQuizLesson = Lesson()
                        ..id = module.id ?? "module_quiz"
                        ..title = "${module.title ?? 'Module'} Assessment"
                        ..type = "quiz"
                        ..moduleId = module.id
                        ..courseId = module.courseId;

                      routeTo(QuizPage.path, data: {
                        "lesson": moduleQuizLesson,
                        "course": course,
                        "module": module,
                        "isModuleQuiz": true,
                      });
                    },
                    icon: const Icon(Icons.quiz, size: 18),
                    label:
                        Text(testScore != null ? "Review Test" : "Take Test"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Notes Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: course != null
                    ? () {
                        routeTo(NotesPage.path, data: {
                          "course": course,
                          "module": module,
                        });
                      }
                    : null,
                icon: const Icon(Icons.note, size: 18),
                label: const Text("View Notes"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonsBottomSheet(
    BuildContext context,
    Module module,
    Course course,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color bgColor,
  ) {
    final lessons = module.lessons ?? [];
    final surfaceColor = isDark ? surfaceDark : Colors.white;
    final accent = Color(0xFF50C1AE);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                          module.title ?? "Module",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${lessons.length} Lessons",
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
            // Lessons List
            Expanded(
              child: lessons.isEmpty
                  ? Center(
                      child: Text(
                        "No lessons available",
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        final isLocked = lesson.isLocked == true;
                        final isCompleted = lesson.isCompleted == true;

                        return InkWell(
                          onTap: isLocked
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  routeTo(LessonDetailPage.path, data: {
                                    "lesson": lesson,
                                    "course": course,
                                    "module": module,
                                  });
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: Row(
                              children: [
                                // Lesson Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isLocked
                                        ? (isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.grey[200])
                                        : (isCompleted
                                            ? accent.withValues(alpha: 0.2)
                                            : accent.withValues(alpha: 0.1)),
                                  ),
                                  child: Center(
                                    child: isLocked
                                        ? Icon(Icons.lock,
                                            size: 18, color: secondaryTextColor)
                                        : isCompleted
                                            ? Icon(Icons.check_circle,
                                                size: 20, color: accent)
                                            : Text(
                                                "${index + 1}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: accent,
                                                ),
                                              ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Lesson Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson.title ?? "Lesson ${index + 1}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isLocked
                                              ? secondaryTextColor
                                              : textColor,
                                        ),
                                      ),
                                      if (lesson.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          lesson.description!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color:
                                      isLocked ? secondaryTextColor : textColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    String label,
    IconData icon,
    Color color,
    Color textColor,
    bool isDark,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
