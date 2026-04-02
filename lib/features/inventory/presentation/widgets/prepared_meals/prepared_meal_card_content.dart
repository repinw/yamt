part of 'prepared_meal_card.dart';

class _PreparedMealCardHeader extends StatelessWidget {
  const _PreparedMealCardHeader({
    required this.meal,
    required this.imageBytes,
    required this.ingredientCount,
    required this.canEat,
    required this.actionColors,
    required this.enabled,
    required this.onTap,
    required this.onEatPressed,
  });

  final PreparedMeal meal;
  final Uint8List? imageBytes;
  final int ingredientCount;
  final bool canEat;
  final AppInventoryEatActionColors actionColors;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onEatPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PreparedMealCover(
                  label: meal.name,
                  imageBytes: imageBytes,
                  imageUrl: meal.imageUrl,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        meal.hasPendingRecipeIngredients
                            ? '${l10n.preparedMealIngredientsCount(ingredientCount)} • '
                                  '${l10n.preparedMealIncompleteLabel}'
                            : l10n.preparedMealIngredientsCount(
                                ingredientCount,
                              ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          l10n.preparedMealPortionsRemaining(
                            meal.remainingPortions,
                            meal.totalPortions,
                          ),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PreparedMealPrimaryActionButton(
                      label: l10n.inventoryItemEatAction,
                      onPressed: canEat ? onEatPressed : null,
                      actionColors: actionColors,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: LinearProgressIndicator(
                      value: meal.remainingRatio,
                      minHeight: 10,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${meal.totalKcal.toStringAsFixed(0)} '
                  '${l10n.caloriesUnitKcal}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparedMealCardExpandedContent extends StatelessWidget {
  const _PreparedMealCardExpandedContent({
    required this.meal,
    required this.inventoryItems,
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
  final ColorScheme colors;
  final bool isWorking;
  final bool enabled;
  final List<InventoryNutritionMetric> nutritionMetrics;
  final List<_PreparedMealDisplayMode> availableDisplayModes;
  final _PreparedMealDisplayMode selectedDisplayMode;
  final String priceLabel;
  final String priceValue;
  final ValueChanged<_PreparedMealDisplayMode> onModeChanged;
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

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nutritionMetrics.isNotEmpty) ...[
            if (availableDisplayModes.length > 1) ...[
              InventorySegmentedButtonFrame(
                child: _PreparedMealDisplayModeToggle(
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
            _PreparedMealPriceCard(label: priceLabel, value: priceValue),
            const SizedBox(height: AppSpacing.md),
          ],
          ...meal.components.map((component) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
              final suggestions = _matchingInventoryItemsForIngredient(
                ingredient: ingredient,
                inventoryItems: inventoryItems,
              ).take(3).toList(growable: false);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PreparedMealPendingIngredientRow(
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
              onPressed: isWorking || !enabled ? null : onEditPressed,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.inventoryReceiptReviewEditAction),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: isWorking || !enabled ? null : onThrowAwayPressed,
              child: Text(l10n.inventoryItemThrowAwayAction),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isWorking || !enabled ? null : onUnbundlePressed,
              child: Text(l10n.preparedMealUnbundleAction),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isWorking || !enabled ? null : onSaveTemplatePressed,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(l10n.preparedMealSaveTemplateAction),
            ),
          ),
        ],
      ),
    );
  }
}
