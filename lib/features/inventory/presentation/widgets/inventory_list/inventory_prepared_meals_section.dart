import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryPreparedMealsSection extends StatelessWidget {
  const InventoryPreparedMealsSection({
    super.key,
    required this.meals,
    required this.expandedPreparedMealId,
    required this.isExpanded,
    required this.subtitle,
    required this.isSelectionMode,
    required this.onShowFilters,
    required this.onToggleExpanded,
    required this.onEatPreparedMeal,
    required this.onThrowAwayPreparedMeal,
    required this.onFillPendingPreparedMealIngredient,
    required this.onIgnorePendingPreparedMealIngredient,
    required this.onUnbundlePreparedMeal,
    required this.onEditPreparedMeal,
    required this.onSavePreparedMealTemplate,
    required this.l10n,
  });

  final List<PreparedMeal> meals;
  final String? expandedPreparedMealId;
  final bool isExpanded;
  final String subtitle;
  final bool isSelectionMode;
  final VoidCallback onShowFilters;
  final VoidCallback onToggleExpanded;
  final Future<bool> Function({
    required String mealId,
    required int portions,
    required MealType mealType,
    required DateTime loggedDay,
  })
  onEatPreparedMeal;
  final Future<bool> Function(
    String mealId,
    int portions,
    InventoryDiscardReason reason,
  )
  onThrowAwayPreparedMeal;
  final Future<bool> Function(
    String mealId,
    String ingredient,
    List<String> inventoryItemIds,
  )
  onFillPendingPreparedMealIngredient;
  final Future<bool> Function(String mealId, String ingredient)
  onIgnorePendingPreparedMealIngredient;
  final Future<bool> Function(String mealId) onUnbundlePreparedMeal;
  final Future<bool> Function(
    String mealId,
    String name,
    bool imageChanged,
    Uint8List? imageBytes,
  )
  onEditPreparedMeal;
  final Future<bool> Function(PreparedMeal meal) onSavePreparedMealTemplate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = isExpanded && meals.isNotEmpty
        ? AppSpacing.lg
        : AppSpacing.sm;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        bottomPadding,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InventorySectionHeader(
              title: l10n.preparedMealSectionTitle,
              subtitle: subtitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InventoryFilterButton(
                    key: const Key('prepared_meals_filter_button'),
                    enabled: !isSelectionMode,
                    tooltip: l10n.preparedMealFilterAction,
                    onPressed: onShowFilters,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InventorySectionExpandButton(
                    key: const Key('prepared_meals_section_expand_button'),
                    isExpanded: isExpanded,
                    semanticLabel: l10n.preparedMealSectionTitle,
                    enabled: !isSelectionMode,
                    rotationKey: const Key(
                      'prepared_meals_section_expand_indicator',
                    ),
                    onPressed: onToggleExpanded,
                  ),
                ],
              ),
            ),
            if (isExpanded && meals.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...meals.map((meal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: PreparedMealCard(
                    key: ValueKey(meal.id),
                    meal: meal,
                    initiallyExpanded: meal.id == expandedPreparedMealId,
                    enabled: !isSelectionMode,
                    onEatPressed: onEatPreparedMeal,
                    onThrowAwayPressed: onThrowAwayPreparedMeal,
                    onFillPendingIngredientPressed:
                        onFillPendingPreparedMealIngredient,
                    onIgnorePendingIngredientPressed:
                        onIgnorePendingPreparedMealIngredient,
                    onUnbundlePressed: onUnbundlePreparedMeal,
                    onEditPressed: onEditPreparedMeal,
                    onSaveTemplatePressed: onSavePreparedMealTemplate,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
