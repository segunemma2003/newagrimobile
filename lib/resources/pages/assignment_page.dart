import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:file_picker/file_picker.dart';
import '/app/models/assignment.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/models/lesson.dart';
import '/config/keys.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentPage extends NyStatefulWidget {
  static RouteView path = ("/assignment", (_) => AssignmentPage());

  AssignmentPage({super.key}) : super(child: () => _AssignmentPageState());
}

class _AssignmentPageState extends NyPage<AssignmentPage> {
  Assignment? assignment;
  Course? course;
  Module? module;
  Lesson? lesson;
  String _selectedTab = "Instructions";
  Map<String, bool> _requirementsCompleted = {};
  String? _submissionFilePath;
  String? _submissionFileName;
  bool _isSubmitting = false;

  // Color scheme
  static const Color primary = Color(0xFF0fbd38);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF102214);
  static const Color surfaceDark = Color(0xFF1C271E);

  @override
  get init => () {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          assignment = data['assignment'] as Assignment?;
          course = data['course'] as Course?;
          module = data['module'] as Module?;
          lesson = data['lesson'] as Lesson?;
          
          // Load assignment from storage if exists
          if (assignment != null) {
            _loadAssignment();
          }
        }
      };

  Future<void> _loadAssignment() async {
    try {
      final assignmentsJson = await Keys.assignments.read<List>();
      if (assignmentsJson != null) {
        final assignments = assignmentsJson.map((a) => Assignment.fromJson(a)).toList();
        final savedAssignment = assignments.firstWhere(
          (a) => a.id == assignment?.id,
          orElse: () => assignment!,
        );
        assignment = savedAssignment;
        _submissionFilePath = assignment?.submissionFilePath;
        _submissionFileName = assignment?.submissionFile;
        
        // Load requirements completion status
        if (assignment?.requirements != null) {
          for (var req in assignment!.requirements!) {
            _requirementsCompleted[req] = false;
          }
        }
        
        setState(() {});
      }
    } catch (e) {
      print("Error loading assignment: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.path != null) {
          setState(() {
            _submissionFilePath = file.path;
            _submissionFileName = file.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveDraft() async {
    if (assignment == null) return;
    
    try {
      assignment!.status = 'draft';
      assignment!.submissionFilePath = _submissionFilePath;
      assignment!.submissionFile = _submissionFileName;
      
      final assignmentsJson = await Keys.assignments.read<List>() ?? [];
      final assignments = assignmentsJson.map((a) => Assignment.fromJson(a)).toList();
      
      // Remove old assignment if exists
      assignments.removeWhere((a) => a.id == assignment!.id);
      assignments.add(assignment!);
      
      await Keys.assignments.save(assignments.map((a) => a.toJson()).toList());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Draft saved successfully"),
          backgroundColor: primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving draft: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitAssignment() async {
    if (assignment == null) return;
    
    if (_submissionFilePath == null || _submissionFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a file before submitting"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      assignment!.status = 'submitted';
      assignment!.submissionFilePath = _submissionFilePath;
      assignment!.submissionFile = _submissionFileName;
      assignment!.submittedAt = DateTime.now();
      
      final assignmentsJson = await Keys.assignments.read<List>() ?? [];
      final assignments = assignmentsJson.map((a) => Assignment.fromJson(a)).toList();
      
      // Remove old assignment if exists
      assignments.removeWhere((a) => a.id == assignment!.id);
      assignments.add(assignment!);
      
      await Keys.assignments.save(assignments.map((a) => a.toJson()).toList());
      
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Assignment submitted successfully!"),
          backgroundColor: primary,
        ),
      );
      
      // Navigate back after a delay
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pop();
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting assignment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        : (Colors.grey[600] ?? Colors.grey);

    if (assignment == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: textColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text("Assignment", style: TextStyle(color: textColor)),
        ),
        body: Center(
          child: Text(
            "Assignment not found",
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    final isSubmitted = assignment!.status == 'submitted' || assignment!.status == 'graded';
    final statusText = isSubmitted
        ? "Submitted"
        : assignment!.status == 'draft'
            ? "Draft"
            : "Not Submitted";
    final statusColor = isSubmitted
        ? primary
        : assignment!.status == 'draft'
            ? Colors.blue
            : Colors.orange;

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
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
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
                  child: Text(
                    module?.title ?? "Assignment",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
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
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(
                    assignment!,
                    statusText,
                    statusColor,
                    surfaceColor,
                    textColor,
                    secondaryTextColor,
                    isDark,
                  ),
                  const SizedBox(height: 24),
                  // Tabs
                  _buildTabs(_selectedTab, textColor, secondaryTextColor, isDark),
                  const SizedBox(height: 24),
                  // Tab Content
                  _buildTabContent(
                    _selectedTab,
                    assignment!,
                    surfaceColor,
                    textColor,
                    secondaryTextColor,
                    isDark,
                  ),
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
          // Bottom Actions
          if (!isSubmitted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saveDraft,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Save Draft",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "Submit Project",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
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

  Widget _buildStatusCard(
    Assignment assignment,
    String statusText,
    Color statusColor,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Hero Image
          Container(
            height: 128,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: course?.thumbnail != null
                  ? DecorationImage(
                      image: NetworkImage(course!.thumbnail!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: course?.thumbnail == null ? Colors.grey[300] : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    surfaceColor,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusText == "Submitted"
                                ? Icons.check_circle
                                : statusText == "Draft"
                                    ? Icons.edit
                                    : Icons.pending,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (assignment.rubricUrl != null)
                      TextButton(
                        onPressed: () async {
                          final url = Uri.parse(assignment.rubricUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: Text(
                          "View Rubric",
                          style: TextStyle(
                            fontSize: 12,
                            color: primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  assignment.title ?? "Assignment",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: secondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      assignment.dueDate != null
                          ? "Due: ${_formatDate(assignment.dueDate!)}"
                          : "No due date",
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    if (assignment.estimatedHours != null) ...[
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.timer, size: 18, color: secondaryTextColor),
                      const SizedBox(width: 8),
                      Text(
                        "Est. ${assignment.estimatedHours}h",
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(String selectedTab, Color textColor, Color secondaryTextColor, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildTabButton(
            "Instructions",
            selectedTab == "Instructions",
            () => setState(() => _selectedTab = "Instructions"),
            textColor,
            secondaryTextColor,
            isDark,
          ),
        ),
        Expanded(
          child: _buildTabButton(
            "Resources",
            _selectedTab == "Resources",
            () => setState(() => _selectedTab = "Resources"),
            textColor,
            secondaryTextColor,
            isDark,
          ),
        ),
        Expanded(
          child: _buildTabButton(
            "Submission",
            _selectedTab == "Submission",
            () => setState(() => _selectedTab = "Submission"),
            textColor,
            secondaryTextColor,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primary : secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    String tab,
    Assignment assignment,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    switch (tab) {
      case "Resources":
        return _buildResourcesTab(assignment, surfaceColor, textColor, secondaryTextColor, isDark);
      case "Submission":
        return _buildSubmissionTab(assignment, surfaceColor, textColor, secondaryTextColor, isDark);
      case "Instructions":
      default:
        return _buildInstructionsTab(assignment, surfaceColor, textColor, secondaryTextColor, isDark);
    }
  }

  Widget _buildInstructionsTab(
    Assignment assignment,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project Brief
        Row(
          children: [
            Icon(Icons.description, size: 20, color: primary),
            const SizedBox(width: 8),
            Text(
              "Project Brief",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
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
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
            ),
          ),
          child: Text(
            assignment.brief ?? assignment.description ?? "No description available.",
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Requirements
        Row(
          children: [
            Icon(Icons.checklist, size: 20, color: primary),
            const SizedBox(width: 8),
            Text(
              "Requirements",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assignment.requirements != null && assignment.requirements!.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
              ),
            ),
            child: Column(
            children: assignment.requirements!.map((requirement) {
                final isCompleted = _requirementsCompleted[requirement] ?? false;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _requirementsCompleted[requirement] = !isCompleted;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
                        ),
                      ),
                      color: isCompleted ? primary.withOpacity(0.05) : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted ? primary : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                              width: 2,
                            ),
                            color: isCompleted ? primary : Colors.transparent,
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            requirement,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isCompleted ? textColor : secondaryTextColor,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
              ),
            ),
            child: Text(
              "No requirements specified.",
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
      ],
    );
  }

  Widget _buildResourcesTab(
    Assignment assignment,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_open, size: 20, color: primary),
            const SizedBox(width: 8),
            Text(
              "Quick Resources",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assignment.resources != null && assignment.resources!.isNotEmpty)
          Column(
            children: assignment.resources!.map((resource) {
              final name = resource['name'] ?? 'Resource';
              final url = resource['url'];
              final type = resource['type'] ?? 'file';
              final size = resource['size'] ?? '';
              
              IconData icon;
              Color iconColor;
              if (type == 'pdf' || name.toLowerCase().contains('.pdf')) {
                icon = Icons.picture_as_pdf;
                iconColor = Colors.red;
              } else {
                icon = Icons.description;
                iconColor = Colors.blue;
              }
              
              return InkWell(
                onTap: url != null
                    ? () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (size.isNotEmpty)
                              Text(
                                size,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.download, color: secondaryTextColor, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
              ),
            ),
            child: Text(
              "No resources available.",
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionTab(
    Assignment assignment,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final isSubmitted = assignment.status == 'submitted' || assignment.status == 'graded';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.upload_file, size: 20, color: primary),
            const SizedBox(width: 8),
            Text(
              "Your Submission",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isSubmitted && _submissionFileName != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Submitted",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      Text(
                        _submissionFileName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      if (assignment.submittedAt != null)
                        Text(
                          "Submitted on ${_formatDate(assignment.submittedAt!)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _submissionFileName ?? "Tap to upload your project",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Supports PDF, DOCX, JPG (Max 25MB)",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_submissionFileName != null && !isSubmitted) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _submissionFileName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: secondaryTextColor,
                  onPressed: () {
                    setState(() {
                      _submissionFileName = null;
                      _submissionFilePath = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
