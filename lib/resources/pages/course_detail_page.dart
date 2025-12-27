import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/models/lesson.dart';
import '/app/controllers/course_detail_controller.dart';
import '/resources/widgets/safearea_widget.dart';
import '/resources/pages/lesson_detail_page.dart';
import '/bootstrap/extensions.dart';

class CourseDetailPage extends NyStatefulWidget<CourseDetailController> {
  static RouteView path = ("/course-detail", (_) => CourseDetailPage());

  CourseDetailPage({super.key}) : super(child: () => _CourseDetailPageState());
}

class _CourseDetailPageState extends NyPage<CourseDetailPage> {
  Course? course;

  @override
  get init => () async {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          course = data['course'] as Course?;
          if (course != null) {
            await widget.controller.loadCourseDetails(course!.id!);
            // Update the local course reference with the loaded course (which has modules)
            course = widget.controller.course;
            setState(() {});
          }
        }
      };

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final displayCourse = widget.controller.course ?? course;

    if (displayCourse == null) {
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
            "Course",
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: Text("Course not found")),
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
          displayCourse.title ?? "Course",
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
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
                displayCourse.title ?? "Untitled Course",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).displayLarge(color: context.color.primaryAccent),
              const SizedBox(height: 8),
              Text(
                displayCourse.description ?? "",
                style: const TextStyle(fontSize: 16),
              ).bodyLarge(color: context.color.content),
              const SizedBox(height: 24),
              _buildProgressSection(context, displayCourse),
              const SizedBox(height: 24),
              Text(
                displayCourse.modules != null && displayCourse.modules!.isNotEmpty
                    ? "Modules"
                    : "Curriculum",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ).titleLarge(color: context.color.surfaceContent),
              const SizedBox(height: 16),
              // Always prefer modules if available, otherwise show curriculum
              if (displayCourse.modules != null && displayCourse.modules!.isNotEmpty)
                _buildModulesList(context, displayCourse)
              else if (displayCourse.lessons != null && displayCourse.lessons!.isNotEmpty)
                _buildCurriculumList(context, displayCourse)
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text("No content available")
                        .bodyMedium(color: context.color.content.withOpacity(0.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, Course course) {
    final progress = course.completedLessons != null &&
            course.totalLessons != null &&
            course.totalLessons! > 0
        ? (course.completedLessons! / course.totalLessons!) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progress").titleMedium(color: context.color.surfaceContent),
              Text("${progress.toStringAsFixed(0)}%")
                  .titleMedium(color: context.color.primaryAccent),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: context.color.primaryAccent.withOpacity(0.1),
            valueColor:
                AlwaysStoppedAnimation<Color>(context.color.primaryAccent),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            "${course.completedLessons ?? 0} of ${course.totalLessons ?? 0} lessons completed",
          ).bodySmall(color: context.color.surfaceContent),
        ],
      ),
    );
  }

  Widget _buildModulesList(BuildContext context, Course course) {
    if (course.modules == null || course.modules!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text("No modules available")
              .bodyMedium(color: context.color.content.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: course.modules!.length,
      itemBuilder: (context, index) {
        final module = course.modules![index];
        final isLocked = widget.controller.isModuleLocked(module.id!);
        return _buildModuleItem(context, module, index + 1, isLocked);
      },
    );
  }

  Widget _buildModuleItem(
    BuildContext context,
    Module module,
    int moduleNumber,
    bool isLocked,
  ) {
    final progress = module.totalLessons != null && module.totalLessons! > 0
        ? (module.completedLessons ?? 0) / module.totalLessons!
        : 0.0;
    final isCompleted = module.isCompleted == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked
              ? Colors.grey[300]!
              : isCompleted
                  ? const Color(0xFF2D8659)
                  : const Color(0xFFE5E5E5),
          width: isLocked ? 1 : isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.grey[100]
                  : isCompleted
                      ? const Color(0xFF2D8659).withOpacity(0.1)
                      : const Color(0xFFF7F9F8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey[300]
                        : isCompleted
                            ? const Color(0xFF2D8659)
                            : const Color(0xFF2D8659).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isLocked
                        ? Icons.lock
                        : isCompleted
                            ? Icons.check_circle
                            : Icons.folder_outlined,
                    color: isLocked
                        ? Colors.grey[600]
                        : isCompleted
                            ? Colors.white
                            : const Color(0xFF2D8659),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Module $moduleNumber: ${module.title ?? 'Untitled'}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isLocked ? Colors.grey[600] : const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (module.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          module.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isLocked ? Colors.grey[500] : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "Locked",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  )
                else if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D8659),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "Completed",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Progress Bar
          if (!isLocked) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${(progress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D8659),
                        ),
                      ),
                      Text(
                        "${module.completedLessons ?? 0}/${module.totalLessons ?? 0} lessons",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2D8659),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Lessons List
          if (!isLocked && module.lessons != null && module.lessons!.isNotEmpty) ...[
            const Divider(height: 1),
            ...module.lessons!.asMap().entries.map((entry) {
              final lesson = entry.value;
              final lessonIndex = entry.key;
              final isLessonCompleted = widget.controller.isLessonCompleted(lesson.id!);
              final isLessonLocked = widget.controller.isLessonLocked(lesson.id!, module.id!);
              return _buildLessonItemInModule(
                context,
                lesson,
                lessonIndex + 1,
                isLessonCompleted,
                isLessonLocked,
                module,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonItemInModule(
    BuildContext context,
    Lesson lesson,
    int lessonNumber,
    bool isCompleted,
    bool isLocked,
    Module module,
  ) {
    IconData icon;
    Color iconColor;

    switch (lesson.type) {
      case 'video':
        icon = Icons.play_circle_outline;
        iconColor = Colors.blue;
        break;
      case 'quiz':
        icon = Icons.quiz_outlined;
        iconColor = Colors.orange;
        break;
      case 'diy':
        icon = Icons.build_outlined;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.article_outlined;
        iconColor = Colors.purple;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked
            ? null
            : () {
                routeTo(LessonDetailPage.path, data: {
                  "lesson": lesson,
                  "course": course,
                  "module": module,
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  Icon(
                    icon,
                    color: isLocked ? Colors.grey[400] : iconColor,
                    size: 28,
                  ),
                  if (isCompleted)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${lessonNumber}. ${lesson.title ?? 'Untitled'}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isLocked ? Colors.grey[400] : const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (lesson.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        lesson.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocked ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isLocked)
                const Icon(Icons.lock, color: Colors.grey, size: 18)
              else
                const Icon(Icons.chevron_right, color: Color(0xFF999999)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurriculumList(BuildContext context, Course course) {
    if (course.lessons == null || course.lessons!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text("No lessons available")
              .bodyMedium(color: context.color.content.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: course.lessons!.length,
      itemBuilder: (context, index) {
        final lesson = course.lessons![index];
        final isCompleted = widget.controller.isLessonCompleted(lesson.id!);
        return _buildLessonItem(context, lesson, index + 1, isCompleted);
      },
    );
  }

  Widget _buildLessonItem(
    BuildContext context,
    Lesson lesson,
    int lessonNumber,
    bool isCompleted,
  ) {
    IconData icon;
    Color iconColor;

    switch (lesson.type) {
      case 'video':
        icon = Icons.play_circle_outline;
        iconColor = Colors.blue;
        break;
      case 'quiz':
        icon = Icons.quiz_outlined;
        iconColor = Colors.orange;
        break;
      case 'diy':
        icon = Icons.build_outlined;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.article_outlined;
        iconColor = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            Icon(icon, color: iconColor, size: 32),
            if (isCompleted)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Text("Lesson $lessonNumber: ${lesson.title ?? 'Untitled'}"),
        subtitle: Text(lesson.description ?? ""),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          routeTo(LessonDetailPage.path, data: {
            "lesson": lesson,
            "course": course,
          });
        },
      ),
    );
  }
}
