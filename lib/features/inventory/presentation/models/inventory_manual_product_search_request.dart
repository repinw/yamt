import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Request to pick a product in the product search hub for an inventory
/// item. Inventory passes it as the route's `extra`; the hub answers with an
/// `InventoryReceiptManualProductResult`.
class InventoryManualProductSearchRequest {
  /// Creates manual product-search request.
  const new({
    required this.item,
    this.includeStoreInSearch = true,
    this.includeWeightInSearch = true,
  });

  /// Base inventory item.
  final InventoryItem item;

  /// Whether store is included in search text.
  final bool includeStoreInSearch;

  /// Whether weight is included in search text.
  final bool includeWeightInSearch;
}
