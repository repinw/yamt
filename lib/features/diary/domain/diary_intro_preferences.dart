import 'package:yamt/core/preferences/app_preferences.dart';

/// Preference helpers for the first diary intro.
abstract final class DiaryIntroPreferences {
  static const _key = 'diary_intro_seen_v1';
  static const _seenValue = 'seen';

  /// Whether the user has already completed the first diary intro.
  static bool isSeen(AppPreferences preferences) {
    return preferences.getStringSync(_key) == _seenValue;
  }

  /// Persist that the user completed the first diary intro.
  static Future<bool> markSeen(AppPreferences preferences) {
    return preferences.setString(_key, _seenValue);
  }

  /// Initial string values for tests or migrations.
  static Map<String, String> initialSeenStrings() {
    return const <String, String>{_key: _seenValue};
  }
}
