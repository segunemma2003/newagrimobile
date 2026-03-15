import 'dart:convert';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';

/// Converts a Dart object string representation to JSON string
/// Handles cases like: {id: 2, name: Admin User, email: admin@agrisiti.com, phone: null}
String? _convertDartObjectStringToJson(String dartString) {
  try {
    String result = dartString.trim();
    
    // Check if it starts with { or [
    if (!result.startsWith('{') && !result.startsWith('[')) {
      return null;
    }
    
    // Step 1: Add quotes around keys (pattern: key: -> "key":)
    result = result.replaceAllMapped(
      RegExp(r'([{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)\s*:'),
      (match) => '${match.group(1)}"${match.group(2)}":',
    );
    
    // Step 2: Handle values - quote unquoted strings, keep numbers/null/booleans as-is
    result = result.replaceAllMapped(
      RegExp(r':\s*([^,}\]]+?)(?=\s*[,}\]])'),
      (match) {
        String val = match.group(1)?.trim() ?? '';
        
        // Skip if already quoted
        if (val.startsWith('"') && val.endsWith('"')) {
          return ': $val';
        }
        
        // Keep null, true, false as-is
        if (val == 'null' || val == 'true' || val == 'false') {
          return ': $val';
        }
        
        // Check if it's a phone number (starts with +, or starts with 0 and has digits, or has many digits)
        // Phone numbers should always be strings, not numbers
        final isPhoneNumber = val.startsWith('+') || 
            (val.startsWith('0') && RegExp(r'^\d+$').hasMatch(val) && val.length >= 8) ||
            (RegExp(r'^\d+$').hasMatch(val) && val.length >= 10);
        
        // Keep numbers as-is (but not phone numbers)
        if (!isPhoneNumber && RegExp(r'^-?\d+(\.\d+)?$').hasMatch(val)) {
          // Don't allow leading zeros in JSON numbers (they cause parsing errors)
          // If it starts with 0 and has more digits, it's likely a phone number or ID, treat as string
          if (val.startsWith('0') && val.length > 1 && !val.contains('.')) {
            // Treat as string
            val = val.replaceAll('"', '\\"');
            return ': "$val"';
          }
          return ': $val';
        }
        
        // Quote everything else (strings, phone numbers, etc.)
        // Escape any existing quotes in the value
        val = val.replaceAll('"', '\\"');
        return ': "$val"';
      },
    );
    
    return result;
  } catch (e) {
    print('Error converting Dart object string to JSON: $e');
    return null;
  }
}

/// Safely reads user auth data from storage, handling both Map and String types
Map<String, dynamic>? safeReadAuthData() {
  try {
    // Try reading from Keys.auth first - use dynamic to avoid type errors
    dynamic data;
    try {
      // Use a try-catch to handle type casting errors from backpackRead
      data = backpackRead(Keys.auth);
    } catch (e) {
      // If backpackRead throws a type error (String is not a subtype of Map),
      // it means the data is stored as a String instead of a Map.
      // This happens when data is stored incorrectly (as Dart object string representation).
      // We can't recover from this without accessing raw storage, so return null.
      // The user will need to log in again, which will store the data correctly.
      if (e.toString().contains('is not a subtype of type')) {
        print('Warning: Auth data stored incorrectly (String instead of Map). User needs to log in again.');
      } else {
        print('Warning: Error reading auth data: $e');
      }
      return null;
    }
    
    if (data == null) return null;
    
    // If it's already a Map, return it
    if (data is Map<String, dynamic>) {
      return data;
    }
    
    // If it's a String, try to parse it
    if (data is String) {
      // Try JSON parsing first (for properly stored data)
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) {
          return parsed;
        }
      } catch (e) {
        // If JSON parsing fails, try converting Dart object string to JSON
        final jsonString = _convertDartObjectStringToJson(data);
        if (jsonString != null) {
          try {
            final parsed = jsonDecode(jsonString);
            if (parsed is Map<String, dynamic>) {
              return parsed;
            }
          } catch (e2) {
            print('Warning: Failed to parse converted JSON: $e2');
          }
        }
        // If all parsing fails, return null
        return null;
      }
    }
    
    return null;
  } catch (e, stackTrace) {
    // Catch any other errors and log them
    print('Error reading auth data: $e');
    print('Stack trace: $stackTrace');
    return null;
  }
}

/// Safely reads courses data from storage, handling both List and String types
List<Map<String, dynamic>>? safeReadCoursesData() {
  try {
    dynamic data;
    try {
      data = backpackRead(Keys.courses);
    } catch (e) {
      // If backpackRead throws a type error, the data might be stored incorrectly
      if (e.toString().contains('is not a subtype of type')) {
        print('Warning: Courses data stored incorrectly (String instead of List).');
      } else {
        print('Warning: Error reading courses data: $e');
      }
      return null;
    }
    
    if (data == null) return null;
    
    // If it's already a List, return it
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).where((item) => item.isNotEmpty).toList();
    }
    
    // If it's a String, try to parse it
    if (data is String) {
      // Try JSON parsing first (for properly stored data)
      try {
        final parsed = jsonDecode(data);
        if (parsed is List) {
          return parsed.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).where((item) => item.isNotEmpty).toList();
        }
      } catch (e) {
        // If JSON parsing fails, try converting Dart object string to JSON
        final jsonString = _convertDartObjectStringToJson(data);
        if (jsonString != null) {
          try {
            final parsed = jsonDecode(jsonString);
            if (parsed is List) {
              return parsed.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).where((item) => item.isNotEmpty).toList();
            }
          } catch (e2) {
            print('Warning: Failed to parse converted courses JSON: $e2');
          }
        }
        // If all parsing fails, return null
        return null;
      }
    }
    
    return null;
  } catch (e, stackTrace) {
    print('Error reading courses data: $e');
    print('Stack trace: $stackTrace');
    return null;
  }
}

/// Safely reads any data from storage and converts string to Map if needed
T? safeReadStorage<T>(StorageKey key) {
  try {
    final data = backpackRead(key);
    if (data == null) return null;
    
    // If T is Map<String, dynamic> and data is String, try to parse it
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        // Check if parsed type matches expected type
        if (parsed is Map && T.toString().contains('Map')) {
          return parsed as T;
        }
        if (parsed is List && T.toString().contains('List')) {
          return parsed as T;
        }
      } catch (e) {
        print('Warning: Failed to parse storage data as JSON: $e');
        return null;
      }
    }
    
    // If types match, return as-is
    if (data is T) {
      return data;
    }
    
    return null;
  } catch (e) {
    print('Error reading storage data: $e');
    return null;
  }
}
