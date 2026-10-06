import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/hero_tags.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/combined_calorie_entry.dart';
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
import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_portions_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Runs a hub action on top of the hub and returns whether it changed the
/// item. A changed item closes the hub, except after a shopping list add.
typedef InventoryItemHubActionRunner = Future<bool> Function(
  BuildContext hubContext,
  InventoryItemHubAction,
);

/// Item hub: the eat page of a stock item plus the item's own actions.
///
/// Pops with an [InventoryItemHubResult]: the entered amount, or a meal of
/// several foods. Actions run while the hub stays open. An item without stock
/// shows only its actions, and the main button puts it on the shopping list.
class InventoryItemHubPage extends ConsumerStatefulWidget {
  /// Creates the hub for [item].
  const new({
    required this.item,
    required this.onAction,
    this.initialPicks = const <InventoryItem>[],
    super.key,
  });

  /// The stock item.
  final InventoryItem item;

  /// Foods that join the meal on open; those without a default amount stay out.
  final List<InventoryItem> initialPicks;

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
  var _portions = 1;
  // The hub's item can leave the meal while other foods are picked. It is
  // back as soon as the meal is empty again.
  var _hubRemoved = false;

  InventoryItemEatSheetControllerProvider get _sheet =>
      inventoryItemEatSheetControllerProvider(item: widget.item);

  @override
  void initState() {
    super.initState();
    if (widget.initialPicks.isEmpty) {
      return;
    }
    // Riverpod refuses changes while the first frame builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final combine = ref.read(
        inventoryItemCombineControllerProvider(widget.item.id).notifier,
      );
      widget.initialPicks.forEach(combine.addWithDefaultAmount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Watched, so the line follows the list after an undo.
    final isOnShoppingList = ref.watch(
      sourceItemInActiveShoppingListProvider((
        name: widget.item.name,
        brand: widget.item.brand,
        initialQuantity: widget.item.initialQuantity,
        unitPrice: widget.item.unitPrice,
      )),
    );
    final combine = inventoryItemCombineControllerProvider(widget.item.id);
    final picks = ref.watch(combine);
    final actions = EatItemActionsCard(
      key: _cardKey,
      isOnShoppingList: isOnShoppingList,
      onPicked: _run,
      actions: [
        for (final action in InventoryItemHubAction.values)
          if (picks.isEmpty || action != InventoryItemHubAction.edit) action,
      ],
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
    ref.listen(combine, (_, next) {
      if (next.isNotEmpty) {
        // A meal is eaten or stored, never planned.
        ref.read(_sheet.notifier).leavePlanDay();
      } else if (_hubRemoved) {
        setState(() => _hubRemoved = false);
      }
    });
    final includesHub = !_hubRemoved || picks.isEmpty;
    final meal = picks.isEmpty ? null : _meal(picks, includesHub: includesHub);
    final hasMealRuler = inventoryItemUsesFixedCalorieUnit(widget.item);
    return InventoryItemEatSheetBody(
      item: widget.item,
      // A meal goes into the stock first; logging it is the second choice.
      confirmIntent: picks.isEmpty
          ? InventoryItemEatSheetIntent.logOnly
          : InventoryItemEatSheetIntent.storeAsMeal,
      confirmLabel: picks.isEmpty ? null : l10n.eatPageCombineStore,
      mealKcal: meal?.total.kcal,
      addMoreActionText: picks.isEmpty ? null : l10n.eatPageCombineConfirm,
      secondaryIntent: InventoryItemEatSheetIntent.logOnly,
      header: meal == null
          ? null
          : EatMealHeader(
              title: combinedFoodName([
                if (includesHub) widget.item.name,
                for (final pick in picks) pick.item.name,
              ]),
              imageUrls: [
                if (includesHub) widget.item.imageUrl,
                for (final pick in picks) pick.item.imageUrl,
              ],
            ),
      // In a meal the hub item's row carries its ruler.
      showAmount: meal == null || (includesHub && !hasMealRuler),
      onCompleteValues: picks.isEmpty
          ? () => _run(InventoryItemHubAction.edit)
          : null,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xxl,
        children: [
          if (InventoryCombinedEatService.canCombine(widget.item))
            EatCombineSection(
              hubItem: widget.item,
              includesHubItem: includesHub,
              onRemoveHubItem: () => setState(() => _hubRemoved = true),
            ),
          if (meal != null) ...[
            EatMealPortionsRow(
              portions: _portions,
              onChanged: (portions) => setState(() => _portions = portions),
            ),
            EatMealTable(meal: meal, portions: _portions),
          ],
          actions,
        ],
      ),
      onSubmitted: (result) => _submit(result, picks, includesHub: includesHub),
    );
  }

  /// Nutrients of [picks], with the hub item's amount when [includesHub]. An
  /// empty hub amount counts as unknown, so the totals show "–".
  EatMealNutrition _meal(
    List<InventoryCombinePick> picks, {
    required bool includesHub,
  }) {
    final hub = ref.watch(_sheet);
    final nutrition = hub.nutrition;
    return EatMealNutrition.combine([
      if (includesHub)
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
    List<InventoryCombinePick> picks, {
    required bool includesHub,
  }) {
    final request = result.request;
    if (_isRunning) {
      return;
    }
    if (picks.isEmpty) {
      Navigator.of(context).pop(InventoryItemHubEat(request));
      return;
    }
    final hubContext = _cardKey.currentContext;
    if (includesHub &&
        !canDirectlySaveInventoryItemEatRequest(widget.item, request)) {
      if (hubContext != null) {
        ScaffoldMessenger.of(hubContext).showAppSnackBar(
          AppLocalizations.of(context)!.inventoryItemActionFailed,
          tone: AppSnackBarTone.error,
        );
      }
      return;
    }
    Navigator.of(context).pop(
      InventoryItemHubMeal(
        request: request,
        picks: picks,
        keepInStock: result.intent == InventoryItemEatSheetIntent.storeAsMeal,
        portions: _portions,
        includesItem: includesHub,
      ),
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
          heroTag: HeroTags.stockItemImage(item.id),
          fallbackLetter: inventoryPictureLetter(item.name),
        ),
        actions,
      ],
    );
  }
}
