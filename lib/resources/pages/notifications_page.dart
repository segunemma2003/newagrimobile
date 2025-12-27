import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class NotificationsPage extends NyStatefulWidget {
  static RouteView path = ("/notifications", (_) => NotificationsPage());

  NotificationsPage({super.key}) : super(child: () => _NotificationsPageState());
}

class _NotificationsPageState extends NyPage<NotificationsPage> {
  // Sample notification data - in real app, this would come from API/storage
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": "1",
      "title": "New Course Available",
      "message": "Introduction to Modern Farming is now available",
      "time": "2 hours ago",
      "isRead": false,
      "type": "course",
    },
    {
      "id": "2",
      "title": "Quiz Reminder",
      "message": "You have a quiz due tomorrow in Advanced Hydroponics Systems",
      "time": "1 day ago",
      "isRead": true,
      "type": "quiz",
    },
    {
      "id": "3",
      "title": "Course Completed",
      "message": "Congratulations! You completed Hydroponics Basics",
      "time": "3 days ago",
      "isRead": true,
      "type": "achievement",
    },
    {
      "id": "4",
      "title": "New Lesson Added",
      "message": "A new lesson has been added to Urban Farming Essentials",
      "time": "5 days ago",
      "isRead": true,
      "type": "course",
    },
    {
      "id": "5",
      "title": "Welcome to Agrisiti Academy",
      "message": "Start your learning journey with our comprehensive courses",
      "time": "1 week ago",
      "isRead": true,
      "type": "system",
    },
  ];

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_notifications.any((n) => !n['isRead']))
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification['isRead'] = true;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All notifications marked as read"),
                    backgroundColor: Color(0xFF2D8659),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                "Mark all read",
                style: TextStyle(
                  color: Color(0xFF2D8659),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh notifications
                await Future.delayed(const Duration(seconds: 1));
                setState(() {});
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationItem(
                    title: notification['title'] as String,
                    message: notification['message'] as String,
                    time: notification['time'] as String,
                    isRead: notification['isRead'] as bool,
                    type: notification['type'] as String,
                    onTap: () {
                      setState(() {
                        notification['isRead'] = true;
                      });
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "No notifications",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
    required bool isRead,
    required String type,
    required VoidCallback onTap,
  }) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case "course":
        iconData = Icons.book_outlined;
        iconColor = const Color(0xFF2D8659);
        break;
      case "quiz":
        iconData = Icons.quiz_outlined;
        iconColor = const Color(0xFF4CAF50);
        break;
      case "achievement":
        iconData = Icons.emoji_events_outlined;
        iconColor = const Color(0xFFFFB300);
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = const Color(0xFF2196F3);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.transparent : const Color(0xFF2D8659).withOpacity(0.3),
              width: isRead ? 0 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2D8659),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
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
}


