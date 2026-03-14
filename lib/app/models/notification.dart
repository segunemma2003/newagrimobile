import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:nylo_framework/nylo_framework.dart';

class Notification extends Model {
  String? id;
  String? userId;
  String? type; // message_sent, course_added, enrollment_confirmed, course_completed, module_added, assignment_graded
  String? title;
  String? message;
  String? actionType; // course, message, assignment, etc.
  String? actionId; // ID of the related resource
  Map<String, dynamic>? data; // Additional JSON data
  bool? isRead;
  String? readAt;
  String? createdAt;
  String? updatedAt;

  static StorageKey key = 'notifications';

  Notification() : super(key: key);

  Notification.fromJson(dynamic data) {
    id = data['id']?.toString();
    userId = data['user_id']?.toString() ?? data['userId']?.toString();
    type = data['type'];
    title = data['title'];
    message = data['message'];
    actionType = data['action_type'] ?? data['actionType'];
    actionId = data['action_id']?.toString() ?? data['actionId']?.toString();
    isRead = data['is_read'] ?? data['isRead'] ?? false;
    readAt = data['read_at'] ?? data['readAt'];
    createdAt = data['created_at'] ?? data['createdAt'];
    updatedAt = data['updated_at'] ?? data['updatedAt'];
    
    if (data['data'] != null) {
      if (data['data'] is Map) {
        this.data = Map<String, dynamic>.from(data['data']);
      } else if (data['data'] is String) {
        try {
          this.data = json.decode(data['data']) as Map<String, dynamic>?;
        } catch (e) {
          this.data = {};
        }
      }
    }
  }

  @override
  toJson() => {
        "id": id,
        "user_id": userId,
        "type": type,
        "title": title,
        "message": message,
        "action_type": actionType,
        "action_id": actionId,
        "data": data,
        "is_read": isRead,
        "read_at": readAt,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };

  /// Get formatted time (e.g., "2h ago", "1d ago")
  String getFormattedTime() {
    if (createdAt == null) return '';
    
    try {
      final created = DateTime.parse(createdAt!);
      final now = DateTime.now();
      final difference = now.difference(created);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  /// Get date group (Today, Yesterday, or date)
  String getDateGroup() {
    if (createdAt == null) return '';
    
    try {
      final created = DateTime.parse(createdAt!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final createdDate = DateTime(created.year, created.month, created.day);
      
      if (createdDate == today) {
        return 'Today';
      } else if (createdDate == yesterday) {
        return 'Yesterday';
      } else {
        return '${created.day}/${created.month}/${created.year}';
      }
    } catch (e) {
      return '';
    }
  }

  /// Get icon based on notification type
  IconData? getIcon() {
    switch (type) {
      case 'message_sent':
        return Icons.message;
      case 'course_added':
      case 'course_published':
        return Icons.menu_book;
      case 'enrollment_confirmed':
        return Icons.check_circle;
      case 'course_completed':
        return Icons.verified;
      case 'module_added':
        return Icons.library_add;
      case 'assignment_graded':
        return Icons.assignment;
      default:
        return Icons.notifications;
    }
  }

  /// Get icon color based on notification type
  Color getIconColor() {
    switch (type) {
      case 'message_sent':
        return const Color(0xFF2196F3);
      case 'course_added':
      case 'course_published':
        return const Color(0xFF0fbd38);
      case 'enrollment_confirmed':
        return const Color(0xFF4CAF50);
      case 'course_completed':
        return const Color(0xFF2196F3);
      case 'module_added':
        return const Color(0xFFFF9800);
      case 'assignment_graded':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF0fbd38);
    }
  }
}
