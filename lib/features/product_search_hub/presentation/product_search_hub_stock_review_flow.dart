import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_add_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_stock_add_result.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';

/// Shows the Vorrat page for [result] before it is saved. "Bearbeiten" there
/// opens the editor and comes back to the page with the edited product.
///
/// Returns [result] with the picked package count, or null when the user
/// closes the page.
Future<InventoryReceiptManualProductResult?> reviewProductSearchHubStockResult({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
}) async {
  var current = result;
  var packages = 1;
  while (true) {
    final picked = await showInventoryStockAddPage(
      context: context,
      item: current.item,
      initialPackages: packages,
    );
    if (!context.mounted) {
      return null;
    }
    switch (picked) {
      case null:
        return null;
      case InventoryStockAddConfirmed(:final packages):
        final item = current.item;
        return current.withItem(
          item.withDerivedAmount(
            quantity: packages,
            fallbackUnit: item.amountUnit,
          ),
        );
      case InventoryStockAddEdit(packages: final count):
        packages = count;
        // An edit keeps the user's own copy; the catalog product stays.
        final edited = await openProductSearchHubCustomProductEditor(
          context: context,
          draftItem: current.item,
          args: args,
        );
        if (!context.mounted) {
          return null;
        }
        if (edited != null) {
          current = edited;
        }
    }
  }
}
