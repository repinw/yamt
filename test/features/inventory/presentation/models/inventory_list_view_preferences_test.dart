import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';

import '../../../../helpers/memory_app_preferences.dart';

void main() {
  const store = InventoryListViewPreferencesStore();

  test('defaults hide consumed foods and prepared meals', () {
    const preferences = InventoryListViewPreferences();

    expect(preferences.viewMode, InventoryListViewMode.list);
    expect(preferences.consumptionFilter.hideFullyConsumedItems, isTrue);
    expect(
      preferences.preparedMealConsumptionFilter,
      PreparedMealConsumptionFilter.hideConsumed,
    );
  });

  test('readSync falls back to current defaults when no values are stored', () {
    final stored = store.readSync(MemoryAppPreferences());

    expect(stored.viewMode, InventoryListViewMode.list);
    expect(stored.consumptionFilter.hideFullyConsumedItems, isTrue);
    expect(
      stored.preparedMealConsumptionFilter,
      PreparedMealConsumptionFilter.hideConsumed,
    );
    expect(
      stored.inventoryItemSortMode,
      InventoryItemSortMode.recentlyAddedDescending,
    );
    expect(stored.preparedMealSortMode, PreparedMealSortMode.addedDescending);
  });

  test('save and readSync round-trip changed values', () async {
    final memory = MemoryAppPreferences();
    const preferences = InventoryListViewPreferences(
      viewMode: InventoryListViewMode.tiles,
      inventoryItemSortMode: InventoryItemSortMode.alphabeticalDescending,
      preparedMealConsumptionFilter: PreparedMealConsumptionFilter.all,
      preparedMealSortMode: PreparedMealSortMode.quantityDescending,
      isRecentItemsSectionExpanded: false,
      isPreparedMealsSectionExpanded: false,
    );

    await store.save(memory, preferences);
    final restored = store.readSync(memory);

    expect(
      restored.viewMode,
      InventoryListViewMode.tiles,
    );
    expect(
      restored.inventoryItemSortMode,
      InventoryItemSortMode.alphabeticalDescending,
    );
    expect(
      restored.preparedMealConsumptionFilter,
      PreparedMealConsumptionFilter.all,
    );
    expect(
      restored.preparedMealSortMode,
      PreparedMealSortMode.quantityDescending,
    );
    expect(restored.isRecentItemsSectionExpanded, isFalse);
    expect(restored.isPreparedMealsSectionExpanded, isFalse);
  });
}
