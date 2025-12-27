import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';
import '/resources/widgets/safearea_widget.dart';

class ProfilePage extends NyStatefulWidget {
  static RouteView path = ("/profile", (_) => ProfilePage());

  ProfilePage({super.key}) : super(child: () => _ProfilePageState());
}

class _ProfilePageState extends NyPage<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Map<String, dynamic>? _userData;
  bool _isEditing = false;
  bool _isChangingPassword = false;

  @override
  get init => () async {
        await _loadUserData();
        // Check if we should show change password section
        final data = widget.data<Map<String, dynamic>>();
        if (data != null && data['showChangePassword'] == true) {
          setState(() {
            _isChangingPassword = true;
          });
        }
      };

  Future<void> _loadUserData() async {
    try {
      _userData = await Keys.auth.read<Map<String, dynamic>>();
      if (_userData == null) {
        // Try Backpack
        _userData = backpackRead(Keys.auth);
      }

      if (_userData != null) {
        _nameController.text = _userData!['name'] ?? '';
        _emailController.text = _userData!['email'] ?? '';
        _phoneController.text = _userData!['phone'] ?? '';
        _bioController.text = _userData!['bio'] ?? '';
      }
      setState(() {});
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name and email are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final updatedData = {
        ...?_userData,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      // Save to storage
      try {
        await Keys.auth.save(updatedData);
      } catch (e) {
        // Suppress error logging for Keychain issues on simulator
        if (!e.toString().contains('-34018')) {
          print('Warning: Failed to save to storage: $e');
        }
      }

      // Save to Backpack
      backpackSave(Keys.auth, updatedData);

      _userData = updatedData;
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Color(0xFF2D8659),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.trim().isEmpty ||
        _newPasswordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All password fields are required"),
          backgroundColor: Colors.red,
        ),
      );
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

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // In a real app, you would call an API here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password changed successfully"),
        backgroundColor: Color(0xFF2D8659),
      ),
    );

    setState(() {
      _isChangingPassword = false;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _updateProfile,
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Color(0xFF2D8659),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF2D8659)),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SafeAreaWidget(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF2D8659),
                      child: Text(
                        _userData?['name']
                                ?.toString()
                                .substring(0, 1)
                                .toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userData?['name'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData?['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Profile Information
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: "Full Name",
                      controller: _nameController,
                      enabled: _isEditing,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Email",
                      controller: _emailController,
                      enabled: _isEditing,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Phone",
                      controller: _phoneController,
                      enabled: _isEditing,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Bio",
                      controller: _bioController,
                      enabled: _isEditing,
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Change Password Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isChangingPassword = !_isChangingPassword;
                            });
                          },
                          child: Text(
                            _isChangingPassword ? "Cancel" : "Change",
                            style: const TextStyle(
                              color: Color(0xFF2D8659),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isChangingPassword) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Current Password",
                        controller: _currentPasswordController,
                        enabled: true,
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "New Password",
                        controller: _newPasswordController,
                        enabled: true,
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Confirm New Password",
                        controller: _confirmPasswordController,
                        enabled: true,
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D8659),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Update Password",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Other Options
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.notifications_outlined,
                      title: "Notifications",
                      onTap: () {
                        // Navigate back to main and switch to notifications tab
                        Navigator.of(context).pop(); // Close profile page
                        // Notifications are accessible from bottom nav
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.message_outlined,
                      title: "Contact Admin",
                      onTap: () => routeTo("/contact-admin"),
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.settings_outlined,
                      title: "Settings",
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.logout,
                      title: "Logout",
                      onTap: () async {
                        try {
                          // Clear auth data
                          try {
                            await Keys.auth.save(null);
                            await Keys.bearerToken.save(null);
                          } catch (e) {
                            print('Warning: Failed to clear auth data: $e');
                          }
                          // Clear from Backpack
                          backpackDelete(Keys.auth);
                          backpackDelete(Keys.bearerToken);
                          routeTo("/login");
                        } catch (e) {
                          print('Error during logout: $e');
                          routeTo("/login");
                        }
                      },
                      textColor: Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF666666)),
        prefixIcon: Icon(icon, color: const Color(0xFF2D8659)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2D8659), width: 2),
        ),
        filled: true,
        fillColor: enabled ? const Color(0xFFFAFAFA) : Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? const Color(0xFF2D8659)),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF999999)),
      onTap: onTap,
    );
  }
}
