import 'package:nylo_framework/nylo_framework.dart';
import 'bootstrap/boot.dart';

void main() async {
  try {
    await Nylo.init(
      setup: Boot.nylo,
      setupFinished: Boot.finished,
      showSplashScreen: true,
    );
  } catch (e) {
    print('Warning: Error during Nylo initialization: $e');
  }
}
