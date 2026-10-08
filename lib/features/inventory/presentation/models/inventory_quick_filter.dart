import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';

/// Quick filter chips above the Vorrat list.
enum InventoryQuickFilter {
  /// Everything in the list.
  all,

  /// Partly used foods and meals.
  open,

  /// Foods and meals that open plans take stock from.
  planned,

  /// Prepared meals only.
  meals,

  /// Less than a quarter left.
  low;

  /// Whether [entry] belongs to this filter. [plannedIds] are the foods
  /// and meals that open plans take stock from.
  bool matches(InventoryListEntry entry, Set<String> plannedIds) {
    return switch (this) {
      InventoryQuickFilter.all => true,
      InventoryQuickFilter.open => entry.isOpen,
      InventoryQuickFilter.planned => plannedIds.contains(entry.id),
      InventoryQuickFilter.meals => entry is InventoryMealEntry,
      InventoryQuickFilter.low => entry.isLow,
    };
  }
}
