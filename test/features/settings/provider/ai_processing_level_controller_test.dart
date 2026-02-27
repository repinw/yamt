import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/settings/provider/ai_processing_level_controller.dart';

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
  test('AI processing level defaults to balanced', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(aiProcessingLevelControllerProvider),
      AiProcessingLevel.balanced,
    );
  });

  test('AI processing level restores minimal from persisted value', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          _FakeAppPreferences(
            initialValues: <String, Object>{
              'preferred_ai_processing_level': 'minimal',
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(aiProcessingLevelControllerProvider),
      AiProcessingLevel.minimal,
    );
  });

  test('AI processing level can be updated and persisted', () async {
    final preferences = _FakeAppPreferences();
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await container
        .read(aiProcessingLevelControllerProvider.notifier)
        .setLevel(AiProcessingLevel.high);

    expect(
      container.read(aiProcessingLevelControllerProvider),
      AiProcessingLevel.high,
    );
    expect(
      await preferences.getString('preferred_ai_processing_level'),
      'high',
    );
  });
}
