// Internal split file. Public names are imported only by sibling widgets.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_tile_header_layout.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card_display.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card_pending_ingredient.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_component_avatar.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_segmented_button_frame.dart';
import 'package:yamt/l10n/app_localizations.dart';

class PreparedMealCardHeader extends StatelessWidget {
  const PreparedMealCardHeader({
    required this.meal,
    required this.imageBytes,
    required this.ingredientCount,
    required this.isExpanded,
    required this.canEat,
    required this.enabled,
    required this.onTap,
    required this.onEatPressed,
  });

  final PreparedMeal meal;
  final Uint8List? imageBytes;
  final int ingredientCount;
  final bool isExpanded;
  final bool canEat;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onEatPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return AppInkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: InventoryTileHeaderLayout(
          leading: PreparedMealCover(
            label: meal.name,
            imageBytes: imageBytes,
            imageUrl: meal.imageUrl,
            size: AppInventoryClosedTile.imageSize,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          badgeText: l10n.preparedMealIngredientsCount(ingredientCount),
          title: meal.name,
          titleStyle:
              Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(
                fontSize: AppInventoryClosedTile.titleFontSize,
                fontWeight: FontWeight.w700,
                height: AppInventoryClosedTile.titleLineHeight,
                letterSpacing: 0,
              ),
          statusText: meal.hasPendingRecipeIngredients
              ? l10n.preparedMealIncompleteLabel
              : null,
          statusColor: meal.hasPendingRecipeIngredients ? colors.error : null,
          progressRatio: meal.remainingRatio,
          progressLabel: preparedMealProgressLabel(l10n: l10n, meal: meal),
          segmentedByUnits: false,
          totalUnits: meal.totalPortions,
          remainingUnits: meal.remainingPortions,
          action: PreparedMealPrimaryActionButton(
            label: l10n.inventoryItemEatAction,
            onPressed: canEat ? onEatPressed : null,
          ),
          isExpanded: isExpanded,
          showExpandIndicator: false,
          expandIndicatorEnabled: enabled,
          expandIndicatorKey: Key(
            'prepared_meal_card_expand_indicator_${meal.id}',
          ),
        ),
      ),
    );
  }
}

class PreparedMealCardExpandedContent extends StatelessWidget {
  const PreparedMealCardExpandedContent({
    required this.meal,
    required this.inventoryItems,
    required this.pendingIngredientSuggestions,
    required this.colors,
    required this.isWorking,
    required this.enabled,
    required this.nutritionMetrics,
    required this.availableDisplayModes,
    required this.selectedDisplayMode,
    required this.priceLabel,
    required this.priceValue,
    required this.onModeChanged,
    required this.onFillPendingIngredient,
    required this.onIgnorePendingIngredient,
    required this.onEditPressed,
    required this.onThrowAwayPressed,
    required this.onUnbundlePressed,
    required this.onSaveTemplatePressed,
    required this.hasFillPendingIngredientAction,
    required this.hasIgnorePendingIngredientAction,
  });

  final PreparedMeal meal;
  final List<InventoryItem> inventoryItems;
  final Map<String, List<InventoryItem>> pendingIngredientSuggestions;
  final ColorScheme colors;
  final bool isWorking;
  final bool enabled;
  final List<InventoryNutritionMetric> nutritionMetrics;
  final List<PreparedMealDisplayMode> availableDisplayModes;
  final PreparedMealDisplayMode selectedDisplayMode;
  final String priceLabel;
  final String priceValue;
  final ValueChanged<PreparedMealDisplayMode> onModeChanged;
  final void Function({
    required String ingredient,
    required List<InventoryItem> inventoryItems,
  })
  onFillPendingIngredient;
  final void Function(String ingredient) onIgnorePendingIngredient;
  final VoidCallback onEditPressed;
  final VoidCallback onThrowAwayPressed;
  final VoidCallback onUnbundlePressed;
  final VoidCallback onSaveTemplatePressed;
  final bool hasFillPendingIngredientAction;
  final bool hasIgnorePendingIngredientAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canRunSecondaryActions = !isWorking && enabled;
    final canThrowAway = canRunSecondaryActions && meal.remainingPortions > 0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nutritionMetrics.isNotEmpty) ...[
            if (availableDisplayModes.length > 1) ...[
              InventorySegmentedButtonFrame(
                child: PreparedMealDisplayModeToggle(
                  selectedMode: selectedDisplayMode,
                  availableModes: availableDisplayModes,
                  onModeChanged: onModeChanged,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            InventoryNutritionStrip(
              metrics: nutritionMetrics,
              colorScheme: colors,
            ),
            const SizedBox(height: AppSpacing.sm),
            PreparedMealPriceCard(label: priceLabel, value: priceValue),
            const SizedBox(height: AppSpacing.md),
          ],
          ...meal.components.map((component) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  PreparedMealComponentAvatar(
                    key: Key(
                      'prepared_meal_ingredient_avatar_'
                      '${component.inventoryItemId}',
                    ),
                    label: component.name,
                    imageUrl: component.imageUrl,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(component.name)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${component.usedAmount} ${component.usedUnit.code}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (meal.hasPendingRecipeIngredients) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.preparedMealIncompleteHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            ...meal.pendingRecipeIngredients.map((ingredient) {
              final suggestions =
                  pendingIngredientSuggestions[ingredient] ??
                  const <InventoryItem>[];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: PreparedMealPendingIngredientRow(
                  ingredient: ingredient,
                  suggestions: suggestions,
                  onAssignPressed:
                      !isWorking && enabled && hasFillPendingIngredientAction
                      ? () => onFillPendingIngredient(
                          ingredient: ingredient,
                          inventoryItems: inventoryItems,
                        )
                      : null,
                  onIgnorePressed:
                      !isWorking && enabled && hasIgnorePendingIngredientAction
                      ? () => onIgnorePendingIngredient(ingredient)
                      : null,
                ),
              );
            }),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canRunSecondaryActions ? onEditPressed : null,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.inventoryReceiptReviewEditAction),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: canThrowAway ? onThrowAwayPressed : null,
              child: Text(l10n.inventoryItemThrowAwayAction),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: canRunSecondaryActions ? onUnbundlePressed : null,
              child: Text(l10n.preparedMealUnbundleAction),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canRunSecondaryActions ? onSaveTemplatePressed : null,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(l10n.preparedMealSaveTemplateAction),
            ),
          ),
        ],
      ),
    );
  }
}
