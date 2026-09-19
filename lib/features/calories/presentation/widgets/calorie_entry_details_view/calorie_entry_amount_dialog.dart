import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_labels.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks for a new consumed amount of [entry].
///
/// Returns the amount, or `null` when the user cancels or keeps the old one.
Future<double?> showCalorieEntryAmountDialog(
  BuildContext context, {
  required CalorieEntry entry,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _CalorieEntryAmountDialog(entry: entry),
  );
}

class _CalorieEntryAmountDialog extends StatefulWidget {
  const new({required this.entry});

  final CalorieEntry entry;

  @override
  State<_CalorieEntryAmountDialog> createState() =>
      _CalorieEntryAmountDialogState();
}

class _CalorieEntryAmountDialogState extends State<_CalorieEntryAmountDialog> {
  late final _controller = TextEditingController(
    text: formatCalorieEntryNutritionMetricValue(widget.entry.consumedAmount),
  );
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      setState(() => _errorText = l10n.caloriesPositiveNumberValidation);
      return;
    }
    Navigator.of(context)
        .pop(amount == widget.entry.consumedAmount ? null : amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.caloriesEntryAmountDialogTitle),
      content: TextField(
        key: CalorieEntryDetailKeys.amountField,
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          suffixText: widget.entry.consumedUnit.localizedName(l10n),
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          key: CalorieEntryDetailKeys.amountSaveButton,
          onPressed: _submit,
          child: Text(l10n.caloriesSaveEntryAction),
        ),
      ],
    );
  }
}
