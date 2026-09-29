import 'package:yamt/features/inventory/application/inventory_search_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_quick_filter.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';

/// What the Vorrat list shows: the filtered and sorted entries, the counts
/// of the quick filter chips, and the receipt groups when grouped.
class InventoryListContent {
  /// Creates the content.
  const new({
    required this.entries,
    required this.counts,
    required this.stockCount,
    required this.hasSource,
    this.receiptGroups,
  });

  /// Filters, sorts and counts [items] and [meals] for the list.
  ///
  /// The chip counts follow the search and the used-up setting but not the
  /// chosen chip, so every chip shows what tapping it would list.
  factory build({
    required List<InventoryItem> items,
    required List<PreparedMeal> meals,
    required InventoryListViewPreferences preferences,
    required InventoryQuickFilter quickFilter,
    required String query,
  }) {
    const search = InventorySearchService();
    final stock = <InventoryListEntry>[
      for (final meal in meals) InventoryMealEntry(meal),
      for (final item in items) InventoryFoodEntry(item),
    ];
    final visible = <InventoryListEntry>[
      for (final meal in search.filterPreparedMeals(meals: meals, query: query))
        InventoryMealEntry(meal),
      for (final item in search.filterItems(items: items, query: query))
        InventoryFoodEntry(item),
    ].where((entry) => !preferences.hideConsumed || !entry.isEmpty).toList();

    final entries = visible.where(quickFilter.matches).toList()
      ..sort((a, b) => _compare(a, b, preferences.sortMode));
    return InventoryListContent(
      entries: entries,
      counts: {
        for (final filter in InventoryQuickFilter.values)
          filter: visible.where(filter.matches).length,
      },
      stockCount: stock.where((entry) => !entry.isEmpty).length,
      hasSource: stock.isNotEmpty,
      receiptGroups: preferences.groupByReceipt
          ? groupInventoryItemsByReceipt([
              for (final entry in visible)
                if (entry is InventoryFoodEntry) entry.item,
            ])
          : null,
    );
  }

  /// Entries in list order.
  final List<InventoryListEntry> entries;

  /// Number of entries each quick filter chip would show.
  final Map<InventoryQuickFilter, int> counts;

  /// Foods and meals with something left, for the header kicker.
  final int stockCount;

  /// Whether the Vorrat has any food or meal at all.
  final bool hasSource;

  /// Foods grouped by receipt, or null when not grouped.
  final List<InventoryReceiptGroup>? receiptGroups;
}

int _compare(
  InventoryListEntry a,
  InventoryListEntry b,
  InventoryItemSortMode mode,
) {
  final result = switch (mode) {
    InventoryItemSortMode.recentlyAddedDescending => b.addedAt.compareTo(
      a.addedAt,
    ),
    InventoryItemSortMode.recentlyAddedAscending => a.addedAt.compareTo(
      b.addedAt,
    ),
    InventoryItemSortMode.recentlyEatenDescending => _compareEaten(
      a,
      b,
      descending: true,
    ),
    InventoryItemSortMode.recentlyEatenAscending => _compareEaten(
      a,
      b,
      descending: false,
    ),
    InventoryItemSortMode.alphabeticalAscending => _compareName(a, b),
    InventoryItemSortMode.alphabeticalDescending => _compareName(b, a),
    InventoryItemSortMode.availableAmountAscending =>
      a.remainingShare.compareTo(b.remainingShare),
    InventoryItemSortMode.availableAmountDescending =>
      b.remainingShare.compareTo(a.remainingShare),
  };
  if (result != 0) {
    return result;
  }
  final byName = _compareName(a, b);
  return byName != 0 ? byName : a.id.compareTo(b.id);
}

int _compareName(InventoryListEntry a, InventoryListEntry b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

/// Compares when two entries were last eaten; an entry never eaten sorts
/// last in both directions.
int _compareEaten(
  InventoryListEntry a,
  InventoryListEntry b, {
  required bool descending,
}) {
  final first = a.lastEatenAt;
  final second = b.lastEatenAt;
  if (first == null || second == null) {
    if (first == second) {
      return 0;
    }
    return first == null ? 1 : -1;
  }
  return descending ? second.compareTo(first) : first.compareTo(second);
}
