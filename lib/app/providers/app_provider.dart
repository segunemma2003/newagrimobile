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
    await LanguageProvider().init();
    String effectiveLanguageCode = LanguageProvider().languageCode;
    
    try {
      await NyLocalization.instance.init(
        localeType: localeType,
        languageCode: effectiveLanguageCode,
        assetsDirectory: assetsDirectory,
      );
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to initialize localization from storage: $e');
      }
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
    nylo.addFormStyle(formStyle);
    nylo.addAuthKey(Keys.auth);
    try {
      await nylo.syncKeys(Keys.syncedOnBoot);
    } catch (e) {
      if (!e.toString().contains('-34018')) {
        print('Warning: Failed to sync keys from storage: $e');
      }
    }

    return nylo;
  }

  @override
  afterBoot(Nylo nylo) async {}
}
