import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/nutrition_profile_card.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_ingredient_row.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Nutrition summary shown in the calorie entry details sheet.
class CalorieEntryNutritionSummaryCard extends StatelessWidget {
  /// Creates a nutrition summary card.
  const CalorieEntryNutritionSummaryCard({required this.entry, super.key});

  /// Entry whose nutrition totals are displayed.
  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NutritionProfileCard(
      key: CalorieEntryDetailKeys.nutritionStrip,
      kcal: entry.totalKcal,
      kcalUnitLabel: l10n.caloriesUnitKcal,
      carbs: entry.totalCarbs,
      protein: entry.totalProtein,
      fat: entry.totalFat,
      carbsLabel: l10n.inventoryNutritionCarbsShortLabel,
      proteinLabel: l10n.caloriesProteinLabel,
      fatLabel: l10n.caloriesFatLabel,
      accentColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Ingredient table shown for bundle calorie entries.
class CalorieEntryIngredientsSection extends StatelessWidget {
  /// Creates an ingredient section.
  const CalorieEntryIngredientsSection({required this.entry, super.key});

  /// Entry whose bundle components are displayed.
  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.preparedMealIngredientsTitle.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: DecoratedBox(
            key: CalorieEntryDetailKeys.ingredientsTable,
            decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
              colors,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              color: Color.alphaBlend(
                colors.surfaceContainerLowest.withValues(alpha: 0.96),
                colors.surface,
              ),
              blurRadius: 16,
              shadowOffset: const Offset(0, 8),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < entry.bundleComponents.length;
                  index++
                ) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppInventoryEditorialSurfaces.ghostBorder(
                        colors,
                      ).withValues(alpha: 0.9),
                    ),
                  CalorieEntryIngredientRow(
                    component: entry.bundleComponents[index],
                    index: index,
                    accentColor: AppInventoryEditorialSurfaces.ingredientAccent(
                      colors,
                      index,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
