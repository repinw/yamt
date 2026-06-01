import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

/// Opens the product search hub for receipt-review manual correction.
Future<InventoryReceiptManualProductResult?>
openReceiptReviewManualProductFlow({
  required BuildContext context,
  required InventoryItem item,
}) {
  return context.push<InventoryReceiptManualProductResult>(
    AppRoutes.homeProductSearchHub,
    extra: ProductSearchHubRouteArgs.selection(
      item: item,
      includeStoreInSearch: false,
      includeWeightInSearch: false,
    ),
  );
}
