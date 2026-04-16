part of 'inventory_item_eat_sheet.dart';

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
                  border: Border.all(
                    color: AppInventoryEditorialSurfaces.ghostBorder(colors),
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
    required this.onAmountChanged,
    required this.onSubmitted,
  });

  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String? amountErrorText;
  final String unitLabel;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return _InventoryItemEatSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      l10n.inventoryItemEatSheetInedibleAmountHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const Key('inventory_item_inedible_amount_dialog_field'),
            controller: amountController,
            focusNode: amountFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      ),
    );
  }
}
