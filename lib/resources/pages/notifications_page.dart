import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/controllers/notifications_controller.dart';
import '/app/models/notification.dart' as NotificationModel;
import '/app/helpers/image_helper.dart';
import '/app/helpers/text_helper.dart';

class NotificationsPage extends NyStatefulWidget<NotificationsController> {
  static RouteView path = ("/notifications", (_) => NotificationsPage());

  NotificationsPage({super.key}) : super(child: () => _NotificationsPageState());
}

class _NotificationsPageState extends NyPage<NotificationsPage> {
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Mentions", "Announcements", "System"];

  // Color scheme - maintaining current background colors
  static const Color primary = Color(0xFF0fbd38);
  static const Color backgroundLight = Color(0xFFF7F9F8);
  static const Color backgroundDark = Color(0xFF102214);
  static const Color surfaceDark = Color(0xFF162b1b);

  @override
  get init => () async {
        // Load notifications from storage first (fast)
        await widget.controller.loadNotificationsFromStorage();
        setState(() {});
        
        // Sync notifications in background (non-blocking)
        widget.controller.syncNotifications().then((_) {
          if (mounted) {
            setState(() {});
          }
        }).catchError((e) {
          print("Error syncing notifications: $e");
        });
      };

  List<NotificationModel.Notification> get _filteredNotifications {
    List<NotificationModel.Notification> filtered = widget.controller.notifications;
    
    if (_selectedFilter != "All") {
      filtered = filtered.where((n) {
        final type = n.type;
        if (type == null) return false;
        switch (_selectedFilter) {
          case "Mentions":
            return type == 'message_sent';
          case "Announcements":
            return type == 'course_added' || type == 'course_published' || type == 'module_added';
          case "System":
            return type == 'enrollment_confirmed' || type == 'course_completed' || type == 'assignment_graded';
          default:
            return true;
        }
      }).toList();
    }
    
    // Sort by created_at (newest first)
    filtered.sort((a, b) {
      final aCreated = a.createdAt;
      final bCreated = b.createdAt;
      if (aCreated == null || bCreated == null) return 0;
      try {
        return DateTime.parse(bCreated).compareTo(DateTime.parse(aCreated));
      } catch (e) {
        return 0;
      }
    });
    
    return filtered;
  }

  void _markAllAsRead() async {
    await widget.controller.markAllAsRead();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All notifications marked as read"),
        backgroundColor: primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _markAsRead(NotificationModel.Notification notification) async {
    if (notification.id != null) {
      await widget.controller.markAsRead(notification.id!);
      setState(() {});
    }
  }

  void _deleteNotification(NotificationModel.Notification notification) async {
    if (notification.id != null) {
      await widget.controller.deleteNotification(notification.id!);
      setState(() {});
    }
  }

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF0f172a);
    final secondaryTextColor = isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : (Colors.grey[600] ?? Colors.grey);
    final surfaceColor = isDark ? surfaceDark : Colors.white;

    final filteredNotifications = _filteredNotifications;

    // Group notifications by date
    final todayNotifications = filteredNotifications
        .where((n) => n.getDateGroup() == 'Today')
        .toList();
    final yesterdayNotifications = filteredNotifications
        .where((n) => n.getDateGroup() == 'Yesterday')
        .toList();
    final olderNotifications = filteredNotifications
        .where((n) => n.getDateGroup() != 'Today' && n.getDateGroup() != 'Yesterday')
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Sticky Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
                ),
              ),
            ),
            child: Column(
              children: [
                // Top Row: Back, Title, Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        color: textColor,
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Text(
                          "Notifications",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, size: 20),
                        color: textColor,
                        onPressed: () {
                          // Navigate to notification settings
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary
                                  : (isDark ? surfaceDark : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.grey[200]!,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.black
                                    : (isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: filteredNotifications.isEmpty
                ? _buildEmptyState(textColor, secondaryTextColor, isDark)
                : RefreshIndicator(
                    onRefresh: () async {
                      await widget.controller.syncNotifications();
                      setState(() {});
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mark All as Read Button
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (filteredNotifications.any((n) => n.isRead != true))
                                  TextButton.icon(
                                    onPressed: _markAllAsRead,
                                    icon: const Icon(Icons.done_all, size: 18),
                                    label: const Text("Mark all as read"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: primary,
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Today Section
                          if (todayNotifications.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                "TODAY",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryTextColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            ...todayNotifications.map((notification) =>
                                _buildNotificationItem(
                                  notification,
                                  bgColor,
                                  surfaceColor,
                                  textColor,
                                  secondaryTextColor,
                                  isDark,
                                )),
                          ],
                          // Yesterday Section
                          if (yesterdayNotifications.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 16,
                                bottom: 8,
                              ),
                              child: Text(
                                "YESTERDAY",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryTextColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            ...yesterdayNotifications.map((notification) =>
                                _buildNotificationItem(
                                  notification,
                                  bgColor,
                                  surfaceColor,
                                  textColor,
                                  secondaryTextColor,
                                  isDark,
                                )),
                          ],
                          // Older Section
                          if (olderNotifications.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 16,
                                bottom: 8,
                              ),
                              child: Text(
                                "OLDER",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryTextColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            ...olderNotifications.map((notification) =>
                                _buildNotificationItem(
                                  notification,
                                  bgColor,
                                  surfaceColor,
                                  textColor,
                                  secondaryTextColor,
                                  isDark,
                                )),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: isDark ? surfaceDark : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off,
              size: 64,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for more updates on your courses and community.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel.Notification notification,
    Color bgColor,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final isRead = notification.isRead ?? false;
    final icon = notification.getIcon();
    final iconColor = notification.getIconColor();
    
    // Check if notification has avatar data (for message_sent type)
    String? avatarUrl;
    if (notification.type == 'message_sent' && notification.data != null) {
      avatarUrl = notification.data!['sender_avatar'] ?? notification.data!['senderAvatar'];
    }

    return Dismissible(
      key: Key(notification.id ?? DateTime.now().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: InkWell(
        onTap: () {
          _markAsRead(notification);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon/Avatar
              if (avatarUrl != null && avatarUrl.isNotEmpty)
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(getImageUrl(avatarUrl)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.message,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (icon != null)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            stripHtmlTags(notification.title ?? ''),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: textColor,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notification.getFormattedTime(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isRead ? secondaryTextColor : primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stripHtmlTags(notification.message ?? ''),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread Dot
              if (!isRead) ...[
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
