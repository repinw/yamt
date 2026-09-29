import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'home_action_usage_repository.g.dart';

const _preferenceKey = 'home_action_usage_counts';

/// Stores how often each action of the home action panel was tapped, in the
/// app preferences of this device.
class HomeActionUsageRepository {
  /// Creates the repository on the given app preferences.
  const new(this._preferences);

  final AppPreferences _preferences;

  /// The stored tap counts by action id, from the loaded preferences.
  Map<String, int> cachedCounts() {
    final stored = _preferences.getStringSync(_preferenceKey);
    if (stored == null) {
      return const <String, int>{};
    }
    return Map.unmodifiable(
      (jsonDecode(stored) as Map<String, dynamic>).cast<String, int>(),
    );
  }

  /// Saves [counts]. Throws a [StateError] when the preferences refuse the
  /// write.
  Future<void> saveCounts(Map<String, int> counts) async {
    final saved = await _preferences.setString(
      _preferenceKey,
      jsonEncode(counts),
    );
    if (!saved) {
      throw StateError('Could not save the home action usage counts.');
    }
  }
}

/// Provides the home action usage repository.
@riverpod
HomeActionUsageRepository homeActionUsageRepository(Ref ref) {
  return HomeActionUsageRepository(ref.watch(appPreferencesProvider));
}
