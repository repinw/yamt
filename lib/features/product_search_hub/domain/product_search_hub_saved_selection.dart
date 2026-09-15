import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Product search hub item already saved during the current insert session.
class ProductSearchHubSavedSelection {
  /// Creates saved selection.
  const ProductSearchHubSavedSelection({
    required this.item,
    required this.sourceKey,
    this.calorieEntryId,
  });

  /// Saved inventory item.
  final InventoryItem item;

  /// Stable source key used to show selected indicators.
  final String sourceKey;

  /// Diary entry id created by an immediate eat flow.
  final String? calorieEntryId;
}
