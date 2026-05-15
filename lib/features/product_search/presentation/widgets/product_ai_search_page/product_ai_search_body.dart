import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/nutrition_profile_card.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/application/'
    'product_ai_nutrition_selection.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_action_selector.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_density_adjust_card.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_eat_when_section.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_headline_card.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_ingredient_table.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Body for the AI manual product search page.
@Dependencies([inventoryManualAddQuickEatConfig])
class ManualProductAiSearchBody extends ConsumerWidget {
  /// Creates an AI manual product search body.
  const ManualProductAiSearchBody({
    required this.draft,
    required this.selection,
    required this.errorText,
    required this.weightController,
    required this.weightErrorText,
    required this.selectedAction,
    required this.showEatImmediatelyOption,
    required this.isLoggedAtToday,
    required this.loggedAtLabel,
    required this.selectedMealType,
    required this.onActionChanged,
    required this.onPickLoggedAt,
    required this.onMealTypeSelected,
    required this.onWeightChanged,
    required this.onPer100KcalChanged,
    required this.onSave,
    super.key,
  });

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

  /// Whether selected eat date is today.
  final bool isLoggedAtToday;

  /// Selected eat date label.
  final String? loggedAtLabel;

  /// Selected meal type.
  final MealType selectedMealType;

  /// Called when action changes.
  final ValueChanged<InventoryReceiptManualProductAction> onActionChanged;

  /// Opens date picker.
  final VoidCallback onPickLoggedAt;

  /// Called when meal type changes.
  final ValueChanged<MealType> onMealTypeSelected;

  /// Called when weight changes.
  final ValueChanged<String> onWeightChanged;

  /// Called when kcal density changes.
  final ValueChanged<double> onPer100KcalChanged;

  /// Saves generated item.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quickEatConfig = ref.watch(
      inventoryManualAddQuickEatConfigProvider,
    );
    final colors = Theme.of(context).colorScheme;
    final resolvedDraft = draft;
    final resolvedSelection = selection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventoryManualAddAiSearchReadOnlyHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (errorText case final String message) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.error),
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
            AiEatWhenSection(
              isToday: isLoggedAtToday,
              label: loggedAtLabel,
              selectedMealType: selectedMealType,
              onPickLoggedAt: onPickLoggedAt,
              onMealTypeSelected: onMealTypeSelected,
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
