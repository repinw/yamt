part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatSheetView extends StatelessWidget {
  const _InventoryItemEatSheetView({required this.data});

  final _InventoryItemEatSheetViewData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: data.viewInsetsBottom + AppSpacing.xxxl,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppInventoryEditorial.cardRadius,
              ),
              child: DecoratedBox(
                decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
                  colors,
                  borderRadius: BorderRadius.circular(
                    AppInventoryEditorial.cardRadius,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _InventoryItemEatHero(
                              itemName: data.hero.itemName,
                              eyebrow: data.hero.eyebrow,
                              imageUrl: data.hero.imageUrl,
                            ),
                            Padding(
                              padding: AppInsets.card,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _InventoryItemEatAmountSection(
                                    data: data.amountSection,
                                  ),
                                  if (data.portionSection
                                      case final portion?) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    _InventoryItemEatPortionSection(
                                      data: portion,
                                    ),
                                  ],
                                  if (data.manualPortionSection
                                      case final manual?) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    _InventoryItemEatManualSection(
                                      data: manual,
                                    ),
                                  ],
                                  if (data.nutritionMetrics.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    _InventoryItemEatSectionCard(
                                      child:
                                          _InventoryItemEatNutritionMetricsRow(
                                            metrics: data.nutritionMetrics,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.xxxl),
                                  _InventoryItemEatWhenSection(
                                    data: data.whenSection,
                                  ),
                                  if (data.inedibleSection
                                      case final inedible?) ...[
                                    const SizedBox(height: AppSpacing.xxxl),
                                    _InventoryItemEatInedibleAmountSection(
                                      amountController: inedible.controller,
                                      amountFocusNode: inedible.focusNode,
                                      amountErrorText: inedible.errorText,
                                      unitLabel: inedible.unitLabel,
                                      onAmountChanged: inedible.onChanged,
                                      onSubmitted: inedible.onSubmitted,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        border: Border(
                          top: BorderSide(
                            color: AppInventoryEditorialSurfaces.ghostBorder(
                              colors,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.lg,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key(
                              'inventory_item_amount_dialog_confirm_button',
                            ),
                            onPressed: data.footer.onConfirm,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xxl,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                              ),
                              backgroundColor: colors.primary,
                            ),
                            child: Text(
                              data.footer.confirmActionText,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryItemEatPortionSection extends StatelessWidget {
  const _InventoryItemEatPortionSection({required this.data});

  final _InventoryItemEatSheetPortionSectionData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return _InventoryItemEatSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: const Key('inventory_item_portion_mode_switch'),
            value: data.isEnabled,
            onChanged: data.onEnabledChanged,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: _InventoryItemEatCardTitle(text: data.title),
            subtitle: Text(data.usePortionsLabel),
          ),
          if (data.isEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('inventory_item_portion_label_field'),
              controller: data.labelController,
              focusNode: data.labelFocusNode,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: data.labelFieldLabel),
              onChanged: data.onLabelChanged,
              onSubmitted: (_) => data.onSubmitted(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                IconButton(
                  key: const Key('inventory_item_portion_decrement_button'),
                  tooltip: data.decrementTooltip,
                  onPressed: () => data.onCountStep(-1),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('inventory_item_portion_count_field'),
                    controller: data.countController,
                    focusNode: data.countFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: data.countFieldLabel,
                      errorText: data.countErrorText,
                    ),
                    onChanged: data.onCountChanged,
                    onSubmitted: (_) => data.onSubmitted(),
                  ),
                ),
                IconButton(
                  key: const Key('inventory_item_portion_increment_button'),
                  tooltip: data.incrementTooltip,
                  onPressed: () => data.onCountStep(1),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('inventory_item_portion_amount_field'),
              controller: data.amountController,
              focusNode: data.amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: data.amountFieldLabel,
                errorText: data.amountErrorText,
              ),
              onChanged: data.onAmountChanged,
              onSubmitted: (_) => data.onSubmitted(),
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<ConsumedUnit>(
              segments: [
                for (final unit in data.availableUnits)
                  ButtonSegment<ConsumedUnit>(
                    value: unit,
                    label: Text(unit.localizedName(l10n)),
                  ),
              ],
              selected: {data.selectedUnit},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                data.onUnitChanged(selection.first);
              },
              showSelectedIcon: false,
            ),
            if (data.totalLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                data.totalLabel!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (data.suggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _InventoryItemEatQuickChipScroller(
                children: [
                  for (final suggestion in data.suggestions)
                    _InventoryItemEatQuickChip(
                      label: suggestion.label,
                      isSelected:
                          data.selectedUnit == suggestion.unit &&
                          data.amountController.text.trim() ==
                              formatInventoryNutritionValue(
                                suggestion.amount,
                              ),
                      onPressed: () => data.onSuggestionPressed(
                        amount: suggestion.amount,
                        unit: suggestion.unit,
                        portionLabel: suggestion.portionLabel,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InventoryItemEatAmountSection extends StatelessWidget {
  const _InventoryItemEatAmountSection({required this.data});

  final _InventoryItemEatSheetAmountSectionData data;

  @override
  Widget build(BuildContext context) {
    return _InventoryItemEatSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InventoryItemEatCardTitle(text: data.label),
          const SizedBox(height: AppSpacing.lg),
          _InventoryItemEatAmountCard(
            controller: data.controller,
            focusNode: data.focusNode,
            unitLabel: data.unitLabel,
            errorText: data.errorText,
            allowFractionalInput: data.allowFractionalInput,
            clearTooltip: data.clearTooltip,
            onChanged: data.onChanged,
            onClearAndFocus: data.onClearAndFocus,
            onSubmitted: data.onSubmitted,
          ),
          if (data.quickOptions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _InventoryItemEatQuickChipScroller(
              children: [
                for (final option in data.quickOptions)
                  _InventoryItemEatQuickChip(
                    label: option.label,
                    isSelected: data.selectedAmount == option.value,
                    onPressed: () => data.onQuickOptionSelected(option.value),
                  ),
              ],
            ),
          ],
        ],
      ),
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
            _InventoryItemEatQuickChipScroller(
              children: [
                for (final suggestion in data.suggestions)
                  _InventoryItemEatQuickChip(
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
    return Row(
      children: [
        if (data.isToday)
          _InventoryItemEatWhenCard(
            label: data.label,
            isToday: data.isToday,
            onPressed: data.onPickLoggedAt,
          )
        else
          Expanded(
            child: _InventoryItemEatWhenCard(
              label: data.label,
              isToday: data.isToday,
              onPressed: data.onPickLoggedAt,
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _InventoryItemEatMealTypeSelector(
            selectedMealType: data.selectedMealType,
            onMealTypeSelected: data.onMealTypeSelected,
          ),
        ),
      ],
    );
  }
}
