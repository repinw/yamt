import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Dialog to prompt the user for manual barcode input.
class ReceiptBarcodeInputDialog extends StatefulWidget {
  /// Creates a [ReceiptBarcodeInputDialog].
  const ReceiptBarcodeInputDialog({super.key});

  /// Displays the dialog and returns the entered barcode or null.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const ReceiptBarcodeInputDialog(),
    );
  }

  @override
  State<ReceiptBarcodeInputDialog> createState() =>
      _ReceiptBarcodeInputDialogState();
}

class _ReceiptBarcodeInputDialogState extends State<ReceiptBarcodeInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
      title: Text(
        l10n?.receiptReviewBarcodeDialogTitle ?? 'Barcode eingeben / scannen',
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n?.receiptReviewBarcodeDialogLabel ?? 'Barcode (EAN)',
        ),
        onSubmitted: (val) => Navigator.of(context).pop(val.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n?.inventoryReceiptReviewCancelAction ?? 'Abbrechen',
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n?.receiptReviewConfirmAction ?? 'Bestätigen'),
        ),
      ],
    );
  }
}
