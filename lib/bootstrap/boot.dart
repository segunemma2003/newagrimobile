import 'package:flutter/material.dart';
import 'dart:async';
import '/resources/widgets/splash_screen.dart';
import '/bootstrap/app.dart';
import '/config/providers.dart';
import '/app/services/data_sync_service.dart';
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
      // Wait 2 seconds before continuing with app initialization (reduced from 5 to save memory)
      await Future.delayed(const Duration(seconds: 2));
    }

    print('Boot nylo: _setup');
    await _setup();
    print('Boot nylo: bootApplication');
    try {
      final nylo = await bootApplication(providers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Boot nylo: bootApplication timed out');
          throw TimeoutException('bootApplication timed out');
        },
      );
      print('Boot nylo: bootApplication (after)');
      return nylo;
    } catch (e, st) {
      print('Boot nylo ERROR in bootApplication: $e');
      print(st);
      rethrow;
    }
  }

  /// This method is called after Learn with Agrisiti is initialized.
  static Future<void> finished(Nylo nylo) async {
    try {
      await bootFinished(nylo, providers);
      print('Boot nylo: finished');

      // Initialize offline sync service (non-blocking)
      DataSyncService().initializeSync().catchError((e) {
        print('Error initializing sync service: $e');
      });

      runApp(Main(nylo));
    } catch (e, stackTrace) {
      print('FATAL ERROR in Boot.finished: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

/* Setup
|--------------------------------------------------------------------------
| You can use _setup to initialize classes, variables, etc.
| It's run before your app providers are booted.
|-------------------------------------------------------------------------- */

_setup() async {
  // Initialize secure storage / keychain behavior for Nylo.
  StorageConfig.init(
    androidOptions: const AndroidOptions(
      resetOnError: true,
      encryptedSharedPreferences: false,
    ),
    iosOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
}
