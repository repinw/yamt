import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/food_estimate_level_change.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_stock_changes.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_label_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Name of a preparation [level].
String foodEstimateLevelLabel(AppLocalizations l10n, FoodEstimateLevel level) {
  return switch (level) {
    FoodEstimateLevel.lean => l10n.foodEstimateLevelLean,
    FoodEstimateLevel.normal => l10n.foodEstimateLevelNormal,
    FoodEstimateLevel.rich => l10n.foodEstimateLevelRich,
  };
}

/// Ingredient lines of [grams] of [estimate] prepared at [level].
List<EatComponentLine> foodEstimateComponents(
  AppLocalizations l10n,
  FoodEstimate estimate,
  FoodEstimateLevel level, {
  required num? grams,
}) {
  return [
    for (final ingredient in estimate.ingredientsAt(
      level,
      grams: (grams ?? 0).toDouble(),
    ))
      (
        name: ingredient.name,
        amount: eatComponentAmount(
          l10n,
          ingredient.grams.roundToDouble(),
          InventoryAmountUnit.gram,
        ),
        kcal: ingredient.kcal,
      ),
  ];
}

/// Head of the eat page of an AI food (#763): its header, the preparation
/// chips and its nutrition label. A chip saves its level on the item and
/// hands the saved item to [onSaved].
class EatFoodEstimateHeader extends ConsumerStatefulWidget {
  /// Creates the head for [item], which has an AI estimate.
  const new({
    required this.item,
    required this.enabled,
    required this.onSaving,
    required this.onSaved,
    super.key,
  });

  /// Key of the chip for [level].
  static Key levelKey(FoodEstimateLevel level) =>
      Key('eat_food_estimate_level_${level.name}');

  /// The AI food.
  final InventoryItem item;

  /// Whether a chip can save, off while the page runs something else.
  final bool enabled;

  /// Called with true when a level starts saving and with false once it is
  /// done, so the page can hold back eating at the old level meanwhile.
  final ValueChanged<bool> onSaving;

  /// Called with the item once its new level is saved.
  final ValueChanged<InventoryItem> onSaved;

  @override
  ConsumerState<EatFoodEstimateHeader> createState() =>
      _EatFoodEstimateHeaderState();
}

class _EatFoodEstimateHeaderState extends ConsumerState<EatFoodEstimateHeader> {
  // One save at a time, so the page shows the level that was saved last.
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    final current = item.productSnapshot.aiEstimate?.level;
    return InventoryItemEatLabelSection(
      item: item,
      state: ref.watch(inventoryItemEatSheetControllerProvider(item: item)),
      brand: l10n.foodEstimateOverline,
      belowHeader: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final level in FoodEstimateLevel.values)
            EatChip(
              key: EatFoodEstimateHeader.levelKey(level),
              label: foodEstimateLevelLabel(l10n, level),
              isSelected: level == current,
              onPressed: level == current || _isSaving || !widget.enabled
                  ? null
                  : () => _save(level),
            ),
        ],
      ),
    );
  }

  Future<void> _save(FoodEstimateLevel level) async {
    final item = widget.item;
    final items = ref.read(inventoryItemsControllerProvider.notifier);
    setState(() => _isSaving = true);
    widget.onSaving(true);
    final saved = await items.setFoodEstimateLevel(item.id, level);
    // Also when the head is gone, so the page does not stay blocked.
    widget.onSaving(false);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        AppLocalizations.of(context)!.inventoryItemActionFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    // The written item carries the newest stock.
    final written = findInventoryItem(
      ref.read(inventoryItemsControllerProvider).value ?? const [],
      item.id,
    );
    widget.onSaved(written ?? item.withFoodEstimateLevel(level));
  }
}

/// Ingredients of the amount of an AI food being eaten, at its level.
class EatFoodEstimateIngredients extends ConsumerWidget {
  /// Creates the list for [item], which has an AI estimate.
  const new({required this.item, super.key});

  /// The AI food.
  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = item.productSnapshot.aiEstimate!;
    // The eaten amount, without an inedible part.
    final grams = ref.watch(
      inventoryItemEatSheetControllerProvider(item: item)
          .select((state) => state.nutrition?.amount),
    );
    return EatComponentsList(
      components: foodEstimateComponents(
        AppLocalizations.of(context)!,
        saved.estimate,
        saved.level,
        grams: grams,
      ),
    );
  }
}
