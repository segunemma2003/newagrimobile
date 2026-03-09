import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/providers/language_provider.dart';
import '/app/helpers/language_helper.dart';

class NotificationSettingsPage extends NyStatefulWidget {
  static RouteView path = ("/notification-settings", (_) => NotificationSettingsPage());

  NotificationSettingsPage({super.key}) : super(child: () => _NotificationSettingsPageState());
}

class _NotificationSettingsPageState extends NyPage<NotificationSettingsPage> {
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _courseUpdatesEnabled = true;
  bool _quizRemindersEnabled = true;
  bool _achievementNotificationsEnabled = true;
  bool _systemNotificationsEnabled = true;
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
        title: Text(
          LanguageHelper.notificationSettings,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Notification Preferences
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      LanguageHelper.notificationPreferences,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: LanguageHelper.pushNotifications,
                    subtitle: LanguageHelper.pushNotificationsDesc,
                    value: _pushNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: LanguageHelper.emailNotifications,
                    subtitle: LanguageHelper.emailNotificationsDesc,
                    value: _emailNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _emailNotificationsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Notification Types
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      LanguageHelper.notificationTypes,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: LanguageHelper.courseUpdates,
                    subtitle: LanguageHelper.courseUpdatesDesc,
                    value: _courseUpdatesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _courseUpdatesEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: LanguageHelper.quizReminders,
                    subtitle: LanguageHelper.quizRemindersDesc,
                    value: _quizRemindersEnabled,
                    onChanged: (value) {
                      setState(() {
                        _quizRemindersEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: LanguageHelper.achievements,
                    subtitle: LanguageHelper.achievementsDesc,
                    value: _achievementNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _achievementNotificationsEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: LanguageHelper.systemNotifications,
                    subtitle: LanguageHelper.systemNotificationsDesc,
                    value: _systemNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _systemNotificationsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF666666),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF2D8659),
    );
  }
}

