import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory prepared meals section.
@Dependencies([InventoryItemsController, preparedMealImagePicker])
class InventoryPreparedMealsSection extends StatelessWidget {
  /// The inventory prepared meals section.
  const InventoryPreparedMealsSection({
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
    super.key,
  });

  /// The meals.
  final List<PreparedMeal> meals;

  /// The expanded prepared meal id.
  final String? expandedPreparedMealId;

  /// Whether expanded.
  final bool isExpanded;

  /// The subtitle.
  final String subtitle;

  /// Whether selection mode.
  final bool isSelectionMode;

  /// The on show filters.
  final VoidCallback onShowFilters;

  /// The on toggle expanded.
  final VoidCallback onToggleExpanded;

  /// The on eat prepared meal.
  final Future<bool> Function({
    required String mealId,
    required int portions,
    required MealType mealType,
    required DateTime loggedDay,
  })
  onEatPreparedMeal;

  /// The on throw away prepared meal.
  final Future<bool> Function(
    String mealId,
    int portions,
    InventoryDiscardReason reason,
  )
  onThrowAwayPreparedMeal;

  /// The on fill pending prepared meal ingredient.
  final Future<bool> Function(
    String mealId,
    String ingredient,
    List<String> inventoryItemIds,
  )
  onFillPendingPreparedMealIngredient;

  /// The on ignore pending prepared meal ingredient.
  final Future<bool> Function(String mealId, String ingredient)
  onIgnorePendingPreparedMealIngredient;

  /// The on unbundle prepared meal.
  final Future<bool> Function(String mealId) onUnbundlePreparedMeal;

  /// The on edit prepared meal.
  final Future<bool> Function(
    String mealId,
    String name,
    // Callback mirrors PreparedMealEditSheetResult shape.
    // ignore: avoid_positional_boolean_parameters
    bool imageChanged,
    Uint8List? imageBytes,
  )
  onEditPreparedMeal;

  /// The on save prepared meal template.
  final Future<bool> Function(PreparedMeal meal) onSavePreparedMealTemplate;

  /// The l10n.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = isExpanded && meals.isNotEmpty
        ? AppSpacing.lg
        : AppSpacing.sm;
    final horizontalPadding = responsivePageHorizontalPadding(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.lg,
        horizontalPadding,
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
