import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test('load returns null for invalid json string', () async {
    final store = AppPreferencesCookingFlowSessionLocalStore(
      preferences: MemoryAppPreferences(
        initialStrings: <String, String>{
          cookingFlowSessionPreferenceKey: '{ invalid_json }',
        },
      ),
    );

    final session = await store.load();

    expect(session, isNull);
  });

  test('load returns null for json array', () async {
    final store = AppPreferencesCookingFlowSessionLocalStore(
      preferences: MemoryAppPreferences(
        initialStrings: <String, String>{
          cookingFlowSessionPreferenceKey: '[]',
        },
      ),
    );

    final session = await store.load();

    expect(session, isNull);
  });

  test('load returns null for malformed session map', () async {
    final store = AppPreferencesCookingFlowSessionLocalStore(
      preferences: MemoryAppPreferences(
        initialStrings: <String, String>{
          cookingFlowSessionPreferenceKey: '{"step":"unknown"}',
        },
      ),
    );

    final session = await store.load();

    expect(session, isNull);
  });
}
