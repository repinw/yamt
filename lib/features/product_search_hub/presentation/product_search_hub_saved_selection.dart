import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Product search hub item already saved during the current insert session.
class ProductSearchHubSavedSelection {
  /// Creates saved selection.
  const ProductSearchHubSavedSelection({
    required this.item,
    required this.sourceKey,
  });

  /// Saved inventory item.
  final InventoryItem item;

  /// Stable source key used to show selected indicators.
  final String sourceKey;
}
