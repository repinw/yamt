import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_meal_food_pick.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_action_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Key of the edit line on the eat page of a picked food.
const productSearchHubEatPageEditKey = Key('product_search_hub_eat_page_edit');

const _mealFoodIds = Uuid();

/// Shows the eat page for a food picked for a meal. "Bearbeiten" there opens
/// the editor and comes back to the eat page with the edited food.
///
/// Returns the food with the entered amount as `pick`, which is null when
/// the user closes the page; `result` then holds the last edit. The food
/// gets a new id: a recent item keeps the id of its stock item, which may
/// already be part of the meal.
Future<
  ({InventoryMealFoodPick? pick, InventoryReceiptManualProductResult result})
>
pickProductSearchHubMealFood({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final picked = await _eatWithEdit(
    context: context,
    args: args,
    result: result.withItem(result.item.copyWith(id: _mealFoodIds.v4())),
    page: (item) =>
        _EditableEatPage(item: item, confirmLabel: l10n.eatPageCombineAddFood),
  );
  final eat = picked.eat;
  return (
    pick: eat == null ? null : (result: picked.result, request: eat.request),
    result: picked.result,
  );
}

/// Shows the eat page for a food picked in the diary. "Bearbeiten" there
/// opens the editor and comes back to the eat page with the edited food.
///
/// Returns the food with the entered eat request. One food is logged per
/// pick (#519). When the user closes the page, `closed` is true and the
/// result holds the last edit. `toStock` is true when the user puts the food
/// into the Vorrat instead of eating it, which [canStore] offers. [loggedAt]
/// replaces the route's preselected day. With [plans], the page's button says
/// "Einplanen" and the food is planned for its day, also for today.
Future<
  ({InventoryReceiptManualProductResult result, bool closed, bool toStock})
>
eatProductSearchHubDiaryFood({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
  DateTime? loggedAt,
  bool canStore = true,
  bool plans = false,
}) async {
  final picked = await _eatWithEdit(
    context: context,
    args: args,
    result: result,
    page: (item) => _EditableEatPage(
      item: item,
      initialLoggedAt: loggedAt ?? args.preselectedLoggedAt,
      initialMealType: args.preselectedMealType,
      canStore: canStore,
      plansOnly: plans,
    ),
  );
  final eat = picked.eat;
  if (eat == null) {
    return (
      result: picked.result,
      closed: !picked.toStock,
      toStock: picked.toStock,
    );
  }
  return (
    result: picked.result.withEatRequest(eat.request),
    closed: false,
    toStock: false,
  );
}

typedef _EatWithEditResult = ({
  InventoryReceiptManualProductResult result,
  InventoryItemEatSheetResult? eat,
  bool toStock,
});

/// Loops between the eat page and the editor until the user eats on the
/// page, puts the food into the Vorrat (`toStock`), or closes it. Without
/// `eat`, the food was not eaten; the result still holds the last edit.
Future<_EatWithEditResult> _eatWithEdit({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
  required Widget Function(InventoryItem item) page,
}) async {
  var current = result;
  while (true) {
    final step = await Navigator.of(context, rootNavigator: true)
        .push<_EatStep>(
          MaterialPageRoute<_EatStep>(
            fullscreenDialog: true,
            builder: (_) => page(current.item),
          ),
        );
    if (!context.mounted || step == null) {
      return (result: current, eat: null, toStock: false);
    }
    switch (step) {
      case _EatSubmitted(:final result):
        return (result: current, eat: result, toStock: false);
      case _EatStore():
        return (result: current, eat: null, toStock: true);
      case _EatEdit():
        final edited = await openProductSearchHubCustomProductEditor(
          context: context,
          draftItem: current.item,
          args: args,
        );
        if (!context.mounted) {
          return (result: current, eat: null, toStock: false);
        }
        if (edited != null) {
          current = edited;
        }
    }
  }
}

sealed class _EatStep {
  const new();
}

final class _EatSubmitted extends _EatStep {
  const new(this.result);

  final InventoryItemEatSheetResult result;
}

final class _EatEdit extends _EatStep {
  const new();
}

final class _EatStore extends _EatStep {
  const new();
}

/// Eat page of a picked food with a "Bearbeiten" line. The food has no stock
/// yet, so its amount is open.
class _EditableEatPage extends StatelessWidget {
  const new({
    required this.item,
    this.confirmLabel,
    this.initialLoggedAt,
    this.initialMealType,
    this.canStore = false,
    this.plansOnly = false,
  });

  final InventoryItem item;
  final String? confirmLabel;
  final DateTime? initialLoggedAt;
  final MealType? initialMealType;
  final bool canStore;
  final bool plansOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InventoryItemEatSheetBody(
      item: item,
      confirmIntent: InventoryItemEatSheetIntent.logOnly,
      initialInventoryAmount: resolveInventoryManualAddInitialConsumedAmount(
        item: item,
        rawWeight: item.weight,
      ),
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
      hasOpenStock: true,
      confirmLabel: confirmLabel,
      plansOnly: plansOnly,
      onSubmitted: (result) => Navigator.of(context).pop(_EatSubmitted(result)),
      onCompleteValues: () => Navigator.of(context).pop(const _EatEdit()),
      onStore: canStore
          ? () => Navigator.of(context).pop(const _EatStore())
          : null,
      footer: EatActionCard(
        title: l10n.eatPageItemTitle,
        actions: [
          (
            key: productSearchHubEatPageEditKey,
            icon: Icons.edit_outlined,
            label: l10n.inventoryReceiptReviewEditAction,
            color: FoodLabelColors.of(context).ink,
            onPressed: () => Navigator.of(context).pop(const _EatEdit()),
          ),
        ],
      ),
    );
  }
}
