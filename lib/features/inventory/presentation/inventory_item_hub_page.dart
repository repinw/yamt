import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
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
import 'package:yamt/features/inventory/presentation/models/inventory_meal_food_pick.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_food_estimate_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_hub_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_used_up_hub_body.dart';
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
/// several foods. Actions run while the hub stays open; the trash button
/// removes the item. An item without stock shows only its actions, and the
/// main button puts it on the shopping list.
class InventoryItemHubPage extends ConsumerStatefulWidget {
  /// Creates the hub for [item].
  const new({
    required this.item,
    required this.onAction,
    this.initialPicks = const <InventoryItem>[],
    this.initialFoods = const <InventoryMealFoodPick>[],
    super.key,
  });

  /// The stock item.
  final InventoryItem item;

  /// Foods that join the meal on open; those without a default amount stay out.
  final List<InventoryItem> initialPicks;

  /// Foods found in the catalog that join the meal on open, with their
  /// entered amounts.
  final List<InventoryMealFoodPick> initialFoods;

  /// Runs a picked action.
  final InventoryItemHubActionRunner onAction;

  @override
  ConsumerState<InventoryItemHubPage> createState() =>
      _InventoryItemHubPageState();
}

class _InventoryItemHubPageState extends ConsumerState<InventoryItemHubPage> {
  // Below the page's snackbar messenger, so action hints show on the hub.
  final GlobalKey _cardKey = GlobalKey();
  var _isRunning = false;
  // An AI level chip saves a new item while the hub stays open (#763).
  late InventoryItem _item = widget.item;
  // The hub item can leave a meal; it is back once the meal is empty.
  var _hubRemoved = false;

  InventoryItemEatSheetControllerProvider get _sheet =>
      inventoryItemEatSheetControllerProvider(item: _item);

  @override
  void initState() {
    super.initState();
    if (widget.initialPicks.isEmpty && widget.initialFoods.isEmpty) {
      return;
    }
    // Riverpod refuses changes while the first frame builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final combine = ref.read(
        inventoryItemCombineControllerProvider(_item.id).notifier,
      );
      widget.initialPicks.forEach(combine.addWithDefaultAmount);
      for (final (:result, :request) in widget.initialFoods) {
        combine.add(result.item, request, searchResult: result);
      }
    });
  }

  // X and back wait for a running action, so its result and snack bar
  // reach the user (#312).
  @override
  Widget build(BuildContext context) =>
      PopScope(canPop: !_isRunning, child: _content(context));

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Watched, so the line follows the list after an undo.
    final isOnShoppingList = ref.watch(
      sourceItemInActiveShoppingListProvider((
        name: _item.name,
        brand: _item.brand,
        initialQuantity: _item.initialQuantity,
        unitPrice: _item.unitPrice,
      )),
    );
    final combine = inventoryItemCombineControllerProvider(_item.id);
    final picks = ref.watch(combine);
    final canEat = consumableInventoryAmount(_item) != null;
    // A running action also blocks "Kombinieren", which closes the hub (#728).
    final actions = IgnorePointer(
      ignoring: _isRunning,
      child: InventoryItemHubActionsCard(
        key: _cardKey,
        item: _item,
        isOnShoppingList: isOnShoppingList,
        onPicked: _run,
        actions: [
          for (final action in InventoryItemHubAction.values)
            if (action != InventoryItemHubAction.remove &&
                (picks.isEmpty || action != InventoryItemHubAction.edit))
              action,
        ],
        offersEatActions: canEat && picks.isEmpty,
      ),
    );
    if (!canEat) {
      return InventoryItemUsedUpHubBody(
        item: _item,
        isOnShoppingList: isOnShoppingList,
        actions: actions,
        onRun: _run,
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
    final hasMealRuler = inventoryItemUsesFixedCalorieUnit(_item);
    return InventoryItemEatSheetBody(
      // A new item starts a new eat page, see [_takeItem].
      key: ValueKey(_item),
      item: _item,
      // A meal goes into the stock first; logging it is the second choice.
      confirmIntent: picks.isEmpty
          ? InventoryItemEatSheetIntent.logOnly
          : InventoryItemEatSheetIntent.storeAsMeal,
      confirmLabel: picks.isEmpty ? null : l10n.eatPageCombineStore,
      mealKcal: meal == null ? null : (kcal: meal.total.kcal),
      addMoreActionText: picks.isEmpty ? null : l10n.eatPageCombineConfirm,
      header: meal != null
          ? EatMealHeader(
              title: combinedFoodName([
                if (includesHub) _item.name,
                for (final pick in picks) pick.item.name,
              ]),
              imageUrls: [
                if (includesHub) _item.imageUrl,
                for (final pick in picks) pick.item.imageUrl,
              ],
            )
          : _item.productSnapshot.aiEstimate == null
          ? null
          : EatFoodEstimateHeader(
              item: _item,
              enabled: !_isRunning,
              onSaving: (saving) =>
                  mounted ? setState(() => _isRunning = saving) : null,
              onSaved: _takeItem,
            ),
      // In a meal the hub item's row carries its ruler.
      showAmount: meal == null || (includesHub && !hasMealRuler),
      showsInedibleLink: false,
      onCompleteValues: picks.isEmpty
          ? () => _run(InventoryItemHubAction.edit)
          : null,
      // A started meal keeps the bottom row for its own buttons.
      onRemove: picks.isEmpty
          ? () => _run(InventoryItemHubAction.remove)
          : null,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xxl,
        children: [
          // The item card starts a meal; then its foods show here.
          if (picks.isNotEmpty && InventoryCombinedEatService.canCombine(_item))
            // A running action blocks the add link, which closes the hub.
            IgnorePointer(
              ignoring: _isRunning,
              child: EatCombineSection(
                hubItem: _item,
                includesHubItem: includesHub,
                onRemoveHubItem: () => setState(() => _hubRemoved = true),
              ),
            ),
          // Portions are set in the meal's "Gekocht" step.
          if (meal != null) EatMealTable(meal: meal),
          if (meal == null && _item.productSnapshot.aiEstimate != null)
            EatFoodEstimateIngredients(item: _item),
          actions,
        ],
      ),
      onSubmitted: (result) => _submit(result, picks, includesHub: includesHub),
    );
  }

  /// Nutrients of [picks], with the hub item's amount when [includesHub]. An
  /// empty hub amount counts as unknown, so energy and the macros show "–"
  /// and the other totals a minimum.
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
    if (_isRunning) return;
    if (picks.isEmpty) {
      Navigator.of(context).pop(InventoryItemHubEat(request));
      return;
    }
    final hubContext = _cardKey.currentContext;
    if (includesHub &&
        !canDirectlySaveInventoryItemEatRequest(_item, request)) {
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
        includesItem: includesHub,
      ),
    );
  }

  void _takeItem(InventoryItem item) {
    final before = ref.read(_sheet);
    setState(() => _item = item);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(_sheet.notifier).takeInput(before);
    });
  }

  Future<void> _run(InventoryItemHubAction action) async {
    final hubContext = _cardKey.currentContext;
    if (_isRunning || hubContext == null) return;
    setState(() => _isRunning = true);
    try {
      final changed = await widget.onAction(hubContext, action);
      if (!changed ||
          !mounted ||
          action == InventoryItemHubAction.addToShoppingList) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }
}
