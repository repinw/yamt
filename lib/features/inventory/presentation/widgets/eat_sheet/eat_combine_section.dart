import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_food_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_text_link.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Hub section to log other foods together with [hubItem].
///
/// Shows a link while nothing is picked, then one row per food with its
/// amount and calories. Tapping a row opens a ruler for its amount;
/// the hub item's row drives the hub's own amount. With other foods picked
/// the hub item can leave the meal like any other food.
class EatCombineSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const new({
    required this.hubItem,
    required this.onRemoveHubItem,
    this.includesHubItem = true,
    super.key,
  });

  /// Key of the hub item's remove button.
  static const removeHubItemKey = Key('eat_combine_remove_hub_item');

  /// Key of the link that adds a food.
  static const addKey = Key('eat_combine_add');

  /// The hub's item.
  final InventoryItem hubItem;

  /// Whether the hub's item is part of the meal.
  final bool includesHubItem;

  /// Called when the user takes the hub's item out of the meal.
  final VoidCallback onRemoveHubItem;

  @override
  ConsumerState<EatCombineSection> createState() => _EatCombineSectionState();
}

class _EatCombineSectionState extends ConsumerState<EatCombineSection> {
  String? _openId;

  InventoryItem get hubItem => widget.hubItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final picks = ref.watch(inventoryItemCombineControllerProvider(hubItem.id));
    final addLink = EatTextLink(
      buttonKey: EatCombineSection.addKey,
      label: picks.isEmpty ? l10n.eatPageCombineLink : l10n.eatPageCombineAdd,
      onPressed: _add,
    );
    if (picks.isEmpty) {
      return addLink;
    }
    final hubProvider = inventoryItemEatSheetControllerProvider(item: hubItem);
    final hubState = ref.watch(hubProvider);
    final hubKcal = hubState.nutrition?.eaten.kcal;
    final combineProvider = inventoryItemCombineControllerProvider(hubItem.id);

    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.includesHubItem)
            EatCombineFoodRow(
              name: hubItem.name,
              amount: hubState.enteredAmountLabel(l10n),
              kcal: hubKcal == null ? null : l10n.eatPageKcal(hubKcal.round()),
              isOpen: _openId == hubItem.id,
              onTap: () => _toggle(hubItem.id),
              removeKey: EatCombineSection.removeHubItemKey,
              onRemove: widget.onRemoveHubItem,
              // The page's own ruler is hidden in a meal, so its error shows
              // here.
              errorText: hubState.amountError(l10n),
              ruler: inventoryItemUsesFixedCalorieUnit(hubItem)
                  ? EatRuler(
                      value: hubState.amountValue,
                      max: hubState.amountMax,
                      step: hubState.amountStep,
                      marks: const <EatRulerMark>[],
                      onChanged: (value) =>
                          ref.read(hubProvider.notifier).pickAmount(value),
                    )
                  : null,
            ),
          for (final pick in picks)
            EatCombineFoodRow(
              key: ValueKey<String>(pick.item.id),
              name: pick.item.name,
              amount: pick.component.amountLabel,
              kcal: l10n.eatPageKcal(pick.component.totalKcal.round()),
              isOpen: _openId == pick.item.id,
              onTap: () => _toggle(pick.item.id),
              onRemove: () =>
                  ref.read(combineProvider.notifier).remove(pick.item.id),
              ruler: defaultMealFoodAmount(pick.item) == null
                  ? null
                  : EatRuler(
                      value: pick.request.inventoryAmount.toDouble(),
                      max: mealFoodMaxAmount(
                        pick.item,
                        hasOpenStock: pick.searchResult != null,
                      ).toDouble(),
                      step: AppFoodLabel.mealRulerStep,
                      marks: const <EatRulerMark>[],
                      onChanged: (value) => ref
                          .read(combineProvider.notifier)
                          .setAmount(pick.item.id, value.round()),
                    ),
            ),
          addLink,
        ],
      ),
    );
  }

  void _toggle(String id) {
    setState(() => _openId = _openId == id ? null : id);
  }

  /// Opens the inventory to pick foods. Stock items join with a default
  /// amount. A food found by search joins the same way, unless it needs its
  /// amount entered on the eat page; it is left out when that page is
  /// closed.
  Future<void> _add() async {
    final notifier = ref.read(
      inventoryItemCombineControllerProvider(hubItem.id).notifier,
    );
    final items = ref.read(inventoryItemsControllerProvider).value;
    final picked = await showInventoryCombinePickPage(
      context,
      candidates: notifier.candidatesFrom(items ?? const <InventoryItem>[]),
    );
    if (picked == null) {
      return;
    }
    final searched = picked.searched;
    for (final (item, searchResult) in [
      for (final item in picked.stock) (item, null),
      if (searched != null) (searched.item, searched),
    ]) {
      if (!mounted) {
        return;
      }
      if (!InventoryCombinedEatService.canCombine(item)) {
        _showCannotCombine(context);
        continue;
      }
      if (searchResult?.eatSelection == null &&
          notifier.addWithDefaultAmount(item, searchResult: searchResult)) {
        continue;
      }
      final request = await _askAmount(context, item);
      if (request == null || !mounted) {
        continue;
      }
      if (!canDirectlySaveInventoryItemEatRequest(item, request)) {
        _showCannotCombine(context);
        continue;
      }
      notifier.add(item, request, searchResult: searchResult);
    }
  }

  static void _showCannotCombine(BuildContext context) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.eatPageCombineNeedsNutrition,
      tone: AppSnackBarTone.error,
    );
  }

  /// Asks the amount of a food found by search on the eat page, whose
  /// button adds the food to the list instead of logging it. The food has
  /// no stock yet, so its amount is open.
  static Future<InventoryItemEatRequest?> _askAmount(
    BuildContext context,
    InventoryItem item,
  ) async {
    final result = await showInventoryItemEatSheetResult(
      context: context,
      item: item,
      initialInventoryAmount: resolveInventoryManualAddInitialConsumedAmount(
        item: item,
        rawWeight: item.weight,
      ),
      hasOpenStock: true,
      confirmLabel: AppLocalizations.of(context)!.eatPageCombineAddFood,
    );
    return result?.request;
  }
}
