import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/config/keys.dart';
import '/app/providers/language_provider.dart';

class LanguageSettingsPage extends NyStatefulWidget {
  static RouteView path = ("/language-settings", (_) => LanguageSettingsPage());

  LanguageSettingsPage({super.key}) : super(child: () => _LanguageSettingsPageState());
}

class _LanguageSettingsPageState extends NyPage<LanguageSettingsPage> {
  final _languageProvider = LanguageProvider();
  String _selectedLanguage = 'en';

  @override
  get init => () async {
        _selectedLanguage = _languageProvider.languageCode;
        setState(() {});
      };

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });

    await _languageProvider.changeLanguage(languageCode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'en' 
                ? "Language changed to English"
                : "An canza harshe zuwa Hausa",
          ),
          backgroundColor: const Color(0xFF2D8659),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate back after a short delay to see the change
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
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
          _languageProvider.isEnglish ? "Language Settings" : "Saitunan Harshe",
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
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildLanguageOption(
                    languageCode: 'en',
                    languageName: 'English',
                    flag: '🇬🇧',
                    isSelected: _selectedLanguage == 'en',
                  ),
                  const Divider(height: 1),
                  _buildLanguageOption(
                    languageCode: 'ha',
                    languageName: 'Hausa',
                    flag: '🇳🇬',
                    isSelected: _selectedLanguage == 'ha',
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

  Widget _buildLanguageOption({
    required String languageCode,
    required String languageName,
    required String flag,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 32),
      ),
      title: Text(
        languageName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF2D8659))
          : const Icon(Icons.radio_button_unchecked, color: Color(0xFF999999)),
      onTap: () => _changeLanguage(languageCode),
    );
  }
}

