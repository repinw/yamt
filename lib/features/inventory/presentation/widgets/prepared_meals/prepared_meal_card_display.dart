part of 'prepared_meal_card.dart';

enum _PreparedMealDisplayMode { perHundred, perPortion, total }

class _PreparedMealDisplayModeToggle extends StatelessWidget {
  const _PreparedMealDisplayModeToggle({
    required this.selectedMode,
    required this.availableModes,
    required this.onModeChanged,
  });

  final _PreparedMealDisplayMode selectedMode;
  final List<_PreparedMealDisplayMode> availableModes;
  final ValueChanged<_PreparedMealDisplayMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_PreparedMealDisplayMode>(
      expandedInsets: AppInsets.zero,
      showSelectedIcon: false,
      style: inventorySegmentedButtonStyle(context),
      segments: [
        for (final mode in availableModes)
          ButtonSegment<_PreparedMealDisplayMode>(
            value: mode,
            label: Text(_displayModeLabel(l10n, mode)),
          ),
      ],
      selected: <_PreparedMealDisplayMode>{selectedMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        onModeChanged(selection.first);
      },
    );
  }
}

class _PreparedMealPrimaryActionButton extends StatelessWidget {
  const _PreparedMealPrimaryActionButton({
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
      width: InventoryItemRowConstants.primaryActionWidth,
      height: InventoryItemRowConstants.primaryActionHeight,
      enabledBackgroundColor: colors.primary,
      disabledBackgroundColor: AppInventoryEditorialSurfaces.section(colors),
      enabledBorderColor: colors.primary,
      disabledBorderColor: AppInventoryEditorialSurfaces.ghostBorder(colors),
      enabledForegroundColor: colors.onPrimary,
      disabledForegroundColor: colors.onSurfaceVariant,
      useGradientWhenShowText: false,
    );
  }
}

class _PreparedMealPriceCard extends StatelessWidget {
  const _PreparedMealPriceCard({required this.label, required this.value});

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
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
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

List<_PreparedMealDisplayMode> _availableDisplayModes(PreparedMeal meal) {
  return [
    if (meal.perHundredAmountBasis != null) ...[
      _PreparedMealDisplayMode.perHundred,
    ],
    if (meal.totalPortions > 0) _PreparedMealDisplayMode.perPortion,
    _PreparedMealDisplayMode.total,
  ];
}

List<InventoryNutritionMetric> _buildPreparedMealNutritionMetrics({
  required AppLocalizations l10n,
  required PreparedMeal meal,
  required _PreparedMealDisplayMode mode,
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

double _resolvePreparedMealPrice({
  required PreparedMeal meal,
  required _PreparedMealDisplayMode mode,
}) {
  return meal.totalPrice *
      _resolvePreparedMealDisplayMultiplier(meal: meal, mode: mode);
}

double _resolvePreparedMealDisplayMultiplier({
  required PreparedMeal meal,
  required _PreparedMealDisplayMode mode,
}) {
  return switch (mode) {
    _PreparedMealDisplayMode.perHundred => meal.perHundredMultiplier ?? 0,
    _PreparedMealDisplayMode.perPortion =>
      meal.totalPortions > 0 ? 1 / meal.totalPortions : 0,
    _PreparedMealDisplayMode.total => 1,
  };
}

String _displayModeLabel(AppLocalizations l10n, _PreparedMealDisplayMode mode) {
  return switch (mode) {
    _PreparedMealDisplayMode.perHundred =>
      l10n.preparedMealNutritionModePerHundred,
    _PreparedMealDisplayMode.perPortion =>
      l10n.preparedMealNutritionModePerPortion,
    _PreparedMealDisplayMode.total => l10n.preparedMealNutritionModeTotal,
  };
}

String _priceModeLabel({
  required AppLocalizations l10n,
  required _PreparedMealDisplayMode mode,
}) {
  return switch (mode) {
    _PreparedMealDisplayMode.perHundred => l10n.preparedMealPricePerHundred,
    _PreparedMealDisplayMode.perPortion => l10n.preparedMealPricePerPortion,
    _PreparedMealDisplayMode.total => l10n.preparedMealPriceTotal,
  };
}
