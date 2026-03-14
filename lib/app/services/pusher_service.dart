import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:nylo_framework/nylo_framework.dart';

/// Service for real-time messaging using Pusher
class PusherService {
  static PusherService? _instance;
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  bool _isConnected = false;
  bool _isInitialized = false;

  PusherService._();

  static PusherService getInstance() {
    _instance ??= PusherService._();
    return _instance!;
  }

  /// Initialize Pusher connection
  Future<void> initialize() async {
    if (_isInitialized) {
      print('Pusher already initialized');
      return;
    }

    try {
      // Get Pusher credentials from environment
      final appKey = getEnv('PUSHER_APP_KEY', defaultValue: '');
      final cluster = getEnv('PUSHER_APP_CLUSTER', defaultValue: 'mt1');

      if (appKey.isEmpty) {
        print('Warning: PUSHER_APP_KEY not configured');
        return;
      }

      await pusher.init(
        apiKey: appKey,
        cluster: cluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
      );

      _isInitialized = true;
      print('Pusher initialized successfully');
    } catch (e) {
      print('Error initializing Pusher: $e');
      _isInitialized = false;
    }
  }

  /// Connect to Pusher
  Future<void> connect() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isConnected) {
      print('Pusher already connected');
      return;
    }

    try {
      await pusher.connect();
      _isConnected = true;
      print('Pusher connected');
    } catch (e) {
      print('Error connecting to Pusher: $e');
      _isConnected = false;
    }
  }

  /// Disconnect from Pusher
  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    try {
      await pusher.disconnect();
      _isConnected = false;
      print('Pusher disconnected');
    } catch (e) {
      print('Error disconnecting from Pusher: $e');
    }
  }

  /// Subscribe to a channel
  Future<void> subscribe(String channelName) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      await pusher.subscribe(channelName: channelName);
      print('Subscribed to channel: $channelName');
    } catch (e) {
      print('Error subscribing to channel $channelName: $e');
    }
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(String channelName) async {
    try {
      await pusher.unsubscribe(channelName: channelName);
      print('Unsubscribed from channel: $channelName');
    } catch (e) {
      print('Error unsubscribing from channel $channelName: $e');
    }
  }

  /// Subscribe to a private channel (requires authentication)
  /// The backend provides authorization via /api/broadcasting/auth endpoint
  Future<void> subscribePrivate(String channelName) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      // Subscribe to private channel with authorization
      // The pusher_channels_flutter package will automatically call the authorization endpoint
      // Make sure your backend has the authorization endpoint configured
      await pusher.subscribe(channelName: channelName);
      print('Subscribed to private channel: $channelName');
    } catch (e) {
      print('Error subscribing to private channel $channelName: $e');
    }
  }

  // Store event callbacks for filtering
  final Map<String, Function(PusherEvent)> _eventCallbacks = {};

  /// Bind to an event on a channel
  /// Events are handled through the onEvent callback in init()
  /// This method stores callbacks that will be called when matching events arrive
  void bind(String channelName, String eventName, Function(PusherEvent) callback) {
    _eventCallbacks['$channelName:$eventName'] = callback;
  }

  /// Unbind from an event on a channel
  void unbind(String channelName, String eventName) {
    _eventCallbacks.remove('$channelName:$eventName');
  }

  // Event handlers
  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print('Pusher connection state changed: $previousState -> $currentState');
    _isConnected = currentState == 'CONNECTED';
  }

  void _onError(String message, int? code, dynamic e) {
    print('Pusher error: $message (code: $code)');
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    print('Successfully subscribed to channel: $channelName');
  }

  void _onEvent(PusherEvent event) {
    print('Pusher event received: ${event.eventName} on ${event.channelName}');
    print('Event data: ${event.data}');
    
    // Check if there's a callback for this channel:event combination
    final callbackKey = '${event.channelName}:${event.eventName}';
    final callback = _eventCallbacks[callbackKey];
    if (callback != null) {
      callback(event);
    }
  }

  void _onSubscriptionError(String message, dynamic e) {
    print('Pusher subscription error: $message');
  }

  void _onDecryptionFailure(String event, String reason) {
    print('Pusher decryption failure: $event - $reason');
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    print('Member added to channel $channelName: ${member.userId}');
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    print('Member removed from channel $channelName: ${member.userId}');
  }

  /// Get connection state
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
}
