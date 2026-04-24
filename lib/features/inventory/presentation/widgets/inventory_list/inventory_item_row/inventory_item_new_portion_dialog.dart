part of 'inventory_item_eat_sheet.dart';

class _NewPortionDialog extends StatefulWidget {
  const _NewPortionDialog({
    required this.initialLabel,
    required this.initialAmount,
    required this.initialUnit,
    required this.availableUnits,
  });

  final String initialLabel;
  final String initialAmount;
  final ConsumedUnit initialUnit;
  final List<ConsumedUnit> availableUnits;

  @override
  State<_NewPortionDialog> createState() => _NewPortionDialogState();
}

class _NewPortionDialogState extends State<_NewPortionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _amountController;
  late ConsumedUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    _amountController = TextEditingController(text: widget.initialAmount);
    _selectedUnit = widget.availableUnits.contains(widget.initialUnit)
        ? widget.initialUnit
        : widget.availableUnits.first;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.inventoryItemEatSheetNewPortionTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('inventory_item_portion_label_field'),
              controller: _labelController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.inventoryItemEatSheetPortionLabelFieldLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('inventory_item_portion_amount_field'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.inventoryItemEatSheetPortionAmountFieldLabel,
              ),
              validator: (value) {
                final amount = _parsePositiveAmount(value ?? '');
                if (amount == null) {
                  return l10n.caloriesPositiveNumberValidation;
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(l10n),
            ),
            if (widget.availableUnits.length > 1) ...[
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<ConsumedUnit>(
                key: const Key('inventory_item_portion_unit_field'),
                initialValue: _selectedUnit,
                items: [
                  for (final unit in widget.availableUnits)
                    DropdownMenuItem<ConsumedUnit>(
                      value: unit,
                      child: Text(unit.localizedName(l10n)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedUnit = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          onPressed: () => _submit(l10n),
          child: Text(l10n.inventoryItemEatSheetSavePortionAction),
        ),
      ],
    );
  }

  void _submit(AppLocalizations l10n) {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final amount = _parsePositiveAmount(_amountController.text);
    if (amount == null) {
      return;
    }

    final label = _labelController.text.trim();
    final defaultLabel = l10n.inventoryItemEatSheetDefaultPortionLabel;
    Navigator.of(context).pop(
      _NewPortionDialogResult(
        amount: amount,
        unit: _selectedUnit,
        label: label.isEmpty || label == defaultLabel ? null : label,
      ),
    );
  }

  double? _parsePositiveAmount(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}

class _NewPortionDialogResult {
  const _NewPortionDialogResult({
    required this.amount,
    required this.unit,
    required this.label,
  });

  final double amount;
  final ConsumedUnit unit;
  final String? label;
}
