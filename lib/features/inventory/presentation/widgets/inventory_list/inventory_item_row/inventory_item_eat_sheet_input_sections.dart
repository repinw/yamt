part of 'inventory_item_eat_sheet.dart';

class _InventoryItemEatAmountCard extends StatelessWidget {
  const _InventoryItemEatAmountCard({
    required this.controller,
    required this.focusNode,
    required this.modeOptions,
    required this.selectedModeId,
    required this.errorText,
    required this.allowFractionalInput,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClearAndFocus,
    required this.onSubmitted,
    required this.onModeSelected,
  });

  static const _amountFieldWidth = 100.0;

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<_InventoryItemEatAmountModeOption> modeOptions;
  final String selectedModeId;
  final String? errorText;
  final bool allowFractionalInput;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearAndFocus;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: colors.primary.withValues(
                alpha: focusNode.hasFocus ? 0.72 : 0.28,
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Row(
              children: [
                SizedBox(
                  width: _amountFieldWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.lg,
                    ),
                    child: TextField(
                      key: const Key('inventory_item_amount_dialog_field'),
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: allowFractionalInput,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        isCollapsed: true,
                      ),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmitted(),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 64,
                  color: AppInventoryEditorialSurfaces.ghostBorder(colors),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.md,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const Key(
                          'inventory_item_amount_mode_dropdown',
                        ),
                        value: selectedModeId,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        dropdownColor: colors.surfaceContainerHigh,
                        icon: Icon(
                          Icons.expand_more_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                        items: [
                          for (final option in modeOptions)
                            DropdownMenuItem<String>(
                              value: option.id,
                              child: Text(
                                option.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          onModeSelected(value);
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('inventory_item_amount_dialog_clear_button'),
                  tooltip: clearTooltip,
                  onPressed: onClearAndFocus,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded),
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
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
    required this.onSubmitted,
  });

  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String? amountErrorText;
  final ConsumedUnit selectedUnit;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<ConsumedUnit> onUnitChanged;
  final VoidCallback onSubmitted;

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
          onSubmitted: (_) => onSubmitted(),
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

class _InventoryItemEatInedibleAmountSection extends StatelessWidget {
  const _InventoryItemEatInedibleAmountSection({
    required this.amountController,
    required this.amountFocusNode,
    required this.amountErrorText,
    required this.unitLabel,
    required this.summaryText,
    required this.isExpanded,
    required this.onAmountChanged,
    required this.onSubmitted,
    required this.onToggleExpanded,
  });

  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String? amountErrorText;
  final String unitLabel;
  final String summaryText;
  final bool isExpanded;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return _InventoryItemEatSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('inventory_item_inedible_amount_toggle'),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    const _InventoryItemEatLeadingIcon(
                      icon: Icons.info_outline_rounded,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InventoryItemEatCardTitle(
                            text: l10n.inventoryItemEatSheetInedibleAmountLabel,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            summaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('inventory_item_inedible_amount_dialog_field'),
              controller: amountController,
              focusNode: amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.inventoryItemEatSheetInedibleAmountFieldLabel,
                suffixText: unitLabel,
                errorText: amountErrorText,
              ),
              onChanged: onAmountChanged,
              onSubmitted: (_) => onSubmitted(),
            ),
          ],
        ],
      ),
    );
  }
}
