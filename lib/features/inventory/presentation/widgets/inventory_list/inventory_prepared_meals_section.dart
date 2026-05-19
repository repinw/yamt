import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Callback used to eat a prepared meal.
typedef PreparedMealEatCallback =
    Future<bool> Function({
      required String mealId,
      required num portions,
      required MealType mealType,
      required DateTime loggedDay,
    });

/// Callback used to discard prepared meal portions.
typedef PreparedMealDiscardCallback =
    Future<bool> Function(
      String mealId,
      num portions,
      InventoryDiscardReason reason,
    );

/// Callback used to fill a pending prepared meal ingredient.
typedef PreparedMealIngredientFillCallback =
    Future<bool> Function(
      String mealId,
      String ingredient,
      List<String> inventoryItemIds,
    );

/// Callback used to ignore a pending prepared meal ingredient.
typedef PreparedMealIngredientIgnoreCallback =
    Future<bool> Function(
      String mealId,
      String ingredient,
    );

/// Callback used to mutate one prepared meal by id.
typedef PreparedMealIdCallback = Future<bool> Function(String mealId);

/// Callback used to edit prepared meal metadata.
typedef PreparedMealEditCallback =
    Future<bool> Function(String mealId, PreparedMealEditSheetResult result);

/// Callback used to select more ingredients for an active meal edit.
typedef PreparedMealEditIngredientSelectionCallback =
    Future<bool> Function(String mealId, PreparedMealEditSheetResult result);

/// Callback used to save a prepared meal as a template.
typedef PreparedMealSaveTemplateCallback =
    Future<bool> Function(
      PreparedMeal meal,
    );

/// Actions used by [InventoryPreparedMealsSection].
class PreparedMealSectionActions {
  /// Creates prepared meal section actions.
  const PreparedMealSectionActions({
    required this.onEatPreparedMeal,
    required this.onThrowAwayPreparedMeal,
    required this.onFillPendingPreparedMealIngredient,
    required this.onIgnorePendingPreparedMealIngredient,
    required this.onUnbundlePreparedMeal,
    required this.onEditPreparedMeal,
    required this.onSelectPreparedMealEditIngredients,
    required this.onSavePreparedMealTemplate,
  });

  /// The on eat prepared meal.
  final PreparedMealEatCallback onEatPreparedMeal;

  /// The on throw away prepared meal.
  final PreparedMealDiscardCallback onThrowAwayPreparedMeal;

  /// The on fill pending prepared meal ingredient.
  final PreparedMealIngredientFillCallback onFillPendingPreparedMealIngredient;

  /// The on ignore pending prepared meal ingredient.
  final PreparedMealIngredientIgnoreCallback
  onIgnorePendingPreparedMealIngredient;

  /// The on unbundle prepared meal.
  final PreparedMealIdCallback onUnbundlePreparedMeal;

  /// The on edit prepared meal.
  final PreparedMealEditCallback onEditPreparedMeal;

  /// The on select prepared meal edit ingredients.
  final PreparedMealEditIngredientSelectionCallback
  onSelectPreparedMealEditIngredients;

  /// The on save prepared meal template.
  final PreparedMealSaveTemplateCallback onSavePreparedMealTemplate;
}

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
    required this.actions,
    required this.onShowFilters,
    required this.onToggleExpanded,
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

  /// Prepared meal section actions.
  final PreparedMealSectionActions actions;

  /// The on show filters.
  final VoidCallback onShowFilters;

  /// The on toggle expanded.
  final VoidCallback onToggleExpanded;

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
                    onEatPressed: actions.onEatPreparedMeal,
                    onThrowAwayPressed: actions.onThrowAwayPreparedMeal,
                    onFillPendingIngredientPressed:
                        actions.onFillPendingPreparedMealIngredient,
                    onIgnorePendingIngredientPressed:
                        actions.onIgnorePendingPreparedMealIngredient,
                    onUnbundlePressed: actions.onUnbundlePreparedMeal,
                    onEditPressed: actions.onEditPreparedMeal,
                    onSelectEditIngredientsPressed:
                        actions.onSelectPreparedMealEditIngredients,
                    onSaveTemplatePressed: actions.onSavePreparedMealTemplate,
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
