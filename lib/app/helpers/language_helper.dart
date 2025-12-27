import '/app/providers/language_provider.dart';

/// Helper class to get localized strings based on current language
class LanguageHelper {
  static final _provider = LanguageProvider();

  // Navigation
  static String get home => _provider.isEnglish ? 'Home' : 'Gida';
  static String get courses => _provider.isEnglish ? 'Courses' : 'Darussa';
  static String get notifications => _provider.isEnglish ? 'Notifications' : 'Sanarwa';
  static String get settings => _provider.isEnglish ? 'Settings' : 'Saituna';

  // Settings
  static String get account => _provider.isEnglish ? 'Account' : 'Asusu';
  static String get editProfile => _provider.isEnglish ? 'Edit Profile' : 'Gyara Bayanan';
  static String get changePassword => _provider.isEnglish ? 'Change Password' : 'Canza Kalmar Sirri';
  static String get preferences => _provider.isEnglish ? 'Preferences' : 'Zaɓin Zaɓuka';
  static String get notificationSettings => _provider.isEnglish ? 'Notification Settings' : 'Saitunan Sanarwa';
  static String get darkMode => _provider.isEnglish ? 'Dark Mode' : 'Yanayin Duhu';
  static String get language => _provider.isEnglish ? 'Language' : 'Harshe';
  static String get support => _provider.isEnglish ? 'Support' : 'Tallafi';
  static String get helpSupport => _provider.isEnglish ? 'Help & Support' : 'Taimako & Tallafi';
  static String get contactAdmin => _provider.isEnglish ? 'Contact Admin' : 'Tuntuɓi Admin';
  static String get termsConditions => _provider.isEnglish ? 'Terms & Conditions' : 'Sharuddan Amfani';
  static String get about => _provider.isEnglish ? 'About' : 'Game da';
  static String get logout => _provider.isEnglish ? 'Logout' : 'Fita';
  static String get cancel => _provider.isEnglish ? 'Cancel' : 'Soke';

  // Notification Settings
  static String get notificationPreferences => _provider.isEnglish ? 'Notification Preferences' : 'Abubuwan Sanarwa';
  static String get pushNotifications => _provider.isEnglish ? 'Push Notifications' : 'Sanarwar Push';
  static String get pushNotificationsDesc => _provider.isEnglish ? 'Receive notifications on your device' : 'Karɓi sanarwa akan na\'urarka';
  static String get emailNotifications => _provider.isEnglish ? 'Email Notifications' : 'Sanarwar Imel';
  static String get emailNotificationsDesc => _provider.isEnglish ? 'Receive notifications via email' : 'Karɓi sanarwa ta imel';
  static String get notificationTypes => _provider.isEnglish ? 'Notification Types' : 'Nau\'ukan Sanarwa';
  static String get courseUpdates => _provider.isEnglish ? 'Course Updates' : 'Sabunta Darussa';
  static String get courseUpdatesDesc => _provider.isEnglish ? 'Notifications about new courses and updates' : 'Sanarwa game da sababbin darussa da sabuntawa';
  static String get quizReminders => _provider.isEnglish ? 'Quiz Reminders' : 'Tunatarwar Jarabawa';
  static String get quizRemindersDesc => _provider.isEnglish ? 'Reminders about upcoming quizzes' : 'Tunatarwa game da jarabawar da za su zo';
  static String get achievements => _provider.isEnglish ? 'Achievements' : 'Nasara';
  static String get achievementsDesc => _provider.isEnglish ? 'Notifications about achievements you\'ve earned' : 'Sanarwa game da nasarorin da kuka samu';
  static String get systemNotifications => _provider.isEnglish ? 'System Notifications' : 'Sanarwar Tsarin';
  static String get systemNotificationsDesc => _provider.isEnglish ? 'Notifications from the system' : 'Sanarwa daga tsarin';

  // Common
  static String get save => _provider.isEnglish ? 'Save' : 'Adana';
  static String get update => _provider.isEnglish ? 'Update' : 'Sabunta';
}

