import 'package:nylo_framework/nylo_framework.dart';

/* Keys
|--------------------------------------------------------------------------
| Storage keys are used to read and write to local storage.
| E.g. static StorageKey coins = "SK_COINS";
| String coins = await Keys.coins.read();
|
| Learn with Agrisiti - Storage Keys
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
  static StorageKey modules = 'SK_MODULES';
  static StorageKey lessons = 'SK_LESSONS';
  static StorageKey categories = 'SK_CATEGORIES';
  static StorageKey courseProgress = 'SK_COURSE_PROGRESS';
  static StorageKey moduleProgress = 'SK_MODULE_PROGRESS';
  static StorageKey lastSyncTime = 'SK_LAST_SYNC_TIME';
  static StorageKey hasSeenIntro = 'SK_HAS_SEEN_INTRO';
  static StorageKey languagePreference = 'SK_LANGUAGE_PREFERENCE';
  static StorageKey notes = 'SK_NOTES';
  static StorageKey assignments = 'SK_ASSIGNMENTS';
  static StorageKey comments = 'SK_COMMENTS';
  static StorageKey reviews = 'SK_REVIEWS';
  static StorageKey messages = 'SK_MESSAGES';
  static StorageKey certificates = 'SK_CERTIFICATES';
  static StorageKey forumPosts = 'SK_FORUM_POSTS';
  static StorageKey forumComments = 'SK_FORUM_COMMENTS';
  static StorageKey chatMessages = 'SK_CHAT_MESSAGES';

  // static StorageKey coins = 'SK_COINS';

  /// Add your storage keys here...
}
