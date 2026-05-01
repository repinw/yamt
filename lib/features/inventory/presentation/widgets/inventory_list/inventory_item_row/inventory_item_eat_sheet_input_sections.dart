part of 'inventory_item_eat_sheet.dart';

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
                    const InventoryEatFlowLeadingIcon(
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
