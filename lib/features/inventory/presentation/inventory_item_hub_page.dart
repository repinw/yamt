import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Runs a hub action on top of the hub. Returns whether it changed the item.
/// A changed item closes the hub, except after adding it to the shopping
/// list, where the hub follows the list itself.
typedef InventoryItemHubActionRunner = Future<bool> Function(
  BuildContext hubContext,
  InventoryItemHubAction,
);

/// Item hub: the eat page of a stock item plus the item's own actions.
///
/// Pops with an [InventoryItemHubResult]: the entered amount, or the amount
/// together with other foods to log as one entry. The actions run while the
/// hub stays open, so cancelling one returns to the hub. An item without
/// stock to eat shows only its actions, and the main button puts it on the
/// shopping list.
class InventoryItemHubPage extends ConsumerStatefulWidget {
  /// Creates the hub for [item].
  const new({required this.item, required this.onAction, super.key});

  /// The stock item.
  final InventoryItem item;

  /// Runs a picked action.
  final InventoryItemHubActionRunner onAction;

  @override
  ConsumerState<InventoryItemHubPage> createState() =>
      _InventoryItemHubPageState();
}

class _InventoryItemHubPageState extends ConsumerState<InventoryItemHubPage> {
  // The card sits below the page's own snackbar messenger, so its context
  // shows action hints on the hub.
  final GlobalKey _cardKey = GlobalKey();
  var _isRunning = false;

  @override
  Widget build(BuildContext context) {
    // Watched, so the line follows the list after an undo.
    final isOnShoppingList = ref.watch(
      sourceItemInActiveShoppingListProvider((
        name: widget.item.name,
        brand: widget.item.brand,
        initialQuantity: widget.item.initialQuantity,
        unitPrice: widget.item.unitPrice,
      )),
    );
    final actions = EatItemActionsCard(
      key: _cardKey,
      isOnShoppingList: isOnShoppingList,
      onPicked: _run,
    );
    if (consumableInventoryAmount(widget.item) == null) {
      return _UsedUpHubBody(
        item: widget.item,
        isOnShoppingList: isOnShoppingList,
        actions: actions,
        onAddToShoppingList: () =>
            _run(InventoryItemHubAction.addToShoppingList),
      );
    }
    final picks = ref.watch(
      inventoryItemCombineControllerProvider(widget.item.id),
    );
    final meal = picks.isEmpty ? null : _meal(picks);
    final hasMealRuler = inventoryItemUsesFixedCalorieUnit(widget.item);
    return InventoryItemEatSheetBody(
      item: widget.item,
      confirmIntent: InventoryItemEatSheetIntent.logOnly,
      confirmLabel: picks.isEmpty
          ? null
          : AppLocalizations.of(context)!.eatPageCombineConfirm,
      extraKcal: picks.fold(0, (sum, pick) => sum + pick.component.totalKcal),
      addMoreActionText: picks.isEmpty
          ? null
          : AppLocalizations.of(context)!.eatPageCombineStore,
      secondaryIntent: InventoryItemEatSheetIntent.storeAsMeal,
      header: meal == null
          ? null
          : EatMealHeader(
              title: [
                widget.item.name,
                for (final pick in picks) pick.item.name,
              ].join(' + '),
              imageUrls: [
                widget.item.imageUrl,
                for (final pick in picks) pick.item.imageUrl,
              ],
            ),
      // In a meal the hub item's row carries its ruler.
      showAmount: meal == null || !hasMealRuler,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xxl,
        children: [
          if (InventoryCombinedEatService.canCombine(widget.item))
            EatCombineSection(hubItem: widget.item),
          ?meal == null ? null : EatMealTable(meal: meal),
          actions,
        ],
      ),
      onSubmitted: (result) => _submit(result, picks),
    );
  }

  /// Nutrients of the hub item's entered amount together with [picks]. An
  /// empty hub amount counts as unknown, so the totals show "–".
  EatMealNutrition _meal(List<InventoryCombinePick> picks) {
    final hub = ref.watch(
      inventoryItemEatSheetControllerProvider(item: widget.item),
    );
    final nutrition = hub.nutrition;
    return EatMealNutrition.combine([
      (
        eaten: nutrition?.eaten ?? const NutritionFacts(),
        amount: nutrition?.amount ?? 0,
        unit: hub.nutritionConsumedUnit,
      ),
      for (final pick in picks) ?eatMealFoodOfRequest(pick.item, pick.request),
    ]);
  }

  void _submit(
    InventoryItemEatSheetResult result,
    List<InventoryCombinePick> picks,
  ) {
    final request = result.request;
    if (_isRunning) {
      return;
    }
    if (picks.isEmpty) {
      Navigator.of(context).pop(InventoryItemHubEat(request));
      return;
    }
    final hubContext = _cardKey.currentContext;
    if (!canDirectlySaveInventoryItemEatRequest(widget.item, request)) {
      if (hubContext != null) {
        ScaffoldMessenger.of(hubContext).showAppSnackBar(
          AppLocalizations.of(context)!.inventoryItemActionFailed,
          tone: AppSnackBarTone.error,
        );
      }
      return;
    }
    Navigator.of(context).pop(
      result.intent == InventoryItemEatSheetIntent.storeAsMeal
          ? InventoryItemHubStoreMeal(request: request, picks: picks)
          : InventoryItemHubCombine(request: request, picks: picks),
    );
  }

  Future<void> _run(InventoryItemHubAction action) async {
    final hubContext = _cardKey.currentContext;
    if (_isRunning || hubContext == null) {
      return;
    }
    _isRunning = true;
    try {
      final changed = await widget.onAction(hubContext, action);
      if (!changed ||
          !mounted ||
          action == InventoryItemHubAction.addToShoppingList) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      _isRunning = false;
    }
  }
}

class _UsedUpHubBody extends StatelessWidget {
  const new({
    required this.item,
    required this.isOnShoppingList,
    required this.actions,
    required this.onAddToShoppingList,
  });

  final InventoryItem item;
  final bool isOnShoppingList;
  final Widget actions;
  final VoidCallback onAddToShoppingList;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EatPageScaffold(
      whenControl: const SizedBox.shrink(),
      kcal: null,
      confirmButtonKey: const Key('inventory_item_hub_shopping_list_button'),
      confirmLabel: l10n.inventoryItemAddToListAction,
      onConfirm: isOnShoppingList ? null : onAddToShoppingList,
      cancelButtonKey: const Key('inventory_item_hub_close_button'),
      children: [
        EatPageHeader(
          title: item.name,
          brand: item.brand,
          imageUrl: item.imageUrl,
        ),
        actions,
      ],
    );
  }
}
