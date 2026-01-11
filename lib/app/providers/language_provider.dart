import 'package:flutter/material.dart';
import '/config/keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

class LanguageProvider extends ChangeNotifier {
  static final LanguageProvider _instance = LanguageProvider._internal();
  factory LanguageProvider() => _instance;
  LanguageProvider._internal();

  Locale _locale = const Locale('en', 'US');
  String _languageCode = 'en';

  Locale get locale => _locale;
  String get languageCode => _languageCode;

  bool get isEnglish => _languageCode == 'en';
  bool get isHausa => _languageCode == 'ha';

  Future<void> init() async {
    try {
      final savedLang = await Keys.languagePreference.read<String>();
      if (savedLang != null) {
        _languageCode = savedLang;
        _locale = Locale(savedLang, savedLang == 'en' ? 'US' : 'NG');
      }
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to load language preference: $e');
      }
      final backpackLang = backpackRead(Keys.languagePreference);
      if (backpackLang != null) {
        _languageCode = backpackLang.toString();
        _locale = Locale(_languageCode, _languageCode == 'en' ? 'US' : 'NG');
      }
    }
    notifyListeners();
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    _languageCode = languageCode;
    _locale = Locale(languageCode, languageCode == 'en' ? 'US' : 'NG');

    try {
      await Keys.languagePreference.save(languageCode);
      backpackSave(Keys.languagePreference, languageCode);
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to save language preference: $e');
      }
      backpackSave(Keys.languagePreference, languageCode);
    }
    notifyListeners();
  }
}

