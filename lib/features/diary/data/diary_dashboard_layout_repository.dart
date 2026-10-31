import 'dart:convert';

import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';

part 'diary_dashboard_layout_repository.g.dart';

const _keyPrefix = 'diary_dashboard_layout_v1';

/// Stores the diary dashboard layout of one user in the app preferences of
/// this device.
class DiaryDashboardLayoutRepository {
  /// Creates the repository for the user with the given uid, or for no user.
  const new(this._preferences, this._uid);

  final AppPreferences _preferences;
  final String? _uid;

  String get _key {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No signed-in user for the diary dashboard layout.');
    }
    return '$_keyPrefix:$uid';
  }

  /// The saved layout from the loaded preferences, or null when the user
  /// never changed it or nobody is signed in. Throws a [FormatException]
  /// when the stored value is no layout object, and a
  /// `CheckedFromJsonException` when a field has the wrong shape.
  DiaryDashboardLayout? cachedLayout() {
    if (_uid == null) return null;
    final stored = _preferences.getStringSync(_key);
    if (stored == null) return null;
    final json = jsonDecode(stored);
    if (json is! Map<String, dynamic>) {
      throw FormatException('Stored dashboard layout is no object.', stored);
    }
    return DiaryDashboardLayout.fromJson(json);
  }

  /// Saves [layout]. Throws a [StateError] when nobody is signed in or the
  /// preferences refuse the write.
  Future<void> saveLayout(DiaryDashboardLayout layout) async {
    final saved = await _preferences.setString(
      _key,
      jsonEncode(layout.toJson()),
    );
    if (!saved) {
      throw StateError('Could not save the diary dashboard layout.');
    }
  }

  /// Deletes the saved layout, so the default layout shows again. Throws a
  /// [StateError] when nobody is signed in or the preferences refuse it.
  Future<void> deleteLayout() async {
    if (!await _preferences.remove(_key)) {
      throw StateError('Could not delete the diary dashboard layout.');
    }
  }
}

/// Provides the dashboard layout repository of the signed-in user.
@riverpod
DiaryDashboardLayoutRepository diaryDashboardLayoutRepository(Ref ref) {
  return DiaryDashboardLayoutRepository(
    ref.watch(appPreferencesProvider),
    ref.watch(
      authStateChangesProvider.select((user) => user.asData?.value?.uid),
    ),
  );
}
