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
    
    if (nameRaw == null || emailRaw == null || passwordRaw == null || 
        nameRaw.toString().trim().isEmpty || 
        emailRaw.toString().trim().isEmpty || 
        passwordRaw.toString().trim().isEmpty) {
      _lastError = "Please fill in all fields";
      form.validate();
      return false;
    }

    final name = nameRaw.toString().trim();
    final email = emailRaw.toString().trim();
    final password = passwordRaw.toString().trim();
    
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
        ),
      ) as Map<String, dynamic>?;

      if (response != null && 
          (response['success'] == true || response['data'] != null)) {
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
    } catch (e) {
      print("Registration Error: $e");
      _lastError = "Registration failed. Please try again.";
      return false;
    }

    _lastError = "Registration failed. Please try again.";
    return false;
  }
}
