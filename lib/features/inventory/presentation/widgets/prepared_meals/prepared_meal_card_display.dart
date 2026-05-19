// Internal split file. Public names are imported only by sibling widgets.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart'
    show InventoryAmountUnit, formatInventoryAmountValue;
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_segmented_button_style.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum PreparedMealDisplayMode { perHundred, perPortion, total }

class PreparedMealDisplayModeToggle extends StatelessWidget {
  const PreparedMealDisplayModeToggle({
    required this.selectedMode,
    required this.availableModes,
    required this.onModeChanged,
  });

  final PreparedMealDisplayMode selectedMode;
  final List<PreparedMealDisplayMode> availableModes;
  final ValueChanged<PreparedMealDisplayMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<PreparedMealDisplayMode>(
      expandedInsets: AppInsets.zero,
      showSelectedIcon: false,
      style: inventorySegmentedButtonStyle(context),
      segments: [
        for (final mode in availableModes)
          ButtonSegment<PreparedMealDisplayMode>(
            value: mode,
            label: Text(_displayModeLabel(l10n, mode)),
          ),
      ],
      selected: <PreparedMealDisplayMode>{selectedMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        onModeChanged(selection.first);
      },
    );
  }
}

class PreparedMealPrimaryActionButton extends StatelessWidget {
  const PreparedMealPrimaryActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InventoryPrimaryActionButton(
      tooltip: label,
      onPressed: onPressed,
      showText: true,
      label: label,
      width: AppInventoryClosedTile.actionWidth,
      height: AppInventoryClosedTile.actionHeight,
      enabledBackgroundColor: colors.primary,
      disabledBackgroundColor: AppEditorialSurfaces.section(colors),
      enabledBorderColor: colors.primary,
      disabledBorderColor: AppEditorialSurfaces.ghostBorder(colors),
      enabledForegroundColor: colors.onPrimary,
      disabledForegroundColor: colors.onSurfaceVariant,
      useGradientWhenShowText: false,
      borderRadius: AppRadius.lg,
    );
  }
}

class PreparedMealPriceCard extends StatelessWidget {
  const PreparedMealPriceCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = Color.alphaBlend(
      colors.secondary.withValues(alpha: 0.05),
      colors.surfaceContainerLowest,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          InventoryItemRowConstants.nutritionStripRadius,
        ),
        border: Border.all(
          color: AppEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<PreparedMealDisplayMode> availablePreparedMealDisplayModes(
  PreparedMeal meal,
) {
  return [
    if (meal.perHundredAmountBasis != null) ...[
      PreparedMealDisplayMode.perHundred,
    ],
    if (meal.totalPortions > 0 && !_isGramTrackedPreparedMeal(meal))
      PreparedMealDisplayMode.perPortion,
    PreparedMealDisplayMode.total,
  ];
}

List<InventoryNutritionMetric> buildPreparedMealNutritionMetrics({
  required AppLocalizations l10n,
  required PreparedMeal meal,
  required PreparedMealDisplayMode mode,
}) {
  final multiplier = _resolvePreparedMealDisplayMultiplier(
    meal: meal,
    mode: mode,
  );

  return [
    InventoryNutritionMetric(
      label: l10n.inventoryNutritionCaloriesShortLabel,
      value: (meal.totalKcal * multiplier).round().toString(),
    ),
    InventoryNutritionMetric(
      label: l10n.inventoryNutritionCarbsShortLabel,
      value: '${formatInventoryNutritionValue(meal.totalCarbs * multiplier)}g',
    ),
    InventoryNutritionMetric(
      label: l10n.caloriesProteinLabel,
      value:
          '${formatInventoryNutritionValue(meal.totalProtein * multiplier)}g',
    ),
    InventoryNutritionMetric(
      label: l10n.caloriesFatLabel,
      value: '${formatInventoryNutritionValue(meal.totalFat * multiplier)}g',
    ),
  ];
}

double resolvePreparedMealPrice({
  required PreparedMeal meal,
  required PreparedMealDisplayMode mode,
}) {
  return meal.totalPrice *
      _resolvePreparedMealDisplayMultiplier(meal: meal, mode: mode);
}

double _resolvePreparedMealDisplayMultiplier({
  required PreparedMeal meal,
  required PreparedMealDisplayMode mode,
}) {
  return switch (mode) {
    PreparedMealDisplayMode.perHundred => meal.perHundredMultiplier ?? 0,
    PreparedMealDisplayMode.perPortion =>
      meal.totalPortions > 0 ? 1 / meal.totalPortions : 0,
    PreparedMealDisplayMode.total => 1,
  };
}

String _displayModeLabel(AppLocalizations l10n, PreparedMealDisplayMode mode) {
  return switch (mode) {
    PreparedMealDisplayMode.perHundred =>
      l10n.preparedMealNutritionModePerHundred,
    PreparedMealDisplayMode.perPortion =>
      l10n.preparedMealNutritionModePerPortion,
    PreparedMealDisplayMode.total => l10n.preparedMealNutritionModeTotal,
  };
}

String preparedMealPriceModeLabel({
  required AppLocalizations l10n,
  required PreparedMealDisplayMode mode,
}) {
  return switch (mode) {
    PreparedMealDisplayMode.perHundred => l10n.preparedMealPricePerHundred,
    PreparedMealDisplayMode.perPortion => l10n.preparedMealPricePerPortion,
    PreparedMealDisplayMode.total => l10n.preparedMealPriceTotal,
  };
}

String preparedMealProgressLabel({
  required AppLocalizations l10n,
  required PreparedMeal meal,
}) {
  if (_isGramTrackedPreparedMeal(meal)) {
    return '${_formatPreparedMealGramAmount(
      meal.remainingPortions,
    )} / ${_formatPreparedMealGramAmount(meal.totalPortions)}';
  }
  final portionLabel = l10n.preparedMealPortionsRemaining(
    formatPreparedMealPortions(
      meal.remainingPortions,
      localeName: l10n.localeName,
    ),
    meal.totalPortions,
  );
  final gramLabel = _preparedMealGramProgressLabel(meal);
  if (gramLabel == null) {
    return portionLabel;
  }
  return '$portionLabel · $gramLabel';
}

bool _isGramTrackedPreparedMeal(PreparedMeal meal) {
  final finalNetWeight = meal.finalNetWeight;
  return finalNetWeight != null &&
      finalNetWeight > 0 &&
      meal.totalPortions == finalNetWeight;
}

String _formatPreparedMealGramAmount(num amount) {
  return '${formatInventoryAmountValue(
    amount: amount.round(),
    unit: InventoryAmountUnit.gram,
  )}g';
}

String? _preparedMealGramProgressLabel(PreparedMeal meal) {
  final finalNetWeight = meal.finalNetWeight;
  if (finalNetWeight == null || finalNetWeight < 1) {
    return null;
  }
  final remainingNetWeight =
      meal.remainingNetWeight ??
      (meal.totalPortions < 1
          ? null
          : ((finalNetWeight * meal.remainingPortions) / meal.totalPortions)
                .round());
  if (remainingNetWeight == null) {
    return null;
  }
  return '${_formatPreparedMealGramAmount(
    remainingNetWeight,
  )} / ${_formatPreparedMealGramAmount(finalNetWeight)}';
}
