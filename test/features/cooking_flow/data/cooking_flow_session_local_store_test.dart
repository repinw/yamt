import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test('store saves, loads, and clears a session snapshot', () async {
    final preferences = MemoryAppPreferences();
    final store = AppPreferencesCookingFlowSessionLocalStore(
      preferences: preferences,
    );
    final session = _session();

    final saved = await store.save(session);
    final loaded = await store.load();
    final cleared = await store.clear();
    final afterClear = await store.load();

    expect(saved, isTrue);
    expect(loaded?.templateId, 'template-1');
    expect(loaded?.summaryIngredients.single.name, 'Rice');
    expect(cleared, isTrue);
    expect(afterClear, isNull);
  });

  test('coordinator refreshes snapshot after save and clear', () async {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ],
    );
    addTearDown(container.dispose);
    final coordinator = container.read(cookingFlowSessionCoordinatorProvider);

    final firstSnapshot = await container.read(
      cookingFlowSessionSnapshotProvider.future,
    );
    final saved = await coordinator.save(_session());
    final savedSnapshot = await container.read(
      cookingFlowSessionSnapshotProvider.future,
    );
    final cleared = await coordinator.clear();
    final clearedSnapshot = await container.read(
      cookingFlowSessionSnapshotProvider.future,
    );

    expect(firstSnapshot, isNull);
    expect(saved, isTrue);
    expect(savedSnapshot?.templateId, 'template-1');
    expect(cleared, isTrue);
    expect(clearedSnapshot, isNull);
  });

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

CookingFlowSession _session() {
  return const CookingFlowSession(
    templateId: 'template-1',
    step: CookingFlowSessionStep.summary,
    taraText: '100',
    adjustmentInputText: 'extra salt',
    adjustments: <String>['extra salt'],
    summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[
      CookingFlowSummaryIngredientSessionDraft(
        key: 'row-rice',
        name: 'Rice',
        amount: '200',
        unitCode: 'g',
        inventoryItemIds: <String>['rice'],
        kind: CookingFlowSummaryIngredientKind.template,
        sourceIngredient: '200g Rice',
      ),
    ],
    grossWeightText: '800',
    splitIntoPortions: true,
    portionCount: 4,
    finalPortionCount: 4,
    introDraft: CookingFlowIntroDraft(),
    introShoppingHandled: false,
    introShoppingBaselineInventoryItemIds: <String>[],
    storageContainers: <CookingFlowStorageContainerSessionDraft>[
      CookingFlowStorageContainerSessionDraft(
        id: 'container-1',
        label: 'Container 1',
        taraText: '100',
        grossWeightText: '800',
        portionCount: 4,
      ),
    ],
    ingredientContainerAssignments: <String, String>{
      'row-rice': 'container-1',
    },
  );
}
