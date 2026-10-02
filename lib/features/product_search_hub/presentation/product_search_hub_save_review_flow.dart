import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/domain/product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_meal_food_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_stock_review_flow.dart';

/// Shows the page a picked food passes before it is saved: the Vorrat page
/// in the Vorrat, the eat page in the diary. Both offer "Bearbeiten".
///
/// Returns the reviewed result and whether the diary batch goes on. When the
/// user closes the page, `closed` is true and the result holds the last edit
/// of the diary eat page.
Future<
  ({
    InventoryReceiptManualProductResult result,
    bool closed,
    bool continuesBatch,
  })
>
reviewProductSearchHubResultBeforeSave({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
  required bool continuesBatch,
}) async {
  switch (args.mode) {
    case ProductSearchHubMode.inventory:
      final reviewed = await reviewProductSearchHubStockResult(
        context: context,
        args: args,
        result: result,
      );
      return (
        result: reviewed ?? result,
        closed: reviewed == null,
        continuesBatch: continuesBatch,
      );
    // A food from the AI page was already eaten there.
    case ProductSearchHubMode.diary when result.eatSelection == null:
      final eaten = await eatProductSearchHubDiaryFood(
        context: context,
        args: args,
        result: result,
        continuesBatch: continuesBatch,
      );
      return (
        result: eaten.result,
        closed: eaten.closed,
        continuesBatch: eaten.addMore,
      );
    case _:
      return (result: result, closed: false, continuesBatch: continuesBatch);
  }
}
