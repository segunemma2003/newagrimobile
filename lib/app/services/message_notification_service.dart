import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '/app/services/pusher_service.dart';
import '/app/networking/api_service.dart';
import '/app/helpers/storage_helper.dart';
import '/app/helpers/text_helper.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Service to handle message notifications via Pusher
/// Shows local notifications when messages arrive
class MessageNotificationService {
  static final MessageNotificationService _instance = MessageNotificationService._internal();
  factory MessageNotificationService() => _instance;
  MessageNotificationService._internal();

  final PusherService _pusherService = PusherService.getInstance();
  final Set<String> _subscribedChannels = {};
  String? _currentUserId;
  FlutterLocalNotificationsPlugin? _localNotifications;

  /// Initialize and subscribe to user's message channels
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
          print('Notification tapped: ${details.payload}');
        },
      );

      // Request permissions
      await _requestPermissions();

      // Get current user
      final userData = safeReadAuthData();
      _currentUserId = userData?['id']?.toString();

      if (_currentUserId == null) {
        print('MessageNotificationService: No user logged in');
        return;
      }

      // Initialize Pusher if not already
      if (!_pusherService.isInitialized) {
        await _pusherService.initialize();
      }

      if (!_pusherService.isConnected) {
        await _pusherService.connect();
      }

      // Subscribe to user's enrolled courses for messages
      await _subscribeToUserChannels();

      print('MessageNotificationService initialized');
    } catch (e) {
      print('Error initializing MessageNotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (_localNotifications == null) return;

    try {
      // Android 13+ requires explicit permission
      final androidPlugin = _localNotifications!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      // iOS requires explicit permission
      final iosPlugin = _localNotifications!.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  /// Subscribe to all channels for user's enrolled courses
  Future<void> _subscribeToUserChannels() async {
    try {
      // Get user's enrolled courses
      final apiService = ApiService();
      final enrollmentsResponse = await apiService.fetchMyEnrollments();

      if (enrollmentsResponse == null) return;

      dynamic enrollments;
      if (enrollmentsResponse is List) {
        enrollments = enrollmentsResponse;
      } else if (enrollmentsResponse is Map) {
        enrollments = enrollmentsResponse['data'] ?? [];
      } else {
        enrollments = [];
      }

      if (enrollments is! List) return;

      // Subscribe to each course's message channel
      for (var enrollment in enrollments) {
        final courseId = enrollment['course_id']?.toString() ?? 
                        enrollment['course']?['id']?.toString();
        
        if (courseId != null && _currentUserId != null) {
          final channelName = 'private-course.$courseId.user.$_currentUserId';
          
          if (!_subscribedChannels.contains(channelName)) {
            await _subscribeToChannel(channelName);
            _subscribedChannels.add(channelName);
          }
        }
      }
    } catch (e) {
      print('Error subscribing to user channels: $e');
    }
  }

  /// Subscribe to a specific channel and listen for messages
  Future<void> _subscribeToChannel(String channelName) async {
    try {
      await _pusherService.subscribePrivate(channelName);

      // Listen for message-sent events
      _pusherService.bind(channelName, 'message-sent', (event) {
        _handleMessageEvent(event);
      });

      print('Subscribed to message channel: $channelName');
    } catch (e) {
      print('Error subscribing to channel $channelName: $e');
    }
  }

  /// Handle incoming message event and show notification
  void _handleMessageEvent(PusherEvent event) {
    try {
      // Parse event data
      dynamic messageData;
      if (event.data is String) {
        try {
          messageData = jsonDecode(event.data);
        } catch (e) {
          print('Error parsing Pusher message event: $e');
          return;
        }
      } else {
        messageData = event.data;
      }

      if (messageData == null) return;

      final senderId = messageData['sender_id']?.toString();
      final recipientId = messageData['recipient_id']?.toString();

      // Only show notification if message is for current user
      if (recipientId != _currentUserId) return;

      // Don't show notification if user sent the message
      if (senderId == _currentUserId) return;

      final senderName = messageData['sender']?['name'] ?? 
                        messageData['sender_name'] ?? 
                        'Someone';
      final messageText = messageData['message'] ?? 
                         messageData['subject'] ?? 
                         'New message';
      
      // Strip HTML from message
      final cleanMessage = stripHtmlTags(messageText);

      // Show local notification
      _showNotification(
        title: senderName,
        body: cleanMessage,
        data: {
          'type': 'message',
          'message_id': messageData['id']?.toString(),
          'course_id': messageData['course_id']?.toString(),
          'sender_id': senderId,
        },
      );
    } catch (e) {
      print('Error handling message event: $e');
    }
  }

  /// Show local notification
  Future<void> _showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (_localNotifications == null) return;

      const androidDetails = AndroidNotificationDetails(
        'messages_channel',
        'Messages',
        channelDescription: 'Notifications for new messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: data?.toString() ?? '',
      );

      print('Notification shown: $title - $body');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Refresh subscriptions (call when user enrolls in new course)
  Future<void> refreshSubscriptions() async {
    _subscribedChannels.clear();
    await _subscribeToUserChannels();
  }

  /// Cleanup
  void dispose() {
    for (var channel in _subscribedChannels) {
      _pusherService.unbind(channel, 'message-sent');
      _pusherService.unsubscribe(channel);
    }
    _subscribedChannels.clear();
  }
}
