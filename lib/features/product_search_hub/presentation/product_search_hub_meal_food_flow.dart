import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
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

/// Key of the edit line on the meal food eat page.
const productSearchHubMealFoodEditKey = Key(
  'product_search_hub_meal_food_edit',
);

const _mealFoodIds = Uuid();

/// Shows the eat page for a food picked for a meal. "Bearbeiten" there opens
/// the editor and comes back to the eat page with the edited food.
///
/// Returns the food with the entered amount, or null when the user closes
/// the page. The food gets a new id: a recent item keeps the id of its stock
/// item, which may already be part of the meal.
Future<InventoryMealFoodPick?> pickProductSearchHubMealFood({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryReceiptManualProductResult result,
}) async {
  var current = result.withItem(result.item.copyWith(id: _mealFoodIds.v4()));
  while (true) {
    final step = await Navigator.of(context, rootNavigator: true)
        .push<_MealFoodStep>(
          MaterialPageRoute<_MealFoodStep>(
            fullscreenDialog: true,
            builder: (_) => _MealFoodEatPage(item: current.item),
          ),
        );
    if (!context.mounted) {
      return null;
    }
    switch (step) {
      case null:
        return null;
      case _MealFoodAdded(:final request):
        return (result: current, request: request);
      case _MealFoodEdit():
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

sealed class _MealFoodStep {
  const new();
}

final class _MealFoodAdded extends _MealFoodStep {
  const new(this.request);

  final InventoryItemEatRequest request;
}

final class _MealFoodEdit extends _MealFoodStep {
  const new();
}

/// Eat page of a picked food. Its button adds the food to the meal instead
/// of logging it. The food has no stock yet, so its amount is open.
class _MealFoodEatPage extends StatelessWidget {
  const new({required this.item});

  final InventoryItem item;

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
      hasOpenStock: true,
      confirmLabel: l10n.eatPageCombineAddFood,
      onSubmitted: (result) =>
          Navigator.of(context).pop(_MealFoodAdded(result.request)),
      footer: EatActionCard(
        title: l10n.eatPageItemTitle,
        actions: [
          (
            key: productSearchHubMealFoodEditKey,
            icon: Icons.edit_outlined,
            label: l10n.inventoryReceiptReviewEditAction,
            color: FoodLabelColors.of(context).ink,
            onPressed: () => Navigator.of(context).pop(const _MealFoodEdit()),
          ),
        ],
      ),
    );
  }
}
