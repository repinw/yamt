import 'package:yamt/core/preferences/app_preferences.dart';

/// Preference helpers for the first diary intro.
abstract final class DiaryIntroPreferences {
  static const _key = 'diary_intro_seen_v1';
  static const _seenValue = 'seen';
  static const _bannerDismissedKey = 'diary_intro_banner_dismissed_v1';
  static const _dismissedValue = 'dismissed';

  /// Whether the user has already completed the first diary intro.
  static bool isSeen(AppPreferences preferences) {
    return preferences.getStringSync(_key) == _seenValue;
  }

  /// Persist that the user completed the first diary intro.
  static Future<bool> markSeen(AppPreferences preferences) {
    return preferences.setString(_key, _seenValue);
  }

  /// Whether the user dismissed the week 1 intro banner.
  static bool isBannerDismissed(AppPreferences preferences) {
    return preferences.getStringSync(_bannerDismissedKey) == _dismissedValue;
  }

  /// Persist that the user dismissed the week 1 intro banner.
  static Future<bool> markBannerDismissed(AppPreferences preferences) {
    return preferences.setString(_bannerDismissedKey, _dismissedValue);
  }

  /// Initial string values for tests or migrations.
  static Map<String, String> initialSeenStrings({
    bool bannerDismissed = false,
  }) {
    return <String, String>{
      _key: _seenValue,
      if (bannerDismissed) _bannerDismissedKey: _dismissedValue,
    };
  }
}
