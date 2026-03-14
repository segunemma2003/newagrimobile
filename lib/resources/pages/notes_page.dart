import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/note.dart';
import '/app/models/course.dart';
import '/app/models/lesson.dart';
import '/app/models/module.dart';
import '/app/networking/api_service.dart';
import '/config/keys.dart';
import '/resources/pages/lesson_detail_page.dart';

class NotesPage extends NyStatefulWidget {
  static RouteView path = ("/notes", (_) => NotesPage());

  NotesPage({super.key}) : super(child: () => _NotesPageState());
}

class _NotesPageState extends NyPage<NotesPage> {
  List<Note> _allNotes = [];
  Course? course;
  Lesson? lesson;
  Module? module;

  // Color scheme
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);

  @override
  get init => () async {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          course = data['course'] as Course?;
          lesson = data['lesson'] as Lesson?;
          module = data['module'] as Module?;
        }
        await _loadAllNotes();
        await _loadNotesFromApi();
        setState(() {});
      };

  Future<void> _loadAllNotes() async {
    try {
      final notesJson = await Keys.notes.read<List>();
      if (notesJson != null) {
        _allNotes = notesJson.map((n) => Note.fromJson(n)).toList();
        // Filter by course if provided
        if (course != null) {
          _allNotes = _allNotes.where((n) => n.courseId == course!.id).toList();
        }
        // Filter by lesson if provided
        if (lesson != null) {
          _allNotes = _allNotes.where((n) => n.lessonId == lesson!.id).toList();
        }
        // Sort by updated date (newest first)
        _allNotes.sort((a, b) {
          final aDate = a.updatedAt ?? a.createdAt ?? DateTime(1970);
          final bDate = b.updatedAt ?? b.createdAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
      }
    } catch (e) {
      print("Error loading notes: $e");
      // If stored notes are in an old/corrupted format, reset them
      try {
        await Keys.notes.save([]);
      } catch (_) {}
      _allNotes = [];
    }
  }

  Future<void> _loadNotesFromApi() async {
    try {
      if (course == null) return;

      final api = ApiService();
      Map<String, dynamic> response;

      // Prefer the most specific scope available
      if (lesson != null && lesson!.id != null) {
        // Lesson/topic-level notes - need module ID
        if (module != null && module!.id != null) {
          response = await api.fetchLessonNotes(
            course!.id!,
            module!.id!.toString(),
            lesson!.id!.toString(),
          );
        } else {
          // If module is not provided, try to find it from course
          if (course!.modules != null) {
            Module? foundModule;
            for (var mod in course!.modules!) {
              if (mod.lessons != null) {
                final hasLesson = mod.lessons!.any((l) => l.id == lesson!.id);
                if (hasLesson) {
                  foundModule = mod;
                  break;
                }
              }
            }
            if (foundModule != null && foundModule.id != null) {
              response = await api.fetchLessonNotes(
                course!.id!,
                foundModule.id!.toString(),
                lesson!.id!.toString(),
              );
            } else {
              // Fallback to course notes if module not found
              response = await api.fetchCourseNotes(course!.id!);
            }
          } else {
            // Fallback to course notes
            response = await api.fetchCourseNotes(course!.id!);
          }
        }
      } else if (module != null && module!.id != null) {
        // Module-level notes
        response = await api.fetchModuleNotes(
          course!.id!,
          module!.id!.toString(),
        );
      } else {
        // Course-level notes
        response = await api.fetchCourseNotes(course!.id!);
      }

      final data = response['data'] as List<dynamic>? ?? [];
      final apiNotes = data.map<Note>((n) {
        final note = Note();
        note.id = n['id']?.toString();
        note.userId = n['user_id']?.toString();
        note.courseId = n['course_id']?.toString();
        note.lessonId = n['topic_id']?.toString();
        note.title = n['topic']?['title']?.toString() ?? "Lesson Note";
        note.content = n['notes']?.toString();

        final createdAtStr = n['created_at']?.toString();
        final updatedAtStr = n['updated_at']?.toString();
        if (createdAtStr != null) {
          note.createdAt = DateTime.tryParse(createdAtStr);
        }
        if (updatedAtStr != null) {
          note.updatedAt = DateTime.tryParse(updatedAtStr);
        }
        return note;
      }).toList();

      // Merge API notes into local list (avoid duplicates by id)
      final existingIds =
          _allNotes.map((n) => n.id).whereType<String>().toSet();
      var merged = List<Note>.from(_allNotes);
      for (final note in apiNotes) {
        if (note.id != null && existingIds.contains(note.id)) {
          // Replace existing note with API version
          final idx = merged.indexWhere((n) => n.id == note.id);
          if (idx != -1) merged[idx] = note;
        } else {
          merged.add(note);
        }
      }

      // Filter by lesson if provided (after merging API notes)
      if (lesson != null && lesson!.id != null) {
        merged = merged.where((n) => n.lessonId == lesson!.id).toList();
      }
      // Filter by course if provided
      if (course != null && course!.id != null) {
        merged = merged.where((n) => n.courseId == course!.id).toList();
      }

      // Sort merged notes by updated/created date
      merged.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(1970);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _allNotes = merged;
      });
    } catch (e) {
      print("Error loading notes from API: $e");
    }
  }

  Future<void> _deleteNote(Note note) async {
    try {
      final allNotesJson = await Keys.notes.read<List>() ?? [];
      final allNotes = allNotesJson.map((n) => Note.fromJson(n)).toList();
      allNotes.removeWhere((n) => n.id == note.id);
      await Keys.notes.save(allNotes.map((n) => n.toJson()).toList());
      await _loadAllNotes();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Note deleted"),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      print("Error deleting note: $e");
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
          lesson != null
              ? "Lesson Notes"
              : course != null
                  ? "Course Notes"
                  : "All My Notes",
          style: TextStyle(color: textColor),
        ),
        actions: [
          if (_allNotes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: textColor,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete All Notes"),
                    content: const Text(
                        "Are you sure you want to delete all notes?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Keys.notes.save([]);
                          await _loadAllNotes();
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                        child:
                            Text("Delete", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _allNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 64,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No notes yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start taking notes in your lessons",
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allNotes.length,
              itemBuilder: (context, index) {
                final note = _allNotes[index];
                return _buildNoteCard(
                  note,
                  textColor,
                  secondaryTextColor,
                  isDark,
                  bgColor,
                );
              },
            ),
    );
  }

  Widget _buildNoteCard(
    Note note,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color bgColor,
  ) {
    final date = note.updatedAt ?? note.createdAt;
    final dateStr = date != null
        ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
        : "Unknown date";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : (Colors.grey[200] ?? Colors.grey),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title ?? "Untitled Note",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert,
                      size: 20, color: secondaryTextColor),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text("Edit"),
                      onTap: () {
                        routeTo(LessonDetailPage.path, data: {
                          "lesson": lesson,
                          "course": course,
                          "note": note,
                        });
                      },
                    ),
                    PopupMenuItem(
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.red)),
                      onTap: () => _deleteNote(note),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.content ?? "",
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                if (note.courseId != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.book, size: 14, color: secondaryTextColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Course Note",
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
