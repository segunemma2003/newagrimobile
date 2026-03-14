import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';
import '/app/helpers/storage_helper.dart';
import '/app/helpers/image_helper.dart';
import '/app/networking/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends NyStatefulWidget {
  static RouteView path = ("/edit-profile", (_) => EditProfilePage());

  EditProfilePage({super.key}) : super(child: () => _EditProfilePageState());
}

class _EditProfilePageState extends NyPage<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  TextEditingController? _locationController;
  Map<String, dynamic>? _userData;
  String? _selectedImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  // Color scheme - maintain from other pages
  static const Color primary = Color(0xFF3F6967);
  static const Color accent = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF161C1B);

  @override
  get init => () async {
        await _loadUserData();
        _nameController = TextEditingController(text: _userData?['name'] ?? '');
        _emailController =
            TextEditingController(text: _userData?['email'] ?? '');
        _phoneController =
            TextEditingController(text: _userData?['phone'] ?? '');
        _locationController =
            TextEditingController(text: _userData?['location'] ?? '');
      };

  Future<void> _loadUserData() async {
    try {
      _userData = await Keys.auth.read<Map<String, dynamic>>();
      if (_userData == null) {
        _userData = safeReadAuthData();
      }
      setState(() {});
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to load user data: $e');
      }
      _userData = safeReadAuthData();
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });

        // Upload image immediately
        await _uploadAvatar(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadAvatar(String imagePath) async {
    try {
      final api = ApiService();
      final response = await api.uploadAvatar(imagePath);

      if (response['data'] != null && response['data']['user'] != null) {
        final userData = response['data']['user'];
        if (userData is Map<String, dynamic>) {
          // Update local storage
          await Keys.auth.save(userData);
          backpackSave(Keys.auth, userData);

          // Update local user data
          _userData = userData;

          // Clear selected image path since it's now uploaded
          setState(() {
            _selectedImagePath = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated!'),
              backgroundColor: accent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading picture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Prepare update data
      final updateData = {
        'name': _nameController?.text.trim() ?? '',
        'email': _emailController?.text.trim() ?? '',
        'phone': _phoneController?.text.trim(),
        'location': _locationController?.text.trim(),
      };

      // Remove null/empty values
      updateData.removeWhere((key, value) {
        if (value == null) return true;
        final strValue = value.toString();
        if (strValue.isEmpty) return true;
        return false;
      });

      // Update via API
      final api = ApiService();
      final response = await api.updateProfile(updateData);

      // Update local storage with response
      if (response['data'] != null && response['data']['user'] != null) {
        final userData = response['data']['user'];
        if (userData is Map<String, dynamic>) {
          await Keys.auth.save(userData);
          backpackSave(Keys.auth, userData);
        }
      } else {
        // Fallback: update local data
        final updatedData = Map<String, dynamic>.from(_userData ?? {});
        updatedData.addAll(updateData);
        await Keys.auth.save(updatedData);
        backpackSave(Keys.auth, updatedData);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: accent,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    _locationController?.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : primary;
    final inputBgColor = isDark ? Colors.grey[900]! : Colors.white;

    final currentAvatar = _selectedImagePath != null
        ? FileImage(File(_selectedImagePath!))
        : (_userData?['avatar'] != null &&
                _userData!['avatar'].toString().isNotEmpty
            ? NetworkImage(getImageUrl(_userData!['avatar']))
            : null);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Top Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[100]!,
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
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: textColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Edit Profile",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balance for back button
                  ],
                ),
              ),
              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      // Profile Photo Section
                      Stack(
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? (Colors.grey[800] ?? Colors.grey)
                                    : Colors.white,
                                width: 4,
                              ),
                              image: currentAvatar != null
                                  ? DecorationImage(
                                      image: currentAvatar as ImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: currentAvatar == null
                                  ? accent.withValues(alpha: 0.2)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: currentAvatar == null
                                ? Center(
                                    child: Text(
                                      (_userData?['name'] ?? 'JD')[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          // Camera Edit Button
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickImage,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? (Colors.grey[800] ?? Colors.grey)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tap to change photo button
                      TextButton(
                        onPressed: _pickImage,
                        child: Text(
                          "Tap to change photo",
                          style: TextStyle(
                            color: primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Form Fields
                      // Full Name
                      _buildTextField(
                        label: "Full Name",
                        controller: _nameController,
                        hintText: "Enter your full name",
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: inputBgColor,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Email
                      _buildTextField(
                        label: "Email",
                        controller: _emailController,
                        hintText: "jane@example.com",
                        keyboardType: TextInputType.emailAddress,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: inputBgColor,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Phone Number
                      _buildTextField(
                        label: "Phone Number",
                        controller: _phoneController,
                        hintText: "+1 234 567 890",
                        keyboardType: TextInputType.phone,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: inputBgColor,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Location
                      _buildTextField(
                        label: "Location",
                        controller: _locationController,
                        hintText: "City",
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                        inputBgColor: inputBgColor,
                        isDark: isDark,
                        validator: null, // Optional field
                      ),
                      const SizedBox(height: 24), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Footer Action (Save Changes)
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 +
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100]!,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: primary.withValues(alpha: 0.3),
            ),
            child: const Text(
              "Save Changes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController? controller,
    required String hintText,
    TextInputType? keyboardType,
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            filled: true,
            fillColor: inputBgColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
