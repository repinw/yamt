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
/// closes the page. With [offersEat], the user may eat the product instead
/// (`eats`), on the picked day `eatOn` when it is planned.
Future<
  ({InventoryReceiptManualProductResult result, bool eats, DateTime? eatOn})?
>
reviewProductSearchHubStockResult({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
  bool offersEat = false,
}) async {
  var packages = 1;
  final shown = await showProductSearchHubPickPage<InventoryStockAddResult>(
    context: context,
    args: args,
    result: result,
    show: (current) => showInventoryStockAddPage(
      context: context,
      item: current.item,
      initialPackages: packages,
      offersEat: offersEat,
    ),
    isEdit: (step) {
      if (step case InventoryStockAddEdit(packages: final count)) {
        packages = count;
        return true;
      }
      return false;
    },
  );
  final current = shown.result;
  return switch (shown.step) {
    null || InventoryStockAddEdit() => null,
    InventoryStockAddConfirmed(:final packages) => (
      result: current.withItem(
        current.item.withDerivedAmount(
          quantity: packages,
          fallbackUnit: current.item.amountUnit,
        ),
      ),
      eats: false,
      eatOn: null,
    ),
    InventoryStockAddEat() => (result: current, eats: true, eatOn: null),
    InventoryStockAddPlan(:final day) => (
      result: current,
      eats: true,
      eatOn: day,
    ),
  };
}
