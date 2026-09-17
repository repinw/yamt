import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Dialog to edit the price of a receipt item.
class ReceiptPriceEditDialog extends StatefulWidget {
  /// Creates a [ReceiptPriceEditDialog].
  const new({required this.initialPrice, super.key});

  /// The current price of the item.
  final double initialPrice;

  /// Shows the dialog and returns the new price or null if cancelled.
  static Future<double?> show(BuildContext context, double initialPrice) {
    return showDialog<double>(
      context: context,
      builder: (context) => ReceiptPriceEditDialog(initialPrice: initialPrice),
    );
  }

  @override
  State<ReceiptPriceEditDialog> createState() => _ReceiptPriceEditDialogState();
}

class _ReceiptPriceEditDialogState extends State<ReceiptPriceEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n?.receiptReviewPriceEditTitle ?? 'Preis anpassen'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: const InputDecoration(suffixText: '€'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.inventoryReceiptReviewCancelAction ?? 'Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final val = double.tryParse(_controller.text.replaceAll(',', '.'));
            if (val != null && val >= 0) {
              Navigator.of(context).pop(val);
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n?.inventoryReceiptReviewSaveAction ?? 'Speichern'),
        ),
      ],
    );
  }
}
