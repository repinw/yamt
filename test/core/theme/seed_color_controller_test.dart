import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';

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
  test('seed color defaults to app seed', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFF29F006);
  });

  test('seed color can be updated and persisted', () async {
    final preferences = _FakeAppPreferences();
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await container
        .read(seedColorControllerProvider.notifier)
        .setSeedColor(const Color(0xFF0D47A1));

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFF0D47A1);
    expect(await preferences.getInt('preferred_seed_color'), 0xFF0D47A1);
  });
}
