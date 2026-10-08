import 'dart:async';
import 'dart:developer';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_content.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_quick_filter.dart';

part 'inventory_list_view_controller.g.dart';

/// How the Vorrat list is filtered, sorted and laid out.
@immutable
class InventoryListViewState {
  /// Creates the state.
  const new({
    required this.preferences,
    this.quickFilter = InventoryQuickFilter.all,
    this.query = '',
  });

  /// Settings that survive a restart.
  final InventoryListViewPreferences preferences;

  /// Selected quick filter chip. Starts at "Alle" on every visit.
  final InventoryQuickFilter quickFilter;

  /// Search text.
  final String query;

  /// Copy with.
  InventoryListViewState copyWith({
    InventoryListViewPreferences? preferences,
    InventoryQuickFilter? quickFilter,
    String? query,
  }) {
    return InventoryListViewState(
      preferences: preferences ?? this.preferences,
      quickFilter: quickFilter ?? this.quickFilter,
      query: query ?? this.query,
    );
  }
}

/// Holds the view state of the Vorrat list and stores its settings.
@riverpod
class InventoryListViewController extends _$InventoryListViewController {
  static const _store = InventoryListViewPreferencesStore();

  @override
  InventoryListViewState build() {
    return InventoryListViewState(
      preferences: _store.read(ref.watch(appPreferencesProvider)),
    );
  }

  /// Sorts by [sortMode].
  void setSortMode(InventoryItemSortMode sortMode) =>
      _savePreferences(state.preferences.copyWith(sortMode: sortMode));

  /// Shows or hides used-up entries.
  void setHideConsumed({required bool hideConsumed}) =>
      _savePreferences(state.preferences.copyWith(hideConsumed: hideConsumed));

  /// Groups foods by receipt or lists them flat.
  void setGroupByReceipt({required bool groupByReceipt}) => _savePreferences(
    state.preferences.copyWith(groupByReceipt: groupByReceipt),
  );

  /// Switches between list and tiles.
  void toggleViewMode() => _savePreferences(
    state.preferences.copyWith(
      viewMode: state.preferences.viewMode == InventoryListViewMode.list
          ? InventoryListViewMode.tiles
          : InventoryListViewMode.list,
    ),
  );

  /// Selects a quick filter chip.
  void setQuickFilter(InventoryQuickFilter quickFilter) =>
      state = state.copyWith(quickFilter: quickFilter);

  /// Filters by search text.
  void setQuery(String query) => state = state.copyWith(query: query);

  void _savePreferences(InventoryListViewPreferences preferences) {
    if (preferences == state.preferences) {
      return;
    }
    state = state.copyWith(preferences: preferences);
    unawaited(
      _store.save(ref.read(appPreferencesProvider), preferences).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        log(
          'Could not store the Vorrat list settings.',
          name: 'InventoryListViewController',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }
}

/// The filtered and sorted Vorrat list for the current view state.
@riverpod
Future<InventoryListContent> inventoryListContent(Ref ref) async {
  final view = ref.watch(inventoryListViewControllerProvider);
  final items = ref.watch(inventoryItemsControllerProvider.future);
  final meals = ref.watch(preparedMealsControllerProvider.future);
  // The list does not wait for the plans; the chip fills in once they load.
  final demand = ref.watch(openPlanDemandProvider).value;
  final planned = {
    ...?demand?.plannedByItemId.keys,
    ...?demand?.plannedPortionsByMealId.keys,
  };
  return InventoryListContent.build(
    items: await items,
    meals: await meals,
    preferences: view.preferences,
    quickFilter: view.quickFilter,
    query: view.query,
    plannedIds: planned,
  );
}
