part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatSheetView extends StatelessWidget {
  const _InventoryItemEatSheetView({required this.data});

  final _InventoryItemEatSheetViewData data;

  @override
  Widget build(BuildContext context) {
    return InventoryEatFlowSheetScaffold(
      viewInsetsBottom: data.viewInsetsBottom,
      hero: _InventoryItemEatHero(
        itemName: data.hero.itemName,
        eyebrow: data.hero.eyebrow,
        imageUrl: data.hero.imageUrl,
      ),
      confirmActionText: data.footer.confirmActionText,
      confirmButtonKey: const Key(
        'inventory_item_amount_dialog_confirm_button',
      ),
      onConfirm: data.footer.onConfirm,
      children: [
        if (data.nutritionMetrics.isNotEmpty) ...[
          NutritionMetricsStrip(
            metrics: [
              for (final metric in data.nutritionMetrics)
                NutritionMetric(label: metric.label, value: metric.value),
            ],
            highlightedMetricIndex: 0,
            metricValueKeyPrefix: 'inventory_item_nutrition_value',
            metricLabelKeyPrefix: 'inventory_item_nutrition_label',
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        _InventoryItemEatAmountSection(data: data.amountSection),
        if (data.manualPortionSection case final manual?) ...[
          const SizedBox(height: AppSpacing.md),
          _InventoryItemEatManualSection(data: manual),
        ],
        const SizedBox(height: AppSpacing.xxxl),
        _InventoryItemEatWhenSection(data: data.whenSection),
        if (data.inedibleSection case final inedible?) ...[
          const SizedBox(height: AppSpacing.xxxl),
          _InventoryItemEatInedibleAmountSection(
            amountController: inedible.controller,
            amountFocusNode: inedible.focusNode,
            amountErrorText: inedible.errorText,
            unitLabel: inedible.unitLabel,
            summaryText: inedible.summaryText,
            isExpanded: inedible.isExpanded,
            onAmountChanged: inedible.onChanged,
            onSubmitted: inedible.onSubmitted,
            onToggleExpanded: inedible.onToggleExpanded,
          ),
        ],
      ],
    );
  }
}

class _InventoryItemEatAmountSection extends StatelessWidget {
  const _InventoryItemEatAmountSection({required this.data});

  final _InventoryItemEatSheetAmountSectionData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InventoryEatFlowAmountCard(
          controller: data.controller,
          focusNode: data.focusNode,
          errorText: data.errorText,
          allowFractionalInput: data.allowFractionalInput,
          clearTooltip: data.clearTooltip,
          fieldKey: const Key('inventory_item_amount_dialog_field'),
          clearButtonKey: const Key(
            'inventory_item_amount_dialog_clear_button',
          ),
          trailing: _InventoryItemEatAmountModeSelector(data: data),
          onChanged: data.onChanged,
          onClearAndFocus: data.onClearAndFocus,
          onSubmitted: data.onSubmitted,
        ),
        if (data.quickOptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: InventoryEatFlowQuickChipScroller(
                  children: [
                    for (final option in data.quickOptions)
                      InventoryEatFlowQuickChip(
                        label: option.label,
                        isSelected: data.selectedAmount == option.value,
                        onPressed: () {
                          data.onQuickOptionSelected(option.value);
                        },
                      ),
                  ],
                ),
              ),
              if (data.totalLabel != null) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  data.totalLabel!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ] else if (data.totalLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              data.totalLabel!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InventoryItemEatManualSection extends StatelessWidget {
  const _InventoryItemEatManualSection({required this.data});

  final _InventoryItemEatSheetManualPortionSectionData data;

  @override
  Widget build(BuildContext context) {
    return _InventoryItemEatSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InventoryItemEatCardTitle(text: data.title),
          const SizedBox(height: AppSpacing.lg),
          _InventoryItemEatManualPortionSection(
            amountController: data.controller,
            amountFocusNode: data.focusNode,
            amountErrorText: data.errorText,
            selectedUnit: data.selectedUnit,
            onAmountChanged: data.onAmountChanged,
            onUnitChanged: data.onUnitChanged,
            onSubmitted: data.onSubmitted,
          ),
          if (data.suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            InventoryEatFlowQuickChipScroller(
              children: [
                for (final suggestion in data.suggestions)
                  InventoryEatFlowQuickChip(
                    label: suggestion.label,
                    isSelected:
                        data.selectedUnit == suggestion.unit &&
                        data.controller.text.trim() ==
                            formatInventoryNutritionValue(suggestion.amount),
                    onPressed: () => data.onSuggestionPressed(
                      amount: suggestion.amount,
                      unit: suggestion.unit,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InventoryItemEatWhenSection extends StatelessWidget {
  const _InventoryItemEatWhenSection({required this.data});

  final _InventoryItemEatSheetWhenSectionData data;

  @override
  Widget build(BuildContext context) {
    return InventoryEatFlowWhenSection(
      isToday: data.isToday,
      label: data.label,
      selectedMealType: data.selectedMealType,
      loggedAtButtonKey: const Key('inventory_item_logged_at_button'),
      loggedAtCompactKey: const Key('inventory_item_logged_at_compact'),
      loggedAtLabeledKey: const Key('inventory_item_logged_at_labeled'),
      onPickLoggedAt: data.onPickLoggedAt,
      onMealTypeSelected: data.onMealTypeSelected,
    );
  }
}

class _InventoryItemEatAmountModeSelector extends StatelessWidget {
  const _InventoryItemEatAmountModeSelector({required this.data});

  final _InventoryItemEatSheetAmountSectionData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        enableFeedback: false,
        key: const Key('inventory_item_amount_mode_dropdown'),
        value: data.selectedModeId,
        isExpanded: true,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        dropdownColor: colors.surfaceContainerHigh,
        icon: Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        items: [
          for (final option in data.modeOptions)
            DropdownMenuItem<String>(
              value: option.id,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) {
          if (value == null) {
            return;
          }
          data.onModeSelected(value);
        },
      ),
    );
  }
}
