import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/meal_log_time_row.dart';
import 'package:yamt/core/widgets/nutrition_profile_card.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_ai_nutrition_selection.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_action_selector.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_ai_search_page/product_ai_density_adjust_card.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_ai_search_page/product_ai_headline_card.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_ai_search_page/product_ai_ingredient_table.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Body for the AI manual product search page.
class ManualProductAiSearchBody extends StatelessWidget {
  /// Creates an AI manual product search body.
  const new({
    required this.draft,
    required this.selection,
    required this.errorText,
    required this.weightController,
    required this.weightErrorText,
    required this.selectedAction,
    required this.showEatImmediatelyOption,
    required this.loggedAt,
    required this.today,
    required this.selectedMealType,
    required this.onActionChanged,
    required this.onDayPicked,
    required this.onMealTypeSelected,
    required this.onWeightChanged,
    required this.onPer100KcalChanged,
    required this.onSave,
    this.quickEatConfig = InventoryManualAddQuickEatConfig.standard,
    super.key,
  });

  /// Quick-eat settings.
  final InventoryManualAddQuickEatConfig quickEatConfig;

  /// Current AI draft.
  final ProductAiSearchDraft? draft;

  /// Resolved nutrition selection.
  final ProductAiNutritionSelection? selection;

  /// Error message shown above generated content.
  final String? errorText;

  /// Weight text controller.
  final TextEditingController weightController;

  /// Weight field error text.
  final String? weightErrorText;

  /// Selected completion action.
  final InventoryReceiptManualProductAction selectedAction;

  /// Whether eat-now is available.
  final bool showEatImmediatelyOption;

  /// When the food is logged.
  final DateTime loggedAt;

  /// The current day.
  final DateTime today;

  /// Selected meal type.
  final MealType selectedMealType;

  /// Called when action changes.
  final ValueChanged<InventoryReceiptManualProductAction> onActionChanged;

  /// Called with the picked day.
  final ValueChanged<DateTime> onDayPicked;

  /// Called when meal type changes.
  final ValueChanged<MealType> onMealTypeSelected;

  /// Called when weight changes.
  final ValueChanged<String> onWeightChanged;

  /// Called when kcal density changes.
  final ValueChanged<double> onPer100KcalChanged;

  /// Saves generated item.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final resolvedDraft = draft;
    final resolvedSelection = selection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventoryManualAddAiSearchReadOnlyHint,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (errorText case final String message) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.error),
          ),
        ],
        if (resolvedDraft != null && resolvedSelection != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AiHeadlineCard(draft: resolvedDraft),
          const SizedBox(height: AppSpacing.lg),
          AiDensityAdjustCard(
            selection: resolvedSelection,
            onChanged: onPer100KcalChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          NutritionProfileCard(
            title: l10n.inventoryManualAddAiSearchPer100CardTitle,
            kcal: resolvedSelection.per100Kcal,
            kcalUnitLabel: l10n.caloriesUnitKcal,
            protein: resolvedSelection.per100Nutrition.per100Protein,
            carbs: resolvedSelection.per100Nutrition.per100Carbs,
            fat: resolvedSelection.per100Nutrition.per100Fat,
            proteinLabel: l10n.caloriesProteinLabel,
            carbsLabel: l10n.inventoryNutritionCarbsShortLabel,
            fatLabel: l10n.caloriesFatLabel,
            accentColor: colors.tertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          NutritionProfileCard(
            title: l10n.inventoryManualAddAiSearchPortionCardTitle,
            titleColor: colors.primary,
            kcal: resolvedSelection.portionNutrition.kcal,
            kcalUnitLabel: l10n.caloriesUnitKcal,
            protein: resolvedSelection.portionNutrition.protein,
            carbs: resolvedSelection.portionNutrition.carbs,
            fat: resolvedSelection.portionNutrition.fat,
            proteinLabel: l10n.caloriesProteinLabel,
            carbsLabel: l10n.inventoryNutritionCarbsShortLabel,
            fatLabel: l10n.caloriesFatLabel,
            accentColor: colors.primary,
            trailing: AiWeightField(
              controller: weightController,
              errorText: weightErrorText,
              labelText: l10n.inventoryManualAddAiSearchWeightLabel,
              onChanged: onWeightChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AiIngredientTable(draft: resolvedDraft),
          const SizedBox(height: AppSpacing.lg),
          if (showEatImmediatelyOption && !quickEatConfig.quickEatOnly) ...[
            ManualProductActionSelector(
              selectedAction: selectedAction,
              onChanged: onActionChanged,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (showEatImmediatelyOption &&
              selectedAction == InventoryReceiptManualProductAction.eatNow) ...[
            MealLogTimeRow(
              loggedAt: loggedAt,
              today: today,
              mealType: selectedMealType,
              onDayPicked: onDayPicked,
              onMealTypeChanged: onMealTypeSelected,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('manual_product_ai_save_button'),
              onPressed: onSave,
              icon: Icon(
                selectedAction ==
                        InventoryReceiptManualProductAction.addToInventory
                    ? Icons.inventory_2_outlined
                    : Icons.restaurant_outlined,
              ),
              label: Text(
                selectedAction ==
                        InventoryReceiptManualProductAction.addToInventory
                    ? l10n.inventoryManualAddResultActionInventory
                    : l10n.inventoryManualAddResultActionEat,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
