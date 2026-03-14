import 'dart:convert';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';
import '/app/networking/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for queuing API requests when offline and syncing when online
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  /// Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Add request to offline queue
  Future<void> queueRequest({
    required String method, // GET, POST, PUT, DELETE, PATCH
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    String? id, // Optional unique ID for deduplication
  }) async {
    try {
      final queue = await getQueue();

      final request = {
        'id': id ?? '${DateTime.now().millisecondsSinceEpoch}_${endpoint}',
        'method': method,
        'endpoint': endpoint,
        'data': data,
        'headers': headers,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
      };

      // Check for duplicates (same endpoint and data)
      queue.removeWhere((item) =>
          item['endpoint'] == endpoint &&
          item['method'] == method &&
          _mapsEqual(item['data'], data));

      queue.add(request);
      await _saveQueue(queue);

      print('Queued offline request: $method $endpoint');
    } catch (e) {
      print('Error queueing request: $e');
    }
  }

  /// Get all queued requests
  Future<List<Map<String, dynamic>>> getQueue() async {
    try {
      final queueJson = await Keys.offlineQueue.read<List>();
      if (queueJson == null) return [];

      return queueJson
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          })
          .where((item) => item.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error reading queue: $e');
      return [];
    }
  }

  /// Save queue to storage
  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    try {
      await Keys.offlineQueue.save(queue);
    } catch (e) {
      print('Error saving queue: $e');
    }
  }

  /// Process queued requests when online
  Future<void> syncQueue() async {
    if (!await isOnline()) {
      print('Device is offline, cannot sync queue');
      return;
    }

    final queue = await getQueue();
    if (queue.isEmpty) {
      print('Queue is empty, nothing to sync');
      return;
    }

    print('Syncing ${queue.length} queued requests...');

    final failedRequests = <Map<String, dynamic>>[];

    for (final request in queue) {
      try {
        final success = await _processRequest(request);
        if (!success) {
          final retryCount = (request['retry_count'] as int? ?? 0) + 1;
          if (retryCount < 3) {
            // Retry up to 3 times
            request['retry_count'] = retryCount;
            failedRequests.add(request);
          } else {
            print('Request failed after 3 retries: ${request['endpoint']}');
          }
        }
      } catch (e) {
        print('Error processing queued request: $e');
        final retryCount = (request['retry_count'] as int? ?? 0) + 1;
        if (retryCount < 3) {
          request['retry_count'] = retryCount;
          failedRequests.add(request);
        }
      }
    }

    // Save failed requests back to queue
    await _saveQueue(failedRequests);

    // Update last sync timestamp
    await Keys.lastSyncTimestamp.save(DateTime.now().toIso8601String());

    if (failedRequests.isEmpty) {
      print('All queued requests synced successfully');
    } else {
      print('${failedRequests.length} requests failed and will be retried');
    }
  }

  /// Process a single queued request
  Future<bool> _processRequest(Map<String, dynamic> request) async {
    try {
      final method = request['method'] as String;
      final endpoint = request['endpoint'] as String;
      final data = request['data'] as Map<String, dynamic>?;

      final apiService = ApiService();

      // Execute the request based on method using ApiService's network method
      try {
        switch (method.toUpperCase()) {
          case 'POST':
            await apiService.network(
              request: (req) => req.post(endpoint, data: data),
            );
            break;
          case 'PUT':
            await apiService.network(
              request: (req) => req.put(endpoint, data: data),
            );
            break;
          case 'PATCH':
            await apiService.network(
              request: (req) => req.patch(endpoint, data: data),
            );
            break;
          case 'DELETE':
            await apiService.network(
              request: (req) => req.delete(endpoint, data: data),
            );
            break;
          default:
            print('Unsupported method: $method');
            return false;
        }

        print('Successfully processed queued request: $method $endpoint');
        return true;
      } catch (e) {
        // Check if it's a network error (should retry) or validation error (should not retry)
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('422') ||
            errorStr.contains('validation') ||
            errorStr.contains('400')) {
          // Validation errors - don't retry
          print('Validation error for request ${request['endpoint']}: $e');
          return false;
        }
        // Network or server errors - retry
        rethrow;
      }
    } catch (e) {
      print('Error processing request ${request['endpoint']}: $e');
      return false;
    }
  }

  /// Clear the queue
  Future<void> clearQueue() async {
    await _saveQueue([]);
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final queue = await getQueue();
    return queue.length;
  }

  /// Check if maps are equal
  bool _mapsEqual(Map? a, Map? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    try {
      return jsonEncode(a) == jsonEncode(b);
    } catch (e) {
      return false;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final timestamp = await Keys.lastSyncTimestamp.read<String>();
      if (timestamp != null) {
        return DateTime.tryParse(timestamp);
      }
    } catch (e) {
      print('Error reading last sync time: $e');
    }
    return null;
  }
}
