import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/networking/api_service.dart';
import '/app/helpers/storage_helper.dart';
import '/app/helpers/image_helper.dart';
import '/resources/pages/chat_detail_page.dart';

class InstructorsPage extends NyStatefulWidget {
  static RouteView path = ("/instructors", (_) => InstructorsPage());

  InstructorsPage({super.key}) : super(child: () => _InstructorsPageState());
}

class _InstructorsPageState extends NyPage<InstructorsPage> {
  List<Map<String, dynamic>> _instructors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = "Facilitators"; // "Facilitators" or "All"

  // Color scheme
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF0A1612);
  static const Color surfaceDark = Color(0xFF13251E);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  @override
  get init => () async {
        await _loadInstructors();
      };

  Future<void> _loadInstructors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      Map<String, dynamic>? response;

      if (_selectedFilter == "Facilitators") {
        response = await api.fetchFacilitators() as Map<String, dynamic>?;
      } else {
        response = await api.fetchInstructors() as Map<String, dynamic>?;
      }

      if (response != null && response['data'] != null) {
        final data = response['data'] as List<dynamic>? ?? [];
        _instructors = data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error loading instructors: $e');
      _errorMessage = 'Failed to load instructors. Please try again.';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startConversation(Map<String, dynamic> instructor) async {
    try {
      final userData = safeReadAuthData();
      final currentUserId = userData?['id']?.toString();
      final instructorId = instructor['id']?.toString();

      if (currentUserId == null || instructorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start conversation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get user's enrolled courses to find a course for messaging
      // For location-based messaging, we'll use a generic course_id (0 or first enrolled course)
      final api = ApiService();
      final enrollmentsResponse = await api.fetchMyEnrollments();
      
      dynamic enrollments;
      if (enrollmentsResponse is List) {
        enrollments = enrollmentsResponse;
      } else if (enrollmentsResponse is Map) {
        enrollments = enrollmentsResponse['data'] ?? [];
      } else {
        enrollments = [];
      }

      String? courseId;
      if (enrollments is List && enrollments.isNotEmpty) {
        // Use first enrolled course
        final firstEnrollment = enrollments[0];
        courseId = firstEnrollment['course_id']?.toString() ?? 
                   firstEnrollment['course']?['id']?.toString();
      }

      // If no enrolled course, use course_id 0 for location-based messaging
      courseId ??= "0";

      // Navigate to chat detail page
      routeTo(ChatDetailPage.path, data: {
        "courseId": courseId,
        "recipientId": instructorId,
        "recipientName": instructor['name'] ?? 'Instructor',
        "recipientAvatar": instructor['avatar'],
      });
    } catch (e) {
      print('Error starting conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
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
    final surfaceColor = isDark ? surfaceDark : surfaceLight;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor =
        isDark ? const Color(0xFF9DB9A3) : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Instructors",
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    "Facilitators",
                    isDark,
                    textColor,
                    secondaryTextColor,
                    accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    "All",
                    isDark,
                    textColor,
                    secondaryTextColor,
                    accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: accent,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: secondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInstructors,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : _instructors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 64,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == "Facilitators"
                                ? "No facilitators found in your location"
                                : "No instructors found",
                            style: TextStyle(color: secondaryTextColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _instructors.length,
                      itemBuilder: (context, index) {
                        final instructor = _instructors[index];
                        return _buildInstructorCard(
                          instructor,
                          isDark,
                          textColor,
                          secondaryTextColor,
                          surfaceColor,
                          accent,
                        );
                      },
                    ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
    Color accent,
  ) {
    final isSelected = _selectedFilter == label;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_selectedFilter != label) {
            setState(() {
              _selectedFilter = label;
            });
            _loadInstructors();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.2)
                : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accent
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? accent : textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorCard(
    Map<String, dynamic> instructor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color accent,
  ) {
    final name = instructor['name'] ?? 'Unknown';
    final bio = instructor['bio'] ?? '';
    final location = instructor['location'] ?? '';
    final avatar = instructor['avatar'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startConversation(instructor),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: avatar != null && avatar.toString().isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(getImageUrl(avatar)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: avatar == null || avatar.toString().isEmpty
                        ? accent.withValues(alpha: 0.2)
                        : null,
                  ),
                  child: avatar == null || avatar.toString().isEmpty
                      ? Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          bio.length > 60 ? '${bio.substring(0, 60)}...' : bio,
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
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
