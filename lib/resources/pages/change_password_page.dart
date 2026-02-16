import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/networking/api_service.dart';

class ChangePasswordPage extends NyStatefulWidget {
  static RouteView path = ("/change-password", (_) => ChangePasswordPage());

  ChangePasswordPage({super.key}) : super(child: () => _ChangePasswordPageState());
}

class _ChangePasswordPageState extends NyPage<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Password visibility toggles
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // Color scheme - maintain from other pages
  static const Color primary = Color(0xFF3F6967);
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF161C1B);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _calculatePasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length < 8) return 'Medium';
    if (password.length >= 8 && 
        password.contains(RegExp(r'[A-Z]')) && 
        password.contains(RegExp(r'[a-z]')) && 
        password.contains(RegExp(r'[0-9]'))) {
      return 'Strong';
    }
    return 'Medium';
  }

  double _getPasswordStrengthProgress(String password) {
    final strength = _calculatePasswordStrength(password);
    switch (strength) {
      case 'Weak':
        return 0.33;
      case 'Medium':
        return 0.66;
      case 'Strong':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark ? Colors.grey[400]! : const Color(0xFF6F7B7B);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFDFE2E2);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
          "Change Password",
                      textAlign: TextAlign.center,
          style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primary,
                        letterSpacing: -0.5,
          ),
        ),
      ),
                  const SizedBox(width: 40), // Balance for back button
                ],
              ),
            ),
            // Main Content
            Expanded(
        child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      const SizedBox(height: 32),
                      // Headline & Intro
                      Text(
                        "Secure Your Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please enter your current password and choose a new strong one to update your credentials.",
                          style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: secondaryTextColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Brand Accent Divider (Mint Line)
                      Container(
                        height: 4,
                        width: 48,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),
                      // Current Password Field
                _buildPasswordField(
                  label: "Current Password",
                  controller: _currentPasswordController,
                        hintText: "Enter current password",
                        isVisible: _currentPasswordVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _currentPasswordVisible = !_currentPasswordVisible;
                          });
                        },
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: bgColor,
                        isDark: isDark,
                        showForgotPassword: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // New Password Field
                _buildPasswordField(
                  label: "New Password",
                  controller: _newPasswordController,
                        hintText: "Create new password",
                        isVisible: _newPasswordVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _newPasswordVisible = !_newPasswordVisible;
                          });
                        },
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: bgColor,
                        isDark: isDark,
                        showStrengthIndicator: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Confirm New Password Field
                _buildPasswordField(
                  label: "Confirm New Password",
                  controller: _confirmPasswordController,
                        hintText: "Re-type new password",
                        isVisible: _confirmPasswordVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: bgColor,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Action Area
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
                  ),
                ),
              ),
              child: Column(
                children: [
                SizedBox(
                  width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: primary.withOpacity(0.3),
                      ),
                      icon: const Icon(Icons.lock_reset, size: 20),
                      label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Update Password",
                            style: TextStyle(
                              fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                  Text(
                    "Your data is protected by Agrisiti encryption.",
                    textAlign: TextAlign.center,
                      style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color inputBgColor,
    required bool isDark,
    bool showForgotPassword = false,
    bool showStrengthIndicator = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[200] : textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
          controller: controller,
                obscureText: !isVisible,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
          decoration: InputDecoration(
            hintText: hintText,
                  hintStyle: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: inputBgColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                validator: validator,
                onChanged: showStrengthIndicator ? (value) => setState(() {}) : null,
              ),
            ),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: inputBgColor,
                border: Border(
                  top: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleVisibility,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: accent,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showForgotPassword) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                routeTo("/forgot-password");
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Forgot password?",
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
        if (showStrengthIndicator && controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _getPasswordStrengthProgress(controller.text),
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _calculatePasswordStrength(controller.text).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the actual API
      Map<String, dynamic>? response = await api<ApiService>(
        (request) => request.changePassword(
          currentPassword: _currentPasswordController.text.trim(),
          password: _newPasswordController.text.trim(),
          passwordConfirmation: _confirmPasswordController.text.trim(),
        ),
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (response != null && response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Password changed successfully'),
              backgroundColor: accent,
              duration: const Duration(seconds: 2),
            ),
          );

          // Clear fields and go back
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          Navigator.of(context).pop();
        } else {
          final errorMessage = response?['message'] ?? 
              response?['errors']?.toString() ?? 
              'Failed to change password. Please try again.';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = 'An error occurred. Please try again.';
        
        // Handle specific error cases
        if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
          errorMessage = 'Your session has expired. Please login again.';
        } else if (e.toString().contains('Current password is incorrect')) {
          errorMessage = 'Current password is incorrect. Please try again.';
        } else if (e.toString().contains('must be different')) {
          errorMessage = 'New password must be different from your current password.';
        } else if (e.toString().contains('at least 8 characters')) {
          errorMessage = 'Password must be at least 8 characters long.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
