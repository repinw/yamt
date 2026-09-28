import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'inventory_item_eat_sheet_body.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows an AI food estimate on the eat page.
///
/// Pops with the chosen result, or with null to go back to the input and
/// analyze again.
class FoodEstimateResultPage extends StatefulWidget {
  /// Creates the page.
  const new({
    required this.estimate,
    required this.baseItem,
    required this.eatsNow,
    required this.description,
    required this.initialLoggedAt,
    required this.initialMealType,
    this.imageBytes,
    super.key,
  });

  /// The AI estimate.
  final FoodEstimate estimate;

  /// Item that carries the caller's household and store context.
  final InventoryItem baseItem;

  /// Whether confirming logs the food; otherwise it goes to the Vorrat.
  final bool eatsNow;

  /// The user's description, shown under the name.
  final String description;

  /// Preselected log time.
  final DateTime initialLoggedAt;

  /// Preselected meal.
  final MealType initialMealType;

  /// First photo of the food.
  final Uint8List? imageBytes;

  @override
  State<FoodEstimateResultPage> createState() => _FoodEstimateResultPageState();
}

class _FoodEstimateResultPageState extends State<FoodEstimateResultPage> {
  FoodEstimateLevel _level = FoodEstimateLevel.normal;
  late int? _grams = widget.estimate.portionGrams.round();
  late DateTime _loggedAt = widget.initialLoggedAt;
  late MealType _mealType = widget.initialMealType;

  // The eat page reads its item once, so a new level starts a new page
  // with the amount and time chosen so far.
  var _generation = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final estimate = widget.estimate;
    final description = widget.description.trim();
    return InventoryItemEatSheetBody(
      key: ValueKey(_generation),
      item: _item(estimate.portionGrams.round()),
      confirmIntent: InventoryItemEatSheetIntent.logOnly,
      confirmLabel: widget.eatsNow ? null : l10n.foodEstimateAddToStock,
      initialInventoryAmount: _grams,
      initialLoggedAt: _loggedAt,
      initialMealType: _mealType,
      hasOpenStock: true,
      headerBrand: l10n.foodEstimateOverline,
      headerCaption: description.isEmpty ? null : description,
      headerImageBytes: widget.imageBytes,
      addMoreActionText: l10n.foodEstimateReanalyze,
      onSecondary: () => Navigator.of(context).pop(),
      onSelectionChanged: (selection) => setState(() {
        _grams = selection.inventoryAmount;
        _loggedAt = selection.loggedAt;
        _mealType = selection.mealType;
      }),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xxl,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final level in FoodEstimateLevel.values)
                EatChip(
                  label: _levelLabel(l10n, level),
                  isSelected: level == _level,
                  onPressed: () => _pickLevel(level),
                ),
            ],
          ),
          EatComponentsList(
            initiallyExpanded: true,
            components: [
              for (final ingredient in estimate.ingredientsAt(
                _level,
                grams: (_grams ?? 0).toDouble(),
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
            ],
          ),
        ],
      ),
      onSubmitted: _submit,
    );
  }

  InventoryItem _item(int grams) => buildFoodEstimateItem(
    baseItem: widget.baseItem,
    estimate: widget.estimate,
    level: _level,
    grams: grams,
  );

  void _pickLevel(FoodEstimateLevel level) {
    if (level == _level) return;
    setState(() {
      _level = level;
      _generation++;
    });
  }

  void _submit(InventoryItemEatSheetResult result) {
    final request = result.request;
    final grams = request.inventoryAmount;
    Navigator.of(context).pop(
      ManualProductAiSearchResult(
        item: _item(grams),
        action: widget.eatsNow
            ? InventoryReceiptManualProductAction.eatNow
            : InventoryReceiptManualProductAction.addToInventory,
        globalPackageWeight: '$grams g',
        eatSelection: widget.eatsNow
            ? EatSelection(
                inventoryAmount: grams,
                loggedAt: request.loggedAt,
                mealType: request.mealType,
              )
            : null,
      ),
    );
  }

  static String _levelLabel(AppLocalizations l10n, FoodEstimateLevel level) {
    return switch (level) {
      FoodEstimateLevel.lean => l10n.foodEstimateLevelLean,
      FoodEstimateLevel.normal => l10n.foodEstimateLevelNormal,
      FoodEstimateLevel.rich => l10n.foodEstimateLevelRich,
    };
  }
}
