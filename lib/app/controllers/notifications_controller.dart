import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/notification.dart';
import '/app/networking/api_service.dart';
import '/config/keys.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NotificationsController extends NyController {
  List<Notification> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;

  Future<void> loadNotifications({
    bool? unreadOnly,
    String? type,
    int? perPage,
    int? page,
  }) async {
    // Load from local storage first
    await _loadNotificationsFromStorage();

    // Try to sync if online
    if (await _isOnline()) {
      await syncNotifications(
        unreadOnly: unreadOnly,
        type: type,
        perPage: perPage,
        page: page,
      );
    }
  }

  Future<void> loadNotificationsFromStorage() async {
    await _loadNotificationsFromStorage();
  }

  Future<void> _loadNotificationsFromStorage() async {
    try {
      final notificationsJson = await Keys.notifications.read<List>();
      if (notificationsJson != null) {
        notifications = notificationsJson
            .map((json) => Notification.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print("Error loading notifications from storage: $e");
    }
  }

  Future<void> syncNotifications({
    bool? unreadOnly,
    String? type,
    int? perPage,
    int? page,
  }) async {
    if (!await _isOnline()) {
      print("No Internet: Cannot sync notifications. Please check your connection.");
      return;
    }

    try {
      isLoading = true;
      print("Syncing notifications...");

      Map<String, dynamic>? response = await api<ApiService>(
        (request) => request.fetchNotifications(
          unreadOnly: unreadOnly,
          type: type,
          perPage: perPage ?? 50,
          page: page ?? 1,
        ),
      );

      if (response != null && response['data'] != null) {
        final List<dynamic> data =
            response['data'] is List ? response['data'] : [response['data']];
        notifications = data.map((json) => Notification.fromJson(json)).toList();

        // Save to local storage
        try {
          await Keys.notifications.save(
              notifications.map((n) => n.toJson()).toList());
        } catch (e) {
          if (!e.toString().contains('-34018')) {
            print("Warning: Failed to save notifications to storage: $e");
          }
        }

        // Load unread count
        await loadUnreadCount();

        print("Synced: Notifications updated successfully");
      }
    } catch (e) {
      print("Sync Failed: $e");
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadUnreadCount() async {
    if (!await _isOnline()) {
      return;
    }

    try {
      Map<String, dynamic>? response = await api<ApiService>(
        (request) => request.fetchUnreadCount(),
      );

      if (response != null && response['data'] != null) {
        unreadCount = response['data']['unread_count'] ?? 0;
      }
    } catch (e) {
      print("Error loading unread count: $e");
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Update locally first
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        notifications[index].isRead = true;
        notifications[index].readAt = DateTime.now().toIso8601String();
      }

      // Update on server if online
      if (await _isOnline()) {
        await api<ApiService>(
          (request) => request.markNotificationAsRead(notificationId),
        );
      }

      // Save to storage
      try {
        await Keys.notifications.save(
            notifications.map((n) => n.toJson()).toList());
      } catch (e) {
        if (!e.toString().contains('-34018')) {
          print("Warning: Failed to save notifications to storage: $e");
        }
      }

      // Update unread count
      await loadUnreadCount();
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Update locally first
      for (var notification in notifications) {
        notification.isRead = true;
        notification.readAt = DateTime.now().toIso8601String();
      }

      // Update on server if online
      if (await _isOnline()) {
        await api<ApiService>(
          (request) => request.markAllNotificationsAsRead(),
        );
      }

      // Save to storage
      try {
        await Keys.notifications.save(
            notifications.map((n) => n.toJson()).toList());
      } catch (e) {
        if (!e.toString().contains('-34018')) {
          print("Warning: Failed to save notifications to storage: $e");
        }
      }

      // Update unread count
      unreadCount = 0;
    } catch (e) {
      print("Error marking all notifications as read: $e");
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      // Remove locally first
      notifications.removeWhere((n) => n.id == notificationId);

      // Delete on server if online
      if (await _isOnline()) {
        await api<ApiService>(
          (request) => request.deleteNotification(notificationId),
        );
      }

      // Save to storage
      try {
        await Keys.notifications.save(
            notifications.map((n) => n.toJson()).toList());
      } catch (e) {
        if (!e.toString().contains('-34018')) {
          print("Warning: Failed to save notifications to storage: $e");
        }
      }

      // Update unread count
      await loadUnreadCount();
    } catch (e) {
      print("Error deleting notification: $e");
    }
  }

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
