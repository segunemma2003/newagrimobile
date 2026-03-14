import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';
import '/app/helpers/storage_helper.dart';
import '/app/helpers/image_helper.dart';
import '/resources/pages/notification_settings_page.dart';
import '/resources/pages/help_support_page.dart';
import '/resources/pages/terms_conditions_page.dart';
import '/resources/pages/edit_profile_page.dart';
import '/resources/pages/certificates_page.dart';
import '/resources/pages/change_password_page.dart';

class ProfilePage extends NyStatefulWidget {
  static RouteView path = ("/profile", (_) => ProfilePage());

  ProfilePage({super.key}) : super(child: () => _ProfilePageState());
}

class _ProfilePageState extends NyPage<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _wifiOnlyDownloads = true;

  // Color scheme from HTML
  static const Color primary = Color(0xFF50C1AE); // Teal/Green from brand
  static const Color brandDark = Color(0xFF3E6866); // Dark green from brand
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFA);

  @override
  get init => () async {
        await _loadUserData();
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

  Future<void> _handleLogout() async {
    try {
      // Clear auth data
      try {
        await Keys.auth.save(null);
        await Keys.bearerToken.save(null);
      } catch (e) {
        if (!e.toString().contains('-34018')) {
          print('Warning: Failed to clear auth data: $e');
        }
      }
      // Clear from Backpack
      backpackDelete(Keys.auth);
      backpackDelete(Keys.bearerToken);
      routeTo("/login");
    } catch (e) {
      print('Error during logout: $e');
      routeTo("/login");
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Show confirmation dialog again for safety
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Final Confirmation"),
        content: const Text(
          "This is your last chance. Are you absolutely sure you want to delete your account?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true) {
      return;
    }

    try {
      // Clear all user data
      try {
        await Keys.auth.save(null);
        await Keys.bearerToken.save(null);
        await Keys.courses.save(null);
        await Keys.courseProgress.save(null);
        await Keys.moduleProgress.save(null);
        await Keys.notes.save(null);
        await Keys.assignments.save(null);
        await Keys.comments.save(null);
        await Keys.reviews.save(null);
        await Keys.messages.save(null);
      } catch (e) {
        if (!e.toString().contains('-34018')) {
          print('Warning: Failed to clear data: $e');
        }
      }

      // Clear from Backpack
      backpackDelete(Keys.auth);
      backpackDelete(Keys.bearerToken);
      backpackDelete(Keys.courses);
      backpackDelete(Keys.courseProgress);
      backpackDelete(Keys.moduleProgress);
      backpackDelete(Keys.notes);
      backpackDelete(Keys.assignments);
      backpackDelete(Keys.comments);
      backpackDelete(Keys.reviews);
      backpackDelete(Keys.messages);

      // In a real app, you would call an API to delete the account
      // await api<ApiService>((request) => request.deleteAccount());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        routeTo("/login");
      }
    } catch (e) {
      print('Error during account deletion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting account: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final userName = _userData?['name']?.toString() ?? "Alex Doe";
    final userEmail = _userData?['email']?.toString() ?? "alex.doe@example.com";
    final userAvatar = _userData?['avatar']?.toString();
    final coursesCount =
        _userData?['courses_enrolled'] ?? _userData?['coursesEnrolled'] ?? 0;
    final hoursLearned =
        _userData?['hours_learned'] ?? _userData?['hoursLearned'] ?? 0;
    final certificatesAcquired = _userData?['certificates_acquired'] ??
        _userData?['certificatesAcquired'] ??
        0;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundLight.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[100]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Profile",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: brandDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 24),
                    color: brandDark,
                    onPressed: () {
                      // TODO: Show more options
                    },
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Section with Gradient Background
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            brandDark.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Avatar with Camera Button
                          Stack(
                            children: [
                              Container(
                                width: 112, // h-28 w-28
                                height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                  image: userAvatar != null &&
                                          userAvatar.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              getImageUrl(userAvatar)),
                                          fit: BoxFit.cover,
                                          onError: (_, __) {},
                                        )
                                      : null,
                                ),
                                child: userAvatar == null || userAvatar.isEmpty
                                    ? Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              brandDark.withValues(alpha: 0.1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            userName.isNotEmpty
                                                ? userName[0].toUpperCase()
                                                : "A",
                                            style: TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w700,
                                              color: brandDark,
                                            ),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              // Camera Button
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.photo_camera,
                                        size: 18, color: Colors.white),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      // TODO: Implement photo picker
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Name and Email
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: brandDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Edit Profile Button
                          ElevatedButton.icon(
                            onPressed: () {
                              routeTo(EditProfilePage.path);
                              // Reload data after returning
                              Future.delayed(const Duration(milliseconds: 500))
                                  .then((_) {
                                _loadUserData();
                              });
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Edit Profile"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stats Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              value: coursesCount.toString(),
                              label: "Courses",
                              isHighlighted: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              value: hoursLearned.toString(),
                              label: "Hours",
                              isHighlighted: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              value: certificatesAcquired.toString(),
                              label: "Certs",
                              isHighlighted: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Settings Sections
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Video Preferences Section
                          _buildSectionTitle("Video Preferences"),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Colors.grey[100]!, width: 1),
                                bottom: BorderSide(
                                    color: Colors.grey[100]!, width: 1),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Wi-Fi Only Downloads
                                _buildSettingRow(
                                  icon: Icons.wifi,
                                  title: "Wi-Fi Only Downloads",
                                  trailing: _buildToggleSwitch(
                                    value: _wifiOnlyDownloads,
                                    onChanged: (value) {
                                      setState(() {
                                        _wifiOnlyDownloads = value;
                                      });
                                    },
                                  ),
                                ),
                                Divider(height: 1, color: Colors.grey[100]),
                                // Video Quality
                                _buildSettingRow(
                                  icon: Icons.high_quality,
                                  title: "Video Quality",
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Auto (1080p)",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right,
                                          size: 20, color: Colors.grey[300]),
                                    ],
                                  ),
                                  onTap: () {
                                    // TODO: Show video quality options
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Account Settings Section
                          _buildSectionTitle("Account Settings"),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Colors.grey[100]!, width: 1),
                                bottom: BorderSide(
                                    color: Colors.grey[100]!, width: 1),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSettingRow(
                                  icon: Icons.lock_reset,
                                  title: "Change Password",
                                  trailing: Icon(Icons.open_in_new,
                                      size: 20, color: Colors.grey[300]),
                                  onTap: () {
                                    routeTo(ChangePasswordPage.path);
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[100]),
                                _buildSettingRow(
                                  icon: Icons.workspace_premium,
                                  title: "My Certificates",
                                  trailing: Icon(Icons.open_in_new,
                                      size: 20, color: Colors.grey[300]),
                                  onTap: () {
                                    routeTo(CertificatesPage.path);
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[100]),
                                _buildSettingRow(
                                  icon: Icons.notifications_active,
                                  title: "Notification Preferences",
                                  onTap: () {
                                    routeTo(NotificationSettingsPage.path);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Support & Info Section
                          _buildSectionTitle("Support & Info"),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Colors.grey[100]!, width: 1),
                                bottom: BorderSide(
                                    color: Colors.grey[100]!, width: 1),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSettingRow(
                                  icon: Icons.help_center,
                                  title: "Help & Support Center",
                                  trailing: Icon(Icons.open_in_new,
                                      size: 20, color: Colors.grey[300]),
                                  onTap: () {
                                    routeTo(HelpSupportPage.path);
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[100]),
                                _buildSettingRow(
                                  icon: Icons.description,
                                  title: "Terms of Service",
                                  trailing: Icon(Icons.open_in_new,
                                      size: 20, color: Colors.grey[300]),
                                  onTap: () {
                                    routeTo(TermsConditionsPage.path);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Delete Account Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleDeleteAccount,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text("Delete Account"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                    color: Colors.red, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Sign Out Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text("Sign Out"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: BorderSide(color: primary, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Version Info
                          Center(
                            child: Text(
                              "Version 2.4.0 (182)",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[300],
                                letterSpacing: 2.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 100), // Space for bottom nav
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: brandDark,
          letterSpacing: 2.4, // tracking-[0.15em]
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? primary.withValues(alpha: 0.1) : surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? primary.withValues(alpha: 0.2)
              : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isHighlighted ? primary : brandDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isHighlighted
                  ? primary.withValues(alpha: 0.7)
                  : Colors.grey[400],
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: brandDark, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null && onTap != null)
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 20 : 2,
              top: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
