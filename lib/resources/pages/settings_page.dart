import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:nylo_framework/theme/helper/ny_theme.dart';
import '/config/keys.dart';
import '/resources/pages/profile_page.dart';
import '/resources/pages/contact_admin_page.dart';
import '/resources/pages/help_support_page.dart';
import '/resources/pages/terms_conditions_page.dart';
import '/resources/pages/notification_settings_page.dart';
import '/app/providers/language_provider.dart';
import '/app/helpers/language_helper.dart';

class SettingsPage extends NyStatefulWidget {
  static RouteView path = ("/settings", (_) => SettingsPage());

  SettingsPage({super.key}) : super(child: () => _SettingsPageState());
}

class _SettingsPageState extends NyPage<SettingsPage> {
  Map<String, dynamic>? _userData;
  bool _isDarkMode = false;
  final _languageProvider = LanguageProvider();

  @override
  void initState() {
    super.initState();
    _languageProvider.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  get init => () async {
        await _loadUserData();
        _loadThemeState();
      };

  void _loadThemeState() {
    _isDarkMode = context.isThemeDark;
    setState(() {});
  }

  Future<void> _loadUserData() async {
    try {
      _userData = await Keys.auth.read<Map<String, dynamic>>();
      if (_userData == null) {
        _userData = backpackRead(Keys.auth);
      }
      setState(() {});
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to load user data: $e');
      }
      _userData = backpackRead(Keys.auth);
      setState(() {});
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageHelper.logout),
        content: Text(_languageProvider.isEnglish 
            ? "Are you sure you want to logout?"
            : "Ka tabbata kana son fita?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LanguageHelper.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Keys.auth.save(null);
                await Keys.bearerToken.save(null);
              } catch (e) {
                if (!e.toString().contains('-34018')) {
                  print('Warning: Failed to clear auth data: $e');
                }
              }
              backpackDelete(Keys.auth);
              backpackDelete(Keys.bearerToken);
              routeTo("/login");
            },
            child: Text(
              LanguageHelper.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          LanguageHelper.settings,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Profile Section
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF2D8659),
                      child: Text(
                        (_userData?['name']?.toString() ?? "U")[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      _userData?['name']?.toString() ?? "User",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    subtitle: Text(
                      _userData?['email']?.toString() ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF999999),
                    ),
                    onTap: () => routeTo(ProfilePage.path),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Account Settings
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      LanguageHelper.account,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.person_outline,
                    title: LanguageHelper.editProfile,
                    onTap: () => routeTo(ProfilePage.path),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.lock_outline,
                    title: LanguageHelper.changePassword,
                    onTap: () => routeTo("/change-password"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Preferences
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      LanguageHelper.preferences,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.notifications_outlined,
                    title: LanguageHelper.notificationSettings,
                    onTap: () => routeTo(NotificationSettingsPage.path),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.dark_mode_outlined,
                    title: LanguageHelper.darkMode,
                    trailing: Switch(
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                        NyTheme.set(
                          context,
                          id: getEnv(_isDarkMode ? 'DARK_THEME_ID' : 'LIGHT_THEME_ID'),
                        );
                      },
                      activeColor: const Color(0xFF2D8659),
                    ),
                    onTap: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                      });
                      NyTheme.set(
                        context,
                        id: getEnv(_isDarkMode ? 'DARK_THEME_ID' : 'LIGHT_THEME_ID'),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.language_outlined,
                    title: LanguageHelper.language,
                    subtitle: _languageProvider.isEnglish ? "English" : "Hausa",
                    onTap: () => routeTo("/language-settings"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Support
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      LanguageHelper.support,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.help_outline,
                    title: LanguageHelper.helpSupport,
                    onTap: () => routeTo(HelpSupportPage.path),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.message_outlined,
                    title: LanguageHelper.contactAdmin,
                    onTap: () => routeTo(ContactAdminPage.path),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.description_outlined,
                    title: LanguageHelper.termsConditions,
                    onTap: () => routeTo(TermsConditionsPage.path),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.info_outline,
                    title: LanguageHelper.about,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: "Agrisiti Academy",
                        applicationVersion: "1.0.0",
                        applicationIcon: const Icon(
                          Icons.school,
                          color: Color(0xFF2D8659),
                          size: 48,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Logout
            Container(
              color: Colors.white,
            child: _buildMenuTile(
              icon: Icons.logout,
              title: LanguageHelper.logout,
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: _logout,
            ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF2D8659)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF1A1A1A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: Color(0xFF999999)),
      onTap: onTap,
    );
  }
}

