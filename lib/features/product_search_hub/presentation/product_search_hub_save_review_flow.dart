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
/// of the diary eat page. `mode` names the mode that saves the food when it
/// is not the route's: the Vorrat for a diary food put into the Vorrat
/// instead, the diary for a Vorrat food eaten or planned instead.
Future<
  ({
    InventoryReceiptManualProductResult result,
    bool closed,
    bool continuesBatch,
    ProductSearchHubMode? mode,
  })
>
reviewProductSearchHubResultBeforeSave({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
  required bool continuesBatch,
}) async {
  switch (args.mode) {
    // A food from the AI page was already put into the Vorrat there.
    case ProductSearchHubMode.inventory when !result.confirmed:
      final reviewed = await reviewProductSearchHubStockResult(
        context: context,
        args: args,
        result: result,
        offersEat: args.offersEatInstead,
      );
      if (reviewed != null && reviewed.eats && context.mounted) {
        final eaten = await eatProductSearchHubDiaryFood(
          context: context,
          args: args,
          result: reviewed.result,
          continuesBatch: false,
          loggedAt: reviewed.eatOn,
          plans: reviewed.eatOn != null,
          canStore: false,
          // It ends like one eaten food, so it adds no more.
          canAddMore: false,
        );
        return (
          result: eaten.result,
          closed: eaten.closed,
          continuesBatch: continuesBatch,
          mode: ProductSearchHubMode.diary,
        );
      }
      return (
        result: reviewed?.result ?? result,
        closed: reviewed == null,
        continuesBatch: continuesBatch,
        mode: null,
      );
    // A food from the AI page was already eaten there.
    case ProductSearchHubMode.diary when result.eatSelection == null:
      final eaten = await eatProductSearchHubDiaryFood(
        context: context,
        args: args,
        result: result,
        continuesBatch: continuesBatch,
      );
      if (eaten.toStock && context.mounted) {
        final stocked = await reviewProductSearchHubStockResult(
          context: context,
          args: args,
          result: eaten.result,
        );
        return (
          result: stocked?.result ?? eaten.result,
          closed: stocked == null,
          continuesBatch: continuesBatch,
          mode: ProductSearchHubMode.inventory,
        );
      }
      return (
        result: eaten.result,
        closed: eaten.closed,
        continuesBatch: eaten.addMore,
        mode: null,
      );
    case _:
      return (
        result: result,
        closed: false,
        continuesBatch: continuesBatch,
        // The AI page in the Vorrat can eat or plan the food instead.
        mode:
            args.mode == ProductSearchHubMode.inventory &&
                result.eatSelection != null
            ? ProductSearchHubMode.diary
            : null,
      );
  }
}
