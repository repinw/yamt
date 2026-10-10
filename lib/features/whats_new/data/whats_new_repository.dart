import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/app_version.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/whats_new/domain/whats_new_release.dart';

part 'whats_new_repository.g.dart';

const _lastSeenKey = 'whats_new_last_seen_version_v1';

/// Reads the release notes bundled with the app and remembers on this device
/// which version's notes were seen.
class WhatsNewRepository {
  /// Creates the repository on the asset [_bundle] and device [_preferences].
  const new(this._bundle, this._preferences);

  final AssetBundle _bundle;
  final AppPreferences _preferences;

  /// The notes of [version], or null when the app has none for it. Throws
  /// when the file is there but malformed.
  Future<WhatsNewRelease?> readRelease(AppVersion version) async {
    final path = 'assets/whats_new/$version.json';
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    if (!manifest.listAssets().contains(path)) {
      return null;
    }
    final text = await _bundle.loadString(path);
    return WhatsNewRelease.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// The last version whose notes this device saw, or null.
  Future<AppVersion?> readLastSeen() async {
    final stored = await _preferences.getString(_lastSeenKey);
    return stored == null ? null : AppVersion.parse(stored);
  }

  /// Remembers that this device saw the notes of [version]. Throws when the
  /// device does not save it.
  Future<void> saveLastSeen(AppVersion version) async {
    final saved = await _preferences.setString(_lastSeenKey, '$version');
    if (!saved) {
      throw StateError('The device did not save the seen version.');
    }
  }

  /// Whether the app was used on this device before: some account finished
  /// the onboarding here.
  Future<bool> usedBefore() async {
    final keys = await _preferences.keys();
    return keys.any(isCalorieGoalOnboardingKey);
  }
}

/// Provides the [WhatsNewRepository].
@riverpod
WhatsNewRepository whatsNewRepository(Ref ref) {
  return WhatsNewRepository(rootBundle, ref.watch(appPreferencesProvider));
}
