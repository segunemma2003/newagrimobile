import 'package:nylo_framework/nylo_framework.dart';
import '/app/forms/register_form.dart';
import '/app/networking/api_service.dart';
import '/config/keys.dart';

class RegisterController extends NyController {
  String? _lastError;

  String? get lastError => _lastError;

  Future<bool> register(RegisterForm form) async {
    _lastError = null;
    // Get form data
    final nameRaw = form.data()['Name'] ?? form.data()['name'];
    final emailRaw = form.data()['Email'] ?? form.data()['email'];
    final passwordRaw = form.data()['Password'] ?? form.data()['password'];
    final passwordConfirmationRaw = form.data()['Password Confirmation'] ??
        form.data()['password_confirmation'] ??
        form.data()['passwordConfirmation'];
    final phoneRaw = form.data()['Phone'] ?? form.data()['phone'];

    if (nameRaw == null ||
        emailRaw == null ||
        passwordRaw == null ||
        passwordConfirmationRaw == null ||
        nameRaw.toString().trim().isEmpty ||
        emailRaw.toString().trim().isEmpty ||
        passwordRaw.toString().trim().isEmpty ||
        passwordConfirmationRaw.toString().trim().isEmpty) {
      _lastError = "Please fill in all required fields";
      form.validate();
      return false;
    }

    final name = nameRaw.toString().trim();
    final email = emailRaw.toString().trim();
    final password = passwordRaw.toString().trim();
    final passwordConfirmation = passwordConfirmationRaw.toString().trim();
    final phone = phoneRaw != null ? phoneRaw.toString().trim() : null;

    // Validate passwords match
    if (password != passwordConfirmation) {
      _lastError = "Passwords do not match";
      return false;
    }

    // Validate form
    if (form.validate() == false) {
      _lastError = "Please check your input fields";
      return false;
    }

    try {
      // Try API first
      Map<String, dynamic>? response = await api<ApiService>(
        (request) => request.register(
          name: name,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
          phone: phone,
        ),
      ) as Map<String, dynamic>?;

      if (response != null) {
        // Check for success response (201 Created)
        if (response['success'] == true || response['data'] != null) {
          // Handle API response
          final data = response['data'] ?? response;
          try {
            if (data['user'] != null) {
              await Keys.auth.save(data['user']);
              backpackSave(Keys.auth, data['user']);
            }
            if (data['token'] != null) {
              await Keys.bearerToken.save(data['token']);
              backpackSave(Keys.bearerToken, data['token']);
            }
          } catch (e) {
            if (!e.toString().contains('-34018')) {
              print('Warning: Failed to save auth data to storage: $e');
            }
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

        // Check for validation errors (422)
        if (response['errors'] != null) {
          final errors = response['errors'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else {
              errorMessages.add(value.toString());
            }
          });
          _lastError = errorMessages.isNotEmpty
              ? errorMessages.join(', ')
              : response['message'] ?? "Validation failed";
          return false;
        }

        // Check for error message
        if (response['message'] != null) {
          _lastError = response['message'];
          return false;
        }
      }
    } catch (e) {
      print("Registration Error: $e");
      // Try to extract error message from exception
      String errorMessage = "Registration failed. Please try again.";
      if (e.toString().contains('422') || e.toString().contains('validation')) {
        errorMessage = "Please check your input fields and try again.";
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = "Authentication failed. Please try again.";
      } else if (e.toString().contains('email') &&
          e.toString().contains('taken')) {
        errorMessage = "This email is already registered.";
      }
      _lastError = errorMessage;
      return false;
    }

    _lastError = "Registration failed. Please try again.";
    return false;
  }
}
