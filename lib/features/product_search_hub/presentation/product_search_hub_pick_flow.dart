import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/domain/product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_completion_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_meal_food_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_stock_review_flow.dart';

/// Completes a food picked in the product search hub for the route mode:
/// a picker returns it, a meal asks its amount on the eat page, the Vorrat
/// and the diary show their page before they save it. [setSaving] tells the
/// hub page while the food is saved, and [close] closes the hub with its
/// result.
///
/// Returns the food with the edits made in a follow-up page that the user
/// canceled, or null when there is nothing to reopen.
Future<InventoryReceiptManualProductResult?> completeProductSearchHubPick({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required String sourceKey,
  required InventoryReceiptManualProductResult result,
  required ValueChanged<bool> setSaving,
  required void Function([Object? result]) close,
}) async {
  if (args.mode == ProductSearchHubMode.selection) {
    close(result);
    return null;
  }
  if (args.mode == ProductSearchHubMode.mealFood) {
    final picked = await pickProductSearchHubMealFood(
      context: context,
      args: args,
      result: result,
    );
    final pick = picked.pick;
    if (pick != null && context.mounted) close(pick);
    return pick == null ? picked.result : null;
  }
  final reviewed = await _reviewBeforeSave(
    context: context,
    args: args,
    result: result,
  );
  if (reviewed.closed || !context.mounted) return reviewed.result;

  setSaving(true);

  final completion = await completeProductSearchHubResult(
    context: context,
    args: args,
    sourceKey: sourceKey,
    result: reviewed.result,
    mode: reviewed.mode,
  );
  if (!context.mounted) {
    return null;
  }
  setSaving(false);
  if (completion.shouldCloseHub) {
    close(true);
  }
  return completion.wasCanceled ? reviewed.result : null;
}

/// Completes a food created in the hub, from the AI page or as an own
/// product. Canceling the eat or save page that follows reopens the editor
/// with the entered values; [complete] completes each version.
Future<void> completeProductSearchHubCreatedEntry({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required ProductSearchHubEditedResult entry,
  required Future<InventoryReceiptManualProductResult?> Function({
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
  })
  complete,
}) async {
  ProductSearchHubEditedResult? current = entry;
  while (current != null) {
    final canceled = await complete(
      sourceKey: current.sourceKey,
      result: current.result,
    );
    if (canceled == null || !context.mounted) {
      return;
    }
    current = await reopenProductSearchHubCreatedEntry(
      context: context,
      args: args,
      result: canceled,
    );
  }
}

/// Shows the page a picked food passes before it is saved: the Vorrat page
/// in the Vorrat, the eat page in the diary. Both offer "Bearbeiten".
///
/// Returns the reviewed result. When the user closes the page, `closed` is
/// true and the result holds the last edit of the diary eat page. `mode`
/// names the mode that saves the food when it is not the route's: the Vorrat
/// for a diary food put into the Vorrat instead, the diary for a Vorrat food
/// eaten or planned instead.
Future<
  ({
    InventoryReceiptManualProductResult result,
    bool closed,
    ProductSearchHubMode? mode,
  })
>
_reviewBeforeSave({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
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
          loggedAt: reviewed.eatOn,
          plans: reviewed.eatOn != null,
          canStore: false,
        );
        return (
          result: eaten.result,
          closed: eaten.closed,
          mode: ProductSearchHubMode.diary,
        );
      }
      return (
        result: reviewed?.result ?? result,
        closed: reviewed == null,
        mode: null,
      );
    // A food from the AI page was already eaten there.
    case ProductSearchHubMode.diary when result.eatSelection == null:
      final eaten = await eatProductSearchHubDiaryFood(
        context: context,
        args: args,
        result: result,
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
          mode: ProductSearchHubMode.inventory,
        );
      }
      return (result: eaten.result, closed: eaten.closed, mode: null);
    case _:
      return (
        result: result,
        closed: false,
        // The AI page in the Vorrat can eat or plan the food instead.
        mode:
            args.mode == ProductSearchHubMode.inventory &&
                result.eatSelection != null
            ? ProductSearchHubMode.diary
            : null,
      );
  }
}
