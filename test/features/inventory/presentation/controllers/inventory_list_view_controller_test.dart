import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_list_view_controller.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_quick_filter.dart';

import '../../../../helpers/memory_app_preferences.dart';

ProviderContainer _container(MemoryAppPreferences preferences) {
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts with the defaults and the Alle chip', () {
    final container = _container(MemoryAppPreferences());

    final state = container.read(inventoryListViewControllerProvider);

    expect(state.preferences, const InventoryListViewPreferences());
    expect(state.quickFilter, InventoryQuickFilter.all);
    expect(state.query, isEmpty);
  });

  test('stores the settings and reads them on the next start', () async {
    final preferences = MemoryAppPreferences();
    final container = _container(preferences);
    container.read(inventoryListViewControllerProvider.notifier)
      ..setSortMode(InventoryItemSortMode.alphabeticalDescending)
      ..setHideConsumed(hideConsumed: false)
      ..setGroupByReceipt(groupByReceipt: true)
      ..toggleViewMode()
      ..setQuickFilter(InventoryQuickFilter.low)
      ..setQuery('quark');
    await pumpEventQueue();

    final next = _container(preferences);
    final state = next.read(inventoryListViewControllerProvider);
    expect(
      state.preferences,
      const InventoryListViewPreferences(
        viewMode: InventoryListViewMode.tiles,
        sortMode: InventoryItemSortMode.alphabeticalDescending,
        hideConsumed: false,
        groupByReceipt: true,
      ),
    );
    expect(state.quickFilter, InventoryQuickFilter.all);
    expect(state.query, isEmpty);
  });

  test('flipping a sort mode keeps its field', () {
    for (final mode in InventoryItemSortMode.values) {
      expect(mode.flipped.criterion, mode.criterion);
      expect(mode.flipped.isAscending, !mode.isAscending);
      expect(mode.flipped.flipped, mode);
    }
  });
}
