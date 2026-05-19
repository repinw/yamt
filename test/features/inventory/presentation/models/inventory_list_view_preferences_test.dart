import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';

class _MemoryAppPreferences implements AppPreferences {
  final Map<String, String> _strings = <String, String>{};
  final Map<String, int> _ints = <String, int>{};

  @override
  String? getStringSync(String key) => _strings[key];

  @override
  int? getIntSync(String key) => _ints[key];

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<int?> getInt(String key) async => _ints[key];

  @override
  Future<bool> setString(String key, String value) async {
    _strings[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _ints[key] = value;
    return true;
  }
}

void main() {
  const store = InventoryListViewPreferencesStore();

  test('defaults hide consumed foods and prepared meals', () {
    const preferences = InventoryListViewPreferences();

    expect(preferences.consumptionFilter.hideFullyConsumedItems, isTrue);
    expect(
      preferences.preparedMealConsumptionFilter,
      PreparedMealConsumptionFilter.hideConsumed,
    );
  });

  test('readSync falls back to current defaults when no values are stored', () {
    final stored = store.readSync(_MemoryAppPreferences());

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
    final memory = _MemoryAppPreferences();
    const preferences = InventoryListViewPreferences(
      inventoryItemSortMode: InventoryItemSortMode.alphabeticalDescending,
      preparedMealConsumptionFilter: PreparedMealConsumptionFilter.all,
      preparedMealSortMode: PreparedMealSortMode.quantityDescending,
      isRecentItemsSectionExpanded: false,
      isPreparedMealsSectionExpanded: false,
    );

    await store.save(memory, preferences);
    final restored = store.readSync(memory);

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
