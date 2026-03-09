import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class NotificationsPage extends NyStatefulWidget {
  static RouteView path = ("/notifications", (_) => NotificationsPage());

  NotificationsPage({super.key}) : super(child: () => _NotificationsPageState());
}

class _NotificationsPageState extends NyPage<NotificationsPage> {
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Mentions", "Announcements", "System"];

  // Sample notification data - in real app, this would come from API/storage
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": "1",
      "title": "New Module Unlocked",
      "message": "Sustainable Farming 101: Module 4 'Water Conservation' is now available for you.",
      "time": "2h ago",
      "isRead": false,
      "type": "course",
      "dateGroup": "Today",
      "icon": Icons.menu_book,
      "iconColor": Color(0xFF0fbd38),
    },
    {
      "id": "2",
      "title": "Jane Doe replied",
      "message": "@You Regarding 'Soil Health Analysis', have you checked the pH levels in the north sector?",
      "time": "4h ago",
      "isRead": false,
      "type": "mention",
      "dateGroup": "Today",
      "avatar": "https://lh3.googleusercontent.com/aida-public/AB6AXuAZv0E3v_bpXmjEagveKH4FR93IWhrjLvjT6L9usv9FPZkls46wW8OJ6BQV-IPhPg2l8hgM-iSd3QmoaKdd-4PC4bytQwiXujHMlh_QZYfdSHcMI41l0ZFRAWNZvOJ5SFDZLhAYV6Rf3wRzMtsmrhTTSf8orQtLSRxZ52kT0cEuPh8SkKRyeJ2t0mP6nxDjQASk3sB6yceC3WXIEImFj17EEa_C-HABa0ETWSsM8eALn5cWZ28NZ3QCNbun8-cJhi8I0PX3gD30utE",
      "iconColor": Color(0xFF2196F3),
    },
    {
      "id": "3",
      "title": "Quiz Deadline Approaching",
      "message": "Don't forget to complete your quiz by 11:59 PM today.",
      "time": "6h ago",
      "isRead": true,
      "type": "announcement",
      "dateGroup": "Today",
      "icon": Icons.alarm,
      "iconColor": Color(0xFFFF9800),
    },
    {
      "id": "4",
      "title": "Certificate Ready",
      "message": "Congratulations! Your certificate for 'Intro to Agri-Business' is ready for download.",
      "time": "1d ago",
      "isRead": true,
      "type": "system",
      "dateGroup": "Yesterday",
      "icon": Icons.verified,
      "iconColor": Color(0xFF2196F3),
    },
    {
      "id": "5",
      "title": "Mark Lee liked your post",
      "message": "\"Great insights on crop rotation...\"",
      "time": "1d ago",
      "isRead": true,
      "type": "mention",
      "dateGroup": "Yesterday",
      "avatar": "https://lh3.googleusercontent.com/aida-public/AB6AXuDFRfK7Mu57sEQu0DsqkOb4VE_Suq6Ud5UKuXUBt1tjeLOLLIjg5e-Jb6TbM7mpO7Ethj3ODY8sWBo6DNGL7WGBg-uyQXqi_2ZVZqIiObUiN8klKqJLooRj2uoKHE7tRjXn8ujY24ac2Mqnp9hS2PcHc0aT5uI5RGvxznvmJnE_dyplFyZ2yTyJ1oZTWODZ7X2y04b4Gm9FPeaS1-HUBBHq49pCGB6q1c9R-fgdEvZCYUk3mHFEPrwe_7h5Ql63YWVX2d5T2MLEEFQ",
      "iconColor": Color(0xFFE91E63),
    },
  ];

  // Color scheme - maintaining current background colors
  static const Color primary = Color(0xFF0fbd38);
  static const Color backgroundLight = Color(0xFFF7F9F8); // Current background
  static const Color backgroundDark = Color(0xFF102214); // Dark mode background
  static const Color surfaceDark = Color(0xFF162b1b);

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == "All") {
      return _notifications;
    }
    return _notifications.where((n) {
      switch (_selectedFilter) {
        case "Mentions":
          return n['type'] == 'mention';
        case "Announcements":
          return n['type'] == 'announcement';
        case "System":
          return n['type'] == 'system';
        default:
          return true;
      }
    }).toList();
  }

  void _markAllAsRead() {
                setState(() {
                  for (var notification in _notifications) {
                    notification['isRead'] = true;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All notifications marked as read"),
        backgroundColor: primary,
                    duration: Duration(seconds: 2),
                  ),
                );
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

    // Group notifications by date
    final todayNotifications = _filteredNotifications
        .where((n) => n['dateGroup'] == 'Today')
        .toList();
    final yesterdayNotifications = _filteredNotifications
        .where((n) => n['dateGroup'] == 'Yesterday')
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
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState(textColor, secondaryTextColor, isDark)
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
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
                                if (_notifications.any((n) => !n['isRead']))
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
    Map<String, dynamic> notification,
    Color bgColor,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final isRead = notification['isRead'] as bool;
    final hasAvatar = notification['avatar'] != null;
    final icon = notification['icon'] as IconData?;
    final iconColor = notification['iconColor'] as Color?;

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((n) => n['id'] == notification['id']);
        });
      },
      child: InkWell(
        onTap: () {
          setState(() {
            notification['isRead'] = true;
          });
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
              if (hasAvatar)
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(notification['avatar']),
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
                            color: notification['type'] == 'mention'
                                ? const Color(0xFF2196F3)
                                : const Color(0xFFE91E63),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notification['type'] == 'mention'
                                ? Icons.chat_bubble
                                : Icons.favorite,
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
                    color: iconColor!.withValues(alpha: 0.1),
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
                            notification['title'],
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
                          notification['time'],
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
                      notification['message'],
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
