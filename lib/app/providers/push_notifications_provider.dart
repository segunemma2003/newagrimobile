import 'package:nylo_framework/nylo_framework.dart';

class PushNotificationsProvider implements NyProvider {
  @override
  boot(Nylo nylo) async {
    nylo.useLocalNotifications();
    print('PushNotificationsProvider boot');
    return nylo;
  }

  @override
  afterBoot(Nylo nylo) async {
    // Called after booting your provider
    // ...
  }
}
