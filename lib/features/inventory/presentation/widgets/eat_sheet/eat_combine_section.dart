import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_add_eat_flow.dart';
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
/// image, amount and calories. Tapping a row opens a ruler for its amount;
/// the hub item's row drives the hub's own amount.
class EatCombineSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const new({required this.hubItem, super.key});

  /// Key of the link that adds a food.
  static const addKey = Key('eat_combine_add');

  /// The hub's item.
  final InventoryItem hubItem;

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
    final notifier = ref.read(
      inventoryItemCombineControllerProvider(hubItem.id).notifier,
    );

    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EatCombineFoodRow(
            imageUrl: hubItem.imageUrl,
            name: hubItem.name,
            amount: hubState.enteredAmountLabel(l10n),
            kcal: hubKcal == null ? null : l10n.eatPageKcal(hubKcal.round()),
            isOpen: _openId == hubItem.id,
            onTap: () => _toggle(hubItem.id),
            ruler: inventoryItemUsesFixedCalorieUnit(hubItem)
                ? EatRuler(
                    value: hubState.amountValue,
                    max: hubState.amountMax,
                    step: hubState.amountStep,
                    marks: const <EatRulerMark>[],
                    onChanged: ref.read(hubProvider.notifier).pickAmount,
                  )
                : null,
          ),
          for (final pick in picks)
            EatCombineFoodRow(
              key: ValueKey<String>(pick.item.id),
              imageUrl: pick.item.imageUrl,
              name: pick.item.name,
              amount: pick.component.amountLabel,
              kcal: l10n.eatPageKcal(pick.component.totalKcal.round()),
              isOpen: _openId == pick.item.id,
              onTap: () => _toggle(pick.item.id),
              onRemove: () => notifier.remove(pick.item.id),
              ruler: defaultMealFoodAmount(pick.item) == null
                  ? null
                  : EatRuler(
                      value: pick.request.inventoryAmount.toDouble(),
                      max: mealFoodMaxAmount(
                        pick.item,
                        hasOpenStock: pick.searchResult != null,
                      ).toDouble(),
                      step: _rulerStep,
                      marks: const <EatRulerMark>[],
                      onChanged: (value) =>
                          notifier.setAmount(pick.item.id, value.round()),
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

  /// Opens the inventory to pick foods. Foods counted in grams or
  /// milliliters join with a default amount; any other food gets its amount
  /// on the eat page, and is left out when that page is closed.
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
      if (searchResult?.eatSelection == null &&
          notifier.addWithDefaultAmount(item, searchResult: searchResult)) {
        continue;
      }
      final request = await _askAmount(context, item, searchResult);
      if (request == null || !mounted) {
        continue;
      }
      if (!InventoryCombinedEatService.canCombine(item) ||
          !canDirectlySaveInventoryItemEatRequest(item, request)) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          AppLocalizations.of(context)!.inventoryItemActionFailed,
          tone: AppSnackBarTone.error,
        );
        continue;
      }
      notifier.add(item, request, searchResult: searchResult);
    }
  }

  /// Asks the amount of [item] on the eat page, whose button adds the food
  /// to the list instead of logging it. A food found by search has no stock
  /// yet, so its amount is open.
  static Future<InventoryItemEatRequest?> _askAmount(
    BuildContext context,
    InventoryItem item,
    InventoryReceiptManualProductResult? searchResult,
  ) async {
    final confirmLabel = AppLocalizations.of(context)!.eatPageCombineAddFood;
    if (searchResult == null) {
      final result = await showInventoryItemEatSheetResult(
        context: context,
        item: item,
        confirmLabel: confirmLabel,
      );
      return result?.request;
    }
    final selected = inventoryManualAddEatRequestFromSelection(
      searchResult.eatSelection,
    );
    if (selected != null) {
      return selected;
    }
    final result = await showInventoryItemEatSheetResult(
      context: context,
      item: item,
      initialInventoryAmount: resolveInventoryManualAddInitialConsumedAmount(
        item: item,
        rawWeight: item.weight,
      ),
      hasOpenStock: true,
      confirmLabel: confirmLabel,
    );
    return result?.request;
  }
}

const _rulerStep = 5.0;
