import 'package:flutter/material.dart';
import 'dart:async';
import '/resources/widgets/splash_screen.dart';
import '/bootstrap/app.dart';
import '/config/providers.dart';
import 'package:nylo_framework/nylo_framework.dart';

/* Boot
|--------------------------------------------------------------------------
| The boot class is used to initialize Learn with Agrisiti application.
| Providers are booted in the order they are defined.
|-------------------------------------------------------------------------- */

class Boot {
  /// This method is called to initialize Learn with Agrisiti.
  static Future<Nylo> nylo() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (getEnv('SHOW_SPLASH_SCREEN', defaultValue: false)) {
      runApp(SplashScreen.app());
      // Wait 5 seconds before continuing with app initialization
      await Future.delayed(const Duration(seconds: 5));
    }

    await _setup();
    return await bootApplication(providers);
  }

  /// This method is called after Learn with Agrisiti is initialized.
  static Future<void> finished(Nylo nylo) async {
    await bootFinished(nylo, providers);

    runApp(Main(nylo));
  }
}

/* Setup
|--------------------------------------------------------------------------
| You can use _setup to initialize classes, variables, etc.
| It's run before your app providers are booted.
|-------------------------------------------------------------------------- */

_setup() async {
  /// Example: Initializing StorageConfig
  // StorageConfig.init(
  //   androidOptions: AndroidOptions(
  //     resetOnError: true,
  //     encryptedSharedPreferences: false
  //   )
  // );
}
