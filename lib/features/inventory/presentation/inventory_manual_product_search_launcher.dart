import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';

part 'inventory_manual_product_search_launcher.g.dart';

/// Request to open a manual product-search flow for an inventory item.
class InventoryManualProductSearchRequest {
  /// Creates manual product-search request.
  const InventoryManualProductSearchRequest({
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

/// Launches manual product search from inventory-owned UI.
typedef InventoryManualProductSearchLauncher =
    Future<InventoryReceiptManualProductResult?> Function({
      required BuildContext context,
      required InventoryManualProductSearchRequest request,
    });

/// Provides the manual product-search launcher for inventory surfaces.
@riverpod
InventoryManualProductSearchLauncher inventoryManualProductSearchLauncher(
  Ref ref,
) {
  return ({required context, required request}) async => null;
}
