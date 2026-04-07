part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatSheetHeader extends StatelessWidget {
  const _InventoryItemEatSheetHeader({
    required this.title,
    required this.eyebrow,
  });

  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppInventoryEditorial.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              key: const Key('inventory_item_amount_dialog_cancel_button'),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _InventoryItemEatAmountCard extends StatelessWidget {
  const _InventoryItemEatAmountCard({
    required this.controller,
    required this.focusNode,
    required this.unitLabel,
    required this.errorText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClearAndFocus,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? unitLabel;
  final String? errorText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearAndFocus;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(
                    AppInventoryEditorial.cardRadius,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                    vertical: AppSpacing.xxl,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('inventory_item_amount_dialog_field'),
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: false,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            isCollapsed: true,
                          ),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                          onChanged: onChanged,
                          onSubmitted: (_) => onSubmitted(),
                        ),
                      ),
                      if (unitLabel != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          unitLabel!,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              key: const Key('inventory_item_amount_dialog_clear_button'),
              tooltip: clearTooltip,
              onPressed: onClearAndFocus,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.cleaning_services_outlined),
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}

class _InventoryItemEatManualPortionSection extends StatelessWidget {
  const _InventoryItemEatManualPortionSection({
    required this.amountController,
    required this.amountFocusNode,
    required this.amountErrorText,
    required this.selectedUnit,
    required this.onAmountChanged,
    required this.onUnitChanged,
  });

  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String? amountErrorText;
  final ConsumedUnit selectedUnit;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<ConsumedUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: amountController,
          focusNode: amountFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.caloriesEntryAmountLabel,
            errorText: amountErrorText,
          ),
          onChanged: onAmountChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.caloriesEntryUnitLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ConsumedUnit>(
          segments: [
            ButtonSegment<ConsumedUnit>(
              value: ConsumedUnit.grams,
              label: Text(ConsumedUnit.grams.localizedName(l10n)),
            ),
            ButtonSegment<ConsumedUnit>(
              value: ConsumedUnit.milliliters,
              label: Text(ConsumedUnit.milliliters.localizedName(l10n)),
            ),
          ],
          selected: {selectedUnit},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            onUnitChanged(selection.first);
          },
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

class _InventoryItemEatWhenCard extends StatelessWidget {
  const _InventoryItemEatWhenCard({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppInventoryEditorial.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryItemEatMealTypeSelector extends StatelessWidget {
  const _InventoryItemEatMealTypeSelector({
    required this.selectedMealType,
    required this.onMealTypeSelected,
  });

  final MealType selectedMealType;
  final ValueChanged<MealType> onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.restaurant_rounded,
              color: AppInventoryEditorial.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MealType>(
                  value: selectedMealType,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
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
                          child: Text(mealType.localizedName(l10n)),
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
      ),
    );
  }
}

class _InventoryItemEatNutritionMetricsRow extends StatelessWidget {
  const _InventoryItemEatNutritionMetricsRow({required this.metrics});

  final List<({String label, String value})> metrics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          Expanded(
            child: _InventoryItemEatNutritionMetric(
              label: metrics[index].label,
              value: metrics[index].value,
            ),
          ),
          if (index < metrics.length - 1)
            Container(
              width: 1,
              height: 28,
              color: colors.surfaceContainerHighest,
            ),
        ],
      ],
    );
  }
}
