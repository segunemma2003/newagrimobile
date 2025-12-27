import 'package:nylo_framework/nylo_framework.dart';

/* Keys
|--------------------------------------------------------------------------
| Storage keys are used to read and write to local storage.
| E.g. static StorageKey coins = "SK_COINS";
| String coins = await Keys.coins.read();
|
| Learn more: https://nylo.dev/docs/6.x/storage#storage-keys
|-------------------------------------------------------------------------- */

class Keys {
  // Define the keys you want to be synced on boot
  static syncedOnBoot() => () async {
        return [
          auth,
          bearerToken,
          // coins.defaultValue(10), // give the user 10 coins by default
        ];
      };

  static StorageKey auth = getEnv('SK_USER', defaultValue: 'SK_USER');

  static StorageKey bearerToken = 'SK_BEARER_TOKEN';

  static StorageKey courses = 'SK_COURSES';
  static StorageKey categories = 'SK_CATEGORIES';
  static StorageKey courseProgress = 'SK_COURSE_PROGRESS';
  static StorageKey moduleProgress = 'SK_MODULE_PROGRESS';
  static StorageKey lastSyncTime = 'SK_LAST_SYNC_TIME';
  static StorageKey hasSeenIntro = 'SK_HAS_SEEN_INTRO';
  static StorageKey languagePreference = 'SK_LANGUAGE_PREFERENCE';

  // static StorageKey coins = 'SK_COINS';

  /// Add your storage keys here...
}
