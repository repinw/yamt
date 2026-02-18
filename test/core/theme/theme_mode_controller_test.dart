import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';

class _FakeAppPreferences implements AppPreferences {
  _FakeAppPreferences({Map<String, Object>? initialValues})
    : _values = initialValues ?? <String, Object>{};

  final Map<String, Object> _values;

  @override
  String? getStringSync(String key) {
    return _values[key] as String?;
  }

  @override
  int? getIntSync(String key) {
    return _values[key] as int?;
  }

  @override
  Future<String?> getString(String key) async {
    return _values[key] as String?;
  }

  @override
  Future<int?> getInt(String key) async {
    return _values[key] as int?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }
}

void main() {
  test('theme mode defaults to system', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeControllerProvider), ThemeMode.system);
  });

  test('theme mode can be updated and persisted', () async {
    final preferences = _FakeAppPreferences();
    final overrideContainer = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(overrideContainer.dispose);

    await overrideContainer
        .read(themeModeControllerProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(overrideContainer.read(themeModeControllerProvider), ThemeMode.dark);
    expect(
      await preferences.getString('preferred_theme_mode'),
      ThemeMode.dark.name,
    );
  });
}
