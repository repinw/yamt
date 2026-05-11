part of 'product_ai_search_page.dart';

class _ManualProductAiSearchBody extends ConsumerWidget {
  const _ManualProductAiSearchBody({
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
  });

  final ProductAiSearchDraft? draft;
  final _AiNutritionSelection? selection;
  final String? errorText;
  final TextEditingController weightController;
  final String? weightErrorText;
  final InventoryReceiptManualProductAction selectedAction;
  final bool showEatImmediatelyOption;
  final bool isLoggedAtToday;
  final String? loggedAtLabel;
  final MealType selectedMealType;
  final ValueChanged<InventoryReceiptManualProductAction> onActionChanged;
  final VoidCallback onPickLoggedAt;
  final ValueChanged<MealType> onMealTypeSelected;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<double> onPer100KcalChanged;
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
          _AiHeadlineCard(draft: resolvedDraft),
          const SizedBox(height: AppSpacing.lg),
          _AiDensityAdjustCard(
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
            trailing: _AiWeightField(
              controller: weightController,
              errorText: weightErrorText,
              labelText: l10n.inventoryManualAddAiSearchWeightLabel,
              onChanged: onWeightChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AiIngredientTable(draft: resolvedDraft),
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
            _AiEatWhenSection(
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

class _AiEatWhenSection extends StatelessWidget {
  const _AiEatWhenSection({
    required this.isToday,
    required this.label,
    required this.selectedMealType,
    required this.onPickLoggedAt,
    required this.onMealTypeSelected,
  });

  final bool isToday;
  final String? label;
  final MealType selectedMealType;
  final VoidCallback onPickLoggedAt;
  final ValueChanged<MealType> onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isToday)
          _AiEatWhenCard(
            label: label,
            isToday: isToday,
            onPressed: onPickLoggedAt,
          )
        else
          Expanded(
            child: _AiEatWhenCard(
              label: label,
              isToday: isToday,
              onPressed: onPickLoggedAt,
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AiMealTypeSelector(
            selectedMealType: selectedMealType,
            onMealTypeSelected: onMealTypeSelected,
          ),
        ),
      ],
    );
  }
}

class _AiEatWhenCard extends StatelessWidget {
  const _AiEatWhenCard({
    required this.label,
    required this.isToday,
    required this.onPressed,
  });

  final String? label;
  final bool isToday;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasLabel = !isToday && label != null;

    return Material(
      color: Colors.transparent,
      child: AppInkWell(
        key: const Key('manual_product_ai_logged_at_button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: hasLabel
                  ? Row(
                      key: const Key('manual_product_ai_logged_at_labeled'),
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            label!,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    )
                  : Row(
                      key: const Key('manual_product_ai_logged_at_compact'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiMealTypeSelector extends StatelessWidget {
  const _AiMealTypeSelector({
    required this.selectedMealType,
    required this.onMealTypeSelected,
  });

  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_rounded, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: AppDropdownButton<MealType>(
                value: selectedMealType,
                isDense: true,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                dropdownColor: colors.surfaceContainerHigh,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: colors.onSurfaceVariant,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                items: MealType.sectionOrder
                    .map((mealType) {
                      return DropdownMenuItem<MealType>(
                        value: mealType,
                        child: Text(
                          _manualProductAiMealTypeLabel(context, mealType),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  onMealTypeSelected(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _manualProductAiMealTypeLabel(BuildContext context, MealType mealType) {
  final l10n = AppLocalizations.of(context)!;
  return switch (mealType) {
    MealType.breakfast => l10n.caloriesMealBreakfast,
    MealType.lunch => l10n.caloriesMealLunch,
    MealType.dinner => l10n.caloriesMealDinner,
    MealType.snack => l10n.caloriesMealSnack,
  };
}

class _AiHeadlineCard extends StatelessWidget {
  const _AiHeadlineCard({required this.draft});

  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const Key('manual_product_ai_result_card'),
      width: double.infinity,
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (draft.brand case final String brand) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              brand,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _AiMetaWrap(
            labels: <String>[
              draft.totalWeightLabel,
              draft.totalKcalRangeLabel,
              '${formatManualProductDouble(draft.defaultKcal)} kcal',
            ],
          ),
        ],
      ),
    );
  }
}

class _AiDensityAdjustCard extends StatelessWidget {
  const _AiDensityAdjustCard({
    required this.selection,
    required this.onChanged,
  });

  final _AiNutritionSelection selection;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryManualAddAiSearchDensityTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.inventoryManualAddAiSearchDensityHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Slider(
              key: const Key('manual_product_ai_density_slider'),
              value: selection.per100Kcal,
              min: selection.minPer100Kcal,
              max: selection.maxPer100Kcal,
              onChanged: onChanged,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.inventoryManualAddAiSearchDensityMinLabel(
                      formatManualProductDouble(selection.minPer100Kcal),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  l10n.inventoryManualAddAiSearchDensityBaseLabel(
                    formatManualProductDouble(selection.basePer100Kcal),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.inventoryManualAddAiSearchDensityMaxLabel(
                      formatManualProductDouble(selection.maxPer100Kcal),
                    ),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AiWeightField extends StatelessWidget {
  const _AiWeightField({
    required this.controller,
    required this.errorText,
    required this.labelText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final String labelText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: TextField(
        key: const Key('manual_product_ai_weight_field'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          manualProductSingleDecimalInputFormatter,
        ],
        textAlign: TextAlign.end,
        decoration: InputDecoration(
          isDense: true,
          labelText: labelText,
          suffixText: 'g',
          errorText: errorText,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _AiMetaWrap extends StatelessWidget {
  const _AiMetaWrap({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final label in labels)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(label),
            ),
          ),
      ],
    );
  }
}

class _AiIngredientTable extends StatelessWidget {
  const _AiIngredientTable({required this.draft});

  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventoryManualAddAiSearchIngredientsTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                l10n.inventoryManualAddAiSearchAmountColumn,
                style: headerStyle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.inventoryNutritionCaloriesShortLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.caloriesProteinLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.inventoryNutritionCarbsShortLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.caloriesFatLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Divider(color: colors.outlineVariant),
        for (final ingredient in draft.ingredients) ...[
          _AiIngredientRow(ingredient: ingredient),
          const SizedBox(height: AppSpacing.sm),
        ],
        Divider(color: colors.outlineVariant),
        _AiIngredientTotalRow(draft: draft),
      ],
    );
  }
}

class _AiIngredientRow extends StatelessWidget {
  const _AiIngredientRow({required this.ingredient});

  final ProductAiSearchIngredientRow ingredient;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ingredient.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(ingredient.amountText, style: valueStyle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _buildKcalText(),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.protein),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.carbs),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.fat),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _buildKcalText() {
    if (ingredient.kcalMin == ingredient.kcalMax) {
      return formatManualProductDouble(ingredient.kcalMin);
    }
    return '${formatManualProductDouble(ingredient.kcalMin)} - '
        '${formatManualProductDouble(ingredient.kcalMax)}';
  }

  String _formatMacro(double? value) {
    if (value == null) {
      return '-';
    }
    return formatManualProductDouble(value);
  }
}

class _AiIngredientTotalRow extends StatelessWidget {
  const _AiIngredientTotalRow({required this.draft});

  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            AppLocalizations.of(context)!.inventoryManualAddAiSearchTotalLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 4,
          child: Text(draft.totalWeightLabel, style: valueStyle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Text(
            draft.totalKcalRangeLabel,
            style: valueStyle,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
