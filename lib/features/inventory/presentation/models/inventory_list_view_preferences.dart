import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_consumption_filter.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';

enum PreparedMealSortMode {
  addedDescending,
  addedAscending,
  eatenDescending,
  eatenAscending,
  alphabeticalAscending,
  alphabeticalDescending,
  quantityAscending,
  quantityDescending,
}

enum PreparedMealCompletionFilter { all, readyOnly, incompleteOnly }

enum PreparedMealConsumptionFilter { all, hideConsumed, depletedOnly }

class InventoryListViewPreferences {
  const InventoryListViewPreferences({
    this.consumptionFilter = const InventoryConsumptionFilter(),
    this.inventoryItemSortMode = InventoryItemSortMode.recentlyAddedDescending,
    this.preparedMealCompletionFilter = PreparedMealCompletionFilter.all,
    this.preparedMealConsumptionFilter = PreparedMealConsumptionFilter.all,
    this.preparedMealSortMode = PreparedMealSortMode.addedDescending,
    this.isRecentItemsSectionExpanded = true,
    this.isPreparedMealsSectionExpanded = true,
  });

  final InventoryConsumptionFilter consumptionFilter;
  final InventoryItemSortMode inventoryItemSortMode;
  final PreparedMealCompletionFilter preparedMealCompletionFilter;
  final PreparedMealConsumptionFilter preparedMealConsumptionFilter;
  final PreparedMealSortMode preparedMealSortMode;
  final bool isRecentItemsSectionExpanded;
  final bool isPreparedMealsSectionExpanded;

  InventoryListViewPreferences copyWith({
    InventoryConsumptionFilter? consumptionFilter,
    InventoryItemSortMode? inventoryItemSortMode,
    PreparedMealCompletionFilter? preparedMealCompletionFilter,
    PreparedMealConsumptionFilter? preparedMealConsumptionFilter,
    PreparedMealSortMode? preparedMealSortMode,
    bool? isRecentItemsSectionExpanded,
    bool? isPreparedMealsSectionExpanded,
  }) {
    return InventoryListViewPreferences(
      consumptionFilter: consumptionFilter ?? this.consumptionFilter,
      inventoryItemSortMode:
          inventoryItemSortMode ?? this.inventoryItemSortMode,
      preparedMealCompletionFilter:
          preparedMealCompletionFilter ?? this.preparedMealCompletionFilter,
      preparedMealConsumptionFilter:
          preparedMealConsumptionFilter ?? this.preparedMealConsumptionFilter,
      preparedMealSortMode: preparedMealSortMode ?? this.preparedMealSortMode,
      isRecentItemsSectionExpanded:
          isRecentItemsSectionExpanded ?? this.isRecentItemsSectionExpanded,
      isPreparedMealsSectionExpanded:
          isPreparedMealsSectionExpanded ?? this.isPreparedMealsSectionExpanded,
    );
  }
}

class InventoryListViewPreferencesStore {
  const InventoryListViewPreferencesStore();

  static const _inventoryHideConsumedItemsKey =
      'inventory_list_hide_consumed_items';
  static const _inventoryItemSortModeKey = 'inventory_list_item_sort_mode';
  static const _preparedMealCompletionFilterKey =
      'inventory_list_prepared_meal_completion_filter';
  static const _preparedMealConsumptionFilterKey =
      'inventory_list_prepared_meal_consumption_filter';
  static const _preparedMealSortModeKey =
      'inventory_list_prepared_meal_sort_mode';
  static const _recentItemsExpandedKey = 'inventory_list_recent_items_expanded';
  static const _preparedMealsExpandedKey =
      'inventory_list_prepared_meals_expanded';

  InventoryListViewPreferences readSync(AppPreferences preferences) {
    const defaultPreferences = InventoryListViewPreferences();

    return InventoryListViewPreferences(
      consumptionFilter: InventoryConsumptionFilter(
        hideFullyConsumedItems: _readBool(
          preferences,
          _inventoryHideConsumedItemsKey,
          defaultPreferences.consumptionFilter.hideFullyConsumedItems,
        ),
      ),
      inventoryItemSortMode: _enumFromName(
        InventoryItemSortMode.values,
        preferences.getStringSync(_inventoryItemSortModeKey),
        defaultPreferences.inventoryItemSortMode,
      ),
      preparedMealCompletionFilter: _enumFromName(
        PreparedMealCompletionFilter.values,
        preferences.getStringSync(_preparedMealCompletionFilterKey),
        defaultPreferences.preparedMealCompletionFilter,
      ),
      preparedMealConsumptionFilter: _enumFromName(
        PreparedMealConsumptionFilter.values,
        preferences.getStringSync(_preparedMealConsumptionFilterKey),
        defaultPreferences.preparedMealConsumptionFilter,
      ),
      preparedMealSortMode: _enumFromName(
        PreparedMealSortMode.values,
        preferences.getStringSync(_preparedMealSortModeKey),
        defaultPreferences.preparedMealSortMode,
      ),
      isRecentItemsSectionExpanded: _readBool(
        preferences,
        _recentItemsExpandedKey,
        defaultPreferences.isRecentItemsSectionExpanded,
      ),
      isPreparedMealsSectionExpanded: _readBool(
        preferences,
        _preparedMealsExpandedKey,
        defaultPreferences.isPreparedMealsSectionExpanded,
      ),
    );
  }

  Future<void> save(
    AppPreferences preferences,
    InventoryListViewPreferences value,
  ) async {
    await preferences.setInt(
      _inventoryHideConsumedItemsKey,
      value.consumptionFilter.hideFullyConsumedItems ? 1 : 0,
    );
    await preferences.setString(
      _inventoryItemSortModeKey,
      value.inventoryItemSortMode.name,
    );
    await preferences.setString(
      _preparedMealCompletionFilterKey,
      value.preparedMealCompletionFilter.name,
    );
    await preferences.setString(
      _preparedMealConsumptionFilterKey,
      value.preparedMealConsumptionFilter.name,
    );
    await preferences.setString(
      _preparedMealSortModeKey,
      value.preparedMealSortMode.name,
    );
    await preferences.setInt(
      _recentItemsExpandedKey,
      value.isRecentItemsSectionExpanded ? 1 : 0,
    );
    await preferences.setInt(
      _preparedMealsExpandedKey,
      value.isPreparedMealsSectionExpanded ? 1 : 0,
    );
  }

  bool _readBool(AppPreferences preferences, String key, bool fallback) {
    final storedValue = preferences.getIntSync(key);
    if (storedValue == null) {
      return fallback;
    }
    return storedValue != 0;
  }

  T _enumFromName<T extends Enum>(
    Iterable<T> values,
    String? storedName,
    T fallback,
  ) {
    if (storedName == null) {
      return fallback;
    }

    return values.asNameMap()[storedName] ?? fallback;
  }
}
