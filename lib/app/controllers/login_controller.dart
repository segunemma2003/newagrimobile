import 'package:nylo_framework/nylo_framework.dart';
import '/app/forms/login_form.dart';
import '/app/networking/api_service.dart';
import '/config/keys.dart';

class LoginController extends NyController {
  String? _lastError;

  String? get lastError => _lastError;

  Future<bool> login(LoginForm form) async {
    _lastError = null;
    // Get form data - try both possible field name formats
    final emailRaw = form.data()['Email'] ?? form.data()['email'];
    final passwordRaw = form.data()['Password'] ?? form.data()['password'];

    // Debug logging
    print(
        "Login attempt - Email (raw): '$emailRaw', Password (raw): '$passwordRaw'");
    print("Form data keys: ${form.data().keys}");
    print("Form data values: ${form.data()}");

    if (emailRaw == null ||
        passwordRaw == null ||
        emailRaw.toString().trim().isEmpty ||
        passwordRaw.toString().trim().isEmpty) {
      print("Login Failed: Email or password is null or empty");
      print("Email value: $emailRaw, Password value: $passwordRaw");
      _lastError = "Please fill in all fields";
      form.validate();
      return false;
    }

    final email = emailRaw.toString().trim();
    final password = passwordRaw.toString().trim();

    // Validate form
    if (form.validate() == false) {
      print("Form validation failed");
      _lastError = "Please check your input fields";
      return false;
    }

    try {
      // Try API first
      Map<String, dynamic>? response = await api<ApiService>(
        (request) => request.login(
          email: email,
          password: password,
        ),
      );

      if (response != null &&
          (response['success'] == true || response['data'] != null)) {
        // Handle API response
        final data = response['data'] ?? response;
        try {
          if (data['user'] != null) {
            await Keys.auth.save(data['user']);
            // Also save to Backpack for session (works without Keychain)
            backpackSave(Keys.auth, data['user']);
          }
          if (data['token'] != null) {
            await Keys.bearerToken.save(data['token']);
            // Also save to Backpack for session (works without Keychain)
            backpackSave(Keys.bearerToken, data['token']);
          }
        } catch (e) {
          // Suppress error logging for Keychain issues on simulator
          if (!e.toString().contains('-34018')) {
            print('Warning: Failed to save auth data to storage: $e');
          }
          // Save to Backpack anyway for session (works without Keychain)
          if (data['user'] != null) {
            backpackSave(Keys.auth, data['user']);
          }
          if (data['token'] != null) {
            backpackSave(Keys.bearerToken, data['token']);
          }
        }
        routeTo("/main");
        return true;
      }
    } catch (e) {
      // API failed - check for specific error responses
      print("API Error: $e");

      // Try to extract error message from exception
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _lastError = "Invalid email or password. Please try again.";
        return false;
      } else if (e.toString().contains('403') ||
          e.toString().contains('Forbidden')) {
        _lastError = "Your account is inactive. Please contact support.";
        return false;
      } else if (e.toString().contains('422') ||
          e.toString().contains('validation')) {
        _lastError = "Please check your input fields and try again.";
        return false;
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Failed host lookup')) {
        _lastError = "Network error. Please check your connection and try again.";
        return false;
      } else {
        _lastError = "Login failed. Please try again.";
        return false;
      }
    }
    
    return false;
  }
}
