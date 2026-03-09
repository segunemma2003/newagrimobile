import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/networking/api_service.dart';
import '/resources/pages/login_page.dart';

class ResetPasswordPage extends NyStatefulWidget {
  final String? email;
  
  static RouteView path = ("/reset-password", (_) => ResetPasswordPage());

  ResetPasswordPage({super.key, this.email}) : super(child: () => _ResetPasswordPageState());
}

class _ResetPasswordPageState extends NyPage<ResetPasswordPage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Password visibility toggles
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Color scheme
  static const Color primary = Color(0xFF3F6967);
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF161C1B);

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
    // Try to get email from route arguments if not provided via widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map && args['email'] != null && _emailController.text.isEmpty) {
        setState(() {
          _emailController.text = args['email'];
        });
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark ? Colors.grey[400]! : const Color(0xFF6F7B7B);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFDFE2E2);

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
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!,
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
                      "Reset Password",
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
                      // Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.vpn_key,
                            color: primary,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Headline
                      Text(
                        "Enter Reset Code",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter the 6-digit code from your email along with your new password.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: secondaryTextColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Brand Accent Divider
                      Container(
                        height: 4,
                        width: 48,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Reset Code Field
                      _buildCodeField(
                        label: "Reset Code",
                        controller: _codeController,
                        hintText: "Enter 6-digit code",
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: bgColor,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the reset code';
                          }
                          if (value.trim().length != 6) {
                            return 'Code must be 6 characters';
                          }
                          if (!RegExp(r'^[0-9A-Za-z]{6}$').hasMatch(value.trim())) {
                            return 'Code must be 6 alphanumeric characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Email Field
                      _buildTextField(
                        label: "Email Address",
                        controller: _emailController,
                        hintText: "Enter your email",
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: bgColor,
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                        enabled: widget.email == null, // Disable if pre-filled
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 24),
                      // New Password Field
                      _buildPasswordField(
                        label: "New Password",
                        controller: _passwordController,
                        hintText: "Enter new password",
                        isVisible: _passwordVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: bgColor,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Confirm Password Field
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
                          if (value != _passwordController.text) {
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
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleResetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: primary.withValues(alpha: 0.3),
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
                            "Reset Password",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Token expires in 60 minutes",
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color inputBgColor,
    required bool isDark,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    bool enabled = true,
    IconData? icon,
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
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          obscureText: isVisible && onToggleVisibility != null,
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
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            prefixIcon: icon != null ? Icon(icon, color: accent, size: 20) : null,
            suffixIcon: onToggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: accent,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCodeField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color inputBgColor,
    required bool isDark,
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
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          textAlign: TextAlign.center,
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
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            prefixIcon: Icon(Icons.pin, color: accent, size: 20),
            counterText: '',
          ),
          validator: validator,
        ),
      ],
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
        TextFormField(
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
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            prefixIcon: Icon(Icons.lock_outline, color: accent, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: accent,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 8 characters"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await api<ApiService>(
        (request) => request.resetPassword(
          token: _codeController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
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
              content: Text(response['message'] ?? 'Password has been reset successfully. You can now login with your new password.'),
              backgroundColor: accent,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to login page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        } else {
          final errorMessage = response?['message'] ?? 
              response?['errors']?.toString() ?? 
              'Failed to reset password. Please try again.';
          
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
        if (e.toString().contains('Invalid reset token') || e.toString().contains('expired') || e.toString().contains('Invalid reset code')) {
          errorMessage = 'Invalid or expired reset code. Please request a new password reset code.';
        } else if (e.toString().contains('No user found')) {
          errorMessage = 'No user found with this email address.';
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
