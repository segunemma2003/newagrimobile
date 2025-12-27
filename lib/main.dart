import 'package:nylo_framework/nylo_framework.dart';
import 'bootstrap/boot.dart';

/// Nylo - Framework for Flutter Developers
/// Docs: https://nylo.dev/docs/6.x

/// Main entry point for the application.
void main() async {
  try {
    await Nylo.init(
      setup: Boot.nylo,
      setupFinished: Boot.finished,

      // appLifecycle: {
      //   // Uncomment the code below to enable app lifecycle events
      //   AppLifecycleState.resumed: () {
      //     print("App resumed");
      //   },
      //   AppLifecycleState.paused: () {
      //     print("App paused");
      //   },
      // }

      showSplashScreen: true,
    );
  } catch (e) {
    // Handle initialization errors gracefully
    // ErrorStack.init may fail due to Keychain issues, but app can still function
    print('Warning: Error during Nylo initialization: $e');
    // Note: ErrorStack.init errors are non-critical and won't prevent app from working
  }
}
