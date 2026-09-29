import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';

/// Quick filter chips above the Vorrat list.
enum InventoryQuickFilter {
  /// Everything in the list.
  all,

  /// Partly used foods and meals.
  open,

  /// Prepared meals only.
  meals,

  /// Less than a quarter left.
  low;

  /// Whether [entry] belongs to this filter.
  bool matches(InventoryListEntry entry) {
    return switch (this) {
      InventoryQuickFilter.all => true,
      InventoryQuickFilter.open => entry.isOpen,
      InventoryQuickFilter.meals => entry is InventoryMealEntry,
      InventoryQuickFilter.low => entry.isLow,
    };
  }
}
