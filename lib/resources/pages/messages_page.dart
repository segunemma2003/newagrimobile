import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/message.dart';
import '/config/keys.dart';
import '/resources/pages/chat_detail_page.dart';

class MessagesPage extends NyStatefulWidget {
  static RouteView path = ("/messages", (_) => MessagesPage());

  MessagesPage({super.key}) : super(child: () => _MessagesPageState());
}

class _MessagesPageState extends NyPage<MessagesPage> {
  String _selectedFilter = "All";
  String _searchQuery = "";
  List<Message> _conversations = [];
  TextEditingController? _searchController;

  // Color scheme - maintain from other pages
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF0A1612);
  static const Color surfaceDark = Color(0xFF13251E);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  @override
  get init => () async {
        _searchController = TextEditingController();
        await _loadConversations();
      };

  Future<void> _loadConversations() async {
    try {
      final conversationsJson = await Keys.messages.read<List>();
      if (conversationsJson != null) {
        _conversations = conversationsJson
            .map((m) => Message.fromJson(m))
            .toList();
        
        // Sort: pinned first, then by last message time
        _conversations.sort((a, b) {
          if (a.isPinned == true && b.isPinned != true) return -1;
          if (a.isPinned != true && b.isPinned == true) return 1;
          final aTime = a.lastMessageTime ?? a.timestamp ?? DateTime(2000);
          final bTime = b.lastMessageTime ?? b.timestamp ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
        
        setState(() {});
      } else {
        // Load dummy data
        _loadDummyConversations();
      }
    } catch (e) {
      print('Error loading conversations: $e');
      _loadDummyConversations();
    }
  }

  void _loadDummyConversations() {
    _conversations = [
      Message()
        ..id = "1"
        ..senderName = "Dr. Amina"
        ..senderAvatar = "https://lh3.googleusercontent.com/aida-public/AB6AXuD6r7hxZTYPqrYdwI4uslBYqlxVWuvl0i_qFYRmt4oqb_nPeGshvQQS_5pSgmbqQkVTejT1OCBOdTXjNZyVkX3VwMjEpQOMAToskkDB1BeUMRmnZl-dd5Lwk1Q9oEqrJIZKaOQ6GQW9C9x7Rd-_L-fgUrJCXOYCa19SpoDFNePH1PLVFtCMCV_jAquM5ptlSNtAttJ47byuxbJ60kf1R2BVTrI9EW96pzXcyHyU2jpR-zW5rRlyJ7cx0WhsBayZLjl6ULSJp8LR7DI"
        ..senderType = "instructor"
        ..lastMessagePreview = "Please review the module 3 quiz results when you have a moment."
        ..lastMessageTime = DateTime.now().subtract(const Duration(hours: 2))
        ..unreadCount = 2
        ..isPinned = true
        ..isRead = false,
      Message()
        ..id = "2"
        ..senderName = "Soil Science Group"
        ..senderAvatar = null
        ..senderType = "group"
        ..lastMessagePreview = "Sarah: Does anyone have the notes for the last lecture?"
        ..lastMessageTime = DateTime.now().subtract(const Duration(hours: 3, minutes: 45))
        ..unreadCount = 1
        ..isPinned = true
        ..isRead = false,
      Message()
        ..id = "3"
        ..senderName = "Marcus (Peer)"
        ..senderAvatar = "https://lh3.googleusercontent.com/aida-public/AB6AXuBIXkV5Uwbg10rXxbmJZt0wpbZ9P07C9dX5A-EDmDsJtHV8pNr_5b_5Ck35e6VNVuTjycvHiL1rq0fwAzUHtZfg503bCG3eI-JPscWd4ryVjcIS2tOxKXaVmSltws-BeXwJ7L_sowYZ7rSgs2J01oqY_zMZiFl8ZAVznlgkF3LnBgFK-czrPMiOPG8Vkew_DZ0-SUPQVQNke8IXwjnHW87fj45NpAbpuaYhvyDdKvhS0ycojZ-qUN7PsukAhQ_ab18FfGcNeht8oBQ"
        ..senderType = "student"
        ..lastMessagePreview = "Thanks for sharing that PDF!"
        ..lastMessageTime = DateTime.now().subtract(const Duration(days: 1))
        ..unreadCount = 0
        ..isPinned = false
        ..isRead = true,
      Message()
        ..id = "4"
        ..senderName = "Agrisiti Bot"
        ..senderAvatar = null
        ..senderType = "bot"
        ..lastMessagePreview = "Your \"Sustainable Farming\" certificate is ready."
        ..lastMessageTime = DateTime.now().subtract(const Duration(days: 2))
        ..unreadCount = 0
        ..isPinned = false
        ..isRead = true,
      Message()
        ..id = "5"
        ..senderName = "Prof. Sarah J."
        ..senderAvatar = "https://lh3.googleusercontent.com/aida-public/AB6AXuDRJ4XA6Q9_sWfg4wWy-T02HcGtQk0lJRAljf_qzIwOmC4D3tj4bWa9K4WmUJ8PCmgOCvvAG4-ptwg2beCvkzHgqebsvlX5xR5x4qIClf-ao8nJ-1pHaku8PWsJJA6E9KBxfTXatmFLEAb7JNE8SpCrMDvHQrWTWYfa2M3OX7OHrCk2VszXQ3Nm4lgohSYIsaWK8_GdRmAx-5HZ3fz1hxqpODPRAkicZ6OXdRhXuEIU8Q8J7oXuZmVrXVKfwmsI_zmu_Y5qyV-oykQ"
        ..senderType = "instructor"
        ..lastMessagePreview = "The workshop has been rescheduled to Friday."
        ..lastMessageTime = DateTime.now().subtract(const Duration(days: 2))
        ..unreadCount = 0
        ..isPinned = false
        ..isRead = true,
    ];
    setState(() {});
  }

  List<Message> get _filteredConversations {
    var filtered = _conversations;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((conv) {
        final senderName = conv.senderName?.toLowerCase() ?? '';
        final preview = conv.lastMessagePreview?.toLowerCase() ?? '';
        return senderName.contains(query) || preview.contains(query);
      }).toList();
    }
    
    // Filter by type
    if (_selectedFilter != "All") {
      filtered = filtered.where((conv) {
        final senderType = conv.senderType ?? '';
        switch (_selectedFilter) {
          case "Instructors":
            return senderType == "instructor";
          case "Groups":
            return senderType == "group";
          case "Students":
            return senderType == "student";
          default:
            return true;
        }
      }).toList();
    }
    
    return filtered;
  }

  List<Message> get _pinnedConversations {
    return _filteredConversations.where((c) => c.isPinned == true).toList();
  }

  List<Message> get _unpinnedConversations {
    return _filteredConversations.where((c) => c.isPinned != true).toList();
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final surfaceColor = isDark ? surfaceDark : surfaceLight;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark
        ? const Color(0xFF9DB9A3)
        : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Messages",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: Open new message dialog
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_square,
                          color: accent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: surfaceColor,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? surfaceDark : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.search,
                        color: secondaryTextColor,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Search conversations...",
                          hintStyle: TextStyle(color: secondaryTextColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: surfaceColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("All", _selectedFilter == "All", () {
                      setState(() => _selectedFilter = "All");
                    }, isDark, accent),
                    const SizedBox(width: 12),
                    _buildFilterChip("Instructors", _selectedFilter == "Instructors", () {
                      setState(() => _selectedFilter = "Instructors");
                    }, isDark, accent),
                    const SizedBox(width: 12),
                    _buildFilterChip("Groups", _selectedFilter == "Groups", () {
                      setState(() => _selectedFilter = "Groups");
                    }, isDark, accent),
                    const SizedBox(width: 12),
                    _buildFilterChip("Students", _selectedFilter == "Students", () {
                      setState(() => _selectedFilter = "Students");
                    }, isDark, accent),
                  ],
                ),
              ),
            ),
            // Messages List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Pinned Section
                  if (_pinnedConversations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSectionDivider("Pinned", isDark, secondaryTextColor),
                    const SizedBox(height: 8),
                    ..._pinnedConversations.map((conv) => _buildConversationItem(
                      conv,
                      surfaceColor,
                      textColor,
                      secondaryTextColor,
                      isDark,
                      accent,
                    )),
                  ],
                  // Earlier Section
                  if (_unpinnedConversations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSectionDivider("Earlier", isDark, secondaryTextColor),
                    const SizedBox(height: 8),
                    ..._unpinnedConversations.map((conv) => _buildConversationItem(
                      conv,
                      surfaceColor,
                      textColor,
                      secondaryTextColor,
                      isDark,
                      accent,
                    )),
                  ],
                  if (_filteredConversations.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: secondaryTextColor),
                          const SizedBox(height: 16),
                          Text(
                            "No conversations found",
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "messages_fab",
        onPressed: () {
          // TODO: Open new message dialog
        },
        backgroundColor: accent,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, bool isDark, Color accent) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? accent
                : (isDark ? surfaceDark : Colors.grey[200]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String label, bool isDark, Color secondaryTextColor) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor.withOpacity(0.6),
            letterSpacing: 1.0,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.only(left: 8),
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
          ),
        ),
      ],
    );
  }

  Widget _buildConversationItem(
    Message conversation,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
    Color accent,
  ) {
    final isUnread = conversation.isRead != true || (conversation.unreadCount ?? 0) > 0;
    final hasUnreadBadge = (conversation.unreadCount ?? 0) > 0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          routeTo(ChatDetailPage.path, data: {'conversation': conversation});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? backgroundDark : Colors.white,
                        width: 2,
                      ),
                      image: conversation.senderAvatar != null && conversation.senderAvatar!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(conversation.senderAvatar!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: conversation.senderAvatar == null || conversation.senderAvatar!.isEmpty
                          ? _getAvatarColor(conversation.senderType ?? 'student')
                          : null,
                    ),
                    child: conversation.senderAvatar == null || conversation.senderAvatar!.isEmpty
                        ? _buildAvatarIcon(conversation.senderType ?? 'student')
                        : null,
                  ),
                  // Online indicator (for instructors/students)
                  if (conversation.senderType != 'group' && conversation.senderType != 'bot' && isUnread)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? backgroundDark : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.senderName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(conversation.lastMessageTime ?? conversation.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            color: isUnread ? accent : secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessagePreview ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                              color: isUnread ? textColor : secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnreadBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "${conversation.unreadCount}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ] else if (conversation.isRead == true) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.done_all,
                            size: 18,
                            color: accent,
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.done,
                            size: 18,
                            color: secondaryTextColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String senderType) {
    switch (senderType) {
      case 'group':
        return Colors.indigo[600]!;
      case 'bot':
        return Colors.teal[800]!;
      case 'instructor':
        return accent.withOpacity(0.2);
      default:
        return Colors.grey[400]!;
    }
  }

  Widget _buildAvatarIcon(String senderType) {
    IconData icon;
    Color iconColor;
    
    switch (senderType) {
      case 'group':
        icon = Icons.groups;
        iconColor = Colors.white;
        break;
      case 'bot':
        icon = Icons.smart_toy;
        iconColor = Colors.white;
        break;
      default:
        icon = Icons.person;
        iconColor = accent;
    }
    
    return Icon(icon, color: iconColor, size: 28);
  }
}
