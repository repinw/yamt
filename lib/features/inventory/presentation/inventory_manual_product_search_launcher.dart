import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

part 'inventory_manual_product_search_launcher.g.dart';

/// Request to open a manual product-search flow for an inventory item.
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

/// Builds the inventory-owned adapter to the reusable product-search hub.
InventoryManualProductSearchLauncher
buildInventoryProductSearchHubManualProductSearchLauncher() {
  return ({required context, required request}) {
    return context.push<InventoryReceiptManualProductResult>(
      AppRoutes.homeProductSearchHub,
      extra: ProductSearchHubRouteArgs.selection(
        item: request.item,
        includeStoreInSearch: request.includeStoreInSearch,
        includeWeightInSearch: request.includeWeightInSearch,
      ),
    );
  };
}
