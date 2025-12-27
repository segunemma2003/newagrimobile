import '/config/keys.dart';
import '/app/forms/style/form_style.dart';
import '/config/form_casts.dart';
import '/config/decoders.dart';
import '/config/design.dart';
import '/config/theme.dart';
import '/config/validation_rules.dart';
import '/config/localization.dart';
import '/app/providers/language_provider.dart';
import 'package:nylo_framework/nylo_framework.dart';

class AppProvider implements NyProvider {
  @override
  boot(Nylo nylo) async {
    // Initialize language provider
    await LanguageProvider().init();
    
    // Load saved language preference
    String effectiveLanguageCode = LanguageProvider().languageCode;
    
    try {
    await NyLocalization.instance.init(
      localeType: localeType,
      languageCode: effectiveLanguageCode,
      assetsDirectory: assetsDirectory,
    );
    } catch (e) {
      // Handle Keychain/storage errors gracefully
      // Continue with default language if storage access fails
      // Suppress error logging for Keychain issues on simulator
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to initialize localization from storage: $e');
      }
      // The app will continue with the default language code
    }

    FormStyle formStyle = FormStyle();

    nylo.addLoader(loader);
    nylo.addLogo(logo);
    nylo.addThemes(appThemes);
    nylo.addToastNotification(getToastNotificationWidget);
    nylo.addValidationRules(validationRules);
    nylo.addModelDecoders(modelDecoders);
    nylo.addControllers(controllers);
    nylo.addApiDecoders(apiDecoders);
    nylo.addFormCasts(formCasts);
    // Disabled ErrorStack due to Keychain storage issues
    // nylo.useErrorStack();
    nylo.addFormStyle(formStyle);
    nylo.addAuthKey(Keys.auth);
    try {
    await nylo.syncKeys(Keys.syncedOnBoot);
    } catch (e) {
      // Handle Keychain/storage errors gracefully
      // Continue without syncing keys if storage access fails
      // Suppress error logging for Keychain issues on simulator
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to sync keys from storage: $e');
      }
    }

    // Optional
    // nylo.showDateTimeInLogs(); // Show date time in logs
    // nylo.monitorAppUsage(); // Monitor the app usage
    // nylo.broadcastEvents(); // Broadcast events in the app

    return nylo;
  }

  @override
  afterBoot(Nylo nylo) async {}
}
